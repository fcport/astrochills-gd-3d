## Il desktop di Windows 98 che sta sul vetro del PC dell'osservatorio.
##
## PERCHÉ ESISTE. Il monitor mostrava una cosa sola alla volta: `CrtScreen.show_control()`
## svuotava il viewport e ci metteva il nuovo arrivato, e chiunque mostrasse qualcosa
## buttava via chi c'era prima. Con un sistema a finestre quella gara per il vetro non
## si vince, si toglie: lo schermo ha SEMPRE questo desktop, e ciò che prima prendeva il
## vetro adesso apre una finestra.
##
## NON SA COSA MOSTRA, come il CRT che lo contiene (tabella dei confini: `crt/` «riceve
## un Control, non sa quale»). Sa disegnare icone, finestre, taskbar e puntatore, e dire
## quale icona è stata aperta o quale finestra chiede di chiudersi. Cosa c'è dietro
## un'icona lo decide chi ascolta, cioè il punto d'ingresso.
##
## LA FINESTRA DI LAVORO. Una delle finestre è speciale: è quella in cui la notte mostra
## le fasi, la rivelazione, la vendita, il menu e il riepilogo. Il desktop non sa che si
## chiami MaxIm DL — il titolo glielo dà chi lo configura — e non si distrugge mai:
## chiuderla la nasconde, perché ciò che contiene continua a lavorare.
##
## NASCE CHIUSA, ed è una decisione presa guardando: sedendosi al computer si vede prima
## Windows, e il programma lo apre chi lo usa. Una versione che si apriva con le finestre
## già spalancate non si capiva né cosa fosse né cosa si potesse fare.
class_name Desktop
extends Control

## Un'icona è stata aperta. Porta l'id; quella della finestra di lavoro la gestisce il
## desktop da sé, ma viene annunciata lo stesso.
signal icon_activated(id: StringName)
## Qualcuno ha premuto la X di una finestra che non è di lavoro. Il desktop NON la
## chiude: il contenuto non è suo, e deve riprenderselo chi lo possiede.
signal window_close_requested(id: StringName)
## La finestra di lavoro ha preso o perso il fuoco. Serve a chi decide se i tasti devono
## arrivare alla fase: comandare un programma che non si vede non ha senso.
signal work_focus_changed(focused: bool)

const WORK_ID := &"work"
const TASKBAR_H := 28.0
const ICON := 32.0
const ICON_STEP := Vector2(64, 46)
const ICON_ORIGIN := Vector2(8, 6)
## Le finestre si aprono a cascata, come in Windows: ognuna un po' più in là.
const CASCADE := Vector2(14, 12)
const FIRST_WINDOW := Vector2(52, 8)
## La finestra di lavoro contiene un pannello da 256x192 con sopra la fila delle schede.
const WORK_SIZE := Vector2(300, 233)
const WORK_POS := Vector2(44, 2)

var look: DesktopTheme
## Le icone: [id, etichetta, forma]. La forma è una di quelle che `_draw_icon` conosce.
var icons: Array = []
## Da dove leggere l'ora per la tray. Un Callable che torna una stringa: il desktop non
## sa che esista un orologio della notte, sa solo chiedere che ore sono.
var clock_source: Callable
var start_open := false

var _pointer: DesktopPointer
var _work: DesktopWindow
var _work_open := false
var _work_focused := false
var _clock := ""
var _cascade := 0
var _drag: DesktopWindow
var _grab := Vector2.ZERO


func setup(t: DesktopTheme, dim: Vector2) -> void:
	look = t
	custom_minimum_size = dim
	size = dim
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_work = DesktopWindow.new()
	_work.setup(look, "", WORK_SIZE, WORK_ID)
	_work.position = WORK_POS
	_work.content_bg = Phosphor.BG
	_work.visible = false
	add_child(_work)

	_pointer = DesktopPointer.new()
	_pointer.setup(dim)
	add_child(_pointer)


func pointer_position() -> Vector2:
	return _pointer.point


