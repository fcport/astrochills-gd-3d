## MaxIm DL: tutto quello che riguarda la fotografia, in una finestra sola.
##
## PROVVISORIO, E SOLO PER LE SONDE. Sta dentro una `cornice98` e non disegna né barra
## del titolo né bordi.
##
## OTTO FASI SU NOVE HANNO UNO SCHERMO — tutte tranne la cupola, che per decisione
## dichiarata non ne ha (`phase_dome.screen()` torna `null`: il PC dell'osservatorio
## non sa che la cupola esista). Le altre otto espongono `screen() -> Control` e sono
## esattamente il lavoro di una notte: si accende il PC, si allinea al polo, si
## risolve il campo, si punta, si sceglie il bersaglio, si mette a fuoco, si raffredda
## la camera, si espone.
##
## PERCHÉ UNA BARRA E NON OTTO ICONE SUL DESKTOP. Sono i moduli di UN programma, non
## otto programmi: nel 1999 il software di ripresa era una finestra con dentro delle
## schede, e soprattutto queste otto cose si fanno IN SEQUENZA nella stessa sessione.
##
## L'ORDINE DI MONTAGGIO NON SI SCEGLIE, è un contratto: `setup()` PRIMA di entrare
## nell'albero, `screen()` DOPO. Lo dichiara `night/night_session.gd` e le fasi ci
## contano — `phase_goto._ready()` asserisce «phase senza run» se il `_run` non è
## ancora arrivato, e con l'ordine sbagliato la sonda moriva aprendo quel modulo.
##
## E I MODULI NON SI RICARICANO CAMBIANDO SCHEDA. La prima stesura buttava la fase e
## ne istanziava un'altra a ogni click, e tornando indietro si ritrovava tutto
## azzerato: l'esposizione impostata, il fuoco cercato, il target scelto. Qui le fasi
## si costruiscono UNA volta e restano, sospese quando non si guardano
## (`PROCESS_MODE_DISABLED`) e riaccese quando tornano davanti. Sospese non consumano
## niente e non fanno girare otto notti in parallelo, che era la ragione vera dietro
## la scelta sbagliata di prima.
##
## E CONDIVIDONO UN SOLO `NightRun`, come nella notte vera: è il foglio su cui una
## fase lascia quello che la successiva legge — il target scelto, il punto di sync,
## l'errore di puntamento. Con un run a testa ognuna avrebbe lavorato su una notte
## sua, e il lavoro non si sarebbe passato di mano.
extends Control

const BARRA_H := 15.0

## I moduli, nell'ordine in cui si fanno in una notte. Etichetta corta perché otto
## pulsanti devono stare in 300 px: sono abbreviazioni da software, non da prosa.
const MODULI := [
	["BOOT", "res://phases/startup/phase_startup.tscn"],
	["POLAR", "res://phases/polar/phase_polar.tscn"],
	["SOLVE", "res://phases/sync/phase_sync.tscn"],
	["GOTO", "res://phases/goto/phase_goto.tscn"],
	["TARGET", "res://phases/targeting/phase_targeting.tscn"],
	["FOCUS", "res://phases/focus/phase_focus.tscn"],
	["COOL", "res://phases/cooling/phase_cooling.tscn"],
	["SEQ", "res://phases/imaging/phase_imaging.tscn"],
]

var tema: RefCounted
var scelto := 7

## La notte su cui lavorano tutti i moduli. È della SONDA e non del gioco: un
## `NightRun` nuovo, così provare l'interfaccia non scrive niente nella partita.
var _run := NightRun.new()
## indice del modulo -> { "fase": Node, "schermo": Control }. Chi c'è dentro ci resta.
var _aperti := {}


func configura(t: RefCounted, dim: Vector2) -> void:
	tema = t
	custom_minimum_size = dim
	size = dim
	_ridimensiona()
	# Il modulo NON si carica qui: `configura()` arriva prima che questo Control sia
	# nell'albero, e un `add_child()` fatto adesso non farebbe girare il `_ready()`
	# del figlio — le fasi tengono il pannello in un `@onready`, che resterebbe null.
	if is_inside_tree():
		_mostra(scelto)


