# Voca backend tasks.
#
# The server entrypoint is cmd/api (ARCHITECTURE.md section 28). There is deliberately
# no cmd/server: competing entrypoints drift apart.

.PHONY: run build test lint fmt vet tidy help

## run: start the API server (PORT from .env, default 8082)
run:
	go run ./cmd/api

## build: compile all packages
build:
	go build ./...

## test: run the test suite
test:
	go test ./...

## fmt: format all Go files
fmt:
	gofmt -w .

## vet: run go vet
vet:
	go vet ./...

## tidy: sync go.mod and go.sum with the code
tidy:
	go mod tidy

## lint: formatting check plus vet (golangci-lint arrives with CI)
lint:
	@test -z "$$(gofmt -l .)" || (echo "unformatted files:"; gofmt -l .; exit 1)
	go vet ./...

## help: list targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## //'
