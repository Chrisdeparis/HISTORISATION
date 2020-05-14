**free
//===================================================================================
//                     GENERALITES PROGRAMME
//-----------------------------------------------------------------------------------
//  ENTETE PROGRAMME
//  ----------------
//
//  Nom du programme : MOUTXHTPRO
//  Date de création : 06/04/2020
//  Titre programme  : Moulinette de MAJ ADH1PACPF
//
//  Programmeur      : YRA
//  N° demande       : JIRA OAV-1467 Patch OAV C2020-12 - ADH1PACPF :
//                     Anomalie lors de modifications des paliers
// ----------------------------------------------------------------------------------
//  RESUME PROGRAMME
//  ----------------
//  Moulinettes de MAJ des montants taxe et hors taxe et profil sur les
//  paliers de cotisation
//
//  Périmètre: tous les paliers où pacmht est à null
//
// ----------------------------------------------------------------------------------
//  HISTORIQUE DES MODIFICATIONS
//  ----------------------------
//
//
//-----------------------------------------------------------------------------------
//===================================================================================
//                     SOURCE - PROGRAMME
//-----------------------------------------------------------------------------------
//
//            *********************************
//            *  DECLARATIONS                 *
//            *********************************
//
//====================   DECLARATION DES FORMATS ====================================
ctl-opt dftactgrp(*no) actgrp(*caller) bnddir('OUTILS':'ADHESION');

// Définition des DS
//-------------------
/copy h1frptechs/qcopsrc,s_errords
/copy h1frptechs/qcopsrc,s_jobEnvDs
/copy h1wwadhess/qcopsrc,gettauxds

// Déclaration des constantes
//---------------------------
dcl-c c_adhesion                     const(4);
dcl-c c_outils                       const(99);

// Définition des variables
//-------------------------
dcl-s wIdPret                        packed(11:0);
dcl-s wpacpac                        packed(11:0);
dcl-s wdateeffetpalier               date;
dcl-s wgarantie                      packed(5:0);
dcl-s wmontantpalier                 packed(11:2);
dcl-s wmontanttaxe                   packed(11:2);
dcl-s wmontantht                     packed(11:2);
dcl-s wpackro                        packed(11:0);
dcl-s wCompagnie                     packed(3:0);
dcl-s wtauxTva                       packed(5:3);
dcl-s wcodePays                      packed(5:0);
dcl-s wprtdrt                        date;
dcl-s wdate8                         packed(8:0);
dcl-s wMajOK                         int(10);
dcl-s wNbTraite                      int(10);
dcl-s wcurscod                       like(sqlcode);

//Indicateurs d'erreurs
dcl-s  errInit                       ind;
dcl-s  errTrtPaliers                 ind;
dcl-s  errRechercheInfosPrets        ind;
dcl-s  errRechercheTauxTaxe          ind;
dcl-s  errUpdatePalier               ind;
dcl-s  werr                          ind;
dcl-s  rc                            int(10);

dcl-ds TauxTaxeDS                    likeds(gettauxtaxeds_t);
dcl-ds w_jobSetIdDs                  likeds(m_jobSetIdDS_t);
// //
dcl-pi *n;
end-pi;

// Déclaration des curseurs
//--------------------------
//Lecture du fichier des paliers
exec sql
  declare LecturePaliers cursor for
    select pacmpa, pacggi, pacdep, pacpac, packro
    from adh1pacpf
    where pacmht is null
    order by pacggi, pacdep;


//=================== TRAITEMENT PRINCIPAL ===============================
//------------------------------------------------------------------------
monitor;

  exsr trt_init;

  if not errInit;

    exsr trt_paliers;

    if errTrtPaliers;
      werr = *on;
    endif;

  else;
    werr = *on;
  endif;

on-error *all;
  m_error('000215'
         :*omit
         :'Erreur inattendue dans le traitement la mise à jour palier'
         :'*Other'
         :'INFO'
         :'99');
endmon;

exsr trt_finpgm;

//=====================  SOUS-PROGRAMMES ===============================
//----------------------------------------------------------------------

// Initialisation environnement
//-----------------------------
begSr trt_init;
  rc = 0;
  werr = *off;
  errInit = *off;
  clear w_jobSetidDs;

  w_jobSetidDs.idDomaine = c_adhesion;
  w_jobSetidDs.idApplication = c_outils;

  rc = m_jobSetId(w_jobSetidDs);

  m_Errrct(m_errrctDs);

  if rc <> 0;
    errInit = *on;
    m_error ('000245'
             :*omit
             :'Erreur initialisation environnement '
             :'*Other'
             :'INFO '
             :%char(rc));
  else;
    m_error ('000252'
             :*omit
             :'DEBUT: Traitement mise à jour ADH1PACPF '
             :'*Other'
             :'INFO '
             :'00');
  endif;

