{{
    config(
        materialized='table',
        partition_by={'field': 'hour_utc', 'data_type': 'timestamp', 'granularity': 'day'},
        cluster_by=['region_code', 'fuel_key']
    )
}}

-- Grain: one row per balancing authority / source fuel code / hour (US, EIA-930).
-- Several source codes can share one fuel_key (e.g. SUN and SNB are both solar),
-- so the grain keeps the source fuel_code. Partitioned by day, clustered by region and fuel.

select
    g.generation_key,
    g.hour_utc,
    g.region_code,
    g.region_name,
    g.fuel_code,
    m.fuel_key,
    g.generation_mwh,
    g.value_units,
    g.extracted_at
from {{ ref('stg_us_fuel_hourly') }} as g
left join {{ ref('fuel_type_mapping') }} as m
    on m.source_system = 'us'
    and m.source_code = g.fuel_code
