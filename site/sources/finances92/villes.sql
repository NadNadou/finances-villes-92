-- Les 36 communes des Hauts-de-Seine, pour les sélecteurs.
select * from read_parquet('../data/marts/dim_ville.parquet')
order by nom_commune
