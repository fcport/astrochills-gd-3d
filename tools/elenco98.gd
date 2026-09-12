## Una finestra di elenco: file, unità, cestino. Il contenuto glielo si dà.
##
## PROVVISORIO, E SOLO PER LE SONDE. Sta dentro una `cornice98` e per questo non
## disegna né barra del titolo né bordi: sa solo di essere un programma dentro una
## finestra, e la finestra la mette qualcun altro.
##
## È UN'APPLICAZIONE WINDOWS, non uno strumento, e quindi usa `tema98` e non il
## fosforo: la regola sta in testa a `tools/tema98.gd` — i programmi che parlano con
## le macchine sono monocromatici, quelli che parlano con te sono Windows. Un elenco
## di file parla con te.
##
## PERCHÉ UNO SOLO PER TRE FINESTRE. «Photos», «My Computer» e il cestino sono la
## stessa cosa con dentro righe diverse, e lo erano anche in Windows: una vista a
## elenco con un'icona, un nome e due colonne. Farne tre copie sarebbe stato copiare
## lo stesso `_draw()` tre volte per cambiare un array.
extends Control

const RIGA_H := 15.0
## Il corpo del testo, alzato con l interlinea per la stessa ragione di `internet98`.
const CORPO := 11

var tema: RefCounted
## Le righe: nome, dimensione, data. Le colonne vuote si lasciano vuote — un elenco
## di unità non ha una data, e mettercene una finta sarebbe peggio che non averla.
var righe := []
## La riga in fondo, che in Windows contava gli oggetti e diceva quanto pesavano.
var stato := ""
var cursore := -1


## Un click sulla lista sceglie la riga. Senza, «Photos» era una vetrina: si vedevano
## i file e non si poteva nemmeno indicarne uno.
func clic(p: Vector2) -> bool:
	var lv := _rect_lista()
	if not lv.has_point(p):
		return false
	var i := int((p.y - lv.position.y - 2) / RIGA_H)
	if i < 0 or i >= righe.size():
		# Il vuoto sotto l'ultima riga deseleziona, come in Windows.
		cursore = -1
		_stato_riga()
		return true
	cursore = i
	_stato_riga()
	return true


## La barra di stato dice cosa hai scelto, che è il motivo per cui una selezione serve.
func _stato_riga() -> void:
	if cursore < 0 or cursore >= righe.size():
		stato = "%d object(s)" % righe.size()
		return
	var r: Array = righe[cursore]
	var pezzi := [str(r[0])]
	if r.size() > 1:
		pezzi.append(str(r[1]))
	if r.size() > 2:
		pezzi.append(str(r[2]))
	stato = "  -  ".join(pezzi)


func _rect_lista() -> Rect2:
	return Rect2(2, 16, size.x - 4, size.y - 32)


func configura(t: RefCounted, dim: Vector2) -> void:
	tema = t
	custom_minimum_size = dim
	size = dim


func _draw() -> void:
	if tema == null:
		return
	var w := size.x
	var h := size.y

	var mx := 3.0
	for m in ["File", "Edit", "View"]:
		tema.testo(self, Vector2(mx, 2), m, tema.INK, 10)
		mx += tema.largo(m, 10) + 10

	var lv := _rect_lista()
	draw_rect(lv, tema.FIELD)
	tema.rilievo(self, lv, tema.SHADOW, tema.HL, tema.DARK, tema.LIGHT)

	var ry := lv.position.y + 2
	for i in righe.size():
		if ry + RIGA_H > lv.position.y + lv.size.y - 2:
			break
		var sel := i == cursore
		if sel:
			draw_rect(Rect2(lv.position.x + 2, ry, lv.size.x - 4, RIGA_H), tema.SELBG)
		var tc: Color = tema.INK_SEL if sel else tema.INK
		# L'icona del file: due tratti e una piega d'angolo. A 9 px è tutto quello che
		# ci sta, ed è tutto quello che serve perché una riga legga come un file.
		var o := Vector2(lv.position.x + 4, ry + 2)
		draw_rect(Rect2(o, Vector2(7, 9)), tema.FIELD)
		tema.rilievo(self, Rect2(o, Vector2(7, 9)), tema.SHADOW, tema.SHADOW)
		tema.testo(self, Vector2(o.x + 11, ry + 1), righe[i][0], tc, CORPO)
		if righe[i].size() > 1:
			tema.cifre(self, Vector2(lv.position.x + lv.size.x * 0.54, ry + 1),
					righe[i][1], tc, CORPO)
		if righe[i].size() > 2:
			tema.cifre(self, Vector2(lv.position.x + lv.size.x * 0.76, ry + 1),
					righe[i][2], tc, CORPO)
		ry += RIGA_H

	var sb := Rect2(1, h - 14, w - 2, 13)
	draw_rect(sb, tema.FACE)
	tema.rilievo(self, sb, tema.SHADOW, tema.HL)
	tema.testo(self, Vector2(sb.position.x + 3, sb.position.y + 1), stato, tema.INK, 10)
