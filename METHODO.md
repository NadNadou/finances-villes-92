# Méthodologie

Document de traçabilité : sources exactes, hypothèses, écarts. Mis à jour à chaque étape.

## État

Étape 1 (socle) faite. Les sections ci-dessous se remplissent au fil des étapes.

## Sources retenues

(voir étape 3 et suivantes)

---

## Étape 2 — Référentiel des 36 communes

| Besoin | Source exacte | Identifiant | Accès |
|---|---|---|---|
| Liste des communes, code INSEE, nom, SIREN, population, surface | API Géo | `https://geo.api.gouv.fr/communes?codeDepartement=92&fields=nom,code,population,siren,epci,surface` | ouvert, sans clé |
| EPT de rattachement | OFGL (Opendatasoft) | dataset `infos-rei`, champs `sirept` / `libept`, filtre `dep="92"` | ouvert, sans clé |

Résultat : **36 communes, 36 avec un EPT, 4 EPT distincts.**

| EPT | SIREN | Communes du 92 |
|---|---|---|
| T2 Vallée Sud – Grand Paris | 200057966 | 11 |
| T3 Grand Paris Seine Ouest | 200057974 | 8 |
| T4 Paris Ouest La Défense | 200057982 | 11 |
| T5 Boucle Nord de Seine | 200057990 | 6 |

### Hypothèses et choix

- **BANATIC n'a pas été utilisé.** Le champ `sirept` du dataset OFGL `infos-rei` donne
  directement le SIREN de l'EPT pour chacune des 36 communes ; c'est une source API, donc
  rafraîchissable automatiquement, là où BANATIC impose un téléchargement de fichier.
  La table en dur `EPT_92` dans `ingest/geo.py` ne sert que de garde-fou : elle vérifie que
  le SIREN renvoyé fait bien partie des 4 EPT attendus et attache le numéro de territoire
  (T2…T5). Si OFGL renvoyait un SIREN inconnu, l'ingestion le signalerait sans planter.
- **Les 4 EPT sont entièrement contenus dans les Hauts-de-Seine** : 11 + 8 + 11 + 6 = 36.
  Conséquence importante pour l'étape 5 : la population de chaque EPT est la somme de celle
  de ses communes du 92, donc le prorata de répartition de l'EPT n'a pas de « fuite » vers
  un autre département.
- L'EPCI renvoyé par l'API Géo est la **Métropole du Grand Paris** (SIREN 200054781) pour
  les 36 communes. C'est exact mais inutilisable pour comparer : le niveau qui porte les
  compétences opérationnelles (voirie, déchets, équipements sportifs et culturels selon les
  territoires) est l'EPT. On garde les deux champs.
- `population_geo` de l'API Géo est une population municipale de millésime non documenté
  par l'API ; elle n'est **pas** utilisée pour les ratios. Les ratios par habitant utilisent
  la population totale OFGL/DGFiP de l'exercice concerné (étape 4).

---

## Étape 3 — Ingestion des finances

### Ce que la source « attendue » ne permettait pas

Le brief prévoyait OFGL (`data.ofgl.fr`) comme source principale pour 2015-2024.
**L'API Explore d'OFGL ne publie plus que les exercices 2018 à 2025** : les datasets
`ofgl-base-communes` et `ofgl-base-gfp` renvoient 8 millésimes, pas 10. Vérifié par
`group_by=exer` sur le dataset entier, pas seulement sur le 92.

La source retenue pour l'historique complet est donc la DGFiP :
**« Comptes individuels des communes — fichier global »** sur `data.economie.gouv.fr`,
un dataset par millésime, qui couvre 2015 à 2025. Avantage décisif : ce sont exactement
les chiffres des fiches « comptes individuels des collectivités » de `impots.gouv.fr/cll`,
donc les ratios légaux de l'étape 7 sont comparables par construction.

### Sources réellement utilisées

| Rôle | Plateforme | Dataset | Filtre | Couverture obtenue |
|---|---|---|---|---|
| Agrégats des 36 communes (référence) | data.economie.gouv.fr (DGFiP) | `comptes-individuels-des-communes-fichier-global-{2011-2015, 2016, 2017, 2018, 2019-2020, 2021, 2022, 2023-2024, 2025}` | `dep="092"` | **2015-2025, 36 × 11 = 396 lignes, sans trou** |
| Agrégats des 4 EPT | data.ofgl.fr | `ofgl-base-gfp`, `type_de_budget='Budget principal'` | `siren in (4 EPT)` | **2018-2025, 4 × 8 = 32 lignes** |
| Contrôle croisé des communes | data.ofgl.fr | `ofgl-base-communes`, budget principal | `dep_code='92'` | 2018-2025, 14 117 lignes (format long) |
| Potentiel fiscal, potentiel financier, effort fiscal | data.ofgl.fr | `dotations-communes` | `code_departement="92"` | 2018-2026, 3 336 lignes |
| Dépenses de fonctionnement par fonction | data.economie.gouv.fr (DGFiP) | `balances-comptables-…-presentation-croisee-nature-fonction` (un dataset par exercice, slugs historiques non devinables : voir `BALANCES` dans `ingest/dgfip.py`) | `ndept="092" and categ="Commune" and cbudg="1" and compte like "6*"` | 2015-2025, 22 198 lignes |

