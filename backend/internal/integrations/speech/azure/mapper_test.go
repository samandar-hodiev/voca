// Golden tests over payloads RECORDED FROM THE LIVE SERVICE.
//
// The mapping is the one place a vendor change corrupts scores silently: no error, no
// panic, just wrong numbers shown to learners. These fixtures are the evidence of what
// Azure actually sends, so a change in their shape fails here instead of in production.
//
// See ARCHITECTURE.md 7.4, 22.1.

package azure

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"github.com/samandar-hodiev/voca/backend/internal/pronunciation"
)

func load(t *testing.T, name string) recognitionResponse {
	t.Helper()
	data, err := os.ReadFile(filepath.Join("testdata", name))
	if err != nil {
		t.Fatalf("read %s: %v", name, err)
	}
	var resp recognitionResponse
	if err := json.Unmarshal(data, &resp); err != nil {
		t.Fatalf("unmarshal %s: %v", name, err)
	}
	return resp
}

func TestToDomainMapsARealAssessment(t *testing.T) {
	out := toDomain(load(t, "assessment_success.json"))

	if out.Provider != "azure" {
		t.Errorf("provider = %q, want azure", out.Provider)
	}
	if out.RecognizedText != "Think." {
		t.Errorf("recognized = %q, want Think.", out.RecognizedText)
	}
	// Scores sit flat on the NBest entry in the detailed REST response. If a future shape
	// nests them, these three go to zero and this test says so.
	if out.Accuracy != 94 || out.Fluency != 100 || out.Completeness != 100 {
		t.Errorf("scores = %v/%v/%v, want 94/100/100",
			out.Accuracy, out.Fluency, out.Completeness)
	}

	if len(out.Words) != 1 {
		t.Fatalf("words = %d, want 1", len(out.Words))
	}
	w := out.Words[0]
	if w.Word != "think" || w.Accuracy != 94 || w.Error != pronunciation.ErrorNone {
		t.Errorf("word = %+v, want think/94/none", w)
	}

	// IPA, because the request asks for it. Anything else and no pronunciation tip would
	// ever match the sound it is about.
	want := []pronunciation.PhonemeAssessment{
		{Phoneme: "θ", Accuracy: 100},
		{Phoneme: "ɪ", Accuracy: 93},
		{Phoneme: "ŋ", Accuracy: 100},
		{Phoneme: "k", Accuracy: 31},
	}
	if len(w.Phonemes) != len(want) {
		t.Fatalf("phonemes = %d, want %d", len(w.Phonemes), len(want))
	}
	for i, p := range want {
		if w.Phonemes[i] != p {
			t.Errorf("phoneme %d = %+v, want %+v", i, w.Phonemes[i], p)
		}
	}
}

func TestSilenceIsReportedAsNothingHeard(t *testing.T) {
	// Recorded from the live service: a second of digital silence answers Success, not
	// NoMatch, with every score 0 and the word marked Omission. Passed through, that
	// would tell somebody who never spoke that they scored zero.
	out := toDomain(load(t, "assessment_silence.json"))

	if len(out.Words) != 0 || out.RecognizedText != "" {
		t.Errorf("silence mapped to %+v, want an empty signal", out)
	}
	if out.Accuracy != 0 || out.Fluency != 0 || out.Completeness != 0 {
		t.Errorf("silence produced scores: %+v", out)
	}
}

func TestUnrecognisedErrorTypeDoesNotLeak(t *testing.T) {
	resp := recognitionResponse{
		RecognitionStatus: "Success",
		NBest: []nBestResult{{
			Display:       "think",
			AccuracyScore: 70,
			Words: []wordResult{{
				Word:          "think",
				AccuracyScore: 70,
				ErrorType:     "SomethingAzureInventedLastWeek",
			}},
		}},
	}

	out := toDomain(resp)
	if got := out.Words[0].Error; got != pronunciation.ErrorNone {
		t.Errorf("unknown vendor error mapped to %q, want none", got)
	}
}

func TestFailedRecognitionIsEmpty(t *testing.T) {
	out := toDomain(recognitionResponse{RecognitionStatus: "InitialSilenceTimeout"})
	if len(out.Words) != 0 || out.RecognizedText != "" {
		t.Errorf("failed recognition mapped to %+v, want empty", out)
	}
}
