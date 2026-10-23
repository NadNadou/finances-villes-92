-- Contrôle qualité : confrontation de nos KPI à deux références extérieures.
--
-- Référence 1 — **les ratios légaux publiés par la DGFiP** dans les comptes individuels.
-- C'est le contrôle le plus fort disponible : il porte sur les 36 communes et les 11
-- exercices, soit 396 points par ratio, et il est automatique. Nous recalculons chaque
-- ratio à partir du montant et de la population, sans jamais reprendre le ratio publié ;
-- la comparaison vérifie donc à la fois notre formule, notre choix d'agrégat et notre
-- choix de population.
--
-- Référence 2 — **les valeurs relevées sur des documents budgétaires communaux**
-- (seed `ref_ratios_legaux`), aujourd'hui le budget primitif 2026 de Vanves. Contrôle
-- ponctuel, et partiellement non comparable : un budget primitif n'est pas un compte
-- administratif. Le seed porte une colonne `comparable` qui dit, ligne par ligne, si
-- l'écart doit être faible, et pourquoi quand il ne doit pas l'être.

with ratios_dgfip as (
    select
        'ratio légal DGFiP' as reference,
        code_insee,
        nom_commune,
        annee,
        ratio,
        libelle,
        valeur_calculee,
        valeur_reference,
        unite
    from (
        select
            code_insee, nom_commune, annee,
            'depenses_fonctionnement_hab' as ratio,
            'Dépenses réelles de fonctionnement par habitant' as libelle,
            depenses_fonctionnement_hab as valeur_calculee,
            ctrl_depenses_hab           as valeur_reference,
            '€/hab' as unite
        from {{ ref('fct_finances_commune_annee') }}
        union all
        select
            code_insee, nom_commune, annee,
            'equipement_hab',
            'Dépenses d''équipement brut par habitant',
            equipement_hab, ctrl_equipement_hab, '€/hab'
        from {{ ref('fct_finances_commune_annee') }}
        union all
        select
            code_insee, nom_commune, annee,
            'encours_dette_hab',
            'Encours de dette par habitant',
            encours_dette_hab, ctrl_dette_hab, '€/hab'
        from {{ ref('fct_finances_commune_annee') }}
        union all
        select
            code_insee, nom_commune, annee,
            'dgf_hab',
            'Dotation globale de fonctionnement par habitant',
            dgf_hab, ctrl_dgf_hab, '€/hab'
        from {{ ref('fct_finances_commune_annee') }}
    )
),

ratios_documents as (
    select
        'document budgétaire' as reference,
        s.code_insee,
        s.nom_commune,
        s.annee_comparaison as annee,
        s.ratio,
        s.libelle,
        case s.ratio
            when 'depenses_fonctionnement_hab' then f.depenses_fonctionnement_hab
            when 'equipement_hab'              then f.equipement_hab
            when 'encours_dette_hab'           then f.encours_dette_hab
            when 'dgf_hab'                     then f.dgf_hab
            when 'part_personnel_pct'          then f.part_personnel_pct
            when 'part_epargne_brute_pct'      then f.part_epargne_brute_pct
            when 'potentiel_fiscal_hab'        then f.potentiel_fiscal_hab
            when 'population_totale'           then f.population_totale * 1.0
        end as valeur_calculee,
        s.valeur as valeur_reference,
        s.unite
    from {{ ref('ref_ratios_legaux') }} s
    join {{ ref('fct_finances_commune_annee') }} f
        on f.code_insee = s.code_insee and f.annee = s.annee_comparaison
),

tout as (
    select * from ratios_dgfip
    union all
    select * from ratios_documents
)

select
    t.reference,
    t.code_insee,
    t.nom_commune,
    t.annee,
    t.ratio,
    t.libelle,
    t.unite,
    t.valeur_calculee,
    t.valeur_reference,
    t.valeur_calculee - t.valeur_reference as ecart_absolu,
    case
        when t.valeur_reference <> 0
            then 100.0 * (t.valeur_calculee - t.valeur_reference) / t.valeur_reference
    end as ecart_pct,
    coalesce(s.comparable, 'oui') as comparable,
    s.commentaire,
    s.source
from tout t
left join {{ ref('ref_ratios_legaux') }} s
    on t.reference = 'document budgétaire'
   and s.code_insee = t.code_insee
   and s.ratio = t.ratio