endsr;

// Traitement des paliers pour un prêt
//-----------------------------------------------------
begSr trt_paliers;


  errTrtPaliers = *off;
  clear wMajOK;
  clear wNbTraite;
  clear wdate8;
  clear wmontantpalier;
  clear wgarantie;
  clear wdateeffetpalier;
  clear wpacpac;
  clear wpackro;

  //Ouverture du curseur
  exec sql open LecturePaliers;

  wcurscod = sqlcode;

  if wcurscod = 0;

    exec sql fetch LecturePaliers
    into :wmontantpalier, :wgarantie,
         :wdateeffetpalier, :wpacpac, :wpackro;

    wcurscod = sqlcode;

    dow wcurscod = 0;

      wNbTraite = wNbTraite + 1;

      exsr rechercheInfosPrets;

      if not errRechercheInfosPrets;

        exsr rechercheTauxTaxe;

        if not errRechercheTauxTaxe;

          exsr updatePalier;

          if not errUpdatePalier;

            wMajOK = wMajOK + 1;

          else;
            errTrtPaliers = *on;
          endif;

        else;
          errTrtPaliers = *on;
        endif;

      else;
        errTrtPaliers = *on;
      endif;

      exec sql fetch LecturePaliers
      into :wmontantpalier, :wgarantie,
           :wdateeffetpalier, :wpacpac, :wpackro;

      wcurscod = sqlcode;

      if wcurscod = 100;
        leave;
      endif;

    enddo;
    if wcurscod <> 100;
      errTrtPaliers = *on;
      m_error('000379'
             :*omit
             :'errreur à la sortie du curseur LecturePaliers '
             :'*SQL'
             :'INFO'
             :%char(sqlcode));
    endif;

  exec sql close LecturePaliers;

  else;//erreur lors de l'ouverture du curseur
    errTrtPaliers = *on;
    m_error('000391'
            :*omit
            :'Une erreur s''est produite lors de '
            +'l''ouverture du curseur LecturePaliers'
            :'*SQL'
            :'INFO'
            :%char(sqlcode));
  endif;

endsr;

// Recherche infos Prets
//----------------------
begsr rechercheInfosPrets;

  errRechercheInfosPrets = *off;
  clear wCompagnie;
  clear wcodePays;
  clear wprtdrt;

  exec sql
  select prtcie, bqeptx, prtdrt
  into :wCompagnie, :wcodePays, :wprtdrt
  from p1abqepf inner join t4pprtpf on prtban = bqeban
  where prtkro = :wpackro;

  if sqlcode <> 0;
    errRechercheInfosPrets = *on;
    m_error('000419'
           :*omit
           :'errreur recherche infos prêt, '
           +%char(wpackro)
           :'*SQL'
           :'INFO'
           :%char(sqlcode));
  endif;

endsr;

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

// Traitement mise à jour palier
//------------------------------
begsr updatePalier;

  errUpdatePalier = *off;

  exec sql
  update adh1pacpf
  set pacmht = :wmontantHT,
  pacmtx = :wmontantTaxe,
  pacpro = 'A0OAV'
  where f_idpret = :wPackro
  and pacpac = :wpacpac;

  if sqlcode <> 0;
    errUpdatePalier = *on;
    m_error('000484'
            :*omit
            :'Erreur mise à jour palier pour le '
            +'prêt '+ %char(wPackro)
            :'*Sql'
            :'INFO'
            :%char(sqlcode));
  else;
    m_error('000492'
            :*omit
            :'Mise à jour palier OK pour le '
            +'prêt '+ %char(wPackro)
            :'*Sql'
            :'INFO'
            :%char(sqlcode));
  endif;
endsr;

// Traitement fin programme
//-------------------------
begSr trt_finpgm;

  if not werr;
    m_error ('000507'
             :*omit
             :'FIN: Traitement mise à jour ADH1PACPF '
             +%char(wNbTraite) + ' prêts traités'
             :'*Other'
             :'INFO '
             :'00');
  else;
    m_error ('000515'
             :*omit
             :'FIN: Traitement mise à jour ADH1PACPF avec des erreurs '
             +%char(wMajOK) + '/' + %char(wNbTraite)
             +' prêts traités'
             :'*Other'
             :'INFO '
             :'01');

  endif;

  *inLr = *on;

endsr; 
