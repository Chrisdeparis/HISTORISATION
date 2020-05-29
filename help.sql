Bonjour Christian, pour le sous fichier je n'ai pas encore regardé, je réserve un temps ce soir, pour la fin du 
confinement Reynald est en train d'organiser cela avec l'équipe et tu devrais avoir des nouvelles de sa part rapidement.
select * from adh1pacpf order by f_idpret, c_dateeffetpalier
christele souhaite que l'on attende pour traiter oav-2082 (particularité bpce vie), du coup, je souhaite 
réserver oav-2113 (le rattrapage des données)  pour christian, 

select pacggi, prtcie, prtdrt
from adh1pacpf
inner join t4pprtpf on packro=prtkro
inner join t4papepf on prtnum=apenum and prtord=apeord
where pactau is not null;

exec sql
select f_idPays_taxe
into :widPaysTaxe
from p1abqepf
where f_bancode = :w_prtban;

select prtcie, prtban, h43ggi, prtdrt 
from adh1h43pf
inner join p0amadpf on h43kmv=madkmv
inner join t4pprtpf on madkro=prtkro 
where h43tau is null;

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

mazo/qrpgsrc/moubsagde2

select * from t4ptaxpf
where x_ciecode =  1
and f_idpays = 71
and taxgar = 3;

select prtcie, prtdrt 
from  p0amadpf                                                              
inner join t4pprtpf on madkro=prtkro
where madkmv = :wh43kmv;

-- fichier logs erreurs
select * from a1ilogpf where date(logdhe) = '2020-05-27' order by logdhe desc;
select * from bibcommu.a1ilogpf where date(logdhe) = '2020-05-27' order by logdhe desc;

-- données pour compiler le pgm
  clear jobSetIdDs;                                                                                
 jobsetidds.idDomaine = c_OAV;                                                                    
 jobsetidds.idApplication = c_Archivage;                                                          
 rc = m_jobsetid(jobsetidds) ;                                                                    
                                                                                                   
 if rc <> 0;                                                                                      
   errInit = *on;                                                                                  
   m_error('012500'                                                                                
          :*omit                                                                                  
          :'Erreur lors de l''initialisation'                                                      
          :'*Other'                                                                                
          :'INFO'                                                                                  
          :%char(rc));                                                                            
 else;                        
 
 
/copy QCOPSRC,S_JOBENVDS
// Déclaration constantes                                                                          
dcl-c c_Archivage         const(13);                                                                
dcl-c c_OAV               const(4);

h1frptechs/qcopsrc,s_jobenvds

dcl-ds jobSetIdDs            likeDs(m_jobSetIdDs_t);
clear jobSetIdDs;                                                                                
 jobsetidds.idDomaine = c_OAV;                                                                    
 jobsetidds.idApplication = c_Archivage; 
 
update adh1h43pf set c_taux = null where c_taux is not null;

select * from wwannexf/t4ptaxpf
where x_ciecode = 25
and f_idpays = 71
and taxgar = 15
