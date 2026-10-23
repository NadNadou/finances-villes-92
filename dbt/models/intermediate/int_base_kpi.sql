-- Base de calcul commune à `fct_finances_commune_annee` et `fct_finances_consolide` :
-- une ligne par commune x exercice, avec les montants de la commune, ceux de la part
-- d'EPT qui lui revient, la population et le contexte socio-démographique.
--
-- Rien n'est divisé ici : les deux tables de faits appliquent les mêmes formules, l'une
-- aux montants « commune seule », l'autre aux montants « commune + part d'EPT ». C'est
-- la garantie que les deux versions de chaque KPI sont calculées de la même façon.

with fonction as (
    select
        code_insee,
        annee,
        sum(montant)                                                   as charges_ventilees_total,
        sum(case when code_domaine = 'ENS' then montant else 0 end)    as charges_enseignement,
        sum(case when est_petite_enfance then montant else 0 end)      as charges_petite_enfance,
        count(*)                                                       as nb_domaines
    from {{ ref('stg_fonction_commune') }}
    group by 1, 2
)

select
    c.code_insee,
    c.nom_commune,
    c.siren_ept,
    c.numero_ept,
    c.nom_ept,
    c.nb_communes_ept,
    f.annee,

    -- population : donnée légale de l'exercice, dénominateur de tous les ratios /hab
    pop.population_totale,
    pop.population_municipale,

    -- montants de la commune (euros)
    f.recettes_fonctionnement,
    f.depenses_fonctionnement,
    f.charges_personnel,
    f.charges_financieres,
    f.impots_locaux,
    f.autres_impots_taxes,
    f.dgf,
    f.depenses_equipement,
    f.epargne_brute,
    f.epargne_nette,
    f.encours_dette,
    f.annuite_dette,
    f.emprunts_nouveaux,
    f.remboursement_dette,
    f.strate_demographique,

    -- flux internes au couple commune + EPT (cf. stg_flux_ept)
    coalesce(flux.fcct, 0)                     as fcct,
    coalesce(flux.attribution_compensation, 0) as attribution_compensation,

    -- ratios légaux publiés par la DGFiP, conservés pour l'étape de contrôle qualité
    f.ctrl_depenses_hab,
    f.ctrl_equipement_hab,
    f.ctrl_dette_hab,
    f.ctrl_dgf_hab,
    f.ctrl_part_personnel_pct,
    f.ctrl_part_epargne_brute_pct,
    f.strate_depenses_hab,
    f.strate_equipement_hab,
    f.strate_dette_hab,

    -- part d'EPT revenant à la commune (euros) ; NULL avant 2018, cf. METHODO.md
    e.part_population                 as ept_part_population,
    e.ept_recettes_fonctionnement,
    e.ept_depenses_fonctionnement,
    e.ept_charges_personnel,
    e.ept_impots_locaux,
    e.ept_epargne_brute,
    e.ept_encours_dette,
    e.ept_annuite_dette,
    e.ept_depenses_equipement,
    coalesce(e.ept_disponible, false) as ept_disponible,

    -- ventilation fonctionnelle (euros)
    fn.charges_ventilees_total,
    fn.charges_enseignement,
    fn.charges_petite_enfance,
    fn.nb_domaines is not null        as ventilation_disponible,

    -- contexte socio-démographique
    age.part_moins_20,
    age.part_65_plus,
    age.part_0_10,
    age.pop_0_10,
    age.pop_moins_20,
    age.methode_part_age,

    filo.millesime                    as millesime_filosofi,
    filo.niveau_vie_median,
    filo.taux_pauvrete,

    dot.potentiel_fiscal_hab,
    dot.potentiel_fiscal_strate_hab,
    dot.potentiel_financier_hab,
    dot.effort_fiscal,

    eq.nb_ecoles,
    eq.nb_creches,
    eq.millesime                      as millesime_bpe
from {{ ref('stg_dgfip_commune') }} f
join {{ ref('dim_commune') }} c
    on c.code_insee = f.code_insee
join {{ ref('stg_population') }} pop
    on pop.code_insee = f.code_insee and pop.annee = f.annee
left join {{ ref('int_ept_reparti') }} e
    on e.code_insee = f.code_insee and e.annee = f.annee
left join fonction fn
    on fn.code_insee = f.code_insee and fn.annee = f.annee
left join {{ ref('int_structure_age') }} age
    on age.code_insee = f.code_insee and age.annee = f.annee
left join {{ ref('stg_filosofi') }} filo
    on filo.code_insee = f.code_insee
left join {{ ref('stg_dotations') }} dot
    on dot.code_insee = f.code_insee and dot.annee = f.annee
left join {{ ref('stg_equipements') }} eq
    on eq.code_insee = f.code_insee
left join {{ ref('stg_flux_ept') }} flux
    on flux.code_insee = f.code_insee and flux.annee = f.annee
