-- Classement des 36 communes sur chacun des 6 KPI, **dernière année disponible** pour
-- chaque KPI (elle n'est pas la même partout : le potentiel fiscal est publié sur un
-- millésime d'avance, le revenu médian n'existe qu'en 2023).
--
-- Format long : une ligne par commune x périmètre x KPI. C'est ce qui permet au tableau
-- du site d'être triable par KPI sans dupliquer la requête.
--
-- `sens` dit comment lire le rang : « élevé = plus » signifie que le rang 1 est la valeur
-- la plus forte (dépenses d'équipement), « élevé = moins bien » que le rang 1 est la
-- valeur la plus faible (capacité de désendettement, où moins d'années vaut mieux).

{% set kpis = [
    ('equipement',  'Q1', "Dépenses d'équipement par habitant (moyenne 3 ans)", 'equipement_hab_moy3',            '€/hab', 'desc', 'Plus la valeur est élevée, plus la ville investit.'),
    ('desendettement', 'Q2', 'Capacité de désendettement',                      'capacite_desendettement_brute',  'années', 'asc',  "Nombre d'années d'épargne nécessaires pour rembourser la dette. Au-delà de 12 ans, l'alerte est classique."),
    ('enfance',     'Q4', 'Dépenses écoles et petite enfance par enfant de 0 à 10 ans', 'depenses_enfance_par_enfant', '€/enfant', 'desc', "Plus la valeur est élevée, plus la ville dépense par enfant."),
    ('impots',      'Q5', 'Impôts locaux par habitant',                         'impots_locaux_hab',              '€/hab', 'asc',  "Ce que les habitants paient à la commune, par habitant."),
    ('poids_impots','Q5', 'Impôts locaux rapportés au niveau de vie médian',    'poids_impots_sur_revenu_pct',    '%',     'asc',  "Impôts locaux par habitant divisés par le niveau de vie médian annuel."),
    ('potentiel',   'Q6', 'Potentiel fiscal par habitant',                      'potentiel_fiscal_hab',           '€/hab', 'desc', "Richesse fiscale théorique de la commune, indépendante de ses taux."),
    ('fonctionnement', 'C', 'Dépenses de fonctionnement par habitant',          'depenses_fonctionnement_hab',    '€/hab', 'asc',  "Coût de fonctionnement annuel du service public communal, par habitant."),
    ('dette_hab',   'C',  'Encours de dette par habitant',                      'encours_dette_hab',              '€/hab', 'asc',  "Dette restant à rembourser, par habitant."),
    ('personnel',   'C',  'Part des charges de personnel',                      'part_personnel_pct',             '%',     'asc',  "Part du personnel dans les dépenses de fonctionnement."),
    ('epargne',     'C',  'Taux d''épargne brute',                              'part_epargne_brute_pct',         '%',     'desc', "Part des recettes de fonctionnement qui reste disponible pour investir et rembourser.")
] %}

{% set perimetres = [
    ('commune',       'fct_finances_commune_annee'),
    ('commune + EPT', 'fct_finances_consolide')
] %}

with unpivot_source as (
    {% for perimetre, modele in perimetres %}
    {% set boucle_perimetre = loop %}
    {% for cle, question, libelle, colonne, unite, sens, explication in kpis %}
    select
        code_insee,
        nom_commune,
        numero_ept,
        nom_ept,
        population_totale,
        annee,
        '{{ perimetre }}'   as perimetre,
        '{{ cle }}'         as kpi,
        '{{ question }}'    as question,
        $${{ libelle }}$$   as kpi_libelle,
        '{{ unite }}'       as unite,
        '{{ sens }}'        as sens_tri,
        $${{ explication }}$$ as explication,
        {{ colonne }}       as valeur
    from {{ ref(modele) }}
    {% if not (boucle_perimetre.last and loop.last) %}union all{% endif %}
    {% endfor %}
    {% endfor %}
),

-- Dernière année où le KPI est réellement renseigné (au moins 30 des 36 communes).
derniere_annee as (
    select perimetre, kpi, max(annee) as annee_retenue
    from (
        select perimetre, kpi, annee, count(valeur) as n
        from unpivot_source
        group by 1, 2, 3
    )
    where n >= 30
    group by 1, 2
),

retenu as (
    select u.*
    from unpivot_source u
    join derniere_annee d
        on d.perimetre = u.perimetre and d.kpi = u.kpi and d.annee_retenue = u.annee
),

stats as (
    select
        perimetre,
        kpi,
        avg(valeur)                                          as moyenne_92,
        median(valeur)                                       as mediane_92,
        min(valeur)                                          as min_92,
        max(valeur)                                          as max_92,
        count(valeur)                                        as nb_communes_renseignees,
        -- moyenne pondérée par la population : la bonne référence pour un ratio /hab
        sum(valeur * population_totale) / nullif(sum(case when valeur is not null then population_totale end), 0)
            as moyenne_ponderee_92
    from retenu
    group by 1, 2
)

select
    r.code_insee,
    r.nom_commune,
    r.numero_ept,
    r.nom_ept,
    r.population_totale,
    r.annee,
    r.perimetre,
    r.kpi,
    r.question,
    r.kpi_libelle,
    r.unite,
    r.sens_tri,
    r.explication,
    r.valeur,
    -- Les communes sans valeur sont classées en dernier plutôt qu'exclues : le tableau
    -- du site doit montrer les 36 lignes, avec une mention « non disponible ».
    case
        when r.sens_tri = 'desc'
            then rank() over (partition by r.perimetre, r.kpi order by r.valeur desc nulls last)
        else rank() over (partition by r.perimetre, r.kpi order by r.valeur asc nulls last)
    end as rang,
    r.valeur is not null as valeur_disponible,
    s.nb_communes_renseignees,
    s.moyenne_92,
    s.moyenne_ponderee_92,
    s.mediane_92,
    s.min_92,
    s.max_92,
    case
        when s.mediane_92 <> 0 then 100.0 * r.valeur / s.mediane_92 - 100.0
    end as ecart_mediane_pct
from retenu r
join stats s on s.perimetre = r.perimetre and s.kpi = r.kpi
