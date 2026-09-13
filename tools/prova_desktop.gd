## IL DESKTOP DEL PC, NEL GIOCO VERO: ci si siede, si clicca, si guarda (D-232).
##
## È la sonda del desktop DEFINITIVO. Quella di prima montava finestre per conto suo e
## spegneva la notte per non farsi portare via il vetro; questa non monta niente e non
## spegne niente: carica `main.tscn`, si siede con la sequenza vera e usa il desktop che
## il CRT ha già, con l'orchestratore acceso. Se una cosa funziona qui, funziona in
## partita.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/prova_desktop.tscn
##
## Serve una finestra vera: il puntatore si muove, il fuoco passa, e lo scatto finale
## si salva da quello che il rasterizzatore disegna — in headless non disegna nessuno.
##
## TOCCA IL SAVE COME UNA PARTITA, e va detto: carica il gioco con gli autoload veri, e
## la notte comincia. Non la finisce — la sonda esce molto prima dell'alba.
##
## Stampa un referto riga per riga; una riga con «<-- ATTESO» è un difetto.
extends Node

var _main: Node
var _crt: CrtScreen
var _desk: Node
var _difetti := 0


func _ready() -> void:
	_prova.call_deferred()


func _prova() -> void:
	_main = load("res://main.tscn").instantiate()
	get_tree().root.add_child(_main)
	get_tree().current_scene = _main
	await get_tree().create_timer(2.5).timeout

	_crt = _main._crt
	_desk = _main._desk
	if _crt == null or _desk == null or _crt.desktop() == null:
		print("[prova] CRT, postazione o desktop assenti  <-- ATTESO: tutti e tre")
		get_tree().quit(1)
		return
	var d: Desktop = _crt.desktop()
	var night: NightSession = _main._night

	print("")
	print("=== DESKTOP DEFINITIVO ===")
	_riga("vetro 352x264", _crt.viewport_size() == Vector2i(352, 264), str(_crt.viewport_size()))
	_riga("finestra di lavoro chiusa all'avvio", not d.is_window_open(Desktop.WORK_ID), "")
	_riga("la fase non ascolta a MaxIm chiuso", not night._screen_focused, "")
	_riga("schede lette dal piano", night._tab_labels.size() == 8,
			" ".join(night._tab_labels))

	_main._sit_down()
	await get_tree().create_timer(1.4).timeout
	_riga("seduti", _desk.is_seated, "")

	# --- MaxIm DL dall'icona, cliccata col puntatore come la cliccherebbe una mano.
	await _clicca(d.rect_icon(0).get_center())
	_riga("MaxIm DL aperto dall'icona", d.is_window_open(Desktop.WORK_ID), "")
	_riga("MaxIm ha il fuoco", d.is_work_focused(), "")
	_riga("la fase ascolta a MaxIm davanti", night._screen_focused, "")
	_riga("dentro c'è il contenuto della notte", d.work_content() != null,
			str(d.work_content()))
	_riga("scheda in corso", night._tab_current >= 0,
			"%d = %s" % [night._tab_current, night._tab_labels[night._tab_current] if night._tab_current >= 0 else "-"])

	# --- Photos: si apre sopra, e la fase smette di ascoltare.
	await _clicca(d.rect_icon(3).get_center())
	_riga("Photos aperto", d.is_window_open(&"photos"), "")
	_riga("con Photos davanti la fase non ascolta", not night._screen_focused, "")

	# --- Il pulsante di MaxIm in taskbar gli ridà il fuoco.
	var lista := d.windows()
	var i_work := lista.find(d.window(Desktop.WORK_ID))
	await _clicca(d.rect_taskbar(i_work, lista.size()).get_center())
	_riga("taskbar riporta MaxIm davanti", d.is_work_focused(), "")

	# --- La X di Photos la chiude davvero, e l'elenco torna a casa. Prima la si porta
	# davanti dalla taskbar: MaxIm la copre quasi tutta, e un click sulla sua X cadrebbe
	# — giustamente — sulla finestra che sta sopra.
	var ph := d.window(&"photos")
	lista = d.windows()
	await _clicca(d.rect_taskbar(lista.find(ph), lista.size()).get_center())
	await _clicca(ph.position + ph.rect_close().get_center())
	_riga("X chiude Photos", not d.is_window_open(&"photos"), "")
	_riga("l'elenco non è orfano", _main._photos != null and _main._photos.get_parent() == _main, "")

	# --- Il terminale rispetta l'attesa, come col tasto.
	await _clicca(d.rect_icon(1).get_center())
	_riga("terminale aperto solo se la notte è in attesa",
			d.is_window_open(&"terminal") == night.is_waiting(),
			"attesa=%s aperto=%s" % [night.is_waiting(), d.is_window_open(&"terminal")])

	# --- Il mouse muove la freccia, non la testa.
	var yaw_prima: float = _desk._player.global_rotation.y
	var freccia_prima := d.pointer_position()
	await _muovi(Vector2(40, 0))
	_riga("il mouse muove la freccia", d.pointer_position() != freccia_prima, "")
	_riga("e non gira la testa", is_equal_approx(_desk._player.global_rotation.y, yaw_prima), "")

	# --- Con ALT la testa gira; lasciato ALT torna al monitor.
	await _tasto(KEY_ALT, true)
	await _muovi(Vector2(120, 0))
	var girata := not is_equal_approx(_desk._player.global_rotation.y, yaw_prima)
	_riga("con ALT la testa gira", girata, "")
	await _tasto(KEY_ALT, false)
	await get_tree().create_timer(0.5).timeout
	_riga("lasciato ALT torna al monitor",
			absf(_desk._player.global_rotation.y - yaw_prima) < 0.01, "")

	# --- Massimizza e ritorno. Si guarda la MISURA e non solo il flag: la prima stesura
	# passava questa riga con la finestra tornata larga quanto il vetro.
	var w := d.window(Desktop.WORK_ID)
	var misura := w.size
	var posto := w.position
	await _clicca(w.position + w.rect_maximize().get_center())
	_riga("MaxIm massimizzato", w.maximized and w.size == d.work_area().size, str(w.size))
	await _clicca(w.position + w.rect_maximize().get_center())
	_riga("e riportato com'era", not w.maximized and w.size == misura and w.position == posto,
			"%s a %s" % [w.size, w.position])
	_riga("la finestra sta dentro il vetro", d.work_area().encloses(Rect2(w.position, w.size)), "")

	for _k in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("user://desktop_definitivo.png")
	print("[prova] scatto: %s/desktop_definitivo.png" % OS.get_user_data_dir())
	print("=== %s ===" % ("tutto a posto" if _difetti == 0 else "%d difetti" % _difetti))
	get_tree().quit()


func _riga(cosa: String, ok: bool, dettaglio: String) -> void:
	if not ok:
		_difetti += 1
	print("[prova] %-44s %s%s" % [cosa, dettaglio, "" if ok else "   <-- ATTESO"])


## Porta la freccia su un punto del vetro e clicca, passando dal CRT come farebbe
## `main.gd`: così vale anche il cancello dell'input.
func _clicca(punto: Vector2) -> void:
	var d: Desktop = _crt.desktop()
	_crt.pointer_move(punto - d.pointer_position())
	_crt.pointer_button(true)
	_crt.pointer_button(false)
	for _k in 3:
		await get_tree().process_frame


## Un movimento del mouse vero, dall'`Input`: deve passare da `main.gd._input`, che è il
## punto in cui si decide se va alla freccia o alla testa.
func _muovi(delta: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.relative = delta
	Input.parse_input_event(ev)
	for _k in 3:
		await get_tree().process_frame


func _tasto(key: Key, premuto: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.keycode = key
	ev.pressed = premuto
	Input.parse_input_event(ev)
	for _k in 3:
		await get_tree().process_frame
