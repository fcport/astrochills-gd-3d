## IL TENTACOLO, a chiamata — `F5`. Esiste solo nelle build di sviluppo.
##
## PERCHE' STA IN `debug/` E NON IN UNA FASE. Quello che scende dal cielo è un fatto
## della storia che non è ancora stato scritto: non si sa in che notte succeda, né
## cosa lo chiami, né cosa succeda dopo. Quello che si può sapere ADESSO è se la
## cosa, quando succederà, si guarda — se il movimento regge, se la scala è quella
## giusta, se davanti a quella facciata ci sta. Questo file serve a quello, e a
## niente altro: preme un tasto e fa scendere il tentacolo, lo ripreme e lo ritira.
##
## Quando la storia ci sarà, `world/tentacolo.tscn` resta dov'è e lo chiamerà lei.
## Questo file può sparire senza portarsi dietro niente — è la stessa divisione di
## `debug/lie_injector.gd`, che accende una bugia che poi le fasi useranno da sole.
##
## DOVE SCENDE, e non è un punto a caso: sull'asse della porta d'ingresso (x da 10,0
## a 11,2 sul muro sud, che sta a z = 9,50), sette metri e mezzo fuori — erano sei,
## ma da quando il braccio è grosso il doppio a otto metri da terra è largo quasi due,
## e la pelle arrivava a quattro metri dalla facciata. Uscendo ci si trova
## davanti; dal piazzale dell'auto si vede contro l'edificio, ed è l'inquadratura
## che dice quanto è grande. Non copre il tragitto verso il cancello, che passa da
## sud-est.
##
## KEYCODE GREZZO, non un'azione dell'`InputMap`, come gli altri strumenti di
## `debug/`: `F5` è libero (la taratura del rendering sta tutta sotto `Shift`).
extends Node

const SCENA := "res://world/tentacolo.tscn"

## In pianta, in metri di gioco. La quota se la calcola lui dal prato.
const DOVE := Vector2(10.6, 17.0)

## Quanto resta fra la punta e l'erba. Un metro e mezzo: abbastanza perché non
## compenetri le gobbe del prato mentre oscilla, poco perché da sotto la punta sia
## ad altezza d'uomo.
const FRANCO := 1.5

var _mondo: Node
var _tentacolo: Tentacolo


func configure(mondo: Node) -> void:
	_mondo = mondo


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or key.keycode != KEY_F5 or key.shift_pressed or key.ctrl_pressed:
		return
	if _tentacolo == null:
		_cala()
	else:
		_ritira()


func _cala() -> void:
	if _mondo == null:
		return
	var scena := load(SCENA) as PackedScene
	if scena == null:
		push_error("tentacolo: manca %s" % SCENA)
		return
	_tentacolo = scena.instantiate() as Tentacolo
	_mondo.add_child(_tentacolo)
	_tentacolo.posa_sul_prato(DOVE.x, DOVE.y, FRANCO)
	_tentacolo.scendi()
	Log.debug("debug", "tentacolo: scende su (%.1f, %.1f)" % [DOVE.x, DOVE.y])


## SI RITIRA E POI SI LIBERA, e l'ordine conta: liberarlo subito lo farebbe sparire
## in un fotogramma, che è l'unica cosa che una cosa di duecento metri non può
## fare. Se ne va come è arrivata, e il nodo muore quando è tornata nel cielo.
func _ritira() -> void:
	var t := _tentacolo
	_tentacolo = null
	if t == null:
		return
	t.risalito.connect(func() -> void: t.queue_free())
	t.risali()
	Log.debug("debug", "tentacolo: risale")
