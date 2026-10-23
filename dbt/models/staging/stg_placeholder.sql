-- Modèle sentinelle : garantit qu'un `dbt run` passe même sans données ingérées.
-- Remplacé par les vrais modèles staging à l'étape 5 ; conservé comme smoke test.
select 1 as ok
