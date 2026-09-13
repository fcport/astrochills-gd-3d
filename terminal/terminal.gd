## Il terminale gestionale: il secondo programma del PC dell'osservatorio.
##
## COS'È, E DOVE VIVE. Un `Control` mostrato sul CRT con `show_control()`, esattamente
## come le schermate della notte — ma NON appartiene alla loro cartella. Vive nella
## propria, che dipende solo da `core/`, `data/` e dagli autoload (`Game`, `Events`):
## non conosce il mondo, la notte, né le fasi. Il confine si prova con un grep sui nomi
## di quelle cartelle dentro questa, e deve restare a zero — per questo qui non si
## nominano nemmeno nei commenti, come già fa l'orchestratore della notte. Il CRT non sa
## cosa mostra; il ponte fra questo Control e la notte è il punto d'ingresso, l'unico che
## conosce entrambe le sponde.
##
## COSA VENDE. Solo gli articoli con `implemented == true`, da due categorie: PERSONAL
## e FACILITIES. Le altre categorie di `economia.md` non compaiono affatto, nemmeno
## disabilitate — un menu che promette cose che non ci sono è peggio di un menu corto.
## Gli articoli non implementati restano nei `.tres` ma il filtro
## `ItemCatalog.for_category()` li tiene fuori.
##
## OGGI VENDE SOLO LA MOKA, ed è la stessa regola portata fino in fondo: è l'unico
## articolo il cui oggetto esiste nel mondo. La lampadina è uscita dal gioco insieme
## alla lampada (D-236). Un negozio che vende cose che non compaiono è un buco
## invisibile, peggio di un negozio corto.
##
## LA SPESA PASSA DA `Game`, COME LA SOMMA. `wallet_now()` è la sola somma; comprare è
## `Game.can_afford()` + `Game.spend_lire()`. Questo Control NON scala lire da sé, NON
## tocca `NightRun` né `PlayerProfile.wallet_lire` direttamente: chiede a `Game`, poi
## marca il possesso e ANNUNCIA con `Events.item_purchased(id)`. Il possesso è del
## giocatore (C1), persiste nel save — lo salva `Game.spend_lire`.
##
## NESSUN BONUS MECCANICO, MAI. Comprare non altera nessun punteggio, e da nessuna parte
## qui è scritto che potrebbe (regola dell'epica).
##
## LE DUE LINGUE (NFR10). L'interfaccia è in INGLESE (software MS-DOS del 1999); le
## descrizioni prodotto (`blurb`) sono in ITALIANO, dietro il tasto descrizione. L'esito
## «fondi insufficienti» è diegetico e in inglese sul vetro (UX-DR10): nessun modale.
##
## Disegnato per 256x192, fosforo verde su nero, come le altre viste del CRT.
extends Control

## Il giocatore esce dal terminale col tasto back/quit. Signal DIRETTO — l'ascoltatore
## è uno solo, il punto d'ingresso, che lo mostra e ripristina il contenuto sotto.
signal closed()

const DESIGN_SIZE := Vector2(256, 192)

const BG := Phosphor.BG
const FG := Phosphor.FG
const DIM := Phosphor.DIM
## L'articolo selezionato risalta in pieno fosforo; gli altri restano in `FG`.
const SEL := Phosphor.SEL

const CATALOG_PATH := "res://data/catalog/catalog.tres"

## Le due categorie dell'MVP, nell'ordine di visualizzazione. NON esiste una terza:
## le altre di `economia.md` non compaiono affatto. La coppia (chiave dato, titolo EN).
const CATEGORIES := [
	[&"personal", "PERSONAL"],
	[&"facilities", "FACILITIES"],
]

var _font: SystemFont

## La lista PIATTA degli articoli in vendita, in ordine di categoria — è ciò su cui
## scorre il cursore. Ogni voce è un `ItemData` implementato; l'intestazione di
## categoria si disegna quando la categoria cambia fra una voce e la precedente.
var _rows: Array[ItemData] = []
var _cursor := 0

## Vero mentre si legge la descrizione italiana dell'articolo selezionato: il tasto
## descrizione entra qui e ne esce, e in questa vista su/giù/acquisto sono inerti.
var _showing_desc := false

## L'ultimo messaggio diegetico in inglese (es. "NOT ENOUGH LIRE", "PURCHASED"), o "".
## È l'esito sul vetro — mai un modale.
var _message := ""


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	_load_rows()


## Riporta il terminale allo stato interattivo all'apertura: cursore in cima, nessuna
## descrizione aperta, nessun messaggio. Lo chiama `main.gd` quando mostra il terminale,
## come `post_photo_menu.arm()`. Ricarica anche il catalogo, così `OWNED` riflette gli
## acquisti fatti nella sessione.
func arm() -> void:
	_cursor = 0
	_showing_desc = false
	_message = ""
	_load_rows()
	queue_redraw()


