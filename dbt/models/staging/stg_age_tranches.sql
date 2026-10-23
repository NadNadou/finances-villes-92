-- Structure par âge aux millésimes de recensement (2012, 2017, 2023), format large.
with p as (
    select
        code_insee,
        cast(millesime as integer) as millesime,
        tranche,
        cast(population as double) as population
    from {{ source('raw', 'insee_age_tranches') }}
)
select
    code_insee,
    millesime,
    max(case when tranche = '_T'     then population end) as population_recensee,
    max(case when tranche = 'Y_LT15' then population end) as pop_moins_15,
    max(case when tranche = 'Y_LT20' then population end) as pop_moins_20,
    max(case when tranche = 'Y20T64' then population end) as pop_20_64,
    max(case when tranche = 'Y_GE65' then population end) as pop_65_plus,
    max(case when tranche = 'Y_GE80' then population end) as pop_80_plus
from p
group by 1, 2
