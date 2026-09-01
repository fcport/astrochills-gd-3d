## Ciò che la fase dell'accensione passa alla propria sorgente di verità.
##
## È un RefCounted e non una Resource, per la ragione di `PolarInput`: non va
## salvato, non va condiviso, e vive quanto un fotogramma.
##
## TUTTO QUI DENTRO È COMANDO, mai osservazione: che cosa il giocatore ha acceso e
## a che cosa ha chiesto di collegarsi. Se ognuna di quelle cose RISPONDA lo dice
## la sorgente, ed è l'unica cosa che si vede sullo schermo.
class_name StartupInput
extends RefCounted

## Quali apparecchi hanno l'interruttore su ON, un bit per apparecchio.
##
## Non tutti ce l'hanno: la ruota portafiltri prende corrente dalla camera, e il
## suo bit qui non si accende mai. Che questo la renda alimentata o no è una
## proprietà del BUS, e la decide la sorgente.
var powered: int = 0

## A quali apparecchi il software ha aperto la porta, un bit per apparecchio.
##
## Un tentativo resta segnato anche quando fallisce: è il driver che ha preso la
## porta e non la molla. Si cancella solo col RESET, ed è per questo che il reset
## esiste — su un bus seriale del '99 è esattamente quello che si fa.
var attempted: int = 0

## Com'era l'ALIMENTAZIONE NELL'ISTANTE in cui si è tentata la porta: per ogni
## apparecchio, la maschera `powered` di quel momento.
##
## È QUI CHE VIVE L'ORDINE DELLE COSE, ed è l'unica ragione per cui questa fase
## ha un mestiere invece di una sequenza da imparare a memoria. Accendere una
## camera DOPO averle aperto la porta non la fa rispondere: la porta era vuota
## quando il driver ci ha parlato, e il driver non ci riprova da solo. Senza
## questo campo la sorgente dovrebbe ricordarselo da sé — cioè non sarebbe più una
## funzione pura, e il banco non potrebbe più collaudarla.
var powered_when: PackedInt32Array = PackedInt32Array()

## Da quanti secondi la fase è aperta. Nessuna sorgente dell'MVP lo usa: sta qui
## perché la rottura che il GDD promette — «il software riconosce dispositivi che
## non hai collegato» — ha bisogno di qualcosa che cambi mentre guardi.
var seconds_running: float = 0.0
