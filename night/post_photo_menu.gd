## Il menu post-foto: hai venduto, ora decidi quanto rifare.
##
## DOVE VIVE, E PERCHÉ QUI. Come `night_summary`, `stacking_reveal` e `photo_sale`,
## è un `Control` di `night/` mostrato sul CRT dall'orchestratore (UX-DR1: evento
## diegetico sullo schermo del mondo, non un popup di gioco sopra la scena). Non è
## una fase — non entra in `_phase`, non emette `finished`, non scrive punteggi. È
## l'orchestratore a possederlo, mostrarlo e liberarlo; il CRT non libera mai ciò
## che mostra.
##
## NON SA COSA SIGNIFICHINO LE SUE SCELTE. Emette soltanto `chosen(option)` con
## l'indice premuto; è l'orchestratore a tradurre l'indice in un punto di rientro
## nel piano della notte. Qui non c'è logica d'economia, nessun autoload, e — come
## in tutto `night/` — nessun nome di fase: le opzioni sono etichette per gli occhi
## del giocatore, non riferimenti a cartelle di `phases/`.
##
## `CLOSE & EXPLORE` RIAPRE. *chiudi ed esplora* non libera questo menu: lo lascia
## vivo e present-gated, così risedendosi ricompare. `arm()` lo ripulisce (`_done`,
## cursore) perché alla riapertura sia di nuovo interattivo.
##
## Il testo è in inglese perché è un'interfaccia software (NFR10). Disegnato per
## 256x192, con i colori del fosforo, come il resto del CRT.
extends Control

## Gli indici delle quattro scelte, in ordine di scorrimento su/giù. L'orchestratore
## li conosce col loro nome, ma NON dipende da questo file: fa `match` sugli stessi
## interi che qui hanno un nome leggibile.
enum {
	OPTION_SHOOT_AGAIN = 0,
	OPTION_CHANGE_TARGET = 1,
	OPTION_REDO_SETUP = 2,
	OPTION_CLOSE = 3,
}

## La scelta è fatta: `chosen` porta l'indice premuto. Signal DIRETTO — l'ascoltatore
## è uno solo, l'orchestratore che ha creato questo Control.
signal chosen(option: int)

const DESIGN_SIZE := Vector2(256, 192)

const BG := Color(0.02, 0.06, 0.03)
const FG := Color(0.62, 1.0, 0.68)
const DIM := Color(0.30, 0.58, 0.34)
## L'opzione selezionata risalta in pieno fosforo; le altre restano in `FG`.
const SEL := Color(0.80, 1.0, 0.86)

## Le etichette in inglese, nell'ordine dell'enum. `_options[i]` è l'etichetta
## dell'opzione `i`. È un `var` e non un `const` perché un `PackedStringArray`
## letterale non è un'espressione costante in GDScript; il contenuto non cambia mai.
var _options: PackedStringArray = PackedStringArray([
	"SHOOT AGAIN",
	"CHANGE TARGET",
	"REDO SETUP",
	"CLOSE & EXPLORE",
])

var _font: SystemFont
var _cursor := 0

## Guarda l'input come `_done` in una fase: dopo la conferma non muove più nulla,
## e una sola `chosen` esce anche se la conferma è premuta due volte in rapida
## successione. Si ri-arma con `arm()`, che *chiudi ed esplora* chiama per riaprire.
var _done := false


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


## Riporta il menu allo stato interattivo: nessuna scelta in corso, cursore in cima.
## Lo chiama l'orchestratore su *chiudi ed esplora*, che NON libera il menu ma lo
## lascia vivo perché risedendosi ricompaia (FR4).
func arm() -> void:
	_done = false
	_cursor = 0
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Guardato da `_done`, come le fasi e la vendita: dopo la conferma l'input non
	# muove più nulla, ed è ciò che debouncia la doppia conferma — una sola `chosen`
	# esce finché `arm()` non lo ri-arma.
	if _done:
		return

	# AZIONI PROPRIE `menu_*`, non le `ui_*`: `ui_accept` è il tasto con cui ci si
	# siede, ed ereditarlo confermerebbe nel frame stesso in cui il menu compare.
	# Modello: `photo_sale._unhandled_input`.
	if event.is_action_pressed(&"menu_up"):
		_cursor = (_cursor - 1 + _options.size()) % _options.size()
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"menu_down"):
		_cursor = (_cursor + 1) % _options.size()
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"menu_confirm"):
		_done = true
		chosen.emit(_cursor)
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)

	_text(Vector2(8, 22), "WHAT NEXT?", FG, 12)

	# Le quattro scelte: la selezionata risalta. Un cursore «>» rende la scelta
	# leggibile sullo schermo curvo anche prima che il colore si noti.
	var y := 62
	for i in _options.size():
		var selected := i == _cursor
		var mark := "> " if selected else "  "
		var col := SEL if selected else FG
		_text(Vector2(8, y), "%s%s" % [mark, _options[i]], col, 12)
		y += 16

	_text(Vector2(8, 182), "up/down choose — enter confirm", DIM, 12)


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
