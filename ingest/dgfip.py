"""Ingestion DGFiP via data.economie.gouv.fr (Opendatasoft, ouvert sans clé).

Deux jeux :

1. **Comptes individuels des communes — fichier global** (un dataset par millésime ou
   groupe de millésimes). C'est la source de référence : ce sont exactement les chiffres
   des fiches « comptes individuels des collectivités » publiées sur impots.gouv.fr/cll,
   donc les ratios légaux y sont directement comparables. Couverture 2015-2025.
   Les montants sont en **milliers d'euros** ; les champs `f*` sont des ratios **€/hab**,
   les `m*` la moyenne €/hab de la strate, les `r*` des ratios en %, les `rm*` la moyenne
   de la strate de ces ratios.

2. **Balances comptables des collectivités avec présentation croisée nature-fonction**
   (un dataset par exercice, identifiants non devinables : résolus par année ci-dessous).
   Sert à la question 3 « où va l'argent » : on agrège les comptes de classe 6 par fonction
   M14/M57.

Sorties :
  data/raw/dgfip_comptes_commune.parquet
  data/raw/dgfip_fonction_commune.parquet
"""

from __future__ import annotations

import httpx

from ingest import common

PREFIXE_COMPTES = "comptes-individuels-des-communes-fichier-global"

# Identifiants des balances « nature x fonction », résolus par exercice.
# Opendatasoft a tronqué/suffixé les slugs historiques : on ne peut pas les deviner.
BALANCES = {
    2015: "balances-comptables-des-collectivites-et-des-etablissements-publics-locaux-avec2",
    2016: "balances-comptables-des-collectivites-et-des-etablissements-publics-locaux-avec1",
    2017: "balances-comptables-des-collectivites-et-des-etablissements-publics-locaux-avec-",
    2018: "balances-comptables-des-collectivites-et-des-etablissements-publics-locaux-avec0",
    2019: "balances-comptables-des-collectivites-et-des-etablissements-publics-locaux-avec6",
    2020: "balances-comptables-des-collectivites-et-des-etablissements-publics-locaux-avec7",
    2021: "balances-comptables-des-collectivites-et-des-etablissements-publics-locaux-avec8",
    2022: "balances-comptables-des-collectivites-et-des-etablissements-publics-locaux-2022",
    2023: "balances-comptables-des-collectivites-et-des-epl-avec-fonction-2023",
    2024: (
        "balances-comptables-des-collectivites-et-des-etablissements-publics-locaux-"
        "avec-la-presentation-croisee-nature-fonction-2024"
    ),
    2025: (
        "balances-comptables-des-collectivites-et-des-etablissements-publics-locaux-"
        "avec-la-presentation-croisee-nature-fonction-2025"
    ),
}

# Champs des comptes individuels qu'on conserve. Les schémas varient d'un millésime à
# l'autre : on intersecte avec les champs réellement présents dans chaque dataset.
IDENTITE = ["an", "dep", "icom", "inom", "pop1", "nomsst1", "nomsst2"]
AGREGATS = [
    # produits / charges de fonctionnement
    "prod", "fprod", "mprod",
    "charge", "fcharge", "mcharge",
    "perso", "fperso", "mperso", "rperso", "rmperso",
    "achat", "fachat", "rachat", "rmachat",
    "fin", "ffin", "rfin", "rmfin",
    "cont", "fcont",
    "subv", "fsubv",
    # fiscalité et dotations
    "impo1", "fimpo1", "mimpo1", "rimpo1", "rmimpo1",
    "impo2", "fimpo2", "mimpo2",
    "dgf", "fdgf", "mdgf", "rdgf", "rmdgf",
    "fiscrev", "ffiscrev", "mfiscrev",
    "autdot", "fautdot", "mautdot",
    # investissement
    "recinv", "frecinv", "mrecinv",
    "emp", "femp", "remp", "rmemp",
    "subr", "fsubr",
    "fctva", "ffctva",
    "depinv", "fdepinv", "mdepinv",
    "equip", "fequip", "mequip", "requip", "rmequip",
    "remb", "fremb", "rremb", "rmremb",
    "repart", "frepart",
    # autofinancement, dette, fonds de roulement
    "ebf", "febf", "mebf", "rebf", "rmebf",
    "caf", "fcaf", "mcaf", "rcaf", "rmcaf",
    "cafn", "fcafn", "mcafn", "rcafn", "rmcafn",
    "dette", "fdette", "mdette", "rdette", "rmdette",
    "encdbr", "fencdbr", "mencdbr", "rencdbr", "rmencdbr",
    "annu", "fannu", "mannu", "rannu", "rmannu",
    "fdr", "ffdr", "mfdr",
    "res1", "fres1", "res2", "fres2",
    # taux votés des taxes directes locales
    "tth", "tmth", "tfb", "tmfb", "tfnb", "tmfnb",
    "pth", "fpth", "pfb", "fpfb", "pfnb", "fpfnb",
]


def datasets_comptes(cli: httpx.Client) -> dict[int, str]:
    """Résout, pour chaque exercice 2015-2025, le dataset « comptes individuels » qui le porte."""
    catalogue: list[str] = []
    offset = 0
    while True:
        data = common.get_json(
            cli,
            f"{common.ECO}/catalog/datasets",
            {"limit": 100, "offset": offset, "select": "dataset_id"},
        )
        res = data.get("results") or []
        catalogue += [r["dataset_id"] for r in res]
        offset += len(res)
        if len(res) < 100 or offset > 2000:
            break
    candidats = sorted(d for d in catalogue if d.startswith(PREFIXE_COMPTES))
    par_annee: dict[int, str] = {}
    for ds in candidats:
        data = common.get_json(
            cli,
            f"{common.ECO}/catalog/datasets/{ds}/records",
            {"group_by": "an", "select": "an", "limit": 100},
        )
        for ligne in data.get("results") or []:
            brut = str(ligne.get("an") or "")
            if brut[:4].isdigit():
                annee = int(brut[:4])
                if common.ANNEE_MIN <= annee <= common.ANNEE_MAX:
                    par_annee[annee] = ds
    return dict(sorted(par_annee.items()))


