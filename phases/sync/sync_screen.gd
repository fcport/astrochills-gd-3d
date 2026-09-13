## L'interfaccia della fase di sincronizzazione, disegnata per un CRT da 256x192.
##
## È solo una vista: non calcola niente, non conosce `truth`, non sa di quanto
## siano sfasati gli encoder. La fase le passa dove appare la stella e lei disegna.
## Modello e idioma: la vista del fuoco.
##
## È IL CAMPO DEL CERCATORE, non quello della camera, e la differenza è tutta
## pratica: cinque gradi. Con l'inquadratura della CCD — mezzo grado scarso — una
## montatura appena accesa punterebbe fuori campo e il giocatore vedrebbe il
## nero, senza sapere da che parte cercare. È esattamente per questo che si
## sincronizza guardando nel cercatore, e non nella camera.
##
## IL CERCHIETTO AL CENTRO È IL TRAGUARDO, ed è l'unica cosa che spiega la fase.
## Non c'è scritto da nessuna parte «porta l'errore sotto otto primi»: c'è un
## cerchio, e la stella o ci sta dentro o no. La stessa proprietà per cui la fase
## polare e quella del fuoco funzionano senza tutorial.
##
## LA FRECCIA AL BORDO quando la stella è fuori campo: è la sola concessione, e
## serve perché una stella fuori campo è indistinguibile da un cielo vuoto. Nel
## cercatore vero si vedono le stelle intorno e ci si orienta; qui non c'è un
## campo stellare, quindi si dice da che parte.
##
## Il testo dell'interfaccia è in INGLESE: è la lingua delle macchine.
extends Control

const DESIGN_SIZE := Vector2(256, 192)

const BG := Phosphor.BG
const FG := Phosphor.FG
const DIM := Phosphor.DIM
const FAINT := Phosphor.FAINT

const MARGIN := 8

## Il campo del cercatore: QUADRATO, e non è una scelta di gusto. La scala deve
## essere la stessa nei due sensi, o mezzo grado in declinazione sembrerebbe più
## grande di mezzo grado in angolo orario e si centrerebbe storto.
const CENTRO := Vector2(128.0, 88.0)
const MEZZO_LATO := 64.0

## Il raggio del cerchietto del traguardo, in gradi. Lo stesso `ERRORE_BUONO`
## della fase: sta scritto qui perché la vista non può conoscere la fase, ed è
## verificato dal banco.
const TOLLERANZA := 0.13

var _font: SystemFont

var _stella := ""
var _scarto := Vector2.ZERO
var _campo := 5.0
var _score := 0
var _in_viaggio := false
var _centrata := false


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


## Unico ingresso della vista. La fase chiama questo e basta.
func set_readout(stella: String, scarto: Vector2, campo: float, score: int,
		in_viaggio: bool, centrata: bool) -> void:
	_stella = stella
	_scarto = scarto
	_campo = campo
	_score = score
	_in_viaggio = in_viaggio
	_centrata = centrata
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)
	_text(Vector2(MARGIN, 15), "SYNC", FG, 12)
	_text(Vector2(DESIGN_SIZE.x - MARGIN - _width(_stella), 15), _stella, FG, 12)
	_draw_campo()
	_draw_footer()


## Da gradi a pixel. Il campo è largo `_campo` gradi da un bordo all'altro.
func _px_per_grado() -> float:
	return (MEZZO_LATO * 2.0) / _campo


func _draw_campo() -> void:
	var r := Rect2(CENTRO - Vector2(MEZZO_LATO, MEZZO_LATO),
		Vector2(MEZZO_LATO, MEZZO_LATO) * 2.0)
	draw_rect(r, FAINT, false, 1.0)
	# IL RETICOLO: due linee e un cerchietto. Le linee non arrivano al centro —
	# un incrocio pieno coprirebbe proprio la stella quando è centrata, che è
	# l'unico momento in cui la si vuole vedere.
	var s := _px_per_grado()
	var vuoto := TOLLERANZA * s + 3.0
	draw_line(Vector2(r.position.x + 4, CENTRO.y), Vector2(CENTRO.x - vuoto, CENTRO.y), DIM, 1.0)
	draw_line(Vector2(CENTRO.x + vuoto, CENTRO.y), Vector2(r.end.x - 4, CENTRO.y), DIM, 1.0)
	draw_line(Vector2(CENTRO.x, r.position.y + 4), Vector2(CENTRO.x, CENTRO.y - vuoto), DIM, 1.0)
	draw_line(Vector2(CENTRO.x, CENTRO.y + vuoto), Vector2(CENTRO.x, r.end.y - 4), DIM, 1.0)
	draw_arc(CENTRO, TOLLERANZA * s, 0.0, TAU, 24, FG if _centrata else DIM, 1.0)

	if _in_viaggio:
		# A MOTORI IN MOTO NON SI DISEGNA LA STELLA, e non è pudore grafico: a
		# metà slew il campo che si sta inquadrando non è quello, e mostrare la
		# stella dove sarà inviterebbe a premere SYNC prima dell'arrivo.
		var t := "SLEWING"
		_text(CENTRO - Vector2(_width(t) / 2.0, -4.0), t, FG, 12)
		return

	# LA STELLA VA DALLA PARTE OPPOSTA ALLO SCARTO IN DECLINAZIONE, perché sullo
	# schermo la declinazione cresce verso l'ALTO e le y dei pixel verso il basso.
	var p := CENTRO + Vector2(_scarto.x, -_scarto.y) * s
	if absf(p.x - CENTRO.x) > MEZZO_LATO or absf(p.y - CENTRO.y) > MEZZO_LATO:
		_freccia_al_bordo(p)
		return
	draw_circle(p, 2.0, FG)
	draw_circle(p, 4.0, Color(FG.r, FG.g, FG.b, 0.25))


## La stella è fuori campo: si dice da che parte, con un triangolo sul bordo.
func _freccia_al_bordo(p: Vector2) -> void:
	var d := (p - CENTRO).normalized()
	# Sul bordo del QUADRATO, non del cerchio inscritto: il punto dove il raggio
	# esce davvero dal riquadro.
	var k := MEZZO_LATO / maxf(absf(d.x), absf(d.y))
	var b := CENTRO + d * (k - 6.0)
	var n := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([b + d * 5.0, b - d * 3.0 + n * 4.0,
		b - d * 3.0 - n * 4.0]), FG)


func _draw_footer() -> void:
	# IN PRIMI D'ARCO E NON IN GRADI: sotto il grado i decimali diventano
	# illeggibili («0.13»), e chi centra ha bisogno di vedere il numero calare.
	# I primi sono anche l'unità in cui si parla di errore di puntamento.
	var primi := _scarto.length() * 60.0
	_text(Vector2(MARGIN, 170), "ERR %5.1f'   SCORE %3d" % [primi, _score], FG, 12)
	var aiuto := "WASD CENTRE   ENTER SYNC"
	if _in_viaggio:
		aiuto = "WAIT FOR THE MOUNT"
	_text(Vector2(MARGIN, 185), aiuto, DIM, 12)


func _width(s: String) -> float:
	return _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
