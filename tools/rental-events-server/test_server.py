#!/usr/bin/env python3
"""Prove customer checkout/return events appear on the crew snapshot."""

from __future__ import annotations

import json
import tempfile
import threading
import time
import unittest
import urllib.error
import urllib.request
from http.server import ThreadingHTTPServer
from pathlib import Path

from server import Handler, LotStore


class LotPipeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        path = Path(self.tmp.name) / "lot.json"
        store = LotStore(path)
        store.data["events"] = []
        store.data["alerts"] = []
        store.save()
        Handler.store = store
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.port = self.server.server_address[1]
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        time.sleep(0.05)

    def tearDown(self) -> None:
        self.server.shutdown()
        self.tmp.cleanup()

    def url(self, path: str) -> str:
        return f"http://127.0.0.1:{self.port}{path}"

    def json_req(self, method: str, path: str, payload=None):
        data = None if payload is None else json.dumps(payload).encode()
        request = urllib.request.Request(self.url(path), data=data, method=method)
        request.add_header("Content-Type", "application/json")
        with urllib.request.urlopen(request, timeout=2) as response:
            return json.loads(response.read().decode())

    def test_dennis_is_seeded(self) -> None:
        snap = self.json_req("GET", "/snapshot")
        self.assertEqual(len(snap["staff"]), 1)
        dennis = snap["staff"][0]
        self.assertEqual(dennis["displayName"], "Front desk / Dennis")
        self.assertEqual(dennis["phoneE164"], "+19075005152")
        self.assertIn("maddasstoner@yahoo.com", dennis["emails"])
        self.assertIn("f.vhappytimes@gmail.com", dennis["emails"])

    def test_checkout_then_return_updates_board_copy(self) -> None:
        checkout = {
            "id": "11111111-1111-4111-8111-111111111111",
            "kind": "checkout",
            "scooterID": "IS-104",
            "scooterName": "Otter",
            "rentalID": "22222222-2222-4222-8222-222222222222",
            "renterDisplayName": "Walk-up guest",
            "startedAt": "2027-07-04T18:15:00Z",
            "endedAt": None,
            "occurredAt": "2027-07-04T18:15:00Z",
            "createdAt": "2027-07-04T18:15:00Z",
        }
        returned = {
            **checkout,
            "id": "33333333-3333-4333-8333-333333333333",
            "kind": "returned",
            "endedAt": "2027-07-04T19:05:00Z",
            "occurredAt": "2027-07-04T19:05:00Z",
        }
        self.json_req("POST", "/events", checkout)
        self.json_req(
            "POST",
            "/alerts",
            {
                "id": "44444444-4444-4444-8444-444444444444",
                "channel": "push",
                "title": "IS-104 Otter checked out",
                "body": "Walk-up guest took IS-104 Otter at Jul 4, 10:15 AM AK.",
                "scooterID": "IS-104",
                "scooterName": "Otter",
                "rentalID": checkout["rentalID"],
                "kindRaw": "checkout",
                "recipientName": "Crew phones",
                "recipientAddress": "apns-not-wired",
                "providerName": "CrewNotificationPayload",
                "sentAt": checkout["occurredAt"],
                "liveDelivery": False,
            },
        )
        snap = self.json_req("GET", "/snapshot")
        latest = [e for e in snap["events"] if e["scooterID"] == "IS-104"][-1]
        self.assertEqual(latest["kind"], "checkout")
        self.assertEqual(latest["scooterName"], "Otter")
        self.assertTrue(any("IS-104 Otter" in a["title"] for a in snap["alerts"]))

        self.json_req("POST", "/events", returned)
        self.json_req(
            "POST",
            "/alerts",
            {
                "id": "55555555-5555-4555-8555-555555555555",
                "channel": "sms",
                "title": "IS-104 Otter is back",
                "body": "Icy Strait: IS-104 Otter return. Walk-up guest checked in Jul 4, 11:05 AM AK.",
                "scooterID": "IS-104",
                "scooterName": "Otter",
                "rentalID": checkout["rentalID"],
                "kindRaw": "checkIn",
                "recipientName": "Front desk / Dennis",
                "recipientAddress": "+19075005152",
                "providerName": "MockStaffNotifier",
                "sentAt": returned["occurredAt"],
                "liveDelivery": False,
            },
        )
        snap = self.json_req("GET", "/snapshot")
        otter = [e for e in snap["events"] if e["scooterID"] == "IS-104"]
        self.assertEqual(otter[-1]["kind"], "returned")
        titles = [a["title"] for a in snap["alerts"]]
        self.assertTrue(any("IS-104 Otter checked out" in t for t in titles))
        self.assertTrue(any("IS-104 Otter is back" in t for t in titles))


if __name__ == "__main__":
    unittest.main()