def comptes_individuels(cli: httpx.Client) -> list[int]:
    par_annee = datasets_comptes(cli)
    manquantes = [a for a in common.annees() if a not in par_annee]
    if manquantes:
        print(f"  !! aucun dataset « comptes individuels » pour {manquantes}")

    lignes: list[dict] = []
    champs_vus: set[str] = set()
    for annee, ds in par_annee.items():
        meta = common.get_json(cli, f"{common.ECO}/catalog/datasets/{ds}")
        presents = {f["name"] for f in meta.get("fields", [])}
        voulus = [c for c in IDENTITE + AGREGATS if c in presents]
        champs_vus |= set(voulus)
        got = list(
            common.ods_records(
                cli,
                common.ECO,
                ds,
                where=f'dep="0{common.DEPARTEMENT}" and an="{annee}"',
                select=",".join(voulus),
                taille=100,
            )
        )
        for ligne in got:
            ligne["annee"] = annee
            ligne["code_insee"] = f"{common.DEPARTEMENT}{str(ligne.get('icom') or '').zfill(3)}"
            ligne["dataset"] = ds
        print(f"    {annee} : {len(got)} communes  ({ds[-18:]})")
        lignes.extend(got)

    # Colonnes homogènes : tous les champs rencontrés, à None quand absents du millésime.
    toutes = IDENTITE + AGREGATS + ["annee", "code_insee", "dataset"]
    normalise = []
    for ligne in lignes:
        normalise.append({c: ligne.get(c) for c in toutes if c in champs_vus | {"annee", "code_insee", "dataset"}})

    common.ecrire_parquet(normalise, "dgfip_comptes_commune")
    common.noter_source(
        "dgfip_comptes_commune",
        url=f"{common.ECO}/catalog/datasets/<dataset>/records",
        datasets=par_annee,
        filtre='dep="092"',
        unite_montants="milliers d'euros",
        unite_f="euros par habitant (commune)",
        unite_m="euros par habitant (moyenne de la strate)",
        unite_r="pourcentage (commune)",
        unite_rm="pourcentage (moyenne de la strate)",
        nb_lignes=len(normalise),
    )
    return sorted(par_annee)


# Comptes de classe 6 exclus : opérations d'ordre, sans contrepartie de trésorerie.
EXCLUS_ORDRE = ("68", "675", "676")


def depenses_par_fonction(cli: httpx.Client) -> None:
    """Agrège, par commune/exercice/fonction, les charges de fonctionnement (classe 6).

    L'agrégation est faite côté serveur (`group_by`) : en lignes brutes, une année de
    balance du 92 dépasse les 10 000 lignes que l'API Opendatasoft accepte de paginer.
    """
    exclusions = " ".join(f'and not (compte like "{p}*")' for p in EXCLUS_ORDRE)
    lignes: list[dict] = []
    for annee, ds in BALANCES.items():
        if not (common.ANNEE_MIN <= annee <= common.ANNEE_MAX):
            continue
        where = (
            f'ndept="0{common.DEPARTEMENT}" and categ="Commune" and cbudg="1" '
            f'and compte like "6*" {exclusions}'
        )
        got = list(
            common.ods_records(
                cli,
                common.ECO,
                ds,
                where=where,
                select="insee,fonction,nomen,sum(obnetdeb) as debit, sum(obnetcre) as credit",
                order_by="insee,fonction",
                groupe="insee,fonction,nomen",
                taille=100,
            )
        )
        for ligne in got:
            lignes.append(
                {
                    "annee": annee,
                    "code_insee": f"{common.DEPARTEMENT}{str(ligne.get('insee') or '').zfill(3)}",
                    # fonction nulle = charge non ventilée (communes < 3 500 hab,
                    # ou lignes que la collectivité n'a pas ventilées)
                    "fonction": str(ligne.get("fonction") or "NV"),
                    "nomen": ligne.get("nomen"),
                    "debit": ligne.get("debit") or 0.0,
                    "credit": ligne.get("credit") or 0.0,
                    "dataset": ds,
                }
            )
        print(f"    {annee} : {len(got)} couples commune x fonction  ({ds[-18:]})")

    common.ecrire_parquet(lignes, "dgfip_fonction_commune")
    common.noter_source(
        "dgfip_fonction_commune",
        url=f"{common.ECO}/catalog/datasets/<dataset>/records",
        datasets=BALANCES,
        filtre=(
            'ndept="092" and categ="Commune" and cbudg="1" and compte like "6*"'
        ),
        exclusions=f"comptes commençant par {EXCLUS_ORDRE} (opérations d'ordre)",
        mesure="sum(obnetdeb) - sum(obnetcre), groupé par insee x fonction x nomenclature",
        unite="euros",
        nb_lignes=len(lignes),
    )


def main() -> None:
    with common.client() as cli:
        print("  comptes individuels des communes")
        comptes_individuels(cli)
        print("  balances nature x fonction")
        depenses_par_fonction(cli)


if __name__ == "__main__":
    main()
