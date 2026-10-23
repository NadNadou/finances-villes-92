-- Aucune ligne des sources INSEE ne doit porter un code commune absent du référentiel.
{% set sources_insee = [
    'stg_population', 'stg_age_tranches', 'stg_age_detail',
    'stg_filosofi', 'stg_equipements'
] %}
{% for modele in sources_insee %}
select '{{ modele }}' as modele, s.code_insee
from {{ ref(modele) }} s
left join {{ ref('dim_commune') }} d on d.code_insee = s.code_insee
where d.code_insee is null
{% if not loop.last %}union all{% endif %}
{% endfor %}
