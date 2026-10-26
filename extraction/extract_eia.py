"""Generic EIA API v2 extractor.

Pulls every page of a route and saves it as newline-delimited JSON (JSONL),
which BigQuery can load natively. Works for any EIA v2 data route, so the same
script serves the US hourly grid data and the international (Morocco) data.

Examples
--------
# US hourly generation by fuel type, last 2 days, two regions
python extract_eia.py \
    --route electricity/rto/fuel-type-data \
    --dataset us_fuel_type_hourly \
    --frequency hourly \
    --start 2026-10-23T00 --end 2026-10-25T00 \
    --facet respondent=CISO --facet respondent=ERCO

# International data (find the real route/facets with explore_eia_routes.py first)
python extract_eia.py \
    --route international \
    --dataset intl_electricity_annual \
    --frequency annual \
    --facet countryRegionId=MAR \
    --start 2010 --end 2024
"""

import argparse
import json
import logging
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import requests

try:  # optional: load EIA_API_KEY from a local .env file
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:
    pass

BASE_URL = "https://api.eia.gov/v2"
PAGE_SIZE = 5000  # EIA's maximum rows per request
log = logging.getLogger("eia_extract")


def get_json(url: str, params: list, retries: int = 4, backoff: float = 2.0) -> dict:
    """GET with retries. Never logs the URL, because it contains the API key."""
    for attempt in range(1, retries + 1):
        try:
            resp = requests.get(url, params=params, timeout=60)
            if resp.status_code == 200:
                return resp.json()
            if resp.status_code in (429, 500, 502, 503, 504):
                log.warning("HTTP %s (attempt %d/%d)", resp.status_code, attempt, retries)
            else:  # 400/401/403/404: retrying will not help
                raise SystemExit(f"EIA API error: HTTP {resp.status_code}: {resp.text[:300]}")
        except (requests.ConnectionError, requests.Timeout) as exc:
            log.warning("%s (attempt %d/%d)", type(exc).__name__, attempt, retries)
        time.sleep(backoff**attempt)
    raise SystemExit(f"Giving up after {retries} attempts")


def build_params(api_key, frequency, facets, start, end, offset):
    params = [
        ("api_key", api_key),
        ("data[0]", "value"),
        ("sort[0][column]", "period"),
        ("sort[0][direction]", "asc"),
        ("offset", offset),
        ("length", PAGE_SIZE),
    ]
    if frequency:
        params.append(("frequency", frequency))
    if start:
        params.append(("start", start))
    if end:
        params.append(("end", end))
    for key, value in facets:
        params.append((f"facets[{key}][]", value))
    return params


def fetch_pages(route, api_key, frequency, facets, start, end):
    """Yield (page_number, rows) until all rows are fetched."""
    url = f"{BASE_URL}/{route.strip('/')}/data/"
    offset, page = 0, 0
    while True:
        payload = get_json(url, build_params(api_key, frequency, facets, start, end, offset))
        response = payload.get("response", {})
        rows = response.get("data", [])
        total = int(response.get("total", 0))
        log.info("page %d: %d rows (offset %d of %d)", page, len(rows), offset, total)
        if rows:
            yield page, rows
        offset += PAGE_SIZE
        page += 1
        if offset >= total or not rows:
            break


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("--route", required=True, help="e.g. electricity/rto/fuel-type-data")
    parser.add_argument("--dataset", required=True, help="folder name for the raw output")
    parser.add_argument("--frequency", help="hourly, daily, monthly, annual...")
    parser.add_argument("--start", help="e.g. 2026-10-23T00 (hourly) or 2010 (annual)")
    parser.add_argument("--end")
    parser.add_argument("--facet", action="append", default=[], help="key=value, repeatable")
    parser.add_argument("--out-dir", default="data/raw")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

    api_key = os.environ.get("EIA_API_KEY")
    if not api_key:
        raise SystemExit("Set EIA_API_KEY (environment variable or .env file)")

    facets = []
    for item in args.facet:
        if "=" not in item:
            raise SystemExit(f"--facet must look like key=value, got: {item}")
        key, value = item.split("=", 1)
        facets.append((key, value))

    now = datetime.now(timezone.utc)
    out_path = Path(args.out_dir) / args.dataset / f"extract_date={now:%Y-%m-%d}"
    out_path.mkdir(parents=True, exist_ok=True)

    total_rows = 0
    for page, rows in fetch_pages(args.route, api_key, args.frequency, facets, args.start, args.end):
        file = out_path / f"{now:%H%M%S}_page_{page:04d}.jsonl"
        with file.open("w", encoding="utf-8") as fh:
            for row in rows:
                row["_extracted_at"] = now.isoformat()
                fh.write(json.dumps(row) + "\n")
        total_rows += len(rows)

    if total_rows == 0:
        raise SystemExit("No rows returned. Check route, facets and date range.")
    log.info("Done: %d rows written to %s", total_rows, out_path)


if __name__ == "__main__":
    sys.exit(main())
