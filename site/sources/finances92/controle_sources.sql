-- Contrôle croisé entre les deux éditeurs publics des comptes communaux (DGFiP et OFGL).
select * from read_parquet('../data/marts/fct_controle_sources.parquet')