# ---------------------------------------------------------------- la finestra di lavoro

func set_work_title(t: String) -> void:
	_work.title = t
	_work.queue_redraw()
	queue_redraw()


## Mette un contenuto nella finestra di lavoro. Non la apre: se è chiusa, il contenuto
## aspetta lì dentro e si vedrà quando la si apre.
func set_work_content(c: Control) -> void:
	_work.host(c)
	_apply_input_focus()


func work_content() -> Control:
	return _work.content()


func set_work_tabs(labels: PackedStringArray, current: int) -> void:
	_work.tabs = labels
	_work.current_tab = current
	_work.layout_content()
	_work.queue_redraw()


func open_work() -> void:
	_work_open = true
	_work.visible = true
	_work.minimized = false
	focus(_work)


func hide_work() -> void:
	_work_open = false
	_work.visible = false
	_work.active = false
	_after_focus_change()
	queue_redraw()


func is_work_focused() -> bool:
	return _work_focused


# ---------------------------------------------------------------- le altre finestre

## Apre `content` in una finestra `id`, o porta davanti quella già aperta. La misura
## viene dal contenuto; la posizione dalla cascata, tenuta dentro il vetro.
func open_window(window_id: StringName, window_title: String, c: Control,
		content_bg := DesktopTheme.FIELD) -> DesktopWindow:
	var existing := window(window_id)
	if existing != null:
		focus(existing)
		return existing
	var w := DesktopWindow.new()
	var inner := c.custom_minimum_size if c != null else Vector2(200, 120)
	var dim := Vector2(inner.x + DesktopWindow.BORDER * 2.0,
			inner.y + DesktopWindow.BORDER * 2.0 + DesktopWindow.TITLE_H)
	w.setup(look, window_title, dim, window_id)
	w.content_bg = content_bg
	var area := work_area()
	var pos := FIRST_WINDOW + CASCADE * float(_cascade % 5)
	_cascade += 1
	w.position = Vector2(clampf(pos.x, 0.0, maxf(0.0, area.size.x - dim.x)),
			clampf(pos.y, 0.0, maxf(0.0, area.size.y - dim.y)))
	add_child(w)
	w.host(c)
	focus(w)
	return w


## Chiude la finestra `id` staccandone il contenuto SENZA liberarlo. Idempotente. La
## finestra di lavoro non si chiude: si nasconde.
func close_window(window_id: StringName) -> void:
	if window_id == WORK_ID:
		hide_work()
		return
	var w := window(window_id)
	if w == null:
		return
	if _drag == w:
		_drag = null
	w.release()
	remove_child(w)
	w.queue_free()
	_focus_topmost()
	queue_redraw()


func window(window_id: StringName) -> DesktopWindow:
	if window_id == WORK_ID:
		return _work if _work_open else null
	for c in get_children():
		var w := c as DesktopWindow
		if w != null and w != _work and w.id == window_id:
			return w
	return null


func is_window_open(window_id: StringName) -> bool:
	return window(window_id) != null


## Le finestre aperte, nell'ordine della pila (l'ultima è quella in cima). Chieste ai
## figli e non tenute in una lista: una seconda lista sarebbe una seconda verità, e la
## taskbar comincerebbe a mentire il giorno in cui una finestra si chiude da un'altra
## parte.
func windows() -> Array[DesktopWindow]:
	var out: Array[DesktopWindow] = []
	for c in get_children():
		var w := c as DesktopWindow
		if w == null:
			continue
		if w == _work and not _work_open:
			continue
		out.append(w)
	return out


## Il vetro meno la taskbar: dove stanno le finestre.
func work_area() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(size.x, size.y - TASKBAR_H))


# ---------------------------------------------------------------- il fuoco

