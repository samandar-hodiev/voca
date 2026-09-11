package localfile

import (
	"bytes"
	"context"
	"image"
	"image/color"
	"image/png"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func pngBytes(t *testing.T) []byte {
	t.Helper()
	img := image.NewRGBA(image.Rect(0, 0, 4, 4))
	img.Set(0, 0, color.RGBA{R: 255, A: 255})
	var buf bytes.Buffer
	if err := png.Encode(&buf, img); err != nil {
		t.Fatalf("encode png: %v", err)
	}
	return buf.Bytes()
}

func newStore(t *testing.T) *AvatarStore {
	t.Helper()
	s, err := NewAvatarStore(filepath.Join(t.TempDir(), "avatars"), "/media/avatars")
	if err != nil {
		t.Fatalf("NewAvatarStore: %v", err)
	}
	return s
}

func TestPutStoresAnImageAndReturnsItsURL(t *testing.T) {
	s := newStore(t)

	url, err := s.Put(context.Background(), "user-1", "image/png", pngBytes(t))
	if err != nil {
		t.Fatalf("Put: %v", err)
	}
	if !strings.HasPrefix(url, "/media/avatars/") {
		t.Errorf("url = %q, want it under the public prefix", url)
	}
	if !strings.HasSuffix(url, ".png") {
		t.Errorf("url = %q, want the extension the bytes imply", url)
	}
	if _, err := os.Stat(filepath.Join(s.Dir(), filepath.Base(url))); err != nil {
		t.Errorf("the file was not written: %v", err)
	}
}

// The declared type is a claim by whoever is uploading. What decides is the bytes, or a
// script could be stored as an image and served back.
func TestPutIgnoresTheDeclaredTypeAndSniffsTheBytes(t *testing.T) {
	s := newStore(t)

	// Real PNG bytes, dishonestly labelled.
	url, err := s.Put(context.Background(), "user-1", "text/plain", pngBytes(t))
	if err != nil {
		t.Fatalf("Put: %v", err)
	}
	if !strings.HasSuffix(url, ".png") {
		t.Errorf("url = %q, want the type the bytes actually are", url)
	}

	// Something that is not an image at all, dishonestly labelled as one.
	_, err = s.Put(context.Background(), "user-1", "image/png",
		[]byte("#!/bin/sh\necho not an image\n"))
	if err == nil {
		t.Fatal("expected a non-image to be refused however it is labelled")
	}
}

func TestPutRefusesEmptyAndOversizedImages(t *testing.T) {
	s := newStore(t)

	if _, err := s.Put(context.Background(), "u", "image/png", nil); err == nil {
		t.Error("expected an empty upload to be refused")
	}

	oversized := make([]byte, MaxAvatarBytes+1)
	copy(oversized, pngBytes(t))
	if _, err := s.Put(context.Background(), "u", "image/png", oversized); err == nil {
		t.Error("expected an oversized upload to be refused")
	}
}

// A predictable URL would let anybody who knows an account id fetch that person's
// picture, and replacing an avatar should not leave the old URL working.
func TestPutGivesEachUploadItsOwnName(t *testing.T) {
	s := newStore(t)
	data := pngBytes(t)

	first, err := s.Put(context.Background(), "user-1", "image/png", data)
	if err != nil {
		t.Fatalf("Put: %v", err)
	}
	second, err := s.Put(context.Background(), "user-1", "image/png", data)
	if err != nil {
		t.Fatalf("Put: %v", err)
	}
	if first == second {
		t.Error("two uploads by the same person produced the same URL")
	}
}

func TestRemoveDeletesTheFileAndToleratesTheRest(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	url, err := s.Put(ctx, "user-1", "image/png", pngBytes(t))
	if err != nil {
		t.Fatalf("Put: %v", err)
	}
	if err := s.Remove(ctx, url); err != nil {
		t.Fatalf("Remove: %v", err)
	}
	if _, err := os.Stat(filepath.Join(s.Dir(), filepath.Base(url))); !os.IsNotExist(err) {
		t.Error("the file should be gone")
	}

	// Removing what is already gone, and what was never ours, both succeed.
	if err := s.Remove(ctx, url); err != nil {
		t.Errorf("removing a missing file returned %v", err)
	}
	if err := s.Remove(ctx, "https://example.com/somebody-elses.png"); err != nil {
		t.Errorf("removing a foreign url returned %v", err)
	}
}

// A stored value containing traversal must not reach outside the directory.
func TestRemoveCannotEscapeTheDirectory(t *testing.T) {
	s := newStore(t)

	outside := filepath.Join(filepath.Dir(s.Dir()), "keep-me.txt")
	if err := os.WriteFile(outside, []byte("important"), 0o600); err != nil {
		t.Fatalf("write: %v", err)
	}

	if err := s.Remove(context.Background(), "/media/avatars/../keep-me.txt"); err != nil {
		t.Fatalf("Remove: %v", err)
	}
	if _, err := os.Stat(outside); err != nil {
		t.Error("a file outside the avatar directory was deleted")
	}
}
