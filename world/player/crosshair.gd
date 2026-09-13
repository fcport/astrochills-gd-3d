## Il mirino: un punto al centro dello schermo, che si apre quando c'è qualcosa da usare.
##
## PERCHÉ UN PUNTO E NON UNA CROCE. Non si spara a niente. Quello che serve è
## sapere DOVE guarda il raggio dell'interazione, perché quel raggio parte dal
## centro esatto della camera e senza un riferimento si finisce a mirare a
## tentoni un interruttore da undici centimetri. Una croce da sparatutto direbbe
## una cosa che questo gioco non fa.
##
## SI APRE INVECE DI CAMBIARE COLORE. Guardando un interagibile il punto resta
## dov'è e gli compaiono attorno quattro trattini: è la stessa informazione del
## prompt in basso, ma dove sta già l'occhio. Il colore lo lascio stare — a
## 640x360 un punto di due pixel che cambia tinta non lo si vede, un punto che
## cambia FORMA sì.
##
## DISEGNATO, NON UNA TEXTURE. Sono nove rettangoli: una texture andrebbe
## importata, filtrata e tenuta allineata alla griglia dei pixel, e il primo
## ridimensionamento della finestra la sfocherebbe. Qui i rettangoli cadono su
## coordinate intere del viewport a bassa risoluzione, che è l'unico modo perché
## restino netti.
##
## Vive nel `SubViewport` del mondo come `InteractionPrompt`, per la stessa
## ragione: deve avere la grana della stanza, non quella di un'interfaccia
## moderna appiccicata sopra.
##
## SOTTO IL PUNTO C'È LA BARRA DEL LANCIO, e sta qui e non in un nodo suo perché
## è dove sta l'occhio mentre si prende la mira. Esiste solo mentre si carica:
## vedi `Player.TEMPO_CARICA`.
class_name Crosshair
extends Control

## Il punto fermo, e il colore dell'ombra che lo stacca da un muro chiaro.
const FG := Color(0.92, 0.94, 0.90, 0.85)
const SHADOW := Color(0, 0, 0, 0.5)

## Due pixel di lato: uno solo sparisce sul terrazzo, tre diventano un bersaglio.
const PUNTO := 2.0

## I quattro trattini che compaiono a fuoco: lunghezza, spessore e quanto stanno
## staccati dal punto.
const TRATTO := 3.0
const SPESSORE := 1.0
const STACCO := 3.0

## La barra del lancio: lunga e spessa, in pixel, e quanto sta sotto il centro. Dieci
## la mette appena sotto il trattino basso, che finisce a sette.
const BARRA := Vector2(16.0, 2.0)
const BARRA_STACCO := 10.0

## Il vuoto della barra: lo stesso bianco del punto, spento. Si deve vedere quanto
## manca, o una barra a metà sembra una barra corta.
const VUOTO := Color(0.92, 0.94, 0.90, 0.25)

var _attivo := false

## Quanto è piena la barra, da 0 a 1. A zero non si disegna.
var _carica := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Lo chiama il giocatore quando il raggio trova o perde un interagibile.
## Ridisegna solo se lo stato cambia davvero: `queue_redraw()` a ogni tick di
## fisica sarebbe un disegno al frame per un'immagine che non si muove.
func set_attivo(valore: bool) -> void:
	if valore == _attivo:
		return
	_attivo = valore
	queue_redraw()


## Lo chiama il giocatore a ogni tick in cui carica un lancio, e con 0 quando smette.
## Ridisegna solo quando la barra guadagna un pixel, per la stessa ragione di
## `set_attivo()`.
func set_carica(valore: float) -> void:
	valore = clampf(valore, 0.0, 1.0)
	var cambia := floori(valore * BARRA.x) != floori(_carica * BARRA.x) \
		or (valore > 0.0) != (_carica > 0.0)
	_carica = valore
	if cambia:
		queue_redraw()


func _draw() -> void:
	# arrotondato, o il punto cade a cavallo di due pixel e si vede grigio
	var c: Vector2 = (size * 0.5).floor()
	_quadretto(Rect2(c - Vector2(PUNTO, PUNTO) * 0.5, Vector2(PUNTO, PUNTO)))
	if _carica > 0.0:
		_barra(c)
	if not _attivo:
		return
	var d := STACCO + PUNTO * 0.5
	var versi: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	for verso in versi:
		var orizzontale := absf(verso.x) > 0.0
		var lungo := Vector2(TRATTO, SPESSORE) if orizzontale else Vector2(SPESSORE, TRATTO)
		var centro: Vector2 = c + verso * (d + TRATTO * 0.5)
		_quadretto(Rect2((centro - lungo * 0.5).floor(), lungo))


## Ogni pezzo si disegna due volte: prima l'ombra spostata di un pixel, poi il
## pezzo. Senza, su un muro chiaro il mirino sparisce — ed è chiaro quasi tutto,
## qui dentro.
func _quadretto(r: Rect2) -> void:
	draw_rect(Rect2(r.position + Vector2.ONE, r.size), SHADOW)
	draw_rect(r, FG)


## La barra intera col suo vuoto e la sua ombra, poi il pieno a pixel interi: mezzo
## pixel di pieno cadrebbe grigio come il punto non arrotondato.
func _barra(c: Vector2) -> void:
	var origine := (c + Vector2(-BARRA.x * 0.5, BARRA_STACCO)).floor()
	draw_rect(Rect2(origine + Vector2.ONE, BARRA), SHADOW)
	draw_rect(Rect2(origine, BARRA), VUOTO)
	var pieno := floorf(BARRA.x * _carica)
	if pieno > 0.0:
		draw_rect(Rect2(origine, Vector2(pieno, BARRA.y)), FG)
