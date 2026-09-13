## Una finestra di Windows 98: il chrome, e dentro un Control che non sa di esserci.
##
## È IL PEZZO CHE RENDE ECONOMICA TUTTA LA STRADA DEL DESKTOP. Le fasi, il terminale, la
## BBS, il menu post-foto disegnano già un `Control` da 256x192. Una finestra che lo
## prende così com'è e ci mette attorno barra del titolo e bordi li trasforma in
## programmi SENZA TOCCARLI: si incorniciano, non si riscrivono.
##
## LA MISURA LA DETTA IL CONTENUTO. Le schermate si impongono 256x192 in `_ready()` e
## sono disegnate a coordinate fisse: stirarle non le adatterebbe, le romperebbe. Qui
## il contenuto si centra nell'area utile e resta della sua misura; se l'area è più
## grande, attorno c'è il fondo del programma.
##
## LA PROPRIETÀ NON CAMBIA. Come per il CRT prima del desktop, la finestra non libera
## MAI ciò che mostra: `release()` lo stacca e lo restituisce, e lo libera chi l'ha
## creato. È la regola di `core/phase.gd` e dell'orchestratore, e non si riscrive qui.
##
## LE MISURE SONO QUELLE DI WINDOWS 98 A 96 DPI: bordo 4 px, barra del titolo 18,
## pulsanti 16x14.
class_name DesktopWindow
extends Control

const BORDER := 4.0
const TITLE_H := 18.0
const BUTTON := Vector2(16, 14)
## La fila delle schede, quando la finestra ne ha. È del software di ripresa: una
## scheda per fase del piano.
const TABS_H := 15.0

## Non si chiama `theme`, che è già una proprietà di `Control` e verrebbe oscurata.
var look: DesktopTheme
var title := ""
## Chi è, senza confrontare stringhe di titolo.
var id: StringName = &""
## Il FUOCO: la finestra che riceve i tasti ha la barra accesa.
var active := false
var has_buttons := true
var maximized := false
## Ridotta a icona: sparisce dal vetro ma resta in taskbar, da cui si riprende.
var minimized := false
## Il fondo dell'area utile. I programmi a fosforo lo vogliono nero-bruno: un bordo
## grigio attorno a un pannello monocromatico si legge come uno sbaglio.
var content_bg: Color = DesktopTheme.FIELD

## Le etichette delle schede e quale è in corso. Prima di `current` sono fatte, dopo
## sono ancora da fare e restano spente. `current` fuori dall'intervallo vuol dire
## «nessuna in corso»: tutte fatte se oltre la fine, tutte neutre se negativo.
var tabs := PackedStringArray()
var current_tab := -1

var _content: Control
var _restore_pos := Vector2.ZERO
var _restore_size := Vector2.ZERO


func setup(t: DesktopTheme, window_title: String, dim: Vector2, window_id: StringName,
		buttons := true) -> void:
	look = t
	title = window_title
	id = window_id
	has_buttons = buttons
	custom_minimum_size = dim
	size = dim
	# Quello che eccede l'area utile si taglia, e si vede che è tagliato.
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## L'area utile, in coordinate locali: tolti bordi, barra del titolo e schede.
func client_rect() -> Rect2:
	var top := BORDER + TITLE_H + (TABS_H if not tabs.is_empty() else 0.0)
	return Rect2(BORDER, top, size.x - BORDER * 2.0, size.y - top - BORDER)


func rect_title() -> Rect2:
	return Rect2(3, 3, size.x - 6, TITLE_H)


func rect_close() -> Rect2:
	if not has_buttons:
		return Rect2()
	return Rect2(size.x - 5 - BUTTON.x, 5, BUTTON.x, BUTTON.y)


func rect_maximize() -> Rect2:
	if not has_buttons:
		return Rect2()
	return Rect2(rect_close().position - Vector2(BUTTON.x, 0), BUTTON)


func rect_minimize() -> Rect2:
	if not has_buttons:
		return Rect2()
	return Rect2(rect_maximize().position - Vector2(BUTTON.x, 0), BUTTON)


## La scheda i-esima. Larghe secondo l'etichetta e non tutte uguali: otto schede
## uguali in 290 px sono 36 px l'una, e «TARGET» non ci entra.
func rect_tab(i: int) -> Rect2:
	if i < 0 or i >= tabs.size():
		return Rect2()
	var widths := _tab_widths()
	var x := BORDER
	for k in i:
		x += widths[k]
	return Rect2(x, BORDER + TITLE_H, widths[i], TABS_H)


func _tab_widths() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var avail := size.x - BORDER * 2.0
	var natural := 0.0
	for label in tabs:
		natural += look.width(label, 9) + 8.0
	var extra := maxf(0.0, avail - natural) / maxf(1.0, tabs.size())
	for label in tabs:
		out.append(look.width(label, 9) + 8.0 + extra)
	return out


func content() -> Control:
	return _content


## Mette un Control dentro la finestra, staccando quello di prima SENZA liberarlo.
func host(c: Control) -> void:
	if _content == c:
		layout_content()
		return
	release()
	_content = c
	if c == null:
		queue_redraw()
		return
	if c.get_parent() != null:
		c.reparent(self)
	else:
		add_child(c)
	layout_content()
	queue_redraw()


