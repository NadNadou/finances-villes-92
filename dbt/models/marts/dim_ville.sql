-- Référentiel des 36 villes exposé au site (sélecteurs de commune).
select
    code_insee,
    nom_commune,
    numero_ept,
    nom_ept,
    siren_ept,
    nom_commune || ' (' || numero_ept || ')' as libelle_selecteur
from {{ ref('dim_commune') }}
order by nom_commune
