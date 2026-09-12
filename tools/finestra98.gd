## Il desktop di Windows 98, e stavolta è una SHELL, non un disegno.
##
## PROVVISORIO, E SOLO PER LE SONDE. Non è il terminale: `terminal/terminal.gd` resta
## quello che è.
##
## NASCE VUOTO, ed è la correzione del difetto peggiore della versione prima: quella
## si apriva con tre finestre già spalancate una sopra l'altra, e non si capiva né
## cosa fosse né cosa si potesse fare. Un desktop è vuoto. Le cose le apre chi lo usa,
## quando gli servono, ed è il gesto stesso di aprirle a dire che si può.
##
## COSA SA FARE E COSA NO. Sa dove stanno le sue icone e sa dire quale sta sotto un
## punto (`icona_a`); NON sa costruire i programmi, perché quelli sono fasi e pannelli
## che vivono altrove. Quando un'icona viene aperta lo ANNUNCIA e basta: chi ascolta
## decide cosa istanziare. È lo stesso confine che il progetto tiene fra `night/` e
## `world/` — chi mostra non conosce ciò che è mostrato.
##
## LE MISURE NON SONO INVENTATE: icone 32x32, taskbar 28 px, pulsante Start 42x18.
## Sono quelle di Windows 98 a 96 DPI.
extends Control

## Un'icona è stata aperta. Porta l'id, non l'etichetta: le etichette si traducono.
signal aperta(id: String)

const TASKBAR_H := 28.0
const ICONA := 32.0
## Il passo della griglia delle icone e da dove comincia.
const PASSO := Vector2(56, 44)
const ORIGINE := Vector2(6, 4)

var tema: RefCounted
## L'ORA DELLA TRAY, che è l'ora VERA della notte e non una scritta. La passa chi
## costruisce il desktop, da `night_clock.clock_text()`. È il dettaglio che costa meno
## di tutti e cambia più di tutti: un PC che sa che ore sono smette di essere il
## disegno di un PC, e l'alba la si vede arrivare nell'angolo mentre si lavora.
var ora := "21:00"

## Le icone: id, etichetta, forma. L'id è quello che viaggia nel segnale.
##
## TRE, E NON OTTO. La versione prima ne aveva otto e il desktop sembrava pieno di
## cose da fare che non si potevano fare. Queste tre sono il lavoro intero di una
## notte: si fotografa (MaxIm DL), si guarda cosa è venuto (Photos), e si sta in
## contatto col mondo — comprare, leggere, vendere (Internet). Il resto erano icone
## di sistema che non aprivano niente di utile.
##
## DICONO COSA C'È DENTRO QUEL COMPUTER prima ancora che tu apra qualcosa, ed è la
## ragione migliore per volere un desktop invece di una schermata sola: il software di
## lavoro del 1999 sta lì, in fila, e si legge come si legge una scrivania.
## Il menu Start, aperto o chiuso. Le voci sono le stesse icone del desktop più
## l'uscita: in Windows tutto quello che c'era sul desktop si raggiungeva anche da lì,
## ed era il punto del pulsante.
var start_aperto := false

var icone := [
	["maxim", "MaxIm DL", "telescopio"],
	["internet", "Internet", "modem"],
	["photos", "Photos", "cartella"],
]


func configura(t: RefCounted, dim: Vector2) -> void:
	tema = t
	custom_minimum_size = dim
	size = dim


## Dove sta l'i-esima icona. La griglia si riempie per COLONNE e non per righe, come
## quella di Windows: si scende fino in fondo e poi si ricomincia da capo a destra.
func rect_icona(i: int) -> Rect2:
	var per_colonna := int((size.y - TASKBAR_H - ORIGINE.y) / PASSO.y)
	var col := i / per_colonna
	var rig := i % per_colonna
	return Rect2(ORIGINE + Vector2(col * PASSO.x, rig * PASSO.y), Vector2(ICONA, ICONA + 10))


## Quale icona sta sotto questo punto, o "" se nessuna.
func icona_a(p: Vector2) -> String:
	for i in icone.size():
		if rect_icona(i).has_point(p):
			return icone[i][0]
	return ""


## Le finestre aperte, chieste ai figli invece che tenute in una lista a parte: una
## seconda lista sarebbe una seconda verità da tenere allineata, e la taskbar
## comincerebbe a mentire il giorno in cui qualcuno chiude una finestra e scorda di
## aggiornarla.
func finestre() -> Array:
	var v := []
	for c in get_children():
		if c is Control and c.has_method("rect_chiudi"):
			v.append(c)
	return v


func rect_start() -> Rect2:
	return Rect2(2, size.y - TASKBAR_H + 4, 42, 18)


