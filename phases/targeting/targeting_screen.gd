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

## LA MAPPA DEL CAROSELLO STA IN TESTA, e non è una preferenza estetica: è l'unico
## posto da cui non ruba spazio alla descrizione.
##
## Prima stava in fondo (y=170) con un titolo "TARGETING / TONIGHT" in cima, e fra
## i due restavano 84 pixel per la descrizione — sei righe a corpo 10, contro le
## sette che M42 richiede (260 caratteri). Il risultato era una frase tagliata a
## metà su un catalogo di sei voci, cioè su tutto il contenuto che questa fase ha.
## Guardandola in gioco, Federico l'ha chiamata «bella strettina», ed era esatto.
##
## Il titolo è sparito perché la striscia lo dice meglio: sei sigle in fila SONO
## «stai scegliendo fra questi», e chi è arrivato qui ha appena scelto TARGETING
## dal monitor. Fra le due, la riga che si può togliere è quella che ripete.
const STRIP_TOP := 14.0

## Le due sponde fra cui vive la descrizione. Il numero massimo di righe si RICAVA
## da queste invece di essere battuto a mano, così spostare una sponda sposta anche
## il limite e non c'è modo che le due misure divergano.
const DESC_TOP := 80.0

## Il piede della descrizione: dove comincia la riga dei comandi, meno il suo
## ingombro. Non è `FOOTER_TOP` esatto perché `draw_string` posiziona la BASE del
## testo: la riga dei comandi occupa i pixel SOPRA la propria y.
const DESC_BOTTOM := 176.0

const FOOTER_TOP := 187.0
const DESC_SIZE := 10

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

	if _catalog.is_empty() or _cursor < 0 or _cursor >= _catalog.size():
		_text(Vector2(MARGIN, 40), "NO CATALOG", DIM, 12)
		return

	# La striscia per PRIMA: è l'intestazione oltre che la mappa.
	_draw_index_strip()
	_draw_detail(_catalog[_cursor])
	_text(Vector2(MARGIN, FOOTER_TOP), "UP/DOWN SELECT   ENTER CONFIRM", FAINT, 10)


func _draw_detail(t: Dictionary) -> void:
	# SIGLA E NOME SULLA STESSA RIGA. Erano due righe (y=33 e y=46), e le due cose
	# insieme non superano i 26 caratteri nemmeno con "M31 Galassia di Andromeda":
	# la seconda riga era spazio regalato alla spaziatura invece che al testo.
	var short: String = t.get(&"short", "")
	_text(Vector2(MARGIN, 34), "%s  %s" % [short, String(t.get(&"full", ""))], FG, 12)

	# Il tipo scende qui accanto ai numeri: è un dato tecnico fra dati tecnici, e in
	# cima faceva concorrenza alla sigla senza aggiungerle niente.
	var type: StringName = t.get(&"type", &"")
	var diff: int = t.get(&"diff", 0)
	var min_exp: int = t.get(&"min_exp", 0)
	_text(Vector2(MARGIN, 48), "%s   DIFF %d   MIN %dm" % [type, diff, min_exp], DIM, 12)

	# Disponibilità: diegetica, inglese, informativa e non gate. Un target fuori
	# finestra mostra la finestra in cui lo sarà, e resta consultabile e
	# selezionabile.
	var available: bool = t.get(&"available", false)
	var window: String = t.get(&"window", "")
	if available:
		_text(Vector2(MARGIN, 62), "visible now", FG, 12)
	else:
		_text(Vector2(MARGIN, 62), "not visible now - %s" % window, DIM, 12)

	# Descrizione narrativa, in italiano, wrappata alla larghezza del vetro.
	#
	# `max_lines` NON è -1. Senza tetto il testo scorre oltre il piede, e non con un
	# catalogo ipotetico: M42 ha 260 caratteri. Con la striscia spostata in testa le
	# righe disponibili sono sette invece di sei, che è quanto M42 chiede — ma il
	# tetto resta, perché la prossima descrizione scritta da qualcuno non ha nessun
	# obbligo di stare in 260 caratteri, e deve troncare invece di sfondare il piede.
	var desc: String = t.get(&"desc", "")
	var line_h := _font.get_height(DESC_SIZE)
	var max_lines := maxi(1, int((DESC_BOTTOM - DESC_TOP) / line_h))
	draw_multiline_string(
		_font, Vector2(MARGIN, DESC_TOP), desc,
		HORIZONTAL_ALIGNMENT_LEFT, DESIGN_SIZE.x - MARGIN * 2, DESC_SIZE, max_lines, DIM)


## La striscia indice: le sei sigle IN TESTA, con l'evidenza sulla corrente e il
## dimming su quelle non disponibili. È la mappa del carosello e insieme
## l'intestazione della schermata — vedi il perché su `STRIP_TOP`.
func _draw_index_strip() -> void:
	var x := float(MARGIN)
	var y := STRIP_TOP
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
