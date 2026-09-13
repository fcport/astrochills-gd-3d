## L'interfaccia della fase del fuoco, disegnata per un CRT da 256x192.
##
## È solo una vista: non calcola niente, non conosce `truth`, non sa dove sia il
## fuoco. La fase le passa la posizione, il diametro misurato e i punti visitati,
## e lei disegna. Modello e idioma: la vista della fase polare.
##
## DUE COSE, E SONO LA STESSA COSA VISTA IN DUE MODI. In alto le stelle come si
## vedono adesso: dischetti che si stringono e si accendono avvicinandosi al fuoco.
## In basso la storia di quello che hai misurato, punto per punto — la curva a V.
## La prima dice «adesso», la seconda dice «da che parte». Insieme sono tutto il
## mestiere di questa fase, e nessuna delle due ha bisogno di una spiegazione.
##
## IL GRAFICO SI SCALA SUI PUNTI VISITATI e non sulla corsa meccanica, e non è per
## comodità: un grafico che mostrasse sempre tutta la corsa metterebbe il fuoco
## sempre nello stesso posto sullo schermo, e la fase si giocherebbe guardando
## dov'è il centro del riquadro invece delle stelle.
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

## Il campo stellare e il riquadro del grafico.
const FIELD := Rect2(8, 20, 240, 96)
const PLOT := Rect2(8, 126, 240, 42)

## Dove stanno le sette stelle dentro il campo, in frazioni del riquadro.
##
## FISSE E NON CASUALI: sono sempre lo stesso pezzo di cielo per tutta la posa, e
## una che si spostasse fra un fotogramma e l'altro racconterebbe una montatura
## che salta. Sparpagliate a mano, senza simmetrie: tre in fila leggerebbero come
## un reticolo.
const STARS: Array[Vector2] = [
	Vector2(0.18, 0.30), Vector2(0.52, 0.18), Vector2(0.79, 0.41),
	Vector2(0.33, 0.66), Vector2(0.64, 0.78), Vector2(0.90, 0.72),
	Vector2(0.08, 0.84),
]

## Da diametro misurato a raggio disegnato. È una scala di disegno, non una misura.
const PIXELS_PER_HFD := 0.85

var _font: SystemFont

var _position := 0.0
var _hfd := 0.0
var _encoder := 0
var _samples: PackedVector2Array = PackedVector2Array()
var _score := 0
var _moving := false


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


## Unico ingresso della vista. La fase chiama questo e basta.
func set_readout(position: float, hfd: float, encoder: int,
		samples: PackedVector2Array, score: int, moving: bool) -> void:
	_position = position
	_hfd = hfd
	_encoder = encoder
	_samples = samples
	_score = score
	_moving = moving
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)
	_draw_header()
	_draw_field()
	_draw_plot()
	_draw_footer()


func _draw_header() -> void:
	_text(Vector2(MARGIN, 15), "FOCUS", FG, 12)
	var passi := "STEP %5d" % _encoder
	_text(Vector2(DESIGN_SIZE.x - MARGIN - _width(passi), 15),
		passi, FG if _moving else DIM, 12)


## Le stelle come si vedono adesso.
##
## PIÙ SONO LARGHE PIÙ SONO FIOCHE, e questa è la sola ragione per cui il campo si
## legge a colpo d'occhio: la luce di una stella è sempre la stessa, e spalmarla su
## un disco più grande la diluisce. Un campo in cui i dischi crescono restando
## luminosi sembrerebbe migliorare mentre peggiora.
##
## La curva dell'opacità è una scelta di DISEGNO e non una legge dell'ottica: la
## legge vera va come l'inverso del quadrato del raggio, e quella qui sotto le
## somiglia abbastanza da leggersi bene su un fosforo verde a 256 pixel.
func _draw_field() -> void:
	draw_rect(FIELD, FAINT, false, 1.0)
	var r := maxf(_hfd * PIXELS_PER_HFD, 0.8)
	var opacita := clampf(6.0 / (_hfd * _hfd), 0.12, 1.0)
	for s in STARS:
		var p := FIELD.position + Vector2(s.x * FIELD.size.x, s.y * FIELD.size.y)
		draw_circle(p, r, Color(FG.r, FG.g, FG.b, opacita))
		# Il nocciolo: una stella, anche gonfia, ha un centro più denso. Serve
		# soprattutto a non far sparire le stelle quando sono molto sfocate.
		draw_circle(p, maxf(r * 0.35, 0.6), Color(FG.r, FG.g, FG.b, minf(opacita * 2.0, 1.0)))


## La curva a V: i punti visitati, con quello di adesso in evidenza.
func _draw_plot() -> void:
	draw_rect(PLOT, FAINT, false, 1.0)
	if _samples.size() < 2:
		_text(Vector2(PLOT.position.x + 6, PLOT.position.y + 26),
			"MOVE THE FOCUSER TO PLOT", FAINT, 10)
		return

	var x0 := _samples[0].x
	var x1 := x0
	var y0 := _samples[0].y
	var y1 := y0
	for s in _samples:
		x0 = minf(x0, s.x)
		x1 = maxf(x1, s.x)
		y0 = minf(y0, s.y)
		y1 = maxf(y1, s.y)
	# Il punto di adesso deve stare dentro il riquadro anche se non è ancora fra i
	# campioni: senza, il cursore uscirebbe dal grafico mentre ci si muove.
	x0 = minf(x0, _position)
	x1 = maxf(x1, _position)
	y0 = minf(y0, _hfd)
	y1 = maxf(y1, _hfd)
	if x1 - x0 < 1.0 or y1 - y0 < 0.05:
		return

	for s in _samples:
		draw_circle(_to_plot(s.x, s.y, x0, x1, y0, y1), 1.0, DIM)
	var qui := _to_plot(_position, _hfd, x0, x1, y0, y1)
	draw_circle(qui, 2.0, FG)
	# La verticale sotto il cursore: dice DOVE sei sulla curva anche quando il
	# punto finisce sopra un altro.
	draw_line(Vector2(qui.x, PLOT.position.y + 1),
		Vector2(qui.x, PLOT.position.y + PLOT.size.y - 1), FAINT, 1.0)


## Da (posizione, diametro) a pixel. Il diametro piccolo va IN BASSO: così la
## curva ha la forma che ha il suo nome.
func _to_plot(px: float, py: float, x0: float, x1: float, y0: float, y1: float) -> Vector2:
	var u := (px - x0) / (x1 - x0)
	var v := (py - y0) / (y1 - y0)
	return Vector2(PLOT.position.x + 2.0 + u * (PLOT.size.x - 4.0),
		PLOT.position.y + PLOT.size.y - 2.0 - v * (PLOT.size.y - 4.0))


func _draw_footer() -> void:
	_text(Vector2(MARGIN, 176), "HFD %5.2f   SCORE %3d" % [_hfd, _score], FG, 12)
	_text(Vector2(MARGIN, 188), "A/D FOCUSER   ENTER DONE", DIM, 12)


func _width(s: String) -> float:
	return _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
