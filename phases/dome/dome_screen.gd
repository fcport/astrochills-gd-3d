## Il pannello della cupola, disegnato per un CRT da 256x192.
##
## È solo una vista: non calcola niente, non conosce `truth`, non sa cosa sia una
## sorgente di verità. La fase le passa la corsa già fatta con `set_readout()` e
## lei disegna. Modello e idioma: la vista della fase polare.
##
## LO SPACCATO È IL PEZZO CHE CONTA. Una percentuale dice quanto, non cosa: un
## numero che sale da 0 a 100 potrebbe essere qualunque cosa, e il gesto di questa
## fase è aprire una fessura sul cielo. Il disegno in sezione — la calotta, i due
## battenti che si ritirano, il buio in mezzo che si allarga — dice al giocatore
## esattamente cosa sta succedendo sopra la sua testa, in una stanza da cui la
## cupola non si vede. La barra e la percentuale restano perché una macchina del
## 1999 le avrebbe avute, e perché a fine corsa serve un numero esatto.
##
## Il testo dell'interfaccia è in INGLESE: è la lingua delle macchine.
extends Control

const DESIGN_SIZE := Vector2(256, 192)

## Colori del fosforo verde, gli stessi delle altre viste.
const BG := Color(0.02, 0.06, 0.03)
const FG := Color(0.62, 1.0, 0.68)
const DIM := Color(0.30, 0.58, 0.34)
const FAINT := Color(0.18, 0.34, 0.20)

const MARGIN := 8

## Lo spaccato: centro della calotta e raggio, in pixel dello schermo.
const DOME_CENTER := Vector2(128, 118)
const DOME_RADIUS := 62.0

## Mezza apertura della fessura, in RADIANTI, a battente tutto aperto.
##
## 0,42 rad sono 24 gradi per parte: sullo spaccato è uno spicchio largo abbastanza
## da leggersi come «di lì passa un telescopio», che è quello che deve dire. Non è
## la misura della cupola vera — quella sta in `tools/geometria.py` e vale per il
## modello, non per un disegnino a fosfori.
const SLIT_HALF := 0.42

## La barra di corsa.
const BAR := Rect2(8, 158, 240, 7)

## Le stelle dello spaccato, come scostamenti dal centro della calotta. Stanno
## FUORI dal raggio (62 px): sono cielo, non soffitto.
const STARS: Array[Vector2] = [Vector2(-10, -70), Vector2(4, -80), Vector2(14, -68)]

var _font: SystemFont

var _aperture := 0.0
var _speed := 0.0
## Il verso del motore: +1 apre, -1 chiude, 0 fermo.
var _motor := 0
var _open := false


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


## Unico ingresso della vista. La fase chiama questo e basta.
func set_readout(aperture: float, speed: float, motor: int, open: bool) -> void:
	_aperture = aperture
	_speed = speed
	_motor = motor
	_open = open
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)
	_draw_header()
	_draw_section()
	_draw_bar()
	_draw_footer()


func _draw_header() -> void:
	_text(Vector2(MARGIN, 15), "DOME SHUTTER", FG, 12)
	_text(Vector2(MARGIN, 29), _state(), DIM, 12)


## Lo stato in una parola, come lo direbbe il quadro: fermo chiuso, in corsa in un
## verso o nell'altro, fermo a metà, fermo aperto.
##
## «STOPPED» a metà corsa non è un guasto ed è scritto in modo da non sembrarlo: il
## battente è dove l'hai lasciato. E APERTURA e CHIUSURA sono due parole diverse
## perché sono due cose diverse: con una parola sola — «in movimento» — chi ha
## sbagliato pulsante lo scoprirebbe solo guardando la barra scendere.
func _state() -> String:
	if _motor > 0 and _speed > 0.0:
		return "OPENING"
	if _motor < 0 and _speed < 0.0:
		return "CLOSING"
	if _open:
		return "OPEN"
	if _aperture <= 0.0:
		return "CLOSED"
	return "STOPPED AT %d%%" % _percent()


