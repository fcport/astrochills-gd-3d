## L'interfaccia della fase polare, disegnata per un CRT da 256x192.
##
## È solo una vista: non calcola niente, non conosce `truth`, non sa cosa sia una
## sorgente di verità. La fase le passa i numeri già pronti con `set_readout()` e
## lei li disegna. Se un giorno la deriva comincerà a mentire, questo file non se
## ne accorgerà — ed è esattamente ciò che deve succedere.
##
## LA MISURA CHE COMANDA IL LAYOUT: 256 px di larghezza. A corpo 12 ci stanno
## circa 34 caratteri prima che la curvatura del CRT se li mangi ai bordi. Ogni
## riga qui sotto sta sotto quella soglia, e non è una coincidenza: è il vincolo.
##
## LA SCIA NON È DECORAZIONE. È il solo modo in cui una velocità si legge a
## occhio: punti radi vuol dire veloce, punti fitti vuol dire quasi fermo. Senza,
## «rallenta la deriva» resterebbe un'istruzione senza supporto.
##
## Il testo è in inglese perché è un'interfaccia software: la lingua delle
## macchine. I commenti sono in italiano, che è la lingua di chi ci lavora.
extends Control

const DESIGN_SIZE := Vector2(256, 192)

## Colori del fosforo verde, ripresi dallo spike del CRT: sono stati scelti
## guardandoli sullo schermo curvo, non stimati.
const BG := Color(0.02, 0.06, 0.03)
const FG := Color(0.62, 1.0, 0.68)
const DIM := Color(0.30, 0.58, 0.34)
const FAINT := Color(0.18, 0.34, 0.20)

const RETICLE_CENTER := Vector2(128, 96)
const RETICLE_RADIUS := 40.0

## Quanti pixel vale un arcominuto. NON è un numero scelto a occhio: è
## `RETICLE_RADIUS / STAR_LIMIT_ARCMIN`, cioè 40 / 3.2. Così la stella al limite
## si ferma esattamente SUL bordo del reticolo, che è quello che il commento
## prometteva e che con 14.0 non succedeva — a 14 px per arcominuto finiva 4.8 px
## fuori dal cerchio. Se uno dei due cambia, va ricalcolato anche questo.
const PIXELS_PER_ARCMIN := 12.5

## Oltre questo scostamento la stella si disegna ferma sul bordo.
##
## È un fatto di DISEGNO e per questo sta qui e non nella fase: lo stato
## osservabile resta l'integrale puro di ciò che `truth` restituisce, e una
## sorgente bugiarda può continuare a portarlo dove vuole. Semplicemente, oltre
## il bordo non c'è più schermo su cui mostrarlo.
const STAR_LIMIT_ARCMIN := 3.2

## Lunghezza della scia e ogni quanto si depone un punto. L'intervallo è fisso
## apposta: è la distanza fra i punti a raccontare la velocità.
const TRAIL_MAX := 56
const TRAIL_INTERVAL := 0.08

var _font: SystemFont

var _star := Vector2.ZERO
var _drift := Vector2.ZERO
var _screws := Vector2.ZERO
var _score := 0
var _steady := false

var _trail: Array[Vector2] = []
var _trail_clock := 0.0


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


## Unico ingresso della vista. La fase chiama questo e basta.
func set_readout(
	star: Vector2, drift: Vector2, screws: Vector2, score: int, steady: bool
) -> void:
	_star = star
	_drift = drift
	_screws = screws
	_score = score
	_steady = steady
	queue_redraw()


func _process(delta: float) -> void:
	_trail_clock += delta
	if _trail_clock < TRAIL_INTERVAL:
		return
	# Si SOTTRAE l'intervallo invece di azzerare. Azzerando, la cadenza si
	# quantizzerebbe al frame — 0.0833 s a 60 fps, 0.100 s a 30 — e la distanza
	# fra i punti, che è precisamente ciò che racconta la velocità, cambierebbe
	# del 20% col frame rate. L'intervallo è fisso apposta: qui lo è davvero.
	_trail_clock -= TRAIL_INTERVAL
	_trail.append(_star_position())
	if _trail.size() > TRAIL_MAX:
		_trail.remove_at(0)
	# La scia è cambiata, quindi si chiede di ridipingere. Senza, la vista muta
	# uno stato che nessuno ripassa a schermo, e dopo la fine della fase continua
	# a deporre punti che non vede nessuno finché qualcosa non forza un redraw.
	queue_redraw()


## Il ritaglio al bordo e il segno di y stanno tutti e due qui, dove si converte
## in pixel, perché tutti e due sono fatti di schermo e non di simulazione.
##
## y è INVERTITO: sullo schermo +Y va verso il basso, ma alzare la vite
## dell'altitudine deve alzare la stella. Gesto e riscontro nella stessa
## direzione — in una fase che esiste per insegnare un mestiere a chi non lo
## conosce, il contrario insegnerebbe la direzione sbagliata.
func _star_position() -> Vector2:
	var s := _star
	if s.length() > STAR_LIMIT_ARCMIN:
		s = s.normalized() * STAR_LIMIT_ARCMIN
	return RETICLE_CENTER + Vector2(s.x, -s.y) * PIXELS_PER_ARCMIN


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)
	_draw_header()
	_draw_reticle()
	_draw_trail()
	draw_circle(_star_position(), 2.0, FG)
	_draw_status()
	_draw_footer()


func _draw_header() -> void:
	_text(Vector2(8, 15), "POLAR ALIGN / DRIFT", FG, 12)
	_text(Vector2(8, 29), "AZ %+.2f  ALT %+.2f" % [_screws.x, _screws.y], DIM, 12)


func _draw_reticle() -> void:
	draw_arc(RETICLE_CENTER, RETICLE_RADIUS, 0.0, TAU, 48, DIM, 1.0)
	draw_arc(RETICLE_CENTER, RETICLE_RADIUS * 0.5, 0.0, TAU, 32, FAINT, 1.0)
	draw_line(
		RETICLE_CENTER - Vector2(RETICLE_RADIUS, 0),
		RETICLE_CENTER + Vector2(RETICLE_RADIUS, 0), FAINT, 1.0)
	draw_line(
		RETICLE_CENTER - Vector2(0, RETICLE_RADIUS),
		RETICLE_CENTER + Vector2(0, RETICLE_RADIUS), FAINT, 1.0)


func _draw_trail() -> void:
	var n := _trail.size()
	for i in n:
		# I punti vecchi svaniscono: la coda dice da dove viene la stella, e
		# quanto fitti sono dice quanto va piano.
		var a := float(i + 1) / float(n)
		draw_circle(_trail[i], 1.0, Color(DIM.r, DIM.g, DIM.b, a * 0.7))


## Una riga sola, e dice l'unica cosa che serve sapere: se si sta ancora
## muovendo o no.
func _draw_status() -> void:
	if _steady:
		_text(Vector2(8, 152), "HOLDING STEADY", FG, 12)
	else:
		_text(Vector2(8, 152), "SLOW THE DRIFT TO ZERO", DIM, 12)


func _draw_footer() -> void:
	_text(Vector2(8, 170), "DRIFT %5.3f'/s  SCORE %3d" % [_drift.length(), _score], FG, 12)
	_text(Vector2(8, 184), "WASD TURN SCREWS  ENTER DONE", DIM, 12)


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
