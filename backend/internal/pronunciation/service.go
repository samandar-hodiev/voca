// pronunciation: business logic / use cases. THE CORE MODULE.
//
// Orchestrates the assessment pipeline end to end (ARCHITECTURE.md 6.1):
//
//	validate audio -> assess via SpeechProvider -> score -> analyse -> feedback -> persist
//
// Validation comes BEFORE the provider call on purpose: a bad upload must cost us nothing.
//
// MUST NOT import gin, pgx or any vendor SDK. It talks to a Repository interface and a
// SpeechProvider port, both of which this module owns.
//
// See ARCHITECTURE.md 6, 5.3, 5.5.

package pronunciation

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/samandar-hodiev/voca/backend/internal/pronunciation/analysis"
	"github.com/samandar-hodiev/voca/backend/internal/pronunciation/feedback"
	"github.com/samandar-hodiev/voca/backend/internal/pronunciation/scoring"
	"github.com/samandar-hodiev/voca/backend/internal/pronunciation/validation"
	"github.com/samandar-hodiev/voca/backend/internal/shared/apperr"
)

// SubmitCommand is one attempt at saying something, as it arrives from the app.
type SubmitCommand struct {
	UserID uuid.UUID

	Audio       []byte
	ContentType string

	// ReferenceText is what the learner was asked to say. Required: this is a scripted
	// assessment, and without it there is nothing to score against.
	ReferenceText string

	Language string

	// DeclaredDurationMS is what the client says it recorded, or 0. Checked against the
	// audio header rather than trusted.
	DeclaredDurationMS int
}

type Service struct {
	repo     Repository
	provider SpeechProvider
	scorer   *scoring.Engine
	analyzer *analysis.Analyzer
	feedback *feedback.Generator
	limits   validation.Limits
	log      *slog.Logger

	// Nil means no limit is enforced, which is what local development and every test
	// that is not about quota get.
	entitlements Entitlements
}

func NewService(
	repo Repository,
	provider SpeechProvider,
	scorer *scoring.Engine,
	analyzer *analysis.Analyzer,
	generator *feedback.Generator,
	limits validation.Limits,
	entitlements Entitlements,
	log *slog.Logger,
) *Service {
	return &Service{
		repo:         repo,
		provider:     provider,
		scorer:       scorer,
		analyzer:     analyzer,
		feedback:     generator,
		limits:       limits,
		entitlements: entitlements,
		log:          log,
	}
}

const defaultLanguage = "en-US"

// SubmitAttempt runs the pipeline and returns the stored result.
func (s *Service) SubmitAttempt(ctx context.Context, cmd SubmitCommand) (Attempt, error) {
	reference := strings.TrimSpace(cmd.ReferenceText)
	if reference == "" {
		return Attempt{}, apperr.Validation("Qaysi so‘z aytilishi kerakligi yuborilmadi.")
	}

	language := strings.TrimSpace(cmd.Language)
	if language == "" {
		language = defaultLanguage
	}

	// The free-tier limit is enforced here, before the provider call, so a blocked
	// request costs no provider money (ARCHITECTURE.md 6.1 step 2).
	if err := s.checkAllowance(ctx, cmd.UserID); err != nil {
		return Attempt{}, err
	}

	audio, err := validation.Validate(cmd.Audio, cmd.ContentType, cmd.DeclaredDurationMS, s.limits)
	if err != nil {
		return Attempt{}, err
	}

	out, err := s.provider.AssessPronunciation(ctx, AssessmentInput{
		Audio:         cmd.Audio,
		ContentType:   cmd.ContentType,
		ReferenceText: reference,
		Language:      language,
	})
	if err != nil {
		return Attempt{}, s.providerError(err)
	}

	// Nothing to score. Two very different things land here and they must not be told
	// apart by guesswork: somebody who said nothing, and somebody who spoke clearly but
	// said the wrong word. The provider reports what it heard, and that is the difference.
	if len(out.Words) == 0 {
		heard := strings.TrimSpace(out.RecognizedText)
		if heard == "" {
			// Telling somebody "something went wrong" when they simply did not speak is
			// the wrong message.
			return Attempt{}, apperr.New(apperr.CodeNoSpeechDetected, http.StatusUnprocessableEntity,
				"Ovoz eshitilmadi. Mikrofonga yaqinroq gapirib ko‘ring.")
		}
		// Saying the wrong word is not a failure to hear them, and reporting it as one
		// sends a learner off to fiddle with their microphone. What they need is the
		// word they actually said, next to the one they were asked for.
		return Attempt{}, apperr.New(apperr.CodeWrongWord, http.StatusUnprocessableEntity,
			"Boshqa so‘z aytildi. Qaytadan urinib ko‘ring.").
			WithDetails(map[string]any{"heard": heard, "expected": reference})
	}

	scores := s.scorer.Score(out)
	problems := s.analyzer.Analyze(out)
	advice := s.feedback.Generate(problems)

	attempt := Attempt{
		UserID:          cmd.UserID,
		ReferenceText:   reference,
		Language:        language,
		Provider:        out.Provider,
		ScoringVersion:  s.scorer.Version(),
		Status:          "scored",
		Scores:          scores,
		RecognizedText:  out.RecognizedText,
		Words:           out.Words,
		Feedback:        advice,
		AudioDurationMS: audio.DurationMS,
	}

	id, createdAt, err := s.repo.SaveAttempt(ctx, attempt)
	if err != nil {
		return Attempt{}, apperr.Internal(err)
	}
	attempt.ID = id
	// Read back rather than stamped here: the response then carries the time the row
	// actually has, instead of Go's zero date, which is what the app was being sent.
	attempt.CreatedAt = createdAt

	return attempt, nil
}

