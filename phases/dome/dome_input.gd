## Ciò che la fase della cupola passa alla propria sorgente di verità.
##
## È un RefCounted e non una Resource, per la stessa ragione di `PolarInput`: non
## va salvato, non va condiviso, e vive quanto un fotogramma. La fase ne tiene una
## sola istanza e la riempie a ogni `_process`.
class_name DomeInput
extends RefCounted

## Il comando a uomo presente: +1 apre, -1 chiude, 0 il motore è fermo.
##
## UN VERSO E NON UN INTERRUTTORE. La prima stesura era un `bool` — «il motore va
## o non va» — e bastava finché la cupola si poteva solo aprire. Una cupola che si
## apre e basta non è una cupola: è una cerniera. Il quadro ne ha due, di pulsanti,
## e il secondo non è un ripensamento — è quello che si preme quando arrivano le
## nuvole.
##
## DESCRIVE IL MOTORE E NON IL TASTO, e il nome lo dice: il giorno in cui il
## comando arrivasse da un temporizzatore o da un upgrade, questo campo non
## cambierebbe. Tenere premuti tutti e due i pulsanti vale 0: sui quadri veri
## quell'interblocco c'è, e qui costa una riga.
var command: int = 0

## Dov'è il battente adesso: 0 chiuso, 1 tutto aperto.
##
## Serve alla sorgente per sapere di essere a fine corsa — e a una sorgente
## bugiarda per fermarsi appena prima, che è l'unico guasto che questa fase può
## raccontare senza inventarsi una meccanica nuova.
var aperture: float = 0.0

## Da quanti secondi il motore sta girando senza interruzione, in un verso o
## nell'altro.
##
## Nessuna sorgente dell'MVP lo usa: il battente onesto va alla stessa velocità al
## primo secondo e al sesto. Sta qui per la stessa ragione per cui
## `PolarInput.seconds_since_correction` sta là — è nel contratto dichiarato, e una
## bugia futura del tipo «il motore si scalda e rallenta» avrebbe bisogno
## esattamente di questo e di nient'altro.
var seconds_running: float = 0.0
