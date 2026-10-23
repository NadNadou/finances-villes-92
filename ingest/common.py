"""Briques communes aux scripts d'ingestion : HTTP, pagination, écriture parquet.

Aucune clé d'API n'est utilisée : toutes les sources sont des API ouvertes
(Opendatasoft Explore v2.1, api.insee.fr/melodi, geo.api.gouv.fr).
"""

from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Any, Iterable, Iterator

import httpx
import pyarrow as pa
import pyarrow.parquet as pq

RACINE = Path(__file__).resolve().parent.parent
RAW = RACINE / "data" / "raw"
MARTS = RACINE / "data" / "marts"
JOURNAL = RACINE / "data" / "raw" / "_sources.json"

DEPARTEMENT = "92"
ANNEE_MIN = 2015
ANNEE_MAX = 2025

OFGL = "https://data.ofgl.fr/api/explore/v2.1"
ECO = "https://data.economie.gouv.fr/api/explore/v2.1"
MELODI = "https://api.insee.fr/melodi"
GEO_API = "https://geo.api.gouv.fr"

_TIMEOUT = httpx.Timeout(120.0, connect=30.0)
_ENTETES = {"User-Agent": "finances-villes-92/0.1 (projet perso, open data)"}


def client() -> httpx.Client:
    return httpx.Client(timeout=_TIMEOUT, headers=_ENTETES, follow_redirects=True)


def get_json(cli: httpx.Client, url: str, params: dict | None = None, essais: int = 4) -> Any:
    """GET + JSON avec retries exponentiels (les deux plateformes throttlent)."""
    derniere: Exception | None = None
    for n in range(essais):
        try:
            r = cli.get(url, params=params)
            if r.status_code in (429, 500, 502, 503, 504):
                raise httpx.HTTPStatusError(f"HTTP {r.status_code}", request=r.request, response=r)
            r.raise_for_status()
            return r.json()
        except Exception as exc:  # noqa: BLE001
            derniere = exc
            time.sleep(2**n)
    raise RuntimeError(f"échec après {essais} essais : {url} {params} -> {derniere}")


def ods_records(
    cli: httpx.Client,
    base: str,
    dataset: str,
    where: str | None = None,
    select: str | None = None,
    order_by: str | None = None,
    groupe: str | None = None,
    taille: int = 100,
    plafond: int | None = None,
) -> Iterator[dict]:
    """Pagine un dataset Opendatasoft via /records.

    L'API Explore v2.1 plafonne offset+limit à 10 000. Au-delà il faut
    découper la requête (cf. `ods_records_par_tranche`).
    """
    offset = 0
    while True:
        params: dict[str, Any] = {"limit": taille, "offset": offset}
        if where:
            params["where"] = where
        if select:
            params["select"] = select
        if order_by:
            params["order_by"] = order_by
        if groupe:
            params["group_by"] = groupe
        data = get_json(cli, f"{base}/catalog/datasets/{dataset}/records", params)
        lignes = data.get("results") or []
        for ligne in lignes:
            yield ligne
        offset += len(lignes)
        if len(lignes) < taille:
            return
        if plafond and offset >= plafond:
            return
        if offset >= 10_000:  # limite dure d'Opendatasoft : offset + limit <= 10 000
            print(
                f"  !! TRONQUÉ à 10 000 lignes : {dataset} where={where!r}. "
                "Découper la requête (par année, par commune ou via group_by).",
                flush=True,
            )
            return


def melodi_observations(
    cli: httpx.Client, dataset: str, params: dict[str, Any] | None = None
) -> list[dict]:
    """Récupère les observations d'un dataset Melodi (INSEE), en suivant la pagination."""
    p: dict[str, Any] = {"maxResult": 10_000}
    p.update(params or {})
    sortie: list[dict] = []
    page = 1
    while True:
        p["page"] = page
        data = get_json(cli, f"{MELODI}/data/{dataset}", p)
        obs = data.get("observations") or []
        sortie.extend(obs)
        if len(obs) < p["maxResult"]:
            return sortie
        page += 1
        if page > 50:
            return sortie


def melodi_plat(obs: dict) -> dict:
    """Aplatit une observation Melodi en dict simple."""
    ligne: dict[str, Any] = dict(obs.get("dimensions") or {})
    for k, v in (obs.get("attributes") or {}).items():
        ligne[f"attr_{k.lower()}"] = v
    mes = obs.get("measures") or {}
    for k, v in mes.items():
        ligne["valeur"] = v.get("value") if isinstance(v, dict) else v
        ligne["mesure"] = k
        break
    return ligne


def ecrire_parquet(lignes: Iterable[dict], nom: str, schema: pa.Schema | None = None) -> Path:
    """Écrit data/raw/<nom>.parquet. Les colonnes sont l'union des clés rencontrées."""
    lignes = list(lignes)
    RAW.mkdir(parents=True, exist_ok=True)
    chemin = RAW / f"{nom}.parquet"
    if not lignes:
        raise RuntimeError(f"{nom} : 0 ligne, on n'écrit pas de parquet vide")
    colonnes: list[str] = []
    for ligne in lignes:
        for k in ligne:
            if k not in colonnes:
                colonnes.append(k)
    table = pa.table({c: [ligne.get(c) for ligne in lignes] for c in colonnes}, schema=schema)
    pq.write_table(table, chemin, compression="zstd")
    print(f"  -> {chemin.relative_to(RACINE)} : {len(lignes)} lignes, {len(colonnes)} colonnes")
    return chemin


def noter_source(cle: str, **infos: Any) -> None:
    """Journalise la source réellement utilisée (URL, dataset, date) pour METHODO.md."""
    JOURNAL.parent.mkdir(parents=True, exist_ok=True)
    journal = {}
    if JOURNAL.exists():
        journal = json.loads(JOURNAL.read_text(encoding="utf-8"))
    journal[cle] = {"ingere_le": time.strftime("%Y-%m-%d %H:%M:%S"), **infos}
    JOURNAL.write_text(
        json.dumps(journal, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8"
    )


def annees() -> list[int]:
    return list(range(ANNEE_MIN, ANNEE_MAX + 1))
