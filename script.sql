
-- table ADH1H43PF
select * 
from WWADHESF.ADH1H43PF 
order by c_dateeffetpalier_avant;

-- table ADH1PACPF palier cotisation
select * 
from wwadhesf.adh1pacpf 
order by f_idpret, c_dateeffetpalier;


-- la zone a alimenter est la colonne C_TAUX dans la table ADH1PACPF
-- Table echeancier
select * 
from WWADHESF.P1ACRDPF;

-- La table des mouvements adhésion :  WWADHESF.P0AMADPF
                    
-- contient F_idpret, C_DateCreation    
select * 
from WWADHESF.P0AMADPF; --la table des mou

-- jointure des deux tables par rapport à la clé packro (F_IDPRET) = H43KMV(X_IDHISTOMOUVEMENT)
SELECT F_IDPRET, pactau, X_IDHISTOMOUVEMENT    
FROM wwadhesf.adh1pacpf
left JOIN WWADHESF.ADH1H43PF
ON wwadhesf.adh1pacpf.F_IDPRET = WWADHESF.ADH1H43PF.X_IDHISTOMOUVEMENT;


-- DATE DE REFERENCE TARIFAIRE
select * 
from WWADHESF.t4pprtpf;


-- La colonne garantie  
select pacggi from  
wwadhesf.adh1pacpf 
order by f_idpret, c_dateeffetpalier;
-- table P_IDGARGARANTIEINCLUSE                     
select * 
from WWANNEXF.pa1xggipf;


-- Les infos prets
 SELECT * 
 from t4pprtpf; 
 
 --PRTBAN = f_BANCODE zoned(5:0)
 -- pacggi = F_IDGARGARANTIEINCLUSE; 
 -- prtcie = F_CIECODE; 
 -- prtdrt = C_DATEREFERENCETARIFAIRE,
 -- pactau = C_TAUX
select pacggi, prtcie, prtdrt 
from WWADHESF.adh1pacpf 
inner join WWADHESF.t4pprtpf on packro=prtkro
inner join WWADHESF.t4papepf on prtnum=apenum and prtord=apeord
where pactau is not null;

-- recupérer le pays
         select f_idPays_taxe
          into :widPaysTaxe
         from   p1abqepf
         where  f_bancode = :w_prtban;
         
         --adh00006
         
-- banque retrouver         

-- MADKMV     CONDEN      11  0 = P_IDHISTOMOUVEMENT
-- H43KMV     CONDEN      11  0 = X_IDHISTOMOUVEMENT
-- H43GGI     CONDEN       5  0 = F_IDGARGARANTIEINCLUSE 
-- PRTBAN     CONDEN       5  0 = F_BANCODE
-- PRTCIE     CONDEN       3  0 = F_CIECODE
-- PRTDRT     DATE           10 = C_DATEREFERENCETARIFAIRE
select prtcie, prtban, h43ggi, prtdrt 
from WWADHESF.adh1h43pf
inner join WWADHESF.p0amadpf on h43kmv=madkmv
inner join WWADHESF.t4pprtpf on madkro=prtkro where h43tau is null;


