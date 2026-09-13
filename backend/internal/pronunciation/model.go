// pronunciation: domain entities.
//
// The types themselves live in the leaf package pronunciation/domain, because the scoring,
// analysis and feedback engines all speak them and a subpackage cannot import its parent.
// They are re-exported here as aliases, so every caller — handler, service, repository,
// and other modules — still writes pronunciation.Attempt and never learns that the leaf
// exists. Aliases, not wrappers: these are the same types, not copies of them.
//
// See ARCHITECTURE.md 6 and 10 (tables backing these entities).

package pronunciation

import "github.com/samandar-hodiev/voca/backend/internal/pronunciation/domain"

type (
	WordErrorType      = domain.WordErrorType
	Severity           = domain.Severity
	AssessmentInput    = domain.AssessmentInput
	AssessmentOutput   = domain.AssessmentOutput
	WordAssessment     = domain.WordAssessment
	PhonemeAssessment  = domain.PhonemeAssessment
	Scores             = domain.Scores
	PronunciationError = domain.PronunciationError
	Feedback           = domain.Feedback
	Attempt            = domain.Attempt
)

const (
	ErrorNone             = domain.ErrorNone
	ErrorMispronunciation = domain.ErrorMispronunciation
	ErrorOmission         = domain.ErrorOmission
	ErrorInsertion        = domain.ErrorInsertion
	ErrorUnexpectedBreak  = domain.ErrorUnexpectedBreak
	ErrorMissingBreak     = domain.ErrorMissingBreak
	ErrorMonotone         = domain.ErrorMonotone

	SeverityMinor    = domain.SeverityMinor
	SeverityModerate = domain.SeverityModerate
	SeveritySevere   = domain.SeveritySevere
)
