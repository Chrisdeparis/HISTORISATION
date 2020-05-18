**free
ctl-opt option(*nodebugio:*srcstmt) dftactgrp(*no) bnddir('OUTILS':'ADHESION');

/copy h1wwadhess/qcopsrc,gettauxds
/copy h1frptechs/qcopsrc,s_errords
/copy h1frptechs/qcopsrc,s_jobEnvDs

// Définition des variables
//-------------------------
dcl-s wIdPret                         packed(11:0);
dcl-s wpacpac                         packed(11:0);
dcl-s wdateeffetpalier                date;
dcl-s wgarantie                       packed(5:0);
dcl-s wmontantpalier                  packed(11:2);
dcl-s wmontanttaxe                    packed(11:2);
dcl-s wmontantht                      packed(11:2);
dcl-s wpackro                         packed(11:0);
dcl-s wCompagnie                      packed(3:0);
dcl-s wtauxTva                        packed(5:3);
dcl-s wcodePays                       packed(5:0);
dcl-s wdate8                          packed(8:0);
dcl-s wMajOK                          int(10);
dcl-s wNbTraite                       int(10);
dcl-s wcurscod                        like(sqlcode);

//Indicateurs d'erreurs
dcl-s errInit                         ind;
dcl-s errTrtPaliers                   ind;
dcl-s errRechercheInfosPrets          ind;
dcl-s errRechercheTauxTaxe            ind;
dcl-s errUpdatePalier                 ind;
dcl-s werr                            ind;
dcl-s rc                              int(10);
dcl-s NbrOfRows                       int(5) inz(%elem(wds));
dcl-s i                               int(5);
dcl-s RowsFetched                     int(5) ;
dcl-s w_message                       char(50);
dcl-s Offset                          int(10) ;
dcl-s wF_IDPRET                       char(11);
dcl-s wF_IDGARGARANTIEINCLUSE         char(5);
dcl-s wC_TAUX                         char(5);            // h43TAU
dcl-s wprtcie                         char(3);            //F_CIECODE
dcl-s wprtban                         char(5);            //F_BANCODE
dcl-s wh43ggi                         char(5);            //F_IDGARGARANTIEINCLUSE
dcl-s wprtdrt                         date;               //C_DATEREFERENCETARIFAIRE
dcl-s wnbLecture int(5);
dcl-s wsqlcodCurseur int(5);

dcl-ds TauxTaxeDS                     likeds(gettauxtaxeds_t);
dcl-ds wds qualified dim(10);
  F_IDPRET                            zoned(11:0);
  F_IDGARGARANTIEINCLUSE              zoned(5:0);
  C_TAUX                              zoned(5:3);
end-ds;

// Déclaration des curseurs
//--------------------------
//Lecture du fichier des paliers
// curseur de lecture
exec sql
  declare curs_01 cursor for
  select prtcie, prtban, h43ggi, prtdrt from wwadhesf.adh1h43pf
  inner join wwadhesf.p0amadpf on h43kmv=madkmv
  inner join wwadhesf.t4pprtpf on madkro=prtkro
  order by c_dateeffetpalier_avant;

monitor;

  clear wds;
  exsr RechercheData;

  Offset += %elem(wds) ;     //10

  wF_IDPRET = %char(wds(i).F_IDPRET);
  wF_IDGARGARANTIEINCLUSE  =  %char(wds(i).F_IDGARGARANTIEINCLUSE);
  wC_TAUX =  %char(wds(i).C_TAUX);


  w_message = 'idpret: '
  + %trim( wF_IDPRET)
  + ' pacggi: '
  + %trim( wF_IDGARGARANTIEINCLUSE)
  + ' h43tau: '
  + %trim( wC_TAUX)
  + '.';

  dsply (%trim(w_message));


on-error *all;

endmon;

eval *inlr = *on;

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


// Recherche Data
begsr RechercheData ;

  RowsFetched = 0 ;
  clear wDs ;


  //where cornat = 250
  //and cordte = '0001-01-01'
  //and cordat = :pcordat
  //order by cornum, corord
  //for fetch only
  //limit 10;

  // ouverture curseur
  exec sql open CURS_01;
  wsqlcodCurseur = sqlcode;

  if wsqlcodCurseur = *zero; // pas erreur open curseur

    clear wprtcie;
    clear wprtban;
    clear wh43ggi;
    clear wprtdrt;
    wnbLecture = 0;



    // lecture curseur
    exec sql
    fetch next from curs_01
    into :wprtcie, :wprtban, :wh43ggi, :wprtdrt;

    if wsqlcodCurseur = 0;
      //update C_TAUX
      exec sql
      update adh1h43pf
    set h43tau=:wc_taux
    where current of curs_01;
    endif;

    wsqlcodCurseur = sqlcode;

    dow wsqlcodCurseur <> 100; // tant que pas fin de curseur

      wnbLecture += 1;

      // coder ci dessous le traitement
      //dsply ('num oav : ' + %char(wcornum));
      w_message = 'F_CIECODE: '
     + %trim( wprtcie)
     + ' F_BANCODE: '
     + %trim( wprtban)
     + ' F_IDGARGARANTIEINC: '
     + %trim( wh43ggi)
     //                  + ' C_DATEREFERENCETARIFAIRE: '
     //                  + %trim( wprtdrt)
     + '.';

      dsply (%trim(w_message));

      // lecture curseur
      exec sql
      fetch next from curs_01
      into :wprtcie, :wprtban, :wh43ggi; //, :wprtdrt;

      wsqlcodcurseur = sqlcode;

    enddo;

    select;
    when wsqlcodCurseur = 0;
    when wsqlcodCurseur = 100;
    // sortie de boucle normale

    other;
      // erreur : sortie de boucle anormale
      //              m_error ('000190'
      //                      :*omit
      //                      :'erreur fetch'
      //                        // ajouter les données de contexte (numéro oav...)
      //                      :'*Sql'
      //                      :'INFO'
      //                      :' '
      //                      );
      dsply ('error');
    endsl;

  exec sql close CURS_01;

  else; // erreur open curseur
    //           m_error ('000203'
    //                   :*omit
    //                   :'erreur open curseur CURS_01'
    //                   :'*Sql'
    //                   :'INFO'
    //                   :' '
    //                   );
    dsply ('error');
  endif;

endsr;











 
