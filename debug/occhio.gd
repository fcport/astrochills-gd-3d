## L'OCCHIO NEL CIELO, a chiamata — `F6`. Esiste solo nelle build di sviluppo.
##
## Stessa ragione e stessa divisione di `debug/tentacolo.gd`: quello che si apre nel
## cielo è un fatto della storia che non è ancora scritto, e qui si guarda soltanto se
## la cosa regge — la scala, il movimento, se contro il cielo di notte si legge. Un
## tasto lo apre, lo stesso tasto lo chiude. `world/occhio.gd` resta quando questo
## file sparirà.
##
## DOVE SI APRE, e non è un punto a caso. Lo si colloca dal punto appena fuori dalla
## porta d'ingresso, perché uscendo è lì che si alza la testa:
##
##   * A CINQUANTA GRADI SULL'ORIZZONTE, perché Federico l'ha voluto più in alto (era a
##     ventisei). Non per questo bisogna cercarlo: è così grande che chi esce e guarda
##     dritto ha sopra la testa la palpebra di sotto, e alzando lo sguardo di trenta
##     gradi ha davanti la pupilla. La pelle scende fino al profilo dell'orizzonte e ci
##     passa dietro.
##   * TRENTA GRADI A SINISTRA DELL'ASSE DELLA PORTA (verso +X), che è la direzione in
##     cui si cammina verso l'auto. Sull'asse della porta scende il tentacolo, e una
##     colonna larga due metri a sei metri di distanza taglierebbe in due l'occhio.
##   * DAVANTI ALLA PORTA la Luna gli illumina la faccia: il cielo di questo gioco ha
##     il nord verso +Z, e la Luna passa a sud. Messo dall'altra parte, sopra il tetto,
##     lo si vedrebbe controluce, una sagoma nera senza iride.
##
## KEYCODE GREZZO come gli altri strumenti di `debug/`: `F6` senza `Shift` è libero
## (con `Shift` è il jitter della taratura del rendering).
extends Node

const SCENA := "res://world/occhio.tscn"

## Da dove lo si guarda: fuori dalla porta, all'altezza degli occhi.
const DA := Vector3(10.6, 1.7, 10.6)
const AZIMUT := 30.0
const ALTEZZA := 50.0

var _mondo: Node
var _occhio: Occhio


func configure(mondo: Node) -> void:
	_mondo = mondo


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or key.keycode != KEY_F6 or key.shift_pressed or key.ctrl_pressed:
		return
	if _occhio == null:
		_apri()
	else:
		_chiudi()


func _apri() -> void:
	if _mondo == null:
		return
	var scena := load(SCENA) as PackedScene
	if scena == null:
		push_error("occhio: manca %s" % SCENA)
		return
	_occhio = scena.instantiate() as Occhio
	_mondo.add_child(_occhio)
	_occhio.colloca(DA, AZIMUT, ALTEZZA)
	_occhio.apri()
	Log.debug("debug", "occhio: si apre a %.0f° di azimut e %.0f° d'altezza" % [AZIMUT, ALTEZZA])


## SI CHIUDE E POI SI LIBERA, come il tentacolo che risale: un occhio largo seicento
## metri non sparisce in un fotogramma.
func _chiudi() -> void:
	var o := _occhio
	_occhio = null
	if o == null:
		return
	o.svanito.connect(func() -> void: o.queue_free())
	o.chiudi()
	Log.debug("debug", "occhio: si chiude")
