-- Potentiel fiscal / financier, effort fiscal, DGF notifiée (OFGL `dotations-communes`).
-- Un pivot vers une ligne par commune x exercice, les variables utiles en colonnes.
with src as (
    select
        code_insee,
        cast(annee as integer) as annee,
        variable,
        cast(valeur as double) as valeur,
        strate_demographique
    from {{ source('raw', 'ofgl_dotations') }}
    where code_insee is not null
)
select
    code_insee,
    annee,
    max(strate_demographique)                                            as strate_dgf,
    max(case when variable = 'Potentiel fiscal 4 taxes'            then valeur end) as potentiel_fiscal,
    max(case when variable = 'Potentiel fiscal 4 taxes par hab.'   then valeur end) as potentiel_fiscal_hab,
    max(case when variable = 'Potentiel fiscal moyen de la strate' then valeur end) as potentiel_fiscal_strate_hab,
    max(case when variable = 'Potentiel financier'                 then valeur end) as potentiel_financier,
    max(case when variable = 'Potentiel financier par hab.'        then valeur end) as potentiel_financier_hab,
    max(case when variable = 'Potentiel financier moyen de la strate' then valeur end) as potentiel_financier_strate_hab,
    max(case when variable = 'Effort fiscal'                       then valeur end) as effort_fiscal,
    max(case when variable = 'Effort fiscal moyen de la strate'    then valeur end) as effort_fiscal_strate,
    max(case when variable = 'Montant Dotation DGF'                then valeur end) as dgf_notifiee,
    max(case when variable = 'Montant Dotation DSU'                then valeur end) as dsu,
    max(case when variable = 'Montant Dotation DNP'                then valeur end) as dnp
from src
group by 1, 2
