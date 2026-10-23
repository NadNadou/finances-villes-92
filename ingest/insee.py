"""Ingestion des données de population, de revenus et d'équipements.

Sources (toutes ouvertes, sans clé) :

- **Population légale par commune et par année** : dataset OFGL `populations-ofgl-communes`.
  Ce sont les populations légales INSEE (`pmun` municipale, `ptot` totale) republiées par
  l'OFGL année par année. On passe par OFGL et non par insee.fr parce que c'est une API
  (donc rafraîchissable en CI) là où l'INSEE ne publie les populations légales qu'en
  fichiers zip dont l'URL change à chaque millésime. Couverture 2012-2025.

- **Structure par âge** : API Melodi de l'INSEE (`api.insee.fr/melodi`, ouverte).
  - `DS_RP_POPULATION_PRINC` : tranches larges (< 15, < 20, 20-64, 65+, 80+),
    millésimes de recensement 2012, 2017 et 2023.
  - `DS_RP_TD_POPULATION_AGESEX_PRINC` : population par âge **année par année**,
    millésime 2023 seulement. C'est ce qui permet de calculer les 0-10 ans exacts.

- **Revenu et pauvreté** : `DS_FILOSOFI_CC` (Filosofi). Seul le millésime **2023** est
  exposé par Melodi (`temporal` = 2023 → 2023) ; il n'existe pas d'historique ouvert à la
  commune sans télécharger les fichiers zip de insee.fr. Voir METHODO.md.

- **Équipements** : `DS_BPE` (base permanente des équipements), millésime 2025.
  Seule la mesure `FACILITIES` (nombre d'équipements) est disponible pour les
  sous-domaines qui nous intéressent : **le nombre de places de crèche n'est pas
  exposé**, seulement le nombre d'établissements.

Sorties :
  data/raw/insee_population_annee.parquet
  data/raw/insee_age_tranches.parquet
  data/raw/insee_age_detail.parquet
  data/raw/insee_filosofi.parquet
  data/raw/insee_equipements.parquet
"""

from __future__ import annotations

import httpx
import pyarrow.parquet as pq

from ingest import common

DS_POP_OFGL = "populations-ofgl-communes"
DS_RP_TRANCHES = "DS_RP_POPULATION_PRINC"
DS_RP_AGE_DETAIL = "DS_RP_TD_POPULATION_AGESEX_PRINC"
DS_FILOSOFI = "DS_FILOSOFI_CC"
DS_BPE = "DS_BPE"

# Tranches d'âge exploitées dans DS_RP_POPULATION_PRINC.
TRANCHES = ["_T", "Y_LT15", "Y_LT20", "Y20T64", "Y55T64", "Y65T79", "Y_GE65", "Y_GE80"]

LIBELLE_TRANCHE = {
    "_T": "Population totale (recensement)",
    "Y_LT15": "Moins de 15 ans",
    "Y_LT20": "Moins de 20 ans",
    "Y20T64": "20 à 64 ans",
    "Y55T64": "55 à 64 ans",
    "Y65T79": "65 à 79 ans",
    "Y_GE65": "65 ans ou plus",
    "Y_GE80": "80 ans ou plus",
}

# Mesures Filosofi retenues.
MESURES_FILOSOFI = {
    "MED_SL": "Niveau de vie médian (€/an par unité de consommation)",
    "PR_MD60": "Taux de pauvreté au seuil de 60 % (%)",
    "D1_SL": "1er décile du niveau de vie (€/an par UC)",
    "D9_SL": "9e décile du niveau de vie (€/an par UC)",
    "IR_D9_D1_SL": "Rapport interdécile D9/D1",
    "GI_SL": "Indice de Gini du niveau de vie",
}

# Codes BPE retenus. Les sous-domaines (`FACILITY_SDOM` avec `FACILITY_TYPE = '_T'`) sont
# stables d'un millésime à l'autre ; les types fins le sont moins, d'où le choix de ne
# descendre au type que pour les crèches, qui n'ont pas de sous-domaine dédié.
BPE_SOUS_DOMAINES = {
    "C1": "Écoles (maternelles, élémentaires, primaires)",
    "C2": "Collèges",
    "C3": "Lycées",
    "F1": "Équipements sportifs",
    "F3": "Équipements culturels et de loisirs",
}
BPE_TYPES = {
    "D502": "Établissements d'accueil du jeune enfant (crèches)",
}