## Porta davanti una finestra e le dà il fuoco. La pila è l'ordine dei figli; il
## puntatore resta sempre l'ultimo.
func focus(w: DesktopWindow) -> void:
	if w == null:
		return
	if w.minimized:
		w.minimized = false
		w.visible = true
	for other in windows():
		other.active = false
		other.queue_redraw()
	w.active = true
	move_child(w, -1)
	move_child(_pointer, -1)
	_after_focus_change()
	w.queue_redraw()
	queue_redraw()


func minimize(w: DesktopWindow) -> void:
	if _drag == w:
		_drag = null
	w.minimized = true
	w.visible = false
	w.active = false
	_focus_topmost()
	queue_redraw()


## Il fuoco va alla finestra più in alto fra quelle a schermo, o a nessuna.
func _focus_topmost() -> void:
	var list := windows()
	for i in range(list.size() - 1, -1, -1):
		if not list[i].minimized:
			focus(list[i])
			return
	for w in list:
		w.active = false
	_after_focus_change()


func _after_focus_change() -> void:
	_apply_input_focus()
	var now := _work_open and _work.active and not _work.minimized
	if now != _work_focused:
		_work_focused = now
		work_focus_changed.emit(now)


func _apply_input_focus() -> void:
	for w in windows():
		w.set_input_focus(w.active and not w.minimized)
	if not _work_open:
		_work.set_input_focus(false)


# ---------------------------------------------------------------- il puntatore

func pointer_move(delta: Vector2) -> void:
	_pointer.move(delta)
	if _drag != null and is_instance_valid(_drag):
		_move_window(_drag, _pointer.point - _grab)


func pointer_button(pressed: bool) -> void:
	if pressed:
		click(_pointer.point)
	else:
		_drag = null


## Lascia la finestra che si stava trascinando. Serve a chi si alza con il tasto giù.
func cancel_drag() -> void:
	_drag = null


## Un click sul vetro. L'ORDINE NON È ARBITRARIO: il menu Start copre tutto, la taskbar
## sta sopra le finestre, le finestre si guardano dall'alto della pila verso il basso, e
## solo alla fine il desktop — un'icona coperta da una finestra non si clicca.
func click(p: Vector2) -> void:
	if start_open:
		var chosen := start_item_at(p)
		start_open = false
		queue_redraw()
		if chosen != &"":
			_activate_icon(chosen)
		return
	if rect_start().has_point(p):
		start_open = true
		queue_redraw()
		return

	var list := windows()
	for i in list.size():
		if not rect_taskbar(i, list.size()).has_point(p):
			continue
		var w := list[i]
		if w.minimized:
			focus(w)
		elif w.active:
			# Il pulsante della finestra che hai davanti la manda giù, come in Windows.
			minimize(w)
		else:
			focus(w)
		return

	for i in range(list.size() - 1, -1, -1):
		var w := list[i]
		if w.minimized:
			continue
		var local := p - w.position
		if not Rect2(Vector2.ZERO, w.size).has_point(local):
			continue
		if w.rect_close().has_point(local):
			if w == _work:
				hide_work()
			else:
				window_close_requested.emit(w.id)
			return
		if w.rect_maximize().has_point(local):
			focus(w)
			w.toggle_maximize(work_area())
			return
		if w.rect_minimize().has_point(local):
			minimize(w)
			return
		focus(w)
		# Si trascina SOLO per la barra del titolo, e non da massimizzata: non c'è dove
		# portarla, e in Windows quella barra infatti non risponde.
		if w.rect_title().has_point(local) and not w.maximized:
			_drag = w
			_grab = local
			return
		# Il click prosegue dentro, a chi sa rispondergli.
		var inner := w.content()
		if inner != null and inner.has_method("click"):
			inner.call("click", local - inner.position)
		return

	var icon_id := icon_at(p)
	if icon_id != &"":
		_activate_icon(icon_id)
		return
	# Il vuoto del desktop toglie il fuoco a tutti, come in Windows.
	for w in list:
		w.active = false
		w.queue_redraw()
	_after_focus_change()


func _activate_icon(icon_id: StringName) -> void:
	if icon_id == WORK_ID:
		open_work()
	icon_activated.emit(icon_id)