Le journal machine des sources (URL, identifiants, filtres, date d'ingestion) est écrit
automatiquement dans `data/raw/_sources.json` par `ingest/common.py:noter_source`.

### Unités et conventions

- Les comptes individuels DGFiP sont publiés **en milliers d'euros**. `stg_dgfip_commune`
  les repasse en euros une fois pour toutes : plus aucun modèle aval ne manipule des k€.
- Dans les comptes individuels, les préfixes de champ sont : `f*` = ratio €/hab de la
  commune, `m*` = moyenne €/hab de la strate, `r*` = ratio en % de la commune,
  `rm*` = moyenne de ce ratio sur la strate. Les champs `f*`, `m*`, `r*`, `rm*` sont
  conservés sous le préfixe `ctrl_` / `strate_` et servent **uniquement de contrôle** :
  tous les KPI du projet sont recalculés à partir des montants et de la population.
- Les agrégats OFGL sont en euros et au format long (une ligne par agrégat).

### Écarts de périmètre identifiés

1. **DGFiP `equip` ≠ OFGL « Dépenses d'équipement ».** Vérifié sur Vanves 2023 :
   OFGL « Dépenses d'équipement » 7 782 118 € + « Subventions d'équipement versées »
   101 536 € = 7 883 654 €, soit exactement le `equip` DGFiP (7 883,65 k€).
   Autrement dit **le `equip` DGFiP inclut les subventions d'équipement versées**.
   C'est la définition du ratio légal d'équipement, donc c'est celle qu'on garde.
2. **DGFiP `charge` ≠ OFGL « Dépenses de fonctionnement ».** Vanves 2023 : 47 755 k€
   contre 38 714 k€. L'agrégat OFGL est la somme stricte personnel + achats et charges
   externes + dépenses d'intervention + charges financières + autres ; le `charge` DGFiP
   est le total des charges de fonctionnement du compte de résultat, atténuations de
   produits (chapitre 014 : FSRIF, FPIC, reversements) comprises. Vanves est contributeur
   net au FSRIF, d'où l'écart. **C'est le `charge` DGFiP qui correspond au ratio légal
   « dépenses réelles de fonctionnement par habitant »**, donc c'est celui qu'on garde.
3. **DGFiP `impo1` ≠ OFGL « Impôts locaux ».** Vanves 2023 : 31 482 k€ contre 29 510 k€.
   On retient `impo1` (produit des contributions directes tel que publié dans les fiches
   de comptes individuels), cohérent avec le reste de la série.

### Trous, et pourquoi

| Trou | Portée | Cause | Traitement |
|---|---|---|---|
| EPT 2015 | 4 EPT | Les EPT n'existent qu'à partir du 1er janvier 2016 (loi NOTRe). | Normal, pas un trou. |
| EPT 2016-2017 | 4 EPT | L'API OFGL ne publie plus ces exercices. Le fichier DGFiP `comptes-individuels-des-groupements-a-fiscalite-propre-fichier-global-*` les couvre, mais ses champs sont **non documentés** (aucun libellé dans les métadonnées) et une tentative de mapping automatique par rapprochement de valeurs avec OFGL 2024 n'a identifié de façon fiable que 5 champs sur 40. Utiliser les autres aurait voulu dire inventer une définition. | **NULL**, documenté. Les KPI consolidés (commune + part EPT) commencent donc en 2018. |
| `encours_dette_bancaire` 2015 | 36 communes | Le champ `encdbr` n'existait pas dans le millésime 2011-2015. | NULL ; on utilise `encours_dette` (`dette`), présent partout. |
| Ventilation par fonction de Marnes-la-Coquette (92047) | toutes années | La commune (1 700 hab) est absente du dataset des balances pour `categ="Commune"`. La présentation fonctionnelle n'est obligatoire qu'au-delà de 3 500 habitants. | NULL ; la question 3 est sans réponse pour cette commune, affiché comme tel. |
| Potentiel fiscal 2015-2017 | 36 communes | `dotations-communes` démarre en 2018. | NULL ; la question 6 commence en 2018. |

### La grille fonctionnelle M14 / M57 : le piège de la question 3

Les 36 communes ont basculé de la nomenclature M14 à la M57 entre 2019 et 2024 (35 des
36 sont en M57 depuis 2024). **Au premier chiffre, les deux grilles ne découpent pas les
mêmes domaines** : en M14 « 3 » = Culture et « 4 » = Sport et jeunesse, alors qu'en M57
« 3 » = Culture, sport et jeunesse et « 4 » = Santé et action sociale. Comparer un « 3 »
de 2022 à un « 3 » de 2024 n'aurait aucun sens, et la liste de domaines donnée dans le
brief est celle de la M57 seulement.

On agrège donc les deux grilles dans **7 domaines + 1 poste non ventilé**, qui est le
découpage le plus fin identique dans les deux nomenclatures (macro
`dbt/macros/domaine_fonctionnel.sql`) :

| Domaine affiché | M14 | M57 |
|---|---|---|
| Écoles et enseignement | 2 | 2 |
| Social, santé et famille | 5 + 6 | 4 |
| Culture, sport et jeunesse | 3 + 4 | 3 |
| Cadre de vie (voirie, espaces verts, déchets, logement, transports) | 7 + 8 | 5 + 7 + 8 |
| Sécurité et salubrité | 1 | 1 |
| Action économique | 9 | 6 |
| Administration et services généraux | 0 | 0 |
| Charges non ventilées | 01 et lignes sans fonction | idem |

**Contrôle de continuité** — Vanves, part de chaque domaine, autour du changement de
nomenclature (2023 en M14, 2024 en M57) :

| Domaine | 2022 M14 | 2023 M14 | 2024 M57 | 2025 M57 |
|---|---|---|---|---|
| Enseignement | 16,5 % | 17,4 % | 17,2 % | 17,5 % |
| Social, santé, famille | 15,4 % | 14,7 % | 14,8 % | 14,5 % |
| Culture, sport, jeunesse | 23,9 % | 23,7 % | 23,4 % | 22,8 % |
| Cadre de vie | 2,9 % | 3,1 % | 2,6 % | 2,7 % |
| Administration | 21,4 % | 21,3 % | 21,6 % | 22,3 % |

Aucune rupture au passage M14 → M57 : la grille unifiée tient.

Base de calcul de la question 3 : **comptes de classe 6, hors comptes 68 (dotations aux
amortissements et provisions), 675 et 676 (opérations d'ordre sur cessions)**, mesurés en
opérations budgétaires nettes (`obnetdeb − obnetcre`). Ce total est inférieur de 3 à 10 %
au `charge` DGFiP, parce que `charge` comprend aussi les atténuations de produits
(chapitre 014, comptes de classe 7) que la ventilation fonctionnelle ne porte pas.
La question 3 étant une **répartition**, cet écart de base n'affecte pas la lecture ;
il est signalé sur la page « méthode » du site.

### Contrainte technique notable

L'API Opendatasoft refuse `offset + limit > 10 000`. Les balances comptables du 92
dépassent cette limite dès une seule année en lignes brutes. L'agrégation est donc faite
**côté serveur** via `group_by=insee,fonction,nomen`, ce qui ramène à ~2 000 lignes par
exercice. `ingest/common.py:ods_records` affiche un avertissement explicite si une requête
atteint quand même le plafond, pour qu'une troncature silencieuse soit impossible.

---

## Étape 4 — Population, âges, revenus, équipements

### Sources réellement utilisées

| Besoin | Plateforme | Dataset | Couverture obtenue |
|---|---|---|---|
| Population légale par commune et par année | data.ofgl.fr | `populations-ofgl-communes` (`pmun`, `ptot`) | **2012-2025, 36 × 14 lignes** |
| Tranches d'âge larges (< 15, < 20, 20-64, 65+, 80+) | api.insee.fr/melodi | `DS_RP_POPULATION_PRINC` | millésimes de recensement **2012, 2017, 2023** |
| Population par âge révolu (0, 1, 2… ans) | api.insee.fr/melodi | `DS_RP_TD_POPULATION_AGESEX_PRINC` | millésime **2023** uniquement |
| Niveau de vie médian, taux de pauvreté | api.insee.fr/melodi | `DS_FILOSOFI_CC` | millésime **2023** uniquement |
| Écoles, collèges, lycées, crèches, équipements sportifs et culturels | api.insee.fr/melodi | `DS_BPE` | millésime **2025** |

### Pourquoi la population passe par l'OFGL et non par insee.fr

Le brief prévoyait « INSEE recensement (séries historiques par commune) — CSV ». Les
populations légales sont bien publiées par l'INSEE, mais en **fichiers zip dont l'URL
contient un identifiant numérique qui change à chaque millésime** : impossible à
rafraîchir sans surveillance manuelle, donc incompatible avec un cron mensuel.
Le dataset `populations-ofgl-communes` republie les mêmes populations légales INSEE
(`pmun` = population municipale, `ptot` = population totale) via une API stable.
C'est aussi, et c'est le point important, **exactement la population que la DGFiP et
l'OFGL utilisent au dénominateur de leurs ratios par habitant** : vérifié sur Vanves,
`ptot` 2025 = 28 794, soit la population affichée dans le BP 2026 de la commune.
Tous les ratios « par habitant » du projet utilisent `population_totale` (`ptot`).

### Comment la structure par âge est reconstituée par année

Le recensement ne donne la structure par âge qu'aux millésimes 2012, 2017 et 2023, et
la population par âge révolu qu'au seul millésime 2023. La question 4 demande pourtant un
dénominateur annuel. Méthode retenue dans `int_structure_age` :

1. **Parts mesurées** aux millésimes de recensement (< 15, < 20, 65+, 80+).
2. **Interpolation linéaire** de ces parts entre deux millésimes ; part maintenue
   constante avant 2012 et après 2023.
3. **Part des 0-10 ans** : mesurée au seul millésime 2023, puis ajustée par l'évolution
   de la part des moins de 15 ans, elle mesurée aux trois millésimes :
   `part_0_10(a) = part_0_10(2023) × part_moins_15(a) / part_moins_15(2023)`.
4. **Effectifs** = part (mesurée ou estimée) × population légale de l'année (mesurée).

La colonne `methode_part_age` indique pour chaque ligne lequel des trois cas s'applique
(`mesuré (recensement 2017)`, `interpolé entre les recensements 2017 et 2023`,
`part du recensement 2023 maintenue (année postérieure)`), et `methode_part_0_10` rappelle
la règle d'ajustement. Le site affiche cette mention. Rien n'est inventé : chaque valeur
est soit une mesure, soit une transformation déclarée d'une mesure.

Un test dbt (`assert_parts_age_bornees`) vérifie que toutes les parts restent dans [0, 1].

### Limites assumées

| Limite | Conséquence | Traitement |
|---|---|---|
| **Filosofi n'existe qu'en millésime 2023** sur l'API Melodi. Les millésimes antérieurs ne sont disponibles qu'en zip sur insee.fr (URL non stable). Testé : `DS_FILOSOFI_CC_2019…2022_CSV_FR` renvoient HTTP 400. | Le revenu médian par UC est une photo 2023, pas une série. | La question 5 affiche son ratio pour la **dernière année disponible** avec le revenu médian 2023 au dénominateur, et la série temporelle montre le numérateur seul (impôts locaux par habitant), qui est, lui, une vraie série. Mentionné sur la page « méthode ». |
| Les déciles D1/D9, le rapport interdécile et l'indice de Gini sont demandés mais renvoyés **vides** par Filosofi au niveau communal (secret statistique). | Colonnes présentes, valeurs `NULL`. | Non utilisées dans les KPI. |
| **La BPE n'expose pas de capacité** pour les crèches : seule la mesure `FACILITIES` (nombre d'établissements) est disponible, pas `CAPACITY`. Le brief demandait « nombre de places de crèche ». | Pas de nombre de places. | On publie le **nombre d'établissements d'accueil du jeune enfant** (code BPE `D502`). Écart explicitement signalé sur le site. |
| La BPE n'est ingérée qu'au dernier millésime (2025). | Pas d'historique d'équipements. | Les équipements servent de contexte, pas de KPI. |

### Vérification des codes BPE

Les métadonnées Melodi ne publient pas les libellés de `FACILITY_TYPE` (aucun endpoint
`codelist` : testé, HTTP 404). Les codes retenus ont donc été validés par ordre de
grandeur sur l'ensemble du département :

| Code | Total 92 | Vanves | Malakoff | Boulogne-Billancourt | Lecture |
|---|---|---|---|---|---|
| `C1` (sous-domaine) | 693 | 8 | 13 | 39 | nombre d'écoles — cohérent avec ~700 écoles dans le 92 |
| `C2` (sous-domaine) | 155 | 2 | 3 | 10 | collèges — cohérent avec ~155 collèges dans le 92 |
| `D502` | 583 | 7 | 6 | 52 | établissements d'accueil du jeune enfant |

Pour les écoles, collèges et lycées on utilise le **sous-domaine** (`FACILITY_TYPE = '_T'`),
plus stable d'un millésime à l'autre que les types fins. Les crèches n'ont pas de
sous-domaine dédié (`D5` mélange plusieurs publics), d'où le recours au type `D502`.

---

## Étape 5 — Modèles dbt et définition des KPI

### Architecture des modèles

```
sources (data/raw/*.parquet)
  └─ staging/     stg_commune  stg_dgfip_commune  stg_ofgl_commune  stg_ofgl_ept
                  stg_dotations  stg_fonction_commune  stg_population
                  stg_age_tranches  stg_age_detail  stg_filosofi  stg_equipements
      └─ intermediate/  dim_commune  int_structure_age  int_ept_reparti  int_base_kpi
          └─ marts/     fct_finances_commune_annee  fct_finances_consolide
                        fct_depenses_domaine  fct_classement_92  fct_controle_qualite
```

Les marts sont matérialisés en `external` : dbt écrit chacun en parquet dans
`data/marts/`, qui est ce que lit le site Evidence (`external_root` dans `profiles.yml`).

`int_base_kpi` rassemble, par commune et par exercice, les montants de la commune, la part
d'EPT qui lui revient, la population et le contexte socio-démographique. Les deux tables
de faits appliquent ensuite **la même macro** (`macros/bloc_kpi.sql`) à deux jeux de
montants différents. C'est la condition pour que la bascule « commune seule / commune +
EPT » du site compare bien la même chose : il n'existe qu'une seule écriture de chaque
formule, de chaque seuil et de chaque cas de nullité.

### Définition exacte des 6 KPI

| # | Question | Colonne | Formule | Cas de nullité |
|---|---|---|---|---|
| 1 | Qui construit le plus ? | `equipement_hab`, `equipement_hab_moy3` | dépenses d'équipement (subventions d'équipement versées incluses, définition du ratio légal) / population totale ; moyenne glissante sur l'exercice et les deux précédents | la moyenne 3 ans est `NULL` tant que les trois exercices ne sont pas disponibles (donc 2015 et 2016) |
| 2 | Qui est le plus endetté ? | `capacite_desendettement_annees` | encours de dette / épargne brute | `NULL` si l'épargne brute est ≤ 0 (aucune capacité de remboursement) ou si le ratio dépasse 100 ans (résultat sans sens économique). `capacite_desendettement_brute` garde la valeur telle quelle, et `desendettement_situation` dit dans quel cas on est. Seuil d'alerte à 12 ans, zone de vigilance de 8 à 12 ans. |
| 3 | Où va l'argent ? | `fct_depenses_domaine` | charges de classe 6 hors opérations d'ordre, ventilées sur la grille unifiée M14/M57, en part du total ventilé | Marnes-la-Coquette : absente du dataset des balances |
| 4 | Une ville pour les enfants ? | `depenses_enfance_par_enfant` | (charges du domaine Enseignement + charges de petite enfance) / population de 0 à 10 ans | `NULL` si la ventilation fonctionnelle manque |
| 5 | Combien paient les habitants ? | `impots_locaux_hab`, `poids_impots_sur_revenu_pct` | impôts locaux / population ; puis rapporté au niveau de vie médian annuel par unité de consommation (Filosofi 2023) | le dénominateur n'existe qu'en millésime 2023 |
| 6 | Ville riche ou ville qui choisit ? | `potentiel_fiscal_hab` | potentiel fiscal 4 taxes par habitant, tel que publié par la DGCL (OFGL `dotations-communes`) | `NULL` avant 2018 |

