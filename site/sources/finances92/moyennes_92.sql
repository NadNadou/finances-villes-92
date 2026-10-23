-- Moyennes et médianes départementales par exercice et par périmètre, pour situer une
-- ville face au reste du département sur chaque courbe.
-- La moyenne pondérée par la population est la bonne référence pour un ratio par
-- habitant : elle répond à « combien par habitant du 92 », là où la moyenne simple
-- donne autant de poids à Marnes-la-Coquette (1 700 hab) qu'à Boulogne (120 000).
with base as (
    select * from read_parquet('../data/marts/fct_finances_commune_annee.parquet')
    union all by name
    select * from read_parquet('../data/marts/fct_finances_consolide.parquet')
)
select
    annee,
    perimetre,
    count(*) as nb_communes,
    sum(population_totale) as population_92,
    sum(equipement_hab * population_totale) / sum(population_totale)              as equipement_hab,
    median(capacite_desendettement_annees)                                        as capacite_desendettement_annees,
    sum(depenses_enfance_par_enfant * pop_0_10) filter (where depenses_enfance_par_enfant is not null)
      / nullif(sum(pop_0_10) filter (where depenses_enfance_par_enfant is not null), 0) as depenses_enfance_par_enfant,
    sum(impots_locaux_hab * population_totale) / sum(population_totale)           as impots_locaux_hab,
    sum(poids_impots_sur_revenu_pct * population_totale) filter (where poids_impots_sur_revenu_pct is not null)
      / nullif(sum(population_totale) filter (where poids_impots_sur_revenu_pct is not null), 0) as poids_impots_sur_revenu_pct,
    sum(potentiel_fiscal_hab * population_totale) filter (where potentiel_fiscal_hab is not null)
      / nullif(sum(population_totale) filter (where potentiel_fiscal_hab is not null), 0) as potentiel_fiscal_hab,
    sum(depenses_fonctionnement_hab * population_totale) / sum(population_totale) as depenses_fonctionnement_hab,
    sum(encours_dette_hab * population_totale) / sum(population_totale)           as encours_dette_hab,
    sum(part_personnel_pct * population_totale) / sum(population_totale)          as part_personnel_pct,
    sum(part_epargne_brute_pct * population_totale) / sum(population_totale)      as part_epargne_brute_pct
from base
group by 1, 2
