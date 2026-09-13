## L'interfaccia del GOTO, disegnata per un CRT da 256x192.
##
## È solo una vista: non calcola niente, non conosce `truth`, non sa dov'è il
## soggetto. La fase le passa dove si vede l'oggetto e lei disegna. Modello e
## idioma: la vista della fase 5, di cui è la sorella — stesso campo, stesso
## reticolo, stesse frecce.
##
## LA COSA CHE QUESTA SCHERMATA DEVE FAR CAPIRE, e che non è scritta da nessuna
## parte: il rettangolino al centro è quello che la camera vede DAVVERO. Tutto il
## resto del riquadro è cielo che il cercatore mostra e la CCD non registra. Un
## GOTO sbagliato di un grado lascia l'oggetto ben dentro il campo e ben fuori
## dalla foto, e finché non lo si vede disegnato non ci si crede.
##
## Il testo dell'interfaccia è in INGLESE: è la lingua delle macchine.
extends Control

const DESIGN_SIZE := Vector2(256, 192)

const BG := Phosphor.BG
const FG := Phosphor.FG
const DIM := Phosphor.DIM
const FAINT := Phosphor.FAINT

const MARGIN := 8

## Il campo del cercatore: quadrato, per la stessa ragione della fase 5 — la
## scala dev'essere la stessa nei due sensi o si centra storto.
const CENTRO := Vector2(128.0, 88.0)
const MEZZO_LATO := 64.0

var _font: SystemFont

var _target := ""
var _scarto := Vector2.ZERO
var _campo := 5.0
var _inquadratura := Vector2(0.5, 0.35)
var _altezza := 0.0
var _in_viaggio := false
var _dentro := false
var _irraggiungibile := false


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


## Unico ingresso della vista. La fase chiama questo e basta.
func set_readout(target: String, scarto: Vector2, campo: float,
		inquadratura: Vector2, altezza: float, in_viaggio: bool,
		dentro: bool, irraggiungibile: bool) -> void:
	_target = target
	_scarto = scarto
	_campo = campo
	_inquadratura = inquadratura
	_altezza = altezza
	_in_viaggio = in_viaggio
	_dentro = dentro
	_irraggiungibile = irraggiungibile
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)
	_text(Vector2(MARGIN, 15), "GOTO", FG, 12)
	_text(Vector2(DESIGN_SIZE.x - MARGIN - _width(_target), 15), _target, FG, 12)
	_draw_campo()
	_draw_footer()


func _px_per_grado() -> float:
	return (MEZZO_LATO * 2.0) / _campo


func _draw_campo() -> void:
	var r := Rect2(CENTRO - Vector2(MEZZO_LATO, MEZZO_LATO),
		Vector2(MEZZO_LATO, MEZZO_LATO) * 2.0)
	draw_rect(r, FAINT, false, 1.0)
	var s := _px_per_grado()

	if _irraggiungibile:
		# Nessun campo da disegnare: il tubo non ci arriverebbe, e mostrare un
		# reticolo inviterebbe a provarci.
		var t := "BELOW DOME HORIZON"
		_text(CENTRO - Vector2(_width(t) / 2.0, 4.0), t, FG, 12)
		var u := "%.0f DEG - NEEDS %.0f" % [_altezza, SkyGeometry.ORIZZONTE_CUPOLA]
		_text(CENTRO - Vector2(_width(u) / 2.0, -10.0), u, DIM, 12)
		return

	# L'INQUADRATURA DELLA CAMERA: il rettangolino che è tutta la fase.
	var mezza := _inquadratura * 0.5 * s
	draw_rect(Rect2(CENTRO - mezza, mezza * 2.0), FG if _dentro else DIM, false, 1.0)

	if _in_viaggio:
		var t := "SLEWING"
		_text(CENTRO - Vector2(_width(t) / 2.0, -26.0), t, FG, 12)
		return

	var p := CENTRO + Vector2(_scarto.x, -_scarto.y) * s
	if absf(p.x - CENTRO.x) > MEZZO_LATO or absf(p.y - CENTRO.y) > MEZZO_LATO:
		_freccia_al_bordo(p)
		return
	# UN OGGETTO DEL PROFONDO CIELO NON È UN PUNTO, e disegnarlo come una stella
	# lo confonderebbe con il campo: un dischetto sfumato, che è come si presenta
	# nel cercatore.
	draw_circle(p, 3.0, Color(FG.r, FG.g, FG.b, 0.35))
	draw_circle(p, 1.5, FG)


func _freccia_al_bordo(p: Vector2) -> void:
	var d := (p - CENTRO).normalized()
	var k := MEZZO_LATO / maxf(absf(d.x), absf(d.y))
	var b := CENTRO + d * (k - 6.0)
	var n := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([b + d * 5.0, b - d * 3.0 + n * 4.0,
		b - d * 3.0 - n * 4.0]), FG)


func _draw_footer() -> void:
	var primi := _scarto.length() * 60.0
	_text(Vector2(MARGIN, 170), "OFF %5.1f'   ALT %4.1f" % [primi, _altezza], FG, 12)
	var aiuto := "WASD CENTRE   ENTER ACCEPT"
	if _irraggiungibile:
		aiuto = "ENTER ABORT"
	elif _in_viaggio:
		aiuto = "WAIT FOR THE MOUNT"
	elif not _dentro:
		aiuto = "WASD - GET IT INSIDE THE BOX"
	_text(Vector2(MARGIN, 185), aiuto, DIM, 12)


func _width(s: String) -> float:
	return _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
