## Overlay di stato — `F12`. Esiste solo nelle build di sviluppo.
##
## La riga che conta è quella della sorgente: `[HONEST]` / `[DRIFTING]`. È il
## dato che altrimenti sfugge, ed è l'unico modo di accorgersi che `F9` ha fatto
## qualcosa — la fase, dopo l'iniezione, si comporta esattamente come prima, che
## è precisamente ciò che si sta cercando di dimostrare.
##
## L'etichetta si ricava dal NOME della sorgente, non da un elenco di classi note
## tenuto qui dentro. La convenzione dice che una sorgente si chiama
## `<aggettivo>_<cosa>` e che l'aggettivo dice se e come mente (NFR23): una
## sorgente futura comparirà da sola, senza che questo file venga toccato.
##
## Vive fuori dal SubViewport del mondo, a piena risoluzione: è uno strumento, e
## uno strumento illeggibile non serve. La bassa risoluzione è per il gioco.
##
## PARTE SPENTO. `F12` lo accende, come dice la riga di aiuto qui sotto: partendo
## acceso coprirebbe l'angolo dello schermo dal primo fotogramma, proprio sopra
## il CRT che i comandi di taratura servono a guardare.
##
## LE DUE LINGUE, e la regola che le separa. Le voci di STATO sono in inglese
## perché sono superfici macchina, come tutti gli identificatori del progetto:
## `DEBUG`, `fps`, `tuning`, `shrink`, `[HONEST]`/`[DRIFTING]`. Le ETICHETTE e le
## righe di aiuto sono in italiano, che è la lingua di chi ci lavora — la stessa
## dei commenti. Non è un miscuglio: è la stessa divisione che il progetto usa
## ovunque, applicata a uno strumento che legge una persona sola.
extends CanvasLayer

@onready var _label: Label = %Label

var _main: Node
var _render: Node


func configure(main: Node, render: Node) -> void:
	_main = main
	_render = render


func _ready() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	_label.add_theme_font_override("font", font)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 4)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if key.pressed and not key.echo and key.keycode == KEY_F12 and not key.shift_pressed:
		visible = not visible


func _process(_delta: float) -> void:
	if not visible:
		return
	_label.text = "\n".join(_lines())


func _lines() -> PackedStringArray:
	var out := PackedStringArray()
	out.append("DEBUG")
	out.append(_clock_line())
	out.append("time_scale  %.1f" % Engine.time_scale)
	out.append(_phase_line())
	if _render != null:
		var s: Vector2i = _render.world_size()
		out.append("mondo     %dx%d  (shrink %d)  filtro %s" % [
			s.x, s.y, _render.shrink(), _render.filter_name()])
		out.append("snapping  %.0f%s" % [
			_render.snap_resolution,
			"  (spento)" if _render.snap_resolution >= 8192.0 else ""])
	out.append("fps       %d   tuning %s" % [
		Engine.get_frames_per_second(), Tuning.profile_hash])
	out.append("")
	out.append("F1/F2/F3/F4 tempo 1x 2x 5x 10x")
	out.append("F9  alterna sorgente onesta/bugiarda · F12 overlay")
	out.append("Shift+F1/F2 risoluzione · Shift+F3 filtro")
	out.append("Shift+F5/F6 jitter · Shift+F7 spegnilo")
	return out


## L'ora della notte e i minuti trascorsi, che sono la stessa cosa detta due
## volte: l'ora si ricava per somma diretta da `elapsed_min`, e vederle accanto è
## ciò che permette di accorgersi se una delle due sta mentendo.
func _clock_line() -> String:
	var c: NightClock = _main.clock() if _main != null else null
	if c == null:
		return "--:--  (nessuna notte)"
	return "%s  (elapsed %d min)" % [c.clock_text(), int(c.elapsed_min())]


## Una fase SOSPESA e una che gira non sono la stessa cosa, e da quando alzarsi
## sospende invece di concludere (storia 1.3) questa riga le mostrava identiche —
## lo strumento diceva «sta girando» di una fase ferma. `SUSP` chiude la voce
## rinviata che il Task 7 della 2.1 aveva riaperto.
func _phase_line() -> String:
	var p: Phase = _main.current_phase() if _main != null else null
	if p != null:
		var state := "SUSP" if _main.phase_suspended() else "RUN "
		return "%-9s %3d  [%s]  %s" % [p.key(), p.score(), _source_tag(p), state]
	if Game.run != null and not Game.run.phase_scores.is_empty():
		var parts := PackedStringArray()
		for k in Game.run.phase_scores:
			parts.append("%s %d" % [k, Game.run.phase_scores[k]])
		return "conclusa: " + ", ".join(parts)
	return "nessuna fase attiva"


## `honest_*` dice la verità; qualunque altro aggettivo, no.
func _source_tag(p: Phase) -> String:
	var src := p.get("truth") as Resource
	if src == null:
		return "??"
	var script := src.get_script() as Script
	if script == null:
		return "??"
	return "HONEST" if script.resource_path.get_file().begins_with("honest_") else "DRIFTING"
