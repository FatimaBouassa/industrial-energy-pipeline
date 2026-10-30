-- The four category shares must add up to 100% for every country-year (tolerance 0.01 point).
-- Returns the rows that do not.

select
    country_code,
    year,
    renewable_share_pct + fossil_share_pct + nuclear_share_pct + other_share_pct as total_pct
from {{ ref('mart_category_share_annual') }}
where abs(renewable_share_pct + fossil_share_pct + nuclear_share_pct + other_share_pct - 100) > 0.01
