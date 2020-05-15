**free
ctl-opt option(*nodebugio:*srcstmt) dftactgrp(*no) ;

Dcl-DS wds qualified dim(10);
  F_IDPRET zoned(11:0);
  F_IDGARGARANTIEINCLUSE  zoned(5:0);
  C_TAUX zoned(5:3);
End-DS;

//dcl-ds adh1pacpf extname('adh1pacpf');
//end-ds;

dcl-s NbrOfRows int(5) inz(%elem(wds));
dcl-s i int(5);
dcl-s RowsFetched int(5) ;

dcl-s w_message char(50);
dcl-s Offset int(10) ;

//variables de travail
dcl-s wF_IDPRET char(11);
dcl-s wF_IDGARGARANTIEINCLUSE char(5);
dcl-s wC_TAUX char(5);
//dcl-s wdate char(10);//(YYYY-MM-DD)
dcl-s wprtcie char(3);
dcl-s wprtban char(5);
dcl-s wh43ggi char(5);
dcl-s wprtdrt date;
dcl-s wnbLecture int(5);
dcl-s wsqlcodCurseur int(5);
*inlr = *on;

monitor;

  dow (i<=10);

    RechercheData();
    Offset += %elem(wds) ;     //10

    // Boucle des 10 enregistrements
    for i=1 to %elem(wds);

      wF_IDPRET = %char(wds(i).F_IDPRET);
      wF_IDGARGARANTIEINCLUSE  =  %char(wds(i).F_IDGARGARANTIEINCLUSE);
      wC_TAUX =  %char(wds(i).C_TAUX);


      w_message = 'idpret: '
                  + %trim( wF_IDPRET)
                  + ' pacggi: '
                  + %trim( wF_IDGARGARANTIEINCLUSE)
                  + ' pactau: '
                  + %trim( wC_TAUX)
                  + '.';

      dsply (%trim(w_message));

    endfor;

    if (RowsFetched = %elem(wds)) ;
      leave ;
    endif ;
  enddo ;

on-error *all;

endmon;

// Recherche Data
dcl-proc RechercheData ;
  dcl-s NbrOfRows int(5) inz(%elem(wds)) ;

  RowsFetched = 0 ;
  clear wDs ;

         // curseur de lecture
       exec sql
       declare curs_01 cursor for
       select prtcie, prtban, h43ggi, prtdrt from wwadhesf.adh1h43pf
       inner join wwadhesf.p0amadpf on h43kmv=madkmv
       inner join wwadhesf.t4pprtpf on madkro=prtkro where h43tau is null
       //where cornat = 250
         //and cordte = '0001-01-01'
         //and cordat = :pcordat
       //order by cornum, corord
       for fetch only;

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
                  + ' C_DATEREFERENCETARIFAIRE: '
                  + %trim( wprtdrt)
                  + '.';

             dsply (%trim(w_message));

             // lecture curseur
             exec sql
             fetch next from curs_01
             into :wprtcie, :wprtban, :wh43ggi, :wprtdrt;


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




end-proc;









 
