import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from contextlib import asynccontextmanager
from datetime import date, datetime, timezone
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError, EndpointConnectionError
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

TABLE_NAME = os.environ.get("TABLE_NAME", "railway-local-bookings")
REGION = os.environ.get("AWS_REGION", "ap-south-1")
# Empty means real AWS DynamoDB (credentials come from EKS Pod Identity).
DYNAMODB_ENDPOINT_URL = os.environ.get("DYNAMODB_ENDPOINT_URL") or None
TRAIN_SERVICE_URL = os.environ.get("TRAIN_SERVICE_URL", "http://train-service:8000")

dynamodb = boto3.resource("dynamodb", region_name=REGION, endpoint_url=DYNAMODB_ENDPOINT_URL)
table = dynamodb.Table(TABLE_NAME)


def _ensure_local_table() -> None:
    """On AWS, Terraform owns the table. Only DynamoDB Local needs it created here."""
    if not DYNAMODB_ENDPOINT_URL:
        return
    for _ in range(15):
        try:
            dynamodb.create_table(
                TableName=TABLE_NAME,
                KeySchema=[{"AttributeName": "pnr", "KeyType": "HASH"}],
                AttributeDefinitions=[{"AttributeName": "pnr", "AttributeType": "S"}],
                BillingMode="PAY_PER_REQUEST",
            )
            return
        except ClientError as err:
            if err.response["Error"]["Code"] == "ResourceInUseException":
                return
            raise
        except EndpointConnectionError:
            time.sleep(2)
    raise RuntimeError("DynamoDB Local is not reachable")


@asynccontextmanager
async def lifespan(_: FastAPI):
    _ensure_local_table()
    yield


app = FastAPI(title="booking-service", lifespan=lifespan)


class BookingRequest(BaseModel):
    name: str = Field(min_length=2, max_length=60)
    from_station: str
    to_station: str
    travel_date: date
    train_number: str


def _lookup_train(number: str, from_station: str, to_station: str) -> dict:
    query = urllib.parse.urlencode({"from": from_station, "to": to_station})
    url = f"{TRAIN_SERVICE_URL}/api/trains/{urllib.parse.quote(number)}?{query}"
    try:
        with urllib.request.urlopen(url, timeout=3) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as err:
        if err.code in (400, 404):
            raise HTTPException(status_code=400, detail="This train is not available on that route")
        raise HTTPException(status_code=502, detail="train-service returned an error")
    except urllib.error.URLError:
        raise HTTPException(status_code=503, detail="train-service is unreachable")


def _clean(item: dict) -> dict:
    return {k: int(v) if isinstance(v, Decimal) else v for k, v in item.items()}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/api/bookings", status_code=201)
def create_booking(req: BookingRequest):
    if req.from_station == req.to_station:
        raise HTTPException(status_code=400, detail="From and To must be different stations")
    if req.travel_date < date.today():
        raise HTTPException(status_code=400, detail="Travel date cannot be in the past")

    train = _lookup_train(req.train_number, req.from_station, req.to_station)
    item = {
        "pnr": uuid.uuid4().hex[:10].upper(),
        "name": req.name.strip(),
        "from_station": req.from_station,
        "to_station": req.to_station,
        "travel_date": req.travel_date.isoformat(),
        "train_number": train["number"],
        "train_name": train["name"],
        "departs": train["departs"],
        "fare": train["fare"],
        "status": "CONFIRMED",
        "created_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }
    table.put_item(Item=item)
    return item


@app.get("/api/bookings")
def list_bookings():
    items = table.scan(Limit=100).get("Items", [])
    items.sort(key=lambda i: i.get("created_at", ""), reverse=True)
    return [_clean(i) for i in items[:20]]


@app.get("/api/bookings/{pnr}")
def get_booking(pnr: str):
    item = table.get_item(Key={"pnr": pnr.upper()}).get("Item")
    if not item:
        raise HTTPException(status_code=404, detail="PNR not found")
    return _clean(item)
