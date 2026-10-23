-- Les 6 KPI, **périmètre commune seule**, une ligne par commune x exercice 2015-2025.
--
-- C'est la lecture « ce que fait ma mairie ». Elle sous-estime mécaniquement l'effort
-- public sur le territoire depuis 2016, parce qu'une partie des compétences (voirie,
-- déchets, parfois équipements sportifs et culturels) est passée à l'EPT.
-- Voir `fct_finances_consolide` pour l'autre lecture.

with base as (
    select * from {{ ref('int_base_kpi') }}
),

kpi as (
    select
        code_insee,
        nom_commune,
        numero_ept,
        nom_ept,
        annee,
        population_totale,
        strate_demographique,
        'commune' as perimetre,

        {{ bloc_kpi(
            equipement     = 'depenses_equipement',
            dette          = 'encours_dette',
            epargne        = 'epargne_brute',
            impots         = 'impots_locaux',
            depenses_fonct = 'depenses_fonctionnement',
            recettes_fonct = 'recettes_fonctionnement',
            personnel      = 'charges_personnel',
            annuite        = 'annuite_dette'
        ) }},

        -- éléments de contexte et de traçabilité repris tels quels
        dgf / nullif(population_totale, 0) as dgf_hab,
        niveau_vie_median,
        taux_pauvrete,
        millesime_filosofi,
        part_moins_20,
        part_65_plus,
        part_0_10,
        pop_0_10,
        methode_part_age,
        effort_fiscal,
        nb_ecoles,
        nb_creches,
        millesime_bpe,
        ventilation_disponible,
        ept_disponible,

        -- ratios légaux DGFiP et moyennes de strate, pour le contrôle qualité
        ctrl_depenses_hab,
        ctrl_equipement_hab,
        ctrl_dette_hab,
        ctrl_dgf_hab,
        ctrl_part_personnel_pct,
        ctrl_part_epargne_brute_pct,
        strate_depenses_hab,
        strate_equipement_hab,
        strate_dette_hab
    from base
)

select
    kpi.*,
    -- Q1 : moyenne glissante 3 ans (exercice courant + deux précédents). NULL tant que
    -- les trois exercices ne sont pas disponibles, pour ne pas publier une moyenne de 1.
    case
        when count(*) over trois_ans = 3
            then avg(equipement_hab) over trois_ans
    end as equipement_hab_moy3
from kpi
window trois_ans as (
    partition by code_insee order by annee rows between 2 preceding and current row
)
