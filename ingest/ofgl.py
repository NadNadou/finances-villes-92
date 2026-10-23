"""Ingestion OFGL (Observatoire des finances et de la gestion publique locales).

Plateforme Opendatasoft, API Explore v2.1, ouverte sans clé : https://data.ofgl.fr

Trois jeux :
  1. `ofgl-base-communes`  -> agrégats financiers des 36 communes (budget principal)
  2. `ofgl-base-gfp`       -> agrégats financiers des 4 EPT (budget principal)
  3. `dotations-communes`  -> potentiel fiscal / potentiel financier / effort fiscal

Couverture réelle de l'API au moment de l'ingestion : **2018-2025** pour les bases
financières (OFGL a retiré les exercices antérieurs de son API Explore), 2018-2026 pour
les dotations. Les exercices 2015-2017 des communes viennent donc de la DGFiP
(cf. ingest/dgfip.py). Voir METHODO.md.

Sorties :
  data/raw/ofgl_commune_agregat.parquet
  data/raw/ofgl_ept_agregat.parquet
  data/raw/ofgl_dotations.parquet
"""

from __future__ import annotations

import httpx

from ingest import common

DS_COMMUNES = "ofgl-base-communes"
DS_GFP = "ofgl-base-gfp"
DS_DOTATIONS = "dotations-communes"

# Variables de `dotations-communes` qu'on garde (une ligne par commune/exercice/variable).
VARIABLES_DOTATIONS = [
    "Potentiel fiscal 4 taxes",
    "Potentiel fiscal 4 taxes par hab.",
    "Potentiel fiscal moyen de la strate",
    "Potentiel financier",
    "Potentiel financier par hab.",
    "Potentiel financier moyen de la strate",
    "Effort fiscal",
    "Effort fiscal moyen de la strate",
    "Montant Dotation DGF",
    "Montant Dotation forfaitaire",
    "Montant Dotation DSU",
    "Montant Dotation DNP",
]


def exercices_disponibles(cli: httpx.Client, base: str, dataset: str, champ: str) -> list[int]:
    """Liste les exercices réellement présents dans un dataset (on ne suppose rien)."""
    data = common.get_json(
        cli,
        f"{base}/catalog/datasets/{dataset}/records",
        {"group_by": champ, "select": f"{champ}", "limit": 100},
    )
    annees = set()
    for ligne in data.get("results") or []:
        brut = str(ligne.get(champ) or "")
        if len(brut) >= 4 and brut[:4].isdigit():
            annees.add(int(brut[:4]))
    return sorted(annees)


def _agregats(cli: httpx.Client, dataset: str, where_base: str, annees: list[int]) -> list[dict]:
    lignes: list[dict] = []
    select = (
        "exer,insee,siren,com_name,epci_code,epci_name,dep_code,agregat,montant,"
        "euros_par_habitant,ptot,nomen,type_de_budget,tranche_population"
    )
    if dataset == DS_GFP:
        select = (
            "exer,siren,lbudg,epci_code,epci_name,dep_code,agregat,montant,"
            "euros_par_habitant,ptot,nomen,type_de_budget,nat_juridique,categ"
        )
    for annee in annees:
        where = f"{where_base} and exer=date'{annee}' and type_de_budget='Budget principal'"
        got = list(
            common.ods_records(cli, common.OFGL, dataset, where=where, select=select, taille=100)
        )
        for ligne in got:
            ligne["annee"] = annee
        lignes.extend(got)
        print(f"    {dataset} {annee} : {len(got)} lignes")
    return lignes


def communes(cli: httpx.Client) -> list[int]:
    annees = [
        a
        for a in exercices_disponibles(cli, common.OFGL, DS_COMMUNES, "exer")
        if common.ANNEE_MIN <= a <= common.ANNEE_MAX
    ]
    print(f"  {DS_COMMUNES} : exercices retenus {annees[0]}-{annees[-1]}")
    lignes = _agregats(cli, DS_COMMUNES, f"dep_code='{common.DEPARTEMENT}'", annees)
    common.ecrire_parquet(lignes, "ofgl_commune_agregat")
    common.noter_source(
        "ofgl_commune_agregat",
        url=f"{common.OFGL}/catalog/datasets/{DS_COMMUNES}/records",
        dataset=DS_COMMUNES,
        filtre="dep_code='92' and type_de_budget='Budget principal'",
        exercices=annees,
        nb_lignes=len(lignes),
    )
    return annees


def ept(cli: httpx.Client, sirens: list[str]) -> list[int]:
    annees = [
        a
        for a in exercices_disponibles(cli, common.OFGL, DS_GFP, "exer")
        if common.ANNEE_MIN <= a <= common.ANNEE_MAX
    ]
    liste = ", ".join(f"'{s}'" for s in sirens)
    print(f"  {DS_GFP} : exercices retenus {annees[0]}-{annees[-1]}")
    lignes = _agregats(cli, DS_GFP, f"siren in ({liste})", annees)
    common.ecrire_parquet(lignes, "ofgl_ept_agregat")
    common.noter_source(
        "ofgl_ept_agregat",
        url=f"{common.OFGL}/catalog/datasets/{DS_GFP}/records",
        dataset=DS_GFP,
        filtre=f"siren in ({liste}) and type_de_budget='Budget principal'",
        exercices=annees,
        nb_lignes=len(lignes),
    )
    return annees


def dotations(cli: httpx.Client) -> None:
    variables = ", ".join(f'"{v}"' for v in VARIABLES_DOTATIONS)
    where = f'code_departement="{common.DEPARTEMENT}" and variable in ({variables})'
    lignes = list(
        common.ods_records(
            cli,
            common.OFGL,
            DS_DOTATIONS,
            where=where,
            select="exercice,code_insee,commune,categorie,variable,unite,valeur,strate_demographique",
            taille=100,
        )
    )
    for ligne in lignes:
        ligne["annee"] = int(str(ligne["exercice"])[:4])
    common.ecrire_parquet(lignes, "ofgl_dotations")
    common.noter_source(
        "ofgl_dotations",
        url=f"{common.OFGL}/catalog/datasets/{DS_DOTATIONS}/records",
        dataset=DS_DOTATIONS,
        filtre=where,
        variables=VARIABLES_DOTATIONS,
        exercices=sorted({ligne["annee"] for ligne in lignes}),
        nb_lignes=len(lignes),
    )


def main() -> None:
    import pyarrow.parquet as pq

    table = pq.read_table(common.RAW / "geo_communes.parquet")
    sirens_ept = sorted(set(table.column("siren_ept").to_pylist()))

    with common.client() as cli:
        communes(cli)
        ept(cli, sirens_ept)
        dotations(cli)


if __name__ == "__main__":
    main()
