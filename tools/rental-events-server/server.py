#!/usr/bin/env python3
"""Tiny shared event list for Icy Strait customer + crew apps.

Not CloudKit. HTTP JSON so the shipping customer TestFlight build does not
need a new iCloud entitlement. Run on a Mac/Pi on the lot, or any host both
phones can reach.

    python3 tools/rental-events-server/server.py --port 8787
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import urlparse
from uuid import uuid4

ISO = "%Y-%m-%dT%H:%M:%S%z"


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def default_dennis() -> dict[str, Any]:
    return {
        "id": "00000000-0000-4000-8000-000000005152",
        "displayName": "Front desk / Dennis",
        "phoneE164": "+19075005152",
        "emails": ["maddasstoner@yahoo.com", "f.vhappytimes@gmail.com"],
        "isActive": True,
        "updatedAt": "2026-01-01T00:00:00Z",
    }


class LotStore:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.data = {
            "events": [],
            "alerts": [],
            "staff": [default_dennis()],
            "revisedAt": utc_now(),
        }
        if path.exists():
            try:
                loaded = json.loads(path.read_text())
                self.data.update({k: loaded.get(k, self.data[k]) for k in self.data})
            except json.JSONDecodeError:
                pass
        if not self.data["staff"]:
            self.data["staff"] = [default_dennis()]
        self.save()

    def save(self) -> None:
        self.data["revisedAt"] = utc_now()
        self.path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self.path.with_suffix(".tmp")
        tmp.write_text(json.dumps(self.data, indent=2, sort_keys=True))
        tmp.replace(self.path)

    def snapshot(self) -> dict[str, Any]:
        return {
            "events": self.data["events"],
            "alerts": self.data["alerts"],
            "staff": self.data["staff"],
            "revisedAt": self.data["revisedAt"],
        }

    def add_event(self, event: dict[str, Any]) -> dict[str, Any]:
        event.setdefault("id", str(uuid4()))
        self.data["events"] = [e for e in self.data["events"] if e.get("id") != event["id"]]
        self.data["events"].append(event)
        self.save()
        return event

    def add_alert(self, alert: dict[str, Any]) -> dict[str, Any]:
        alert.setdefault("id", str(uuid4()))
        self.data["alerts"] = [a for a in self.data["alerts"] if a.get("id") != alert["id"]]
        self.data["alerts"].append(alert)
        self.save()
        return alert

    def upsert_staff(self, member: dict[str, Any]) -> dict[str, Any]:
        member.setdefault("id", str(uuid4()))
        staff = [s for s in self.data["staff"] if s.get("id") != member["id"]]
        staff.append(member)
        self.data["staff"] = staff
        self.save()
        return member

    def replace_staff(self, members: list[dict[str, Any]]) -> list[dict[str, Any]]:
        self.data["staff"] = members
        self.save()
        return members


class Handler(BaseHTTPRequestHandler):
    store: LotStore

    def log_message(self, fmt: str, *args: Any) -> None:
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def _send(self, code: int, payload: Any) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self) -> Any:
        length = int(self.headers.get("Content-Length", "0") or "0")
        raw = self.rfile.read(length) if length else b"{}"
        return json.loads(raw.decode("utf-8") or "{}")

    def do_OPTIONS(self) -> None:  # noqa: N802
        self._send(200, {"ok": True})

    def do_GET(self) -> None:  # noqa: N802
        path = urlparse(self.path).path.rstrip("/") or "/"
        if path in ("/", "/health"):
            self._send(200, {"ok": True, "service": "icy-strait-lot-events", "revisedAt": self.store.data["revisedAt"]})
            return
        if path == "/snapshot":
            self._send(200, self.store.snapshot())
            return
        if path == "/events":
            self._send(200, self.store.data["events"])
            return
        if path == "/alerts":
            self._send(200, self.store.data["alerts"])
            return
        if path == "/staff":
            self._send(200, self.store.data["staff"])
            return
        self._send(404, {"error": "not found"})

    def do_POST(self) -> None:  # noqa: N802
        path = urlparse(self.path).path.rstrip("/")
        payload = self._read_json()
        if path == "/events":
            self._send(201, self.store.add_event(payload))
            return
        if path == "/alerts":
            self._send(201, self.store.add_alert(payload))
            return
        self._send(404, {"error": "not found"})

    def do_PUT(self) -> None:  # noqa: N802
        path = urlparse(self.path).path.rstrip("/")
        payload = self._read_json()
        if path == "/staff":
            if not isinstance(payload, list):
                self._send(400, {"error": "staff must be an array"})
                return
            self._send(200, self.store.replace_staff(payload))
            return
        match = re.fullmatch(r"/staff/([0-9a-fA-F-]+)", path)
        if match:
            payload["id"] = match.group(1)
            self._send(200, self.store.upsert_staff(payload))
            return
        self._send(404, {"error": "not found"})


def main() -> int:
    parser = argparse.ArgumentParser(description="Icy Strait shared rental event pipe")
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8787)
    parser.add_argument(
        "--data",
        default=os.environ.get("ICY_STRAIT_LOT_DATA", str(Path(__file__).with_name("lot-events.json"))),
    )
    args = parser.parse_args()
    store = LotStore(Path(args.data))
    Handler.store = store
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"Icy Strait lot events on http://{args.host}:{args.port}  data={store.path}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nstopped", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
