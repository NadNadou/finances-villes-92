---
title: Méthode
description: Comment lire ces chiffres, d'où ils viennent, et ce qu'ils ne disent pas.
---

# Comment lire ces chiffres

Ce site compare les finances des 36 communes des Hauts-de-Seine de 2015 à 2025, pour répondre
à six questions qu'on se pose vraiment quand on habite une ville : qui construit, qui est
endetté, où part l'argent, est-ce une ville pour les enfants, combien paient les habitants,
et si la ville est riche ou si elle choisit.

Tous les chiffres viennent de données publiques officielles. Aucune valeur n'est estimée sans
que ce soit écrit noir sur blanc : quand une donnée manque, elle est vide, jamais remplie au
jugé.

## Les trois pièges à connaître avant de comparer deux villes

### 1. Une mairie n'est plus seule à dépenser sur son territoire

Depuis le 1er janvier 2016, les 36 communes du 92 appartiennent à la Métropole du Grand Paris,
découpée en **établissements publics territoriaux** (EPT). L'EPT a repris une partie des
compétences communales : selon les territoires, la voirie, les déchets, l'assainissement,
parfois les équipements sportifs et culturels.

Conséquence directe : **regarder le seul budget de la mairie fait apparaître une baisse de
l'effort public qui n'a pas eu lieu.** La dépense a changé de guichet, pas disparu. C'est
pourquoi chaque indicateur de ce site existe en deux versions, que la bascule en haut de la
page [Comparer](/) permet d'alterner :

| Périmètre | Ce qu'il mesure | Quand le choisir |
|---|---|---|
| **La mairie seule** | Ce que décide et paie le conseil municipal | Pour juger la gestion de l'équipe élue |
| **La mairie + sa part de territoire** | Ce que la puissance publique locale dépense sur le territoire | Pour comparer deux villes de deux EPT différents, ou suivre une série dans le temps |

Les quatre EPT qui couvrent le département :

| EPT | Communes du 92 | Exemples |
|---|---|---|
| T2 Vallée Sud – Grand Paris | 11 | Antony, Bagneux, Clamart, **Malakoff**, Montrouge |
| T3 Grand Paris Seine Ouest | 8 | Boulogne-Billancourt, Issy-les-Moulineaux, Meudon, **Vanves** |
| T4 Paris Ouest La Défense | 11 | Courbevoie, Nanterre, Neuilly-sur-Seine, Rueil-Malmaison |
| T5 Boucle Nord de Seine | 6 | Asnières-sur-Seine, Clichy, Colombes, Gennevilliers |

**La part d'EPT attribuée à chaque commune est au prorata de sa population. C'est une
convention de lecture, pas une mesure.** Un territoire ne dépense pas uniformément par
habitant : une commune qui accueille le centre technique de l'EPT « consomme » plus que sa
part de population. Faute de données de dépenses infra-EPT publiées, le prorata de population
est la clé la plus neutre disponible, et c'est celle qu'on annonce.

À noter : **T5 Boucle Nord de Seine compte aussi Argenteuil**, dans le Val-d'Oise, soit un
quart de sa population. La part de T5 qui revient à Argenteuil n'est attribuée à aucune
commune du 92 — c'est le résultat correct, et c'est pour cela que le dénominateur du prorata
est la population de l'EPT entier, non la somme de ses communes du 92.

**Le transfert entre la commune et son EPT est neutralisé.** Chaque commune verse à son
territoire une contribution au fonds de compensation des charges territoriales (FCCT,
compte 65561 de la comptabilité publique, 65541 avant le passage à la nomenclature M57).
Cette somme est une dépense réelle de la mairie — elle figure donc au périmètre « la mairie
seule », où elle a toute sa place — mais elle finance aussi les dépenses de l'EPT.
L'additionner telle quelle compterait deux fois le même euro. Pour Vanves en 2024, le FCCT
vaut 7,1 M€ sur 49,7 M€ de dépenses de fonctionnement, soit 14 % : l'enjeu n'est pas
anecdotique. Le périmètre consolidé le retire donc du côté de la commune.

