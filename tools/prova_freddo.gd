## Chiedere troppo freddo si PAGA? E chiedere il giusto si può fare?
##
## DUE DOMANDE CHE SI PROVANO SOLO GIOCANDO. Il banco può dire che la sorgente
## restituisce i numeri giusti; non può dire se la fase, in tempo reale, arriva al
## punteggio pieno prima che il giocatore si annoi, né se chi ha chiesto trenta
## gradi di troppo se ne accorge. La prima è una misura di tempo, la seconda è una
## misura di conseguenza.
##
## SI ASPETTA DAVVERO, senza toccare `Engine.time_scale`. Accelerare il tempo per
## misurare un'attesa vuol dire misurare un'altra cosa, ed è già costato tre giri
## alla sonda della cupola.
##
## È una scena e non uno `--script`: la fase legge `Tuning`, che è un autoload.
##
##     SET=-28 Godot_v4.7.2-stable_win64.exe --path . tools/prova_freddo.tscn
##
## SET=<gradi> è la temperatura da chiedere (difetto -28). ATTESA=<secondi> quanto
## si sta a guardare. Scrive user://freddo.png, il pannello ingrandito tre volte.
extends Node

const FUORI := "user://freddo.png"

## Ogni quanto si stampa una riga di referto.
const OGNI := 5.0

var _fase: PhaseCooling
var _voluto := -28.0
var _attesa := 45.0
var _tempo := 0.0
var _da_ultimo := 0.0
var _finita := false
var _conto := 0

## Il MEGLIO e il PEGGIO del punteggio dopo la stabilizzazione.
##
## Un punteggio istantaneo non basta a giudicare una temperatura che ondeggia: chi
## la guarda al momento buono la vede ferma. La domanda giusta non e' «quanto vale
## adesso» ma «quanto puo' valere al massimo scegliendo l'istante migliore», e
## quella si risponde solo guardando un ciclo intero.
const DA_QUANDO := 30.0
var _meglio := -1
var _peggio := 101


func _ready() -> void:
	_monta.call_deferred()


func _monta() -> void:
	var s := OS.get_environment("SET")
	if not s.is_empty():
		_voluto = float(s)
	var a := OS.get_environment("ATTESA")
	if not a.is_empty():
		_attesa = float(a)

	var scena: Node = load("res://phases/cooling/phase_cooling.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	_fase = scena as PhaseCooling

	var strato := CanvasLayer.new()
	strato.scale = Vector2(3, 3)
	add_child(strato)
	var vista := _fase.screen()
	vista.get_parent().remove_child(vista)
	strato.add_child(vista)

	print("[freddo] parto da %.1f gradi, chiedo %.0f" % [_fase.temperature(), _voluto])
	_chiedi(_voluto)


## Porta il setpoint dove si vuole, premendo il tasto una volta per grado: è quello
## che farebbe il giocatore, e prova anche che il tasto funzioni.
func _chiedi(gradi: float) -> void:
	var quanti := int(round(absf(gradi) / PhaseCooling.STEP))
	var azione := &"cooling_colder" if gradi < 0.0 else &"cooling_warmer"
	for _i in quanti:
		var e := InputEventAction.new()
		e.action = azione
		e.pressed = true
		Input.parse_input_event(e)


func _process(d: float) -> void:
	if _fase == null:
		return
	if _finita:
		_conto += 1
		if _conto > 6:
			_scatta()
			get_tree().quit()
		return

	_tempo += d
	if _tempo > DA_QUANDO:
		var ora := _fase.score()
		_meglio = maxi(_meglio, ora)
		_peggio = mini(_peggio, ora)
	if _tempo - _da_ultimo >= OGNI:
		_da_ultimo = _tempo
		print("[freddo] %5.1f s  temp %+6.2f  cella %3d%%  ballo %.2f  punteggio %3d"
			% [_tempo, _fase.temperature(), roundi(_fase.duty() * 100.0),
				_fase.escursione(), _fase.score()])

	if _tempo < _attesa:
		return
	_referto()
	_finita = true
	_conto = 0


func _referto() -> void:
	var punteggio := _fase.score()
	var ballo := _fase.escursione()
	print("[freddo] dopo %.0f s chiedendo %.0f: temp %+.2f, cella %d%%, ballo %.2f, punteggio %d"
		% [_attesa, _voluto, _fase.temperature(), roundi(_fase.duty() * 100.0),
			ballo, punteggio])
	# I DUE VERDETTI, e ciascuno vale solo per la sua strada. Che cosa sia «troppo»
	# lo sa la sorgente, non questa sonda: qui si guarda il SINTOMO — se la cella è
	# al massimo, la temperatura deve ballare e il punteggio deve sparire.
	print("[freddo] dopo i primi %.0f s il punteggio e' stato fra %d e %d"
		% [DA_QUANDO, _peggio, _meglio])
	if _fase.duty() >= 0.92:
		print("[freddo] cella al limite: %s"
			% ("non si prende un buon voto nemmeno scegliendo l'istante migliore"
				if _meglio < 60
				else "SI PRENDE %d SCEGLIENDO L'ISTANTE   <-- ATTESO: meno di 60" % _meglio))
	else:
		print("[freddo] cella nei margini: %s"
			% ("si arriva al punteggio pieno" if punteggio >= 90
				else "NON CI SI ARRIVA   <-- ATTESO: punteggio >= 90"))


func _scatta() -> void:
	if DisplayServer.get_name() == "headless":
		print("[freddo] headless: nessuno scatto")
		return
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(FUORI)
		print("[freddo] scatto in %s" % ProjectSettings.globalize_path(FUORI))
