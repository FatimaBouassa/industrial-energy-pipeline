-- One row per country and year, with the share of each fuel category in separate columns.
-- Built for the dashboard: a line chart of renewable share over time needs a date field (year_date)
-- and one column per category, so no calculated fields are needed in Looker Studio.

select
    concat(country_code, '|', cast(year as string)) as country_year_key,
    country_code,
    country_name,
    year,
    date(year, 1, 1) as year_date,
    max(total_twh) as total_twh,
    sum(if(fuel_category = 'renewable', share_pct, 0)) as renewable_share_pct,
    sum(if(fuel_category = 'fossil', share_pct, 0)) as fossil_share_pct,
    sum(if(fuel_category = 'nuclear', share_pct, 0)) as nuclear_share_pct,
    sum(if(fuel_category not in ('renewable', 'fossil', 'nuclear'), share_pct, 0)) as other_share_pct
from {{ ref('mart_generation_mix_annual') }}
group by country_code, country_name, year
