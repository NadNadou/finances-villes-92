-- Dimension commune : 36 lignes, une par commune des Hauts-de-Seine.
-- `nb_communes_ept` sert au prorata EPT de `int_ept_reparti`.
with base as (
    select * from {{ ref('stg_commune') }}
)
select
    base.*,
    count(*) over (partition by siren_ept) as nb_communes_ept,
    case when code_insee = '{{ var("ville_a") }}' then true else false end as est_ville_a,
    case when code_insee = '{{ var("ville_b") }}' then true else false end as est_ville_b
from base
