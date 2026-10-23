-- Écarts entre nos KPI et les références extérieures (ratios légaux DGFiP, documents
-- budgétaires communaux).
select * from read_parquet('../data/marts/fct_controle_qualite.parquet')
