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

var _attivo := false


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


func _draw() -> void:
	# arrotondato, o il punto cade a cavallo di due pixel e si vede grigio
	var c: Vector2 = (size * 0.5).floor()
	_quadretto(Rect2(c - Vector2(PUNTO, PUNTO) * 0.5, Vector2(PUNTO, PUNTO)))
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
