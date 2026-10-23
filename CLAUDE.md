# Finances des villes 92

Comparateur des finances des 36 communes des Hauts-de-Seine (2015-2024), pour répondre à 6 questions simples.
Projet perso, 0 €, sans clé API. Le duo mis en avant par défaut : **Vanves (92075) vs Malakoff (92046)**.

Page projet Notion : https://app.notion.com/p/402999875d1d816eaf91df263b56cdc7
Maquette de l'interface cible : https://claude.ai/artifact/884gFsecWviM89BzNtcAZ9

## Mode de travail attendu (session autonome)

- Exécuter les tâches **1 à 8 dans l'ordre**. Ne passer à la suivante que si le **critère** de la tâche est validé.
- Un commit par tâche, message `feat(étape N): …`. Pousser sur `origin main` à chaque commit.
- Tenir `METHODO.md` à jour : sources exactes utilisées (URL, date, identifiant de dataset), hypothèses, écarts.
- Si une source est inaccessible ou a changé d'identifiant : chercher l'équivalent dans le catalogue de la plateforme, le noter dans `METHODO.md`, continuer. Ne jamais inventer de chiffres : une valeur manquante reste `NULL`.
- Ne pas poser de questions : prendre la lecture la plus raisonnable, la noter dans `METHODO.md`.
- À la fin, écrire `RAPPORT.md` : ce qui est fait, ce qui ne l'est pas, les 3 choses à vérifier au réveil.

## Les 6 questions → 6 KPI

| # | Question | KPI | Calcul |
|---|---|---|---|
| 1 | Qui construit le plus ? | Dépenses d'équipement / hab | moyenne glissante 3 ans |
| 2 | Qui est le plus endetté ? | Capacité de désendettement (années) | encours de dette / épargne brute ; alerte > 12 |
| 3 | Où va l'argent ? | Répartition des dépenses de fonctionnement par domaine | fonctions M14/M57 : 0 services généraux, 1 sécurité, 2 enseignement, 3 culture-sport-jeunesse, 4 social-santé, 5 aménagement, 6 action éco, 7 environnement, 8 transports (si disponibles via balances DGFiP ; sinon par nature : 011, 012, 65) |
| 4 | Une ville pour les enfants ? | Dépenses enseignement + petite enfance par enfant | (fonction 2 + sous-fonction petite enfance) / population 0-10 ans ; + part des < 20 ans |
| 5 | Combien paient les habitants ? | Impôts locaux / revenu médian | produit fiscal (chap. 731) / hab ÷ revenu médian par UC |
| 6 | Ville riche ou ville qui choisit ? | Potentiel fiscal / hab | tel que fourni par OFGL/DGCL |

Tous les KPI existent en deux versions : **commune seule** et **commune + part de l'EPT** (EPT réparti au prorata de la population de ses communes). Vanves ∈ EPT Grand Paris Seine Ouest (T3), Malakoff ∈ EPT Vallée Sud – Grand Paris (T2).

Référence de contrôle — BP 2026 Vanves (page 4, ratios légaux, population 28 794) : dépenses réelles de fonct. 1 734,67 €/hab · équipement brut 270,60 €/hab · encours de dette 853,69 €/hab · DGF 134,10 €/hab · personnel 53,99 % des DRF · épargne brute 2,74 % des RRF · potentiel fiscal 1 303 €/hab. (Prévisionnel, donc ordre de grandeur, pas valeur exacte.)

## Sources (aucune clé)

| Besoin | Source | Accès |
|---|---|---|
| Finances communes et EPT 2015-2024 | OFGL — https://data.ofgl.fr (plateforme OpenDataSoft, API Explore v2.1 ; datasets communes et groupements à fiscalité propre — retrouver les identifiants exacts dans `/api/explore/v2.1/catalog/datasets`) | API ouverte |
| Détail par fonction | Balances comptables des communes — https://data.economie.gouv.fr (DGFiP, un dataset par exercice) | CSV / API |
| Population, tranches d'âge | INSEE recensement (séries historiques par commune) — https://www.insee.fr | CSV |
| Revenu médian, pauvreté | INSEE Filosofi (niveau commune) | CSV |
| Crèches, écoles, équipements | INSEE BPE (base permanente des équipements) | CSV |
| Liste des communes, EPCI, codes | API Géo — https://geo.api.gouv.fr/communes?codeDepartement=92&fields=nom,code,population,epci,siren | API ouverte |
| EPT (sous-ensemble de la Métropole du Grand Paris) + compétences | BANATIC — https://www.banatic.interieur.gouv.fr ; à défaut, table en dur des 4 EPT du 92 et de leurs communes (T2 Vallée Sud-GP, T3 GPSO, T4 Paris Ouest La Défense, T5 Boucle Nord de Seine) | fichier |

## Architecture

