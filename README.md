# Finances des villes 92

**→ https://nadnadou.github.io/finances-villes-92/**

Comparateur des finances des 36 communes des Hauts-de-Seine (2015-2025), pour répondre à 6 questions
simples : qui construit le plus, qui est le plus endetté, où va l'argent, est-ce une ville
pour les enfants, combien paient les habitants, ville riche ou ville qui choisit.

Duo mis en avant par défaut : **Vanves (92075) vs Malakoff (92046)**.

## Pile

```
ingest/ (Python, httpx + pyarrow)  ->  data/raw/*.parquet
      -> dbt-duckdb (staging / intermediate / marts)  ->  data/marts/*.parquet
      -> site/ (Evidence)  ->  GitHub Pages
```

Aucune clé d'API, aucun service payant : OFGL, DGFiP (data.economie.gouv.fr),
INSEE (api.insee.fr/melodi) et geo.api.gouv.fr sont tous ouverts.

## Lancer en local

```bash
python3.12 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/python -m ingest.run_all          # ingestion (data/raw/*.parquet)
cd dbt && ../.venv/bin/dbt build --profiles-dir .   # modèles + tests
cd ../site && npm install && npx evidence build     # site statique dans site/build
```

Le site statique est dans `site/build`, déployé sur GitHub Pages par
`.github/workflows/build.yml` (cron mensuel + déclenchement manuel).

## Documentation

- `METHODO.md` : sources exactes (identifiants de datasets, filtres), définition de chaque
  KPI, écarts de périmètre entre sources, trous et pourquoi, contrôles qualité.
- `RAPPORT.md` : ce qui est fait, ce qui ne l'est pas, les points à vérifier.
- `data/raw/_sources.json` : journal machine des sources réellement ingérées, écrit à chaque
  exécution (URL, identifiant de dataset, filtre, date).

## Qualité

87 tests dbt à chaque build : unicité des clés, non-nullité des agrégats principaux, bornes
de vraisemblance des indicateurs, et écarts aux références extérieures. Les ratios du site
sont recalculés depuis les montants bruts, puis confrontés aux ratios légaux publiés par la
DGFiP (396 points par ratio, écart maximal 0,04 %) et aux agrégats de l'OFGL, éditeur
indépendant (288 points par concept).