Vérification : la somme des FCCT versés par les communes d'un même EPT égale la
« fiscalité reversée » que l'OFGL inscrit en recette de cet EPT. Pour T2 Vallée Sud – Grand
Paris en 2024, les deux valent **108 569 800 €**, au centime près. L'OFGL fait d'ailleurs
la même opération dans ses propres agrégats : ses formules publiées retranchent le compte
65561 des dépenses de fonctionnement **pour les communes de la Métropole du Grand Paris, et
pour elles seules**.

Ne pas confondre avec l'**attribution de compensation** (compte 73211), qui va dans l'autre
sens : c'est la Métropole du Grand Paris qui la verse à la commune, en échange de la
fiscalité économique qu'elle perçoit à sa place. La Métropole étant extérieure au couple
commune + EPT, cette ressource n'est pas neutralisée. Certaines communes à fortes bases
économiques — Neuilly-sur-Seine, Levallois-Perret, La Garenne-Colombes — ne versent aucun
FCCT et ne font que recevoir l'attribution de compensation.

Enfin, **la part d'EPT n'existe pas avant 2018** : les EPT ont été créés en 2016, et l'API de
l'Observatoire des finances locales ne publie plus les exercices 2016 et 2017. Sur ces années,
le périmètre consolidé affiche les valeurs de la commune seule.

### 2. Un montant par habitant n'est pas un jugement

Dépenser 2 200 € par habitant en fonctionnement plutôt que 1 700 € ne veut pas dire
« mal gérer ». Cela peut vouloir dire : plus de crèches, plus de personnel pour les écoles, un
conservatoire municipal, un centre de santé, une population plus âgée ou plus précaire qui
mobilise davantage de services sociaux. À l'inverse, une ville sobre peut l'être parce qu'elle
a délégué ou supprimé des services.

C'est pour cette raison que le site donne six indicateurs plutôt qu'un score, et affiche
systématiquement le niveau de vie médian et le taux de pauvreté à côté des montants.

### 3. La moyenne du département est une moyenne pondérée

Les moyennes affichées sur la page [classement](/classement) sont **pondérées par la
population**. Pour un ratio par habitant, c'est la seule référence qui ait un sens : elle
répond à « combien par habitant du département ». La moyenne simple des 36 communes donnerait
autant de poids à Marnes-la-Coquette (1 700 habitants) qu'à Boulogne-Billancourt (120 000).
Les deux sont affichées, avec la médiane, pour que l'écart soit visible.

## Ce que mesure exactement chaque question

| Question | Indicateur | Calcul |
|---|---|---|
| **1. Qui construit le plus ?** | Dépenses d'équipement par habitant | Dépenses d'équipement, subventions d'équipement versées incluses, divisées par la population totale. Moyenne glissante sur l'exercice et les deux précédents, parce qu'un seul chantier suffit à doubler une année. Pas de moyenne avant 2017, faute des trois exercices. |
| **2. Qui est le plus endetté ?** | Capacité de désendettement, en années | Encours de dette divisé par l'épargne brute. Combien d'années il faudrait consacrer toute l'épargne au remboursement. Vide quand l'épargne est nulle ou négative — il n'y a alors aucune capacité de remboursement — et au-delà de 100 ans, où le résultat n'a plus de sens économique. Seuil d'alerte usuel : 12 ans. |
| **3. Où va l'argent ?** | Répartition des charges de fonctionnement | Comptes de charges de classe 6, hors opérations d'ordre comptables, ventilés par fonction budgétaire, en part du total ventilé. |
| **4. Une ville pour les enfants ?** | Dépenses écoles et petite enfance par enfant | Charges du domaine enseignement, plus les charges de petite enfance (crèches et garderies), divisées par le nombre d'enfants de 0 à 10 ans. La part des moins de 20 ans est affichée à côté, pour distinguer « dépense beaucoup » de « compte peu d'enfants ». |
| **5. Combien paient les habitants ?** | Impôts locaux par habitant, et leur poids | Produit des impôts locaux divisé par la population, puis rapporté au niveau de vie médian annuel par unité de consommation. |
| **6. Ville riche ou ville qui choisit ?** | Potentiel fiscal par habitant | Potentiel fiscal 4 taxes par habitant, tel que publié par la direction générale des collectivités locales. Ce que la ville encaisserait aux taux moyens nationaux : une mesure de sa richesse fiscale, indépendante de ses décisions de taux. |