def _geo_params(codes: list[str], extra: dict | None = None) -> list[tuple[str, str]]:
    params: list[tuple[str, str]] = [("GEO", f"COM-{code}") for code in codes]
    for cle, val in (extra or {}).items():
        params.append((cle, str(val)))
    return params


def melodi_par_paquets(
    cli: httpx.Client, dataset: str, codes: list[str], taille_paquet: int = 9
) -> list[dict]:
    """Interroge Melodi par paquets de communes (plafond de 10 000 observations par appel)."""
    obs: list[dict] = []
    for debut in range(0, len(codes), taille_paquet):
        paquet = codes[debut : debut + taille_paquet]
        params = _geo_params(paquet, {"maxResult": 10_000})
        data = common.get_json(cli, f"{common.MELODI}/data/{dataset}", params)
        lot = data.get("observations") or []
        if len(lot) >= 10_000:
            print(f"  !! {dataset} : paquet saturé à 10 000 observations, réduire taille_paquet")
        obs.extend(lot)
    return obs


def population_annuelle(cli: httpx.Client, codes: list[str]) -> None:
    liste = ", ".join(f'"{c}"' for c in codes)
    lignes = list(
        common.ods_records(
            cli,
            common.OFGL,
            DS_POP_OFGL,
            where=f"insee_25 in ({liste})",
            select="annee,insee_25,nom,pmun,ptot",
            taille=100,
        )
    )
    sortie = []
    for ligne in lignes:
        annee = int(str(ligne["annee"])[:4])
        sortie.append(
            {
                "code_insee": ligne["insee_25"],
                "annee": annee,
                "nom_insee": ligne.get("nom"),
                "population_municipale": ligne.get("pmun"),
                "population_totale": ligne.get("ptot"),
            }
        )
    sortie.sort(key=lambda x: (x["code_insee"], x["annee"]))
    common.ecrire_parquet(sortie, "insee_population_annee")
    annees = sorted({x["annee"] for x in sortie})
    common.noter_source(
        "insee_population_annee",
        plateforme="data.ofgl.fr (republication des populations légales INSEE)",
        dataset=DS_POP_OFGL,
        champs="pmun = population municipale, ptot = population totale",
        exercices=annees,
        nb_lignes=len(sortie),
    )
    print(f"    population : {annees[0]}-{annees[-1]}, {len(sortie)} lignes")


def age_tranches(cli: httpx.Client, codes: list[str]) -> None:
    obs = melodi_par_paquets(cli, DS_RP_TRANCHES, codes, taille_paquet=12)
    lignes = []
    for o in obs:
        d = o["dimensions"]
        if d.get("SEX") != "_T" or d.get("AGE") not in TRANCHES:
            continue
        lignes.append(
            {
                "code_insee": d["GEO"][-5:],
                "millesime": int(d["TIME_PERIOD"]),
                "tranche": d["AGE"],
                "libelle_tranche": LIBELLE_TRANCHE[d["AGE"]],
                "population": o["measures"]["OBS_VALUE_NIVEAU"]["value"],
            }
        )
    common.ecrire_parquet(lignes, "insee_age_tranches")
    millesimes = sorted({x["millesime"] for x in lignes})
    common.noter_source(
        "insee_age_tranches",
        plateforme="api.insee.fr/melodi",
        dataset=DS_RP_TRANCHES,
        filtre="SEX=_T, AGE dans " + ", ".join(TRANCHES),
        millesimes=millesimes,
        nb_lignes=len(lignes),
    )
    print(f"    tranches d'âge : millésimes {millesimes}, {len(lignes)} lignes")


def age_detail(cli: httpx.Client, codes: list[str]) -> None:
    """Population par âge année par année : seule façon d'obtenir les 0-10 ans exacts."""
    obs = melodi_par_paquets(cli, DS_RP_AGE_DETAIL, codes, taille_paquet=9)
    lignes = []
    for o in obs:
        d = o["dimensions"]
        age = d.get("AGE") or ""
        if d.get("SEX") != "_T":
            continue
        if age == "_T":
            age_num = None
        elif age.startswith("Y") and age[1:].isdigit():
            age_num = int(age[1:])
        elif age == "Y_GE100":
            age_num = 100
        else:
            continue
        lignes.append(
            {
                "code_insee": d["GEO"][-5:],
                "millesime": int(d["TIME_PERIOD"]),
                "age": age_num,
                "code_age": age,
                "population": o["measures"]["OBS_VALUE_NIVEAU"]["value"],
            }
        )
    common.ecrire_parquet(lignes, "insee_age_detail")
    millesimes = sorted({x["millesime"] for x in lignes})
    common.noter_source(
        "insee_age_detail",
        plateforme="api.insee.fr/melodi",
        dataset=DS_RP_AGE_DETAIL,
        filtre="SEX=_T, population par âge révolu",
        millesimes=millesimes,
        nb_lignes=len(lignes),
    )
    print(f"    âge détaillé : millésimes {millesimes}, {len(lignes)} lignes")


