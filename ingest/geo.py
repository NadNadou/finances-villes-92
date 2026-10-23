"""Référentiel des 36 communes des Hauts-de-Seine + rattachement EPT.

Sources (ouvertes, sans clé) :
  - geo.api.gouv.fr /communes?codeDepartement=92  -> code INSEE, nom, population, SIREN, EPCI
  - data.ofgl.fr dataset `infos-rei`               -> EPT de rattachement (sirept, libept)

Les 36 communes du 92 appartiennent toutes à la Métropole du Grand Paris (EPCI unique,
SIREN 200054781) ; le niveau qui porte les compétences opérationnelles est l'EPT
(établissement public territorial), sous-ensemble de la MGP. C'est l'EPT qu'on veut.

Sortie : data/raw/geo_communes.parquet
"""

from __future__ import annotations

from ingest import common

# Les 4 EPT qui couvrent les Hauts-de-Seine, avec leur numéro de territoire MGP.
# Sert uniquement de garde-fou : si `infos-rei` renvoie un SIREN inconnu, on le voit.
EPT_92 = {
    "200057966": ("T2", "Vallée Sud - Grand Paris"),
    "200057974": ("T3", "Grand Paris Seine Ouest"),
    "200057982": ("T4", "Paris Ouest La Défense"),
    "200057990": ("T5", "Boucle Nord de Seine"),
}


def main() -> None:
    with common.client() as cli:
        communes = common.get_json(
            cli,
            f"{common.GEO_API}/communes",
            {
                "codeDepartement": common.DEPARTEMENT,
                "fields": "nom,code,population,siren,epci,departement,region,codesPostaux,surface",
            },
        )
        print(f"  geo.api.gouv.fr : {len(communes)} communes")

        rei = list(
            common.ods_records(
                cli,
                common.OFGL,
                "infos-rei",
                where=f'dep="{common.DEPARTEMENT}"',
                select="idcom,libcom,sirept,libept,sirepci",
            )
        )
        print(f"  infos-rei : {len(rei)} lignes")

    ept_par_insee = {r["idcom"]: r for r in rei}

    lignes = []
    for c in communes:
        code = c["code"]
        info = ept_par_insee.get(code, {})
        siren_ept = (info.get("sirept") or "").strip() or None
        libelle_rei = info.get("libept")
        numero, nom_ept = EPT_92.get(siren_ept, (None, None))
        if siren_ept and numero is None:
            print(f"  !! EPT inconnu pour {code} {c['nom']} : {siren_ept} ({libelle_rei})")
            nom_ept = libelle_rei
        lignes.append(
            {
                "code_insee": code,
                "nom_commune": c["nom"],
                "population_geo": c.get("population"),
                "siren_commune": c.get("siren"),
                "surface_ha": c.get("surface"),
                "code_epci": (c.get("epci") or {}).get("code"),
                "nom_epci": (c.get("epci") or {}).get("nom"),
                "siren_ept": siren_ept,
                "numero_ept": numero,
                "nom_ept": nom_ept,
                "libelle_ept_rei": libelle_rei,
            }
        )

    lignes.sort(key=lambda x: x["code_insee"])
    sans_ept = [x["code_insee"] for x in lignes if not x["siren_ept"]]
    if sans_ept:
        raise RuntimeError(f"communes sans EPT : {sans_ept}")
    if len(lignes) != 36:
        raise RuntimeError(f"{len(lignes)} communes au lieu de 36")

    common.ecrire_parquet(lignes, "geo_communes")
    common.noter_source(
        "geo_communes",
        api="https://geo.api.gouv.fr/communes?codeDepartement=92",
        dataset_ept="data.ofgl.fr / infos-rei (champs sirept, libept)",
        nb_communes=len(lignes),
        nb_ept=len({x["siren_ept"] for x in lignes}),
    )
    for numero in sorted({x["numero_ept"] for x in lignes}):
        membres = [x for x in lignes if x["numero_ept"] == numero]
        print(f"  {numero} {membres[0]['nom_ept']} : {len(membres)} communes du 92")


if __name__ == "__main__":
    main()
