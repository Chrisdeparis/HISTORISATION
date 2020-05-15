
-- table ADH1H43PF
select * from WWADHESF.ADH1H43PF order by c_dateeffetpalier_avant;

-- table ADH1PACPF
select * from wwadhesf.adh1pacpf order by f_idpret, c_dateeffetpalier;
select *from wwadhesf.adh1pacpf where f_idpret=74668684;

-- la zone a alimenter est la colonne C_TAUX dans la table ADH1PACPF

-- La table des mouvements adhésion :  WWADHESF.P0AMADPF
                    
-- contient F_idpret, C_DateCreation    
select * from WWADHESF.P0AMADPF; --la table des mou

-- jointure des deux tables par rapport à la date effet palier
SELECT *
FROM wwadhesf.adh1pacpf
LEFT JOIN WWADHESF.ADH1H43PF ON wwadhesf.adh1pacpf.c_dateeffetpalier = WWADHESF.ADH1H43PF.c_dateeffetpalier_avant
order by f_idpret, c_dateeffetpalier;

-- DATE DE REFERENCE TARIFAIRE
select prtdrt from WWADHESF.t4pprtpf;


-- La colonne garantie  
select pacggi from  wwadhesf.adh1pacpf order by f_idpret, c_dateeffetpalier;
-- table P_IDGARGARANTIEINCLUSE                     
select * from WWANNEXF.pa1xggipf;


-- Les infos prets
 SELECT * from WWADHESF.t4pprtpf 
 
 --PRTBAN = f_BANCODE zoned(5:0)
