# HISTORISATION

Je souhaite historiser les modifications de taux de taxe en ajoutant la valeur du taux par garantie sur chaque palier de cotisation
Afin de conserver une trace

Definir le périmetre du pgm : F_IDPRET représente un dossier.


## Le montant palier : 

le palier c'est le détail des cotisations par garantie qu'on prélève aux assurés : 
- dans ce palier tu as le montant TTC
- le montant HT
- le montant de taxe
- et maintenant on doit rajouter le taux => C_TAUX dans ADH1PACPF :ok_hand::ok_hand:

## Recherche Taux Taxe

```sql
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
```
A changer car la demande est différente : 

> lecture palier
> si **palier** concerne une oav crée **avant 01/01/2019**

> **taux dc = 0** / taux **autre garantie = 9**

> sinon (oav crée **à partir 01/01/2019)**

> **taux dc = 9** / taux **autre garantie = 9**

> fin Si  

## La date de référence tarifaire

```
select prtdrt from WWADHESF.t4pprtpf;
```
Information qui vient du métier Oui, la date pivot est bien la date de référence tarifaire (date qui est présente dans nos BDD puisqu'elle apparaît sur l'OAV).

## Le taux Décès

c'est la garantie 3 : pacggi : C'est aussi une règle métier.

```sql
-- La colonne garantie
select pacggi from  wwadhesf.adh1pacpf order by f_idpret, c_dateeffetpalier;
-- table P_IDGARGARANTIEINCLUSE                     
select * from WWANNEXF.pa1xggipf;
```

## Les prêts
t4pprtpf

## ADH1PACPF

| ------------------------------|-------------------------------|
| PACPAC     CONDEN      11  0  |  =>   P_IDPALIERCOTISATION    |
| ------------------------------|-------------------------------|
| PACMPA     CONDEN      11  2  |  =>   C_MONTANTPALIER         |
| ------------------------------|-------------------------------|
| PACDEP     DATE           10  |   =>   C_DATEEFFETPALIER      |
| ------------------------------|-------------------------------|
| PACDMO     HORODAT     26  6  |  =>   C_DATEMODIFICATION      |
| ------------------------------|-------------------------------|
| PACKRO     CONDEN      11  0  |  =>   F_IDPRET                |
| ------------------------------|-------------------------------| 
| PACGGI     CONDEN       5  0  |  =>   F_IDGARGARANTIEINCLUSE  |
| ------------------------------|-------------------------------|
| PACTAU     CONDEN       5  3  |  =>   C_TAUX                  |
| ------------------------------|-------------------------------|
| PACMTX     CONDEN      11  2  |  =>   C_MONTANTTAXE           |
| ------------------------------|-------------------------------|
| PACMHT     CONDEN      11  2  |  =>   C_MONTANTHT             |
| ------------------------------|-------------------------------|
| PACPRO     ALPHA          10  |  =>   F_PROFIL                |
| ------------------------------|-------------------------------|

