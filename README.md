# HISTORISATION
## Développement d'une moulinette : curseur qui va mettre à jour une colonne dans une table

Je souhaite historiser les modifications de taux de taxe en ajoutant la valeur du taux par garantie sur chaque palier de cotisation
Afin de conserver une trace

Definir le périmetre du pgm : F_IDPRET représente un dossier.


## Le montant palier : 

le palier c'est le détail des cotisations par garantie qu'on prélève aux assurés : 
- dans ce palier tu as le montant TTC
- le montant HT
- le montant de taxe
- et maintenant on doit rajouter le taux => C_TAUX dans ADH1PACPF :ok_hand::ok_hand:

## Recherche Taux Taxe

```sql
// Recherche taux taxe par garantie
//---------------------------------
begsr rechercheTauxTaxe;

  errRechercheTauxTaxe = *off;
  clear TauxTaxeDS;
  clear rc;
  clear wTauxTva;
  clear wmontantht;
  clear wmontanttaxe;

  wdate8 = %dec(wprtdrt);

  TauxTaxeDS.Pays = wcodePays;
  TauxTaxeDS.Cie = wCompagnie;
  TauxTaxeDS.Garantie = wgarantie;
  TauxTaxeDS.DateCalcul = wdate8;

  //Récupération du taux de taxe
  rc = m_getTauxTaxe(TauxTaxeDS);

  if rc = 0;
    wTauxTva = TauxTaxeDS.TauxTaxe;
    wTauxTva = (wTauxTva / 100) + 1;
    wmontantHT = %dech(wmontantPalier/wTauxTva:11:2);
    wmontantTaxe = wmontantPalier - wmontantHT ;
  else;
    errRechercheTauxTaxe = *on;
    m_error('000458'
            :*omit
            :'errreur recherche taux de taxe pour le prêt, '
            +%char(wpackro)
            :'*Other'
            :'INFO'
            :%char(rc));
  endif;
endsr;
```
A changer car la demande est différente : 

> lecture palier
> si **palier** concerne une oav crée **avant 01/01/2019**

> **taux dc = 0** / taux **autre garantie = 9**

> sinon (oav crée **à partir 01/01/2019)**

> **taux dc = 9** / taux **autre garantie = 9**

> fin Si  

## La date de référence tarifaire

```
select prtdrt from WWADHESF.t4pprtpf;
```
Information qui vient du métier Oui, la date pivot est bien la date de référence tarifaire (date qui est présente dans nos BDD puisqu'elle apparaît sur l'OAV).

## Le taux Décès

c'est la garantie 3 : pacggi : C'est aussi une règle métier.

```sql
-- La colonne garantie
select pacggi from  wwadhesf.adh1pacpf order by f_idpret, c_dateeffetpalier;
-- table P_IDGARGARANTIEINCLUSE                     
select * from WWANNEXF.pa1xggipf;
```

## Les prêts
t4pprtpf

## ADH1PACPF

|    NOMS COURT                  |      ALIAS                     |
| :----------------------------: | :----------------------------: |
| PACPAC     CONDEN      11  0   |     P_IDPALIERCOTISATION       |
| PACMPA     CONDEN      11  2   |     C_MONTANTPALIER            | 
| PACDEP     DATE           10   |     C_DATEEFFETPALIER          |
| PACDMO     HORODAT     26  6   |     C_DATEMODIFICATION         | 
| PACKRO     CONDEN      11  0   |     F_IDPRET                   | 
| PACGGI     CONDEN       5  0   |     F_IDGARGARANTIEINCLUSE     | 
| PACTAU     CONDEN       5  3   |     C_TAUX                     |  
| PACMTX     CONDEN      11  2   |     C_MONTANTTAXE              |  
| PACMHT     CONDEN      11  2   |     C_MONTANTHT                |  
| PACPRO     ALPHA          10   |     F_PROFIL                   | 

## ADH1H43PF

|   NOMS COURT                   |    ALIAS                       |
| :----------------------------: | :----------------------------: |
| H43DMO TIMESTAMP               | C_dateModification             |
| H43MPB DECIMAL(11, 2)          | C_montantPalier_Avant          |
| H43DEB DATE                    | C_dateEffetPalier_Avant        |
| H43NLI DECIMAL(3, 0)           | P_numeroLigne                  |
| H43KMV DECIMAL(11, 0)          | X_idHistoMouvement             |
| H43GGI DECIMAL(5, 0)           | F_idGarGarantieIncluse         |
| H43TAU DECIMAL(5, 3)           | C_taux                         |
| H43MTX DECIMAL(11, 2)          | C_montantTaxe                  |
| H43MHT DECIMAL(11, 2)          | C_montantHt                    |
| H43PRO CHAR(10)                | F_profil