**Petite enfance (question 4), sous-fonction identifiée dans les deux nomenclatures.**
La ventilation par fonction ne donne que le premier chiffre pour les domaines, mais les
codes bruts sont conservés dans `data/raw`, ce qui permet d'isoler la petite enfance :
`64x` en M14 (« Crèches et garderies »), `422x` en M57 (« Petite enfance »). Contrôlé sur
les 16 communes encore en M14 en 2023 : le total `64x` de 2023 et le total `422x` de 2024
se recollent à quelques pourcents près (Vanves −4 %, Antony +5 %, Montrouge −4 %,
Nanterre +2 %, Châtillon 0 %, Bois-Colombes 0 %). La continuité de la série de
Boulogne-Billancourt au passage M14 → M57 (20,4 M€ en 2020, 21,2 M€ en 2021) confirme.

**Pourquoi la question 4 est identique dans les deux périmètres** : écoles et crèches sont
des compétences communales, l'EPT n'en porte pas. Ajouter une part d'EPT au numérateur
serait faux.

**Pourquoi la question 6 est identique dans les deux périmètres** : le potentiel fiscal
publié par la DGCL est celui de la commune. Il n'existe pas de « potentiel fiscal
commune + part d'EPT » officiel, et en construire un reviendrait à inventer un indicateur.

