-- Agrégats OFGL des communes (budget principal), format long : une ligne par agrégat.
-- Sert de source de contrôle croisé face à la DGFiP et apporte quelques agrégats
-- que les comptes individuels n'isolent pas (fiscalité reversée, épargne de gestion…).
select
    insee                                   as code_insee,
    cast(annee as integer)                  as annee,
    com_name                                as nom_ofgl,
    agregat,
    cast(montant as double)                 as montant,
    cast(euros_par_habitant as double)      as euros_par_habitant,
    cast(ptot as integer)                   as population_totale,
    nomen                                   as nomenclature
from {{ source('raw', 'ofgl_commune_agregat') }}
where insee is not null