```
GitHub Actions (cron mensuel) → ingest/ (Python, httpx + pyarrow) → data/raw/*.parquet
→ DuckDB (finances.duckdb) → dbt-duckdb (staging → intermediate → marts) → data/marts/*.parquet
→ site/ (Evidence) → GitHub Pages
```

Arborescence :
```
ingest/        scripts Python, un par source (ofgl.py, dgfip.py, insee.py, geo.py)
data/raw/      parquet bruts (commités, petits)
data/marts/    parquet finaux lus par Evidence
dbt/           projet dbt-duckdb (profiles.yml inclus, target: dev)
site/          projet Evidence
.github/workflows/build.yml
METHODO.md  RAPPORT.md  README.md
```

Outils : Python 3.11+, `uv` ou `pip`, `duckdb`, `dbt-duckdb`, `httpx`, `pyarrow`, `pandas` ; Node 20+ pour Evidence (`npx degit evidence-dev/template site`).

## Tâches

### 1. Socle
Créer l'arborescence, `pyproject.toml`/`requirements.txt`, projet dbt vide, projet Evidence vide, workflow CI qui lance `dbt build` et `npm run build` du site.
**Critère** : `dbt run` et `evidence build` passent à vide, en local et en CI.

### 2. Référentiel des 36 villes
`ingest/geo.py` : API Géo → 36 communes du 92 avec code INSEE, nom, population, SIREN, EPCI. Ajouter l'EPT de chaque commune (BANATIC ou table en dur) et le SIREN de l'EPT.
**Critère** : `dim_commune` = 36 lignes, aucune sans EPT.

### 3. Ingestion finances
`ingest/ofgl.py` : pour chaque commune et chaque EPT, exercices 2015-2024, tous les agrégats disponibles (dépenses/recettes réelles de fonctionnement, charges de personnel, dépenses d'équipement, encours de dette, épargne brute, DGF, produit des impôts, potentiel fiscal…). Puis `ingest/dgfip.py` : balances par fonction si exploitables.
**Critère** : 36 × 10 = 360 lignes commune-année + 4 × ~9 lignes EPT (les EPT existent depuis 2016), aucun trou sur les agrégats principaux ; sinon trous documentés.

### 4. Ingestion population
`ingest/insee.py` : population par commune et par année (ou interpolée entre recensements), part des < 20 ans, des 0-10 ans, des > 65 ans ; revenu médian par UC et taux de pauvreté (Filosofi) ; nombre de places de crèche et d'écoles (BPE).
**Critère** : jointure sur code INSEE sans perte ; les 36 villes ont une population pour chaque année 2015-2024.

### 5. Modèles dbt
- `stg_*` : une vue par source.
- `int_ept_reparti` : agrégats EPT répartis par commune au prorata de la population.
- `fct_finances_commune_annee` : 6 KPI, commune seule.
- `fct_finances_consolide` : 6 KPI, commune + part EPT.
- `fct_classement_92` : rang de chaque ville sur chaque KPI, dernière année disponible.
- Tests : unicité (commune, année), non-null sur les agrégats principaux, bornes (ex. population > 0, capacité de désendettement entre -50 et 100).
**Critère** : `dbt build` vert ; Vanves 2024 cohérent (± 15 %) avec les ratios du BP 2026 ci-dessus.

### 6. Site Evidence
Trois pages, en français, sobres :
- `index.md` — « Comparer » : deux sélecteurs de ville (défaut Vanves / Malakoff), bascule commune seule / avec EPT, un bandeau de synthèse textuel, puis 6 cartes (une par question) : les deux valeurs côte à côte, une courbe 2015-2024, une phrase d'explication en langage simple.
- `classement.md` — tableau des 36 villes, triable par KPI, avec la moyenne du département.
- `methode.md` — comment lire les chiffres, pourquoi l'EPT compte, sources, limites.
Déployer sur GitHub Pages via le workflow (branche `gh-pages` ou artefact Pages).
**Critère** : site en ligne, les 6 questions ont une réponse chiffrée pour Vanves et Malakoff.

### 7. Contrôle qualité
Pour Vanves, Malakoff et une troisième ville, comparer 2023 ou 2024 avec les fiches « comptes individuels des collectivités » (impots.gouv.fr/cll). Expliquer chaque écart dans `METHODO.md`.
**Critère** : écart < 2 % sur les ratios légaux, ou écart expliqué.

### 8. Automatisation
Workflow `build.yml` : `schedule` mensuel + `workflow_dispatch` ; ingestion → dbt build → build Evidence → déploiement Pages ; commit des parquet mis à jour.
**Critère** : un run déclenché à la main passe au vert.

## Interdits
- Pas de clé API, pas de service payant, pas de nom de domaine.
- Pas de chiffre inventé ou « estimé » : `NULL` + note dans `METHODO.md`.
- Pas de dépendance à MotherDuck ou BigQuery : DuckDB local uniquement.
