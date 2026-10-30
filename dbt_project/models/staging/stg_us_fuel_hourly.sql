-- One row per balancing authority / fuel code / hour (UTC).
-- Raw column names contain hyphens, so they need backticks.
-- Re-extracted files create duplicate rows; keep the most recently extracted one.

with source as (

    select *
    from {{ source('eia_raw', 'us_fuel_type_hourly') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by respondent, fueltype, period
        order by _extracted_at desc
    ) = 1

)

select
    concat(respondent, '|', fueltype, '|', period) as generation_key,
    parse_timestamp('%Y-%m-%dT%H', period) as hour_utc,
    respondent as region_code,
    `respondent-name` as region_name,
    fueltype as fuel_code,
    `type-name` as fuel_name,
    cast(value as float64) as generation_mwh,
    `value-units` as value_units,
    _extracted_at as extracted_at
from deduplicated
