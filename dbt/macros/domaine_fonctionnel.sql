{#
  Grille fonctionnelle unifiée M14 / M57.

  Les 36 communes du 92 ont basculé de la nomenclature M14 à la M57 entre 2019 et 2024.
  Les deux grilles fonctionnelles n'ont PAS le même découpage au premier chiffre :

    chiffre | M14 (communes)                               | M57
    --------+----------------------------------------------+----------------------------
       0    | Services généraux                            | Services généraux
       1    | Sécurité et salubrité publiques              | Sécurité
       2    | Enseignement - formation                     | Enseignement - formation
       3    | Culture                                      | Culture, vie sociale, jeunesse, sports
       4    | Sport et jeunesse                            | Santé et action sociale
       5    | Interventions sociales et santé              | Aménagement des territoires et habitat
       6    | Famille                                      | Action économique
       7    | Logement                                     | Environnement
       8    | Aménagement et services urbains, environnement | Transports
       9    | Action économique                            | (non utilisé par les communes)

  Comparer « 3 » de 2022 avec « 3 » de 2024 n'aurait donc aucun sens. On regroupe les deux
  grilles dans 7 domaines + un poste non ventilé, qui sont les plus fins qu'on puisse
  obtenir de façon identique dans les deux nomenclatures sans descendre au deuxième
  chiffre (que la présentation croisée ne renseigne pas toujours).

  Contrôle fait sur Malakoff (92046) : M14 2022 culture(3) 0,92 M€ + sport-jeunesse(4)
  6,29 M€ = 7,21 M€, à comparer aux 8,81 M€ du domaine 3 M57 de 2024 ; social M14
  5+6 = 10,09 M€ contre 9,83 M€ en M57. Les ordres de grandeur se recollent.
#}

{% macro code_domaine_unifie(nomenclature, premier_chiffre) %}
case
    when {{ premier_chiffre }} in ('01', 'NV') then 'NV'
    when {{ nomenclature }} = 'M14' then
        case {{ premier_chiffre }}
            when '0' then 'SG'
            when '1' then 'SEC'
            when '2' then 'ENS'
            when '3' then 'CSJ'
            when '4' then 'CSJ'
            when '5' then 'SOC'
            when '6' then 'SOC'
            when '7' then 'CDV'
            when '8' then 'CDV'
            when '9' then 'ECO'
        end
    else
        case {{ premier_chiffre }}
            when '0' then 'SG'
            when '1' then 'SEC'
            when '2' then 'ENS'
            when '3' then 'CSJ'
            when '4' then 'SOC'
            when '5' then 'CDV'
            when '6' then 'ECO'
            when '7' then 'CDV'
            when '8' then 'CDV'
            when '9' then 'ECO'
        end
end
{% endmacro %}


{% macro libelle_domaine_unifie(code) %}
case {{ code }}
    when 'SG'  then 'Administration et services généraux'
    when 'SEC' then 'Sécurité et salubrité'
    when 'ENS' then 'Écoles et enseignement'
    when 'CSJ' then 'Culture, sport et jeunesse'
    when 'SOC' then 'Social, santé et famille'
    when 'CDV' then 'Cadre de vie : voirie, espaces verts, déchets, logement, transports'
    when 'ECO' then 'Action économique'
    when 'NV'  then 'Charges non ventilées'
    else 'Inconnu'
end
{% endmacro %}


{% macro ordre_domaine_unifie(code) %}
case {{ code }}
    when 'ENS' then 1
    when 'SOC' then 2
    when 'CSJ' then 3
    when 'CDV' then 4
    when 'SEC' then 5
    when 'ECO' then 6
    when 'SG'  then 7
    when 'NV'  then 8
    else 9
end
{% endmacro %}
