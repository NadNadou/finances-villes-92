{#
  Les 6 KPI du projet, écrits une seule fois.

  `fct_finances_commune_annee` et `fct_finances_consolide` appellent cette macro avec
  des expressions de montants différentes (commune seule / commune + part d'EPT) :
  les formules, les seuils et les cas de nullité sont donc rigoureusement identiques
  entre les deux versions, ce qui est la condition pour que la bascule du site ait un
  sens. Les montants passés en argument sont en euros.
#}

{% macro bloc_kpi(
    equipement,
    dette,
    epargne,
    impots,
    depenses_fonct,
    recettes_fonct,
    personnel,
    annuite
) %}
    -- Q1 : qui construit le plus ? Dépenses d'équipement par habitant.
    -- La moyenne glissante 3 ans est calculée dans le modèle appelant (fenêtre).
    {{ equipement }} / nullif(population_totale, 0) as equipement_hab,

    -- Q2 : qui est le plus endetté ? Capacité de désendettement, en années.
    -- Nombre d'années d'épargne brute qu'il faudrait y consacrer pour rembourser toute
    -- la dette. Deux cas rendent le ratio non significatif :
    --   - épargne brute nulle ou négative : aucune capacité de remboursement, le ratio
    --     n'existe pas ;
    --   - ratio supérieur à 100 ans : l'épargne est positive mais résiduelle, le résultat
    --     n'a plus de sens économique. Clichy-la-Garenne atteint ainsi 2 007 ans en 2022.
    -- `capacite_desendettement_brute` garde la valeur telle quelle pour la traçabilité et
    -- pour le classement ; `capacite_desendettement_annees` est le KPI publié, borné.
    case when {{ epargne }} > 0 then {{ dette }} / {{ epargne }} end
        as capacite_desendettement_brute,
    case
        when {{ epargne }} > 0 and {{ dette }} / {{ epargne }} <= 100
            then {{ dette }} / {{ epargne }}
    end as capacite_desendettement_annees,
    case
        when {{ epargne }} <= 0 then 'épargne brute nulle ou négative : aucune capacité de remboursement'
        when {{ dette }} / {{ epargne }} > 100 then 'au-delà de 100 ans : capacité de remboursement résiduelle'
        when {{ dette }} / {{ epargne }} > 12 then 'au-delà du seuil d''alerte de 12 ans'
        when {{ dette }} / {{ epargne }} > 8 then 'zone de vigilance (8 à 12 ans)'
        else 'soutenable (moins de 8 ans)'
    end as desendettement_situation,
    case
        when {{ epargne }} <= 0 then true
        when {{ dette }} / {{ epargne }} > 12 then true
        else false
    end as alerte_desendettement,

    -- Q4 : une ville pour les enfants ? Dépenses scolaires et de petite enfance par
    -- enfant de 0 à 10 ans. Les deux postes sont des compétences communales : l'EPT
    -- n'en porte pas, donc ce KPI est identique dans les deux périmètres.
    case
        when ventilation_disponible and pop_0_10 > 0
            then (charges_enseignement + charges_petite_enfance) / pop_0_10
    end as depenses_enfance_par_enfant,
    case when ventilation_disponible then charges_enseignement / nullif(population_totale, 0) end
        as charges_enseignement_hab,
    case when ventilation_disponible then charges_petite_enfance / nullif(population_totale, 0) end
        as charges_petite_enfance_hab,

    -- Q5 : combien paient les habitants ? Impôts locaux par habitant, et poids de ces
    -- impôts rapporté au niveau de vie médian annuel par unité de consommation.
    {{ impots }} / nullif(population_totale, 0) as impots_locaux_hab,
    100.0 * ({{ impots }} / nullif(population_totale, 0)) / nullif(niveau_vie_median, 0)
        as poids_impots_sur_revenu_pct,

    -- Q6 : ville riche ou ville qui choisit ? Potentiel fiscal par habitant, tel que
    -- publié par la DGCL (OFGL `dotations-communes`), et son écart à la strate.
    potentiel_fiscal_hab,
    potentiel_fiscal_strate_hab,
    case
        when potentiel_fiscal_strate_hab > 0
            then 100.0 * potentiel_fiscal_hab / potentiel_fiscal_strate_hab - 100.0
    end as potentiel_fiscal_ecart_strate_pct,

    -- contexte financier, mêmes montants que ci-dessus
    {{ recettes_fonct }} / nullif(population_totale, 0) as recettes_fonctionnement_hab,
    {{ depenses_fonct }} / nullif(population_totale, 0) as depenses_fonctionnement_hab,
    {{ dette }}          / nullif(population_totale, 0) as encours_dette_hab,
    {{ epargne }}        / nullif(population_totale, 0) as epargne_brute_hab,
    100.0 * {{ personnel }} / nullif({{ depenses_fonct }}, 0) as part_personnel_pct,
    100.0 * {{ epargne }}   / nullif({{ recettes_fonct }}, 0) as part_epargne_brute_pct,
    100.0 * {{ annuite }}   / nullif({{ recettes_fonct }}, 0) as part_annuite_pct
{% endmacro %}
