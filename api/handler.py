"""Quiz stats API for Pocket Orrery.

Runs on AWS Lambda behind an API Gateway HTTP API (payload format 2.0).

  GET  /stats  -> {"counts": {"mercury": 12, ...}}
  POST /vote   -> body {"planet": "saturn"}; adds one vote, returns the new counts

Votes live in one DynamoDB table with one item per planet: {"id": "saturn", "votes": 12}.
CORS is handled by API Gateway, so responses here carry no CORS headers.
"""

import base64
import json
import os

PLANETS = ("mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune")

_table = None


def table():
    # Created lazily so tests can swap in a fake before the first call. boto3 is
    # imported here too: Lambda ships it, but the unit tests never need it.
    global _table
    if _table is None:
        import boto3

        _table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])
    return _table


def respond(status, body):
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json", "cache-control": "no-store"},
        "body": json.dumps(body),
    }


def counts():
    # Eight tiny items, so a single Scan is cheaper and simpler than BatchGetItem.
    items = table().scan(ProjectionExpression="id, votes").get("Items", [])
    found = {item["id"]: int(item.get("votes", 0)) for item in items if item.get("id") in PLANETS}
    return {planet: found.get(planet, 0) for planet in PLANETS}


def parse_body(event):
    raw = event.get("body") or ""
    if event.get("isBase64Encoded"):
        raw = base64.b64decode(raw).decode("utf-8")
    if len(raw) > 1024:
        raise ValueError("body too large")
    data = json.loads(raw or "{}")
    if not isinstance(data, dict):
        raise ValueError("body must be a JSON object")
    return data


def vote(event):
    try:
        planet = str(parse_body(event).get("planet", "")).lower()
    except (ValueError, UnicodeDecodeError):
        return respond(400, {"error": "Send JSON like {\"planet\": \"saturn\"}."})
    if planet not in PLANETS:
        return respond(400, {"error": f"planet must be one of: {', '.join(PLANETS)}"})
    table().update_item(
        Key={"id": planet},
        UpdateExpression="ADD votes :one",
        ExpressionAttributeValues={":one": 1},
    )
    print(json.dumps({"event": "vote", "planet": planet}))
    return respond(200, {"counts": counts()})


ROUTES = {
    "GET /stats": lambda event: respond(200, {"counts": counts()}),
    "POST /vote": vote,
}


def lambda_handler(event, context):
    route = ROUTES.get(event.get("routeKey", ""))
    if route is None:
        return respond(404, {"error": "Not found"})
    try:
        return route(event)
    except Exception as exc:  # log and hide internals from the caller
        print(json.dumps({"event": "error", "route": event.get("routeKey"), "error": repr(exc)}))
        return respond(500, {"error": "Something went wrong. Try again in a moment."})
