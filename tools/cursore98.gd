## La freccia del mouse, dentro il vetro.
##
## PROVVISORIO, E SOLO PER LE SONDE.
##
## SI MUOVE DI DELTA, NON DI POSIZIONE, ed è la scelta che rende la cosa possibile
## senza matematica. Il modo «giusto» sarebbe tirare un raggio dalla camera al quad,
## prendere le UV del punto colpito e convertirle in pixel del viewport — ma quel
## quad è curvo (`curve_uv` nello shader) e bombato (`glass_bulge`), quindi le UV
## geometriche non sono quelle che l'occhio vede: il cursore starebbe qualche pixel
## più in là del punto guardato, e sui bordi molto più in là. Prendendo invece il
## SOLO SPOSTAMENTO del mouse e sommandolo a una posizione tenuta qui, il puntatore
## sta sempre dove il giocatore lo ha portato — che è l'unica cosa che gli interessa.
## In cambio non c'è corrispondenza fra il mouse fisico e il punto sul vetro, e non
## serve: il mouse è catturato, un puntatore di sistema non si vede.
##
## STA SOPRA TUTTI, e per questo è un Control a sé aggiunto per ultimo invece di
## qualche riga dentro il desktop: i figli si disegnano dopo il padre, quindi una
## freccia disegnata nel `_draw()` del desktop finirebbe SOTTO le finestre.
extends Control

## La freccia di Windows: sette punti, e sono quelli. Disegnata in bianco con il
## contorno nero perché si veda sia sul teal del desktop sia sul nero di un
## programma a fosforo — che è esattamente il problema che il cursore di sistema
## risolveva così.
var PUNTA := PackedVector2Array([
	Vector2(0, 0), Vector2(0, 12), Vector2(3, 9), Vector2(5, 14),
	Vector2(7, 13), Vector2(5, 9), Vector2(9, 9),
])

var colore := Color(1, 1, 1)
var bordo := Color(0, 0, 0)
## Dove sta la punta, in pixel del viewport.
var punto := Vector2(160, 120)


func configura(dim: Vector2) -> void:
	custom_minimum_size = dim
	size = dim
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Sposta il cursore di quanto si è mosso il mouse, tenendolo dentro il vetro.
## Il clamp NON è cosmetico: senza, il puntatore se ne va fuori dallo schermo e per
## ritrovarlo si deve indovinare da che parte è uscito.
func muovi(delta: Vector2, dentro: Vector2) -> void:
	punto.x = clampf(punto.x + delta.x, 0.0, dentro.x - 1.0)
	punto.y = clampf(punto.y + delta.y, 0.0, dentro.y - 1.0)
	queue_redraw()


func _draw() -> void:
	var p := PackedVector2Array()
	for v in PUNTA:
		p.append(v + punto)
	draw_colored_polygon(p, colore)
	var chiuso := p.duplicate()
	chiuso.append(p[0])
	draw_polyline(chiuso, bordo, 1.0)
