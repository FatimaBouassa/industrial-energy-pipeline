-- Grain: one row per country / year / fuel_key (international, annual).

select
    g.generation_key,
    g.country_code,
    g.country_name,
    g.year,
    m.fuel_key,
    g.generation_twh,
    g.data_flag_id,
    g.extracted_at
from {{ ref('stg_intl_generation') }} as g
left join {{ ref('fuel_type_mapping') }} as m
    on m.source_system = 'intl'
    and m.source_code = cast(g.product_id as string)
