## L'interfaccia della fase di targeting, disegnata per un CRT da 256x192.
##
## È solo una vista: non calcola niente, non conosce `truth`, non sa cosa sia una
## sorgente di verità. La fase le passa l'elenco già pronto con `set_readout()` e
## lei disegna il target in dettaglio più la striscia indice. Modello/idioma:
## la vista della fase polare.
##
## CAROSELLO, NON LISTA INTEGRALE. A 256x192 non entrano sei righe complete più
## sei descrizioni: si mostra UN target alla volta con tutti i suoi campi, più una
## striscia con le sei sigle e l'evidenza sulla corrente. Scorrendo si legge ogni
## target — è la lettura onesta del vincolo di leggibilità.
##
## Il testo dell'interfaccia è in INGLESE (la lingua delle macchine); la
## descrizione narrativa del target è in ITALIANO, perché è contenuto per il
## giocatore. La segnalazione «not visible now» è diegetica, in inglese, e NON
## blocca la consultazione né la selezione.
extends Control

const DESIGN_SIZE := Vector2(256, 192)

## Colori del fosforo verde, ripresi dallo spike del CRT: scelti guardandoli
## sullo schermo curvo, non stimati. Stessi valori della vista polare.
const BG := Color(0.02, 0.06, 0.03)
const FG := Color(0.62, 1.0, 0.68)
const DIM := Color(0.30, 0.58, 0.34)
const FAINT := Color(0.18, 0.34, 0.20)

## Il margine sinistro del testo, come nella vista polare.
const MARGIN := 8

var _font: SystemFont

var _catalog: Array[Dictionary] = []
var _cursor := 0


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


## Unico ingresso della vista. La fase chiama questo e basta.
func set_readout(catalog: Array[Dictionary], cursor: int) -> void:
	_catalog = catalog
	_cursor = cursor
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)
	_text(Vector2(MARGIN, 15), "TARGETING / TONIGHT", FG, 12)

	if _catalog.is_empty() or _cursor < 0 or _cursor >= _catalog.size():
		_text(Vector2(MARGIN, 40), "NO CATALOG", DIM, 12)
		return

	var t := _catalog[_cursor]
	_draw_detail(t)
	_draw_index_strip()
	_text(Vector2(MARGIN, 184), "UP/DOWN SELECT  ENTER CONFIRM", DIM, 12)


func _draw_detail(t: Dictionary) -> void:
	var short: String = t.get(&"short", "")
	var type: StringName = t.get(&"type", &"")
	# Riga sigla + tipo: sono da macchina, restano in inglese.
	_text(Vector2(MARGIN, 33), "%s  %s" % [short, type], FG, 12)

	# Nome esteso, in italiano: è narrativa. Dim per distinguerlo dai dati tecnici.
	_text(Vector2(MARGIN, 46), String(t.get(&"full", "")), DIM, 12)

	# DIFF e MIN sono etichette da macchina, in inglese.
	var diff: int = t.get(&"diff", 0)
	var min_exp: int = t.get(&"min_exp", 0)
	_text(Vector2(MARGIN, 61), "DIFF %d   MIN %dm" % [diff, min_exp], FG, 12)

	# Disponibilità: diegetica, inglese, informativa e non gate. Un target fuori
	# finestra mostra la finestra in cui lo sarà, e resta consultabile e
	# selezionabile.
	var available: bool = t.get(&"available", false)
	var window: String = t.get(&"window", "")
	if available:
		_text(Vector2(MARGIN, 74), "visible now", FG, 12)
	else:
		_text(Vector2(MARGIN, 74), "not visible now - %s" % window, DIM, 12)

	# Descrizione narrativa, in italiano, wrappata alla larghezza del vetro.
	var desc: String = t.get(&"desc", "")
	draw_multiline_string(
		_font, Vector2(MARGIN, 92), desc,
		HORIZONTAL_ALIGNMENT_LEFT, DESIGN_SIZE.x - MARGIN * 2, 10, -1, DIM)


## La striscia indice: le sei sigle in fondo, con l'evidenza sulla corrente e il
## dimming su quelle non disponibili. È la mappa del carosello.
func _draw_index_strip() -> void:
	var x := float(MARGIN)
	var y := 170.0
	for i in _catalog.size():
		var entry := _catalog[i]
		var short: String = entry.get(&"short", "")
		var available: bool = entry.get(&"available", false)
		var color := FAINT
		if i == _cursor:
			color = FG
		elif available:
			color = DIM
		_text(Vector2(x, y), short, color, 10)
		# Passo fisso per sigla: M42/M13/... stanno tutte in <= 4 caratteri, sei
		# voci entrano nei 256 px con margine.
		x += 40.0


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
