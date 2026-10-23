# Méthodologie

Document de traçabilité : sources exactes, hypothèses, écarts. Mis à jour à chaque étape.

## État

Étape 1 (socle) faite. Les sections ci-dessous se remplissent au fil des étapes.

## Sources retenues

(voir étape 3 et suivantes)

---

## Étape 2 — Référentiel des 36 communes

| Besoin | Source exacte | Identifiant | Accès |
|---|---|---|---|
| Liste des communes, code INSEE, nom, SIREN, population, surface | API Géo | `https://geo.api.gouv.fr/communes?codeDepartement=92&fields=nom,code,population,siren,epci,surface` | ouvert, sans clé |
| EPT de rattachement | OFGL (Opendatasoft) | dataset `infos-rei`, champs `sirept` / `libept`, filtre `dep="92"` | ouvert, sans clé |

Résultat : **36 communes, 36 avec un EPT, 4 EPT distincts.**

| EPT | SIREN | Communes du 92 |
|---|---|---|
| T2 Vallée Sud – Grand Paris | 200057966 | 11 |
| T3 Grand Paris Seine Ouest | 200057974 | 8 |
| T4 Paris Ouest La Défense | 200057982 | 11 |
| T5 Boucle Nord de Seine | 200057990 | 6 |

### Hypothèses et choix

- **BANATIC n'a pas été utilisé.** Le champ `sirept` du dataset OFGL `infos-rei` donne
  directement le SIREN de l'EPT pour chacune des 36 communes ; c'est une source API, donc
  rafraîchissable automatiquement, là où BANATIC impose un téléchargement de fichier.
  La table en dur `EPT_92` dans `ingest/geo.py` ne sert que de garde-fou : elle vérifie que
  le SIREN renvoyé fait bien partie des 4 EPT attendus et attache le numéro de territoire
  (T2…T5). Si OFGL renvoyait un SIREN inconnu, l'ingestion le signalerait sans planter.
- **Les 4 EPT sont entièrement contenus dans les Hauts-de-Seine** : 11 + 8 + 11 + 6 = 36.
  Conséquence importante pour l'étape 5 : la population de chaque EPT est la somme de celle
  de ses communes du 92, donc le prorata de répartition de l'EPT n'a pas de « fuite » vers
  un autre département.
- L'EPCI renvoyé par l'API Géo est la **Métropole du Grand Paris** (SIREN 200054781) pour
  les 36 communes. C'est exact mais inutilisable pour comparer : le niveau qui porte les
  compétences opérationnelles (voirie, déchets, équipements sportifs et culturels selon les
  territoires) est l'EPT. On garde les deux champs.
- `population_geo` de l'API Géo est une population municipale de millésime non documenté
  par l'API ; elle n'est **pas** utilisée pour les ratios. Les ratios par habitant utilisent
  la population totale OFGL/DGFiP de l'exercice concerné (étape 4).
