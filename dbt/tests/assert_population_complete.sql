-- Les 36 communes doivent avoir une population légale pour chaque année 2015-2025,
-- strictement positive, et la jointure sur le code INSEE ne doit rien perdre.
with attendu as (
    select c.code_insee, a.annee
    from {{ ref('dim_commune') }} c
    cross join (
        select unnest(range({{ var('annee_min') }}, {{ var('annee_max') }} + 1)) as annee
    ) a
)
select a.code_insee, a.annee, p.population_totale
from attendu a
left join {{ ref('stg_population') }} p
    on p.code_insee = a.code_insee and p.annee = a.annee
where p.code_insee is null
   or p.population_totale is null
   or p.population_totale <= 0