### Le piège des communes qui votent leur budget par fonction

Dans les balances comptables, une commune qui vote son budget par fonction **préfixe le
code fonction par le chapitre** : chapitres 92x en M14 et 93x en M57 pour la section de
fonctionnement, 94x à 96x pour les opérations non ventilées. Dans le 92, une seule commune
le fait : **Boulogne-Billancourt**. Son code « 9264 » est le chapitre 92 + fonction 64
(crèches, 22,6 M€ en 2015) et « 934222 » le chapitre 93 + fonction 4222 (crèches, 22,1 M€
en 2024).

Sans traitement, le premier chiffre de ces codes vaut 9, et toutes les dépenses de
fonctionnement de la 1re ville du département (120 000 habitants) se retrouvaient classées
en « action économique » — ce qui gonflait ce domaine à 215 M€ à l'échelle du 92.

La détection se fait **par commune et par exercice**, sur la part de codes commençant par
9 (seuil 80 %) : Boulogne est à 98-100 %, toutes les autres communes sous 10 %, où les
codes 90x à 96x sont de vraies sous-fonctions d'action économique en M14. Aucun code INSEE
n'est écrit en dur.

Les codes contiennent aussi parfois des séparateurs (« 020.90 », « 020& », « 0020 ») :
seuls les chiffres sont conservés avant découpage.