## Stacca il contenuto e lo restituisce. Non lo libera: non è suo.
func release() -> Control:
	var c := _content
	_content = null
	if c != null and is_instance_valid(c) and c.get_parent() == self:
		remove_child(c)
	return c


## Piazza il contenuto: della SUA misura, centrato. Le ancore si azzerano perché chi lo
## ha mostrato prima poteva averlo steso a tutto il vetro.
func layout_content() -> void:
	if _content == null or not is_instance_valid(_content):
		return
	var area := client_rect()
	var want := _content.custom_minimum_size
	if want.x <= 0.0 or want.y <= 0.0:
		want = area.size
	_content.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_content.size = want
	var offset := ((area.size - want) * 0.5).floor()
	_content.position = area.position + Vector2(maxf(0.0, offset.x), maxf(0.0, offset.y))


## Chi riceve i tasti. Si spengono gli `_unhandled_input` di tutto il contenuto quando
## la finestra non ha il fuoco: nello stesso viewport ci sono più programmi, e una
## freccia premuta per il terminale non deve muovere il cursore del menu post-foto
## che sta sotto. Si toccano solo i nodi che quell'ingresso ce l'hanno davvero.
func set_input_focus(on: bool) -> void:
	if _content != null and is_instance_valid(_content):
		_set_input(_content, on)


func _set_input(n: Node, on: bool) -> void:
	if n.has_method("_unhandled_input"):
		n.set_process_unhandled_input(on)
	if n.has_method("_input"):
		n.set_process_input(on)
	for child in n.get_children():
		_set_input(child, on)


## A tutto schermo dentro `area`, o di nuovo com'era. `area` è il vetro MENO la
## taskbar: una finestra massimizzata arriva fino alla taskbar e non ci passa sotto.
func toggle_maximize(area: Rect2) -> void:
	var target_pos := area.position
	var target_size := area.size
	if maximized:
		target_pos = _restore_pos
		target_size = _restore_size
	else:
		_restore_pos = position
		_restore_size = size
	# LA MISURA MINIMA PRIMA DELLA MISURA. Un Control non può essere più piccolo del suo
	# `custom_minimum_size`: impostando prima `size`, il ritorno da massimizzata veniva
	# gonfiato alla misura del vetro e la finestra usciva a destra, con i pulsanti fuori.
	# Visto nello scatto della sonda — che controllava il flag e non la misura.
	custom_minimum_size = target_size
	size = target_size
	position = target_pos
	maximized = not maximized
	layout_content()
	queue_redraw()


func _draw() -> void:
	if look == null:
		return
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, DesktopTheme.FACE)
	look.bevel(self, r, DesktopTheme.HL, DesktopTheme.DARK, DesktopTheme.LIGHT, DesktopTheme.SHADOW)

	var bar := rect_title()
	if active:
		for i in range(int(bar.position.x), int(bar.end.x)):
			var t := float(i - bar.position.x) / maxf(1.0, bar.size.x)
			draw_line(Vector2(i + 0.5, bar.position.y), Vector2(i + 0.5, bar.end.y),
					DesktopTheme.TITLE_A.lerp(DesktopTheme.TITLE_B, t), 1.0)
	else:
		draw_rect(bar, DesktopTheme.TITLE_OFF)
	draw_rect(Rect2(bar.position.x + 2, bar.position.y + 3, 12, 12), DesktopTheme.LIGHT)
	look.text(self, Vector2(bar.position.x + 18, bar.position.y + 3), title,
			DesktopTheme.TITLE_TX if active else DesktopTheme.TITLE_TX_OFF)

	if has_buttons:
		# Il segno di mezzo dice cosa FARÀ il pulsante, come in Windows.
		var marks := ["_", "=" if maximized else "O", "X"]
		var rects := [rect_minimize(), rect_maximize(), rect_close()]
		for i in 3:
			var b: Rect2 = rects[i]
			look.button(self, b)
			look.text(self, Vector2(b.position.x + 5, b.position.y + 1), marks[i], DesktopTheme.INK)

	for i in tabs.size():
		_draw_tab(i)

	var c := client_rect()
	draw_rect(c, content_bg)
	look.bevel(self, c.grow(1), DesktopTheme.SHADOW, DesktopTheme.HL)


## Una scheda. Quella in corso è incassata e scritta scura; le fatte normali; quelle
## ancora da fare spente — si vedono, così si sa cosa manca, ma non invitano.
func _draw_tab(i: int) -> void:
	var r := rect_tab(i)
	var here := i == current_tab
	look.button(self, r, here)
	var locked := current_tab >= 0 and i > current_tab
	var ink: Color = DesktopTheme.GRAY_TX if locked else DesktopTheme.INK
	var label := tabs[i]
	look.text(self, Vector2(r.position.x + (r.size.x - look.width(label, 9)) * 0.5,
			r.position.y + (3.0 if here else 2.0)), label, ink, 9)
