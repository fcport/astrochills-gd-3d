## Ciò che la fase della cupola passa alla propria sorgente di verità.
##
## È un RefCounted e non una Resource, per la stessa ragione di `PolarInput`: non
## va salvato, non va condiviso, e vive quanto un fotogramma. La fase ne tiene una
## sola istanza e la riempie a ogni `_process`.
class_name DomeInput
extends RefCounted

## Il comando a uomo presente: `true` finché il giocatore tiene premuto.
##
## SI CHIAMA `motor_on` E NON `open_pressed` perché descrive il MOTORE, non il
## tasto. Chi legge questo campo è la sorgente di verità, che simula un
## meccanismo: il giorno in cui il comando arrivasse da un temporizzatore o da un
## upgrade, il campo non cambierebbe nome.
var motor_on: bool = false

## Dov'è il battente adesso: 0 chiuso, 1 tutto aperto.
##
## Serve alla sorgente per sapere di essere a fine corsa — e a una sorgente
## bugiarda per fermarsi appena prima, che è l'unico guasto che questa fase può
## raccontare senza inventarsi una meccanica nuova.
var aperture: float = 0.0

## Da quanti secondi il motore sta girando senza interruzione.
##
## Nessuna sorgente dell'MVP lo usa: il battente onesto va alla stessa velocità al
## primo secondo e al sesto. Sta qui per la stessa ragione per cui
## `PolarInput.seconds_since_correction` sta là — è nel contratto dichiarato, e una
## bugia futura del tipo «il motore si scalda e rallenta» avrebbe bisogno
## esattamente di questo e di nient'altro.
var seconds_running: float = 0.0
