## La freccia del mouse, dentro il vetro.
##
## SI MUOVE DI SPOSTAMENTO, NON DI POSIZIONE, ed è la scelta che rende possibile un
## puntatore senza il raycast che ADR-003 rinvia. Il modo canonico tirerebbe un raggio
## dalla camera al quad e convertirebbe le UV del punto colpito in pixel — ma quel vetro
## è curvo nello shader (`curve_uv`) e bombato nella mesh (`glass_bulge`), quindi le UV
## geometriche non stanno dove l'occhio le vede: il puntatore finirebbe accanto al
## punto guardato, e sui bordi parecchio accanto. Sommando invece lo spostamento del
## mouse a una posizione tenuta qui, la freccia sta sempre dove la si è portata. In
## cambio non c'è corrispondenza col mouse fisico, e non serve: da seduti il mouse è
## catturato e un puntatore di sistema non si vede.
##
## STA SOPRA TUTTI, ed è per questo un Control a sé tenuto per ultimo fra i figli del
## desktop: i figli si disegnano dopo il padre.
class_name DesktopPointer
extends Control

## La freccia di Windows, sette punti.
var _shape := PackedVector2Array([
	Vector2(0, 0), Vector2(0, 12), Vector2(3, 9), Vector2(5, 14),
	Vector2(7, 13), Vector2(5, 9), Vector2(9, 9),
])

## Dove sta la punta, in pixel del viewport.
var point := Vector2.ZERO


func setup(dim: Vector2) -> void:
	size = dim
	point = (dim * 0.5).floor()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Il limite NON è cosmetico: senza, il puntatore esce dal vetro e per ritrovarlo si
## deve indovinare da che parte è uscito.
func move(delta: Vector2) -> void:
	point = Vector2(clampf(point.x + delta.x, 0.0, size.x - 1.0),
			clampf(point.y + delta.y, 0.0, size.y - 1.0))
	queue_redraw()


func _draw() -> void:
	var p := PackedVector2Array()
	for v in _shape:
		p.append(v + point)
	# Bianca col bordo nero, perché si veda sul teal del desktop come sul nero di un
	# programma a fosforo: è il problema che il cursore di sistema risolveva così.
	draw_colored_polygon(p, Color(1, 1, 1))
	var closed := p.duplicate()
	closed.append(p[0])
	draw_polyline(closed, Color(0, 0, 0), 1.0)
