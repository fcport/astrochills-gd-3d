## Ciò che la fase del raffreddamento passa alla propria sorgente di verità.
##
## È un RefCounted e non una Resource, per la ragione di `PolarInput`: non va
## salvato, non va condiviso, e vive quanto un fotogramma.
class_name CoolingInput
extends RefCounted

## La temperatura che il giocatore ha CHIESTO, in gradi centigradi.
##
## È l'unico comando di questa fase, ed è un numero che si può chiedere e non
## ottenere: un Peltier scende di tanto sotto l'ambiente e non di più. Che cosa
## succeda quando gliene chiedi trentacinque in una notte tiepida lo decide la
## sorgente, non questo campo.
var setpoint: float = 0.0

## Dove sta ADESSO la temperatura del sensore.
##
## Ci torna dentro perché la sorgente restituisce una VELOCITÀ e non una
## posizione: per sapere quanto ha ancora da scendere deve sapere da dove parte.
## È la stessa forma dell'apertura nella fase della cupola.
var temperature: float = 0.0

## Da quanti secondi la fase è aperta.
##
## QUI SERVE DAVVERO, a differenza delle altre fasi in cui sta come porta per le
## bugie future: quando il refrigeratore va al massimo e non ce la fa, la
## temperatura non si ferma — ondeggia. Quell'ondeggiare è una funzione del tempo,
## e passa da qui perché la sorgente resti una funzione pura del proprio ingresso.
var seconds_running: float = 0.0
