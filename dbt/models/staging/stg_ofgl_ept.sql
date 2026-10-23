-- Agrégats OFGL des 4 EPT du 92 (budget principal), format long.
select
    siren                                   as siren_ept,
    cast(annee as integer)                  as annee,
    lbudg                                   as nom_ept_ofgl,
    agregat,
    cast(montant as double)                 as montant,
    cast(euros_par_habitant as double)      as euros_par_habitant,
    cast(ptot as integer)                   as population_totale,
    nomen                                   as nomenclature
from {{ source('raw', 'ofgl_ept_agregat') }}
