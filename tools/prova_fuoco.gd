## La fase del fuoco si può VINCERE? Si gioca, e si guarda.
##
## DUE DOMANDE, E UNA SOLA NON BASTA. La prima è aritmetica: cercando il minimo
## come lo cercherebbe una persona — vai da una parte, se peggiora torna indietro,
## accorcia il passo — si arriva al punteggio pieno, o la zona buona è così stretta
## che ci si passa sopra senza accorgersene? La seconda è di disegno: a 256x192 di
## fosforo verde, quel pannello si legge? Il banco può rispondere solo alla prima.
##
## LA RICERCA QUI DENTRO NON È UN AUTOFOCUS, ed è importante che resti stupida: se
## avesse la formula della curva troverebbe il minimo al primo colpo e non
## proverebbe niente. Fa quello che fa un giocatore la prima notte — tiene premuto,
## guarda il numero, cambia idea — e se anche così ci arriva, ci arriva chiunque.
##
## È UNA SCENA E NON UNO `--script`: la fase legge `Tuning`, che è un autoload.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/prova_fuoco.tscn
##
## Scrive user://fuoco.png (il pannello ingrandito tre volte, per leggerlo).
extends Node

const FUORI := "user://fuoco.png"

## Ogni quanto la ricerca guarda il diametro e decide.
const OGNI := 0.20

## Quanti cambi di direzione prima di fermarsi. Tre bastano: il primo trova il
## verso, il secondo scavalca il minimo, il terzo ci si ferma sopra.
const INVERSIONI := 5

## Oltre questo tempo si smette comunque, e si dice che non ci si è arrivati.
const LIMITE := 40.0

var _fase: PhaseFocus
var _verso := 1
var _ultimo := INF
var _inversioni := 0
var _tempo := 0.0
var _fra_una_e_l_altra := 0.0
var _finita := false
var _conto := 0


func _ready() -> void:
	_monta.call_deferred()


func _monta() -> void:
	var scena: Node = load("res://phases/focus/phase_focus.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	_fase = scena as PhaseFocus
	# Il pannello a schermo, ingrandito: a grandezza naturale è un francobollo in
	# un angolo della finestra, e giudicarlo così vorrebbe dire non giudicarlo.
	var strato := CanvasLayer.new()
	strato.scale = Vector2(3, 3)
	add_child(strato)
	var vista := _fase.screen()
	vista.get_parent().remove_child(vista)
	strato.add_child(vista)
	print("[fuoco] partenza: encoder %d, diametro %.2f" % [_fase.encoder(), _fase.hfd()])
	Input.action_press(&"focus_out")


func _process(d: float) -> void:
	if _fase == null:
		return
	if _finita:
		_conto += 1
		if _conto > 6:
			var img: Image = get_viewport().get_texture().get_image()
			if img != null:
				img.save_png(FUORI)
				print("[fuoco] scatto in %s" % ProjectSettings.globalize_path(FUORI))
			get_tree().quit()
		return

	_tempo += d
	_fra_una_e_l_altra += d
	if _fra_una_e_l_altra < OGNI:
		return
	_fra_una_e_l_altra = 0.0

	var ora := _fase.hfd()
	print("[fuoco] %5.2f s  encoder %5d  diametro %.3f  punteggio %3d"
		% [_tempo, _fase.encoder(), ora, _fase.score()])

	# PEGGIORATO: si torna indietro. È tutta la strategia, ed è quella che si usa
	# stando davanti al monitor la prima volta.
	if ora > _ultimo:
		_inversioni += 1
		_verso = -_verso
		Input.action_release(&"focus_in")
		Input.action_release(&"focus_out")
		Input.action_press(&"focus_out" if _verso > 0 else &"focus_in")
	_ultimo = ora

	if _inversioni >= INVERSIONI or _tempo > LIMITE:
		Input.action_release(&"focus_in")
		Input.action_release(&"focus_out")
		var punteggio := _fase.score()
		print("[fuoco] fermo dopo %.1f s e %d inversioni: diametro %.3f, punteggio %d%s"
			% [_tempo, _inversioni, _fase.hfd(), punteggio,
				"" if punteggio >= 90 else "   <-- NON CI SI ARRIVA cercando a occhio"])
		_finita = true
		_conto = 0
