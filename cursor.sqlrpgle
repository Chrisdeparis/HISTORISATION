       // curseur de lecture
       exec sql
       declare CURS_01 cursor for
       select corkro, cornum, corord, cordat,
              prtkro, prtres, prtmot
       from t4pcorpf
       exception join adh1csupf on corkro = csukro
       inner join t4pprtpf on cornum = prtnum
                          and corord = prtord
       where cornat = 250
         and cordte = '0001-01-01'
         and cordat = :pcordat
       order by cornum, corord
       for fetch only;

         // ouverture curseur
         exec sql open CURS_01;
         wsqlcodCurseur = sqlcode;

         if wsqlcodCurseur = *zero; // pas erreur open curseur

           clear wcorkro;
           clear wcornum;
           clear wcorord;
           clear wcordat;
           clear wprtkro;
           clear wprtres;
           clear wprtmot;
           wnbLecture = 0;

           // lecture curseur
           exec sql
           fetch next from CURS_01
           into :wcorkro, :wcornum, :wcorord, :wcordat,
                :wprtkro, :wprtres, :wprtmot;

           wsqlcodCurseur = sqlcode;

           dow wsqlcodCurseur <> 100; // tant que pas fin de curseur

             wnbLecture += 1;

             // coder ci dessous le traitement
             dsply ('num oav : ' + %char(wcornum));

             // lecture curseur
             exec sql
             fetch next from CURS_01
             into :wcorkro, :wcornum, :wcorord, :wcordat,
                  :wprtkro, :wprtres, :wprtmot;

             wsqlcodCurseur = sqlcode;

           enddo;

           select;
            when wsqlcodCurseur = 0;
            when wsqlcodCurseur = 100;
             // sortie de boucle normale
            other;
              // erreur : sortie de boucle anormale
              m_error ('000190'
                      :*omit
                      :'erreur fetch'
                        // ajouter les données de contexte (numéro oav...)
                      :'*Sql'
                      :'INFO'
                      :' '
                      );
           endsl;

           exec sql close CURS_01;

         else; // erreur open curseur
           m_error ('000203'
                   :*omit
                   :'erreur open curseur CURS_01'
                   :'*Sql'
                   :'INFO'
                   :' '
                   );
         endif;

     *inlr = *on;
 
// Cursor avec Update

EXEC SQL
        declare CURS_01 cursor for
        select corkroTmp,
               cornumTmp, corordTmp,
               cornatTmp,
               corkrgTmp,
               apedemTmp
        from pcorTmp
        order by cornatTmp, apedemTmp, corkroTmp
        for update with nc;
EXEC SQL
         update pcorTmp
         set corkrgTmp = :corkroTmp
         where current of CURS_01;
