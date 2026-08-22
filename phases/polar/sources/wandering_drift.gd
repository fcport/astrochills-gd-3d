## Una sorgente che mente: la stella deriva per conto proprio, alimentata dal
## tempo invece che dalle viti. Girarle non serve più a niente.
##
## NON È CONTENUTO. L'MVP non ha rotture — il seam esiste, le bugie no. Questa
## classe esiste per essere iniettata da `F9` e dimostrare che il vincolo di
## ADR-001 regge davvero: se `phase_polar.gd` continua a funzionare senza che una
## sua riga cambi, il seam tiene. Se dovesse cambiare, l'architettura è sbagliata
## e lo si scopre adesso, con una fase sola da sistemare invece di tre.
##
## È deliberatamente NON deterministica nel senso che conta: accumula il proprio
## tempo da `delta`, quindi due chiamate con lo stesso `input` danno risultati
## diversi. È esattamente la differenza che il banco di collaudo mette in stampa
## accanto a `HonestDrift`, perché è la differenza che si vuole poter vedere.
##
## L'accumulatore vive nella Resource e non in un nodo: quando la fase non è
## attiva la bugia si ferma da sola, senza nessun orfano che deriva in sottofondo.
class_name WanderingDrift
extends PolarTruthSource

## Ampiezza della velocita di deriva, in arcominuti al secondo.
@export var amplitude: float = 0.30

## Due frequenze incommensurabili: la stella non ripassa mai dallo stesso punto,
## e il moto non legge come un ciclo.
@export var speed_x: float = 0.30
@export var speed_y: float = 0.17

var _t := 0.0


func sample(_input: PolarInput, delta: float) -> Vector2:
	_t += delta
	return Vector2(sin(_t * speed_x), cos(_t * speed_y)) * amplitude
