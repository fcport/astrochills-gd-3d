## Il modale di sistema: la finestrella che si apre da sola e aspetta un OK.
##
## PROVVISORIO, E SOLO PER LE SONDE. Sta dentro una `cornice98` senza pulsanti, come
## i modali veri: non si minimizza e non si ridimensiona, si risponde e basta.
##
## È LA COSA CHE IL FOSFORO NON POTEVA DARE, ed è la ragione non tecnica per volere
## un sistema a finestre in un gioco che ha paura addosso. Un terminale scrive una
## riga in più in fondo e tu la leggi quando arrivi a leggerla; un sistema operativo
## ti mette una finestra DAVANTI a quello che stavi facendo, ci appoggia un suono, e
## resta lì finché non la tocchi. Non è più informazione: è interruzione, e
## l'interruzione la decide la macchina.
##
## IL TESTO È IN INGLESE (NFR10): l'interfaccia delle macchine parla inglese, le
## persone e la narrativa parlano italiano.
extends Control

var tema: RefCounted
var righe := ["CCDOPS: sequence complete.", "Frame 24 of 23 saved to disk."]


## Il pulsante OK, in coordinate locali. Stessa formula del disegno: se divergessero,
## si cliccherebbe il pulsante e non risponderebbe.
func rect_ok() -> Rect2:
	return Rect2((size.x - 44) * 0.5, size.y - 20, 44, 17)


## Torna vero se il click e caduto sull OK. Chi chiama chiude la finestra: un modale
## non si chiude da se, lo chiude chi lo ha aperto.
func clic(p: Vector2) -> bool:
	return rect_ok().has_point(p)


func configura(t: RefCounted, dim: Vector2) -> void:
	tema = t
	custom_minimum_size = dim
	size = dim


## Il triangolo d'avviso, disegnato a mano: tre linee e il punto esclamativo. A 16 px
## l'icona vera era comunque una manciata di pixel, e il pack d'arte la sostituirà.
func _triangolo(o: Vector2) -> void:
	var p := PackedVector2Array([o + Vector2(8, 1), o + Vector2(15, 14), o + Vector2(1, 14)])
	draw_colored_polygon(p, tema.WARN)
	draw_polyline(PackedVector2Array([p[0], p[1], p[2], p[0]]), tema.DARK, 1.0)
	draw_line(o + Vector2(8, 5), o + Vector2(8, 10), tema.DARK, 1.0)
	draw_line(o + Vector2(8, 11.5), o + Vector2(8, 12.5), tema.DARK, 1.0)


func _draw() -> void:
	if tema == null:
		return
	_triangolo(Vector2(6, 6))
	var y := 4.0
	for r in righe:
		tema.testo(self, Vector2(28, y), r, tema.INK, 10)
		y += 12
	var b := rect_ok()
	tema.pulsante(self, b)
	tema.testo(self, Vector2(b.position.x + (44 - tema.largo("OK", 10)) * 0.5,
			b.position.y + 3), "OK", tema.INK, 10)
	# Il rettangolo tratteggiato del fuoco dentro il pulsante: era il segno che il
	# tasto INVIO andava lì, e a schermo pesa quattro linee.
	var f := b.grow(-3)
	tema.rilievo(self, f, tema.SHADOW, tema.SHADOW)
