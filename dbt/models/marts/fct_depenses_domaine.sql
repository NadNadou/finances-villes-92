-- Question 3 « où va l'argent » : répartition des charges de fonctionnement par domaine,
-- une ligne par commune x exercice x domaine.
--
-- Base : comptes de classe 6 hors opérations d'ordre, ventilés sur la grille unifiée
-- M14/M57 (cf. macros/domaine_fonctionnel.sql). Ce total est inférieur de 3 à 10 % aux
-- dépenses réelles de fonctionnement publiées par la DGFiP, parce que celles-ci
-- comprennent aussi les atténuations de produits (chapitre 014 : FSRIF, FPIC,
-- reversements), que la présentation fonctionnelle ne porte pas.
-- `part_pct` est donc une part **des charges ventilables**, et c'est bien la bonne
-- lecture pour une question de répartition. `couverture_drf_pct` donne la part des
-- dépenses réelles de fonctionnement couverte par cette ventilation, pour que le lecteur
-- sache sur quoi porte le camembert.
--
-- Marnes-la-Coquette (92047) est absente : commune de 1 700 habitants, dispensée de
-- présentation fonctionnelle et absente du dataset des balances.

with ventile as (
    select
        code_insee,
        annee,
        code_domaine,
        sum(montant) as montant
    from {{ ref('stg_fonction_commune') }}
    group by 1, 2, 3
),

total as (
    select code_insee, annee, sum(montant) as total_ventile
    from ventile
    group by 1, 2
)

select
    c.code_insee,
    c.nom_commune,
    c.numero_ept,
    v.annee,
    v.code_domaine,
    {{ libelle_domaine_unifie('v.code_domaine') }} as domaine,
    {{ ordre_domaine_unifie('v.code_domaine') }}   as ordre_domaine,
    v.montant,
    v.montant / nullif(p.population_totale, 0)                as montant_hab,
    100.0 * v.montant / nullif(t.total_ventile, 0)             as part_pct,
    t.total_ventile,
    100.0 * t.total_ventile / nullif(f.depenses_fonctionnement, 0) as couverture_drf_pct
from ventile v
join total t
    on t.code_insee = v.code_insee and t.annee = v.annee
join {{ ref('dim_commune') }} c
    on c.code_insee = v.code_insee
join {{ ref('stg_population') }} p
    on p.code_insee = v.code_insee and p.annee = v.annee
left join {{ ref('stg_dgfip_commune') }} f
    on f.code_insee = v.code_insee and f.annee = v.annee
