## I DUE PANNELLI NUOVI SI LEGGONO? Si disegnano, ingranditi, e si guardano.
##
## PERCHE' NON BASTA IL BANCO. `tools/prova_sync.gd` dimostra che i numeri sono
## giusti — l'errore della fase 5 arriva fino al GOTO — e non puo' dire niente
## sull'unica altra cosa che conta: che a 256x192 di fosforo verde quel reticolo
## si legga, che il rettangolino dell'inquadratura si veda, che la freccia al
## bordo si capisca. Sono due domande diverse e il banco risponde solo alla prima.
##
## E SERVE ANCHE COME RETE: un `_draw()` che sbaglia una chiamata non si accorge
## di niente in un collaudo headless — nessuno lo disegna. Qui si disegna.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/prova_schermi.tscn
##
## Scrive user://schermi.png con i due pannelli affiancati, ingranditi due volte.
extends Node

const FUORI := "user://schermi.png"

## Quanti fotogrammi si lasciano passare prima dello scatto: i `Control` si
## disegnano su `queue_redraw`, che arriva al fotogramma dopo.
const RESPIRO := 4

var _conto := 0


func _ready() -> void:
	_monta.call_deferred()


func _monta() -> void:
	var strato := CanvasLayer.new()
	strato.scale = Vector2(2, 2)
	add_child(strato)

	# LA FASE 5, con la stella dove nasce: fuori centro di un grado abbondante.
	var sync := load("res://phases/sync/phase_sync.tscn").instantiate() as PhaseSync
	var run := NightRun.new()
	sync.setup(run, {})
	add_child(sync)
	sync._process(0.016)
	var s1 := sync.screen()
	s1.get_parent().remove_child(s1)
	s1.position = Vector2(2, 2)
	strato.add_child(s1)
	print("[schermi] fase 5: stella %s a %.1f primi dal centro, punteggio %d"
		% [sync.truth.star_label(), sync.errore() * 60.0, sync.score()])

	# IL GOTO, con un modello di puntamento MEDIOCRE: e' lo stato in cui il
	# pannello ha piu' da dire, perche' il soggetto sta fuori dall'inquadratura e
	# dentro il cercatore — che e' precisamente la cosa che deve far capire.
	var run2 := NightRun.new()
	run2.elapsed_min = 150.0
	run2.selected_target_id = &"m13"
	run2.sync_done = true
	run2.sync_point_deg = Vector2(10.0, 38.8)
	run2.pointing_error_deg = Vector2(0.18, -0.12)
	var goto := load("res://phases/goto/phase_goto.tscn").instantiate() as PhaseGoto
	goto.setup(run2, {})
	add_child(goto)
	goto._process(0.016)
	var s2 := goto.screen()
	s2.get_parent().remove_child(s2)
	s2.position = Vector2(262, 2)
	strato.add_child(s2)
	print("[schermi] GOTO: soggetto a %.1f primi dal centro, %s"
		% [goto.errore() * 60.0, "inquadrato" if goto._inquadrato() else "fuori dal chip"])


func _process(_d: float) -> void:
	_conto += 1
	if _conto <= RESPIRO:
		return
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(FUORI)
	print("[schermi] scritto %s" % ProjectSettings.globalize_path(FUORI))
	get_tree().quit()
