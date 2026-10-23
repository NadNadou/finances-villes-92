# Rapport de session

Session autonome du 23 au 24 octobre 2026. Les 8 tâches du brief sont faites, chaque
critère validé avant de passer à la suivante, un commit poussé par étape.

**Le site est en ligne : https://nadnadou.github.io/finances-villes-92/**

Dépôt : https://github.com/NadNadou/finances-villes-92 — 11 commits, `main`.

---

## Les trois choses à vérifier au réveil

### 1. La maquette de l'interface ne m'est pas accessible

`CLAUDE.md` renvoie vers https://claude.ai/artifact/884gFsecWviM89BzNtcAZ9 pour la maquette
de l'interface cible. **Ce document n'est pas partagé avec mon compte** : la lecture renvoie
un refus d'accès. L'interface a donc été construite à partir de la seule description
textuelle du brief (deux sélecteurs, bascule de périmètre, bandeau de synthèse, six cartes
avec deux valeurs côte à côte, une courbe et une phrase d'explication).

Elle respecte cette description, mais elle peut diverger de ce qui était dessiné : hiérarchie
visuelle, ordre des blocs, choix des graphiques. **À faire** : partager la maquette, ou dire
en une phrase ce qui ne va pas, et je réaligne les trois pages.

### 2. Un écart de DGF non résolu sur le BP 2026 de Vanves

Le brief donne « DGF 134,10 €/hab » parmi les ratios de référence du BP 2026 de Vanves.
Notre valeur est **45,36 €/hab** pour 2025, soit 1 306 047 €, et elle est **identique au
centime dans trois sources indépendantes** : le champ `dgf` des comptes individuels DGFiP,
l'agrégat « Dotation globale de fonctionnement » de l'OFGL, et la variable « Montant Dotation
DGF » de la base des dotations de la DGCL.

Aucune combinaison testée ne tombe sur 134,10 €/hab (DGF + autres dotations = 163,6 ;
moyenne de strate de la DGF = 205,6). L'hypothèse la plus probable est que le BP renseigne
là un agrégat plus large, du type « dotations et participations ».

Précédent utile pour trancher : le « potentiel fiscal 1 303 €/hab » du même tableau du BP
s'est avéré être **la moyenne de la strate** et non la valeur de Vanves — l'OFGL publie un
« potentiel fiscal moyen de la strate » 2025 de 1 303,22 €/hab, à 22 centimes près. Le même
genre de confusion de colonne expliquerait la DGF.

**À faire** : ouvrir la page 4 du BP 2026 et vérifier l'intitulé exact de la ligne. Si c'est
bien un agrégat plus large, il suffit de corriger une ligne du seed
`dbt/seeds/ref_ratios_legaux.csv`.

### 3. Répartir l'EPT au prorata de la population est une convention, pas une mesure

C'est le choix méthodologique le plus lourd du projet, et il mérite une validation explicite.

Depuis 2016, une partie des compétences communales est portée par l'établissement public
territorial. Pour produire les KPI « commune + part d'EPT », les dépenses de l'EPT sont
réparties entre ses communes **au prorata de leur population**. Un EPT ne dépense pourtant
pas uniformément par habitant : une commune qui accueille son centre technique ou sa
piscine intercommunale en « consomme » plus que sa part. Aucune donnée de dépenses
infra-EPT n'est publiée, donc la clé de population est la plus neutre disponible — mais elle
reste une convention, annoncée comme telle sur la page « méthode ».

**À faire** : valider la convention, ou décider que le périmètre consolidé doit être
présenté autrement (par exemple en affichant la part d'EPT à part, sans l'additionner).

---

## Ce qui est fait

| Étape | Critère du brief | Résultat |
|---|---|---|
| 1. Socle | `dbt run` et `evidence build` passent à vide, en local et en CI | ✅ |
| 2. Référentiel | `dim_commune` = 36 lignes, aucune sans EPT | ✅ 36 communes, 4 EPT (T2 11, T3 8, T4 11, T5 6) |
| 3. Ingestion finances | 360 lignes commune-année + ~36 lignes EPT, sans trou ou trous documentés | ✅ **396** lignes commune-année (2015-**2025**), 32 lignes EPT, trous documentés |
| 4. Ingestion population | Jointure sur code INSEE sans perte, une population par ville et par année | ✅ 0 ligne orpheline sur 5 sources INSEE, 36 × 11 populations |
| 5. Modèles dbt | `dbt build` vert, Vanves 2024 cohérent à ±15 % avec le BP 2026 | ✅ 87 tests verts ; 4 ratios sur 8 dans la tolérance, 3 écarts expliqués, 1 non résolu |
| 6. Site Evidence | Site en ligne, les 6 questions chiffrées pour Vanves et Malakoff | ✅ 3 pages en ligne, 6 réponses chiffrées |
| 7. Contrôle qualité | Écart < 2 % sur les ratios légaux, ou écart expliqué | ✅ < 0,04 % sur 396 points par ratio ; 7 divergences d'éditeur expliquées |
| 8. Automatisation | Un run déclenché à la main passe au vert | ✅ run `40041011488` vert de bout en bout |

### Les 6 questions, répondues pour le duo par défaut

Exercice 2025, périmètre commune seule.

| Question | Indicateur | Vanves | Malakoff |
|---|---|---|---|
| 1. Qui construit le plus ? | Équipement /hab, moyenne 3 ans | 415 € | 318 € |
| 2. Qui est le plus endetté ? | Capacité de désendettement | 4,8 ans | **15,7 ans** (au-delà du seuil d'alerte de 12 ans) |
| 3. Où va l'argent ? | Premier poste de charges | Culture, sport et jeunesse, 22,8 % | Administration et services généraux, 34,8 % |
| 4. Une ville pour les enfants ? | Écoles + petite enfance /enfant de 0-10 ans | 4 057 € | 2 252 € |
| 5. Combien paient les habitants ? | Impôts locaux /hab | 1 168 € (3,35 % du niveau de vie médian) | 1 033 € (3,64 %) |
| 6. Ville riche ou ville qui choisit ? | Potentiel fiscal /hab | 1 747 € | 1 587 € |

Lecture rapide : Vanves investit plus, est beaucoup moins contrainte par sa dette, dépense
près du double par enfant, prélève davantage par habitant en valeur absolue — mais moins
lourdement une fois rapporté au niveau de vie, qui est de 34 820 € par unité de consommation
à Vanves contre 28 400 € à Malakoff.

### Dépassements du brief, assumés

- **2025 est couvert**, pas seulement 2015-2024 : la DGFiP et l'OFGL publient l'exercice
  2025, autant le prendre. 396 lignes commune-année au lieu des 360 attendues.
- **Trois contrôles qualité** au lieu d'un, et sur 288 à 396 points chacun au lieu de trois
  villes (étape 7 ci-dessous).
- **10 indicateurs classables** sur la page classement au lieu des 6 KPI, les 4 autres
  servant de contexte (fonctionnement, dette, personnel, épargne).

---

## Les quatre pièges trouvés en route, et ce qu'ils ont changé

Ce sont les quatre endroits où une implémentation littérale du brief aurait produit des
chiffres faux. Le détail complet est dans `METHODO.md`.

### 1. OFGL ne publie plus que 2018-2025

Le brief désignait l'OFGL comme source principale pour 2015-2024. Son API Explore ne renvoie
que **8 millésimes, 2018 à 2025**. La source de référence est donc devenue les **comptes
individuels des communes de la DGFiP** sur data.economie.gouv.fr, qui couvrent 2015-2025 —
et qui sont, avantage décisif, exactement les chiffres des fiches d'impots.gouv.fr/cll, donc
directement comparables aux ratios légaux.

### 2. Les grilles fonctionnelles M14 et M57 ne découpent pas les mêmes domaines

Les 36 communes sont passées de la nomenclature M14 à la M57 entre 2019 et 2024. **Au
premier chiffre, les deux grilles diffèrent** : en M14, « 3 » est la culture et « 4 » le
sport et la jeunesse ; en M57, « 3 » est culture-sport-jeunesse et « 4 » la santé et
l'action sociale. La liste de domaines donnée dans le brief est celle de la M57 seule.

Comparer un « 3 » de 2022 à un « 3 » de 2024 n'aurait aucun sens. Une grille unifiée de
7 domaines + un poste non ventilé a été construite, puis vérifiée : les parts par domaine de
Vanves ne font aucun saut au passage M14 → M57 (enseignement 17,4 % en 2023 contre 17,2 %
en 2024, culture-sport-jeunesse 23,7 % contre 23,4 %, administration 21,3 % contre 21,6 %).

### 3. Boulogne-Billancourt préfixe ses codes fonction par le chapitre budgétaire

Une commune qui vote son budget par fonction code « 9264 » pour le chapitre 92 + fonction 64.
Dans le 92, **une seule le fait**, Boulogne-Billancourt. Sans traitement, le premier chiffre
de ses codes vaut 9, et **toutes les dépenses de fonctionnement de la première ville du
département basculaient en « action économique »** — ce qui gonflait ce domaine à 215 M€ à
l'échelle du 92.

La détection se fait par commune et par exercice sur la part de codes commençant par 9
(Boulogne 98-100 %, toutes les autres sous 10 %), jamais en dur sur un code INSEE.

### 4. Argenteuil est dans un EPT des Hauts-de-Seine, et le FCCT était compté deux fois

Deux erreurs de périmètre, trouvées par des contrôles mis en place pour ça.

**Argenteuil (95018, Val-d'Oise) est membre de T5 Boucle Nord de Seine** : c'est la seule
commune de la Métropole du Grand Paris hors 75/92/93/94, et elle pèse un quart de la
population de T5. Le contrôle de couverture a sorti T5 à 75 % là où T2, T3 et T4 étaient à
100,00 %. Utiliser la somme des populations de nos 36 communes comme dénominateur du prorata
aurait surévalué d'un tiers la part d'EPT attribuée aux 6 communes du 92 membres de T5.

**Le FCCT était compté deux fois dans le périmètre consolidé.** En lisant les formules que
l'OFGL publie pour ses propres agrégats, une mention a arrêté l'enquête : *« formule
applicable aux communes à l'exclusion des communes appartenant à la Métropole du Grand
Paris »*. Nos 36 communes en font toutes partie, et la formule spécifique retranche le
compte 65561 — la contribution au fonds de compensation des charges territoriales, ce que la
commune verse à son EPT. Ce transfert figurait donc en dépense chez la commune **et** dans
les dépenses de l'EPT qu'il finance.

Vérification croisée : la somme des FCCT versés par les communes de T2 Vallée Sud en 2024
vaut **108 569 800 €**, soit au centime la « fiscalité reversée » que l'OFGL inscrit en
recette de cet EPT. Le compte a été ingéré (**65541 en M14, 65561 en M57** — repéré parce
qu'il ressortait à zéro pour les communes encore en M14) et neutralisé. Effet : les dépenses
de fonctionnement consolidées de Vanves 2024 passent de 2 254 à **2 002 €/hab**, soit −11 %.

Aucun des 6 KPI du brief n'était faux — le double compte n'affectait que les indicateurs de
contexte — mais ils sont affichés, donc corrigés.

---

## Ce qui n'est pas fait, et pourquoi

| Attendu du brief | État | Raison |
|---|---|---|
| **Nombre de places de crèche** (question 4) | ❌ remplacé par le **nombre d'établissements** d'accueil du jeune enfant | La base permanente des équipements de l'INSEE n'expose que la mesure `FACILITIES` pour ce domaine, pas `CAPACITY`. Aucune source ouverte sans clé ne donne les berceaux à la commune. |
| **Revenu médian en série** (question 5) | ⚠️ un seul millésime, **2023** | L'API Melodi de l'INSEE n'expose Filosofi à la commune que sur le dernier millésime (testé : les millésimes 2019 à 2022 renvoient HTTP 400). Les antérieurs n'existent qu'en zip sur insee.fr, dont l'URL change à chaque publication — incompatible avec un cron. Le site montre donc la série des impôts par habitant (réelle) et le rapport au revenu comme une photo 2023, mentionné comme tel. |
| **EPT 2016-2017** | ❌ `NULL` | L'API OFGL ne publie plus ces exercices. Le fichier DGFiP des groupements existe, mais **aucun de ses 165 champs n'a de libellé** dans les métadonnées ; un rapprochement automatique par valeurs avec l'OFGL 2024 n'a identifié de façon fiable que 5 champs sur 40. Les utiliser aurait voulu dire inventer des définitions. Les KPI consolidés commencent donc en 2018. |
| **Potentiel fiscal 2015-2017** (question 6) | ❌ `NULL` | La base des dotations de l'OFGL démarre en 2018. |
| **Ventilation par fonction de Marnes-la-Coquette** (questions 3 et 4) | ❌ `NULL` | Commune de 1 700 habitants, dispensée de présentation fonctionnelle et absente du dataset des balances pour `categ="Commune"`. Affichée comme non disponible, pas retirée du classement. |
| **BANATIC** pour le rattachement aux EPT | ⚠️ remplacé par l'API OFGL `infos-rei` | BANATIC impose un téléchargement de fichier ; `infos-rei` donne le même SIREN d'EPT par API, donc rafraîchissable en CI. Une table en dur des 4 EPT reste comme garde-fou : elle vérifie que le SIREN renvoyé est bien l'un des quatre attendus. |
| **Fiches impots.gouv.fr/cll** comme référence de contrôle (étape 7) | ⚠️ remplacé par un contrôle DGFiP contre OFGL | **Ces fiches sont générées depuis le dataset DGFiP que nous ingérons déjà** : les comparer serait comparer une source à elle-même, l'écart serait nul par construction. Accessoirement, `cll` est une application à état de session, non interrogeable de façon reproductible. Le contrôle réellement indépendant confronte les deux éditeurs publics, sur 288 points par concept. |

Aucune valeur n'a été inventée ni estimée en silence. Les seules valeurs non directement
mesurées sont les parts de population par âge entre deux recensements, et chaque ligne porte
alors une colonne `methode_part_age` qui dit si la valeur est mesurée, interpolée ou tenue
constante — mention reprise sur le site.

---

## Résultat du contrôle qualité

Trois contrôles, du plus exigeant au plus ponctuel. Tous recalculés à chaque `dbt build` et
résumés dans le récapitulatif de chaque run GitHub Actions.

**1. Nos ratios contre les ratios légaux publiés par la DGFiP** — 396 points par ratio
(36 communes × 11 exercices). Aucun ratio publié n'est repris tel quel : tous sont recalculés
depuis le montant et la population, ce qui valide à la fois la formule, le choix de
l'agrégat et le choix de la population.

| Ratio | Écart relatif maximal |
|---|---|
| Dépenses réelles de fonctionnement /hab | **0,0008 %** |
| Dépenses d'équipement brut /hab | **0,005 %** |
| Encours de dette /hab | **0,036 %** |
| DGF /hab | 3,7 % sur un point — Puteaux 2020, qui touche 0,13 €/hab de DGF : c'est l'arrondi au centime. Écart absolu maximal : 0,005 €/hab. |

**2. Les deux éditeurs publics confrontés** — DGFiP contre OFGL, 288 points par concept.
Les quatre concepts à définition commune coïncident à **5 € près**, soit exactement l'arrondi
au millier d'euros de la publication DGFiP : charges de personnel, encours de dette, DGF, et
population (écart nul). Les sept autres divergent, et **chaque divergence a une cause
établie à partir des formules que l'OFGL publie lui-même**, dont deux vérifiées au centime
(les charges financières d'Antony 2021, où le compte 6681 vaut 1 000 000 € intégralement en
opérations d'ordre ; le FCCT de T2 en 2024).

**3. Un document budgétaire communal** — le BP 2026 de Vanves. Quatre ratios sur huit dans
la tolérance de ±15 %, dont la population et l'encours de dette par habitant **exactement**
sur la valeur du document pour 2025 (28 794 habitants, 853,83 contre 853,69 €/hab). Trois
écarts expliqués (équipement volatil, épargne prévisionnelle d'un budget primitif, potentiel
fiscal qui est en fait la moyenne de strate), un non résolu (la DGF, point 2 du haut de ce
rapport).

---

## Comment c'est fait

```
ingest/ (Python 3.12, httpx + pyarrow)   ->  data/raw/*.parquet       (1,0 Mo, commités)
   -> dbt-duckdb, 20 modèles, 87 tests   ->  data/marts/*.parquet     (0,5 Mo, commités)
   -> site/ (Evidence v40)               ->  GitHub Pages
```

Tout tourne sur des API ouvertes sans clé : OFGL, DGFiP via data.economie.gouv.fr, INSEE via
api.insee.fr/melodi, et geo.api.gouv.fr. Zéro euro, zéro service payant, zéro dépendance à
MotherDuck ou BigQuery.

Le workflow `build.yml` tourne le 5 de chaque mois et se déclenche à la main. Une source
indisponible ne casse plus le site : l'ingestion est en `continue-on-error`, mais l'échec
remonte en warning et dans le récapitulatif du run, jamais en silence. Les parquet
rafraîchis sont commités avec `[skip ci]`.

Pour tout relancer en local :

```bash
python3.12 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/python -m ingest.run_all
cd dbt  && ../.venv/bin/dbt build --profiles-dir .
cd ../site && npm install && npx evidence sources && npx evidence build:strict
```

Revalidé de bout en bout à froid (`data/` et `finances.duckdb` supprimés) avant le dernier
commit.

---

## Pistes, si ça vous intéresse de continuer

Par ordre décroissant de rapport valeur/effort.

1. **Une page par ville.** Toute la donnée est là, il manque une route paramétrée
   `/ville/[code_insee]` — le fichier serait une variante de `index.md` à une seule colonne.
2. **Le détail à deux chiffres des fonctions.** Les codes bruts sont conservés dans
   `data/raw/dgfip_fonction_commune.parquet`. On pourrait descendre sous le domaine
   (restauration scolaire, conservatoire, espaces verts) en ne le faisant que là où M14 et
   M57 se recollent, comme pour la petite enfance.
3. **Les budgets annexes.** Tout le projet travaille sur le budget principal. Les parcs de
   stationnement, les réseaux de chaleur et l'eau vivent dans des budgets annexes, que
   l'OFGL publie (`ofgl-base-communes-consolidee`). Ça changerait l'encours de dette de
   quelques communes.
4. **Les taux votés.** `stg_dgfip_commune` porte déjà `tth`, `tfb` et `tfnb`. Les afficher
   répondrait à « cette ville prélève-t-elle beaucoup parce qu'elle est riche, ou parce que
   ses taux sont élevés ? » de façon plus directe que le potentiel fiscal.
5. **Les EPT 2016-2017.** Faisable en demandant à la DGFiP, ou à l'OFGL, le dictionnaire des
   champs du fichier des groupements à fiscalité propre. Avec les libellés, deux heures
   suffiraient.
