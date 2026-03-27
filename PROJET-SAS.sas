/* =====================================================
   PROJET SAS 2026 - TRAITEMENT DES SINISTRES ASSURANCE
   ===================================================== */

/* 1. Importer le fichier CSV des sinistres */
data TABLE_SAS_BRUTE;
    infile "/home/u64423420/sasuser.v94/donnees_2026_projet_SAS.csv"
           dlm=";" firstobs=2;

    /* Déclaration des variables au format texte (telles que lues du CSV) */
    length ID_ASSURE $8
           DATE_SIN $8
           GARANTIE $15
           COUT_SIN $8
           REC_SIN $8
           PMT_SIN $8
           PRIME_ANNUELLE $8;
    input ID_ASSURE
          DATE_SIN
          GARANTIE
          COUT_SIN
          REC_SIN
          PMT_SIN
          PRIME_ANNUELLE;
run;


/* 1.b Préparation des données : conversion en numériques + date SAS */
data TABLE_SAS_CLEAN;
    set TABLE_SAS_BRUTE;

    /* Conversion texte → numérique/date */
    ID_ASSURE_num        = input(ID_ASSURE, best32.);
    DATE_SIN_num         = input(DATE_SIN, best32.);
    COUT_SIN_num         = input(COUT_SIN, best32.);
    REC_SIN_num          = input(REC_SIN, best32.);
    PMT_SIN_num          = input(PMT_SIN, best32.);
    PRIME_ANNUELLE_num   = input(PRIME_ANNUELLE, best32.);

    /* Conversion de DATE_SIN en date SAS + format JJ/MM/AAAA */
    format DATE_SIN_num ddmmyy10.;

    /* Suppression des anciennes variables texte */
    drop ID_ASSURE DATE_SIN COUT_SIN REC_SIN PMT_SIN PRIME_ANNUELLE;

    /* Renommage des nouvelles variables numériques */
    rename ID_ASSURE_num       = ID_ASSURE
           DATE_SIN_num        = DATE_SIN
           COUT_SIN_num        = COUT_SIN
           REC_SIN_num         = REC_SIN
           PMT_SIN_num         = PMT_SIN
           PRIME_ANNUELLE_num  = PRIME_ANNUELLE;
run;


/* Vérification qualité des données */
proc means data=TABLE_SAS_CLEAN n nmiss min max mean;
    title "Statistiques descriptives - Vérification qualité données";
    var ID_ASSURE DATE_SIN COUT_SIN REC_SIN PMT_SIN PRIME_ANNUELLE;
run;

proc freq data=TABLE_SAS_CLEAN;
    tables GARANTIE / missing;
run;
/* Résultat : Aucune donnée manquante, valeurs cohérentes
   → Données prêtes pour analyses actuarielles */


/* 2. Création de la variable BRANCHE
      - A à P  : Prévoyance
      - Q à Z  : Dommages aux biens
*/
data TABLE_SAS_B;
    set TABLE_SAS_CLEAN;

    if 'A' <= GARANTIE <= 'P' then BRANCHE = 'Prévoyance';
    else                           BRANCHE = 'Dommages aux biens';
run;


/* 3. Création de l'identifiant de sinistre ID_SIN 
      Forme : AA + GARANTIE + AAAA
      - AA   : 2 derniers chiffres de l'année de DATE_SIN
      - AAAA : 4 derniers chiffres de ID_ASSURE
*/
data TABLE_SAS_ID;
    set TABLE_SAS_B;

    /* 1. Année complète de la date de sinistre */
    Annee_complete = year(DATE_SIN);

    /* 2. Deux derniers chiffres de l'année */
    Derniers2_chiffres_annee = mod(Annee_complete, 100);
    Annee_2chiffres_texte    = put(Derniers2_chiffres_annee, z2.);

    /* 3. 4 derniers chiffres de l'ID assuré */
    ID_4derniers       = mod(ID_ASSURE, 10000);
    ID_4derniers_texte = put(ID_4derniers, z4.);

    /* 4. Construction de l'ID sinistre */
    ID_SIN = cats(Annee_2chiffres_texte, GARANTIE, ID_4derniers_texte);
run;


/* 4. Calcul des provisions */
data TABLE_SAS_PR;
    set TABLE_SAS_ID;

    /* Provision brute : charge - paiements */
    PROV_SINISTRE = sum(COUT_SIN, -PMT_SIN);

    /* Provision nette de recours : jamais négative */
    PROV_SINISTRE_NETTE = max(0, sum(PROV_SINISTRE, -REC_SIN));
run;