## Il pulsante dell'i-esima finestra nella taskbar. Stessa formula del disegno: se le
## due divergessero si cliccherebbe un pulsante e ne risponderebbe un altro.
func rect_taskbar(i: int, quante: int) -> Rect2:
	if quante <= 0:
		return Rect2()
	var spazio := size.x - 54.0 - 54.0
	var largo := minf(64.0, spazio / quante - 2.0)
	return Rect2(52.0 + i * (largo + 2.0), size.y - TASKBAR_H + 4, largo, 18)


## Le voci del menu Start: le stesse icone, più la chiusura del menu.
func voci_start() -> Array:
	var v := []
	for ic in icone:
		v.append([ic[0], ic[1]])
	v.append(["_chiudi_menu", "Shut Down..."])
	return v


func rect_menu() -> Rect2:
	var voci := voci_start()
	var alto := voci.size() * 16.0 + 6.0
	return Rect2(2, size.y - TASKBAR_H - alto, 108, alto)


## Quale voce del menu sta sotto il punto, o "" se nessuna.
func voce_start_a(p: Vector2) -> String:
	if not start_aperto:
		return ""
	var m := rect_menu()
	if not m.has_point(p):
		return ""
	var i := int((p.y - m.position.y - 3) / 16.0)
	var voci := voci_start()
	if i < 0 or i >= voci.size():
		return ""
	return voci[i][0]


func _icona(o: Vector2, quale: String) -> void:
	match quale:
		"computer":
			var b := Rect2(o + Vector2(4, 3), Vector2(24, 17))
			draw_rect(b, tema.FACE)
			tema.rilievo(self, b, tema.HL, tema.DARK)
			draw_rect(Rect2(o + Vector2(7, 6), Vector2(18, 11)), tema.SELBG)
			draw_rect(Rect2(o + Vector2(11, 20), Vector2(10, 3)), tema.SHADOW)
			var p := Rect2(o + Vector2(6, 23), Vector2(20, 4))
			draw_rect(p, tema.FACE)
			tema.rilievo(self, p, tema.HL, tema.DARK)
		"cartella":
			draw_rect(Rect2(o + Vector2(3, 5), Vector2(12, 4)), tema.LIGHT)
			var c := Rect2(o + Vector2(3, 8), Vector2(26, 17))
			draw_rect(c, tema.LIGHT)
			tema.rilievo(self, c, tema.HL, tema.DARK)
		"dischetto":
			draw_rect(Rect2(o + Vector2(4, 3), Vector2(24, 24)), tema.SHADOW)
			draw_rect(Rect2(o + Vector2(9, 4), Vector2(14, 9)), tema.FIELD)
			draw_rect(Rect2(o + Vector2(8, 17), Vector2(16, 9)), tema.FACE)
		"telescopio":
			var t := Rect2(o + Vector2(5, 11), Vector2(22, 6))
			draw_rect(t, tema.FACE)
			tema.rilievo(self, t, tema.HL, tema.DARK)
			draw_rect(Rect2(o + Vector2(14, 17), Vector2(4, 8)), tema.SHADOW)
			draw_rect(Rect2(o + Vector2(9, 25), Vector2(14, 3)), tema.FACE)
		"cupola":
			# Una semisfera sopra una base: la cupola vista da fuori.
			var centro := o + Vector2(16, 20)
			for r in range(11, 0, -1):
				draw_arc(centro, float(r), PI, TAU, 14, tema.FACE if r > 8 else tema.LIGHT, 2.0)
			draw_rect(Rect2(o + Vector2(4, 20), Vector2(24, 5)), tema.FACE)
			tema.rilievo(self, Rect2(o + Vector2(4, 20), Vector2(24, 5)), tema.HL, tema.DARK)
			draw_line(o + Vector2(16, 10), o + Vector2(16, 20), tema.DARK, 1.0)
		"modem":
			var b := Rect2(o + Vector2(3, 12), Vector2(26, 12))
			draw_rect(b, tema.FACE)
			tema.rilievo(self, b, tema.HL, tema.DARK)
			for k in 3:
				draw_rect(Rect2(o + Vector2(7 + k * 6, 16), Vector2(3, 3)), tema.SELBG)
			draw_line(o + Vector2(16, 12), o + Vector2(16, 5), tema.SHADOW, 1.0)
			draw_line(o + Vector2(11, 5), o + Vector2(21, 5), tema.SHADOW, 1.0)
		"libro":
			var b := Rect2(o + Vector2(5, 4), Vector2(22, 24))
			draw_rect(b, tema.FIELD)
			tema.rilievo(self, b, tema.DARK, tema.DARK)
			for k in 4:
				draw_line(o + Vector2(8, 9 + k * 5), o + Vector2(24, 9 + k * 5), tema.SHADOW, 1.0)
		"cestino":
			var l := Rect2(o + Vector2(8, 6), Vector2(16, 3))
			draw_rect(l, tema.FACE)
			tema.rilievo(self, l, tema.HL, tema.DARK)
			var v := Rect2(o + Vector2(9, 9), Vector2(14, 18))
			draw_rect(v, tema.FACE)
			tema.rilievo(self, v, tema.HL, tema.DARK)
			for k in 3:
				draw_line(o + Vector2(12 + k * 4, 12), o + Vector2(12 + k * 4, 24), tema.SHADOW, 1.0)


