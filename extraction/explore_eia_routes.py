"""Explore the EIA API v2 route tree, so you can discover real routes and facets.

Usage
-----
python explore_eia_routes.py                       # top-level routes
python explore_eia_routes.py electricity           # children of 'electricity'
python explore_eia_routes.py electricity/rto/fuel-type-data   # facets, frequencies, columns
python explore_eia_routes.py international         # find the Morocco/country route

For a leaf route, the script also lists the values of each facet (for example
the country codes), so you can pick the right --facet for extract_eia.py.
"""

import os
import sys

import requests

try:
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:
    pass

BASE_URL = "https://api.eia.gov/v2"


def get(path: str, api_key: str) -> dict:
    resp = requests.get(f"{BASE_URL}/{path.strip('/')}/", params={"api_key": api_key}, timeout=60)
    if resp.status_code != 200:
        raise SystemExit(f"HTTP {resp.status_code}: {resp.text[:300]}")
    return resp.json().get("response", {})


def main():
    api_key = os.environ.get("EIA_API_KEY")
    if not api_key:
        raise SystemExit("Set EIA_API_KEY (environment variable or .env file)")

    route = sys.argv[1] if len(sys.argv) > 1 else ""
    meta = get(route, api_key)

    print(f"\nRoute: /{route}")
    print(f"Name: {meta.get('name')}")
    print(f"Description: {meta.get('description')}\n")

    routes = meta.get("routes")
    if routes:
        print("Child routes:")
        for child in routes:
            print(f"  {child['id']:<35} {child.get('name', '')}")
        return

    print("Frequencies:")
    for freq in meta.get("frequency", []):
        print(f"  {freq.get('id'):<10} {freq.get('description', '')} (format {freq.get('format')})")
    print(f"Date range: {meta.get('startPeriod')} to {meta.get('endPeriod')}\n")

    print("Data columns:")
    for col in meta.get("data", {}):
        print(f"  {col}")

    print("\nFacets (use with --facet key=value):")
    for facet in meta.get("facets", []):
        facet_id = facet["id"]
        print(f"  {facet_id}: {facet.get('description', '')}")
        values = get(f"{route}/facet/{facet_id}", api_key).get("facets", [])
        for value in values[:15]:
            print(f"      {value.get('id'):<12} {value.get('name', '')}")
        if len(values) > 15:
            print(f"      ... and {len(values) - 15} more")


if __name__ == "__main__":
    main()
