-- Les 4 EPT doivent avoir des agrégats sur tous les exercices où OFGL en publie.
-- Trou connu et documenté : 2016-2017 (l'API OFGL ne remonte pas avant 2018) et 2015
-- (les EPT n'existaient pas : création au 1er janvier 2016).
with couverture as (
    select siren_ept, count(distinct annee) as n_annees
    from {{ ref('stg_ofgl_ept') }}
    group by 1
),
attendu as (
    select max(n_annees) as n from couverture
)
select c.siren_ept, c.n_annees
from couverture c, attendu a
where c.n_annees <> a.n