## Lo spaccato della cupola vista da sud: la calotta, i due battenti, il cielo.
func _draw_section() -> void:
	# Il profilo della calotta: la semicirconferenza superiore. In coordinate
	# schermo la y cresce verso il basso, quindi la metà ALTA sta fra PI e TAU.
	draw_arc(DOME_CENTER, DOME_RADIUS, PI, TAU, 64, FAINT, 1.0)
	# Il piano d'appoggio, che dà il verso al disegno.
	draw_line(DOME_CENTER - Vector2(DOME_RADIUS + 6, 0),
		DOME_CENTER + Vector2(DOME_RADIUS + 6, 0), FAINT, 1.0)

	# I due battenti, spessi, che si ritirano verso i fianchi. Lo zenit sta a
	# 1,5·PI; la fessura si apre simmetrica attorno a lui.
	var half := SLIT_HALF * clampf(_aperture, 0.0, 1.0)
	var zenith := PI * 1.5
	var colore := FG if _motor != 0 else DIM
	draw_arc(DOME_CENTER, DOME_RADIUS, PI, zenith - half, 32, colore, 3.0)
	draw_arc(DOME_CENTER, DOME_RADIUS, zenith + half, TAU, 32, colore, 3.0)

	# Il cielo che si vede dalla fessura. Le stelle stanno FUORI dalla calotta, non
	# dentro: dentro sarebbero nella sala del telescopio, e il disegno direbbe una
	# cosa diversa da quella che succede. Compaiono man mano che lo spicchio si
	# allarga abbastanza da scoprirle, che è il modo in cui una fessura scopre il
	# cielo davvero.
	for stella in STARS:
		var p: Vector2 = DOME_CENTER + stella
		# `wrapf` e non una differenza secca: sopra il centro `atan2` restituisce
		# angoli NEGATIVI, e sottrarre 1,5·PI darebbe un giro intero di scarto —
		# nessuna stella si accenderebbe mai, e il disegno resterebbe muto senza
		# che niente lo dica.
		var da_zenit := wrapf(atan2(p.y - DOME_CENTER.y, p.x - DOME_CENTER.x) - zenith, -PI, PI)
		if absf(da_zenit) < half:
			draw_circle(p, 1.0, DIM)


func _draw_bar() -> void:
	draw_rect(BAR, BG)
	draw_rect(BAR, FAINT, false, 1.0)
	var w := (BAR.size.x - 2.0) * clampf(_aperture, 0.0, 1.0)
	if w > 0.0:
		draw_rect(Rect2(BAR.position + Vector2.ONE, Vector2(w, BAR.size.y - 2.0)), FG)


func _draw_footer() -> void:
	_text(Vector2(MARGIN, 176), "APERTURE %3d%%" % _percent(), FG, 12)
	# I DUE PULSANTI CI SONO SEMPRE, e INVIO solo quando risponde. Mostrare un tasto
	# che non fa niente è il modo più veloce per far credere che il pannello sia
	# rotto — e per la stessa ragione, quando INVIO manca, il pannello DICE perché
	# invece di lasciare il posto vuoto: senza quella riga, chi ha richiuso la cupola
	# resterebbe seduto a premere INVIO su una macchina muta.
	_text(Vector2(MARGIN, 189), "HOLD UP OPEN   DOWN CLOSE", DIM, 12)
	var coda := "ENTER CONTINUE" if _open else "OPEN FULLY TO CONTINUE"
	_text(Vector2(DESIGN_SIZE.x - 8 - _larghezza(coda), 176), coda,
		FG if _open else FAINT, 12)


## Quanto è larga una scritta, per allinearla a destra.
func _larghezza(s: String) -> float:
	return _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x


func _percent() -> int:
	return roundi(clampf(_aperture, 0.0, 1.0) * 100.0)


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
