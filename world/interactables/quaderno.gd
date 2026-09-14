## IL QUADERNO DELLE PROCEDURE, sulla consolle accanto al monitor.
##
## LA RICHIESTA, DA FEDERICO: «di fianco al pc a sinistra, un libro con le istruzioni
## per giocare e fare le varie fasi». Fra un raccoglitore d'ufficio, un volume
## rilegato e un organizer di pelle ad anelli ha scelto il terzo, e ha deciso che
## prende il posto del «foglio di procedura appeso al monitor» del GDD: la sequenza
## della notte la insegna questo, e di fogli appesi non ce ne sono (D-233).
##
## COSA FA. Guardandolo da vicino, `E` lo apre: il controllo del giocatore si
## sospende, e sopra la stanza compare il quaderno aperto, due pagine alla volta.
## Si sfoglia con A e D, con la rotella o cliccando sulla pagina; si
## chiude con `E` o Esc. È la stessa forma dell'oculare (`oculare.gd`): un gesto
## che mette l'occhio da qualche parte e un tasto per toglierlo.
##
## LA CARTA VIVE NEL VIEWPORT DEL MONDO, come il velo dell'oculare e il prompt: è
## un `CanvasLayer` figlio di questo nodo, quindi ha la grana della stanza e passa
## dal filtro come tutto il resto. Nitido a piena risoluzione sarebbe un'interfaccia
## moderna appoggiata sopra un gioco del 1999.
##
## L'A CAPO NON LO FA IL `Label`, e il perché sta in `QuadernoData`: le righe le
## calcola una funzione pura a colonne, la stessa con cui il banco controlla che
## nessuna pagina esca dal foglio. Il font è a spaziatura fissa per questo — e perché
## i fogli di un raccoglitore del 1999 sono battuti a macchina.
class_name Quaderno
extends Interactable

## Chi ha bisogno del quaderno lo trova per GRUPPO, mai per percorso: stessa regola
## del monitor, dell'oculare e della montatura.
const GROUP := &"quaderno"

## Le pagine. Un `.tres` e non un testo nel codice: il contenuto si corregge senza
## toccare la logica, e il banco lo collauda dal file che il gioco carica davvero.
const PAGINE_PATH := "res://data/quaderno/quaderno.tres"

## LE MISURE DELLA CARTA, in pixel del viewport del mondo (640x360). Sono tarate
## guardando uno scatto (`tools/prova_quaderno.gd`), non stimate: una riga in più o
## in meno si vede solo con il quaderno aperto davanti.
const CORPO := 12
const INTERLINEA := -1
const MARGINE := 10
const PAGINA := Vector2(300.0, 318.0)
const DORSO := 12.0
const BORDO_COPERTINA := 5.0

const INCHIOSTRO := Color(0.13, 0.12, 0.15)
const CARTA := Color(0.87, 0.84, 0.75)
const CARTA_OMBRA := Color(0.78, 0.74, 0.65)
const PELLE := Color(0.22, 0.13, 0.08)
const OTTONE := Color(0.72, 0.58, 0.30)

## La riga in basso che dice come si sfoglia. Stessa resa del prompt d'interazione,
## ed è la sola cosa non diegetica di questa vista: senza, chi apre il quaderno la
## prima volta non sa che le pagine sono più di due.
const RIGA_TASTI := "[A/D] sfoglia    [E] chiudi"

## Emesso aprendo e chiudendo: è un FATTO del mondo, e chi vorrà saperlo — la
## telemetria dell'attesa, un biglietto della prima notte — lo ascolta.
signal letto(aperto: bool)

var _dati: QuadernoData
var _foglio: CanvasLayer
var _testo_sx: Label
var _testo_dx: Label
var _numero_sx: Label
var _numero_dx: Label
var _aperto := false
var _chi: Player = null

## La pagina di sinistra della coppia aperta, sempre pari. Resta dov'era fra una
## lettura e l'altra: si riapre il quaderno dove lo si era lasciato, come un
## quaderno vero con la pagina tenuta dalla cinghietta.
var _pagina := 0

## Il fotogramma in cui si è aperto. La stessa pressione di `E` che apre il quaderno
## passa dal giocatore e POI, nello stesso giro di consegna degli eventi, può
## arrivare anche qui: senza questo controllo lo si aprirebbe e richiuderebbe con un
## tasto solo, e sembrerebbe che non faccia niente.
var _aperto_al := -1