def filosofi(cli: httpx.Client, codes: list[str]) -> None:
    obs = melodi_par_paquets(cli, DS_FILOSOFI, codes, taille_paquet=18)
    lignes = []
    for o in obs:
        d = o["dimensions"]
        mesure = d.get("FILOSOFI_MEASURE")
        if mesure not in MESURES_FILOSOFI:
            continue
        # Certaines valeurs sont couvertes par le secret statistique : pas de `value`,
        # on garde la ligne avec une valeur nulle plutôt que de la faire disparaître.
        mes = (o.get("measures") or {}).get("OBS_VALUE_NIVEAU") or {}
        lignes.append(
            {
                "code_insee": d["GEO"][-5:],
                "millesime": int(d["TIME_PERIOD"]),
                "mesure": mesure,
                "libelle_mesure": MESURES_FILOSOFI[mesure],
                "unite": d.get("UNIT_MEASURE"),
                "valeur": mes.get("value"),
                "statut": (o.get("attributes") or {}).get("OBS_STATUS"),
                "confidentialite": (o.get("attributes") or {}).get("CONF_STATUS"),
            }
        )
    common.ecrire_parquet(lignes, "insee_filosofi")
    millesimes = sorted({x["millesime"] for x in lignes})
    common.noter_source(
        "insee_filosofi",
        plateforme="api.insee.fr/melodi",
        dataset=DS_FILOSOFI,
        mesures=MESURES_FILOSOFI,
        millesimes=millesimes,
        limite="Melodi n'expose que le millésime le plus récent de Filosofi à la commune.",
        nb_lignes=len(lignes),
    )
    print(f"    Filosofi : millésimes {millesimes}, {len(lignes)} lignes")


def equipements(cli: httpx.Client, codes: list[str]) -> None:
    obs = melodi_par_paquets(cli, DS_BPE, codes, taille_paquet=4)
    lignes = []
    for o in obs:
        d = o["dimensions"]
        if d.get("BPE_MEASURE") != "FACILITIES":
            continue
        sdom, typ = d.get("FACILITY_SDOM"), d.get("FACILITY_TYPE")
        if typ == "_T" and sdom in BPE_SOUS_DOMAINES:
            code, libelle = sdom, BPE_SOUS_DOMAINES[sdom]
        elif typ in BPE_TYPES:
            code, libelle = typ, BPE_TYPES[typ]
        else:
            continue
        lignes.append(
            {
                "code_insee": d["GEO"][-5:],
                "millesime": int(d["TIME_PERIOD"]),
                "code_equipement": code,
                "libelle_equipement": libelle,
                "nombre": o["measures"]["OBS_VALUE_NIVEAU"]["value"],
            }
        )
    common.ecrire_parquet(lignes, "insee_equipements")
    millesimes = sorted({x["millesime"] for x in lignes})
    common.noter_source(
        "insee_equipements",
        plateforme="api.insee.fr/melodi",
        dataset=DS_BPE,
        sous_domaines=BPE_SOUS_DOMAINES,
        types=BPE_TYPES,
        millesimes=millesimes,
        limite="Seule la mesure FACILITIES est disponible : pas de capacité (places de crèche).",
        nb_lignes=len(lignes),
    )
    print(f"    équipements : millésimes {millesimes}, {len(lignes)} lignes")


def main() -> None:
    codes = sorted(pq.read_table(common.RAW / "geo_communes.parquet").column("code_insee").to_pylist())
    with common.client() as cli:
        population_annuelle(cli, codes)
        age_tranches(cli, codes)
        age_detail(cli, codes)
        filosofi(cli, codes)
        equipements(cli, codes)


if __name__ == "__main__":
    main()
