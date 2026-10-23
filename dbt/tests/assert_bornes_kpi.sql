-- Bornes de vraisemblance sur les KPI. Tout dépassement signale une erreur de calcul
-- ou une donnée source aberrante, pas une particularité locale.
{% set controles = [
    ('population_totale',             '> 0',                    'population strictement positive'),
    ('capacite_desendettement_annees','between -50 and 100',    'capacité de désendettement entre -50 et 100 ans'),
    ('equipement_hab',                'between -500 and 10000', "dépenses d'équipement entre -500 et 10 000 €/hab"),
    ('depenses_fonctionnement_hab',   'between 200 and 10000',  'dépenses de fonctionnement entre 200 et 10 000 €/hab'),
    ('encours_dette_hab',             'between 0 and 20000',    'encours de dette entre 0 et 20 000 €/hab'),
    ('impots_locaux_hab',             'between 0 and 10000',    'impôts locaux entre 0 et 10 000 €/hab'),
    ('part_personnel_pct',            'between 0 and 100',      'part du personnel entre 0 et 100 %'),
    ('part_epargne_brute_pct',        'between -100 and 100',   "taux d'épargne brute entre -100 et 100 %"),
    ('potentiel_fiscal_hab',          'between 0 and 50000',    'potentiel fiscal entre 0 et 50 000 €/hab'),
    ('depenses_enfance_par_enfant',   'between 0 and 50000',    'dépenses enfance entre 0 et 50 000 €/enfant'),
    ('poids_impots_sur_revenu_pct',   'between 0 and 100',      'poids des impôts entre 0 et 100 % du revenu médian')
] %}
{% for modele in ['fct_finances_commune_annee', 'fct_finances_consolide'] %}
{% set boucle_modele = loop %}
{% for colonne, borne, libelle in controles %}
select
    '{{ modele }}'  as modele,
    $${{ libelle }}$$ as controle,
    code_insee,
    annee,
    {{ colonne }}   as valeur
from {{ ref(modele) }}
where {{ colonne }} is not null and not ({{ colonne }} {{ borne }})
{% if not (boucle_modele.last and loop.last) %}union all{% endif %}
{% endfor %}
{% endfor %}
