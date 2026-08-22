## Il riepilogo dell'alba, sul CRT come tutto il resto.
##
## DOVE VIVE, E PERCHÉ QUI. Il rilievo M2 lasciava aperta la scelta fra il CRT
## diegetico e un'eccezione dichiarata a UX-DR1. È il CRT: UX-DR1 vuole che ogni
## interfaccia che non sia pausa o impostazioni viva sullo schermo del mondo, e
## UX-DR10 ha già fissato lo stesso precedente per il payout — «evento diegetico,
## non popup di gioco sopra la scena».
##
## IL PREZZO, e va detto invece che scoperto. All'alba il giocatore può essere in
## cucina, e questo riepilogo non lo insegue: lo trova tornando al monitor.
## «L'alba mostra il riepilogo» significa che il riepilogo è lì, non che venga
## portato davanti agli occhi di chi è in un'altra stanza. Trascinare il giocatore
## alla scrivania sarebbe l'unica alternativa, e romperebbe ADR-003, che la
## sedersi lo costruisce come gesto volontario.
##
## Il testo è in inglese perché è un'interfaccia software: la lingua delle
## macchine. I commenti sono in italiano, che è la lingua di chi ci lavora.
##
## Disegnato per 256x192, come la vista della fase polare, e con gli stessi
## colori del fosforo: sono stati scelti guardando lo schermo curvo, non stimati.
extends Control

const DESIGN_SIZE := Vector2(256, 192)

const BG := Color(0.02, 0.06, 0.03)
const FG := Color(0.62, 1.0, 0.68)
const DIM := Color(0.30, 0.58, 0.34)

var _font: SystemFont
var _night_index := 1
var _clock_text := ""
var _scores: Array[Vector2i] = []
var _score_keys: PackedStringArray = PackedStringArray()


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


## Unico ingresso. Si legge la `NightRun` una volta sola, all'alba: da qui in poi
## questo Control non guarda più niente, e non deve — la notte è finita.
func set_readout(run: NightRun, clock_text: String) -> void:
	_clock_text = clock_text
	if run == null:
		return
	_night_index = run.night_index
	_score_keys = PackedStringArray()
	_scores = []
	for k in run.phase_scores:
		_score_keys.append(String(k).to_upper())
		_scores.append(Vector2i(int(run.phase_scores[k]), 0))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)
	_text(Vector2(8, 22), "NIGHT %d — DAWN" % _night_index, FG, 12)
	_text(Vector2(8, 38), "21:00 → %s" % _clock_text, DIM, 12)

	# La spaziatura è stata scelta guardando lo schermo, non calcolata: con le
	# righe attaccate in alto restava un buco al centro che faceva sembrare il
	# riepilogo incompiuto invece che essenziale.
	var y := 84
	if _score_keys.is_empty():
		_text(Vector2(8, y), "NOTHING RECORDED", DIM, 12)
	else:
		_text(Vector2(8, 64), "PHASE SCORES", DIM, 12)
		for i in _score_keys.size():
			_text(Vector2(8, y), "%-14s %3d" % [_score_keys[i], _scores[i].x], FG, 12)
			y += 16

	_text(Vector2(8, 172), "the sky is getting light", DIM, 12)


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