## Quando la finestra entra davvero nell'albero: è qui che il modulo si carica.
func _ready() -> void:
	if _aperti.is_empty():
		_mostra(scelto)


## Rimette i pannelli al loro posto dopo un cambio di misura (massimizza e ritorno).
## Li tocca TUTTI e non solo quello davanti: uno sospeso non si ridisegna da sé, e
## tornando a guardarlo si troverebbe piazzato secondo la misura di prima.
func _ridimensiona() -> void:
	for i in _aperti:
		var s: Control = _aperti[i]["schermo"]
		if is_instance_valid(s):
			s.position = Vector2(0, BARRA_H)


func rect_modulo(i: int) -> Rect2:
	var w := size.x / float(MODULI.size())
	return Rect2(i * w, 0, w, BARRA_H)


func clic(p: Vector2) -> bool:
	for i in MODULI.size():
		if rect_modulo(i).has_point(p):
			if i != scelto:
				_mostra(i)
			return true
	return false


## Porta davanti un modulo, costruendolo solo la prima volta.
func _mostra(i: int) -> void:
	scelto = i
	if not _aperti.has(i):
		_costruisci(i)
	for k in _aperti:
		var voce: Dictionary = _aperti[k]
		var davanti: bool = k == i
		var fase: Node = voce["fase"]
		var schermo: Control = voce["schermo"]
		if is_instance_valid(fase):
			# Sospesa, non distrutta: lo stato resta dov'è e i timer smettono di girare.
			fase.process_mode = (Node.PROCESS_MODE_INHERIT if davanti
					else Node.PROCESS_MODE_DISABLED)
		if is_instance_valid(schermo):
			schermo.visible = davanti
	queue_redraw()


func _costruisci(i: int) -> void:
	var scena: PackedScene = load(MODULI[i][1])
	if scena == null:
		push_warning("[maxim98] modulo %s non caricabile" % MODULI[i][0])
		return
	var fase: Node = scena.instantiate()
	# IL CONTRATTO: `setup()` prima dell'albero. Vedi la nota in testa.
	if fase.has_method("setup"):
		fase.setup(_run, {&"target_id": &"m42"})
	add_child(fase)

	var schermo: Control = null
	if fase.has_method("screen"):
		var s = fase.screen()
		if s == null:
			# Non è per forza un errore — la cupola non ha schermo per scelta — ma qui
			# dentro sono tutti moduli che dovrebbero averlo.
			push_warning("[maxim98] %s non ha consegnato il pannello" % MODULI[i][0])
		elif s is Control:
			schermo = s
			# Riparentato QUI dentro, e non è un dettaglio: le fasi sono `Node`, non
			# `Control`, e un Control figlio di un non-CanvasItem si attacca al canvas
			# del viewport — niente trasformazione del padre, niente ritaglio. Lasciato
			# dov'era, il pannello finiva a tutto schermo sopra le finestre.
			if schermo.get_parent() != null:
				schermo.get_parent().remove_child(schermo)
			add_child(schermo)
			schermo.position = Vector2(0, BARRA_H)
	_aperti[i] = {"fase": fase, "schermo": schermo}


func _draw() -> void:
	if tema == null:
		return
	# Il fondo è NERO e non grigio: sotto la barra ci sta un pannello a fosforo, e un
	# bordo grigio attorno a un programma monocromatico si vede come uno sbaglio.
	draw_rect(Rect2(Vector2(0, BARRA_H), size - Vector2(0, BARRA_H)), Phosphor.BG)

	for i in MODULI.size():
		var r := rect_modulo(i)
		var qui := i == scelto
		tema.pulsante(self, r, qui)
		var lab: String = MODULI[i][0]
		var w: float = tema.largo(lab, 9)
		tema.testo(self, Vector2(r.position.x + (r.size.x - w) * 0.5,
				r.position.y + (3 if qui else 2)), lab, tema.INK, 9)

	if not _aperti.has(scelto) or _aperti[scelto]["schermo"] == null:
		tema.testo(self, Vector2(6, BARRA_H + 8), "no panel", Phosphor.DIM, 10)
