{{ config(severity='warn') }}

-- Checks my assumption about the product hierarchy: the individual fuels (no totals, no storage)
-- should add up to the "Electricity" total within 5%. Returns the country-years that do not.
-- Severity is 'warn' because storage and rounding can legitimately cause small gaps.

with leaf as (

    select
        f.country_code,
        f.year,
        sum(f.generation_twh) as leaf_twh
    from {{ ref('fct_generation_annual') }} as f
    inner join {{ ref('dim_fuel_type') }} as d
        on f.fuel_key = d.fuel_key
    where not d.is_aggregate
        and d.fuel_category != 'storage'
    group by f.country_code, f.year

),

total as (

    select
        country_code,
        year,
        generation_twh as total_twh
    from {{ ref('fct_generation_annual') }}
    where fuel_key = 'total'

)

select
    leaf.country_code,
    leaf.year,
    leaf.leaf_twh,
    total.total_twh
from leaf
inner join total
    on leaf.country_code = total.country_code
    and leaf.year = total.year
where abs(leaf.leaf_twh - total.total_twh) > 0.05 * total.total_twh
