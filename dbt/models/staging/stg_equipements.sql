-- Nombre d'équipements par commune (base permanente des équipements, dernier millésime).
with p as (
    select
        code_insee,
        cast(millesime as integer) as millesime,
        code_equipement,
        cast(nombre as double)     as nombre
    from {{ source('raw', 'insee_equipements') }}
)
select
    code_insee,
    millesime,
    coalesce(max(case when code_equipement = 'C1'   then nombre end), 0) as nb_ecoles,
    coalesce(max(case when code_equipement = 'C2'   then nombre end), 0) as nb_colleges,
    coalesce(max(case when code_equipement = 'C3'   then nombre end), 0) as nb_lycees,
    coalesce(max(case when code_equipement = 'D502' then nombre end), 0) as nb_creches,
    coalesce(max(case when code_equipement = 'F1'   then nombre end), 0) as nb_equipements_sportifs,
    coalesce(max(case when code_equipement = 'F3'   then nombre end), 0) as nb_equipements_culturels
from p
group by 1, 2
