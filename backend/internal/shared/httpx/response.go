// Package httpx holds the standard API response envelope.
//
//	success: {"data": ..., "meta": {...}}
//	error:   {"error": {"code", "message", "details", "request_id"}}
//
// "code" is a stable machine-readable string the client switches on. The app localizes
// by CODE, not by message, which is why the message can stay English and a second UI
// language costs no backend work (ARCHITECTURE.md 19.1).
package httpx

import (
	"github.com/gin-gonic/gin"

	"github.com/samandar-hodiev/voca/backend/internal/shared/apperr"
)

// ContextRequestIDKey is where middleware stores the per-request identifier.
const ContextRequestIDKey = "request_id"

// Meta carries response metadata such as the request ID and pagination cursors.
type Meta struct {
	RequestID string `json:"request_id,omitempty"`
}

// Envelope is the success response shape.
type Envelope struct {
	Data any   `json:"data"`
	Meta *Meta `json:"meta,omitempty"`
}

// ErrorBody describes a failure in terms the client can act on.
type ErrorBody struct {
	Code      string         `json:"code"`
	Message   string         `json:"message"`
	Details   map[string]any `json:"details,omitempty"`
	RequestID string         `json:"request_id,omitempty"`
}

// ErrorEnvelope is the error response shape.
type ErrorEnvelope struct {
	Error ErrorBody `json:"error"`
}

// RequestID returns the identifier attached to this request, if any.
func RequestID(c *gin.Context) string {
	if v, ok := c.Get(ContextRequestIDKey); ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}

// OK writes a successful response.
func OK(c *gin.Context, status int, data any) {
	env := Envelope{Data: data}
	if id := RequestID(c); id != "" {
		env.Meta = &Meta{RequestID: id}
	}
	c.JSON(status, env)
}

// Fail writes an error response and stops the handler chain.
//
// Never pass an internal message here: constraint names, driver errors, vendor payloads
// and stack traces go to the log, not to the client (ARCHITECTURE.md 19.3).
func Fail(c *gin.Context, status int, code, message string) {
	c.AbortWithStatusJSON(status, ErrorEnvelope{Error: ErrorBody{
		Code:      code,
		Message:   message,
		RequestID: RequestID(c),
	}})
}

// FailWith renders an AppError. This is the ONE place a domain error becomes an HTTP
// response, so status codes cannot drift between call sites (ARCHITECTURE.md 19.3).
//
// Only client-safe fields are serialized. The wrapped internal cause is never written to
// the response; it belongs in the log, alongside the request ID.
func FailWith(c *gin.Context, err error) {
	appErr := apperr.From(err)
	if appErr == nil {
		return
	}

	body := ErrorEnvelope{Error: ErrorBody{
		Code:      string(appErr.Code),
		Message:   appErr.Message,
		Details:   appErr.Details,
		RequestID: RequestID(c),
	}}

	c.AbortWithStatusJSON(appErr.HTTPStatus, body)
}
