## La sorgente onesta della fase del fuoco: la curva a V vera.
##
## L'aggettivo nel nome dice se e come mente (NFR23). Questa non mente: c'è un
## punto di fuoco, le stelle si stringono avvicinandosi e si allargano
## allontanandosi, e il minimo è dove il minimo è.
##
## NON È UNA V, È UN'IPERBOLE, e la differenza si vede giocando. Una V vera —
## `min + pendenza · |Δ|` — ha un vertice a punta: il giocatore ci passa sopra e
## non sente niente, perché a un passo dal fuoco la stella è già grande quanto due
## passi prima. La curva vera dell'ottica è `sqrt(min² + (pendenza·Δ)²)`: lontano
## è indistinguibile da una retta, vicino si arrotonda, e quell'arrotondamento è
## precisamente la sensazione di «ci sono quasi». È la stessa formula che usano
## gli autofocus veri per interpolare il minimo.
##
## FUNZIONE PURA DI `input`, ed è un requisito, non uno stile. Nessuno stato
## interno, `delta` mai usato: `sample(i, 0.016)` e `sample(i, 0.99)` danno lo
## stesso valore.
class_name HonestVCurve
extends FocusTruthSource

## Dove sta il fuoco, in passi del focheggiatore.
##
## FISSO, PER ADESSO, ed è un limite dichiarato: chi gioca molte notti può
## imparare che il fuoco sta al centro della corsa meccanica. La cura vera non è
## un numero casuale — è la DERIVA TERMICA, che nella realtà sposta il fuoco di
## qualche decina di passi per grado mentre la notte si raffredda. Quando ci sarà
## una temperatura, questo campo diventerà il suo punto di partenza e la fase non
## cambierà di una riga: continuerà a chiedere quanto sono grosse le stelle.
@export var best_position: float = 0.0

## Il diametro minimo raggiungibile, in pixel. Non è zero e non deve esserlo:
## a fuoco perfetto una stella resta un dischetto, perché l'atmosfera la allarga.
## È il «seeing», ed è il motivo per cui il punteggio pieno non chiede un diametro
## nullo ma uno abbastanza vicino a questo.
@export var min_hfd: float = 2.4

## Di quanto cresce il diametro per ogni passo di scostamento, lontano dal fuoco.
@export var slope: float = 0.010


## Quanto sono grosse le stelle da qui. Tutto il resto della fase è il disegno di
## questo numero.
func sample(input: FocusInput, _delta: float) -> float:
	var d := (input.position - best_position) * slope
	return sqrt(min_hfd * min_hfd + d * d)
