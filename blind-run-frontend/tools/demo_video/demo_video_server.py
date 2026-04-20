#!/usr/bin/env python3

from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlparse
import json
import sys


ROOT = Path(__file__).resolve().parents[2]


class DemoVideoRequestHandler(SimpleHTTPRequestHandler):
    def translate_path(self, path: str) -> str:
        parsed = urlparse(path)
        relative = Path(unquote(parsed.path.lstrip("/")))
        resolved = (ROOT / relative).resolve()
        if not str(resolved).startswith(str(ROOT)):
            return str(ROOT)
        return str(resolved)

    def do_POST(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path != "/__upload__":
            self.send_error(HTTPStatus.NOT_FOUND, "Unknown upload endpoint")
            return

        query = parse_qs(parsed.query)
        relative_path = query.get("path", [None])[0]
        if not relative_path:
          self.send_error(HTTPStatus.BAD_REQUEST, "Missing path")
          return

        destination = (ROOT / relative_path).resolve()
        if not str(destination).startswith(str(ROOT)):
            self.send_error(HTTPStatus.FORBIDDEN, "Destination outside workspace")
            return

        content_length = int(self.headers.get("Content-Length", "0"))
        payload = self.rfile.read(content_length)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(payload)

        body = json.dumps({
            "saved": str(destination),
            "bytes": len(payload),
        }).encode("utf-8")
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main() -> int:
    port = 4173
    if len(sys.argv) > 1:
        port = int(sys.argv[1])

    with ThreadingHTTPServer(("127.0.0.1", port), DemoVideoRequestHandler) as server:
        print(f"Serving demo-video workspace root at http://127.0.0.1:{port}")
        server.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
