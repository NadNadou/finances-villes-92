{#
  Test réutilisable : (code_insee, annee) doit être une clé unique.
  Écrit à la main plutôt qu'importé de dbt_utils, pour garder le projet sans dépendance
  de paquet (un `dbt deps` en moins à faire tourner en CI).
#}
{% test unicite_commune_annee(model) %}
select code_insee, annee, count(*) as n
from {{ model }}
group by 1, 2
having count(*) > 1
{% endtest %}
