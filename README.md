# Industrial Energy Pipeline (US + Morocco)

End-to-end data pipeline on EIA energy data:

- **US hourly grid data**: electricity generation by region and fuel type (scheduled, hourly grain)
- **International data (Morocco + other countries)**: annual generation, consumption, imports/exports

Business question: *How is the electricity generation mix changing by fuel type, and how does
Morocco's mix compare with the US?*

## Architecture (target)

EIA API -> Python extractor (Docker) -> GCS (raw JSONL) -> orchestrator (Kestra/Airflow)
-> BigQuery (raw) -> dbt (staging -> marts) -> Looker Studio dashboard.
Infrastructure (bucket, dataset) provisioned with Terraform.

## Progress

- [x] Step 1: local extraction scripts
- [ ] Step 2: Dockerize extractor
- [ ] Step 3: Terraform + GCS upload
- [ ] Step 4: Orchestration + BigQuery load
- [ ] Step 5: dbt models + tests
- [ ] Step 6: Dashboard + final README

## Run Step 1

```bash
cd extraction
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp ../.env.example ../.env      # then paste your EIA key into .env (never commit it)

# 1. Discover routes and facets
python explore_eia_routes.py
python explore_eia_routes.py electricity/rto/fuel-type-data
python explore_eia_routes.py international

# 2. Small US test (2 regions, 2 days)
python extract_eia.py --route electricity/rto/fuel-type-data \
    --dataset us_fuel_type_hourly --frequency hourly \
    --start 2026-10-23T00 --end 2026-10-25T00 \
    --facet respondent=CISO --facet respondent=ERCO
```

Raw output lands in `extraction/data/raw/<dataset>/extract_date=YYYY-MM-DD/*.jsonl`.
