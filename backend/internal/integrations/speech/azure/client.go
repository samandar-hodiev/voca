// integrations/speech/azure: raw HTTP calls to Azure Speech.
//
// Owns authentication (AZURE_SPEECH_KEY, AZURE_SPEECH_REGION), the per-call timeout budget
// (about 10s), and the retry policy: AT MOST ONE retry, only for transient network or 5xx
// errors, never for a 4xx (ARCHITECTURE.md 6.5).
//
// Records provider latency, which is a first-class metric — it is our evidence of vendor
// health and the trigger for circuit breaking or switching (ARCHITECTURE.md 18.4).
//
// The key lives here and ONLY here. It never reaches the mobile app, and it is never
// logged: only the region, the status and the latency are.
//
// See ARCHITECTURE.md 6.5, 7.2.

package azure

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/samandar-hodiev/voca/backend/internal/pronunciation"
)

const (
	providerName   = "azure"
	defaultTimeout = 10 * time.Second

	// The assessment engine is part of speech-to-text, so this is the recognition
	// endpoint with an assessment header attached, not an endpoint of its own.
	endpointTemplate = "https://%s.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1"

	// Enough of the vendor's body to be useful in a log line, not enough to fill it.
	maxErrorBody = 512
)

// Config is what the client needs.
type Config struct {
	Key    string
	Region string

	// Endpoint overrides the region-derived URL. Tests set it; production leaves it empty.
	Endpoint string

	Timeout time.Duration
}

type client struct {
	cfg  Config
	http *http.Client
	log  *slog.Logger
}

func newClient(cfg Config, logger *slog.Logger) (*client, error) {
	if strings.TrimSpace(cfg.Key) == "" {
		return nil, errors.New("azure speech: key is required")
	}
	if strings.TrimSpace(cfg.Region) == "" {
		return nil, errors.New("azure speech: region is required")
	}
	if cfg.Timeout <= 0 {
		cfg.Timeout = defaultTimeout
	}
	if cfg.Endpoint == "" {
		cfg.Endpoint = fmt.Sprintf(endpointTemplate, cfg.Region)
	}
	return &client{
		cfg:  cfg,
		http: &http.Client{Timeout: cfg.Timeout},
		log:  logger,
	}, nil
}

// assessmentConfig is the JSON that rides in the Pronunciation-Assessment header.
//
// PhonemeAlphabet is IPA because Voca's feedback tips are keyed by IPA symbol. Left at the
// default, Azure answers in its own SAPI alphabet and not one tip would ever match.
type assessmentConfig struct {
	ReferenceText   string `json:"ReferenceText"`
	GradingSystem   string `json:"GradingSystem"`
	Granularity     string `json:"Granularity"`
	Dimension       string `json:"Dimension"`
	EnableMiscue    bool   `json:"EnableMiscue"`
	PhonemeAlphabet string `json:"PhonemeAlphabet"`
}

// assess sends one recording with the reference text attached and returns the scored
// vendor response.
func (c *client) assess(
	ctx context.Context, in pronunciation.AssessmentInput,
) (recognitionResponse, error) {
	header, err := assessmentHeader(in.ReferenceText)
	if err != nil {
		return recognitionResponse{}, err
	}
	return c.call(ctx, in, header)
}

// recognize asks only what was actually said, with NO reference text attached.
//
// This exists because Azure cannot tell us on its own whether a learner was silent or
// said a completely different word. Measured against the live service, both answer
// Success with DisplayText ".", every score 0, the reference word marked Omission and no
// phonemes — byte for byte the same shape (testdata/assessment_silence.json). Without a
// reference the two separate cleanly: silence comes back with an empty DisplayText, and
// a wrong word comes back as that word.
//
// Only called when the scored pass returned nothing, so the extra request is spent on the
// rare failure and never on a normal attempt.
func (c *client) recognize(
	ctx context.Context, in pronunciation.AssessmentInput,
) (recognitionResponse, error) {
	return c.call(ctx, in, "")
}