## Il testo sotto un'icona: centrato sui 32 px, con l'ombra di un pixel dietro.
## SI TIENE DENTRO IL BORDO: un'etichetta più larga della sua icona, centrata e basta,
## usciva dal vetro a sinistra e si perdeva.
func _etichetta(o: Vector2, s: String) -> void:
	var x := maxf(1.0, o.x + ICONA * 0.5 - tema.largo(s, 9) * 0.5)
	tema.testo(self, Vector2(x + 1, o.y + 33), s, tema.ICONSH, 9)
	tema.testo(self, Vector2(x, o.y + 32), s, tema.ICONTX, 9)


func _draw() -> void:
	if tema == null:
		return
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), tema.DESKTOP)

	for i in icone.size():
		var r := rect_icona(i)
		_icona(r.position, icone[i][2])
		_etichetta(r.position, icone[i][1])

	# --- LA TASKBAR: Start, l'avvio veloce, i pulsanti delle finestre aperte, e la
	# tray con l'ora. Senza la tray non è la taskbar del '98.
	var tbb := Rect2(0, h - TASKBAR_H, w, TASKBAR_H)
	draw_rect(tbb, tema.FACE)
	tema.rilievo(self, tbb, tema.HL, tema.DARK)

	var stb := rect_start()
	tema.pulsante(self, stb, start_aperto)
	draw_rect(Rect2(stb.position.x + 4, stb.position.y + 5, 8, 8), tema.SELBG)
	tema.testo(self, Vector2(stb.position.x + 15, stb.position.y + 3), "Start", tema.INK, 10)

	draw_line(Vector2(47.5, h - TASKBAR_H + 5), Vector2(47.5, h - 6), tema.SHADOW, 1.0)
	draw_line(Vector2(48.5, h - TASKBAR_H + 5), Vector2(48.5, h - 6), tema.HL, 1.0)

	# I pulsanti delle finestre. Quello della finestra col fuoco è INCASSATO: è lo
	# stesso segno della barra del titolo accesa, ripetuto in fondo allo schermo.
	var lista := finestre()
	for i in lista.size():
		var f: Control = lista[i]
		var b := rect_taskbar(i, lista.size())
		# Incassato se ha il fuoco ED è a schermo: una finestra ridotta a icona non ha
		# il fuoco anche quando è l'ultima che hai toccato.
		tema.pulsante(self, b, f.attiva and not f.minimizzata)
		draw_rect(Rect2(b.position.x + 4, b.position.y + 5, 8, 8), tema.LIGHT)
		tema.testo(self, Vector2(b.position.x + 15, b.position.y + 3), f.titolo, tema.INK, 9)

	if start_aperto:
		_disegna_menu()

	var tray := Rect2(w - 50, h - TASKBAR_H + 4, 48, 18)
	draw_rect(tray, tema.FACE)
	tema.rilievo(self, tray, tema.SHADOW, tema.HL)
	draw_rect(Rect2(tray.position.x + 4, tray.position.y + 5, 9, 9), tema.SELBG)
	tema.cifre(self, Vector2(tray.position.x + 17, tray.position.y + 4), ora, tema.INK, 10)


## Il menu Start aperto. Si disegna DOPO le finestre e prima della tray: in Windows
## copriva tutto quello che aveva sotto, ed era l'unica cosa a farlo insieme ai modali.
func _disegna_menu() -> void:
	var m := rect_menu()
	draw_rect(m, tema.FACE)
	tema.rilievo(self, m, tema.HL, tema.DARK, tema.LIGHT, tema.SHADOW)
	# La banda blu verticale a sinistra, che è la firma di quel menu.
	draw_rect(Rect2(m.position + Vector2(3, 3), Vector2(14, m.size.y - 6)), tema.TITLE_A)
	var voci := voci_start()
	for i in voci.size():
		var y := m.position.y + 3 + i * 16.0
		tema.testo(self, Vector2(m.position.x + 22, y + 2), voci[i][1], tema.INK, 10)
		if i == voci.size() - 2:
			var sy := y + 15.0
			draw_line(Vector2(m.position.x + 20, sy), Vector2(m.position.x + m.size.x - 4, sy),
					tema.SHADOW, 1.0)
