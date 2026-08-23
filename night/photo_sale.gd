## L'interfaccia di vendita: qualcuno compra la foto, e paga subito.
##
## DOVE VIVE, E PERCHÉ QUI. Come `night_summary` e `stacking_reveal`, è un `Control`
## di `night/` mostrato sul CRT dall'orchestratore (UX-DR1, UX-DR10: evento diegetico
## sullo schermo del mondo, non un popup di gioco sopra la scena). Non è una fase —
## non entra in `_phase`, non emette `finished`, non scrive punteggi. È l'orchestratore
## a possederlo, mostrarlo e liberarlo; il CRT non libera mai ciò che mostra.
##
## È IL PRIMO CONTROL DIEGETICO CHE GESTISCE INPUT. `main._unhandled_input` inoltra a
## `crt.push()`, che fa `push_input` sul `SubViewport`: la tastiera passa, il mouse no
## (vedi `crt_screen.push()`). Le azioni `sale_*` sono la strada che i commenti di
## `push()` dichiaravano fatta apposta per «il primo Button diegetico».
##
## LA LOGICA D'ECONOMIA NON VIVE QUI. Il payout base e il moltiplicatore arrivano già
## calcolati (`photo/payout.gd`); questa schermata decide solo COSA mostrare e legge
## la scelta del giocatore. La mutazione del portafoglio e l'emissione di
## `Events.photo_sold` restano nell'orchestratore.
##
## IL «NIENTE» DEL RIFIUTO (NFR20). Rifiutare la commessa non è un errore: paga il
## base, e la schermata lo dice con una riga gentile («declined — no harm»). Nessuna
## penalità significa nessun ramo che sottrae — non un ramo che sottrae zero.
##
## Il testo è in inglese perché è un'interfaccia software. Disegnato per 256x192, con
## i colori del fosforo, come il resto del CRT.
extends Control

## La vendita è decisa: `fulfill` è true solo se il giocatore ha scelto FULFILL (la
## commessa era applicabile ed è stata accettata). Signal DIRETTO — l'ascoltatore è
## uno solo, l'orchestratore che ha creato questo Control.
signal confirmed(fulfill: bool)

## La schermata «SOLD» è stata congedata: il giocatore ha premuto conferma di nuovo,
## e vuole vedere cosa fare adesso. Porta al menu post-foto (2.6). Signal DIRETTO —
## l'ascoltatore è uno solo, l'orchestratore che ha creato questo Control.
signal dismissed()

const DESIGN_SIZE := Vector2(256, 192)

const BG := Color(0.02, 0.06, 0.03)
const FG := Color(0.62, 1.0, 0.68)
const DIM := Color(0.30, 0.58, 0.34)
## L'opzione selezionata risalta in pieno fosforo; le altre restano in `FG`.
const SEL := Color(0.80, 1.0, 0.86)

var _font: SystemFont

var _target := ""
var _quality := 0
var _base := 0
var _commission: Dictionary = {}

## La commessa è applicabile a QUESTA foto: il target non è vuoto ed è esattamente il
## soggetto richiesto. Calcolato una volta in `set_readout`.
var _applicable := false
var _client_name := ""
var _multiplier := 1.0

## Le opzioni del menu, in ordine, e il cursore. Con commessa applicabile sono due
## (FULFILL / SELL OPEN); altrimenti una sola (SELL). `_fulfill_options[i]` dice se
## l'opzione `i` è un FULFILL.
var _options: PackedStringArray = PackedStringArray()
var _fulfill_options: Array[bool] = []
var _cursor := 0

## Stato «SOLD»: dopo la conferma la schermata non torna indietro (la 2.6 porterà il
## menu post-foto). `_done` guarda l'input come `_done` in una fase.
var _done := false
var _sold := false
var _sold_lire := 0
var _declined := false


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


