---
title: Comparer deux villes des Hauts-de-Seine
description: Six questions simples sur les finances des 36 communes du 92, 2015-2025.
---

```sql villes
select code_insee, nom_commune, libelle_selecteur from finances92.villes order by nom_commune
```

<Dropdown
    data={villes}
    name=ville_a
    value=code_insee
    label=nom_commune
    title="Première ville"
    defaultValue="92075"
/>

<Dropdown
    data={villes}
    name=ville_b
    value=code_insee
    label=nom_commune
    title="Deuxième ville"
    defaultValue="92046"
/>

<ButtonGroup name=perimetre title="Périmètre" defaultValue="commune">
    <ButtonGroupItem valueLabel="La mairie seule" value="commune" />
    <ButtonGroupItem valueLabel="La mairie + sa part de territoire (EPT)" value="commune + EPT" />
</ButtonGroup>

```sql serie_a
select *
from finances92.finances
where code_insee = '${inputs.ville_a.value}'
  and perimetre = '${inputs.perimetre}'
order by annee
```

```sql serie_b
select *
from finances92.finances
where code_insee = '${inputs.ville_b.value}'
  and perimetre = '${inputs.perimetre}'
order by annee
```

```sql serie_duo
select nom_commune, annee, perimetre,
       equipement_hab, equipement_hab_moy3,
       capacite_desendettement_annees, depenses_enfance_par_enfant,
       impots_locaux_hab, poids_impots_sur_revenu_pct, potentiel_fiscal_hab,
       depenses_fonctionnement_hab, encours_dette_hab, part_personnel_pct,
       part_epargne_brute_pct
from finances92.finances
where code_insee in ('${inputs.ville_a.value}', '${inputs.ville_b.value}')
  and perimetre = '${inputs.perimetre}'
order by annee, nom_commune
```

```sql derniere
select max(annee) as annee from finances92.finances
```

```sql a
select * from ${serie_a} where annee = (select annee from ${derniere})
```

```sql b
select * from ${serie_b} where annee = (select annee from ${derniere})
```

```sql moyenne
select * from finances92.moyennes_92
where perimetre = '${inputs.perimetre}' and annee = (select annee from ${derniere})
```

```sql moyennes_serie
select * from finances92.moyennes_92
where perimetre = '${inputs.perimetre}'
order by annee
```

# {inputs.ville_a.label} face à {inputs.ville_b.label}

Exercice <Value data={derniere} column=annee fmt='0' />, périmètre **{inputs.perimetre}**.
Les montants par habitant utilisent la population totale légale de l'exercice.

<Alert status=info>

**En une phrase.**
Sur les trois derniers exercices, <Value data={a} column=nom_commune /> a investi
<Value data={a} column=equipement_hab_moy3 fmt='#,##0 "€/hab"' /> par an et par habitant contre
<Value data={b} column=equipement_hab_moy3 fmt='#,##0 "€/hab"' /> pour <Value data={b} column=nom_commune /> ;
sa dette représente <Value data={a} column=capacite_desendettement_annees fmt='#,##0.0' /> années d'épargne
contre <Value data={b} column=capacite_desendettement_annees fmt='#,##0.0' /> ;
elle fait fonctionner son service public pour
<Value data={a} column=depenses_fonctionnement_hab fmt='#,##0 "€/hab"' /> contre
<Value data={b} column=depenses_fonctionnement_hab fmt='#,##0 "€/hab"' />,
et prélève <Value data={a} column=impots_locaux_hab fmt='#,##0 "€/hab"' /> d'impôts locaux contre
<Value data={b} column=impots_locaux_hab fmt='#,##0 "€/hab"' />.
Moyenne du département, pondérée par la population :
<Value data={moyenne} column=depenses_fonctionnement_hab fmt='#,##0 "€/hab"' /> de fonctionnement et
<Value data={moyenne} column=impots_locaux_hab fmt='#,##0 "€/hab"' /> d'impôts locaux.

</Alert>

