-- Population par âge révolu au recensement 2023 : seule source permettant d'isoler
-- des tranches fines (0-2 ans pour la petite enfance, 0-10 ans pour la scolarité).
with p as (
    select
        code_insee,
        cast(millesime as integer) as millesime,
        cast(age as integer)       as age,
        cast(population as double) as population
    from {{ source('raw', 'insee_age_detail') }}
    where age is not null
)
select
    code_insee,
    millesime,
    sum(case when age <= 2  then population else 0 end) as pop_0_2,
    sum(case when age <= 5  then population else 0 end) as pop_0_5,
    sum(case when age <= 10 then population else 0 end) as pop_0_10,
    sum(case when age <= 14 then population else 0 end) as pop_0_14,
    sum(case when age <= 19 then population else 0 end) as pop_0_19,
    sum(population)                                     as pop_totale_recensee
from p
group by 1, 2