## Sposta una finestra tenendone dentro il vetro la BARRA, non tutto il corpo: sporgere
## è normale, perdere l'unica maniglia no. In basso il limite è la taskbar.
func _move_window(w: DesktopWindow, where: Vector2) -> void:
	var area := work_area()
	w.position = Vector2(clampf(where.x, -(w.size.x - 40.0), area.size.x - 40.0),
			clampf(where.y, 0.0, area.size.y - DesktopWindow.TITLE_H))


# ---------------------------------------------------------------- geometrie

## Dove sta l'i-esima icona. Si riempie per colonne, come Windows.
func rect_icon(i: int) -> Rect2:
	var per_column := maxi(1, int((size.y - TASKBAR_H - ICON_ORIGIN.y) / ICON_STEP.y))
	var col := i / per_column
	var row := i % per_column
	return Rect2(ICON_ORIGIN + Vector2(col * ICON_STEP.x, row * ICON_STEP.y),
			Vector2(ICON, ICON + 10))


func icon_at(p: Vector2) -> StringName:
	for i in icons.size():
		if rect_icon(i).has_point(p):
			return icons[i][0]
	return &""


func rect_start() -> Rect2:
	return Rect2(2, size.y - TASKBAR_H + 4, 42, 18)


## Il pulsante dell'i-esima finestra in taskbar. Stessa formula del disegno.
func rect_taskbar(i: int, count: int) -> Rect2:
	if count <= 0:
		return Rect2()
	var room := size.x - 50.0 - 56.0
	var w := minf(76.0, room / count - 2.0)
	return Rect2(50.0 + i * (w + 2.0), size.y - TASKBAR_H + 4, w, 18)


func rect_start_menu() -> Rect2:
	var h := icons.size() * 16.0 + 6.0
	return Rect2(2, size.y - TASKBAR_H - h, 112, h)


func start_item_at(p: Vector2) -> StringName:
	var m := rect_start_menu()
	if not m.has_point(p):
		return &""
	var i := int((p.y - m.position.y - 3) / 16.0)
	if i < 0 or i >= icons.size():
		return &""
	return icons[i][0]


# ---------------------------------------------------------------- disegno

func _process(_delta: float) -> void:
	if not clock_source.is_valid():
		return
	var now: String = clock_source.call()
	if now != _clock:
		_clock = now
		queue_redraw()


func _draw() -> void:
	if look == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), DesktopTheme.DESKTOP)

	for i in icons.size():
		var r := rect_icon(i)
		_draw_icon(r.position, icons[i][2])
		var label: String = icons[i][1]
		# L'etichetta si tiene dentro il bordo: centrata e basta usciva dal vetro.
		var x := maxf(1.0, r.position.x + ICON * 0.5 - look.width(label, 9) * 0.5)
		look.text(self, Vector2(x + 1, r.position.y + 33), label, DesktopTheme.ICON_SH, 9)
		look.text(self, Vector2(x, r.position.y + 32), label, DesktopTheme.ICON_TX, 9)

	var tb := Rect2(0, size.y - TASKBAR_H, size.x, TASKBAR_H)
	draw_rect(tb, DesktopTheme.FACE)
	look.bevel(self, tb, DesktopTheme.HL, DesktopTheme.DARK)
	var st := rect_start()
	look.button(self, st, start_open)
	draw_rect(Rect2(st.position.x + 4, st.position.y + 5, 8, 8), DesktopTheme.SEL_BG)
	look.text(self, Vector2(st.position.x + 15, st.position.y + 3), "Start", DesktopTheme.INK, 10)

	var list := windows()
	for i in list.size():
		var w := list[i]
		var b := rect_taskbar(i, list.size())
		look.button(self, b, w.active and not w.minimized)
		draw_rect(Rect2(b.position.x + 4, b.position.y + 5, 8, 8), DesktopTheme.LIGHT)
		look.text(self, Vector2(b.position.x + 15, b.position.y + 3), w.title, DesktopTheme.INK, 9)

	var tray := Rect2(size.x - 52, size.y - TASKBAR_H + 4, 50, 18)
	draw_rect(tray, DesktopTheme.FACE)
	look.bevel(self, tray, DesktopTheme.SHADOW, DesktopTheme.HL)
	draw_rect(Rect2(tray.position.x + 4, tray.position.y + 5, 9, 9), DesktopTheme.SEL_BG)
	look.digits(self, Vector2(tray.position.x + 17, tray.position.y + 4), _clock, DesktopTheme.INK, 10)

	if start_open:
		_draw_start_menu()


