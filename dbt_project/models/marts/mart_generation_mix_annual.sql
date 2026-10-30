-- Generation mix per country and year, ready for the dashboard.
-- Uses only individual fuels: aggregates (totals) are excluded to avoid double counting,
-- and storage is excluded because it is not a source of generation.

with leaf as (

    select
        f.country_code,
        f.country_name,
        f.year,
        f.fuel_key,
        d.fuel_category,
        f.generation_twh
    from {{ ref('fct_generation_annual') }} as f
    inner join {{ ref('dim_fuel_type') }} as d
        on f.fuel_key = d.fuel_key
    where not d.is_aggregate
        and d.fuel_category != 'storage'

),

totals as (

    select
        country_code,
        year,
        sum(generation_twh) as total_twh
    from leaf
    group by country_code, year

)

select
    leaf.country_code,
    leaf.country_name,
    leaf.year,
    leaf.fuel_key,
    leaf.fuel_category,
    leaf.generation_twh,
    totals.total_twh,
    safe_divide(leaf.generation_twh, totals.total_twh) * 100 as share_pct
from leaf
inner join totals
    on leaf.country_code = totals.country_code
    and leaf.year = totals.year
