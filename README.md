# Finances des villes 92

Comparateur des finances des 36 communes des Hauts-de-Seine, pour répondre à 6 questions
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

- `METHODO.md` : sources exactes, hypothèses, écarts, limites.
- `RAPPORT.md` : ce qui est fait, ce qui reste, points à vérifier.
