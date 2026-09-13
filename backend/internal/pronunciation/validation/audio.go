// pronunciation/validation: audio validation rules, applied BEFORE any provider call.
//
// Order matters — invalid input must cost us nothing:
//   1. body size cap
//   2. declared MIME type against an allow-list
//   3. MAGIC-BYTE SNIFFING of actual content (a declared MIME type is a claim, not a fact)
//   4. header parse: sample rate, channel count, bit depth, duration
//   5. cross-check duration against the client-declared value
//
// Rejections return specific codes (AUDIO_TOO_LARGE, AUDIO_TOO_LONG,
// UNSUPPORTED_AUDIO_FORMAT) so the app can show an actionable message.
//
// Limits are passed in rather than read from config here, so this package stays pure and
// a test can state its own bounds in one line.
//
// See ARCHITECTURE.md 12.1, 12.2, 18.2.

package validation

import (
	"encoding/binary"
	"net/http"
	"strings"

	"github.com/samandar-hodiev/voca/backend/internal/shared/apperr"
)

// Limits bound what we will accept. They come from configuration at the call site.
type Limits struct {
	MaxBytes      int
	MinDurationMS int
	MaxDurationMS int
}

// DefaultLimits match the recorder's contract in the app: 16 kHz mono PCM WAV, a fraction
// of a second at minimum so an accidental tap is not assessed, and short enough that the
// provider's own 30-second ceiling for pronunciation assessment is never the thing that
// fails.
func DefaultLimits() Limits {
	return Limits{
		MaxBytes:      2 * 1024 * 1024,
		MinDurationMS: 400,
		MaxDurationMS: 15_000,
	}
}

// Audio is what a valid upload turned out to be.
type Audio struct {
	SampleRate int
	Channels   int
	BitDepth   int
	DurationMS int
}

// allowedContentTypes is what the app is permitted to declare. The declaration is only a
// hint; the bytes are checked regardless.
var allowedContentTypes = []string{"audio/wav", "audio/wave", "audio/x-wav"}

// Validate checks an upload and reports what it is.
//
// declaredDurationMS is what the client said it recorded, or 0 when it said nothing. A
// client that lies is caught here rather than being trusted into a billable call.
func Validate(data []byte, contentType string, declaredDurationMS int, limits Limits) (Audio, error) {
	if len(data) == 0 {
		return Audio{}, apperr.New(apperr.CodeUnsupportedAudio, http.StatusBadRequest,
			"Ovoz yuborilmadi.")
	}
	if len(data) > limits.MaxBytes {
		return Audio{}, apperr.New(apperr.CodeAudioTooLarge, http.StatusRequestEntityTooLarge,
			"Yozuv juda katta. Qisqaroq gapirib ko‘ring.")
	}
	if !contentTypeAllowed(contentType) {
		return Audio{}, apperr.New(apperr.CodeUnsupportedAudio, http.StatusBadRequest,
			"Bu audio format qo‘llab-quvvatlanmaydi.")
	}

	audio, err := parseWAV(data)
	if err != nil {
		return Audio{}, err
	}

	switch {
	case audio.DurationMS < limits.MinDurationMS:
		return Audio{}, apperr.New(apperr.CodeAudioTooShort, http.StatusBadRequest,
			"Yozuv juda qisqa. So‘zni to‘liq ayting.")
	case audio.DurationMS > limits.MaxDurationMS:
		return Audio{}, apperr.New(apperr.CodeAudioTooLong, http.StatusBadRequest,
			"Yozuv juda uzun.")
	}

	// The client's own figure is a claim like the MIME type. A large disagreement means
	// the file is not what the app says it is, so it does not reach the provider.
	if declaredDurationMS > 0 {
		diff := declaredDurationMS - audio.DurationMS
		if diff < 0 {
			diff = -diff
		}
		if diff > 2000 {
			return Audio{}, apperr.New(apperr.CodeUnsupportedAudio, http.StatusBadRequest,
				"Yozuv buzilgan ko‘rinadi. Qaytadan urinib ko‘ring.")
		}
	}

	return audio, nil
}

func contentTypeAllowed(declared string) bool {
	// "audio/wav; codecs=audio/pcm; samplerate=16000" — only the media type matters here.
	base := strings.ToLower(strings.TrimSpace(strings.Split(declared, ";")[0]))
	for _, allowed := range allowedContentTypes {
		if base == allowed {
			return true
		}
	}
	return false
}

// parseWAV reads a RIFF/WAVE header far enough to know what the audio is.
//
// Hand-rolled rather than pulled from a dependency: this reads four fields from a header
// whose layout has not changed since 1991, and a decoder that can decode is a larger
// attack surface than a reader that only measures.
func parseWAV(data []byte) (Audio, error) {
	unsupported := func() (Audio, error) {
		return Audio{}, apperr.New(apperr.CodeUnsupportedAudio, http.StatusBadRequest,
			"Bu audio format qo‘llab-quvvatlanmaydi. 16 kHz mono WAV kutilgan.")
	}

	// 12 bytes of RIFF header, then chunks.
	if len(data) < 44 {
		return unsupported()
	}
	if string(data[0:4]) != "RIFF" || string(data[8:12]) != "WAVE" {
		return unsupported()
	}

	var (
		sampleRate, channels, bitDepth int
		dataBytes                      int
		sawFmt                         bool
	)

	// Walk the chunk list rather than assuming "fmt " and "data" sit at fixed offsets:
	// recorders on both platforms insert LIST and fact chunks.
	for offset := 12; offset+8 <= len(data); {
		id := string(data[offset : offset+4])
		size := int(binary.LittleEndian.Uint32(data[offset+4 : offset+8]))
		body := offset + 8
		if size < 0 || body+size > len(data) {
			// A truncated final chunk: measure what is actually there.
			size = len(data) - body
			if size < 0 {
				break
			}
		}

		switch id {
		case "fmt ":
			if size < 16 {
				return unsupported()
			}
			format := int(binary.LittleEndian.Uint16(data[body : body+2]))
			channels = int(binary.LittleEndian.Uint16(data[body+2 : body+4]))
			sampleRate = int(binary.LittleEndian.Uint32(data[body+4 : body+8]))
			bitDepth = int(binary.LittleEndian.Uint16(data[body+14 : body+16]))
			// 1 is uncompressed PCM. Anything else would need decoding before it could
			// be measured, and is not what the app records.
			if format != 1 {
				return unsupported()
			}
			sawFmt = true
		case "data":
			dataBytes = size
		}

		// Chunks are word-aligned: an odd size is followed by a pad byte.
		offset = body + size
		if size%2 == 1 {
			offset++
		}
	}

	if !sawFmt || sampleRate <= 0 || channels <= 0 || bitDepth <= 0 || dataBytes <= 0 {
		return unsupported()
	}

	bytesPerSecond := sampleRate * channels * (bitDepth / 8)
	if bytesPerSecond <= 0 {
		return unsupported()
	}

	return Audio{
		SampleRate: sampleRate,
		Channels:   channels,
		BitDepth:   bitDepth,
		DurationMS: dataBytes * 1000 / bytesPerSecond,
	}, nil
}