// call performs the request, retrying once on a transient failure. An empty header means
// plain recognition rather than a scored assessment.
func (c *client) call(
	ctx context.Context, in pronunciation.AssessmentInput, header string,
) (recognitionResponse, error) {
	target, err := requestURL(c.cfg.Endpoint, in.Language)
	if err != nil {
		return recognitionResponse{}, err
	}

	// At most one retry, and only for a transport failure or a 5xx. A 4xx means the
	// request itself is wrong; sending it again would just spend the quota twice.
	var lastErr error
	for attempt := 0; attempt < 2; attempt++ {
		resp, retryable, err := c.send(ctx, target, header, in)
		if err == nil {
			return resp, nil
		}
		lastErr = err
		if !retryable || ctx.Err() != nil {
			break
		}
		c.log.Warn("speech_provider_retry",
			slog.String("provider", providerName),
			slog.String("region", c.cfg.Region),
			slog.String("error", err.Error()))
	}
	return recognitionResponse{}, lastErr
}

// send performs one attempt and says whether failing it is worth retrying.
func (c *client) send(
	ctx context.Context, target, header string, in pronunciation.AssessmentInput,
) (recognitionResponse, bool, error) {
	req, err := http.NewRequestWithContext(
		ctx, http.MethodPost, target, bytes.NewReader(in.Audio),
	)
	if err != nil {
		return recognitionResponse{}, false, fmt.Errorf("azure speech: build request: %w", err)
	}

	req.Header.Set("Ocp-Apim-Subscription-Key", c.cfg.Key)
	req.Header.Set("Content-Type", contentType(in.ContentType))
	req.Header.Set("Accept", "application/json")
	if header != "" {
		req.Header.Set("Pronunciation-Assessment", header)
	}

	started := time.Now()
	res, err := c.http.Do(req)
	latency := time.Since(started)
	if err != nil {
		// A transport failure: DNS, connection refused, a timeout mid-flight.
		return recognitionResponse{}, true, fmt.Errorf("azure speech: %w", err)
	}
	defer res.Body.Close()

	// Latency is recorded for every outcome, because a vendor that is slow before failing
	// is the case we most need evidence of.
	c.log.Info("speech_provider_call",
		slog.String("provider", providerName),
		slog.String("region", c.cfg.Region),
		slog.Int("status", res.StatusCode),
		slog.Int64("latency_ms", latency.Milliseconds()))

	if res.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(res.Body, maxErrorBody))
		retryable := res.StatusCode >= 500
		return recognitionResponse{}, retryable, fmt.Errorf(
			"azure speech: status %d: %s", res.StatusCode, strings.TrimSpace(string(body)))
	}

	var parsed recognitionResponse
	if err := json.NewDecoder(res.Body).Decode(&parsed); err != nil {
		return recognitionResponse{}, false, fmt.Errorf("azure speech: decode: %w", err)
	}
	return parsed, false, nil
}

// assessmentHeader is the base64 JSON Azure expects in the Pronunciation-Assessment header.
func assessmentHeader(reference string) (string, error) {
	payload, err := json.Marshal(assessmentConfig{
		ReferenceText: reference,
		GradingSystem: "HundredMark",
		// Phoneme granularity is what makes "your θ is the problem" possible; word-level
		// alone would only ever say "that word was wrong".
		Granularity:     "Phoneme",
		Dimension:       "Comprehensive",
		EnableMiscue:    true,
		PhonemeAlphabet: "IPA",
	})
	if err != nil {
		return "", fmt.Errorf("azure speech: assessment config: %w", err)
	}
	return base64.StdEncoding.EncodeToString(payload), nil
}

func requestURL(endpoint, language string) (string, error) {
	u, err := url.Parse(endpoint)
	if err != nil {
		return "", fmt.Errorf("azure speech: endpoint: %w", err)
	}
	q := u.Query()
	q.Set("language", language)
	// Detailed, because the assessment scores ride on the NBest entries and the simple
	// format has none.
	q.Set("format", "detailed")
	u.RawQuery = q.Encode()
	return u.String(), nil
}

// contentType declares the audio to Azure. Our own validation has already established that
// the bytes really are 16 kHz mono PCM WAV before we get here.
func contentType(declared string) string {
	if strings.Contains(declared, "wav") || declared == "" {
		return "audio/wav; codecs=audio/pcm; samplerate=16000"
	}
	return declared
}
