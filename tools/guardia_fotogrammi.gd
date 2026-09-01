## SCRIVE NEL LOG OGNI FOTOGRAMMA CHE DURA TROPPO, e dove si era.
##
## PERCHÉ ESISTE. «Quando entro nell'osservatorio le ombre sfarfallano e poi si
## stabilizzano»: un sintomo così non si diagnostica dalla parte del programmatore,
## perché chi lo vede è dall'altra parte dello schermo e quando succede non sta
## misurando niente. Una sonda sintetica ci arriva vicino e non ci arriva: la mia ha
## riprodotto **96 e 137 millisecondi nei primi fotogrammi di una sessione** —
## contro i sette normali — ma non ha saputo riprodurre nulla entrando in una stanza
## a motore caldo, nemmeno in una mai vista prima.
##
## Allora si sposta lo strumento dove sta il sintomo: nel gioco vero, addosso a chi
## lo vede. Quando succede, il log dice quanto è durato il fotogramma, dove stava il
## giocatore e da quanto era acceso il gioco — e a quel punto la domanda «perché»
## smette di essere un'opinione.
##
## SI ACCENDE SOLO NELLE BUILD DI DEBUG, insieme al resto degli strumenti. Costa un
## confronto per fotogramma, e non scrive niente finché non c'è niente da scrivere.
##
## LA SOGLIA È VENTI MILLISECONDI perché a sessanta fotogrammi al secondo il budget
## è sedici e mezzo: oltre venti, un fotogramma è saltato ed è una cosa che si vede.
## Non è una soglia di comodo — è quella per cui l'immagine sobbalza.
class_name GuardiaFotogrammi
extends Node

const LENTO_MS := 20.0

## Quanti se ne segnalano, al massimo. Un difetto che si presenta duecento volte non
## è più informativo di uno che si presenta venti, e un log allagato non lo legge
## nessuno — che è il modo in cui uno strumento diventa rumore.
const QUANTI := 20

## I primi fotogrammi di una sessione sono lenti sempre e per costruzione: il
## motore accende, la scena si monta, la notte parte. Segnalarli vorrebbe dire
## seppellire il caso interessante sotto quello noto.
const GRAZIA := 1.5

var _giocatore: Node3D
var _visti := 0
var _t := 0.0


func _ready() -> void:
	# In coda a tutti, così `delta` è quello del fotogramma appena finito.
	process_priority = 1000


func _process(delta: float) -> void:
	_t += delta
	if _t < GRAZIA or _visti >= QUANTI:
		return
	var ms := delta * 1000.0
	if ms < LENTO_MS:
		return
	_visti += 1
	if _giocatore == null or not is_instance_valid(_giocatore):
		_giocatore = Player.find_in(get_tree())
	var dove := "sconosciuto"
	if _giocatore != null:
		var p := _giocatore.global_position
		dove = "(%.1f, %.1f)" % [p.x, p.z]
	Log.info("fotogrammi", "fotogramma lento: %.0f ms a %s, %.1f s dall'avvio%s"
		% [ms, dove, _t, "  (ultimo segnalato)" if _visti == QUANTI else ""])