Utiliser de préférences les alias dans le code pour la lisibilité et compréhension du code.

Les 3 variables à manipuler dans ce programme sont donc : 
- F_IDPRET
- F_IDGARGARANTIEINCLUSE
- C_TAUX

## M_getTauxTaxe
L'intéret d'utiliser cette procédure c'est qu'elle retourne le taux à partir de 4 paramètres à renseigner qui sont
- wdate8 = %dec(wprtdrt); 
- wgarantie = wh43ggi;
- wCompagnie = wprtcie; 
- wcodePays = widpaystaxe;
Cette fonction retourne le taux de taux de taxe en fonction de la date. On est bon.
Pour debuger une procedure externe : shift F10
## table de version
Pour pouvoir utiliser les nouvelles colonnes il faut ajouter la bibliothèque de version pour tester en intégration.

```diff
+ addlible adh20140a
```

Pour debugger utiliser adh1logpf avec m_error
```diff
+ SELECT * FROM adh1logpf WHERE date(logdhe)='2020-05-26' ORDER BY 
+ logdhe desc   
```

## Init
```diff
/copy h1frptechs/QCOPSRC,S_JOBENVDS
// Déclaration constantes                                                                          
dcl-c c_Archivage         const(13);                                                                
dcl-c c_OAV               const(4);
```
Au début du programme pour créer l'initialisation et permettre d'envoyer les logs
```diff
+ -- fichier a1ilog
+ SELECT * FROM BIBCOMMU.a1ilogpf WHERE date(logdhe)='2020-05-27' ORDER BY
+ logdhe desc;   
+ --- visualisation fichier log
+ SELECT * FROM wwadhesf.adh1logpf WHERE date(logdhe)='2020-05-27' ORDER BY
+ logdhe desc;        
```
wrkobjlock pour débloquer une table.
```diff
+ -- tester la première ligne
+ update WWADHESF.adh1h43pf set c_taux = null where c_taux is not null;
+ commit;
```
```sql
-- verifier taux de taxe en sortie de m_gettauxtaxe en fonction du code pays, compagnie et la garantie
select * from wwannexf/t4ptaxpf
where x_ciecode = 25
and f_idpays = 71
and taxgar = 15
```
## For Update 
 Dans la requete sql : le for update n'est pas possible avec des jointures. :warning: :warning:
