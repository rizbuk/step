import json
import os
import socket
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.getenv("PORT", "8080"))
APP_NAME = os.getenv("APP_NAME", "0root-demo-app")
APP_VERSION = os.getenv("APP_VERSION", "dev")


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _send(self, status, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path in ("/", "/healthz", "/readyz"):
            self._send(
                200,
                {
                    "status": "ok0root1",
                    "app": APP_NAME,
                    "version": APP_VERSION,
                    "hostname": socket.gethostname(),
                    "time": datetime.now(timezone.utc).isoformat(),
                },
            )
        else:
            self._send(404, {"status": "not found", "path": self.path})

    def log_message(self, fmt, *args):
        print("%s - %s" % (self.address_string(), fmt % args), flush=True)


if __name__ == "__main__":
    print(f"{APP_NAME} listening on 0.0.0.0:{PORT}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
