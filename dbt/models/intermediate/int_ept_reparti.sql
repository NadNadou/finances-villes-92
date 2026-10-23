-- Agrégats de l'EPT ramenés à chaque commune membre, au prorata de sa population.
--
-- Attention, piège : **les EPT ne sont pas tous contenus dans les Hauts-de-Seine.**
-- T2 Vallée Sud – Grand Paris (11 communes), T3 Grand Paris Seine Ouest (8) et
-- T4 Paris Ouest La Défense (11) le sont. T5 Boucle Nord de Seine compte en revanche
-- une commune du Val-d'Oise, **Argenteuil (95018)**, seule commune de la Métropole du
-- Grand Paris hors 75/92/93/94. Elle pèse environ un quart de la population de T5.
--
-- Utiliser la somme des populations de nos 36 communes comme dénominateur aurait donc
-- surévalué de ~33 % la part d'EPT attribuée aux 6 communes du 92 membres de T5.
-- Le dénominateur retenu est la **population totale de l'EPT telle que publiée par
-- l'OFGL** (`ptot` du groupement), qui inclut Argenteuil. Conséquence correcte et voulue :
-- la part de T5 revenant à Argenteuil n'est attribuée à aucune de nos communes.
--
-- `controle_couverture_pct` donne, par EPT et par exercice, la fraction de l'EPT couverte
-- par nos communes : ~100 % pour T2, T3, T4 et ~76 % pour T5. C'est la vérification qui a
-- permis de repérer Argenteuil, elle reste en place comme garde-fou.
--
-- Avertissement de lecture : répartir les dépenses d'un EPT au prorata de la population
-- est une **convention**, pas une mesure. Un EPT ne dépense pas uniformément par habitant
-- sur son territoire. C'est la clé la plus neutre disponible sans données infra-EPT, et
-- elle est signalée comme telle sur la page « méthode » du site.

with agregats_ept as (
    select
        siren_ept,
        annee,
        max(population_totale) as population_ept_ofgl,
        max(case when agregat = 'Recettes de fonctionnement' then montant end) as recettes_fonctionnement,
        max(case when agregat = 'Dépenses de fonctionnement' then montant end) as depenses_fonctionnement,
        max(case when agregat = 'Frais de personnel'         then montant end) as charges_personnel,
        max(case when agregat = 'Charges financières'        then montant end) as charges_financieres,
        max(case when agregat = 'Impôts locaux'              then montant end) as impots_locaux,
        max(case when agregat = 'Epargne brute'              then montant end) as epargne_brute,
        max(case when agregat = 'Encours de dette'           then montant end) as encours_dette,
        max(case when agregat = 'Annuité de la dette'        then montant end) as annuite_dette,
        -- même définition que le `equip` DGFiP : équipement + subventions d'équipement
        coalesce(max(case when agregat = 'Dépenses d''équipement' then montant end), 0)
          + coalesce(max(case when agregat = 'Subventions d''équipement versées' then montant end), 0)
            as depenses_equipement
    from {{ ref('stg_ofgl_ept') }}
    group by 1, 2
),

prorata as (
    select
        c.code_insee,
        c.siren_ept,
        c.numero_ept,
        c.nom_ept,
        p.annee,
        p.population_totale,
        sum(p.population_totale) over (partition by c.siren_ept, p.annee)
            as population_communes_92_ept
    from {{ ref('dim_commune') }} c
    join {{ ref('stg_population') }} p on p.code_insee = c.code_insee
),

cle as (
    select
        pr.*,
        a.population_ept_ofgl,
        -- dénominateur : population de l'EPT entier. Repli sur la somme de nos communes
        -- si l'OFGL ne publie pas la population de l'EPT pour cet exercice.
        coalesce(a.population_ept_ofgl, pr.population_communes_92_ept) as population_ept,
        a.recettes_fonctionnement,
        a.depenses_fonctionnement,
        a.charges_personnel,
        a.charges_financieres,
        a.impots_locaux,
        a.epargne_brute,
        a.encours_dette,
        a.annuite_dette,
        a.depenses_equipement,
        a.siren_ept is not null as ept_disponible
    from prorata pr
    left join agregats_ept a on a.siren_ept = pr.siren_ept and a.annee = pr.annee
)

select
    code_insee,
    annee,
    siren_ept,
    numero_ept,
    nom_ept,
    population_totale,
    population_ept,
    population_ept_ofgl,
    round(100.0 * population_communes_92_ept / nullif(population_ept, 0), 2)
        as controle_couverture_pct,

    population_totale * 1.0 / nullif(population_ept, 0) as part_population,

    -- agrégats de l'EPT attribués à la commune
    recettes_fonctionnement * population_totale / nullif(population_ept, 0) as ept_recettes_fonctionnement,
    depenses_fonctionnement * population_totale / nullif(population_ept, 0) as ept_depenses_fonctionnement,
    charges_personnel       * population_totale / nullif(population_ept, 0) as ept_charges_personnel,
    charges_financieres     * population_totale / nullif(population_ept, 0) as ept_charges_financieres,
    impots_locaux           * population_totale / nullif(population_ept, 0) as ept_impots_locaux,
    epargne_brute           * population_totale / nullif(population_ept, 0) as ept_epargne_brute,
    encours_dette           * population_totale / nullif(population_ept, 0) as ept_encours_dette,
    annuite_dette           * population_totale / nullif(population_ept, 0) as ept_annuite_dette,
    depenses_equipement     * population_totale / nullif(population_ept, 0) as ept_depenses_equipement,

    ept_disponible
from cle
