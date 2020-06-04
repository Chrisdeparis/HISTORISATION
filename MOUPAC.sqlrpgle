**free
ctl-opt option(*nodebugio:*srcstmt) dftactgrp(*no) bnddir('OUTILS':'ADHESION');

/copy qcopsrc,gettauxds
/copy qcopsrc,s_errords
/copy qcopsrc,s_jobEnvDs

dcl-ds jobSetIdDs            likeDs(m_jobSetIdDs_t);


//-- Variables de travail
dcl-s wsqlcodcurseur                 int(5);
dcl-s wsqlcodcurseur2                int(5);
dcl-s wprtcie                        zoned(3:0);      //F_CIECODE
dcl-s wprtban                        zoned(5:0);      //F_BANCODE
dcl-s wpacggi                        zoned(5:0);      //F_IDGARGARANTIEINCLUSE
dcl-s wpactau                        zoned(5:3);
dcl-s wpackro                        zoned(11:0);
dcl-s wnbLecture                     int(5);
dcl-s w_message                      char(50);
dcl-s wNbLignesLues                  int(10);
dcl-s wnbLigneATraiter               zoned(12);
dcl-ds TauxTaxeDS                    likeds(gettauxtaxeds_t);
dcl-s rc                             int(5);
dcl-s wIdPret                        packed(11:0);
dcl-s wgarantie                      packed(5:0);
dcl-s wCompagnie                     packed(3:0);
dcl-s wcodePays                      packed(5:0);
dcl-s wprtdrt                        date;
dcl-s wdate8                         packed(8:0);
dcl-s widpaystaxe                    zoned(5:0);
dcl-s errGlobale                     ind;
dcl-s errRechercheTauxTaxe           ind;
dcl-s wErrParm                       ind;
dcl-s wErrPret                       ind;
dcl-s wErrUpdateTraite               ind;
dcl-s wErrBan                        ind;
dcl-s errInit                        ind;
dcl-s werrCountLine                  ind;
dcl-s wCountMAJ                      int(10);
dcl-s wtraite                        char(1);
// Déclaration constantes
dcl-c c_Archivage                    const(13);
dcl-c c_OAV                          const(4);

dcl-pi *n;
  //paremeter list
  quantiteParm char(8);
end-pi;

// Déclaration des curseurs
//--------------------------
// TABLE PRETPRIORITAIRE
exec sql
  declare curs_01 cursor for
  select idpret, traite
  from pretprioritaire
  where traite='N'
  for update with nc;

// table ADH1PACPF
exec sql
declare curs_02 cursor for
select pacggi, packro
from adh1pacpf
where pactau is null and packro=:widpret
order by packro
for update with nc;

//---------- début procédure principale ------------------------------


exsr init;

if not ErrInit;
  // controle parametre quantiteParm obligatoire
  // todo : ajouter test sur werrParm pour ne pas executer traiter curseur
    exsr traiterCurseur;
else;
  errGlobale = *on;

endif;
  m_error('000204'
          :*omit
          :'NB de lignes MAJ = '
          + %char(wCountMAJ)
          :'*Other'
          :'INFO'
          :%char(rc));
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
    m_error('000239'
          :*omit
          :'Erreur lors de l''initialisation'
          :'*Other'
          :'INFO'
          :%char(rc));
  else;
  endif;
endsr;

