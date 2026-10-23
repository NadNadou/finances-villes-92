---
title: Les 36 villes classées
description: Rang de chaque commune des Hauts-de-Seine sur chaque indicateur.
---

```sql kpis
select distinct kpi, kpi_libelle, question, unite, sens_tri, explication
from finances92.classement
order by question, kpi_libelle
```

```sql annee_kpi
select distinct annee from finances92.classement
where kpi = '${inputs.kpi.value}' and perimetre = '${inputs.perimetre}'
```

<Dropdown
    data={kpis}
    name=kpi
    value=kpi
    label=kpi_libelle
    title="Indicateur"
    defaultValue="equipement"
/>

<ButtonGroup name=perimetre title="Périmètre" defaultValue="commune">
    <ButtonGroupItem valueLabel="La mairie seule" value="commune" />
    <ButtonGroupItem valueLabel="La mairie + sa part de territoire (EPT)" value="commune + EPT" />
</ButtonGroup>

```sql tableau
select
    rang,
    nom_commune,
    numero_ept,
    nom_ept,
    population_totale,
    valeur,
    valeur_disponible,
    ecart_mediane_pct,
    unite,
    kpi_libelle,
    explication,
    annee,
    moyenne_92,
    moyenne_ponderee_92,
    mediane_92,
    min_92,
    max_92,
    nb_communes_renseignees
from finances92.classement
where kpi = '${inputs.kpi.value}' and perimetre = '${inputs.perimetre}'
order by rang
```

```sql resume
select distinct kpi_libelle, explication, unite, annee,
       moyenne_92, moyenne_ponderee_92, mediane_92, min_92, max_92,
       nb_communes_renseignees
from ${tableau}
```

```sql duo
select nom_commune, rang, valeur
from ${tableau}
where nom_commune in ('Vanves', 'Malakoff')
order by rang
```

# <Value data={resume} column=kpi_libelle />

Exercice <Value data={resume} column=annee fmt='0' />, périmètre **{inputs.perimetre}**,
<Value data={resume} column=nb_communes_renseignees fmt='0' /> communes renseignées sur 36.

<Value data={resume} column=explication />

<Grid cols=3>
<BigValue
    data={resume}
    value=moyenne_ponderee_92
    title="Moyenne du département, pondérée par la population"
    fmt='#,##0.00'
/>
<BigValue
    data={resume}
    value=mediane_92
    title="Médiane des 36 villes"
    fmt='#,##0.00'
/>
<BigValue
    data={resume}
    value=moyenne_92
    title="Moyenne simple des 36 villes"
    fmt='#,##0.00'
/>
</Grid>

La moyenne **pondérée par la population** est la référence à retenir pour un ratio par
habitant : elle répond à « combien par habitant du département ». La moyenne simple donne
autant de poids à Marnes-la-Coquette (1 700 habitants) qu'à Boulogne-Billancourt (120 000),
ce qui en fait un repère trompeur. La médiane dit où se situe la ville du milieu.

<BarChart
    data={tableau}
    x=nom_commune
    y=valeur
    swapXY=true
    yAxisTitle={resume[0].unite}
    title="Les 36 villes, triées par rang"
    yFmt='#,##0.0'
    sort=false
    chartAreaHeight=720
/>

## Le tableau

Cliquez sur l'en-tête d'une colonne pour trier.

<DataTable data={tableau} rows=36 search=true sortable=true>
    <Column id=rang title="Rang" align=center />
    <Column id=nom_commune title="Ville" />
    <Column id=numero_ept title="EPT" align=center />
    <Column id=population_totale title="Habitants" fmt='#,##0' />
    <Column id=valeur title={resume[0].kpi_libelle} fmt='#,##0.00' contentType=colorscale />
    <Column id=ecart_mediane_pct title="Écart à la médiane" fmt='+#,##0.0"%";-#,##0.0"%"' />
</DataTable>

<Details title="Comment le rang est attribué">

Pour chaque indicateur, le rang 1 va à la valeur la plus intéressante au sens de l'indicateur :
la plus forte pour les dépenses d'équipement, le potentiel fiscal, les dépenses par enfant et
le taux d'épargne ; la plus faible pour la capacité de désendettement, la dette, les impôts
locaux, les dépenses de fonctionnement et la part des charges de personnel.

**Un rang n'est pas une note.** Dépenser peu en fonctionnement peut vouloir dire une gestion
sobre, ou un service public réduit. Prélever peu d'impôts locaux peut vouloir dire des taux
bas, ou des bases d'imposition riches qui suffisent. C'est l'intérêt de croiser plusieurs
indicateurs plutôt que d'en lire un seul — et c'est ce que fait la page
[Comparer](/).

Les communes pour lesquelles l'indicateur n'est pas disponible sont classées en dernier et
non retirées du tableau, pour que les 36 villes restent visibles. L'exercice retenu est le
dernier où l'indicateur est renseigné pour au moins 30 des 36 communes.

</Details>

## Où se situent Vanves et Malakoff

<DataTable data={duo}>
    <Column id=rang title="Rang" align=center />
    <Column id=nom_commune title="Ville" />
    <Column id=valeur title={resume[0].kpi_libelle} fmt='#,##0.00' />
</DataTable>

Voir aussi la page [Comparer](/) et la [méthode](/methode).
