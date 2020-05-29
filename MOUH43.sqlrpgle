**free
ctl-opt option(*nodebugio:*srcstmt) dftactgrp(*no) bnddir('OUTILS':'ADHESION');

/copy qcopsrc,gettauxds
/copy qcopsrc,s_errords
/copy qcopsrc,s_jobEnvDs

dcl-ds jobSetIdDs            likeDs(m_jobSetIdDs_t);


//-- Variables de travail
dcl-s wsqlcodCurseur                 int(5);
dcl-s wprtcie                        zoned(3:0);      //F_CIECODE
dcl-s wprtban                        zoned(5:0);      //F_BANCODE
dcl-s wh43ggi                        zoned(5:0);      //F_IDGARGARANTIEINCLUSE
dcl-s wpacggi                        zoned(5:0);      //F_IDGARGARANTIEINCLUSE
dcl-s wNbTraite                      int(10);
dcl-s wh43tau                        zoned(5:3);
dcl-s wpactau                        zoned(5:3);
dcl-s wtauxtaxe                      zoned(5:3);
dcl-s wpackro                        zoned(11:0);
dcl-s wnbLecture                     int(5);
dcl-s w_message                      char(50);
dcl-s w_message2                     char(50);
dcl-s w_codeEntree                   char(20);
dcl-s wh43kmv                        zoned(11:0);
dcl-s w_codeSortie                   packed(5);
dcl-s w_returnCode                   int(10);
dcl-s errCheckParm                   ind;
dcl-s wCountLu                       int(5);
dcl-s wquantiteNum                   zoned(8);
dcl-s wErrParm                       ind;
dcl-s wparm                          zoned(9);
dcl-s errRechercheTauxTaxe           ind;
dcl-ds TauxTaxeDS                    likeds(gettauxtaxeds_t);
dcl-s rc                             int(5);
dcl-s wIdPret                        packed(11:0);
dcl-s wgarantie                      packed(5:0);
dcl-s wCompagnie                     packed(3:0);
dcl-s wcodePays                      packed(5:0);
dcl-s wprtdrt                        date;
dcl-s wdate8                         packed(8:0);
dcl-s widpaystaxe                    zoned(5:0);
dcl-s wtaxtau                        zoned(5:3);
dcl-s errGlobale                     ind;
dcl-s wErrPret                       ind;
dcl-s wErrBan                        ind;
dcl-s errInit                        ind;
// Déclaration constantes
dcl-c c_Archivage         const(13);
dcl-c c_OAV               const(4);

dcl-pi *n;
  //paremeter list
  quantite char(8);
end-pi;

// Déclaration des curseurs
//--------------------------
//Lecture du fichier des paliers
// curseur de lecture
// table ADH1H43PF
exec sql
declare curs_01 cursor for
select h43ggi, h43kmv
from adh1h43pf
where h43tau is null
order by h43kmv
for update with nc;

//---------- début procédure principale ------------------------------


exsr init;

  if not ErrInit;
    // controle parametre quantite obligatoire
    exsr controlparam;
    // todo : ajouter test sur werrParm pour ne pas executer traiter curseur
       if not werrParm;
          exsr traiterCurseur;
       else;
          errGlobale = *on;
       endif;
  else;
    errGlobale = *on;
  endif;
*inlr = *on; // todo : en fin de procédure principale

//----------   fin procédure principale ------------------------------


//---------- début sub routines ------------------------------
begsr Init;
  clear jobSetIdDs;
  jobsetidds.idDomaine = c_OAV;
  jobsetidds.idApplication = c_Archivage;

   rc = m_jobsetid(jobsetidds) ;

 if rc <> 0;
   errInit = *on;
   m_error('000215'
          :*omit
          :'Erreur lors de l''initialisation'
          :'*Other'
          :'INFO'
          :%char(rc));
 else;
 endif;
endsr;

begsr controlparam;
  wErrParm = *off;
  if quantite <> *blank;
    monitor;
    // todo : mettre ici le %dec
   wquantiteNum = %dec(quantite:8:0); //
    on-error;    // ko
      wErrParm = *on;
    endmon;
  else;
    wErrParm = *on;
  endif;
endsr;

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

        wCountLu=0;  //
      dow wsqlcodcurseur = 0 and wCountLu <= wquantiteNum;
        wCountLu += 1;
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
            m_error('000279'
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
            m_error('000301'
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
              else;
                m_error('000339'
                     :*omit
                     :  'Erreur - update -  '
                      + %char(wh43tau)
                      + 'sqlcode = '
                      + %char(sqlcode)
                      :'*Other'
                     :'INFO'
                     :%char(rc));
              endif;
          else;
            errRechercheTauxTaxe = *on;
            m_error('000351'
                 :*omit
                 :  'Erreur - calcul taux de taxe -  '
                  + '1ére tentative '
                  + 'pour garantie/pays/cie/date '
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
             m_error('000373'
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
        if wcountlu > 0;

        else;
         m_error('000390'
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
         m_error('000555'
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
         m_error('000418'
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
