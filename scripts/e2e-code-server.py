#!/usr/bin/env python3
"""Serves the newest development verification code to the end-to-end test.

Why this exists. The app asks the backend for a fresh code the moment an address is
submitted, so a code fetched before the test starts is already stale by the time the code
screen appears. The test therefore has to read the code DURING the run, and a sandboxed
simulator app cannot read a file on the host.

This is a host-side helper, started and stopped by scripts/e2e-mobile.sh. It binds to
localhost only, it is never part of the backend, and it exists solely so an automated test
can do what a person does by opening the outbox file.
"""

import http.server
import os
import re
import sys
import urllib.parse

OUTBOX = sys.argv[1]
PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 8099

CODE_LINE = re.compile(r"^\s*code\s*=\s*(\d+)\s*$")
SAFE = re.compile(r"[^A-Za-z0-9.-]")


def newest_code(email: str) -> str | None:
    """Returns the code from the most recent signup message for this address."""
    wanted = SAFE.sub("_", email)
    candidates = [
        os.path.join(OUTBOX, name)
        for name in os.listdir(OUTBOX)
        if wanted in name and "signup_code" in name
    ]
    if not candidates:
        return None
    newest = max(candidates, key=os.path.getmtime)
    with open(newest, encoding="utf-8") as handle:
        for line in handle:
            match = CODE_LINE.match(line)
            if match:
                return match.group(1)
    return None


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):  # noqa: N802 - required by the base class
        query = urllib.parse.urlparse(self.path).query
        email = urllib.parse.parse_qs(query).get("email", [""])[0]

        code = newest_code(email) if email else None
        body = (code or "").encode()

        self.send_response(200 if code else 404)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_args):
        """Silent: the code must not reach a terminal or a log file."""


if __name__ == "__main__":
    http.server.HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
