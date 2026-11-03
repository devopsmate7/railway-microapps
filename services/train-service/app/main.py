from fastapi import FastAPI, HTTPException, Query

app = FastAPI(title="train-service")

STATIONS = [
    "Hyderabad",
    "Bengaluru",
    "Chennai",
    "Mumbai",
    "New Delhi",
    "Kolkata",
    "Pune",
    "Vijayawada",
    "Tirupati",
    "Visakhapatnam",
]

# (train type, departure time, fare multiplier)
SERVICES = [
    ("Express", "06:15", 1.0),
    ("Superfast", "13:40", 1.4),
    ("Night Mail", "21:05", 0.8),
]


def _validate(from_station: str, to_station: str) -> None:
    if from_station not in STATIONS or to_station not in STATIONS:
        raise HTTPException(status_code=400, detail="Unknown station")
    if from_station == to_station:
        raise HTTPException(status_code=400, detail="From and To must be different stations")


def _trains_for(from_station: str, to_station: str) -> list[dict]:
    a, b = STATIONS.index(from_station), STATIONS.index(to_station)
    distance = abs(a - b) + 1
    base_number = 12000 + a * 100 + b * 10
    return [
        {
            "number": str(base_number + i),
            "name": f"{from_station} - {to_station} {kind}",
            "departs": departs,
            "fare": int(250 * distance * multiplier),
        }
        for i, (kind, departs, multiplier) in enumerate(SERVICES)
    ]


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/api/trains/stations")
def stations():
    return STATIONS


@app.get("/api/trains")
def search_trains(
    from_station: str = Query(..., alias="from"),
    to_station: str = Query(..., alias="to"),
):
    _validate(from_station, to_station)
    return _trains_for(from_station, to_station)


@app.get("/api/trains/{number}")
def get_train(
    number: str,
    from_station: str = Query(..., alias="from"),
    to_station: str = Query(..., alias="to"),
):
    _validate(from_station, to_station)
    for train in _trains_for(from_station, to_station):
        if train["number"] == number:
            return train
    raise HTTPException(status_code=404, detail="Train not found on this route")
