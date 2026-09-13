## Un elenco alla Windows: righe con nome e due colonne, e la barra di stato in fondo.
##
## È UN'APPLICAZIONE, non uno strumento, quindi usa `DesktopTheme` e non il fosforo:
## un elenco di file parla con te. Non sa COSA elenca — le righe gliele dà chi lo apre.
class_name DesktopList
extends Control

const ROW_H := 15.0
## Il corpo alzato con l'interlinea: alzare l'uno senza l'altra fa toccare le righe.
const BODY := 11

var look: DesktopTheme
## Ogni riga è un array di stringhe: nome, poi fino a due colonne. Le colonne vuote
## restano vuote — un'unità disco non ha una data, e inventargliela sarebbe peggio.
var rows: Array = []
## La riga in fondo, che in Windows contava gli oggetti.
var status := ""
var cursor := -1


func setup(t: DesktopTheme, dim: Vector2) -> void:
	look = t
	custom_minimum_size = dim
	size = dim


func set_rows(new_rows: Array, empty_status := "") -> void:
	rows = new_rows
	cursor = clampi(cursor, -1, rows.size() - 1)
	_update_status(empty_status)
	queue_redraw()


func _list_rect() -> Rect2:
	return Rect2(2, 2, size.x - 4, size.y - 18)


## Un click sceglie la riga; il vuoto sotto l'ultima deseleziona, come in Windows. Torna
## vero se ha fatto qualcosa.
func click(p: Vector2) -> bool:
	var lv := _list_rect()
	if not lv.has_point(p):
		return false
	var i := int((p.y - lv.position.y - 2) / ROW_H)
	cursor = i if i >= 0 and i < rows.size() else -1
	_update_status()
	queue_redraw()
	return true


func _update_status(empty_status := "") -> void:
	if cursor < 0 or cursor >= rows.size():
		status = empty_status if empty_status != "" else "%d object(s)" % rows.size()
		return
	status = "  -  ".join(PackedStringArray(rows[cursor]))


func _draw() -> void:
	if look == null:
		return
	var lv := _list_rect()
	draw_rect(lv, DesktopTheme.FIELD)
	look.bevel(self, lv, DesktopTheme.SHADOW, DesktopTheme.HL, DesktopTheme.DARK, DesktopTheme.LIGHT)

	var y := lv.position.y + 2
	for i in rows.size():
		if y + ROW_H > lv.end.y - 2:
			break
		var row: Array = rows[i]
		var sel := i == cursor
		if sel:
			draw_rect(Rect2(lv.position.x + 2, y, lv.size.x - 4, ROW_H), DesktopTheme.SEL_BG)
		var ink: Color = DesktopTheme.INK_SEL if sel else DesktopTheme.INK
		# L'icona del file: un rettangolo col bordo. A 9 px è tutto quello che serve
		# perché una riga legga come un file.
		var o := Vector2(lv.position.x + 4, y + 3)
		draw_rect(Rect2(o, Vector2(7, 9)), DesktopTheme.FIELD)
		look.bevel(self, Rect2(o, Vector2(7, 9)), DesktopTheme.SHADOW, DesktopTheme.SHADOW)
		look.text(self, Vector2(o.x + 11, y + 1), str(row[0]), ink, BODY)
		if row.size() > 1:
			look.digits(self, Vector2(lv.position.x + lv.size.x * 0.56, y + 1), str(row[1]), ink, BODY)
		if row.size() > 2:
			look.digits(self, Vector2(lv.position.x + lv.size.x * 0.78, y + 1), str(row[2]), ink, BODY)
		y += ROW_H

	var sb := Rect2(1, size.y - 14, size.x - 2, 13)
	draw_rect(sb, DesktopTheme.FACE)
	look.bevel(self, sb, DesktopTheme.SHADOW, DesktopTheme.HL)
	look.text(self, Vector2(sb.position.x + 3, sb.position.y + 1), status, DesktopTheme.INK, 9)