### Le piège de la répartition de l'EPT : Argenteuil

Le contrôle `controle_couverture_pct` de `int_ept_reparti` a révélé que la somme des
populations des communes du 92 membres de **T5 Boucle Nord de Seine** ne représente que
**75 à 77 %** de la population que l'OFGL attribue à cet EPT, là où T2, T3 et T4 sont à
100,00 %. Cause : **Argenteuil (95018, Val-d'Oise)** est membre de T5. C'est la seule
commune de la Métropole du Grand Paris située hors 75/92/93/94, et elle pèse environ un
quart de la population de T5.

Utiliser la somme des populations de nos 36 communes comme dénominateur aurait surévalué
d'environ un tiers la part d'EPT attribuée à Asnières, Bois-Colombes, Clichy, Colombes,
Gennevilliers et Villeneuve-la-Garenne. Le dénominateur retenu est donc la **population
totale de l'EPT publiée par l'OFGL**, qui inclut Argenteuil : la part de T5 revenant à
Argenteuil n'est attribuée à aucune de nos communes, ce qui est le résultat correct.

Le contrôle reste en place comme garde-fou.

**Convention à garder en tête** : répartir les dépenses d'un EPT au prorata de la
population est une convention, pas une mesure. Un EPT ne dépense pas uniformément par
habitant sur son territoire. C'est la clé la plus neutre disponible sans données
infra-EPT ; elle est signalée comme telle sur la page « méthode » du site.

### Tests

**83 tests dbt**, tous verts. Outre les tests de schéma (unicité `(code_insee, annee)`,
non-nullité des agrégats principaux, valeurs acceptées, intégrité référentielle vers
`dim_commune`), quatre tests singuliers portent sur le fond :

- `assert_couverture_commune_annee` : 36 × 11 lignes, sans doublon ni manque ;
- `assert_population_complete` : une population légale strictement positive pour chaque
  commune et chaque année ;
- `assert_parts_age_bornees` : toutes les parts de population dans [0, 1] ;
- `assert_bornes_kpi` : 11 bornes de vraisemblance appliquées aux deux tables de faits
  (population > 0, capacité de désendettement entre −50 et 100 ans, dépenses de
  fonctionnement entre 200 et 10 000 €/hab, etc.) ;
- `assert_controle_qualite` : les écarts aux références extérieures sous leurs seuils.

### Validation : nos KPI contre les ratios légaux publiés par la DGFiP

Le contrôle le plus fort disponible, parce qu'il est automatique et porte sur
**396 points par ratio** (36 communes × 11 exercices). Nous recalculons chaque ratio à
partir du montant et de la population, sans jamais reprendre le ratio publié : la
comparaison valide donc à la fois la formule, le choix de l'agrégat et le choix de la
population.

| Ratio | Points comparés | Écart relatif maximal |
|---|---|---|
| Dépenses réelles de fonctionnement / hab | 396 | **0,0008 %** |
| Dépenses d'équipement brut / hab | 396 | **0,005 %** |
| Encours de dette / hab | 396 | **0,036 %** |
| DGF / hab | 396 | 3,73 % sur un seul point — Puteaux 2020, qui ne touche que 0,13 €/hab de DGF : c'est l'arrondi au centime. Écart absolu maximal sur ce ratio : 0,005 €/hab. |

### Validation : Vanves contre le BP 2026 (critère de l'étape 5)

Référence : budget primitif 2026 de Vanves, page 4, ratios légaux, population 28 794.
Les valeurs sont versionnées dans le seed `dbt/seeds/ref_ratios_legaux.csv` avec, pour
chacune, un drapeau `comparable` et son motif. Le mart `fct_controle_qualite` calcule les
écarts à chaque `dbt build`.

| Ratio du BP 2026 | BP 2026 | Calculé 2024 | Écart | Calculé 2025 | Écart | Verdict |
|---|---|---|---|---|---|---|
| Population totale | 28 794 | 28 303 | −1,7 % | **28 794** | **0,0 %** | ✅ identique |
| Dépenses réelles de fonct. /hab | 1 734,67 € | 1 755,59 € | +1,2 % | 1 693,14 € | −2,4 % | ✅ dans ±15 % |
| Encours de dette /hab | 853,69 € | 947,93 € | +11,0 % | **853,83 €** | **+0,0 %** | ✅ dans ±15 % |
| Personnel en % des DRF | 53,99 % | 52,71 % | −2,4 % | 54,15 % | +0,3 % | ✅ dans ±15 % |
| Équipement brut /hab | 270,60 € | 373,35 € | +38,0 % | 592,85 € | +119 % | ⚠️ écart expliqué |
| Épargne brute en % des RRF | 2,74 % | 8,89 % | +225 % | 9,84 % | +259 % | ⚠️ écart expliqué |
| Potentiel fiscal /hab | 1 303 € | 1 692,69 € | +29,9 % | 1 747,17 € | +34,1 % | ⚠️ écart expliqué |
| DGF /hab | 134,10 € | 51,80 € | −61,4 % | 45,36 € | −66,2 % | ❌ écart non expliqué |

**Quatre ratios sur huit sont dans la tolérance de ±15 %**, dont la population et l'encours
de dette par habitant qui tombent exactement sur la valeur du BP pour 2025. Explications
des écarts :

- **Équipement brut** : poste structurellement volatil. Vanves a dépensé entre 131 €/hab
  (2016) et 593 €/hab (2025) selon l'année ; un budget primitif chiffre un programme
  prévisionnel, pas une réalisation. Par ailleurs le `equip` DGFiP inclut les subventions
  d'équipement versées (vérifié sur 2023 : OFGL 7 782 118 € + 101 536 € = 7 883 654 € =
  `equip` DGFiP).