## Legge il catalogo e ricostruisce la lista piatta degli articoli in vendita.
##
## CATALOGO ASSENTE/ILLEGGIBILE (I/O matrix): `load` torna `null`; il terminale mostra
## le categorie vuote senza crash, e avvisa su canale 1 — è un errore di programma (un
## dato di gioco mancante), non un fatto per il giocatore.
func _load_rows() -> void:
	_rows = []
	var catalog := load(CATALOG_PATH) as ItemCatalog
	if catalog == null:
		push_error("[terminal] catalogo assente o illeggibile: %s" % CATALOG_PATH)
		_cursor = 0
		return
	for entry in CATEGORIES:
		for item in catalog.for_category(entry[0]):
			_rows.append(item)
	_cursor = clampi(_cursor, 0, maxi(0, _rows.size() - 1))


func _unhandled_input(event: InputEvent) -> void:
	# BACK/QUIT chiude sempre: da una descrizione torna alla vista prezzi, dalla vista
	# prezzi esce dal terminale. È il tasto d'uscita, l'unico che non dipende dallo stato.
	if event.is_action_pressed(&"terminal_back"):
		if _showing_desc:
			_showing_desc = false
			queue_redraw()
		else:
			closed.emit()
		get_viewport().set_input_as_handled()
		return

	# DESCRIZIONE: entra nella descrizione italiana dell'articolo selezionato, o ne
	# esce ri-premendo (torna alla vista prezzi). Nessun effetto se la lista è vuota.
	if event.is_action_pressed(&"terminal_desc"):
		if not _rows.is_empty():
			_showing_desc = not _showing_desc
			_message = ""
			queue_redraw()
		get_viewport().set_input_as_handled()
		return

	# Nella descrizione, navigazione e acquisto sono inerti: si legge e basta.
	if _showing_desc:
		return

	if event.is_action_pressed(&"menu_up"):
		_move_cursor(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"menu_down"):
		_move_cursor(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"menu_confirm"):
		_try_buy()
		get_viewport().set_input_as_handled()


func _move_cursor(delta: int) -> void:
	if _rows.is_empty():
		return
	_cursor = (_cursor + delta + _rows.size()) % _rows.size()
	_message = ""
	queue_redraw()


## Prova a comprare l'articolo selezionato. Tre esiti, tutti diegetici sul vetro:
##   - già posseduto → nessuna spesa (la voce mostra già OWNED, ma il messaggio lo dice);
##   - fondi insufficienti → "NOT ENOUGH LIRE", il portafoglio non cambia;
##   - fondi sufficienti → il possesso è marcato, la spesa scala il portafoglio (via
##     `Game`) e SALVA entrambi in un colpo, poi si emette `Events.item_purchased(id)`.
##
## PERCHÉ MARCARE PRIMA DI `spend_lire`. `Game.spend_lire` salva il profilo dopo aver
## scalato le lire: marcare il possesso PRIMA fa sì che quello stesso salvataggio scriva
## anche `owned_items` — un solo save, portafoglio e possesso persistiti insieme. `Game`
## non sa cosa si compra (come `wallet_now()` non lo sa): il possesso lo marca il
## chiamante, la deduzione e il salvataggio li fa `Game`.
##
## `can_afford` GIÀ CONTROLLATO: dopo di esso `spend_lire` non fallisce per fondi. La
## sua guardia interna resta cintura e bretelle — se un giorno fallisse, il possesso
## marcato non sarebbe stato salvato (lo save è dentro `spend_lire`), quindi non resta
## niente di sporco in memoria che il prossimo save cristallizzerebbe.
func _try_buy() -> void:
	if _rows.is_empty():
		return
	var item := _rows[_cursor]
	if Game.profile.owns(item.id):
		_message = "ALREADY OWNED"
		queue_redraw()
		return
	if not Game.can_afford(item.price):
		_message = "NOT ENOUGH LIRE"
		queue_redraw()
		return
	Game.profile.mark_owned(item.id)
	if not Game.spend_lire(item.price):
		# Non affordabile è già escluso: questo ramo è la rete. Il possesso appena marcato
		# non è stato salvato (lo save vive dentro `spend_lire`), quindi si toglie per non
		# lasciare in memoria un possesso senza spesa.
		Game.profile.owned_items.erase(item.id)
		_message = "NOT ENOUGH LIRE"
		queue_redraw()
		return
	Events.item_purchased.emit(item.id)
	_message = "PURCHASED"
	Log.info("terminal", "acquistato %s per %d lire" % [item.id, item.price])
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)
	# CORNICE a linea singola, come la finestra di testo di un software DOS (AC2). Un
	# rettangolo di contorno inset di pochi px: «linee singole» senza dover allineare
	# caratteri di box-drawing al passo del font — si sostituirà con i caratteri veri
	# quando il look si rifinirà.
	draw_rect(Rect2(Vector2(3, 3), DESIGN_SIZE - Vector2(6, 6)), DIM, false, 1.0)

	# INTESTAZIONE in INGLESE (NFR10): WALLET (la somma sola, `wallet_now()`) e NIGHT
	# TAKE (la presa che ti resta, `run.night_earnings`). Entrambi da `Game` — la vista
	# non ricalcola la somma.
	_text(Vector2(9, 16), "ASTROCHILL INVENTORY v1.0", DIM, 11)
	_text(Vector2(9, 32), "WALLET %d LIRE" % Game.wallet_now(), FG, 12)
	_text(Vector2(9, 46), "NIGHT TAKE %d" % _night_take(), DIM, 11)
	# Riga sotto l'intestazione, come la linea del mockup fra WALLET e le voci.
	draw_line(Vector2(6, 54), Vector2(DESIGN_SIZE.x - 6, 54), DIM, 1.0)

	if _showing_desc:
		_draw_desc()
		return

	_draw_catalog()


