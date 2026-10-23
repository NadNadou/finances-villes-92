"""Lance toutes les ingestions dans l'ordre des dépendances."""

from __future__ import annotations

import sys


def main() -> int:
    from ingest import common, dgfip, geo, insee, ofgl

    # dbt-duckdb ne crée pas le répertoire de sortie des marts : on s'en assure ici pour
    # qu'un `dbt build` sur un clone frais ne tombe pas sur une IO Error.
    common.RAW.mkdir(parents=True, exist_ok=True)
    common.MARTS.mkdir(parents=True, exist_ok=True)

    etapes = [
        ("geo", geo.main),
        ("ofgl", ofgl.main),
        ("dgfip", dgfip.main),
        ("insee", insee.main),
    ]
    echecs = []
    for nom, fn in etapes:
        print(f"\n=== ingest.{nom} ===", flush=True)
        try:
            fn()
        except Exception as exc:  # on continue : une source morte ne bloque pas le reste
            print(f"!! ingest.{nom} a échoué : {exc}", file=sys.stderr)
            echecs.append(nom)
    if echecs:
        print(f"\nÉchecs : {', '.join(echecs)}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
