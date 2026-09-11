// Package localfile stores uploaded files on the machine running the service.
//
// It is the MVP adapter for avatars. Object storage is the eventual home, but a local
// directory is enough while there is one server, and swapping it later is a new adapter
// behind the same port rather than a change to the auth module (ADR-006).
//
// Two rules the adapter enforces rather than trusting the caller:
//
//   - The content type is decided by sniffing the bytes, not by believing the header a
//     client sent. A file named `avatar.png` that is really a script must not be stored
//     with an image type and served back.
//   - Only a small set of image types is accepted at all. Anything else is refused,
//     because a store that will hold any bytes at a public URL is a file-hosting service
//     nobody asked for.
package localfile

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"net/http"
	"os"
	"path"
	"path/filepath"
	"strings"
)

// MaxAvatarBytes bounds a single upload. Two megabytes is generous for a profile picture
// and small enough that a handful of concurrent uploads cannot exhaust memory.
const MaxAvatarBytes = 2 << 20

// allowed maps a sniffed content type to the extension it is stored with.
var allowed = map[string]string{
	"image/jpeg": ".jpg",
	"image/png":  ".png",
	"image/webp": ".webp",
}

// AvatarStore writes avatars into a directory and serves them under a URL prefix.
type AvatarStore struct {
	dir string

	// publicPrefix is what a stored file's URL starts with, for example "/media/avatars".
	// It is a path rather than a full URL so the same stored value works whatever host
	// the API is reached on.
	publicPrefix string
}

// NewAvatarStore creates the directory if it does not exist.
func NewAvatarStore(dir, publicPrefix string) (*AvatarStore, error) {
	if strings.TrimSpace(dir) == "" {
		return nil, errors.New("localfile: avatar directory is required")
	}
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return nil, fmt.Errorf("create avatar directory: %w", err)
	}
	return &AvatarStore{
		dir:          dir,
		publicPrefix: "/" + strings.Trim(publicPrefix, "/"),
	}, nil
}

// Dir is where the files live, for wiring up static serving.
func (s *AvatarStore) Dir() string { return s.dir }

// PublicPrefix is the path stored URLs begin with.
func (s *AvatarStore) PublicPrefix() string { return s.publicPrefix }

// Put validates the bytes and writes them.
//
// The declared content type is accepted as a hint and then ignored: what decides is what
// the bytes actually are.
func (s *AvatarStore) Put(_ context.Context, userID, _ string, data []byte) (string, error) {
	if len(data) == 0 {
		return "", errors.New("localfile: the image is empty")
	}
	if len(data) > MaxAvatarBytes {
		return "", fmt.Errorf("localfile: the image is larger than %d bytes", MaxAvatarBytes)
	}

	sniffed := http.DetectContentType(data)
	ext, ok := allowed[sniffed]
	if !ok {
		return "", fmt.Errorf("localfile: %s is not an accepted image type", sniffed)
	}

	// A random name rather than the user id alone: a predictable avatar URL lets anybody
	// who knows an account id fetch that person's picture, and a changed picture should
	// not keep the URL the old one had.
	suffix := make([]byte, 8)
	if _, err := rand.Read(suffix); err != nil {
		return "", fmt.Errorf("localfile: generate file name: %w", err)
	}
	name := fmt.Sprintf("%s-%s%s", safeSegment(userID), hex.EncodeToString(suffix), ext)

	if err := os.WriteFile(filepath.Join(s.dir, name), data, 0o644); err != nil {
		return "", fmt.Errorf("localfile: write avatar: %w", err)
	}

	return s.publicPrefix + "/" + name, nil
}

// Remove deletes a stored avatar. A URL that is not ours, or a file that is already gone,
// is not an error: the caller's intent was that the file should not exist.
func (s *AvatarStore) Remove(_ context.Context, url string) error {
	if !strings.HasPrefix(url, s.publicPrefix+"/") {
		return nil
	}

	// path.Base strips any directory traversal a stored value might somehow contain, so a
	// crafted URL cannot reach outside the avatar directory.
	name := path.Base(url)
	if name == "." || name == "/" || name == ".." {
		return nil
	}

	if err := os.Remove(filepath.Join(s.dir, name)); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("localfile: remove avatar: %w", err)
	}
	return nil
}

// safeSegment keeps an identifier usable inside a file name.
func safeSegment(s string) string {
	return strings.Map(func(r rune) rune {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9', r == '-':
			return r
		default:
			return '-'
		}
	}, s)
}
