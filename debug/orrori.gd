## GLI ORRORI COSMICI, a chiamata — `Ctrl+F1`…`Ctrl+F9`. Esiste solo nelle build di
## sviluppo.
##
## Stessa divisione del tentacolo (`F5`) e dell'occhio (`F6`): quello che succede sta in
## `world/orrori/`, e resterà quando la storia li chiamerà da sola; questo file preme i
## tasti e basta. Un tasto apre un orrore, lo stesso tasto gli chiede di andarsene, e il
## nodo si libera quando se n'è andato davvero.
##
##   Ctrl+F1  le nubi che passano sul cielo        `world/orrori/nubi.gd`
##   Ctrl+F2  l'inchiostro                         `world/orrori/inchiostro.gd`
##   Ctrl+F3  le ventose contro il cielo           `world/orrori/ventose.gd`
##   Ctrl+F4  le braccia all'orizzonte             `world/orrori/braccia.gd`
##   Ctrl+F5  l'occhio nell'oculare                `world/orrori/nell_oculare.gd`
##   Ctrl+F6  l'occhio nella posa                 `world/orrori/posa.gd`
##   Ctrl+F7  la montatura che ti segue            `world/orrori/montatura.gd`
##   Ctrl+F8  il colore venuto dallo spazio        `world/orrori/colore.gd`
##
## C'È CHI SE NE VA DA SOLO. Il tasto apre e il tasto manda via, ma un orrore può anche
## finire per conto suo — la visione di `Ctrl+F9` dura mezzo minuto e poi non c'è più. Il
## tasto non ha bisogno di saperlo: si sta dietro a `finito`, che arriva comunque, e il
## tasto ripremuto nel frattempo la manda via prima.
##
## PERCHÉ CTRL. Le F senza niente sono prese — tempo, tentacolo, occhio, bugie, partite,
## overlay — e con `Shift` c'è la taratura del rendering. Ctrl era libero, e gli strumenti
## sulle F nude adesso lo ignorano: prima rispondevano a qualunque F senza `Shift`, e
## `Ctrl+F1` avrebbe anche rimesso il tempo a velocità reale.
extends Node

const ORRORI := {
	KEY_F1: ["res://world/orrori/nubi.gd", "le nubi che passano"],
	KEY_F2: ["res://world/orrori/inchiostro.gd", "l'inchiostro"],
	KEY_F3: ["res://world/orrori/ventose.gd", "le ventose contro il cielo"],
	KEY_F4: ["res://world/orrori/braccia.gd", "le braccia all'orizzonte"],
	KEY_F5: ["res://world/orrori/nell_oculare.gd", "l'occhio nell'oculare"],
	KEY_F6: ["res://world/orrori/posa.gd", "l'occhio nella posa"],
	KEY_F7: ["res://world/orrori/montatura.gd", "la montatura che ti segue"],
	KEY_F8: ["res://world/orrori/colore.gd", "il colore venuto dallo spazio"],
	KEY_F9: ["res://world/orrori/pianeta.gd", "la visione del pianeta"],
}

var _mondo: Node
## Per tasto, l'orrore in corso: quello che il tasto, ripremuto, manda via.
var _aperti := {}


func configure(mondo: Node) -> void:
	_mondo = mondo


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or not key.ctrl_pressed or key.shift_pressed:
		return
	if not ORRORI.has(key.keycode):
		return
	get_viewport().set_input_as_handled()
	premi(key.keycode)


## Quello che fa il tasto. Pubblico per le sonde, che il tasto lo premono anche davvero.
func premi(tasto: Key) -> Orrore:
	var o: Orrore = _aperti.get(tasto)
	if o != null and is_instance_valid(o):
		_aperti.erase(tasto)
		o.finisci()
		Log.debug("orrori", "se ne va: %s" % ORRORI[tasto][1])
		return o
	if _mondo == null:
		return null
	var script := load(ORRORI[tasto][0]) as GDScript
	if script == null:
		push_error("orrori: manca %s" % ORRORI[tasto][0])
		return null
	o = script.new() as Orrore
	o.name = (ORRORI[tasto][0] as String).get_file().get_basename().capitalize().replace(" ", "")
	_mondo.add_child(o)
	o.finito.connect(func() -> void:
		if _aperti.get(tasto) == o:
			_aperti.erase(tasto)
		o.queue_free())
	_aperti[tasto] = o
	o.inizia()
	Log.debug("orrori", "arriva: %s" % ORRORI[tasto][1])
	return o


## L'orrore in corso su un tasto, o null.
func aperto(tasto: Key) -> Orrore:
	var o: Orrore = _aperti.get(tasto)
	return o if o != null and is_instance_valid(o) else null