## Le due categorie e le loro voci numerate. Si itera `CATEGORIES`, non le righe: così
## PERSONAL e FACILITIES compaiono SEMPRE entrambe (AC3), anche se una restasse senza
## articoli in vendita — mostra `(none)` invece di sparire. Il numero è per l'occhio
## (menu numerato, AC2); il cursore resta l'indice piatto in `_rows`, in ordine di
## categoria, così su/giù scorrono la lista e il numero mostrato la segue.
func _draw_catalog() -> void:
	var y := 64
	var num := 0
	for entry in CATEGORIES:
		var cat: StringName = entry[0]
		_text(Vector2(9, y), entry[1], DIM, 11)
		y += 13
		var any := false
		for i in _rows.size():
			var item := _rows[i]
			if item.category != cat:
				continue
			any = true
			num += 1
			var selected := i == _cursor
			var mark := ">" if selected else " "
			var col := SEL if selected else FG
			var owned := Game.profile.owns(item.id)
			var right := "OWNED" if owned else "%d L" % item.price
			_text(Vector2(9, y), "%s %d. %s" % [mark, num, item.label], col, 12)
			_text(Vector2(196, y), right, DIM if owned else col, 11)
			y += 15
		if not any:
			# Categoria senza articoli in vendita: resta a schermo, vuota — non sparisce.
			_text(Vector2(9, y), "   (none)", DIM, 11)
			y += 15

	# L'esito diegetico, in inglese, sul vetro — mai un modale.
	if not _message.is_empty():
		_text(Vector2(9, 168), _message, SEL, 12)

	_text(Vector2(9, 182), "w/s  enter buy  tab desc  esc quit", DIM, 10)


func _draw_desc() -> void:
	# Guardia: `_showing_desc` si accende solo con `_rows` non vuoto e la lista non cambia
	# mentre la descrizione è aperta, ma la rete costa una riga e toglie ogni OOB.
	if _rows.is_empty():
		return
	var item := _rows[_cursor]
	_text(Vector2(9, 68), item.label, SEL, 12)
	# La descrizione è ITALIANA e può essere lunga: si manda a capo esplicitamente entro
	# i 256 px del vetro — nessun testo troncato in silenzio.
	var y := 88
	for line in _wrap(item.blurb, 42):
		_text(Vector2(8, y), line, FG, 11)
		y += 13
	_text(Vector2(8, 182), "tab / esc back to prices", DIM, 10)


## La presa della notte che resta: `run.night_earnings`, o 0 se non c'è una notte.
## Passa da `Game.run`, come tutto il resto — è la sola sorgente.
func _night_take() -> int:
	return Game.run.night_earnings if Game.run != null else 0


## Manda a capo `text` a parole entro `width` caratteri. Monospace, quindi contare i
## caratteri basta a stare nel vetro — niente misure di pixel, coerente con lo stile
## delle altre viste del CRT.
func _wrap(text: String, width: int) -> PackedStringArray:
	var out := PackedStringArray()
	var line := ""
	for word in text.split(" ", false):
		if line.is_empty():
			line = word
		elif line.length() + 1 + word.length() <= width:
			line += " " + word
		else:
			out.append(line)
			line = word
	if not line.is_empty():
		out.append(line)
	return out


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
