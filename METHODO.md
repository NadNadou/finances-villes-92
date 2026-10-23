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
