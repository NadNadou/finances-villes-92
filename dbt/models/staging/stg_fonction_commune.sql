-- Charges de fonctionnement (classe 6, hors opérations d'ordre) ventilées par fonction.
--
-- Source : balances comptables DGFiP « présentation croisée nature-fonction », en euros.
--
-- Deux normalisations indispensables avant de pouvoir comparer quoi que ce soit.
--
-- 1. **Les communes qui votent leur budget par fonction préfixent le code par le
--    chapitre.** Dans le 92, c'est le cas de Boulogne-Billancourt (92012) et d'elle seule :
--    98 à 100 % de ses codes commencent par 9, contre moins de 10 % ailleurs (où les
--    codes 90x à 96x sont de vraies sous-fonctions d'action économique). Chez elle,
--    « 9264 » est le chapitre 92 (fonctionnement) + fonction 64 (crèches, 22,6 M€ en 2015)
--    et « 934222 » le chapitre 93 + fonction 4222 (crèches, 22,1 M€ en 2024). Les
--    chapitres 94x à 96x portent les opérations non ventilées (charges financières,
--    groupes d'élus). La détection est faite **par commune et par exercice** sur la part
--    de codes commençant par 9, jamais en dur sur un code INSEE.
--
-- 2. **La grille fonctionnelle M14 et la grille M57 ne découpent pas les mêmes domaines
--    au premier chiffre** (cf. macros/domaine_fonctionnel.sql). Le mapping dépend donc de
--    la nomenclature de la commune pour l'exercice.
--
-- Les codes contiennent parfois des séparateurs (« 020.90 », « 020& ») : on ne garde que
-- les chiffres avant de découper.

with brut as (
    select
        code_insee,
        cast(annee as integer) as annee,
        nomen as nomenclature,
        fonction,
        cast(debit as double) - cast(credit as double) as montant
    from {{ source('raw', 'dgfip_fonction_commune') }}
),

-- Une commune vote par fonction, ou pas : c'est un choix de présentation budgétaire
-- qui vaut pour tout l'exercice. On le déduit de la part de codes commençant par 9.
mode_vote as (
    select
        code_insee,
        annee,
        sum(case when fonction like '9%' then 1 else 0 end) * 1.0 / count(*) > 0.8
            as vote_par_fonction
    from brut
    group by 1, 2
),

normalise as (
    select
        b.code_insee,
        b.annee,
        b.nomenclature,
        b.fonction as fonction_source,
        v.vote_par_fonction,
        case
            when b.fonction = 'NV' then 'NV'
            -- présentation par chapitre : 92x (M14) / 93x (M57) = fonctionnement ventilé
            when v.vote_par_fonction and regexp_matches(b.fonction, '^9[23]')
                then regexp_replace(substr(b.fonction, 3), '[^0-9]', '', 'g')
            -- présentation par chapitre : 90x, 91x, 94x à 96x = opérations non ventilées
            when v.vote_par_fonction and regexp_matches(b.fonction, '^9')
                then 'NV'
            else regexp_replace(b.fonction, '[^0-9]', '', 'g')
        end as fonction_nette,
        b.montant
    from brut b
    join mode_vote v on v.code_insee = b.code_insee and v.annee = b.annee
),

classe as (
    select
        code_insee,
        annee,
        nomenclature,
        fonction_nette,
        case
            when fonction_nette in ('', 'NV', '01') then 'NV'
            else substr(fonction_nette, 1, 1)
        end as premier_chiffre,
        -- Petite enfance (crèches et garderies) : la seule sous-fonction dont on a besoin
        -- au-delà du premier chiffre, pour la question 4.
        --   M14 : 64x « Crèches et garderies »
        --   M57 : 422x « Petite enfance »
        -- Contrôlé sur les 16 communes encore en M14 en 2023 : le total 64x de 2023 et le
        -- total 422x de 2024 se recollent à quelques pourcents près.
        case
            when nomenclature = 'M14' and fonction_nette like '64%'  then true
            when nomenclature <> 'M14' and fonction_nette like '422%' then true
            else false
        end as est_petite_enfance,
        montant
    from normalise
)

select
    code_insee,
    annee,
    nomenclature,
    {{ code_domaine_unifie('nomenclature', 'premier_chiffre') }} as code_domaine,
    est_petite_enfance,
    sum(montant) as montant
from classe
group by 1, 2, 3, 4, 5
