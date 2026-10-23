-- Contrôle croisé entre les deux éditeurs qui publient les comptes des communes.
--
-- Pourquoi ce modèle plutôt qu'une comparaison aux fiches « comptes individuels des
-- collectivités » de impots.gouv.fr/cll : **ces fiches sont générées depuis le jeu de
-- données que nous ingérons déjà** (« Comptes individuels des communes — fichier global »,
-- DGFiP). Les comparer reviendrait à comparer une source à elle-même. Le contrôle utile
-- est celui qui confronte **deux éditeurs différents** travaillant sur les mêmes comptes
-- de gestion : la DGFiP (data.economie.gouv.fr) et l'OFGL (data.ofgl.fr), dont les
-- chaînes de traitement et les définitions d'agrégats sont indépendantes.
--
-- Le modèle compare, pour les 36 communes et les exercices couverts par les deux sources
-- (2018-2025), les agrégats qui ont une contrepartie dans l'autre source. La colonne
-- `attendu_identique` dit si les deux définitions sont censées coïncider :
--
--   - **oui** : même périmètre, l'écart doit être nul au centime près. Un écart ici est un
--     bug chez nous ou chez un des deux éditeurs.
--   - **non** : les définitions diffèrent structurellement. L'écart est alors une mesure
--     de cette différence, utile à documenter, pas une anomalie.

-- Pour chaque concept : le nom du champ DGFiP, l'agrégat OFGL correspondant, un libellé,
-- et si les deux définitions sont censées coïncider. Les motifs de divergence sont établis
-- à partir des **formules publiées par l'OFGL** (dataset
-- `methodologie-ofgl-formules-des-agregats-financiers`), pas supposés.
{% set concepts = [
    ('charges_personnel', 'Frais de personnel', 'Charges de personnel', 'oui',
     'Mêmes comptes (621, 631, 633, 64).'),

    ('encours_dette', 'Encours de dette', 'Encours de dette', 'oui',
     'Mêmes comptes (16 hors 1688 et 169).'),

    ('dgf', 'Dotation globale de fonctionnement', 'Dotation globale de fonctionnement', 'oui',
     'Même notification DGCL.'),

    ('charges_financieres', 'Charges financières', 'Charges financières', 'non',
     "Le chapitre 66 est le même, mais l'OFGL en exclut les opérations d'ordre, que le `fin` DGFiP conserve. Vérifié au centime sur Antony 2021 : le compte 6681 (indemnités de renégociation de dette) y vaut 1 000 000 € dont 1 000 000 € d'opérations d'ordre ; 2 970 319 - 1 000 000 = 1 970 319, soit exactement la valeur OFGL. L'écart ne concerne que 7 points sur 288, ceux des communes qui ont renégocié leur dette."),

    ('depenses_equipement', '__equipement__', "Dépenses d'équipement", 'non',
     "La formule OFGL est D20 + D21 + D23 - D204 - D2324 - C236 - C237 - C238 : elle retire les subventions d'équipement versées (qu'on rajoute pour comparer) MAIS AUSSI les avances versées sur commandes d'immobilisations, que le `equip` DGFiP conserve. Le ratio légal est celui de la DGFiP."),

    ('epargne_brute', 'Epargne brute', 'Épargne brute', 'non',
     "L'OFGL calcule recettes de fonctionnement moins dépenses de fonctionnement avec ses propres définitions étroites ; la DGFiP publie une capacité d'autofinancement issue du compte de résultat. Deux constructions différentes du même concept."),

    ('annuite_dette', 'Annuité de la dette', 'Annuité de la dette', 'non',
     "L'OFGL additionne les remboursements d'emprunts HORS gestion active de la dette et les charges financières ; le `annu` DGFiP inclut les mouvements de gestion active (tirages et remboursements de lignes de trésorerie), d'où des écarts très larges sur les communes qui en font usage."),

    ('depenses_fonctionnement', 'Dépenses de fonctionnement', 'Dépenses de fonctionnement', 'non',
     "Pour les communes de la Métropole du Grand Paris, l'OFGL retire explicitement le compte 65561 (contribution au fonds de compensation des charges territoriales) en plus des opérations d'ordre. Le `charge` DGFiP, qui est la base du ratio légal, le conserve."),

    ('recettes_fonctionnement', 'Recettes de fonctionnement', 'Recettes de fonctionnement', 'non',
     "Même raison, en miroir : la formule OFGL spécifique aux communes de la Métropole du Grand Paris retranche le 65561 des produits."),

    ('impots_locaux', 'Impôts locaux', 'Impôts locaux', 'non',
     "L'agrégat OFGL est une ressource fiscale nette : il ajoute la fiscalité reversée (chapitre 732) et retranche le FCCT. Le `impo1` DGFiP est le produit des contributions directes (chapitre 731), c'est-à-dire ce que paient effectivement les contribuables locaux — la définition demandée par la question 5.")
] %}

with ofgl as (
    select
        code_insee,
        annee,
        max(population_totale) as population_ofgl,
        {% for champ, agregat, libelle, identique, motif in concepts %}
        {% if agregat == '__equipement__' %}
        -- Le `equip` de la DGFiP inclut les subventions d'équipement versées : pour
        -- comparer la même chose, on les rajoute à l'agrégat OFGL.
        coalesce(max(case when agregat = 'Dépenses d''équipement' then montant end), 0)
          + coalesce(max(case when agregat = 'Subventions d''équipement versées' then montant end), 0)
            as ofgl_{{ champ }}
        {% else %}
        max(case when agregat = '{{ agregat }}' then montant end) as ofgl_{{ champ }}
        {% endif %}
        {%- if not loop.last %},{% endif %}
        {% endfor %}
    from {{ ref('stg_ofgl_commune') }}
    group by 1, 2
),

dgfip as (
    select
        f.code_insee,
        c.nom_commune,
        c.numero_ept,
        f.annee,
        f.population_dgfip,
        {% for champ, agregat, libelle, identique, motif in concepts %}
        f.{{ champ }}{% if not loop.last %},{% endif %}
        {% endfor %}
    from {{ ref('stg_dgfip_commune') }} f
    join {{ ref('dim_commune') }} c on c.code_insee = f.code_insee
),

compare as (
    {% for champ, agregat, libelle, identique, motif in concepts %}
    select
        d.code_insee,
        d.nom_commune,
        d.numero_ept,
        d.annee,
        '{{ champ }}'   as concept,
        $${{ libelle }}$$ as libelle,
        '{{ identique }}' as attendu_identique,
        $${{ motif }}$$   as motif,
        d.{{ champ }}   as valeur_dgfip,
        o.ofgl_{{ champ }} as valeur_ofgl
    from dgfip d
    join ofgl o on o.code_insee = d.code_insee and o.annee = d.annee
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
),

population as (
    select
        d.code_insee,
        d.nom_commune,
        d.numero_ept,
        d.annee,
        'population'           as concept,
        'Population totale'    as libelle,
        'oui'                  as attendu_identique,
        'Même source de population légale.' as motif,
        d.population_dgfip * 1.0 as valeur_dgfip,
        o.population_ofgl * 1.0  as valeur_ofgl
    from dgfip d
    join ofgl o on o.code_insee = d.code_insee and o.annee = d.annee
)

select
    *,
    valeur_dgfip - valeur_ofgl as ecart_absolu,
    case
        when valeur_ofgl <> 0 then 100.0 * (valeur_dgfip - valeur_ofgl) / valeur_ofgl
    end as ecart_pct
from (
    select * from compare
    union all
    select * from population
)
