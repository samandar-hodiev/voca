// pronunciation: request and response shapes for the HTTP API.
//
// Kept separate from domain models on purpose: the wire contract and the domain evolve
// independently. Field names are snake_case per ARCHITECTURE.md 11.1.
//
// The request is multipart rather than JSON — it carries audio — so it has no struct here;
// the handler reads its fields. What is declared here is what we answer with.
//
// See ARCHITECTURE.md 11.2.

package pronunciation

// attemptResponse is what the app renders on the result screen.
type attemptResponse struct {
	ID string `json:"id"`

	ReferenceText  string `json:"reference_text"`
	RecognizedText string `json:"recognized_text"`
	Language       string `json:"language"`

	Scores scoresResponse `json:"scores"`

	Words    []wordResponse     `json:"words"`
	Feedback []feedbackResponse `json:"feedback"`

	// Which engine produced the signal and which policy turned it into these numbers.
	// Returned so a support conversation about a surprising score has the facts in it.
	Provider       string `json:"provider"`
	ScoringVersion string `json:"scoring_version"`

	AudioDurationMS int    `json:"audio_duration_ms"`
	CreatedAt       string `json:"created_at"`
}

type scoresResponse struct {
	Accuracy     float64 `json:"accuracy"`
	Fluency      float64 `json:"fluency"`
	Completeness float64 `json:"completeness"`
	Overall      float64 `json:"overall"`
}

type wordResponse struct {
	Word     string            `json:"word"`
	Accuracy float64           `json:"accuracy"`
	Error    string            `json:"error"`
	Phonemes []phonemeResponse `json:"phonemes"`
}

type phonemeResponse struct {
	Phoneme  string  `json:"phoneme"`
	Accuracy float64 `json:"accuracy"`
}

// feedbackResponse carries keys, not sentences: the app owns the wording, in whichever
// language the learner reads.
type feedbackResponse struct {
	Word       string `json:"word,omitempty"`
	Phoneme    string `json:"phoneme,omitempty"`
	MessageKey string `json:"message_key"`
	TipKey     string `json:"tip_key,omitempty"`
	Priority   int    `json:"priority"`
}

func toAttemptResponse(a Attempt) attemptResponse {
	words := make([]wordResponse, 0, len(a.Words))
	for _, w := range a.Words {
		phonemes := make([]phonemeResponse, 0, len(w.Phonemes))
		for _, p := range w.Phonemes {
			phonemes = append(phonemes, phonemeResponse{
				Phoneme:  p.Phoneme,
				Accuracy: p.Accuracy,
			})
		}
		words = append(words, wordResponse{
			Word:     w.Word,
			Accuracy: w.Accuracy,
			Error:    string(w.Error),
			Phonemes: phonemes,
		})
	}

	feedback := make([]feedbackResponse, 0, len(a.Feedback))
	for _, f := range a.Feedback {
		feedback = append(feedback, feedbackResponse{
			Word:       f.Word,
			Phoneme:    f.Phoneme,
			MessageKey: f.MessageKey,
			TipKey:     f.TipKey,
			Priority:   f.Priority,
		})
	}

	return attemptResponse{
		ID:             a.ID.String(),
		ReferenceText:  a.ReferenceText,
		RecognizedText: a.RecognizedText,
		Language:       a.Language,
		Scores: scoresResponse{
			Accuracy:     a.Scores.Accuracy,
			Fluency:      a.Scores.Fluency,
			Completeness: a.Scores.Completeness,
			Overall:      a.Scores.Overall,
		},
		Words:           words,
		Feedback:        feedback,
		Provider:        a.Provider,
		ScoringVersion:  a.ScoringVersion,
		AudioDurationMS: a.AudioDurationMS,
		CreatedAt:       a.CreatedAt.UTC().Format("2006-01-02T15:04:05Z"),
	}
}
