-- Charges de fonctionnement (classe 6, hors opérations d'ordre) ventilées par domaine.
--
-- Source : balances comptables DGFiP « présentation croisée nature-fonction », montants
-- en euros. Les fonctions sont ramenées à la grille unifiée M14/M57 (cf. macro
-- `code_domaine_unifie`) : au premier chiffre, les deux nomenclatures ne découpent pas
-- les mêmes domaines, donc on ne peut pas les comparer telles quelles.
--
-- « 01 » est le code normalisé des opérations non ventilables et « NV » les lignes sans
-- fonction renseignée : les deux vont dans le poste « Charges non ventilées ».
with src as (
    select
        code_insee,
        cast(annee as integer) as annee,
        nomen as nomenclature,
        case
            when fonction in ('01', 'NV') then fonction
            else substr(fonction, 1, 1)
        end as premier_chiffre,
        cast(debit as double) - cast(credit as double) as montant
    from {{ source('raw', 'dgfip_fonction_commune') }}
),
classe as (
    select
        code_insee,
        annee,
        nomenclature,
        premier_chiffre,
        {{ code_domaine_unifie('nomenclature', 'premier_chiffre') }} as code_domaine,
        montant
    from src
)
select
    code_insee,
    annee,
    code_domaine,
    {{ libelle_domaine_unifie('code_domaine') }}  as domaine,
    {{ ordre_domaine_unifie('code_domaine') }}    as ordre_domaine,
    max(nomenclature)                             as nomenclature,
    sum(montant)                                  as montant
from classe
group by 1, 2, 3, 4, 5
