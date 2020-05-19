      *%CSTD===========================================================*
      ** Application. : BSA        World - Base Adherent               *
      ** Composant. . : MOUBSAGDE2                    Type: SQLRPGLE   *
      **===============================================================*
      ** Sous-système :                                                *
      ** Fonction . . :                                                *
      ** Sous-fonction:                                                *
      **%S=============================================================*
      ** Description des fonctionnalités:                              *
      **                                                               *
      **                                                               *
      **                                                               *
      **%E=============================================================*
      ** AUTEUR:    MAZO       17/03/2015 12:38  V150317C              *
      ** MODIFS: ** MAZO       17/03/2015   :    V150317C    00/       *
      *%ECSTD==========================================================*
      //-------------------------------------------------------------------------
      //  RESUME PROGRAMME
      //  ----------------
      //  moulinette qui permet :
      //  - de mettre à jour : gdecdc, gdedec, gdecn1, gdecn2, gdecn3
      //    si écart entre sr et bsa
      //
      //  à lancer en 3 étapes:
      //  - etape 1 : cielst = 1 / cieano = 0 / cieupd = 0
      //     -> listeAdherents de this compagnie origine sr présents dans p0egdepf
      //  - etape 2 : cielst = 0 / cieano = 1 / cieupd = 0
      //  - etape 3 : cielst = 0 / cieano = 0 / cieupd = 1
      //
      //  Auteur : N Mazo   Date : 09/03/2015
      //
      //-------------------------------------------------------------------------
     H dftactgrp(*no) actgrp(*new) bnddir('OUTILS')

      /copy h1frptechs/qcopsrc,s_errords

      // Définition des DS
      // -----------------
     d padh          e ds                  extname(t4padhpf)
     d mdec          e ds                  extname(p0mdecpf)
     d egde          e ds                  extname(p0egdepf)
     d mexc          e ds                  extname(p0mexcpf)

      // prototype
     d Main            pr                  extpgm('MOUBSAGDE2')
     d  in_parm1                      6
     d  in_parm2                      4
     d  in_parm3                      8
     d Main            pi
     d option                         6
     d compagnie                      4
     d quantite                       8

      // Définition des constantes

      // Indicateur Valeur nulle
     d c_indnull       C                   const(-1)
      // type entrée dans le programme
     d c_lst           c                   '*lst  '
     d c_ano           c                   '*ano  '
     d c_upd           c                   '*upd  '

      // Définition des variables de travail
     d wnumDemSR       s             11  0
     d wnumObaSR       s             11  0
     d wkronoAdh       s             11  0

     d wadhkro         s                   like(adhkro)

     d wgdegar         s                   like(gdegar)
     d wgdedec         s                   like(gdedec)
     d wgdecdc         s                   like(gdecdc)
     d wgdecn1         s                   like(gdecn1)
     d wgdecn2         s                   like(gdecn2)
     d wgdecn3         s                   like(gdecn3)

     d wdecdec         s                   like(decdec)
     d wdecgar         s                   like(decgar)
     d wdecdat         s                   like(decdat)
     d wdectdp         s                   like(dectdp)

     d wexcord         s                   like(excord)
     d wexccod         s                   like(exccod)

     d wErrParm        s               n
     d wErrSqlMaj      s               n
     d wErrMajListeAdherent...
     d                 s               n
     d wErrcorrectionAnos...
     d                 s               n
     d wErrMajDecision...
     d                 s               n
     d wErrRechAno     s               n
     d obFound         s               n
     d oneDecSRFound   s               n
     d oneDecGDEFound  s               n

     d wsqlCod_cursAdherent...
     d                 s                   like(sqlcode)
     d wsqlCod_cursDecGarADH...
     d                 s                   like(sqlcode)
     d wsqlCod_cursExcDecSR...
     d                 s                   like(sqlcode)
     d wsqlCod_cursAdherentAnos...
     d                 s                   like(sqlcode)
     d wsqlCod_SR      s                   like(sqlcode)

     d wmajDecision    s              1n
     d wcount          s              2s 0
     d wcompagnienum   s              3s 0
     d wquantitenum    s              8s 0
     d wdecisionGde    s              3s 0
     d wparm           s              9
     d wDecGarAdherent...
     d                 s              1s 0
     d wnatureDecision...
     d                 s              1a
     d uneDecisionAMettreAJour...
     d                 s              1n
     d uneDecisionSRRenseignee...
     d                 s              1n

     d wdecdatn        s              8s 0

     d wgaranties      s             20a
     d wdecisionsSR    s             20a
     d wdecisionsGDE   s             20a

     d wCountLu        s              8s 0

      /free

        // constitution laeref :
        //
        //  Cas 1 :
        //   pos 1  à 11 = num demande sr
        //   pos 13 à 23 = num OB      sr
        //   pos 25 à... = blanc
        //  -> l'Ob correspond à la demande SR = OK
        //
        //  Cas 2 :
        //   pos 1  à 11 = num demande sr
        //   pos 13 à 23 = num OB 1    sr
        //   pos 25 à 35 = num OB 2    sr
        //  -> l'Ob 1 ne correspond pas à la demande SR = KO
        //  -> l'Ob 2    correspond     à la demande SR = ??
        //
        // ex en R2 : SELECT * FROM p0elaepf WHERE substr(laeref, 5, 7) = '2642739'
        // cie laeref                              kro adh
        // 2   00002642739 00003001366             5736157 -> OK ob 3001366 liée à 2642739
        // 2   00002642739 00003606253 00003001366 5737703 -> KO ob 3606253 liée à 3240943 ??
        //
        // --> Donc est exclu l'adherent (ex: 5737703) dont pos 24 long 2 = ' 0'  <--

        // Curseur des adherents origine SR par compagnie
        exec sql
        declare  cursAdherent cursor for
        select    kronoADh,
                  numDemSR,
                  numObaSR
        from      qgpl/adhgde2
        where     rechercheAno is null;

        // Curseur des adherents origine SR par compagnie avec Anos
        exec sql
        declare  cursAdherentAnos cursor for
        select    kronoADh,
                  numDemSR,
                  numObaSR
        from      qgpl/adhgde2
        where     garantie is not null
          and     compagnie = :wcompagnieNum
          and     rechercheAno = 'O'
          and     correctionAno is null;

        // lecture des derniere décision par garantie en Adherent pour une OB
        exec sql
        declare cursDecGarADH cursor for
        select  gdegar,
                gdedec,
                ifnull(gdecdc, 0)
         from  p0egdepf inner join egdeDerDec on gdekrh=derkroDec
         where derkroAdh = :wadhKro;

        // lecture des exclusions par décisions/garantie
        exec sql
        declare cursExcDecSR cursor for
        select  excord,
                exccod
        from  p0mexcpf
        where excdec = :wdecdec
          and excgar = :wdecgar
          and excoba = :wnumObaSr
        order by excgar, excord;


        //---------- DEBUT DE PROGRAMME ---------------------------------------

        exsr controlParm;

        if not wErrParm; // pas erreur parm

          select;
            when option = c_lst;
              exsr listeAdherents;

            when option = c_ano;
              exsr listeAnos;

            when option = c_upd;
              exsr correctionAnos;
              if not wErrcorrectionAnos;
                dsply ('pas erreur  -> maj p0egdepf validées');
                // sauvegarde adherents modifiés
                exsr saveModif;
                exec sql commit;
              else;
                dsply ('erreurs     -> maj annulées');
                exec sql rollback;
              endif;

          endsl;

        else; // erreur parametre option invalide
          m_error('001227'
                 :*omit
                 :'parametre '
                 + %trim(wparm)
                 + ' invalide'
                 :'*Other'
                 :'WARN'
                 :' '
                  );
        endif;

        *inlr = *on;

        //----------   FIN PROGRAMME ------------------------------------------


        //--------------------------------------------------------------------
        begsr saveModif;

          // ajout dans le fichier de sauvegarde des adhérents modifiés
          // car le fichier egdederdec est rab à chaque lancement
          exec sql
          insert into qgpl/adhgde2sav
             (
              select *
              from  qgpl/adhgde2
              where dateModif is not null
              );

        endsr;

        //--------------------------------------------------------------------
        begsr listeAnos;

          exec sql open cursAdherent;

          wsqlCod_cursAdherent = sqlCode;

          if wsqlCod_cursAdherent = 0; // pas erreur open cursor

            // lecture des adhérents
            exec sql
            fetch next from cursAdherent
            into :wadhKro,
                 :wnumDemSR,
                 :wnumObaSR;

            wsqlCod_cursAdherent = sqlCode;

            // curseur adherent :tant que pas d'erreur
            dow wsqlCod_cursAdherent = 0 and wCountLu < wquantiteNum;

              wgaranties    = *blank;
              wdecisionsSR  = *blank;
              wdecisionsGDE = *blank;
              wmajDecision  = *off;
              oneDecGDEFound = *off;
              oneDecSRFound  = *off;

              wCountLu += 1;

              exsr rechercheAnos;

              // lecture des adhérents
              exec sql
              fetch next from cursAdherent
              into :wadhKro,
                   :wnumDemSR,
                   :wnumObaSR;

              wsqlCod_cursAdherent = sqlCode;

            enddo; // fin boucle curseur adherent

            // fermeture curseur
            exec sql close cursAdherent;

          else; // erreur open curseur adhérent
            m_error('001329'
                   :*omit
                   :'erreur open curseur cursAdherent'
                   :'*Other'
                   :'WARN'
                   :%char(wsqlCod_cursAdherent)
                   );
          endif;

        endsr;

        //---------------------------------------------------------------------
        begsr rechercheAnos;

              werrRechAno = *off;

              // lecture des garanties pour cet adhérent
              exec sql open cursDecGarADH;

              wsqlCod_cursDecGarADH = sqlCode;

              if wsqlCod_cursDecGarADH = 0; // pas erreur open cursor

                // lecture des garanties de p0egdepf
                exec sql
                fetch next from cursDecGarADH
                into :wgdegar,
                     :wgdedec,
                     :wgdecdc;

                wsqlCod_cursDecGarADH = sqlCode;

                // curseur decision garantie : tant que pas d'erreur
                dow wsqlCod_cursDecGarADH = 0;

                  oneDecGDEFound = *on;
                  // recherche de la derniére décison renseignée en Sr pour cette Ob/garantie
                  exec sql
                  select decdec,
                         ifnull(decdat, '0001-01-01'),
                         ifnull(dectdp, 0)
                  into  :wdecdec,
                        :wdecdat,
                        :wdectdp
                  from sri1ddopf
                  inner join p0mdecpf on ddodec = decdec
                                     and ddooba = decoba
                  where  decoba = :wnumObaSR
                    and  decgar = :wgdegar;

                  wsqlCod_SR = sqlcode;

                  if wsqlCod_SR = 0; // decision trouvée en sr pour cette OB/garantie

                    obFound    = *on;
                    oneDecSRFound = *on;

                    if wgdecdc <> wdectdp; // decision bsa différente décison sr
                      select;
                        when option = c_ano;
                          wgaranties    = %trim(wgaranties)
                                      + %trim(%char(wgdegar)) +  '/';
                          wdecisionsSR  = %trim(wdecisionsSR)
                                      + %trim(%char(wdectdp)) + '/';
                          wdecisionsGDE = %trim(wdecisionsGDE)
                                      + %trim(%char(wgdecdc)) + '/';
                        when option = c_upd;
                          exsr majDecision;
                      endsl;

                    else; // égalité décision sr/bsa = ne rien faire

                    endif;

                  else; // décision non trouvée en SR pour cette OB/garantie

                    if wsqlCod_SR = 100;

                      obFound = *off;

                      select;
                        when option = c_ano;
                          wgaranties    = %trim(wgaranties)
                                      + %trim(%char(wgdegar)) +  '/';
                          wdecisionsSR  = %trim(wdecisionsSR)
                                      + '-' + '/';
                          wdecisionsGDE = %trim(wdecisionsGDE)
                                       + %trim(%char(wgdecdc)) + '/';
                        when option = c_upd;
                          if wgdecdc <> 0;
                            wdecdat = d'0001-01-10';
                            wdectdp = 0;
                            exsr majDecision;
                          endif;
                      endsl;
                    else;
                      //werrRechAno = *on;
                    endif;

                    m_error('001401'
                           :*omit
                           :'décision non trouvée pour OB '
                            + %char(wnumObaSR)
                            + ' garantie ' + %char(wgdegar)
                           :'*Other'
                           :'WARN'
                           :%char(wsqlCod_SR)
                           );
                  endif; // fin décision non trouvée

                  exec sql
                  fetch next from cursDecGarADH
                  into :wgdegar,
                       :wgdedec,
                       :wgdecdc;

                  wsqlCod_cursDecGarADH = sqlCode;

                enddo; // fin boucle curseur decision garantie pour cet adhérent

                exsr majListeADherent;

                // fermeture curseur
                exec sql close cursDecGarADH;


              else; // erreur open curseur cursDecGarADH
                m_error('001325'
                       :*omit
                       :'erreur open curseur cursDecGarADH'
                       :'*Other'
                       :'WARN'
                       :%char(wsqlCod_cursDecGarADH)
                       );
              endif; // fin erreur open curseur cursDecGarADH
       endsr;

       //-----------------------------------------------------------------------
       begsr affich;
         m_error('001443'
                :*omit
                :' on est à '
                 + %char(wCountLu)
                :'*Other'
                :'INFO'
                :' '
                );
       endsr;

       //----------------------------------------------------------------------
       begsr exclusions;

         wgdecn1 =  0;
         wgdecn2 =  0;
         wgdecn3 =  0;

         exec sql open cursExcDecSR;

         wsqlCod_cursExcDecSR = sqlCode;

         if wsqlCod_cursExcDecSR = 0; // pas erreur open cursor

           // lecture des exclusions
           exec sql
           fetch next from cursExcDecSR
           into :wexcord,
                :wexccod;

           wsqlCod_cursExcDecSR = sqlCode;

           dow wsqlCod_cursExcDecSR = 0; // tant que pas d'erreur

             // contrôle parametre -> option
             select;
               when wexcord = 1;
                 wgdecn1 = wexccod;
               when wexcord = 2;
                 wgdecn2 = wexccod;
               when wexcord = 3;
                 wgdecn3 = wexccod;
               other;
                 // c'est bizarre...
             endsl;

             // lecture des exclusions
             exec sql
             fetch next from cursExcDecSR
             into :wexcord,
                  :wexccod;

             wsqlCod_cursExcDecSR = sqlCode;
           enddo;

           exec sql close cursExcDecSR;

         else; // erreur open curseur
           m_error('001500'
                   :*omit
                   :'erreur open curseur cursExcDecSR'
                   :'*Other'
                   :'WARN'
                   :%char( wsqlCod_cursExcDecSR)
                   );
         endif;
       endsr;

       //--------------------------------------------------------
       // Traitement generation liste des adhérents à traiter

       begsr listeAdherents;

           wCount = 0;

           // recherche si table existe
           exec sql
           select count(*) into :wCount
           from  systables
           where table_schema = 'QGPL'
             and table_name   = 'ADHGDE2';

           if wCount = 0; // si table pas créée alors création
             exec sql
             create table qgpl/adhgde2
             (compagnie     numeric(03, 0) not null,
              kronoAdh      numeric(11, 0) not null,
              numDemSR      numeric(11, 0),
              numObaSR      numeric(11, 0),
              garantie      character(20),
              decisionSR    character(20),
              decisionGDE   character(20),
              rechercheAno  character(1),
              correctionAno character(1),
              dateModif     timestamp);
           else; // si table déjà créée alors suppression lignes
             exec sql
             delete from qgpl/adhgde2 with nc;
           endif;

           // alimentation pour cette compagnie
           exec sql
           insert into qgpl/adhgde2
             (compagnie,
              kronoAdh,
              numDemSR,
              numObaSR)
              (select adhcie,
                      adhkro,
                      dec(substr(laeref, 01, 11), 11, 0),
                      dec(substr(laeref, 13, 11), 11, 0)
               from   t4padhpf
               inner join p0elaepf on adhkro=laekro
               where adhcie = :wcompagnienum
                 and adhcor = 4
                 and exists
                 (select * from p0egdepf where gdekro=adhkro))
               ;

           // EGDEDERDEC
           wCount = 0;

           exec sql
           select count(*) into :wCount
           from  systables
           where table_schema = 'QGPL'
             and table_name   = 'EGDEDERDEC';

           if wCount = 0; // si pas créée alors création

             exec sql
             create table qgpl/egdeDerDec
             (derkroAdh   numeric(11, 0) not null,
              derkroDec   numeric(11, 0) not null);

           else; // si créée suppression lignes de la cie
             exec sql
             delete from qgpl/egdeDerDec with nc;
           endif;

           // alimentation par rapport à adhgde2
           exec sql
           insert into qgpl/egdederdec
             (derkroAdh, derkroDec)
             (
              select gdekro, max(gdekrh)
              from   p0egdepf
              where  gdekro in (select kronoadh from qgpl/adhgde2)
              group by gdekro
                 );

           // adhgde2SAV
           wCount = 0;

           exec sql
           select count(*) into :wCount
           from  systables
           where table_schema = 'QGPL'
             and table_name   = 'ADHGDE2SAV';

           if wCount = 0; // si pas créée alors création

             exec sql
             create table qgpl/ADHGDE2SAV
             (compagnie     numeric(03, 0) not null,
              kronoAdh      numeric(11, 0) not null,
              numDemSR      numeric(11, 0),
              numObaSR      numeric(11, 0),
              garantie      character(20),
              decisionSR    character(20),
              decisionGDE   character(20),
              rechercheAno  character(1),
              correctionAno character(1),
              dateModif     timestamp);

           endif;

       endsr;

       //-------------------------------------------
       begsr controlParm;

         wErrParm =*off;

         // contrôle parametre -> option
         select;

           when option = c_lst; // generation liste adhérent par cie dans adhgde2
             wErrParm = *off;

           when option = c_ano; // recherche ano
             wErrParm = *off;
             // controle parametre quantite obligatoire
             if quantite <> *blank;
               // test si quantite est numérique
               monitor;
                 wquantiteNum = %dec(quantite:8:0);
               on-error;    // ko
                 wErrParm = *on;
                 wparm    = 'quantite';
               endmon;
             else;
               wErrParm = *on;
               wparm    = 'quantite';
             endif;

           when option = c_upd; // maj
             wErrParm = *off;

           other;  // optin diff de *lst, *ano, *upd
             wparm = 'option';
             wErrParm = *on;

         endsl;

         if wErrParm = *off; // pas d'erreur parametre option

           // contrôle parametre -> compagnie
           if compagnie <>  ' ';  // ok

             // test si compagnie est numérique
             monitor;
               wcompagnienum = %dec(compagnie:3:0);
             on-error;    // ko
               wErrParm = *on;
               wparm    = 'compagnie';
             endmon;

             if not wErrParm; // valeur du parametre compagnie numerique
               wcount = 0;

               exec sql
               select count(*) into :wCount
               from t4pciepf
               where ciecie = :wcompagnienum
                 and cieban = 0;

               if sqlcode = 0;
                 if wCount = 1;
                   // OK parm compagnie
                 else;
                   wErrParm = *on;
                   wparm = 'compagnie';
                 endif;
               else; // compagnie non trouvée
                 wErrParm = *on;
                 wparm = 'compagnie';
               endif;
             else; // valeur parametre cie non numérique
             endif;
           else; // parametre compagnie non renseigné
             wErrParm = *on;
             wparm = 'compagnie';
           endif;
         else; // erreur parametre option
         endif;


       endsr;

       //----------------------------------------------------------------------
       begsr majDecision;

           wErrMajDecision = *off;
           wmajDecision    = *on;

           wdecdatn = 0;
           if wdecdat <> d'0001-01-01';
             wdecdatn = %dec(wdecdat:*iso);
           else;
           endif;

           // boucle de chargement des exclusions de l'ob en sr
           if obFound;
             exsr exclusions;
           endif;

           // maj fichier p0egcdepf : gdecdc, gdedec, gdecn1, gdecn2,  gdecn3
           exec sql
           update  p0egdepf
              set  gdedec = :wdecdatn,
                   gdecdc = :wdectdp,
                   gdecn1 = :wgdecn1,
                   gdecn2 = :wgdecn2,
                   gdecn3 = :wgdecn3
           where gdekro = :wadhkro
             and gdegar = :wgdegar
           with cs;

           if sqlcod <> 0;
             wErrMajDecision = *on;
             wmajDecision    = *off;
             m_error('001738'
                    :*omit
                    :'erreur maj p0egdepf, adhérent ' + %char(wadhkro)
                     + ' garantie ' + %char(wgdegar)
                    :'*Sql'
                    :'WARN'
                    :%char(sqlcod)
                    );
           endif;
       endsr;

       //----------------------------------------------------------------------
       begsr correctionAnos;

         wErrCorrectionAnos = *off;

         exec sql open cursAdherentAnos;

         wsqlCod_cursAdherentAnos = sqlCode;

         if wsqlCod_cursAdherentAnos = 0; // pas erreur open cursor

           // lecture des adhérents
           exec sql
           fetch next from cursAdherentAnos
           into :wadhKro,
                :wnumDemSR,
                :wnumObaSR;

           wsqlCod_cursAdherentAnos = sqlCode;


           // curseur adherent :tant que pas d'erreur
           dow wsqlCod_cursAdherentAnos = 0;

           exsr rechercheAnos;

             // lecture des adhérents
             exec sql
             fetch next from cursAdherentAnos
             into :wadhKro,
                :wnumDemSR,
                :wnumObaSR;

             wsqlCod_cursAdherentAnos = sqlCode;
           enddo;

           exec sql close cursAdherentAnos;

         else; // erreur open curseur
           m_error('001808'
                  :*omit
                  :'erreur open curseur cursAdherentAnos'
                  :'*Other'
                  :'WARN'
                  :%char(wsqlCod_cursAdherentAnos)
                  );
         endif;

       endsr;

       //----------------------------------------------------------------------
       begsr majListeAdherent;

         wErrMajListeAdherent = *off;

         if oneDecGDEFound;
           if oneDecSRFound;
             select;
               when option = c_ano;
                 if wgaranties <> *blank; // si au moins une garantie modifiée
                   exec sql
                   update qgpl/adhgde2
                   set   garantie     = :wgaranties,
                         decisionSR   = :wdecisionsSR,
                         decisionGDE  = :wdecisionsGDE,
                         rechercheAno = 'O'
                   where  kronoAdh = :wadhkro
                   with nc;
                 else; // si aucune garantie modifiée
                   exec sql
                   update qgpl/adhgde2
                   set    rechercheAno = 'O',
                          correctionAno = 'N'
                   where  kronoAdh = :wadhkro
                   with nc;
                 endif;
               when option = c_upd; // option maj avec des corrections
                 if wmajDecision; // si correction
                   exec sql
                   update qgpl/adhgde2
                   set    correctionAno = 'O',
                          dateModif     = current timestamp
                   where  kronoAdh = :wadhkro
                   with nc;
                 endif;
             endsl;
           else; // aucune decision trouvée pour cette Ob en SR
             exec sql
             update qgpl/adhgde2
             set    decisionSR = 'not found',
                    rechercheAno = 'N'
             where  kronoAdh = :wadhkro
             with nc;
           endif;
         else; // aucune decision trouvée pour cette Ob en BSA
           exec sql
           update qgpl/adhgde2
           set    decisionGDE = 'not found',
                  rechercheAno = 'N'
           where  kronoAdh = :wadhkro
           with nc;
         endif;

         if sqlcod <> 0;
           wErrMajListeAdherent = *on;
           m_error('001842'
                  :*omit
                  :'erreur pendant maj adhgde2, adhérent '
                   + %char(wadhkro)
                  :'*Sql'
                  :'INFO'
                  :%char(sqlcod)
                  );
         endif;
       endsr;

      /end-free 