static func find_in(tree: SceneTree) -> Quaderno:
	return tree.get_first_node_in_group(GROUP) as Quaderno


func _ready() -> void:
	add_to_group(GROUP)
	_dati = load(PAGINE_PATH) as QuadernoData
	if _dati == null or _dati.pagine.is_empty():
		# Canale 1: è un errore di programma, non una cosa che il giocatore debba
		# leggere. Il quaderno si spegne invece di aprirsi su due pagine bianche.
		push_error("[quaderno] pagine assenti o illeggibili: %s" % PAGINE_PATH)
		enabled = false
		return
	interacted.connect(_su_interazione)
	set_process_unhandled_input(false)
	set_process(false)


## Se in questo momento il quaderno è aperto davanti agli occhi.
func aperto() -> bool:
	return _aperto


## L'indice della pagina di sinistra aperta adesso. Serve alle sonde.
func pagina() -> int:
	return _pagina


## Quante pagine ha il quaderno.
func quante_pagine() -> int:
	return 0 if _dati == null else _dati.pagine.size()


func _su_interazione(chi: Node3D) -> void:
	if _aperto:
		_chiudi()
	else:
		_apri(chi as Player)


func _apri(chi: Player) -> void:
	if _aperto or _dati == null:
		return
	_aperto = true
	_aperto_al = Engine.get_process_frames()
	_chi = chi
	# IL CONTROLLO SI TOGLIE PRIMA DI MOSTRARE LA CARTA, come all'oculare: con il
	# controller acceso il mouse girerebbe una testa che nessuno vede, e chiudendo
	# ci si ritroverebbe voltati verso il muro.
	if _chi != null:
		_chi.set_enabled(false)
		_chi.mostra_mirino(false)
	_costruisci()
	_mostra()
	_foglio.visible = true
	set_process_unhandled_input(true)
	set_process(true)
	letto.emit(true)


func _chiudi() -> void:
	if not _aperto:
		return
	_aperto = false
	set_process_unhandled_input(false)
	set_process(false)
	if _foglio != null:
		_foglio.visible = false
	if _chi != null:
		_chi.mostra_mirino(true)
		_chi.set_enabled(true)
	_chi = null
	letto.emit(false)


## SE QUALCUN ALTRO RIDÀ IL CONTROLLO AL GIOCATORE, il quaderno si chiude. Oggi può
## farlo solo la sequenza dell'alba, che rimette il corpo al punto di partenza: senza
## questo controllo il giocatore camminerebbe per la stanza con il quaderno
## incollato davanti agli occhi, e nessun tasto lo toglierebbe più — il suo `E`
## andrebbe al mondo, non a lui.
func _process(_delta: float) -> void:
	if _aperto and _chi != null and _chi.is_enabled():
		_chi = null
		_chiudi()


func _unhandled_input(event: InputEvent) -> void:
	if not _aperto or Engine.get_process_frames() == _aperto_al:
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_chiudi()
	elif event.is_action_pressed(&"move_right"):
		get_viewport().set_input_as_handled()
		sfoglia(1)
	elif event.is_action_pressed(&"move_left"):
		get_viewport().set_input_as_handled()
		sfoglia(-1)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var click := event as InputEventMouseButton
		match click.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				sfoglia(1)
			MOUSE_BUTTON_WHEEL_UP:
				sfoglia(-1)
			MOUSE_BUTTON_LEFT:
				# LA PAGINA CHE SI TOCCA: a destra si va avanti, a sinistra indietro.
				var mezzo := get_viewport().get_visible_rect().size.x / 2.0
				sfoglia(1 if click.position.x >= mezzo else -1)
		get_viewport().set_input_as_handled()


## Gira di `verso` coppie di pagine, fermandosi alla prima e all'ultima. Pubblica
## perché le sonde sfogliano come sfoglia il giocatore, senza fabbricare tasti.
func sfoglia(verso: int) -> void:
	if _dati == null:
		return
	var nuova := clampi(_pagina + 2 * signi(verso), 0, _ultima_coppia())
	if nuova == _pagina:
		return
	_pagina = nuova
	if _aperto:
		_mostra()


## La pagina di sinistra dell'ultima coppia: con sette pagine è la sesta (indice 6),
## che resta sola a sinistra con la destra bianca, come in un quaderno vero.
func _ultima_coppia() -> int:
	var n := _dati.pagine.size()
	return maxi(0, (n - 1) - ((n - 1) % 2))