- **Épargne brute en % des RRF** : écart attendu par construction. Un budget primitif est
  voté avec une épargne prévisionnelle minimale — les recettes réelles se révèlent en
  cours d'exercice. L'épargne constatée de Vanves est de 8,9 % en 2024 et 9,9 % en 2025.
- **Potentiel fiscal** : le « 1 303 € » du BP est la **moyenne de la strate**, pas le
  potentiel fiscal de Vanves. Vérification : l'OFGL publie « Potentiel fiscal moyen de la
  strate » 2025 = **1 303,22 €/hab**, à 22 centimes du chiffre du BP, tandis que le
  potentiel fiscal 4 taxes de Vanves vaut 1 747,17 €/hab.
- **DGF** : **écart non résolu**. Notre valeur (45,36 €/hab en 2025, soit 1 306 047 €) est
  identique au centime dans trois sources indépendantes : le champ `dgf` des comptes
  individuels DGFiP, l'agrégat « Dotation globale de fonctionnement » de l'OFGL, et la
  variable « Montant Dotation DGF » de `dotations-communes`. Les 134,10 €/hab du BP
  (3,86 M€) correspondent probablement à un agrégat plus large du type « dotations et
  participations », mais aucune combinaison testée ne tombe exactement sur cette valeur
  (DGF + autres dotations = 163,6 €/hab ; moyenne de strate de la DGF = 205,6 €/hab).
  À vérifier sur le document d'origine, cf. `RAPPORT.md`.

---

## Étape 7 — Contrôle qualité

### Pourquoi le contrôle n'est pas fait contre les fiches impots.gouv.fr/cll

Le brief demandait de comparer 2023 ou 2024 avec les fiches « comptes individuels des
collectivités » de `impots.gouv.fr/cll`. **Ces fiches sont générées depuis le jeu de données
que nous ingérons déjà** (« Comptes individuels des communes — fichier global », DGFiP,
sur data.economie.gouv.fr). Les comparer reviendrait à comparer une source à elle-même :
l'écart serait nul par construction et ne prouverait rien.

Accessoirement, `cll` est une application Spring WebFlow à état de session (vérifié :
`/cll/` redirige vers `flux.ex?_flowId=accueilcclloc-flow`, les URL directes renvoient 404),
donc ni interrogeable de façon reproductible ni compatible avec un cron mensuel.

Trois contrôles ont été mis en place à la place, du plus exigeant au plus ponctuel.

### Contrôle 1 — nos ratios contre les ratios légaux publiés par la DGFiP

Décrit à l'étape 5. Aucun ratio publié n'est repris tel quel : tous sont recalculés depuis
le montant et la population. **396 points par ratio** (36 communes × 11 exercices).
Écart relatif maximal : 0,0008 % sur les dépenses réelles de fonctionnement, 0,005 % sur
l'équipement, 0,036 % sur l'encours de dette. Largement sous les 2 % demandés.

### Contrôle 2 — nos chiffres contre un document budgétaire communal

Décrit à l'étape 5 (BP 2026 de Vanves). Quatre ratios sur huit dans la tolérance de ±15 %,
dont la population et l'encours de dette par habitant exactement sur la valeur du document ;
trois écarts expliqués ; un écart non résolu (la DGF).

### Contrôle 3 — les deux éditeurs publics confrontés l'un à l'autre

C'est le contrôle réellement indépendant, et celui qui a été le plus instructif. Les comptes
des communes sont publiés par **deux éditeurs distincts** travaillant sur les mêmes comptes
de gestion, avec des chaînes de traitement et des définitions d'agrégats propres :

- la **DGFiP** sur data.economie.gouv.fr (notre source) ;
- l'**OFGL** sur data.ofgl.fr.

`fct_controle_sources` les confronte sur les 36 communes et les 8 exercices couverts par les
deux, soit **288 points par concept**. Le test `assert_coherence_dgfip_ofgl` échoue si un
concept censé être défini de la même façon s'écarte de plus de 0,1 % **et** de plus de
1 000 € (les comptes individuels DGFiP sont publiés en milliers d'euros, donc arrondis).

**Les quatre concepts à définition commune coïncident à 5 € près sur 288 points :**

| Concept | Points | Écart relatif max | Écart absolu max |
|---|---|---|---|
| Charges de personnel | 288 | 0,0012 % | 5 € |
| Encours de dette | 288 | 0,0011 % | 5 € |
| Dotation globale de fonctionnement | 259 | 0,037 % | 5 € |
| Population totale | 288 | **0,000 %** | **0 €** |

Les 5 € résiduels sont exactement l'arrondi au millier d'euros de la publication DGFiP.

Détail sur **Vanves, Malakoff et Boulogne-Billancourt** pour l'exercice 2024 — la troisième
ville a été choisie parce que c'est le cas atypique du département (elle vote son budget par
fonction, cf. étape 5) :

