// Package apperr is the single error taxonomy for the API.
//
// Services return an AppError; exactly one mapping turns it into an HTTP response, so
// there is one place in the codebase where an error becomes a status code.
//
// Database and provider errors are WRAPPED, never surfaced. A client must never see a
// constraint name, a table name, a driver message, a vendor payload, a file path, or a
// stack trace. Internal detail goes to the log with the request ID; the client gets a
// stable code and that ID (ARCHITECTURE.md 19).
package apperr

import (
	"errors"
	"fmt"
	"net/http"
)

// Code is a stable, machine-readable error identifier. Clients switch on this value and
// localize from it, which is why the message text can stay English and a second UI
// language costs no backend work (ARCHITECTURE.md 19.1).
type Code string

const (
	// Validation and request shape.
	CodeValidation    Code = "VALIDATION_ERROR"
	CodeInvalidBody   Code = "INVALID_BODY"
	CodePayloadTooBig Code = "PAYLOAD_TOO_LARGE"

	// Authentication.
	CodeUnauthenticated Code = "UNAUTHENTICATED"
	CodeTokenExpired    Code = "TOKEN_EXPIRED"

	// Authorization. These two are deliberately distinct: one means "come back tomorrow
	// or upgrade", the other means "not in your plan". The clients show different screens,
	// so the API must not collapse them (ARCHITECTURE.md 19.2).
	CodeForbidden       Code = "FORBIDDEN"
	CodePremiumRequired Code = "PREMIUM_REQUIRED"
	CodeUsageLimit      Code = "USAGE_LIMIT_REACHED"

	// Resource.
	CodeNotFound Code = "NOT_FOUND"
	CodeConflict Code = "CONFLICT"

	// Throttling.
	CodeRateLimited Code = "RATE_LIMITED"

	// Upstream providers.
	CodeProviderError       Code = "PROVIDER_ERROR"
	CodeProviderUnavailable Code = "PROVIDER_UNAVAILABLE"
	CodeProviderTimeout     Code = "PROVIDER_TIMEOUT"

	// Catch-all.
	CodeInternal Code = "INTERNAL_ERROR"
)

// AppError carries everything needed to answer a client safely.
//
// Message is client-safe text. Err is the internal cause and is NEVER serialized.
type AppError struct {
	Code       Code
	HTTPStatus int
	Message    string
	Details    map[string]any
	Err        error
}

func (e *AppError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%s: %s: %v", e.Code, e.Message, e.Err)
	}
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

// Unwrap exposes the internal cause to errors.Is and errors.As, never to a client.
func (e *AppError) Unwrap() error { return e.Err }

// WithDetails attaches structured, client-safe context.
func (e *AppError) WithDetails(d map[string]any) *AppError {
	e.Details = d
	return e
}

// Wrap attaches an internal cause for logging.
func (e *AppError) Wrap(err error) *AppError {
	e.Err = err
	return e
}

func newError(code Code, status int, message string) *AppError {
	return &AppError{Code: code, HTTPStatus: status, Message: message}
}

// Constructors. Each fixes the status code so it cannot be chosen inconsistently at
// different call sites.

func Validation(message string) *AppError {
	return newError(CodeValidation, http.StatusBadRequest, message)
}

func InvalidBody(message string) *AppError {
	return newError(CodeInvalidBody, http.StatusBadRequest, message)
}

func Unauthenticated(message string) *AppError {
	return newError(CodeUnauthenticated, http.StatusUnauthorized, message)
}

func Forbidden(message string) *AppError {
	return newError(CodeForbidden, http.StatusForbidden, message)
}

func NotFound(message string) *AppError {
	return newError(CodeNotFound, http.StatusNotFound, message)
}

func Conflict(message string) *AppError {
	return newError(CodeConflict, http.StatusConflict, message)
}

func RateLimited(message string) *AppError {
	return newError(CodeRateLimited, http.StatusTooManyRequests, message)
}

func ProviderUnavailable(message string) *AppError {
	return newError(CodeProviderUnavailable, http.StatusServiceUnavailable, message)
}

// Internal builds a 500. The caller passes the real cause for the log; the client only
// ever sees the generic message.
func Internal(err error) *AppError {
	return &AppError{
		Code:       CodeInternal,
		HTTPStatus: http.StatusInternalServerError,
		Message:    "An unexpected error occurred.",
		Err:        err,
	}
}

// From converts any error into an AppError. An error that is not already one is treated
// as internal, which is the safe default: unknown errors never leak their text.
func From(err error) *AppError {
	if err == nil {
		return nil
	}
	var appErr *AppError
	if errors.As(err, &appErr) {
		return appErr
	}
	return Internal(err)
}
