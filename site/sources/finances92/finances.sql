-- Les 6 KPI dans les deux périmètres, 2015-2025.
-- Les deux marts partagent la même macro de calcul : les colonnes communes sont
-- empilées ici pour que le site n'ait qu'une seule table à interroger, et que la bascule
-- « commune seule / commune + EPT » soit un simple filtre.
select
    code_insee, nom_commune, numero_ept, nom_ept, annee, perimetre,
    population_totale, strate_demographique,
    equipement_hab, equipement_hab_moy3,
    capacite_desendettement_annees, capacite_desendettement_brute,
    desendettement_situation, alerte_desendettement,
    depenses_enfance_par_enfant, charges_enseignement_hab, charges_petite_enfance_hab,
    impots_locaux_hab, poids_impots_sur_revenu_pct,
    potentiel_fiscal_hab, potentiel_fiscal_strate_hab, potentiel_fiscal_ecart_strate_pct,
    recettes_fonctionnement_hab, depenses_fonctionnement_hab,
    encours_dette_hab, epargne_brute_hab,
    part_personnel_pct, part_epargne_brute_pct, part_annuite_pct,
    dgf_hab, niveau_vie_median, taux_pauvrete, millesime_filosofi,
    part_moins_20, part_65_plus, part_0_10, pop_0_10, methode_part_age,
    nb_ecoles, nb_creches, millesime_bpe,
    ventilation_disponible, ept_disponible,
    null::double as part_ept_equipement_pct,
    null::double as part_ept_dette_pct,
    null::double as part_ept_fonctionnement_pct
from read_parquet('../data/marts/fct_finances_commune_annee.parquet')

union all

select
    code_insee, nom_commune, numero_ept, nom_ept, annee, perimetre,
    population_totale, strate_demographique,
    equipement_hab, equipement_hab_moy3,
    capacite_desendettement_annees, capacite_desendettement_brute,
    desendettement_situation, alerte_desendettement,
    depenses_enfance_par_enfant, charges_enseignement_hab, charges_petite_enfance_hab,
    impots_locaux_hab, poids_impots_sur_revenu_pct,
    potentiel_fiscal_hab, potentiel_fiscal_strate_hab, potentiel_fiscal_ecart_strate_pct,
    recettes_fonctionnement_hab, depenses_fonctionnement_hab,
    encours_dette_hab, epargne_brute_hab,
    part_personnel_pct, part_epargne_brute_pct, part_annuite_pct,
    dgf_hab, niveau_vie_median, taux_pauvrete, millesime_filosofi,
    part_moins_20, part_65_plus, part_0_10, pop_0_10, methode_part_age,
    nb_ecoles, nb_creches, millesime_bpe,
    ventilation_disponible, ept_disponible,
    part_ept_equipement_pct, part_ept_dette_pct, part_ept_fonctionnement_pct
from read_parquet('../data/marts/fct_finances_consolide.parquet')