begsr traiterCurseur;
  // ouverture curseur
  exec sql
  open curs_01;

  wsqlcodcurseur = sqlcode;

  if wsqlcodcurseur = 0; // pas erreur open curseur

    clear widpret;
    clear wtraite;

    // lecture curseur
    exec sql
      fetch next from curs_01
      into :widpret, :wtraite;

    wsqlcodcurseur = sqlcode;

    wNbLignesLues=0;  //
    dow wsqlcodcurseur = 0;
      // Traitement d'un pret
      exsr TraiterPret;

      // update pret prioritaire
      exec sql
        update pretprioritaire
          set traite='O'
          where current of curs_01;
      if sqlcode=0;
      else;
        wErrUpdateTraite = *on;
        m_error('000284'
              :*omit
              :  'Erreur - Update Traite-  '
               + 'sqlcode = '
               + %char(sqlcode)
               :'*Other'
              :'INFO'
              :%char(rc));
      endif;
      // fetch curs_01
      exec sql
        fetch next from curs_01
        into :widpret, :wtraite;

      wsqlcodcurseur = sqlcode;
    enddo;
    if wsqlcodcurseur = 100;  // todo : à déplacer aprés enddo
      if wNbLignesLues > 0;

      else;
        m_error('000402'
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
        m_error('000413'
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
    m_error('000428'
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


begsr TraiterPret;
  wCountMAJ=0;
  // ouverture curseur
  exec sql
  open curs_02;

  wsqlcodcurseur2 = sqlcode;

  if wsqlcodcurseur2 = 0; // pas erreur open curseur

    clear wpacggi;
    clear wpackro;

    // lecture curseur
    exec sql
    fetch next from curs_02
    into :wpacggi, :wpackro;

    wsqlcodcurseur2 = sqlcode;

    wNbLignesLues=0;  //
    dow wsqlcodcurseur2 = 0;
      wNbLignesLues += 1;
      clear wprtcie;
      clear wprtban;
      clear wprtdrt;

      // recuperer prtcie, prtdrt et prtban
      wErrPret = *off;
      exec sql
      select  prtcie, prtdrt, prtban
      into  :wprtcie, :wprtdrt, :wprtban
      from t4pprtpf
      where prtkro = :widpret;


      if sqlcode=0;
      else;
        werrpret = *on;
        m_error('000480'
             :*omit
             :  'Erreur - Pret   '
              + '-wpackro = '
              + %char(wpackro)
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
          m_error('000502'
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
        clear wpactau;

        // implémente les variables
        wdate8 = %dec(wprtdrt);
        wgarantie = wpacggi;
        wCompagnie = wprtcie;
        wcodePays = widpaystaxe;

        TauxTaxeDS.Pays = wcodePays;
        TauxTaxeDS.Cie = wCompagnie;
        TauxTaxeDS.Garantie = wgarantie;
        TauxTaxeDS.DateCalcul = wdate8;

        //appel m_getTaux
        rc = m_getTauxTaxe(TauxTaxeDS);
        if rc = 0;
          // todo : ajouter update sur adh1pacpf
          exec sql
          update adh1pacpf
          set pactau=:tauxtaxeds.tauxtaxe
          where current of curs_02;

          if sqlcode=0;              // verification exec sql
            wCountMAJ += 1;
          else;
            m_error('000541'
                 :*omit
                 :  'Erreur - update -  '
                  + %char(wpactau)
                  + 'sqlcode = '
                  + %char(sqlcode)
                  :'*Other'
                 :'INFO'
                 :%char(rc));
          endif;
        else;
          errRechercheTauxTaxe = *on;
          m_error('000553'
               :*omit
               :  'Erreur - calcul taux de taxe -  '
                + '1ére tentative '
                + 'pour garantie '
                + %char(wpacggi)
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
      fetch next from curs_02
      into :wpacggi, :wpackro;



      // todo : ajouter wsqlcodcurseur2 = sqlcode
      wsqlcodcurseur2 = sqlcode;
    enddo;
    if wsqlcodcurseur2 = 100;  // todo : à déplacer aprés enddo
      if wNbLignesLues > 0;

      else;
        m_error('000597'
                :*omit
                :  'Erreur - fichier vide -  '
                 + 'boucle invalide '
                :'*Other'
                :'INFO'
                :%char(rc));
      endif;
    else;
      if wsqlcodcurseur2= 0;
      else;
        m_error('000608'
                :*omit
                :  'Erreur - wsqlcodcurseur2 -  '
                 + 'boucle invalide '
                 + 'sqlcode = '
                 + %char(wsqlcodcurseur2)
                :'*Other'
                :'INFO'
                :%char(rc));
      endif;
    endif;
  //close cursor
  exec sql
    close curs_02;
  else;// erreur sur open cursor
    m_error('000623'
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
 
