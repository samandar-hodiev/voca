package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

const allowedOrigin = "https://admin.voca.uz"

func newCORSRouter(origins []string) *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.Use(CORS(CORSConfig{AllowedOrigins: origins}))
	r.GET("/x", func(c *gin.Context) { c.String(http.StatusOK, "ok") })
	return r
}

func do(r *gin.Engine, method, origin string) *httptest.ResponseRecorder {
	req := httptest.NewRequest(method, "/x", nil)
	if origin != "" {
		req.Header.Set("Origin", origin)
	}
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	return w
}

func TestCORS_AllowedOriginGetsHeaders(t *testing.T) {
	w := do(newCORSRouter([]string{allowedOrigin}), http.MethodGet, allowedOrigin)

	if got := w.Header().Get("Access-Control-Allow-Origin"); got != allowedOrigin {
		t.Errorf("Allow-Origin = %q, want %q", got, allowedOrigin)
	}
	if got := w.Header().Get("Vary"); got != "Origin" {
		t.Errorf("Vary = %q, want Origin so caches do not reuse across origins", got)
	}
}

// An unknown origin must receive NO CORS headers. The browser then refuses the response.
func TestCORS_UnknownOriginGetsNoHeaders(t *testing.T) {
	w := do(newCORSRouter([]string{allowedOrigin}), http.MethodGet, "https://evil.example")

	if got := w.Header().Get("Access-Control-Allow-Origin"); got != "" {
		t.Errorf("an unknown origin must get no Allow-Origin header, got %q", got)
	}
}

func TestCORS_PreflightFromAllowedOriginShortCircuits(t *testing.T) {
	w := do(newCORSRouter([]string{allowedOrigin}), http.MethodOptions, allowedOrigin)

	if w.Code != http.StatusNoContent {
		t.Errorf("preflight status = %d, want 204", w.Code)
	}
	if w.Header().Get("Access-Control-Allow-Methods") == "" {
		t.Error("preflight must advertise allowed methods")
	}
}

func TestCORS_PreflightFromUnknownOriginIsRefused(t *testing.T) {
	w := do(newCORSRouter([]string{allowedOrigin}), http.MethodOptions, "https://evil.example")

	if w.Code != http.StatusForbidden {
		t.Errorf("status = %d, want 403", w.Code)
	}
}

// An unconfigured deployment must permit nothing rather than everything.
func TestCORS_EmptyConfigAllowsNoOrigin(t *testing.T) {
	w := do(newCORSRouter(nil), http.MethodGet, allowedOrigin)

	if got := w.Header().Get("Access-Control-Allow-Origin"); got != "" {
		t.Errorf("empty config must allow no origin, got %q", got)
	}
}

// A same-origin request carries no Origin header and must pass through untouched.
func TestCORS_NoOriginHeaderPassesThrough(t *testing.T) {
	w := do(newCORSRouter([]string{allowedOrigin}), http.MethodGet, "")

	if w.Code != http.StatusOK || w.Body.String() != "ok" {
		t.Errorf("request without Origin must reach the handler, got %d %q", w.Code, w.Body.String())
	}
}
