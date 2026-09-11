// middleware: rate limiting.
//
// A per-client token bucket, applied to the endpoints where guessing is the attack:
// signing in, asking for a code, and asking whether an address is registered.
//
// Why it exists at all. Once an endpoint tells a caller whether an address has an account,
// somebody can walk a list of addresses and learn who is a customer. Rate limiting does
// not make that impossible, it makes it slow enough to be useless: at ten attempts a
// minute, testing a million addresses takes two years.
//
// MVP uses an in-process bucket. The moment a second API instance runs, in-memory counters
// stop being CORRECT rather than merely approximate, because each instance would allow the
// full quota. That is the trigger for moving the counters to Redis
// (ARCHITECTURE.md 20.3, 33 Stage 2).
package middleware

import (
	"fmt"
	"sync"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/samandar-hodiev/voca/backend/internal/shared/apperr"
	"github.com/samandar-hodiev/voca/backend/internal/shared/httpx"
)

// RateLimitConfig describes one bucket.
type RateLimitConfig struct {
	// Requests allowed per Window. Zero or less disables the limiter, which is what a
	// test or a local run wants.
	Requests int

	Window time.Duration

	// Now is overridable so a test does not have to sleep. Nil means time.Now.
	Now func() time.Time
}

// RateLimit returns a middleware enforcing cfg per client address.
func RateLimit(cfg RateLimitConfig) gin.HandlerFunc {
	if cfg.Requests <= 0 || cfg.Window <= 0 {
		return func(c *gin.Context) { c.Next() }
	}
	now := cfg.Now
	if now == nil {
		now = time.Now
	}

	limiter := &ipLimiter{
		requests: cfg.Requests,
		window:   cfg.Window,
		now:      now,
		buckets:  map[string]*bucket{},
	}

	return func(c *gin.Context) {
		// ClientIP honours the proxy headers gin is configured to trust. Behind an
		// untrusted proxy every caller would share one bucket, which is why the trusted
		// proxy list matters as much as the limit itself.
		allowed, retryAfter := limiter.allow(c.ClientIP())
		if !allowed {
			c.Header("Retry-After", fmt.Sprint(int(retryAfter.Seconds()+0.999)))
			httpx.FailWith(c, apperr.RateLimited(
				"Juda ko‘p urinish. Biroz kutib qayta urinib ko‘ring."))
			c.Abort()
			return
		}
		c.Next()
	}
}

type bucket struct {
	count    int
	resetsAt time.Time
}

type ipLimiter struct {
	requests int
	window   time.Duration
	now      func() time.Time

	mu      sync.Mutex
	buckets map[string]*bucket

	// lastSweep bounds how often expired buckets are cleared out. Without it the map
	// grows with every address that ever called, which is a slow memory leak on a public
	// endpoint.
	lastSweep time.Time
}

// allow records an attempt and reports whether it may proceed.
func (l *ipLimiter) allow(key string) (bool, time.Duration) {
	l.mu.Lock()
	defer l.mu.Unlock()

	now := l.now()
	l.sweep(now)

	b, ok := l.buckets[key]
	if !ok || now.After(b.resetsAt) {
		l.buckets[key] = &bucket{count: 1, resetsAt: now.Add(l.window)}
		return true, 0
	}

	if b.count >= l.requests {
		return false, b.resetsAt.Sub(now)
	}

	b.count++
	return true, 0
}

// sweep drops buckets whose window has passed. Called under the lock.
func (l *ipLimiter) sweep(now time.Time) {
	if now.Sub(l.lastSweep) < l.window {
		return
	}
	l.lastSweep = now
	for key, b := range l.buckets {
		if now.After(b.resetsAt) {
			delete(l.buckets, key)
		}
	}
}