Les questions 4 et 6 sont **identiques dans les deux périmètres**, et c'est voulu : écoles et
crèches sont des compétences communales que l'EPT ne porte pas, et le potentiel fiscal publié
est celui de la commune. Construire un « potentiel fiscal commune + EPT » reviendrait à
fabriquer un indicateur qui n'existe pas.

## Les sources

Toutes ouvertes, sans clé d'accès, interrogées par API pour que le site se rafraîchisse tout
seul.

| Donnée | Source | Couverture |
|---|---|---|
| Agrégats financiers des 36 communes | DGFiP, « Comptes individuels des communes — fichier global », sur [data.economie.gouv.fr](https://data.economie.gouv.fr) | 2015-2025, sans trou |
| Dépenses par fonction | DGFiP, « Balances comptables avec présentation croisée nature-fonction », sur [data.economie.gouv.fr](https://data.economie.gouv.fr) | 2015-2025 |
| Agrégats financiers des 4 EPT | [Observatoire des finances et de la gestion publique locales](https://data.ofgl.fr), base des groupements à fiscalité propre | 2018-2025 |
| Potentiel fiscal, potentiel financier, effort fiscal | OFGL, base des dotations aux communes (données DGCL) | 2018-2026 |
| Population légale par année | OFGL, populations des communes (populations légales INSEE) | 2012-2025 |
| Structure par âge | INSEE, recensement de la population, API [Melodi](https://api.insee.fr/melodi) | millésimes 2012, 2017, 2023 |
| Niveau de vie médian, taux de pauvreté | INSEE, Filosofi, API Melodi | millésime 2023 |
| Écoles, collèges, crèches, équipements | INSEE, base permanente des équipements, API Melodi | millésime 2025 |
| Liste des communes, codes, SIREN | [API Géo](https://geo.api.gouv.fr) | à jour |
| Rattachement de chaque commune à son EPT | OFGL, `infos-rei` | à jour |

Le détail exact — identifiants de datasets, filtres, dates d'ingestion, écarts de périmètre
entre sources — est tenu dans le fichier `METHODO.md` du dépôt, et le journal machine des
sources dans `data/raw/_sources.json`.

## Les limites, en toutes lettres

### Ce qui manque

| Limite | Conséquence concrète |
|---|---|
| **Le revenu médian n'existe qu'en millésime 2023.** L'INSEE n'expose Filosofi à la commune que sur le dernier millésime, en accès libre. | La question 5 montre une vraie série pour les impôts par habitant, mais le rapport au niveau de vie est une photo 2023, pas une évolution. |
| **Le potentiel fiscal commence en 2018.** | La question 6 n'a pas de valeur avant 2018. |
| **Les EPT 2016 et 2017 ne sont pas publiés** sur l'API ouverte de l'OFGL. Le fichier DGFiP correspondant existe, mais ses champs ne sont accompagnés d'aucun libellé : s'en servir aurait voulu dire deviner des définitions. | Le périmètre consolidé affiche la commune seule sur 2015-2017. |
| **Marnes-la-Coquette n'a pas de ventilation par fonction.** Avec 1 700 habitants, elle est dispensée de présentation fonctionnelle et absente du jeu de données des balances. | Les questions 3 et 4 sont vides pour cette commune. Elle est affichée comme telle, pas retirée. |
| **Le nombre de places de crèche n'est pas publié**, seulement le nombre d'établissements. | Le site compte les établissements d'accueil du jeune enfant, pas les berceaux. |

### Ce qui demande une précaution de lecture

**La structure par âge est reconstituée entre les recensements.** Le recensement donne la
structure par âge en 2012, 2017 et 2023, et l'âge année par année en 2023 seulement. Pour les
autres exercices, la part des moins de 20 ans est interpolée linéairement entre deux
recensements, et la part des 0-10 ans est ajustée sur l'évolution de la part des moins de
15 ans. Chaque valeur du site porte la mention de la méthode qui s'y applique (« mesuré
(recensement 2017) », « interpolé entre les recensements 2017 et 2023 »…). Les effectifs sont
toujours cette part appliquée à la population légale de l'année, qui est une donnée réelle.

**La répartition par domaine porte sur les charges ventilables**, soit 90 à 97 % des dépenses
réelles de fonctionnement selon les villes. La différence est faite pour l'essentiel des
reversements de péréquation (FSRIF, FPIC), qui ne financent aucun service local. Le poste
« charges non ventilées » regroupe ce que la commune n'affecte pas à un domaine, le plus
souvent une partie de la masse salariale et les frais financiers.

**Les nomenclatures comptables ont changé en cours de période.** Les communes sont passées de
la nomenclature M14 à la M57 entre 2019 et 2024, et les deux ne découpent pas les mêmes
domaines : en M14, « culture » et « sport et jeunesse » sont deux domaines distincts, en M57
ils n'en font qu'un. Les séries de ce site utilisent une grille unifiée des deux
nomenclatures, vérifiée sur les communes qui ont changé de nomenclature : leurs parts par
domaine ne font pas de saut au moment de la bascule.

## Le contrôle qualité

```sql controle_dgfip
select
    libelle as ratio,
    count(*) as points_compares,
    max(abs(ecart_pct)) as ecart_relatif_max_pct,
    max(abs(ecart_absolu)) as ecart_absolu_max
from finances92.controle
where reference = 'ratio légal DGFiP'
group by 1
order by 1
```

### Premier contrôle : les ratios légaux de la DGFiP

Chaque indicateur du site est **recalculé** à partir du montant brut et de la population :
aucun ratio publié n'est repris tel quel. Cela permet de confronter nos résultats aux ratios
légaux que la DGFiP publie elle-même, sur les 36 communes et les 11 exercices, soit
396 points de comparaison par ratio.

<DataTable data={controle_dgfip}>
    <Column id=ratio title="Ratio" wrap=true />
    <Column id=points_compares title="Points comparés" fmt='#,##0' />
    <Column id=ecart_relatif_max_pct title="Écart relatif max" fmt='#,##0.000"%"' />
    <Column id=ecart_absolu_max title="Écart absolu max" fmt='#,##0.000' />
</DataTable>

Les écarts relatifs sont inférieurs au millième de pourcent, sauf sur la dotation globale de
fonctionnement, où un seul point atteint 3,7 % : Puteaux en 2020, qui ne touche que
0,13 € par habitant de DGF — l'arrondi au centime y suffit à faire un gros pourcentage.
L'écart absolu maximal sur ce ratio est de cinq millièmes d'euro par habitant.

### Troisième contrôle : les deux éditeurs publics, confrontés

```sql controle_croise
select
    libelle as concept,
    attendu_identique,
    motif,
    count(*) as points_compares,
    max(abs(ecart_pct)) as ecart_relatif_max_pct,
    max(abs(ecart_absolu)) as ecart_absolu_max
from finances92.controle_sources
where valeur_dgfip is not null and valeur_ofgl is not null
group by 1, 2, 3
order by attendu_identique desc, libelle
```

Les comptes des communes sont publiés par **deux éditeurs indépendants** : la DGFiP, sur
data.economie.gouv.fr, et l'Observatoire des finances et de la gestion publique locales,
sur data.ofgl.fr. Les deux travaillent sur les mêmes comptes de gestion, avec des chaînes
de traitement et des définitions d'agrégats distinctes. Les confronter sur les
36 communes et les 8 exercices couverts par les deux, soit 288 points par concept, est le
contrôle le plus exigeant qu'on puisse faire sans données supplémentaires.

<DataTable data={controle_croise} rows=12>
    <Column id=concept title="Concept" wrap=true />
    <Column id=attendu_identique title="Même définition ?" align=center />
    <Column id=points_compares title="Points" fmt='#,##0' />
    <Column id=ecart_relatif_max_pct title="Écart relatif max" fmt='#,##0.00"%"' />
    <Column id=ecart_absolu_max title="Écart absolu max" fmt='#,##0 "€"' />
</DataTable>

Les quatre concepts dont les deux éditeurs publient **la même définition** coïncident à
5 € près sur 288 points : charges de personnel, encours de dette, dotation globale de
fonctionnement et population. Les 5 € résiduels viennent de l'arrondi au millier d'euros
des comptes individuels DGFiP.

Les sept autres divergent, et **chaque divergence a une cause identifiée**, établie à
partir des formules que l'OFGL publie lui-même, pas supposée :

<Details title="Les sept écarts de définition, et leur cause">

<DataTable data={controle_croise} rows=12>
    <Column id=concept title="Concept" wrap=true />
    <Column id=motif title="Cause de l'écart" wrap=true />
</DataTable>

Le plus instructif pour les Hauts-de-Seine est celui des dépenses de fonctionnement :
**pour les communes de la Métropole du Grand Paris, et pour elles seules, l'OFGL retranche
le compte 65561** — la contribution au fonds de compensation des charges territoriales.
Autrement dit, l'éditeur public a lui aussi jugé nécessaire de neutraliser le transfert de
la commune vers son territoire. C'est exactement ce que fait le périmètre consolidé de ce
site.

</Details>

```sql controle_doc
select nom_commune, annee, libelle as ratio, unite,
       valeur_reference, valeur_calculee, ecart_pct, comparable, commentaire
from finances92.controle
where reference = 'document budgétaire'
order by comparable desc, abs(ecart_pct)
```

### Deuxième contrôle : un document budgétaire communal

Les ratios légaux publiés par Vanves dans son budget primitif 2026.

<DataTable data={controle_doc} rows=10>
    <Column id=ratio title="Ratio" wrap=true />
    <Column id=valeur_reference title="BP 2026" fmt='#,##0.00' />
    <Column id=valeur_calculee title="Calculé 2025" fmt='#,##0.00' />
    <Column id=ecart_pct title="Écart" fmt='+#,##0.0"%";-#,##0.0"%"' />
    <Column id=comparable title="Comparable" align=center />
</DataTable>

<Details title="Pourquoi certaines lignes ne sont pas comparables">

Un budget primitif n'est pas un compte administratif : il chiffre une prévision, pas une
réalisation. Trois lignes diffèrent pour des raisons connues.

- **Dépenses d'équipement** : poste structurellement volatil. Vanves a dépensé entre 131 et
  593 € par habitant selon l'année. Un budget primitif chiffre un programme prévisionnel.
- **Épargne brute en part des recettes** : écart attendu par construction. Un budget primitif
  est voté avec une épargne prévisionnelle minimale, les recettes réelles se révélant en
  cours d'exercice. L'épargne constatée de Vanves est de 9,8 % en 2025, contre 2,7 % au BP.
- **Potentiel fiscal** : le « 1 303 € » du budget est la **moyenne de la strate** de communes,
  pas le potentiel fiscal de Vanves. Vérification : l'OFGL publie un « potentiel fiscal moyen
  de la strate » 2025 de 1 303,22 € par habitant, à 22 centimes près. Le potentiel fiscal de
  Vanves vaut, lui, 1 747 € par habitant.
- **Dotation globale de fonctionnement** : écart **non résolu**. Notre valeur (45,36 € par
  habitant en 2025) est identique au centime dans trois sources indépendantes : les comptes
  individuels DGFiP, les agrégats de l'OFGL et la base des dotations de la DGCL. Les
  134,10 € du budget correspondent vraisemblablement à un agrégat plus large du type
  « dotations et participations », mais aucune combinaison testée ne tombe exactement sur
  cette valeur. Signalé comme tel plutôt que rapproché de force.

</Details>

## Reproduire ces chiffres

Le dépôt est public : [github.com/NadNadou/finances-villes-92](https://github.com/NadNadou/finances-villes-92).
L'ingestion, les modèles de calcul et le site sont dans le même dépôt, et la chaîne complète
se relance en trois commandes. 83 tests automatiques vérifient à chaque exécution l'unicité
des clés, la présence des agrégats, les bornes de vraisemblance des indicateurs et les écarts
aux références extérieures.

Retour à la page [Comparer](/) ou au [classement](/classement).
