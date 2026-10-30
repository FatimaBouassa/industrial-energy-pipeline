-- One row per common fuel. Both sources map onto these keys through the fuel_type_mapping seed.
-- is_aggregate = true marks totals (e.g. "Fossil fuels"), which must not be summed with their parts.

select distinct
    fuel_key,
    fuel_category,
    is_aggregate
from {{ ref('fuel_type_mapping') }}