```sql
declare curs_01 cursor for
select h43ggi, h43kmv
from adh1h43pf
where h43tau is null
order by h43kmv
for update with nc;
```
## Traitement des exec sql
Toujours faire le traitement des exec sql juste après pour controler le bon déroulement.
```diff
if sqlcode=0;
else;
  wErrBan = *on;
  m_error('000307' // => la ligne dans le code source
          :*omit
          :  'Erreur - prtban -  ' // préciser le contexte
          + %char(wprtban)
          + 'sqlcode = '          // récupérer le sqlcode
          + %char(sqlcode)
          :'*Other'
          :'INFO'
          :%char(rc));
endif;
```
## Template cursor
```diff
begsr traiterCurseur;
  // ouverture curseur
  exec sql
  open curs_01;

  wsqlcodcurseur = sqlcode;

  if wsqlcodcurseur = 0; // pas erreur open curseur

    clear wh43ggi;
    clear wh43kmv;
    // lecture curseur
    exec sql
    fetch next from curs_01
    into :wh43ggi, :wh43kmv;

    wsqlcodCurseur = sqlcode;

    wNbLignesLues=0;  //
    dow wsqlcodcurseur = 0 and wNbLignesLues <= wnbLigneATraiter;
      wNbLignesLues += 1;
      clear wprtcie;
      clear wprtban;
      clear wprtdrt;

      // recuperer prtcie et prtdrt
      wErrPret = *off;
      exec sql
      select prtcie, prtdrt, prtban
      into :wprtcie, :wprtdrt, :wprtban
      from  p0amadpf
      inner join t4pprtpf on madkro=prtkro
      where madkmv = :wh43kmv;
      if sqlcode=0;
      else;
        wErrPret = *on;
        m_error('000303'
             :*omit
             :  'Erreur - Pret   '
              + '-wh43kmv = '
              + %char(wh43kmv)
              :'*Other'
             :'INFO'
             :%char(rc));
      endif;

      if not wErrPret;

        wErrBan=*off;
        //recherche pays banque
        exec sql
        select f_idpays_taxe
        into :widpaystaxe
        from p1abqepf
        where f_bancode = :wprtban;
        if sqlcode=0;
        else;
          wErrBan = *on;
          m_error('000325'
               :*omit
               :  'Erreur - prtban -  '
                + %char(wprtban)
                + 'sqlcode = '
                + %char(sqlcode)
                :'*Other'
               :'INFO'
               :%char(rc));
        endif;
        // todo : ajouter test sqlcode
        errrecherchetauxtaxe = *off;
        clear TauxTaxeDS;
        clear rc;
        clear  wh43tau;

        // implémente les variables
        wdate8 = %dec(wprtdrt);
        wgarantie = wh43ggi;
        wCompagnie = wprtcie;
        wcodePays = widpaystaxe;

        TauxTaxeDS.Pays = wcodePays;
        TauxTaxeDS.Cie = wCompagnie;
        TauxTaxeDS.Garantie = wgarantie;
        TauxTaxeDS.DateCalcul = wdate8;

        //appel m_getTaux
        rc = m_getTauxTaxe(TauxTaxeDS);
        if rc = 0;
          // todo : ajouter update sur adh1h43pf
          exec sql
          update adh1h43pf
          set h43tau=:tauxtaxeds.tauxtaxe
          where current of curs_01;

          if sqlcode=0;              // verification exec sql
            wCountMAJ += 1;
          else;
            m_error('000364'
                 :*omit
                 :  'Erreur - update - C_TAUX '
                  + %char(wh43tau)
                  + 'sqlcode = '
                  + %char(sqlcode)
                  :'*Other'
                 :'INFO'
                 :%char(rc));
          endif;
        else;
          errRechercheTauxTaxe = *on;
          m_error('000376'
               :*omit
               :  'Erreur - calcul taux de taxe -  '
                + '1ére tentative '
                + 'pour garantie/ '
                + %char(wh43ggi)
                + '/71/' + %char(wprtcie)
                + %char(wprtdrt)
                + ' pour pret '
                + %char(wIDPRET)
               :'*Other'
               :'INFO'
               :%char(rc));
        endif;
      endif;
      // lecture curseur
      exec sql  // todo : déplacer avant enddo
      fetch next from curs_01
      into :wh43ggi, :wh43kmv;

      if sqlcode=0; // verification exec sql
      else;
        m_error('000398'
              :*omit
              :  'Erreur - sqlcode-  '
               + 'sqlcode = '
               + %char(sqlcode)
               :'*Other'
              :'INFO'
              :%char(rc));
      endif;

      // todo : ajouter wsqlcodcurseur = sqlcode
      wsqlcodcurseur = sqlcode;
    enddo;
    if wsqlcodCurseur = 100;  // todo : à déplacer aprés enddo
      if wNbLignesLues > 0;

      else;
        m_error('000415'
                :*omit
                :  'Erreur - fichier vide -  '
                 + 'boucle invalide '
                :'*Other'
                :'INFO'
                :%char(rc));
      endif;
    else;
      if wsqlcodcurseur= 0;
      else;
        m_error('000426'
                :*omit
                :  'Erreur - wsqlcodcurseur -  '
                 + 'boucle invalide '
                 + 'sqlcode = '
                 + %char(wsqlcodcurseur)
                :'*Other'
                :'INFO'
                :%char(rc));
      endif;

    endif;

  //close cursor
  exec sql
  close curs_01;
  else;// erreur sur open cursor
    m_error('000443'
            :*omit
            :  'Erreur -open cursor -  '
             + 'boucle invalide '
             + 'sqlcode = '
             + %char(sqlcode)
            :'*Other'
            :'INFO'
            :%char(rc));
  endif;
endsr;

```
## Batch
```diff
+ SBMJOB CMD(CALL PGM(MOUPAC)) JOB(MOUPAC) USER(A0OAV)
+ wrksbmjob
```
Pour verifier l'état de la commande et vérifier si le batch est actif.

## Bibliothèque pour les programmes
Toujours placer les programmes dans H1WWADHESO :warning: :warning: dans Arcade.

## CALL [MOUPAC](https://github.com/Chrisdeparis/HISTORISATION/blob/master/MOUPAC.sqlrpgle)
Le programme MOUPAC traite dans son curseur les idPret quand traite='N'.
Quand la moulinette se passe normalement traite='O'; :smile: :smile:
```diff
select * 
  from WWADHESF.pretprioritaire; 
```
| IDPRET   | TRAITE  |
| :------: | :-----: |
| 4295327	 |   O     |
| 4295351	 |  O      |
| 4296188	 |  O      |

En analysant la table ADH1PACPF on va donc voir les MAJ du C_TAUX qui sont effectuées pour chaque clé IDPRET correspondantes.
```sql
select *from WWADHESF.adh1pacpf where packro=4295327;
select *from WWADHESF.adh1pacpf where packro=4295351;
select *from WWADHESF.adh1pacpf where packro=4296188;