## Il menu Start copre tutto quello che ha sotto, come l'originale; le finestre però
## sono figli e si disegnano dopo, quindi lo si porta in cima alzando lo z_index.
func _draw_start_menu() -> void:
	var m := rect_start_menu()
	draw_rect(m, DesktopTheme.FACE)
	look.bevel(self, m, DesktopTheme.HL, DesktopTheme.DARK, DesktopTheme.LIGHT, DesktopTheme.SHADOW)
	draw_rect(Rect2(m.position + Vector2(3, 3), Vector2(14, m.size.y - 6)), DesktopTheme.TITLE_A)
	for i in icons.size():
		look.text(self, Vector2(m.position.x + 22, m.position.y + 5 + i * 16.0), icons[i][1],
				DesktopTheme.INK, 10)


func _draw_icon(o: Vector2, shape: String) -> void:
	match shape:
		"telescope":
			var t := Rect2(o + Vector2(5, 11), Vector2(22, 6))
			draw_rect(t, DesktopTheme.FACE)
			look.bevel(self, t, DesktopTheme.HL, DesktopTheme.DARK)
			draw_rect(Rect2(o + Vector2(14, 17), Vector2(4, 8)), DesktopTheme.SHADOW)
			draw_rect(Rect2(o + Vector2(9, 25), Vector2(14, 3)), DesktopTheme.FACE)
		"terminal":
			var s := Rect2(o + Vector2(4, 4), Vector2(24, 18))
			draw_rect(s, DesktopTheme.FACE)
			look.bevel(self, s, DesktopTheme.HL, DesktopTheme.DARK)
			draw_rect(Rect2(o + Vector2(7, 7), Vector2(18, 12)), Phosphor.BG)
			draw_line(o + Vector2(9, 11), o + Vector2(15, 11), Phosphor.FG, 1.0)
			draw_line(o + Vector2(9, 14), o + Vector2(19, 14), Phosphor.FG, 1.0)
			draw_rect(Rect2(o + Vector2(8, 23), Vector2(16, 4)), DesktopTheme.FACE)
		"modem":
			var b := Rect2(o + Vector2(3, 12), Vector2(26, 12))
			draw_rect(b, DesktopTheme.FACE)
			look.bevel(self, b, DesktopTheme.HL, DesktopTheme.DARK)
			for k in 3:
				draw_rect(Rect2(o + Vector2(7 + k * 6, 16), Vector2(3, 3)), DesktopTheme.SEL_BG)
			draw_line(o + Vector2(16, 12), o + Vector2(16, 5), DesktopTheme.SHADOW, 1.0)
			draw_line(o + Vector2(11, 5), o + Vector2(21, 5), DesktopTheme.SHADOW, 1.0)
		"folder":
			var f := Color8(255, 222, 130)
			draw_rect(Rect2(o + Vector2(3, 6), Vector2(12, 4)), f)
			var c := Rect2(o + Vector2(3, 9), Vector2(26, 17))
			draw_rect(c, f)
			look.bevel(self, c, DesktopTheme.HL, DesktopTheme.DARK)
		_:
			draw_rect(Rect2(o + Vector2(6, 6), Vector2(20, 20)), DesktopTheme.FACE)
			look.bevel(self, Rect2(o + Vector2(6, 6), Vector2(20, 20)), DesktopTheme.HL, DesktopTheme.DARK)
