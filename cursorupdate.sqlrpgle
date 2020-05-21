**free

        dcl-s lId            Char(10);
        dcl-s lName          Char(20);
        
       
        //Cursor with update


        //Declare cursor
         exec sql
          declare customer cursor for
          select CustId, CustName
          from Case3PF
          for update of Custage;
          // For update;

          //open cursor
          exec sql
           open customer;

          //fetch first cursor
          exec sql
          fetch cursor into :lId, :lName;

          dow sqlcode = 0;
       

            exec sql
            update Case3PF
            set Custage = 99
            where current of customer;

            //fetch next cursor
            exec sql
            fetch customer into :lId, :lName;

           enddo;

            //close cursor
            exec sql
            close customer;

               *inlr=*on;
