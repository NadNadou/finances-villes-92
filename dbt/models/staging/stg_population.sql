-- Population légale par commune et par année (INSEE, republiée par l'OFGL).
-- `population_totale` (ptot) est la population de référence des ratios par habitant :
-- c'est celle que la DGFiP et l'OFGL utilisent pour leurs ratios légaux.
select
    code_insee,
    cast(annee as integer)                  as annee,
    nom_insee,
    cast(population_municipale as integer)  as population_municipale,
    cast(population_totale as integer)      as population_totale
from {{ source('raw', 'insee_population_annee') }}
where annee between {{ var('annee_min') }} and {{ var('annee_max') }}
