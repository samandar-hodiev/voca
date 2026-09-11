package middleware

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
)

func newLimitedRouter(cfg RateLimitConfig) *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.Use(RateLimit(cfg))
	r.GET("/x", func(c *gin.Context) { c.Status(http.StatusOK) })
	return r
}

func call(t *testing.T, r *gin.Engine, ip string) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(http.MethodGet, "/x", nil)
	req.RemoteAddr = ip + ":12345"
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	return w
}

func TestRateLimitAllowsUpToTheLimitThenRefuses(t *testing.T) {
	r := newLimitedRouter(RateLimitConfig{Requests: 3, Window: time.Minute})

	for i := 1; i <= 3; i++ {
		if got := call(t, r, "10.0.0.1").Code; got != http.StatusOK {
			t.Fatalf("request %d = %d, want 200", i, got)
		}
	}

	res := call(t, r, "10.0.0.1")
	if res.Code != http.StatusTooManyRequests {
		t.Fatalf("the fourth request = %d, want 429", res.Code)
	}
	if res.Header().Get("Retry-After") == "" {
		t.Error("a refusal should say when to try again")
	}
}

// One noisy client must not lock everybody else out.
func TestRateLimitCountsEachClientSeparately(t *testing.T) {
	r := newLimitedRouter(RateLimitConfig{Requests: 1, Window: time.Minute})

	if got := call(t, r, "10.0.0.1").Code; got != http.StatusOK {
		t.Fatalf("first client = %d, want 200", got)
	}
	if got := call(t, r, "10.0.0.1").Code; got != http.StatusTooManyRequests {
		t.Fatalf("first client again = %d, want 429", got)
	}
	if got := call(t, r, "10.0.0.2").Code; got != http.StatusOK {
		t.Fatalf("second client = %d, want 200", got)
	}
}

func TestRateLimitRecoversAfterTheWindow(t *testing.T) {
	now := time.Now()
	r := newLimitedRouter(RateLimitConfig{
		Requests: 1,
		Window:   time.Minute,
		Now:      func() time.Time { return now },
	})

	if got := call(t, r, "10.0.0.1").Code; got != http.StatusOK {
		t.Fatalf("first = %d, want 200", got)
	}
	if got := call(t, r, "10.0.0.1").Code; got != http.StatusTooManyRequests {
		t.Fatalf("second = %d, want 429", got)
	}

	now = now.Add(time.Minute + time.Second)
	if got := call(t, r, "10.0.0.1").Code; got != http.StatusOK {
		t.Fatalf("after the window = %d, want 200", got)
	}
}

// A limit of zero means the limiter is off, which is what a test or a local run wants.
func TestRateLimitDisabledWhenNotConfigured(t *testing.T) {
	r := newLimitedRouter(RateLimitConfig{})
	for i := 0; i < 50; i++ {
		if got := call(t, r, "10.0.0.1").Code; got != http.StatusOK {
			t.Fatalf("request %d = %d, want 200 with the limiter disabled", i, got)
		}
	}
}

// The bucket map must not grow with every address that has ever called.
func TestRateLimitForgetsIdleClients(t *testing.T) {
	now := time.Now()
	limiter := &ipLimiter{
		requests: 1,
		window:   time.Minute,
		now:      func() time.Time { return now },
		buckets:  map[string]*bucket{},
	}

	for i := 0; i < 100; i++ {
		limiter.allow(string(rune('a' + i%26)))
	}
	before := len(limiter.buckets)

	now = now.Add(2 * time.Minute)
	limiter.allow("survivor")

	if len(limiter.buckets) >= before {
		t.Errorf("buckets = %d, want the expired ones dropped (was %d)",
			len(limiter.buckets), before)
	}
}

// The limit keys on ClientIP, and ClientIP is only as honest as the proxy configuration.
// With no trusted proxy, a caller rotating X-Forwarded-For must still land in one bucket;
// otherwise the limit that stops address enumeration does nothing.
func TestRateLimitIgnoresSpoofedForwardingHeaders(t *testing.T) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	if err := r.SetTrustedProxies(nil); err != nil {
		t.Fatalf("SetTrustedProxies: %v", err)
	}
	r.Use(RateLimit(RateLimitConfig{Requests: 3, Window: time.Minute}))
	r.GET("/x", func(c *gin.Context) { c.Status(http.StatusOK) })

	blocked := 0
	for i := 0; i < 10; i++ {
		req := httptest.NewRequest(http.MethodGet, "/x", nil)
		req.RemoteAddr = "203.0.113.7:4000"
		req.Header.Set("X-Forwarded-For", fmt.Sprintf("10.0.0.%d", i))
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		if w.Code == http.StatusTooManyRequests {
			blocked++
		}
	}

	if blocked != 7 {
		t.Fatalf("blocked %d of 10 with a rotating header, want 7: the header must not "+
			"buy a fresh bucket", blocked)
	}
}