// checkAllowance blocks an attempt that would exceed the account's daily quota.
//
// The policy comes from the entitlements port; the counting is done here, against this
// module's own table. Because only assessed attempts are ever stored, a failed one is
// invisible to this count — we do not charge somebody for our own outage.
func (s *Service) checkAllowance(ctx context.Context, userID uuid.UUID) error {
	if s.entitlements == nil {
		return nil
	}

	allowance, err := s.entitlements.Allowance(ctx, userID)
	if err != nil {
		return apperr.Internal(err)
	}
	if allowance.Unlimited || allowance.DailyLimit <= 0 {
		return nil
	}

	used, err := s.repo.CountAttemptsSince(ctx, userID, allowance.Since)
	if err != nil {
		return apperr.Internal(err)
	}
	if used < allowance.DailyLimit {
		return nil
	}

	s.log.Info("usage_limit_reached",
		slog.String("user_id", userID.String()),
		slog.Int("limit", allowance.DailyLimit))

	// resets_at is what the app turns into "come back tomorrow at": the client reads it
	// out of details rather than guessing a rollover hour of its own.
	return apperr.New(apperr.CodeUsageLimit, http.StatusTooManyRequests,
		"Bugungi mashq chegarasiga yetdingiz. Ertaga davom ettirasiz.").
		WithDetails(map[string]any{
			"resets_at": allowance.ResetsAt.UTC().Format(time.RFC3339),
			"limit":     allowance.DailyLimit,
			"used":      used,
		})
}

// History is the learner's own recent attempts.
func (s *Service) History(ctx context.Context, userID uuid.UUID, limit int) ([]Attempt, error) {
	attempts, err := s.repo.RecentAttempts(ctx, userID, limit)
	if err != nil {
		return nil, apperr.Internal(err)
	}
	return attempts, nil
}

// providerError turns a vendor failure into something the app can act on.
//
// A timeout and an outage are different to a learner: one is worth retrying immediately,
// the other is not. Neither is the learner's fault, so neither is reported as one.
func (s *Service) providerError(err error) error {
	if errors.Is(err, context.DeadlineExceeded) || errors.Is(err, context.Canceled) {
		s.log.Warn("speech_provider_timeout", slog.String("provider", s.provider.Name()))
		return apperr.New(apperr.CodeProviderTimeout, http.StatusGatewayTimeout,
			"Baholash juda uzoq davom etdi. Qaytadan urinib ko‘ring.")
	}
	s.log.Error("speech_provider_failed",
		slog.String("provider", s.provider.Name()),
		slog.String("error", err.Error()))
	return apperr.ProviderUnavailable("Baholash xizmati hozir ishlamayapti. Birozdan so‘ng urinib ko‘ring.")
}
