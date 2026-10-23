-- Comptes individuels DGFiP, une ligne par commune x exercice.
-- Les montants bruts sont en milliers d'euros : on repasse tout en euros ici, une fois
-- pour toutes, pour que plus aucun modèle aval n'ait à y penser.
with src as (
    select * from {{ source('raw', 'dgfip_comptes_commune') }}
)
select
    code_insee,
    cast(annee as integer)                              as annee,
    inom                                                as nom_dgfip,
    cast(pop1 as integer)                               as population_dgfip,
    nomsst1                                             as strate_demographique,
    nomsst2                                             as strate_fiscale,

    -- section de fonctionnement
    prod   * 1000.0                                     as recettes_fonctionnement,
    charge * 1000.0                                     as depenses_fonctionnement,
    perso  * 1000.0                                     as charges_personnel,
    achat  * 1000.0                                     as achats_charges_externes,
    fin    * 1000.0                                     as charges_financieres,
    subv   * 1000.0                                     as subventions_versees,
    cont   * 1000.0                                     as contingents_participations,

    -- fiscalité et dotations
    impo1  * 1000.0                                     as impots_locaux,
    impo2  * 1000.0                                     as autres_impots_taxes,
    dgf    * 1000.0                                     as dgf,

    -- section d'investissement
    recinv * 1000.0                                     as recettes_investissement,
    depinv * 1000.0                                     as depenses_investissement,
    equip  * 1000.0                                     as depenses_equipement,
    subr   * 1000.0                                     as subventions_recues_investissement,
    fctva  * 1000.0                                     as fctva,
    emp    * 1000.0                                     as emprunts_nouveaux,
    remb   * 1000.0                                     as remboursement_dette,

    -- autofinancement, dette
    ebf    * 1000.0                                     as excedent_brut_fonctionnement,
    caf    * 1000.0                                     as epargne_brute,
    cafn   * 1000.0                                     as epargne_nette,
    dette  * 1000.0                                     as encours_dette,
    encdbr * 1000.0                                     as encours_dette_bancaire,
    annu   * 1000.0                                     as annuite_dette,
    fdr    * 1000.0                                     as fonds_roulement,

    -- ratios légaux publiés par la DGFiP (servent de contrôle, pas de calcul)
    fprod                                               as ctrl_recettes_hab,
    fcharge                                             as ctrl_depenses_hab,
    fperso                                              as ctrl_personnel_hab,
    fequip                                              as ctrl_equipement_hab,
    fdette                                              as ctrl_dette_hab,
    fdgf                                                as ctrl_dgf_hab,
    fcaf                                                as ctrl_epargne_brute_hab,
    fimpo1                                              as ctrl_impots_locaux_hab,
    rperso                                              as ctrl_part_personnel_pct,
    rcaf                                                as ctrl_part_epargne_brute_pct,
    rdette                                              as ctrl_dette_sur_recettes_pct,

    -- moyennes de la strate (€/hab) publiées par la DGFiP
    mprod                                               as strate_recettes_hab,
    mcharge                                             as strate_depenses_hab,
    mperso                                              as strate_personnel_hab,
    mequip                                              as strate_equipement_hab,
    mdette                                              as strate_dette_hab,
    mcaf                                                as strate_epargne_brute_hab,
    mimpo1                                              as strate_impots_locaux_hab,

    dataset                                             as source_dataset
from src
