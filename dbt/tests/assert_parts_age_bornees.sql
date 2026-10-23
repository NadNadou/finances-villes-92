-- Les parts de population doivent rester dans [0, 1] : garde-fou sur l'interpolation.
select code_insee, annee, part_moins_20, part_0_10, part_65_plus
from {{ ref('int_structure_age') }}
where part_moins_20 not between 0 and 1
   or part_65_plus  not between 0 and 1
   or part_0_10     not between 0 and 1
   or part_0_10 is null
