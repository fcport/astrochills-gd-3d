## Ciò che la fase del fuoco passa alla propria sorgente di verità.
##
## È un RefCounted e non una Resource, per la stessa ragione di `PolarInput`: non
## va salvato, non va condiviso, e vive quanto un fotogramma.
class_name FocusInput
extends RefCounted

## Dov'è il focheggiatore, in PASSI del motore.
##
## È l'unico ingresso che conta, ed è tutta la fase: la dimensione delle stelle è
## una funzione di questo numero e di nient'altro. Zero è il centro della corsa
## meccanica, non il fuoco — dove sia il fuoco lo sa la sorgente, e il giocatore
## lo scopre guardando.
var position: float = 0.0

## Da quanti secondi il focheggiatore è fermo.
##
## Nessuna sorgente dell'MVP lo usa: la curva a V onesta dipende solo dalla
## posizione. Sta qui perché è la porta di due bugie che il GDD ha già scritto —
## «le stelle non vanno mai a fuoco del tutto» e «ci vanno, ma la forma non è
## quella di una stella» — e la prima ha bisogno esattamente di questo: qualcosa
## che peggiori mentre stai fermo a guardare.
var seconds_since_move: float = 0.0
