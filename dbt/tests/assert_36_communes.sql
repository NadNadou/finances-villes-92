-- Le département compte 36 communes : toute autre valeur est une erreur d'ingestion.
select count(*) as n
from {{ ref('dim_commune') }}
having count(*) <> 36
