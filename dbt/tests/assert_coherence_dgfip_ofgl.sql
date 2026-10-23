-- Les concepts dont les deux éditeurs publient la même définition doivent coïncider.
-- Tolérance : 0,1 % en relatif ET 1 000 € en absolu — les comptes individuels DGFiP sont
-- publiés en milliers d'euros, donc arrondis au millier, ce qui suffit à créer un écart
-- de quelques centaines d'euros face aux montants OFGL, publiés à l'euro près.
--
-- Les concepts marqués `attendu_identique = 'non'` sont exclus : leur écart est une
-- différence de définition documentée dans la colonne `motif`, établie à partir des
-- formules que l'OFGL publie lui-même (dataset
-- `methodologie-ofgl-formules-des-agregats-financiers`).
select
    concept,
    motif,
    code_insee,
    nom_commune,
    annee,
    valeur_dgfip,
    valeur_ofgl,
    ecart_absolu,
    ecart_pct
from {{ ref('fct_controle_sources') }}
where attendu_identique = 'oui'
  and valeur_dgfip is not null
  and valeur_ofgl is not null
  and abs(ecart_pct) > 0.1
  and abs(ecart_absolu) > 1000
