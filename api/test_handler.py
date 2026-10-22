"""Unit tests for the quiz stats API. Run with: python -m unittest discover -s api"""

import base64
import json
import unittest

import handler


class FakeTable:
    """Just enough of the DynamoDB Table API for the handler."""

    def __init__(self):
        self.items = {}

    def scan(self, **_):
        return {"Items": [{"id": k, "votes": v} for k, v in self.items.items()]}

    def update_item(self, Key, ExpressionAttributeValues, **_):
        self.items[Key["id"]] = self.items.get(Key["id"], 0) + ExpressionAttributeValues[":one"]


def call(route, body=None, b64=False):
    event = {"routeKey": route}
    if body is not None:
        raw = json.dumps(body) if not isinstance(body, str) else body
        event["body"] = base64.b64encode(raw.encode()).decode() if b64 else raw
        event["isBase64Encoded"] = b64
    res = handler.lambda_handler(event, None)
    return res["statusCode"], json.loads(res["body"])


class HandlerTest(unittest.TestCase):
    def setUp(self):
        handler._table = FakeTable()

    def test_stats_start_at_zero_for_every_planet(self):
        status, body = call("GET /stats")
        self.assertEqual(status, 200)
        self.assertEqual(set(body["counts"]), set(handler.PLANETS))
        self.assertEqual(sum(body["counts"].values()), 0)

    def test_vote_counts_up(self):
        call("POST /vote", {"planet": "saturn"})
        status, body = call("POST /vote", {"planet": "Saturn"}, b64=True)
        self.assertEqual(status, 200)
        self.assertEqual(body["counts"]["saturn"], 2)

    def test_rejects_unknown_planet(self):
        status, _ = call("POST /vote", {"planet": "pluto"})
        self.assertEqual(status, 400)
        self.assertEqual(handler._table.items, {})

    def test_rejects_bad_json(self):
        self.assertEqual(call("POST /vote", "not json")[0], 400)
        self.assertEqual(call("POST /vote", "[1, 2]")[0], 400)

    def test_unknown_route(self):
        self.assertEqual(call("DELETE /vote")[0], 404)

    def test_internal_errors_are_hidden(self):
        class Broken(FakeTable):
            def scan(self, **_):
                raise RuntimeError("table on fire")

        handler._table = Broken()
        status, body = call("GET /stats")
        self.assertEqual(status, 500)
        self.assertNotIn("fire", body["error"])


if __name__ == "__main__":
    unittest.main()
