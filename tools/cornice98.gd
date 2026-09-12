## Una finestra di Windows 98: il chrome, e dentro quello che gli si dà.
##
## PROVVISORIO, E SOLO PER LE SONDE — ma è il pezzo che conta, perché è il prototipo
## della cosa che renderebbe economica tutta la strada del desktop.
##
## PERCHÉ ESISTE. Le nove fasi della notte espongono già `screen() -> Control`, e oggi
## quel Control va a tutto schermo sul vetro. Se una finestra è un contenitore che
## prende un Control qualunque e ci disegna attorno barra del titolo e bordi, allora
## le fasi diventano programmi SENZA CHE NESSUNA FASE CAMBI: si incorniciano, non si
## riscrivono. È la differenza fra un pomeriggio e un mese.
##
## IL LIMITE CHE LA PROVA HA TROVATO, e va detto prima che qualcuno ci sbatta:
## `phases/imaging/imaging_screen.gd` si impone `256x192` in `_ready()`, e così fanno
## le sorelle. Dentro una client area più piccola vengono TAGLIATE, non adattate —
## qui il taglio è dichiarato (`clip_contents`) e si vede. Perché le fasi stiano
## davvero in finestra devono accettare la dimensione da chi le contiene invece di
## dettarla: è una riga per schermata, ma sono nove schermate.
##
## LE MISURE NON SONO INVENTATE: bordo 4 px, barra del titolo 18, pulsanti 16x14.
## Sono quelle di Windows 98 a 96 DPI.
extends Control

signal chiusa(quale: Control)

const BORDO := 4.0
const TITOLO_H := 18.0
const BOTTONE := Vector2(16, 14)

var tema: RefCounted
var titolo := ""
## L'id del programma, per sapere chi è senza confrontare stringhe di titolo.
var id := ""
## Il FUOCO. In Windows la finestra che riceve i tasti ha la barra colorata e le
## altre ce l'hanno spenta: è l'unico segno che dice a chi vanno a finire i tasti, e
## senza di lui due finestre aperte sono due disegni sovrapposti.
var attiva := true
## I tre pulsanti a destra. Un modale non li ha: si chiude col suo bottone.
var bottoni := true
## A tutto schermo. Sotto ci sono la posizione e la misura di prima: senza tenerle,
## il pulsante saprebbe solo andare e non tornare.
var massimizzata := false
## Ridotta a icona: sparisce dallo schermo ma resta nella taskbar, ed è da lì che si
## riprende. Una finestra minimizzata che sparisse anche dalla taskbar sarebbe chiusa.
var minimizzata := false
var _prima_pos := Vector2.ZERO
var _prima_dim := Vector2.ZERO


func configura(t: RefCounted, tit: String, dim: Vector2, chi := "", bot := true) -> void:
	tema = t
	titolo = tit
	id = chi
	bottoni = bot
	custom_minimum_size = dim
	size = dim
	# Quello che eccede la client area si taglia, e si vede che è tagliato.
	clip_contents = true


## L'area utile, in coordinate locali. È quanto resta tolti i bordi e la barra.
func area_client() -> Rect2:
	return Rect2(BORDO, BORDO + TITOLO_H,
			size.x - BORDO * 2.0, size.y - BORDO * 2.0 - TITOLO_H)


## Il pulsante di chiusura, in coordinate LOCALI. Serve al desktop per sapere se un
## click ci è caduto dentro: è l'unica parte del chrome che fa qualcosa.
func rect_chiudi() -> Rect2:
	if not bottoni:
		return Rect2()
	return Rect2(size.x - 3 - 2 - BOTTONE.x, 3 + 2, BOTTONE.x, BOTTONE.y)


## Il pulsante di mezzo: a tutto schermo e ritorno. Sta a sinistra della chiusura,
## come in Windows.
func rect_massimizza() -> Rect2:
	if not bottoni:
		return Rect2()
	var r := rect_chiudi()
	return Rect2(r.position - Vector2(BOTTONE.x, 0), r.size)


## Va a tutto schermo dentro l'area data, o torna com'era.
##
## `dentro` è lo spazio utile del desktop — lo schermo MENO la taskbar — perché in
## Windows una finestra massimizzata arriva fino alla taskbar e non ci passa sotto:
## la taskbar resta visibile, ed è l'unica cosa che non si può coprire.
func massimizza(dentro: Rect2) -> void:
	if massimizzata:
		position = _prima_pos
		size = _prima_dim
		custom_minimum_size = _prima_dim
	else:
		_prima_pos = position
		_prima_dim = size
		position = dentro.position
		size = dentro.size
		custom_minimum_size = dentro.size
	massimizzata = not massimizzata
	queue_redraw()


## Il pulsante di sinistra dei tre: riduce a icona.
func rect_minimizza() -> Rect2:
	if not bottoni:
		return Rect2()
	var r := rect_massimizza()
	return Rect2(r.position - Vector2(BOTTONE.x, 0), r.size)


## La barra del titolo, per il trascinamento e per portare avanti la finestra.
func rect_titolo() -> Rect2:
	return Rect2(3, 3, size.x - 6, TITOLO_H)


## Mette un Control dentro la finestra. Non gli si tocca la dimensione di proposito:
## se non ci sta, deve VEDERSI che non ci sta.
func ospita(c: Control) -> void:
	if c.get_parent() != null:
		c.get_parent().remove_child(c)
	add_child(c)
	c.position = area_client().position


func _draw() -> void:
	if tema == null:
		return
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, tema.FACE)
	tema.rilievo(self, r, tema.HL, tema.DARK, tema.LIGHT, tema.SHADOW)

	var tr := rect_titolo()
	if attiva:
		for i in range(int(tr.position.x), int(tr.position.x + tr.size.x)):
			var t := float(i - tr.position.x) / maxf(1.0, tr.size.x)
			draw_line(Vector2(i + 0.5, tr.position.y),
					Vector2(i + 0.5, tr.position.y + tr.size.y),
					tema.TITLE_A.lerp(tema.TITLE_B, t), 1.0)
	else:
		draw_rect(tr, tema.TITLE_OFF)

	draw_rect(Rect2(tr.position.x + 2, tr.position.y + 3, 12, 12), tema.LIGHT)
	tema.testo(self, Vector2(tr.position.x + 18, tr.position.y + 3), titolo,
			tema.TITLE_TX if attiva else tema.TITLE_TX_OFF)

	if bottoni:
		var bx := tr.position.x + tr.size.x - 2 - BOTTONE.x
		# Il segno di mezzo dice cosa FARÀ il pulsante, non com'è la finestra adesso:
		# da normale mostra il quadrato grande (vai a tutto schermo), da massimizzata
		# il segno del ritorno. Era così anche in Windows.
		for lab in ["X", "=" if massimizzata else "O", "_"]:
			var b := Rect2(bx, tr.position.y + 2, BOTTONE.x, BOTTONE.y)
			tema.pulsante(self, b)
			tema.testo(self, Vector2(bx + 5, tr.position.y + 3), lab, tema.INK)
			bx -= BOTTONE.x

	# L'incasso attorno all'area utile: in Windows il contenuto sta più in basso della
	# cornice, e quel gradino di due pixel è metà di ciò che fa «finestra».
	tema.rilievo(self, area_client().grow(1), tema.SHADOW, tema.HL)
