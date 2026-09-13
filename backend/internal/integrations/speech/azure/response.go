// integrations/speech/azure: private structs mirroring Azure's JSON exactly.
//
// EVERY TYPE IN THIS FILE IS UNEXPORTED, deliberately. Go's visibility rules then make it
// impossible for any other package to reference an Azure field, so vendor coupling cannot
// leak by accident rather than merely by convention.
//
// Nothing here is ever stored, returned to the app, or passed to business logic.
//
// The shape below was MEASURED against the live service, not copied from documentation.
// It matters: much of Microsoft's own material shows the per-word and per-utterance scores
// nested inside a "PronunciationAssessment" object, which is the shape their SDKs emit. The
// detailed REST response this adapter uses puts them flat on the NBest entry and flat on
// each word. Modelling the documented shape instead would unmarshal silently into zeros —
// every learner scored 0 with no error anywhere. testdata/assessment_success.json is the
// recorded proof.
//
// See ARCHITECTURE.md 7.2, 7.4.

package azure

// recognitionResponse is the whole body of a detailed recognition.
type recognitionResponse struct {
	// Success, NoMatch, InitialSilenceTimeout, BabbleTimeout or Error. Note that silence
	// alone does NOT produce NoMatch here — see mapper.go.
	RecognitionStatus string `json:"RecognitionStatus"`

	DisplayText string        `json:"DisplayText"`
	NBest       []nBestResult `json:"NBest"`
}

// nBestResult is one hypothesis. Assessment scores ride on the first one.
type nBestResult struct {
	Confidence float64 `json:"Confidence"`
	Lexical    string  `json:"Lexical"`
	Display    string  `json:"Display"`

	AccuracyScore     float64 `json:"AccuracyScore"`
	FluencyScore      float64 `json:"FluencyScore"`
	CompletenessScore float64 `json:"CompletenessScore"`

	// Azure's own weighted total. Deliberately NOT used as our overall score: that policy
	// belongs to our scoring engine, so Voca's number can move without a vendor change.
	PronScore float64 `json:"PronScore"`

	Words []wordResult `json:"Words"`
}

type wordResult struct {
	Word          string          `json:"Word"`
	AccuracyScore float64         `json:"AccuracyScore"`
	ErrorType     string          `json:"ErrorType"`
	Phonemes      []phonemeResult `json:"Phonemes"`
}

// phonemeResult carries IPA because the request asks for IPA. Without that the symbols
// come back in Azure's SAPI alphabet and no pronunciation tip would ever match.
type phonemeResult struct {
	Phoneme       string  `json:"Phoneme"`
	AccuracyScore float64 `json:"AccuracyScore"`
}
