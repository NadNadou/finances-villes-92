-- Niveau de vie et pauvreté (Filosofi). Un seul millésime exposé par l'API Melodi.
with p as (
    select
        code_insee,
        cast(millesime as integer) as millesime,
        mesure,
        cast(valeur as double)     as valeur
    from {{ source('raw', 'insee_filosofi') }}
)
select
    code_insee,
    millesime,
    max(case when mesure = 'MED_SL'      then valeur end) as niveau_vie_median,
    max(case when mesure = 'PR_MD60'     then valeur end) as taux_pauvrete,
    max(case when mesure = 'D1_SL'       then valeur end) as decile_1,
    max(case when mesure = 'D9_SL'       then valeur end) as decile_9,
    max(case when mesure = 'IR_D9_D1_SL' then valeur end) as rapport_interdecile,
    max(case when mesure = 'GI_SL'       then valeur end) as gini
from p
group by 1, 2
