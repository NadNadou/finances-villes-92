-- Structure par âge par commune ET par année, 2015-2025.
--
-- Problème : le recensement ne donne la structure par âge qu'aux millésimes 2012, 2017
-- et 2023, et la population par âge révolu (nécessaire pour isoler les 0-10 ans) qu'au
-- seul millésime 2023. Il faut pourtant un dénominateur par année pour la question 4.
--
-- Méthode, explicite et traçable :
--   1. `part_moins_20` et `part_65_plus` : part mesurée aux millésimes de recensement,
--      **interpolée linéairement** entre deux millésimes, **maintenue constante** avant
--      le premier et après le dernier. La colonne `methode_part_age` dit lequel des trois
--      cas s'applique pour chaque ligne.
--   2. `part_0_10` : la part des 0-10 ans n'est connue qu'en 2023. On la fait évoluer
--      proportionnellement à la part des moins de 15 ans, qui est elle mesurée aux trois
--      millésimes : part_0_10(a) = part_0_10(2023) x part_moins_15(a) / part_moins_15(2023).
--      C'est une estimation, jamais une mesure : `methode_part_age` vaut alors
--      'estimé d'après la part des moins de 15 ans'.
--   3. Les effectifs (`pop_moins_20`, `pop_0_10`…) sont ces parts appliquées à la
--      population totale de l'année, qui est elle une donnée légale réelle.
--
-- Aucune valeur n'est inventée : tout est soit mesuré, soit une transformation déclarée
-- d'une mesure, et la colonne de méthode permet de l'afficher sur le site.

with pop as (
    select * from {{ ref('stg_population') }}
),

recensements as (
    select
        t.code_insee,
        t.millesime,
        t.population_recensee,
        t.pop_moins_15 / nullif(t.population_recensee, 0) as part_moins_15,
        t.pop_moins_20 / nullif(t.population_recensee, 0) as part_moins_20,
        t.pop_65_plus  / nullif(t.population_recensee, 0) as part_65_plus,
        t.pop_80_plus  / nullif(t.population_recensee, 0) as part_80_plus
    from {{ ref('stg_age_tranches') }} t
),

-- Référence 2023 : seul millésime où les 0-10 ans sont mesurables.
ref_2023 as (
    select
        d.code_insee,
        d.pop_0_2  / nullif(d.pop_totale_recensee, 0) as part_0_2_2023,
        d.pop_0_5  / nullif(d.pop_totale_recensee, 0) as part_0_5_2023,
        d.pop_0_10 / nullif(d.pop_totale_recensee, 0) as part_0_10_2023,
        r.part_moins_15                                as part_moins_15_2023
    from {{ ref('stg_age_detail') }} d
    left join recensements r
        on r.code_insee = d.code_insee and r.millesime = d.millesime
),

-- Pour chaque commune x année : le recensement juste avant et juste après.
encadrement as (
    select
        p.code_insee,
        p.annee,
        p.population_totale,
        p.population_municipale,
        (select max(r.millesime) from recensements r
          where r.code_insee = p.code_insee and r.millesime <= p.annee) as mil_avant,
        (select min(r.millesime) from recensements r
          where r.code_insee = p.code_insee and r.millesime >= p.annee) as mil_apres
    from pop p
),

interpole as (
    select
        e.code_insee,
        e.annee,
        e.population_totale,
        e.population_municipale,
        coalesce(e.mil_avant, e.mil_apres) as mil_bas,
        coalesce(e.mil_apres, e.mil_avant) as mil_haut,
        case
            when e.mil_avant is null or e.mil_apres is null then 0.0
            when e.mil_apres = e.mil_avant                  then 0.0
            else (e.annee - e.mil_avant) * 1.0 / (e.mil_apres - e.mil_avant)
        end as poids
    from encadrement e
),

parts as (
    select
        i.code_insee,
        i.annee,
        i.population_totale,
        i.population_municipale,
        rb.millesime = i.annee as annee_de_recensement,
        rb.part_moins_15 + (rh.part_moins_15 - rb.part_moins_15) * i.poids as part_moins_15,
        rb.part_moins_20 + (rh.part_moins_20 - rb.part_moins_20) * i.poids as part_moins_20,
        rb.part_65_plus  + (rh.part_65_plus  - rb.part_65_plus)  * i.poids as part_65_plus,
        rb.part_80_plus  + (rh.part_80_plus  - rb.part_80_plus)  * i.poids as part_80_plus,
        i.mil_bas,
        i.mil_haut
    from interpole i
    join recensements rb on rb.code_insee = i.code_insee and rb.millesime = i.mil_bas
    join recensements rh on rh.code_insee = i.code_insee and rh.millesime = i.mil_haut
)

select
    p.code_insee,
    p.annee,
    p.population_totale,
    p.population_municipale,

    p.part_moins_15,
    p.part_moins_20,
    p.part_65_plus,
    p.part_80_plus,

    -- part des 0-10 ans : mesurée en 2023, sinon déduite de l'évolution des moins de 15 ans
    r.part_0_10_2023 * p.part_moins_15 / nullif(r.part_moins_15_2023, 0) as part_0_10,
    r.part_0_5_2023  * p.part_moins_15 / nullif(r.part_moins_15_2023, 0) as part_0_5,
    r.part_0_2_2023  * p.part_moins_15 / nullif(r.part_moins_15_2023, 0) as part_0_2,

    -- effectifs : part (mesurée ou estimée) x population légale de l'année (mesurée)
    p.part_moins_20 * p.population_totale as pop_moins_20,
    p.part_65_plus  * p.population_totale as pop_65_plus,
    r.part_0_10_2023 * p.part_moins_15 / nullif(r.part_moins_15_2023, 0) * p.population_totale
        as pop_0_10,
    r.part_0_2_2023  * p.part_moins_15 / nullif(r.part_moins_15_2023, 0) * p.population_totale
        as pop_0_2,

    case
        when p.annee_de_recensement then 'mesuré (recensement ' || p.annee || ')'
        when p.mil_bas <> p.mil_haut
            then 'interpolé entre les recensements ' || p.mil_bas || ' et ' || p.mil_haut
        when p.annee < p.mil_bas
            then 'part du recensement ' || p.mil_bas || ' maintenue (année antérieure)'
        else 'part du recensement ' || p.mil_bas || ' maintenue (année postérieure)'
    end as methode_part_age,
    'part des 0-10 ans du recensement 2023, ajustée par l''évolution de la part des moins de 15 ans'
        as methode_part_0_10
from parts p
left join ref_2023 r on r.code_insee = p.code_insee
