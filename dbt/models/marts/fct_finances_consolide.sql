-- Les 6 KPI, **périmètre commune + part de l'EPT**, une ligne par commune x exercice.
--
-- C'est la lecture « ce que la puissance publique locale dépense sur mon territoire » :
-- depuis 2016, une partie des compétences communales est portée par l'établissement
-- public territorial. La part d'EPT attribuée à chaque commune est au prorata de sa
-- population (cf. `int_ept_reparti`), qui est une convention et non une mesure.
--
-- `ept_disponible` dit si la part d'EPT a pu être ajoutée. Elle vaut `false` :
--   - en 2015 : les EPT n'existaient pas (création au 1er janvier 2016) ;
--   - en 2016-2017 : l'API OFGL ne publie plus ces exercices (cf. METHODO.md).
-- Dans ces cas, les colonnes consolidées valent la valeur commune seule, et le site
-- affiche l'avertissement correspondant plutôt que de laisser croire à un périmètre
-- consolidé complet.

with base as (
    select
        *,
        depenses_equipement     + coalesce(ept_depenses_equipement, 0)     as cons_equipement,
        encours_dette           + coalesce(ept_encours_dette, 0)           as cons_dette,
        epargne_brute           + coalesce(ept_epargne_brute, 0)           as cons_epargne,
        impots_locaux           + coalesce(ept_impots_locaux, 0)           as cons_impots,
        depenses_fonctionnement + coalesce(ept_depenses_fonctionnement, 0) as cons_depenses_fonct,
        recettes_fonctionnement + coalesce(ept_recettes_fonctionnement, 0) as cons_recettes_fonct,
        charges_personnel       + coalesce(ept_charges_personnel, 0)       as cons_personnel,
        annuite_dette           + coalesce(ept_annuite_dette, 0)           as cons_annuite
    from {{ ref('int_base_kpi') }}
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
        'commune + EPT' as perimetre,

        {{ bloc_kpi(
            equipement     = 'cons_equipement',
            dette          = 'cons_dette',
            epargne        = 'cons_epargne',
            impots         = 'cons_impots',
            depenses_fonct = 'cons_depenses_fonct',
            recettes_fonct = 'cons_recettes_fonct',
            personnel      = 'cons_personnel',
            annuite        = 'cons_annuite'
        ) }},

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
        ept_part_population,

        -- poids de l'EPT dans le périmètre consolidé : utile pour expliquer la bascule
        100.0 * coalesce(ept_depenses_equipement, 0) / nullif(cons_equipement, 0)
            as part_ept_equipement_pct,
        100.0 * coalesce(ept_encours_dette, 0) / nullif(cons_dette, 0)
            as part_ept_dette_pct,
        100.0 * coalesce(ept_depenses_fonctionnement, 0) / nullif(cons_depenses_fonct, 0)
            as part_ept_fonctionnement_pct
    from base
)

select
    kpi.*,
    case
        when count(*) over trois_ans = 3
            then avg(equipement_hab) over trois_ans
    end as equipement_hab_moy3
from kpi
window trois_ans as (
    partition by code_insee order by annee rows between 2 preceding and current row
)