func _mostra() -> void:
	_testo_sx.text = _righe(_pagina)
	_testo_dx.text = _righe(_pagina + 1)
	_numero_sx.text = "- %d -" % (_pagina + 1)
	_numero_dx.text = "- %d -" % (_pagina + 2) if _pagina + 1 < _dati.pagine.size() else ""


func _righe(indice: int) -> String:
	return "\n".join(_dati.righe_pagina(indice))


## La carta si costruisce la prima volta che si apre il quaderno, e poi si tiene: chi
## non lo apre mai non paga niente, e chi lo apre dieci volte non lo ricostruisce
## dieci volte.
func _costruisci() -> void:
	if _foglio != null:
		return
	var schermo := get_viewport().get_visible_rect().size
	_foglio = CanvasLayer.new()
	_foglio.name = "FoglioQuaderno"
	var radice := Control.new()
	radice.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foglio.add_child(radice)

	# LA STANZA SI ABBASSA, e non sparisce: resta sotto, un po' più buia, perché il
	# quaderno lo si legge stando lì e non in un menu.
	_rettangolo(radice, Vector2.ZERO, schermo, Color(0.0, 0.0, 0.0, 0.55))

	var aperto := Vector2(PAGINA.x * 2.0 + DORSO, PAGINA.y)
	var origine := ((schermo - aperto) / 2.0).floor() - Vector2(0.0, 7.0)
	# la copertina di pelle, che sborda di qualche pixel attorno alla carta
	_rettangolo(radice, origine - Vector2.ONE * BORDO_COPERTINA,
		aperto + Vector2.ONE * BORDO_COPERTINA * 2.0, PELLE)
	var sx := origine
	var dx := origine + Vector2(PAGINA.x + DORSO, 0.0)
	_rettangolo(radice, sx, PAGINA, CARTA)
	_rettangolo(radice, dx, PAGINA, CARTA)
	# L'OMBRA VERSO GLI ANELLI: la carta appesa si incurva verso il dorso, e una
	# striscia più scura è quello che fa leggere due rettangoli come due pagine.
	_rettangolo(radice, sx + Vector2(PAGINA.x - 6.0, 0.0), Vector2(6.0, PAGINA.y), CARTA_OMBRA)
	_rettangolo(radice, dx, Vector2(6.0, PAGINA.y), CARTA_OMBRA)
	# gli anelli d'ottone, a cavallo del dorso
	for k in 6:
		var y := origine.y + PAGINA.y * (0.12 + 0.152 * k)
		_rettangolo(radice, Vector2(sx.x + PAGINA.x - 5.0, y), Vector2(DORSO + 10.0, 3.0), OTTONE)

	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	_testo_sx = _scritta(radice, font, sx + Vector2(MARGINE + 4.0, MARGINE))
	_testo_dx = _scritta(radice, font, dx + Vector2(MARGINE + 6.0, MARGINE))
	_numero_sx = _numero(radice, font, sx)
	_numero_dx = _numero(radice, font, dx)

	var tasti := Label.new()
	tasti.add_theme_font_override("font", font)
	tasti.add_theme_font_size_override("font_size", InteractionPrompt.FONT_SIZE - 2)
	tasti.add_theme_color_override("font_color", InteractionPrompt.FG)
	tasti.add_theme_color_override("font_shadow_color", InteractionPrompt.SHADOW)
	tasti.add_theme_constant_override("shadow_offset_x", 1)
	tasti.add_theme_constant_override("shadow_offset_y", 1)
	tasti.text = RIGA_TASTI
	tasti.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radice.add_child(tasti)
	tasti.position = Vector2(origine.x, origine.y + PAGINA.y + BORDO_COPERTINA + 2.0)

	add_child(_foglio)
	_foglio.visible = false


func _rettangolo(padre: Control, dove: Vector2, quanto: Vector2, colore: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = dove
	r.size = quanto
	r.color = colore
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(r)
	return r


func _scritta(padre: Control, font: Font, dove: Vector2) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", CORPO)
	l.add_theme_color_override("font_color", INCHIOSTRO)
	l.add_theme_constant_override("line_spacing", INTERLINEA)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = dove
	padre.add_child(l)
	return l


func _numero(padre: Control, font: Font, pagina_: Vector2) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", CORPO - 2)
	l.add_theme_color_override("font_color", INCHIOSTRO)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = pagina_ + Vector2(0.0, PAGINA.y - 16.0)
	l.size = Vector2(PAGINA.x, 14.0)
	padre.add_child(l)
	return l
