-- One row per country / year / product, unit BKWH only.
-- The raw table repeats each series in several units (BKWH, MTOE, QBTU, TJ),
-- so filtering to BKWH avoids counting every value more than once.
-- Re-extracted files create duplicate rows; keep the most recently extracted one.

with source as (

    select *
    from {{ source('eia_raw', 'intl_electricity_generation') }}
    where unit = 'BKWH'

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by countryRegionId, period, productId
        order by _extracted_at desc
    ) = 1

)

select
    concat(countryRegionId, '|', cast(period as string), '|', cast(productId as string)) as generation_key,
    countryRegionId as country_code,
    countryRegionName as country_name,
    cast(period as int64) as year,
    cast(productId as int64) as product_id,
    productName as product_name,
    cast(value as float64) as generation_twh,  -- 1 billion kWh = 1 TWh
    cast(dataFlagId as int64) as data_flag_id,
    _extracted_at as extracted_at
from deduplicated
