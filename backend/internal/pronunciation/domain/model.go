// pronunciation/domain: the module's shared vocabulary.
//
// A leaf package on purpose. The engines in analysis, feedback and scoring all speak these
// types, and so does the module itself; if they lived in the parent package the engines
// would have to import their own parent, which Go forbids. Nothing here imports anything
// of ours, so nothing can ever cycle back to it.
//
// The parent package re-exports every name as a type alias, so callers still write
// pronunciation.Attempt and never see this package.
//
// See ARCHITECTURE.md 6 and 10 (tables backing these entities).

package domain

import (
	"time"

	"github.com/google/uuid"
)

// WordErrorType is OUR diagnosis of what went wrong with a word.
//
// Deliberately our own vocabulary rather than a vendor's enum copied through: changing how
// an error is detected must not require touching a provider adapter.
type WordErrorType string

const (
	ErrorNone             WordErrorType = "none"
	ErrorMispronunciation WordErrorType = "mispronunciation"
	ErrorOmission         WordErrorType = "omission"
	ErrorInsertion        WordErrorType = "insertion"
	ErrorUnexpectedBreak  WordErrorType = "unexpected_break"
	ErrorMissingBreak     WordErrorType = "missing_break"
	ErrorMonotone         WordErrorType = "monotone"
)

// Severity is how much a problem matters, used to order what the learner is told first.
type Severity string

const (
	SeverityMinor    Severity = "minor"
	SeverityModerate Severity = "moderate"
	SeveritySevere   Severity = "severe"
)

// AssessmentInput is what a SpeechProvider is given. Our types only: no vendor concept
// appears here, or the abstraction has already failed.
type AssessmentInput struct {
	Audio         []byte
	ContentType   string
	ReferenceText string

	// BCP-47, for example en-US.
	Language string
}

// AssessmentOutput is the provider's SIGNAL, not yet our scores.
//
// Scoring policy lives in the scoring engine, so what a provider returns and what Voca
// tells a learner can move independently.
type AssessmentOutput struct {
	Provider       string
	RecognizedText string

	Accuracy     float64
	Fluency      float64
	Completeness float64

	Words []WordAssessment
}

type WordAssessment struct {
	Word     string
	Accuracy float64
	Error    WordErrorType
	Phonemes []PhonemeAssessment
}

type PhonemeAssessment struct {
	Phoneme  string
	Accuracy float64
}

// Scores are Voca's numbers, derived from the provider signal by the scoring engine.
type Scores struct {
	Accuracy     float64
	Fluency      float64
	Completeness float64
	Overall      float64
}

// PronunciationError is a detected problem, before it becomes advice.
type PronunciationError struct {
	Word     string
	Phoneme  string
	Type     WordErrorType
	Severity Severity
}

// Feedback is one piece of advice.
//
// Carries message KEYS and parameters, never finished sentences: the learner-facing text
// lives in the app's ARB files, which is what makes a new interface language a translation
// task rather than a backend change.
type Feedback struct {
	Word       string
	Phoneme    string
	MessageKey string
	TipKey     string

	// Lower sorts first on screen.
	Priority int
}

// Attempt is one recording, assessed and stored.
type Attempt struct {
	ID     uuid.UUID
	UserID uuid.UUID

	ReferenceText  string
	Language       string
	Provider       string
	ScoringVersion string
	Status         string

	Scores         Scores
	RecognizedText string
	Words          []WordAssessment
	Feedback       []Feedback

	AudioDurationMS int
	CreatedAt       time.Time
}
