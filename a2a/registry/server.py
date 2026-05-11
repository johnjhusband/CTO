#!/usr/bin/env python3
"""Minimal A2A registry for CTO v1.0.
Serves Agent Cards over HTTP. Full a2a-sdk integration follows in v1.1.
"""
import json
import os
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler

CARDS_DIR = os.path.join(os.path.dirname(__file__), "cards")
AUDIT_LOG = os.path.join(os.path.dirname(__file__), "audit.log")
PORT = int(os.environ.get("A2A_REGISTRY_PORT", "9000"))

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/cards":
            cards = {}
            for fn in os.listdir(CARDS_DIR):
                if fn.endswith(".json"):
                    with open(os.path.join(CARDS_DIR, fn)) as f:
                        cards[fn[:-5]] = json.load(f)
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(cards).encode())
        elif self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"status":"ok"}')
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, fmt, *args):
        with open(AUDIT_LOG, "a") as f:
            f.write(f"{self.address_string()} {fmt % args}\n")

if __name__ == "__main__":
    HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
