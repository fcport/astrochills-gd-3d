## L'interfaccia della fase del raffreddamento, disegnata per un CRT da 256x192.
##
## È solo una vista: non calcola niente, non conosce `truth`, non sa quanto faccia
## freddo in cupola. La fase le passa cinque numeri e una storia, e lei disegna.
##
## TRE LETTURE, IN ORDINE DI IMPORTANZA. La temperatura grande, perché è quella che
## si guarda da lontano attraversando la stanza. La potenza della cella, perché è
## quella che dice se reggerà. La storia, perché è l'unica che mostra se sta
## ballando — un numero che oscilla di mezzo grado, a schermo, sembra solo un
## numero che cambia; una riga che ondeggia si vede da tre metri.
##
## NESSUNA TACCA SULLA SOGLIA della potenza, ed è deliberato: dire «sopra il
## novanta per cento non regge» trasformerebbe la diagnosi in una lettura. La
## soglia si impara guardando la temperatura ballare, che è come la si impara
## davvero.
##
## Il testo dell'interfaccia è in INGLESE: è la lingua delle macchine.
extends Control

const DESIGN_SIZE := Vector2(256, 192)

## Colori del fosforo verde, gli stessi delle altre viste.
const BG := Phosphor.BG
const FG := Phosphor.FG
const DIM := Phosphor.DIM
const FAINT := Phosphor.FAINT

const MARGIN := 8

## La barra della potenza e il riquadro della storia.
const BAR := Rect2(8, 86, 240, 12)
const PLOT := Rect2(8, 112, 240, 52)

## Quanti secondi di storia entrano nel grafico.
const HISTORY := 40.0

var _font: SystemFont

var _temperature := 0.0
var _setpoint := 0.0
var _duty := 0.0
var _swing := 0.0
var _score := 0
var _samples: PackedVector2Array = PackedVector2Array()
var _now := 0.0


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


## Unico ingresso della vista. La fase chiama questo e basta.
func set_readout(temperature: float, setpoint: float, duty: float, swing: float,
		score: int, samples: PackedVector2Array, now: float) -> void:
	_temperature = temperature
	_setpoint = setpoint
	_duty = duty
	_swing = swing
	_score = score
	_samples = samples
	_now = now
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)
	_text(Vector2(MARGIN, 15), "CCD COOLING", FG, 12)
	draw_line(Vector2(MARGIN, 22), Vector2(DESIGN_SIZE.x - MARGIN, 22), FAINT, 1.0)

	_temperatura()
	_potenza()
	_storia()
	_piede()


## La temperatura, grande. È il numero che si legge attraversando la stanza.
func _temperatura() -> void:
	var t := "%+.1f" % _temperature
	_text(Vector2(MARGIN, 62), t, FG, 34)
	_text(Vector2(MARGIN + _width(t, 34) + 4, 62), "C", DIM, 16)
	var s := "SET %+.0f C" % _setpoint
	_text(Vector2(DESIGN_SIZE.x - MARGIN - _width(s, 12), 40), s, FG, 12)
	# L'escursione recente, in piccolo: chi la guarda ha già capito che serve.
	var d := "SWING %.2f" % _swing
	_text(Vector2(DESIGN_SIZE.x - MARGIN - _width(d, 11), 58), d, DIM, 11)


## Quanto sta lavorando la cella. La barra è piena a piena potenza, e non c'è
## nessun segno a dire dove sia il limite: vedi la testa del file.
func _potenza() -> void:
	_text(Vector2(MARGIN, BAR.position.y - 4), "COOLER", FAINT, 11)
	var etichetta := "%3d%%" % roundi(_duty * 100.0)
	_text(Vector2(DESIGN_SIZE.x - MARGIN - _width(etichetta, 11), BAR.position.y - 4),
		etichetta, FG if _duty > 0.0 else FAINT, 11)
	draw_rect(BAR, FAINT, false, 1.0)
	var dentro := Rect2(BAR.position + Vector2(1, 1),
		Vector2((BAR.size.x - 2) * clampf(_duty, 0.0, 1.0), BAR.size.y - 2))
	if dentro.size.x >= 1.0:
		draw_rect(dentro, DIM)


## La storia della temperatura: quaranta secondi che scorrono.
##
## SI SCALA SU QUELLO CHE È SUCCESSO, non su un intervallo fisso: un grafico da
## +10 a -40 schiaccerebbe mezzo grado di ondeggio in mezzo pixel, cioè
## nasconderebbe esattamente la cosa che questa fase chiede di vedere. Con una
## banda minima di due gradi, però, se no una temperatura ferma diventa una riga
## che salta per il rumore dell'ultimo decimale.
func _storia() -> void:
	draw_rect(PLOT, FAINT, false, 1.0)
	if _samples.size() < 2:
		_text(Vector2(PLOT.position.x + 6, PLOT.position.y + 30),
			"COOLER OFF", FAINT, 11)
		return

	var da := _now - HISTORY
	var alto := -INF
	var basso := INF
	for s in _samples:
		if s.x < da:
			continue
		alto = maxf(alto, s.y)
		basso = minf(basso, s.y)
	if alto == -INF:
		return
	var mezzo := (alto + basso) * 0.5
	var meta := maxf((alto - basso) * 0.6, 1.0)
	alto = mezzo + meta
	basso = mezzo - meta

	var prima := Vector2.INF
	for s in _samples:
		if s.x < da:
			continue
		var p := _in_plot(s.x, s.y, da, alto, basso)
		if prima != Vector2.INF:
			draw_line(prima, p, FG, 1.0)
		prima = p
	# La banda coperta, scritta: senza, non si sa se si stanno guardando due gradi
	# o venti, e una riga piatta e una riga tranquilla sembrano la stessa cosa.
	_text(Vector2(PLOT.position.x + 3, PLOT.position.y + 10),
		"%.1f" % alto, FAINT, 10)
	_text(Vector2(PLOT.position.x + 3, PLOT.position.y + PLOT.size.y - 3),
		"%.1f" % basso, FAINT, 10)


func _in_plot(x: float, y: float, da: float, alto: float, basso: float) -> Vector2:
	var u := clampf((x - da) / HISTORY, 0.0, 1.0)
	var v := clampf((y - basso) / maxf(alto - basso, 0.001), 0.0, 1.0)
	return Vector2(PLOT.position.x + 2.0 + u * (PLOT.size.x - 4.0),
		PLOT.position.y + PLOT.size.y - 2.0 - v * (PLOT.size.y - 4.0))


func _piede() -> void:
	_text(Vector2(MARGIN, 176), "SCORE %3d" % _score, FG, 12)
	_text(Vector2(MARGIN, 188), "W/S SETPOINT   ENTER DONE", DIM, 12)


func _width(s: String, px: int) -> float:
	return _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
