-- Flux financiers entre une commune et son intercommunalité, en euros.
--
--   `fcct` (compte 65561) : contribution au fonds de compensation des charges
--   territoriales, soit ce que la commune verse à son EPT. C'est un **transfert interne**
--   au couple commune + EPT : il est en dépense chez la commune et en recette chez l'EPT.
--   Le neutraliser est indispensable pour que le périmètre consolidé ne compte pas deux
--   fois la même somme.
--
--   `attribution_compensation` (compte 73211) : attribution de compensation reçue de la
--   Métropole du Grand Paris. La Métropole est **extérieure** au couple commune + EPT :
--   cette ressource ne doit pas être neutralisée. On la mesure pour pouvoir le montrer.
--
-- Somme et non maximum : plusieurs comptes alimentent le même flux (65541 en M14 et
-- 65561 en M57 pour le FCCT, 73211 et 73212 pour l'attribution de compensation), et une
-- même commune peut en avoir deux renseignés sur un exercice de transition.
select
    code_insee,
    cast(annee as integer) as annee,
    sum(case when flux = 'fcct'                     then montant else 0 end) as fcct,
    sum(case when flux = 'attribution_compensation' then montant else 0 end) as attribution_compensation
from {{ source('raw', 'dgfip_flux_ept') }}
group by 1, 2
