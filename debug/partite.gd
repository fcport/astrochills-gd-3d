## LE PARTITE, col tasto F10: continuare, cominciarne una da zero, provare una cosa su una
## copia della partita vera (D-243).
##
## PERCHÉ ESISTE. Federico: «testare cose e fare cose senza avere un concetto di
## salvataggio» diventa strano. Per provare la moka non ancora comprata bisognava togliere
## la moka dalla partita vera, e le sonde giravano sopra le sue trentacinque notti. Qui si
## apre un'altra partita, e quella vera resta dov'è.
##
## SOLO IN SVILUPPO, come tutto `debug/`: `main.gd` lo monta dietro `OS.is_debug_build()`.
## In release F10 non risponde, e la partita è sempre la vera.
##
## MENTRE È APERTO IL MONDO SI FERMA (`SceneTree.paused`): W e S scelgono una voce, e senza
## la pausa farebbero anche camminare il giocatore — il suo movimento legge `Input` a ogni
## passo di fisica, e non c'è `set_input_as_handled` che lo fermi.
##
## FUORI DALLA PARTITA VERA resta scritto in alto a sinistra quale si sta giocando: una
## partita di prova sopravvive al riavvio, e dimenticarsela vorrebbe dire credere di aver
## perso le lire.
extends CanvasLayer

const FG := Color(0.92, 0.94, 0.90)
const DIM := Color(0.62, 0.64, 0.60)
const FONDO := Color(0.0, 0.0, 0.0, 0.85)
const FONT_SIZE := 14

var _pannello: PanelContainer
var _testo: Label
var _etichetta: Label

## Le righe del pannello: `{testo, azione, nome}`. Si ricompongono a ogni apertura, perché
## le partite possono essere cambiate da un'altra finestra.
var _voci: Array[Dictionary] = []
var _scelta := 0
var _aperto := false
var _mouse_prima := Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])

	_etichetta = Label.new()
	_etichetta.position = Vector2(8, 6)
	_stile(_etichetta, font, FG)
	_etichetta.text = "PARTITA DI PROVA: %s   (F10)" % Game.partita
	_etichetta.visible = Game.partita != SaveManager.PARTITA_VERA
	add_child(_etichetta)

	_pannello = PanelContainer.new()
	var sfondo := StyleBoxFlat.new()
	sfondo.bg_color = FONDO
	sfondo.set_content_margin_all(14)
	_pannello.add_theme_stylebox_override("panel", sfondo)
	_pannello.set_anchors_preset(Control.PRESET_CENTER)
	_pannello.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_pannello.grow_vertical = Control.GROW_DIRECTION_BOTH
	_testo = Label.new()
	_stile(_testo, font, FG)
	_pannello.add_child(_testo)
	_pannello.visible = false
	add_child(_pannello)


func _stile(l: Label, font: Font, colore: Color) -> void:
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", FONT_SIZE)
	l.add_theme_color_override("font_color", colore)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)


## `_input` e non `_unhandled_input`: aperto, il pannello deve prendersi i tasti prima di
## chiunque altro, e chiuso deve comunque sentire F10.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null:
		if _aperto and event is InputEventMouseButton:
			get_viewport().set_input_as_handled()
		return
	if key.pressed and not key.echo and key.keycode == KEY_F10 and not key.shift_pressed:
		if _aperto:
			_chiudi()
		else:
			_apri()
		get_viewport().set_input_as_handled()
		return
	if not _aperto:
		return
	get_viewport().set_input_as_handled()
	if not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_W:
			_scelta = wrapi(_scelta - 1, 0, _voci.size())
		KEY_S:
			_scelta = wrapi(_scelta + 1, 0, _voci.size())
		KEY_E, KEY_ENTER, KEY_KP_ENTER:
			_conferma()
			return
		KEY_ESCAPE:
			_chiudi()
			return
	_disegna()


func _apri() -> void:
	_voci.clear()
	for nome in SaveManager.elenco_partite():
		if nome == SaveManager.PARTITA_SONDE:
			continue
		_voci.append({&"testo": nome, &"azione": &"apri", &"nome": nome})
	if not _voci.any(func(v: Dictionary) -> bool: return v[&"nome"] == Game.partita):
		_voci.insert(0, {&"testo": Game.partita, &"azione": &"apri", &"nome": Game.partita})
	_voci.append({&"testo": "nuova partita, da zero", &"azione": &"nuova", &"nome": ""})
	_voci.append({&"testo": "copia della partita vera", &"azione": &"copia", &"nome": ""})
	_scelta = 0
	for i in _voci.size():
		if _voci[i][&"nome"] == Game.partita:
			_scelta = i
	_aperto = true
	_mouse_prima = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_pannello.visible = true
	_disegna()


func _chiudi() -> void:
	_aperto = false
	_pannello.visible = false
	get_tree().paused = false
	Input.mouse_mode = _mouse_prima


func _disegna() -> void:
	var righe := PackedStringArray(["PARTITE", ""])
	for i in _voci.size():
		var v := _voci[i]
		var segno := ">" if i == _scelta else " "
		var nota := ""
		if v[&"nome"] == Game.partita:
			nota = "   in corso — notte %d, %d lire" % [
				Game.profile.nights_completed + 1, Game.wallet_now()]
		if v[&"azione"] != &"apri" and (i == 0 or _voci[i - 1][&"azione"] == &"apri"):
			righe.append("")
		righe.append("%s %s%s" % [segno, v[&"testo"], nota])
	righe.append("")
	righe.append("W/S scegli   E apri   F10 chiudi")
	righe.append("La notte in corso non si salva: si riparte dalle 21:00.")
	_testo.text = "\n".join(righe)


func _conferma() -> void:
	var v := _voci[_scelta]
	var nome: String = v[&"nome"]
	match v[&"azione"]:
		&"nuova":
			nome = Game.nuova_partita()
		&"copia":
			nome = Game.copia_partita(SaveManager.PARTITA_VERA)
	if nome.is_empty():
		Log.warn("debug", "F10: la partita non si è potuta creare")
		return
	if nome == Game.partita:
		_chiudi()
		return
	Log.info("debug", "F10: si apre la partita «%s»" % nome)
	_aperto = false
	Game.apri_partita(nome)
