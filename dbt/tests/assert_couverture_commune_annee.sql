-- Chaque commune doit avoir un exercice complet 2015-2025 dans les comptes DGFiP :
-- 36 communes x 11 exercices = 396 lignes, sans doublon.
with compte as (
    select code_insee, annee, count(*) as n
    from {{ ref('stg_dgfip_commune') }}
    group by 1, 2
),
doublons as (
    select 'doublon' as souci, code_insee, annee from compte where n > 1
),
manquants as (
    select 'manquant' as souci, c.code_insee, a.annee
    from {{ ref('dim_commune') }} c
    cross join (
        select unnest(range({{ var('annee_min') }}, {{ var('annee_max') }} + 1)) as annee
    ) a
    left join compte p on p.code_insee = c.code_insee and p.annee = a.annee
    where p.code_insee is null
)
select * from doublons
union all
select * from manquants