## Unico ingresso. Il target e la qualità danno il titolo; `base` è il payout di
## scaglione già calcolato; `commission` è la commessa della notte (`{}` se nessuna).
## Da qui si decide se la commessa è applicabile e si compone il menu.
func set_readout(target: String, quality: int, base: int, commission: Dictionary) -> void:
	_target = target
	_quality = quality
	_base = base
	_commission = commission

	# L'applicabilità è pura e vive in `Commission.applies_to` (unica sorgente di
	# verità, collaudata al banco): questa schermata la CHIAMA, non la ricalcola. Copre
	# la foto senza nome (DW-3) e la commessa dal target diverso — entrambe → SELL.
	_applicable = Commission.applies_to(StringName(target), commission)
	_client_name = String(commission.get(Commission.CLIENT_NAME, ""))
	_multiplier = float(commission.get(Commission.MULTIPLIER, 1.0))

	_options = PackedStringArray()
	_fulfill_options = []
	if _applicable:
		_options.append("FULFILL %s x%s" % [_client_name.to_upper(), _fmt_mult(_multiplier)])
		_fulfill_options.append(true)
		_options.append("SELL OPEN")
		_fulfill_options.append(false)
	else:
		_options.append("SELL")
		_fulfill_options.append(false)
	_cursor = 0
	queue_redraw()


## Passa allo stato «SOLD — N LIRE». Se la vendita è un rifiuto della commessa
## (SELL OPEN su una commessa applicabile), mostra la riga gentile del «niente».
func show_sold(lire: int) -> void:
	_sold = true
	_sold_lire = lire
	# Rifiutata ⟺ la commessa ERA applicabile ma il giocatore non ha scelto FULFILL.
	_declined = _applicable and not _fulfill_options[_cursor]
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Nello stato «SOLD» il menu di vendita è inerte, ma la conferma non lo è più:
	# congeda la schermata e porta al menu post-foto (2.6). È deferito a valle da
	# `dismissed`, perché nasce nell'input di questo Control che l'orchestratore sta
	# per liberare. Va PRIMA della guardia `_done`, che dopo la vendita è true.
	if _sold:
		if event.is_action_pressed(&"sale_confirm"):
			dismissed.emit()
			get_viewport().set_input_as_handled()
		return

	# Guardato da `_done`, come le fasi: dopo la conferma l'input non muove più nulla,
	# e la schermata «SOLD» resta finché il giocatore non congeda con conferma.
	if _done:
		return

	# AZIONI PROPRIE `sale_*`, non le `ui_*`: `ui_accept` è il tasto con cui ci si
	# siede, ed ereditarlo confermerebbe la vendita nel frame stesso in cui la
	# schermata compare. Modello: `phase_targeting._unhandled_input`.
	if event.is_action_pressed(&"sale_up"):
		_cursor = (_cursor - 1 + _options.size()) % _options.size()
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"sale_down"):
		_cursor = (_cursor + 1) % _options.size()
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"sale_confirm"):
		_done = true
		confirmed.emit(_fulfill_options[_cursor])
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)

	# Una foto senza nome (DW-3) si mostra come «UNTITLED», non come titolo vuoto.
	var name_up := _target.to_upper() if not _target.is_empty() else "UNTITLED"
	_text(Vector2(8, 22), "SELL — %s" % name_up, FG, 12)
	_text(Vector2(8, 38), "QUALITY %d" % _quality, DIM, 12)

	if _sold:
		_draw_sold()
		return

	_text(Vector2(8, 62), "BASE %d LIRE" % _base, FG, 12)
	if _applicable:
		_text(Vector2(8, 78), "%s wants %s" % [_client_name, _target.to_upper()], DIM, 12)

	# Il menu: l'opzione selezionata risalta. Un cursore «>» rende la scelta leggibile
	# sullo schermo curvo anche prima che il colore si noti.
	var y := 108
	for i in _options.size():
		var selected := i == _cursor
		var mark := "> " if selected else "  "
		var col := SEL if selected else FG
		_text(Vector2(8, y), "%s%s" % [mark, _options[i]], col, 12)
		y += 16

	_text(Vector2(8, 182), "up/down choose — enter confirm", DIM, 12)


func _draw_sold() -> void:
	_text(Vector2(8, 84), "SOLD — %d LIRE" % _sold_lire, SEL, 14)
	if _declined:
		# Il «niente» reso percepibile (NFR20): una riga gentile, tono cozy. Nessuna
		# penalità, nessuna traccia — solo il base pagato.
		_text(Vector2(8, 108), "declined — no harm", DIM, 12)
	_text(Vector2(8, 182), "press enter for options", DIM, 12)


## Formatta il moltiplicatore senza zeri inutili: 1.4 → "1.4", 1.0 → "1".
func _fmt_mult(m: float) -> String:
	if m == floor(m):
		return "%d" % int(m)
	return "%s" % m


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
