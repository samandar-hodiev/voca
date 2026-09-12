# Voca backend tasks.
#
# The server entrypoint is cmd/api (ARCHITECTURE.md section 28). There is deliberately
# no cmd/server: competing entrypoints drift apart.

.PHONY: run run-lan build test lint fmt vet tidy help migrate

## run: start the API server (PORT from .env, default 8082)
run:
	go run ./cmd/api

## run-lan: run from a fixed binary path, so a phone on the same Wi-Fi can reach the API
#
# `go run` compiles to a new path under /var/folders on every start, and the macOS firewall
# keys its rules on the executable path: each restart looks like an unknown program and
# incoming LAN connections are dropped, while localhost keeps working. A fixed path is
# allowed once and stays allowed. See docs/runbooks/local-development.md.
run-lan:
	go build -o bin/api ./cmd/api
	./bin/api

## migrate: apply pending database migrations
migrate:
	go run ./cmd/migrate

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