{#if inputs.perimetre === 'commune + EPT'}
<Alert status=warning>

Périmètre consolidé : la part de l'EPT est répartie entre ses communes **au prorata de leur
population**. C'est une convention de lecture, pas une mesure : un territoire ne dépense pas
uniformément par habitant. Avant 2018, la part d'EPT n'est pas disponible et les valeurs
affichées sont celles de la commune seule — voir la page [méthode](/methode).

</Alert>
{/if}

---

## 1. Qui construit le plus ?

**Dépenses d'équipement par habitant**, moyenne des trois derniers exercices. Écoles, gymnases,
voirie, bâtiments : tout ce que la ville achète ou construit et qui lui reste. La moyenne sur
trois ans lisse les à-coups, car un seul gros chantier suffit à doubler une année.

<Grid cols=2>
<BigValue
    data={a}
    value=equipement_hab_moy3
    title={inputs.ville_a.label}
    fmt='#,##0 "€/hab"'
    comparison=equipement_hab
    comparisonTitle="dont le seul exercice en cours"
    comparisonFmt='#,##0 "€/hab"'
    comparisonDelta=false
/>
<BigValue
    data={b}
    value=equipement_hab_moy3
    title={inputs.ville_b.label}
    fmt='#,##0 "€/hab"'
    comparison=equipement_hab
    comparisonTitle="dont le seul exercice en cours"
    comparisonFmt='#,##0 "€/hab"'
    comparisonDelta=false
/>
</Grid>

<LineChart
    data={serie_duo}
    x=annee
    y=equipement_hab_moy3
    series=nom_commune
    yAxisTitle="€ par habitant"
    xAxisTitle=""
    title="Dépenses d'équipement par habitant, moyenne glissante 3 ans"
    yFmt='#,##0'
    xFmt='0'
    markers=true
/>

Lecture : plus la courbe est haute, plus la ville investit par habitant. Au-dessus de la
moyenne du département
(<Value data={moyenne} column=equipement_hab fmt='#,##0 "€/hab"' /> en
<Value data={derniere} column=annee fmt='0' />), la ville construit plus que la moyenne des
villes du 92 ; en dessous, moins.

---

## 2. Qui est le plus endetté ?

**Capacité de désendettement**, en années. Combien d'années il faudrait consacrer *toute*
l'épargne de la ville au remboursement pour éteindre sa dette. C'est le bon indicateur,
meilleur que la dette par habitant : une ville très endettée mais qui dégage beaucoup
d'épargne est plus solide qu'une ville peu endettée sans épargne.
**Au-delà de 12 ans, la situation est considérée comme tendue.**

<Grid cols=2>
<BigValue
    data={a}
    value=capacite_desendettement_annees
    title={inputs.ville_a.label}
    fmt='#,##0.0 "ans"'
    comparison=encours_dette_hab
    comparisonTitle="dette par habitant"
    comparisonFmt='#,##0 "€/hab"'
    comparisonDelta=false
/>
<BigValue
    data={b}
    value=capacite_desendettement_annees
    title={inputs.ville_b.label}
    fmt='#,##0.0 "ans"'
    comparison=encours_dette_hab
    comparisonTitle="dette par habitant"
    comparisonFmt='#,##0 "€/hab"'
    comparisonDelta=false
/>
</Grid>

- {inputs.ville_a.label} : <Value data={a} column=desendettement_situation />
- {inputs.ville_b.label} : <Value data={b} column=desendettement_situation />

<LineChart
    data={serie_duo}
    x=annee
    y=capacite_desendettement_annees
    series=nom_commune
    yAxisTitle="années d'épargne brute"
    title="Capacité de désendettement"
    yFmt='#,##0.0'
    xFmt='0'
    markers=true
>
    <ReferenceLine y=12 label="seuil d'alerte : 12 ans" labelPosition=aboveStart color=negative />
    <ReferenceLine y=8 label="vigilance : 8 ans" labelPosition=aboveStart color=warning />
</LineChart>

Lecture : plus la courbe est basse, plus la ville se désendette vite. Une courbe qui monte
brutalement signale le plus souvent un effondrement de l'épargne, pas un emprunt nouveau.

---

## 3. Où va l'argent ?

**Répartition des charges de fonctionnement par domaine.** Ce que la ville paie chaque année
pour faire tourner le service public : salaires, chauffage, fournitures, subventions, répartis
selon la fonction à laquelle les dépenses sont rattachées en comptabilité publique.

```sql domaines_duo
select nom_commune, domaine, code_domaine, ordre_domaine, part_pct, montant_hab, annee,
       couverture_drf_pct
from finances92.domaines
where code_insee in ('${inputs.ville_a.value}', '${inputs.ville_b.value}')
  and annee = (select annee from ${derniere})
order by ordre_domaine
```

```sql couverture
select round(min(couverture_drf_pct)) as mini, round(max(couverture_drf_pct)) as maxi
from finances92.domaines
where annee = (select annee from ${derniere})
```

<BarChart
    data={domaines_duo}
    x=domaine
    y=part_pct
    series=nom_commune
    type=grouped
    swapXY=true
    yAxisTitle="% des charges ventilées"
    title="Part de chaque domaine dans les charges de fonctionnement"
    yFmt='#,##0.0"%"'
    sort=false
/>

<DataTable data={domaines_duo} rows=16 search=false>
    <Column id=nom_commune title="Ville" />
    <Column id=domaine title="Domaine" wrap=true />
    <Column id=part_pct title="Part" fmt='#,##0.0"%"' />
    <Column id=montant_hab title="Par habitant" fmt='#,##0 "€"' />
</DataTable>

Lecture : les parts se lisent sur les **charges ventilables**, c'est-à-dire les comptes de
charges que la commune rattache à une fonction. Ce total couvre entre
<Value data={couverture} column=mini fmt='#,##0'/> % et
<Value data={couverture} column=maxi fmt='#,##0'/> % des dépenses réelles de fonctionnement
selon les villes ; le reste, ce sont principalement les reversements de péréquation
(FSRIF, FPIC), qui ne financent aucun service local. Le poste « charges non ventilées » regroupe ce que la ville n'affecte pas à un domaine,
le plus souvent une partie de la masse salariale et les frais financiers.

---

## 4. Une ville pour les enfants ?

**Dépenses d'écoles et de petite enfance par enfant de 0 à 10 ans.** Le numérateur additionne
les charges de fonctionnement du domaine « enseignement » (écoles, restauration scolaire,
activités périscolaires) et celles de la petite enfance (crèches et garderies). Le
dénominateur est le nombre d'enfants de moins de 11 ans, et non la population totale : ce qui
compte est l'effort par enfant concerné.

<Grid cols=2>
<BigValue
    data={a}
    value=depenses_enfance_par_enfant
    title={inputs.ville_a.label}
    fmt='#,##0 "€/enfant"'
    comparison=part_moins_20
    comparisonTitle="part des moins de 20 ans"
    comparisonFmt='0.0%'
    comparisonDelta=false
/>
<BigValue
    data={b}
    value=depenses_enfance_par_enfant
    title={inputs.ville_b.label}
    fmt='#,##0 "€/enfant"'
    comparison=part_moins_20
    comparisonTitle="part des moins de 20 ans"
    comparisonFmt='0.0%'
    comparisonDelta=false
/>
</Grid>

<LineChart
    data={serie_duo}
    x=annee
    y=depenses_enfance_par_enfant
    series=nom_commune
    yAxisTitle="€ par enfant de 0 à 10 ans"
    title="Dépenses écoles et petite enfance par enfant"
    yFmt='#,##0'
    xFmt='0'
    markers=true
/>

Lecture : un chiffre élevé peut vouloir dire deux choses opposées — une ville qui dépense
beaucoup pour ses enfants, ou une ville qui en compte peu. La part des moins de 20 ans, sous
chaque valeur, permet de trancher. Le nombre d'enfants de 0 à 10 ans vient du recensement
2023 ; pour les autres années, la part est ajustée sur l'évolution de la part des moins de
15 ans ({inputs.ville_a.label} : <Value data={a} column=methode_part_age />).

---

## 5. Combien paient les habitants ?

**Impôts locaux par habitant**, et ce qu'ils représentent rapportés au **niveau de vie médian**
de la commune. Deux villes qui prélèvent le même montant par habitant ne pèsent pas pareil sur
leurs habitants si l'une est deux fois plus riche que l'autre.

<Grid cols=2>
<BigValue
    data={a}
    value=impots_locaux_hab
    title={inputs.ville_a.label}
    fmt='#,##0 "€/hab"'
    comparison=poids_impots_sur_revenu_pct
    comparisonTitle="du niveau de vie médian"
    comparisonFmt='#,##0.00"%"'
    comparisonDelta=false
/>
<BigValue
    data={b}
    value=impots_locaux_hab
    title={inputs.ville_b.label}
    fmt='#,##0 "€/hab"'
    comparison=poids_impots_sur_revenu_pct
    comparisonTitle="du niveau de vie médian"
    comparisonFmt='#,##0.00"%"'
    comparisonDelta=false
/>
</Grid>

<Grid cols=2>
<BigValue
    data={a}
    value=niveau_vie_median
    title="Niveau de vie médian, {inputs.ville_a.label}"
    fmt='#,##0 "€/an par UC"'
    comparison=taux_pauvrete
    comparisonTitle="taux de pauvreté"
    comparisonFmt='#,##0.0"%"'
    comparisonDelta=false
/>
<BigValue
    data={b}
    value=niveau_vie_median
    title="Niveau de vie médian, {inputs.ville_b.label}"
    fmt='#,##0 "€/an par UC"'
    comparison=taux_pauvrete
    comparisonTitle="taux de pauvreté"
    comparisonFmt='#,##0.0"%"'
    comparisonDelta=false
/>
</Grid>

<LineChart
    data={serie_duo}
    x=annee
    y=impots_locaux_hab
    series=nom_commune
    yAxisTitle="€ par habitant"
    title="Impôts locaux par habitant"
    yFmt='#,##0'
    xFmt='0'
    markers=true
/>

Lecture : la courbe montre le montant prélevé par habitant, qui est une vraie série annuelle.
Le rapport au niveau de vie, lui, n'est calculé qu'avec le **millésime
<Value data={a} column=millesime_filosofi fmt='0' /> du revenu médian** : c'est le seul que
l'INSEE expose en accès libre à la commune. Le pourcentage est donc à lire comme une photo,
pas comme une évolution.

---

## 6. Ville riche, ou ville qui choisit ?

**Potentiel fiscal par habitant.** Ce que la ville encaisserait si elle appliquait les taux
moyens nationaux à ses propres bases d'imposition. C'est une mesure de sa richesse fiscale,
indépendante de ses décisions de taux. Confronté à la question 5, il dit si une ville prélève
beaucoup parce qu'elle est riche, ou parce qu'elle a choisi des taux élevés.

<Grid cols=2>
<BigValue
    data={a}
    value=potentiel_fiscal_hab
    title={inputs.ville_a.label}
    fmt='#,##0 "€/hab"'
    comparison=potentiel_fiscal_ecart_strate_pct
    comparisonTitle="écart à la moyenne de sa strate"
    comparisonFmt='+#,##0.0"%";-#,##0.0"%"'
    comparisonDelta=false
/>
<BigValue
    data={b}
    value=potentiel_fiscal_hab
    title={inputs.ville_b.label}
    fmt='#,##0 "€/hab"'
    comparison=potentiel_fiscal_ecart_strate_pct
    comparisonTitle="écart à la moyenne de sa strate"
    comparisonFmt='+#,##0.0"%";-#,##0.0"%"'
    comparisonDelta=false
/>
</Grid>

<LineChart
    data={serie_duo}
    x=annee
    y=potentiel_fiscal_hab
    series=nom_commune
    yAxisTitle="€ par habitant"
    title="Potentiel fiscal par habitant"
    yFmt='#,##0'
    xFmt='0'
    markers=true
/>

Lecture : la série commence en 2018, premier exercice publié par la direction générale des
collectivités locales sur l'API ouverte. Une ville au potentiel fiscal élevé qui prélève peu
« choisit » de ne pas mobiliser sa richesse ; une ville au potentiel faible qui prélève
beaucoup n'a pas vraiment le choix.

---

## Le détail, si vous voulez creuser

<Details title="Tous les indicateurs, année par année">

<DataTable data={serie_duo} rows=12 search=true>
    <Column id=nom_commune title="Ville" />
    <Column id=annee title="Exercice" fmt='0' />
    <Column id=depenses_fonctionnement_hab title="Fonctionnement" fmt='#,##0 "€/hab"' />
    <Column id=equipement_hab title="Équipement" fmt='#,##0 "€/hab"' />
    <Column id=encours_dette_hab title="Dette" fmt='#,##0 "€/hab"' />
    <Column id=capacite_desendettement_annees title="Désendettement" fmt='#,##0.0 "ans"' />
    <Column id=part_personnel_pct title="Personnel" fmt='#,##0.0"%"' />
    <Column id=part_epargne_brute_pct title="Épargne brute" fmt='#,##0.0"%"' />
    <Column id=impots_locaux_hab title="Impôts locaux" fmt='#,##0 "€/hab"' />
    <Column id=potentiel_fiscal_hab title="Potentiel fiscal" fmt='#,##0 "€/hab"' />
    <Column id=depenses_enfance_par_enfant title="Enfance" fmt='#,##0 "€/enfant"' />
</DataTable>

</Details>

Voir aussi le [classement des 36 villes](/classement) et la [méthode](/methode).