| Ville | Concept | DGFiP | OFGL | Écart |
|---|---|---|---|---|
| Vanves | Charges de personnel | 26 190 140 € | 26 190 139 € | 0,85 € |
| Vanves | Encours de dette | 26 829 290 € | 26 829 287 € | 2,95 € |
| Vanves | DGF | 1 466 060 € | 1 466 056 € | 4,00 € |
| Vanves | Population | 28 303 | 28 303 | 0 |
| Malakoff | Charges de personnel | 31 520 630 € | 31 520 625 € | 4,64 € |
| Malakoff | Encours de dette | 35 163 380 € | 35 163 383 € | −3,40 € |
| Malakoff | DGF | 3 381 650 € | 3 381 648 € | 2,00 € |
| Malakoff | Population | 30 470 | 30 470 | 0 |
| Boulogne-Billancourt | Charges de personnel | 98 212 240 € | 98 212 243 € | −3,08 € |
| Boulogne-Billancourt | Encours de dette | 98 476 940 € | 98 476 936 € | 4,46 € |
| Boulogne-Billancourt | DGF | 52 360 € | 52 361 € | −0,84 € |
| Boulogne-Billancourt | Population | 120 954 | 120 954 | 0 |

### Les sept divergences de définition, chacune avec sa cause établie

Les autres concepts divergent. **Chaque cause a été établie à partir des formules que l'OFGL
publie lui-même** (dataset `methodologie-ofgl-formules-des-agregats-financiers`), pas
supposée. Les motifs sont stockés dans la colonne `motif` du mart et affichés sur le site.

| Concept | Écart relatif max | Cause |
|---|---|---|
| Dépenses d'équipement | 47,6 % | Formule OFGL : `D20 + D21 + D23 − D204 − D2324 − C236 − C237 − C238`. Elle retire les subventions d'équipement versées (qu'on rajoute pour comparer) **mais aussi les avances versées sur commandes d'immobilisations**, que le `equip` DGFiP conserve. Le ratio légal est celui de la DGFiP : c'est lui qu'on publie. |
| Épargne brute | 154,8 % | L'OFGL calcule `recettes de fonctionnement − dépenses de fonctionnement` avec ses propres définitions étroites ; la DGFiP publie une capacité d'autofinancement issue du compte de résultat. Deux constructions distinctes du même concept. |
| Annuité de la dette | 152,9 % | Formule OFGL : `remboursements d'emprunts hors gestion active de la dette + charges financières`. Le `annu` DGFiP inclut les mouvements de gestion active (tirages et remboursements de lignes de trésorerie), d'où des écarts très larges sur les communes qui en usent. |
| Charges financières | 882,2 % sur 7 points / 288 | Même chapitre 66, mais l'OFGL en exclut les opérations d'ordre. **Vérifié au centime sur Antony 2021** : le compte 6681 (indemnités de renégociation de dette) y vaut 1 000 000 €, intégralement en opérations d'ordre ; 2 970 319 − 1 000 000 = 1 970 319, soit exactement la valeur OFGL. Ne concerne que les communes ayant renégocié leur dette. |
| Dépenses de fonctionnement | 163,5 % | Voir ci-dessous : l'OFGL retranche le FCCT pour les communes de la Métropole du Grand Paris. |
| Recettes de fonctionnement | 127,9 % | Même raison, en miroir. |
| Impôts locaux | 72,7 % | L'agrégat OFGL est une ressource fiscale **nette** : il ajoute la fiscalité reversée (chapitre 732) et retranche le FCCT. Le `impo1` DGFiP est le produit des contributions directes (chapitre 731), c'est-à-dire ce que paient effectivement les contribuables locaux — la définition demandée par la question 5. |

### La découverte qui a changé un calcul : le FCCT

En lisant les formules de l'OFGL, une mention a arrêté l'enquête :

> *formule applicable aux communes **à l'exclusion des communes appartenant à la Métropole
> du Grand Paris***

Les 36 communes du 92 en font toutes partie. L'OFGL publie donc, pour elles, une formule
spécifique des dépenses et des recettes de fonctionnement, qui **retranche le compte
65561 — la contribution au fonds de compensation des charges territoriales (FCCT)**, c'est-
à-dire ce que la commune verse à son EPT.

Conséquence directe pour ce projet : **le périmètre consolidé « commune + part d'EPT »
comptait ce transfert deux fois**, une fois en dépense de la commune et une fois dans les
dépenses de l'EPT qu'il finance. Le FCCT a donc été ingéré (`ingest/dgfip.py:flux_ept`) et
neutralisé dans `fct_finances_consolide`.

**Le compte n'est pas le même selon la nomenclature : 65541 en M14, 65561 en M57.**
Repéré parce que le FCCT ressortait à zéro pour les communes encore en M14 (Vanves 2023,
par exemple). Piège voisin évité : le compte **65568** (« autres contributions ») porte des
cotisations à des syndicats et n'est **pas** un flux vers l'EPT — Colombes y inscrit 6,2 M€
en 2024 alors que son EPT ne perçoit presque pas de FCCT.

**Contrôle de cohérence croisée** — la somme des FCCT versés par les communes d'un EPT doit
égaler la « fiscalité reversée » que l'OFGL inscrit en recette de cet EPT :

| EPT | FCCT 2024 versé par les communes du 92 | « Fiscalité reversée » OFGL de l'EPT | Écart |
|---|---|---|---|
| T2 Vallée Sud – Grand Paris | 108 569 800 € | 108 569 800 € | **0,00 %** |
| T3 Grand Paris Seine Ouest | 125 636 070 € | 125 193 594 € | 0,35 % |
| T4 Paris Ouest La Défense | 170 728 021 € | 170 924 629 € | 0,12 % |
| T5 Boucle Nord de Seine | 958 050 € | 1 160 251 € | écart = Argenteuil (202 201 €), hors département |

Le même contrôle sur 2023, avec le compte M14 `65541` ajouté : T2 104,70 M€ contre
104,69 M€, T3 123,54 contre 122,66, T4 168,51 contre 168,15.

Effet mesuré sur le KPI : les dépenses de fonctionnement consolidées de Vanves en 2024
passent de 2 254 €/hab (avec double compte) à **2 002 €/hab** (FCCT neutralisé), soit
−11 %. Pour Malakoff 2024, de 2 517 à **2 211 €/hab**.

**Ce qui n'est PAS neutralisé, et pourquoi** : l'attribution de compensation (compte 73211)
est versée par la **Métropole du Grand Paris**, extérieure au couple commune + EPT. C'est
une ressource externe, qui reste. Mesurée aussi, pour pouvoir le montrer sur le site :
Neuilly-sur-Seine, Levallois-Perret et La Garenne-Colombes ne versent **aucun** FCCT et ne
font que recevoir l'attribution de compensation (vérifié sur les balances 2024 : Neuilly
43,7 M€ au crédit du 73211, aucun débit en 65541 ni 65561).

