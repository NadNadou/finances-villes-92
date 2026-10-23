-- Les écarts aux références extérieures doivent rester sous les seuils annoncés :
--   - ratios légaux DGFiP : moins de 2 % (c'est la même source, nous ne faisons que
--     recalculer le ratio à partir du montant et de la population) ;
--   - documents budgétaires marqués `comparable = oui` : moins de 15 % (un budget
--     primitif n'est pas un compte administratif).
-- Les lignes marquées `comparable = non` sont exclues : leur écart est attendu et son
-- motif est écrit dans le seed `ref_ratios_legaux`.
--
-- Un plancher en valeur absolue accompagne le seuil relatif : sur un ratio quasi nul,
-- un écart d'arrondi devient un énorme pourcentage. Puteaux ne touche par exemple que
-- 0,13 €/hab de DGF en 2020 ; l'arrondi au centime y vaut 3,7 %.
select
    reference,
    code_insee,
    nom_commune,
    annee,
    ratio,
    valeur_calculee,
    valeur_reference,
    ecart_absolu,
    ecart_pct
from {{ ref('fct_controle_qualite') }}
where comparable = 'oui'
  and valeur_calculee is not null
  and valeur_reference is not null
  and abs(ecart_pct) > case when reference = 'ratio légal DGFiP' then 2.0 else 15.0 end
  and abs(ecart_absolu) > case when unite = '%' then 0.5 else 1.0 end
