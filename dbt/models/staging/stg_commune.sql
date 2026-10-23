-- Référentiel des communes : une ligne par commune du 92.
select
    code_insee,
    nom_commune,
    siren_commune,
    population_geo,
    surface_ha,
    code_epci,
    nom_epci,
    siren_ept,
    numero_ept,
    nom_ept
from {{ source('raw', 'geo_communes') }}