/* 5.a Création du ratio SIN_COT = COUT_SIN / PRIME_ANNUELLE */
data TABLE_SAS_SIN_COT;
    set TABLE_SAS_PR;

    /* Eviter la division par zéro */
    if PRIME_ANNUELLE = 0 then SIN_COT = .;
    else                         SIN_COT = COUT_SIN / PRIME_ANNUELLE;
run;


/* 5.b Moyenne du ratio S/C par branche (PROC MEANS) */
proc means data=TABLE_SAS_SIN_COT;
    class BRANCHE;
    var SIN_COT;
    output out=stats_sin_cot_branche
           mean = Mean_S_C;
run;


/* 5.c Moyenne du ratio S/C par garantie (PROC SUMMARY) */
proc summary data=TABLE_SAS_SIN_COT nway;
    class GARANTIE;
    var SIN_COT;
    output out=stats_sin_cot_garantie(drop=_TYPE_ _FREQ_)
           mean = Mean_S_C;
run;

proc print data=stats_sin_cot_garantie noobs;
    title "Ratio moyen S/C par garantie";
    var GARANTIE Mean_S_C;
run;

/* 5.d Commentaire :
   La garantie la plus rentable est celle avec le ratio S/C moyen le plus faible.
   Plus le ratio est bas, plus la branche est rentable pour l'assureur.
*/


/* 6.a Création de la table TOP_SIN :
       sinistres dont la charge COUT_SIN > 2500€, sans centimes
       et ne garder que GARANTIE, ID_SIN, COUT_SIN
*/
data TOP_SIN;
    set TABLE_SAS_SIN_COT;

    /* Filtre : sinistres lourds (COUT_SIN > 2500€) */
    where COUT_SIN > 2500;

    /* Troncature des centimes */
    COUT_SIN_ARRONDI = floor(COUT_SIN);

    /* Garder uniquement les variables demandées */
    keep GARANTIE ID_SIN COUT_SIN_ARRONDI;
    rename COUT_SIN_ARRONDI = COUT_SIN;
run;


/* 6.b Tri de TOP_SIN : sinistres les plus chers en premier */
proc sort data=TOP_SIN
          out=TOP_SIN_TRIE;
    by descending COUT_SIN;
run;

proc print data=TOP_SIN_TRIE noobs;
    title "TOP_SIN : Sinistres avec charge > 2500€ (sans centimes)";
run;


/* 7. Total des provisions nettes par branche */
proc summary data=TABLE_SAS_PR nway;
    class BRANCHE;
    var PROV_SINISTRE_NETTE;
    output out=PROV_PAR_BRANCHE(drop=_TYPE_ _FREQ_)
           sum = PROV_NETTE_TOTALE;
run;


/* 8. Coût moyen d'un sinistre par garantie
      (on repart de la table propre TABLE_SAS_CLEAN)
*/
proc summary data=TABLE_SAS_CLEAN nway;
    class GARANTIE;
    var COUT_SIN;
    output out=SIN_COUTS_MOYENS(drop=_TYPE_ _FREQ_)
    mean = COUT_MOYEN_SINISTRE;
run;


/* 9. Suppression de la table TOP_SIN */
proc sql;
    drop table TOP_SIN;
quit;


/* 10. Ancienneté des sinistres à la date de rendu du projet (21/03/2026) */
data ANCIENNETE_SINISTRES;
    set TABLE_SAS_SIN_COT;

    /* Date de rendu du projet */
    format DATE_RENDU ddmmyy10.;
    DATE_RENDU = '21MAR2026'd;

    /* Ancienneté du sinistre en années */
    ANCIENNETE = intck('year', DATE_SIN, DATE_RENDU, 'c');

    /* Tranches d'ancienneté :
       - Moins de 4 ans
       - 4 ans et plus
    */
    length TRANCHE_ANC $20;
    if ANCIENNETE < 4 then TRANCHE_ANC = "Moins de 4 ans";
    else                    TRANCHE_ANC = "4 ans et plus";
run;


/* 11. Synthèse finale : nombre de sinistres par branche et tranche d'ancienneté */

/* Comptage avec PROC FREQ : une ligne = une combinaison (BRANCHE, TRANCHE_ANC) */
proc freq data=ANCIENNETE_SINISTRES noprint;
    tables BRANCHE*TRANCHE_ANC / out=SYNTHESE_FINALE_SINISTRES;
run;
proc print data=SYNTHESE_FINALE_SINISTRES noobs;
    title "Synthèse finale : Nombre de sinistres par branche et tranche d'ancienneté";
run;