**Ce qui n'avait pas besoin d'être corrigé** : les dépenses d'équipement et l'encours de
dette ne portent pas de flux croisé commune/EPT ; l'épargne brute consolidée est déjà juste
par construction, le FCCT diminuant celle de la commune et augmentant celle de l'EPT du même
montant. Et aucun des 6 KPI du brief n'était faux : le double compte n'affectait que les
indicateurs de contexte (dépenses et recettes de fonctionnement par habitant, part du
personnel). La correction a quand même été faite, parce que ces indicateurs sont affichés.

### Verdict de l'étape 7

Critère demandé : « écart < 2 % sur les ratios légaux, ou écart expliqué ».

- Ratios légaux recalculés contre ratios légaux publiés : **< 0,04 %** sur 396 points par
  ratio. ✅
- Concepts à définition commune, DGFiP contre OFGL : **< 0,04 %** et **< 5 €** sur
  288 points par concept, pour Vanves, Malakoff, Boulogne-Billancourt et les 33 autres. ✅
- Sept divergences de définition : **chacune expliquée par la formule publiée de l'éditeur**,
  dont deux vérifiées au centime (charges financières d'Antony 2021, FCCT de T2 2024). ✅
- Un écart non résolu : la DGF du BP 2026 de Vanves. ❌ — signalé comme tel, à vérifier sur
  le document d'origine.

---

## Étape 8 — Automatisation

Workflow `.github/workflows/build.yml`.

| Déclencheur | Ingestion | Reconstruction dbt + site | Déploiement Pages | Commit des parquet |
|---|---|---|---|---|
| `schedule` le 5 de chaque mois à 04:17 UTC | oui | oui | oui | oui |
| `workflow_dispatch` (case « relancer l'ingestion », cochée par défaut) | au choix | oui | oui | si ingestion |
| `push` sur `main` (hors fichiers `.md`) | non | oui | oui | non |

Choix et pourquoi :

- **Un push ne relance pas l'ingestion.** On reconstruit depuis les parquet commités : les
  pushes restent rapides et on ne martèle pas des API ouvertes gratuites pour rien.
- **Une source indisponible ne casse pas le site.** L'étape d'ingestion est en
  `continue-on-error`, mais l'échec est remonté en `::warning` et dans le
  `GITHUB_STEP_SUMMARY` du run. Le site se reconstruit alors sur les parquet commités.
  Un échec silencieux est le seul scénario à éviter absolument ; un décalage d'un mois sur
  un millésime ne l'est pas.
- **Les contrôles qualité sont résumés dans chaque run.** Une étape lit les marts et écrit
  dans le récapitulatif GitHub les écarts maximaux face aux ratios légaux DGFiP et face à
  l'OFGL. On voit la qualité des données sans ouvrir un seul log.
- **`evidence sources` avant `evidence build`.** `evidence build` ne lit pas les sources tout
  seul : sans cette étape, le site se construisait sans données (log « No sources found ») et
  déployait des pages vides. C'était le cas du premier déploiement, corrigé.
- **`evidence build:strict`** : une requête cassée fait échouer le run au lieu de publier
  silencieusement une page vide.
- **`[skip ci]` sur le commit de données** : le site vient d'être construit avec ces mêmes
  parquet, inutile de relancer un run.
- **`data/raw/.gitkeep` et `data/marts/.gitkeep`** : dbt-duckdb ne crée pas le répertoire de
  sortie des marts, et un `dbt build` sur un clone où `data/marts/` n'existe pas échoue en
  `IO Error`. `ingest/run_all.py` recrée aussi les deux répertoires.

GitHub Pages a été activé en mode « GitHub Actions »
(`gh api -X POST repos/.../pages -f build_type=workflow`). Les échecs de workflow antérieurs
à cette activation portaient uniquement sur l'étape `deploy-pages`, le job `build` passant.

**Critère validé** : run `workflow_dispatch` n° 40041011488 vert de bout en bout — ingestion
des 4 modules, `dbt build` avec 87 tests, `evidence sources`, `evidence build:strict`, commit
des données rafraîchies, déploiement Pages. Les trois pages répondent en HTTP 200 et le
parquet servi au navigateur contient bien les valeurs attendues.
