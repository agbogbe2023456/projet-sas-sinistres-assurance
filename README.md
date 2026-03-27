# Projet SAS – Analyse de sinistres d'assurance

## 🎯 Objectif du projet

Mettre en place, en SAS, une chaîne complète de traitement de sinistres d’assurance IARD :
de la donnée brute à des indicateurs de pilotage (provisions, ratios S/C, coûts moyens, ancienneté).

Ce projet a été réalisé dans le cadre de ma formation en actuariat.

---

## 🧾 Données utilisées

- Fichier CSV de sinistres d’assurance :
  - ID assuré
  - Date de sinistre
  - Garantie
  - Montants (charge, recours, paiements)
  - Prime annuelle
- Données pédagogiques fournies pour un projet universitaire (pas de données réelles clients).

---

## 🔧 Étapes réalisées en SAS

### 1. Import & nettoyage

- Import du fichier CSV dans une table SAS (`TABLE_SAS_BRUTE`).
- Conversion des variables texte en numériques (montants, dates, identifiants).
- Création d’une vraie date SAS pour `DATE_SIN` avec format `ddmmyy10.`.
- Contrôle qualité : statistiques descriptives et fréquences par garantie.

### 2. Création de variables métier

- **BRANCHE** :
  - Garanties A à P → `Prévoyance`
  - Garanties Q à Z → `Dommages aux biens`
- **ID_SIN** : identifiant unique de sinistre construit à partir de :
  - 2 derniers chiffres de l’année de sinistre
  - code garantie
  - 4 derniers chiffres de l’ID assuré
- **Provisions** :
  - `PROV_SINISTRE` = charge – paiements
  - `PROV_SINISTRE_NETTE` = max(0, PROV_SINISTRE – recours)
- **Ratio sinistres / cotisations** :
  - `SIN_COT` = COUT_SIN / PRIME_ANNUELLE
  - Gestion des cas PRIME_ANNUELLE = 0 (éviter la division par zéro)

### 3. Analyses réalisées

- Moyenne du ratio **S/C** par **branche** et par **garantie**.
- Coût moyen d’un sinistre par garantie.
- Table `TOP_SIN` :
  - sinistres de charge > 2500 €
  - montant sans centimes (troncature)
  - tri des sinistres les plus coûteux.
- Total des provisions nettes par branche.

### 4. Ancienneté des sinistres

- Date de rendu du projet : **21/03/2026** (`DATE_RENDU`).
- Calcul de l’**ancienneté** du sinistre en années :
  - `ANCIENNETE = intck('year', DATE_SIN, DATE_RENDU, 'c')`
- Création d’une variable de **tranche d’ancienneté** :
  - `< 4 ans` → “Moins de 4 ans”
  - `≥ 4 ans` → “4 ans et plus”

### 5. Synthèse finale

- Table `SYNTHESE_FINALE_SINISTRES` :
  - Nombre de sinistres par **BRANCHE** × **TRANCHE_ANC**
  - Permet d’analyser le profil du portefeuille selon la branche et l’ancienneté des sinistres.

---

## 🛠️ Outils et procédures SAS utilisés

- **DATA step** : préparation et création de variables.
- **PROC IMPORT / DATA + INFILE** : import du CSV.
- **PROC MEANS / PROC SUMMARY** : statistiques et agrégations.
- **PROC FREQ** : comptages par modalités (branche, tranches).
- **PROC SORT** : tri des sinistres lourds.
- **PROC SQL** : suppression de tables intermédiaires.

---

## ✅ Compétences développées

- Préparation et nettoyage de données en SAS dans un contexte assurance.
- Construction d’indicateurs métiers : provisions, ratio S/C, coût moyen, ancienneté.
- Structuration d’un projet technique de bout en bout (de la donnée brute à la synthèse).
- Capacité à documenter un projet pour le partager (GitHub, LinkedIn, entretien).
