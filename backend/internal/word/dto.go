// word: request and response shapes for the HTTP API.
//
// Kept separate from domain models on purpose: the wire contract and the domain evolve
// independently. Field names are snake_case per ARCHITECTURE.md 11.1.
//
// See ARCHITECTURE.md 11.2.

package word

type wordResponse struct {
	ID   string `json:"id"`
	Text string `json:"text"`

	PhoneticIPA    string   `json:"phonetic_ipa"`
	TargetPhonemes []string `json:"target_phonemes"`

	// FocusSound is the one symbol the app shows beside the word. Sent rather than left
	// to the client to pick, so every screen shows the same one.
	FocusSound string `json:"focus_sound"`

	DifficultyLevel string `json:"difficulty_level"`
	CEFRLevel       string `json:"cefr_level"`
	PartOfSpeech    string `json:"part_of_speech,omitempty"`

	// Absent for most words today. The app hides the line rather than showing a blank.
	MeaningUz       string `json:"meaning_uz,omitempty"`
	ExampleSentence string `json:"example_sentence,omitempty"`
	AudioURL        string `json:"audio_url,omitempty"`
}

type categoryResponse struct {
	ID        string `json:"id"`
	Slug      string `json:"slug"`
	NameKey   string `json:"name_key"`
	Icon      string `json:"icon,omitempty"`
	WordCount int    `json:"word_count"`
}

func toWordResponse(w Word) wordResponse {
	phonemes := w.TargetPhonemes
	if phonemes == nil {
		phonemes = []string{}
	}
	return wordResponse{
		ID:              w.ID.String(),
		Text:            w.Text,
		PhoneticIPA:     w.PhoneticIPA,
		TargetPhonemes:  phonemes,
		FocusSound:      w.FocusSound(),
		DifficultyLevel: w.DifficultyLevel,
		CEFRLevel:       w.CEFRLevel,
		PartOfSpeech:    w.PartOfSpeech,
		MeaningUz:       w.MeaningUz,
		ExampleSentence: w.ExampleSentence,
		AudioURL:        w.AudioURL,
	}
}

func toWordResponses(words []Word) []wordResponse {
	out := make([]wordResponse, 0, len(words))
	for _, w := range words {
		out = append(out, toWordResponse(w))
	}
	return out
}
