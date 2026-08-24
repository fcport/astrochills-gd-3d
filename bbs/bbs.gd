## La BBS: il secondo programma diegetico del PC dell'osservatorio, gemello del terminale.
##
## COS'È, E DOVE VIVE. Un `Control` mostrato sul CRT con `show_control()`, esattamente
## come il terminale e le schermate della notte — ma NON appartiene alle loro cartelle.
## Vive nella propria, che dipende solo da `core/`, `data/` e dagli autoload (`Game`,
## `Events`): non conosce il mondo, la notte, né le fasi. Il confine si prova con un grep
## sui nomi di quelle cartelle dentro questa, e deve restare a zero — per questo qui non
## si nominano nemmeno nei commenti. Il CRT non sa cosa mostra; il ponte fra questo
## Control e la notte è il punto d'ingresso, l'unico che conosce entrambe le sponde.
##
## È LO STESSO COMPUTER DEL TERMINALE. Stessa cornice a linea singola, stesso fosforo
## verde su nero, stesso font monospace, stesso beep sintetizzato in codice. Le costanti
## estetiche (`BG/FG/DIM/SEL`), il font, il beep, `_wrap`/`_text` si replicano dal
## terminale: è duplicazione DELIBERATA di costanti provvisorie (coerente con la memoria
## sugli asset), non si estrae una base condivisa ora. Due estetiche diverse sullo stesso
## vetro sarebbero un errore di finzione.
##
## LA CONNESSIONE È UN'ATTESA PICCOLA DENTRO L'ATTESA GRANDE. All'`arm()` parte un
## handshake udibile — beep/rumore sintetizzato in codice, nessun asset — che dura qualche
## secondo: il tempo che ci vuole fa parte della cosa, non è un caricamento da nascondere.
## Finché l'handshake gira la vista mostra CONNECTING; poi compare l'elenco.
##
## LE DUE LINGUE (NFR10). La cornice/menu/prompt e i titoli delle aree (`title`) sono
## INGLESE (voce macchina, come `WALLET`/`PERSONAL` del terminale); soggetto e corpo dei
## messaggi sono ITALIANO (scritti da persone). Gli handle degli autori restano com'è.
##
## NESSUN BONUS, NESSUN CONTATORE. Leggere non dà punteggi, sconti, target o suggerimenti,
## e da nessuna parte qui è scritto che potrebbe. Nessun conto alla rovescia, nessun
## badge di «non letti»: la distinzione letto/non-letto è PER RIGA (soggetto in `DIM` se
## letto, `FG` se no) — visibile se la cerchi, non un badge che chiede di essere svuotato.
##
## IL CONDOTTO DI MISURA È SUO (C4). `activate()` emette `wait_activity_started(&"forum")`,
## `deactivate()` emette `wait_activity_ended(&"forum")`, con guardia `_active` per
## l'idempotenza — come la moka e la cupola emettono la propria coppia. L'emissione non
## produce nessun feedback visibile. Un `started` senza `ended` (quit a BBS aperta) è un
## abbandono, un dato per la telemetria (3.6), non un buco.
##
## Disegnato per 256x192, leggibile da seduti.
extends Control

## Il giocatore esce dalla BBS col tasto back/quit. Signal DIRETTO — l'ascoltatore è uno
## solo, il punto d'ingresso, che la mostra e ripristina il contenuto sotto.
signal closed()

const DESIGN_SIZE := Vector2(256, 192)

## Le stesse costanti estetiche del terminale — è lo stesso computer. Duplicazione
## deliberata di valori provvisori, non un'astrazione da estrarre ora.
const BG := Color(0.02, 0.06, 0.03)
const FG := Color(0.62, 1.0, 0.68)
const DIM := Color(0.30, 0.58, 0.34)
const SEL := Color(0.80, 1.0, 0.86)

const FORUM_PATH := "res://data/forum/forum.tres"

## Il marcatore dell'attività per il condotto di misura (C4). La coppia
## `Events.wait_activity_started/ended(&"forum")` racchiude una sessione di lettura.
const ACTIVITY := &"forum"

## Larghezza di a-capo del corpo, in caratteri: monospace, quindi contare i caratteri
## basta a stare nei 256 px del vetro — come il terminale (`_wrap(blurb, 42)`).
const WRAP_WIDTH := 42

## Quante righe di corpo stanno nella finestra di lettura fra l'intestazione e il piede.
## Se il messaggio ne ha di più, si scorre e lo scorrimento è ESPLICITO (indicatori
## ▲/▼). Verificato guardando, non stimato: valore d'operatore, tarabile sul vetro.
const BODY_WINDOW := 8

## Durata dell'handshake del modem 56k, in secondi reali. Qualche secondo: l'attesa
## piccola dentro l'attesa grande. Il tempo che ci vuole fa parte della cosa.
const HANDSHAKE_SEC := 3.0

var _font: SystemFont
var _beep: AudioStreamPlayer
## Il rumore del modem 56k in loop, sintetizzato in codice: l'handshake udibile.
var _handshake: AudioStreamPlayer
## Conta i secondi dell'handshake e poi apre l'elenco. Il tempo REALE (non scalato):
## la connessione dura quello che dura, F1–F4 non la accorciano.
var _connect_timer: Timer

## Le aree del forum, caricate da `forum.tres`. Ogni board sa filtrare i propri
## messaggi per notte con `available()`.
var _boards: Array[ForumBoard] = []

## La lista PIATTA dei messaggi VISIBILI adesso (dopo il filtro per notte), in ordine di
## board — è ciò su cui scorre il cursore. `_row_board_index` dice, per ogni riga, a
## quale board appartiene, così l'intestazione EN si disegna quando la board cambia.
var _rows: Array[ForumMessage] = []
var _row_board_index: PackedInt32Array = PackedInt32Array()
var _cursor := 0

## Le tre viste. `_connecting` vince su tutto (handshake in corso). Poi `_reading`
## distingue elenco (falso) da lettura (vero).
var _connecting := false
var _reading := false

## Cursore di scroll del corpo nella vista di lettura: la prima riga visibile. Clampato
## fra 0 e `max(0, righe - BODY_WINDOW)`.
var _scroll := 0
## Le righe del corpo del messaggio in lettura, già mandate a capo. Ricalcolate
## all'apertura del messaggio (una volta), non a ogni `_draw`.
var _body_lines: PackedStringArray = PackedStringArray()

## Guardia dell'idempotenza della coppia `wait_activity_*`. Vero fra `activate()` e
## `deactivate()`: `activate` non riemette `started` se già attivo, `deactivate` non
## emette `ended` se non attivo. Così ogni percorso di chiusura di `main.gd` (tasto,
## interact, alba, notte nuova) può chiamare `deactivate()` senza sbilanciare la coppia.
var _active := false


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	_install_beep()
	_install_handshake()
	_install_connect_timer()
	_load_boards()


## Riporta la BBS allo stato iniziale all'apertura e AVVIA l'handshake: cursore in cima,
## nessun messaggio aperto, scroll a zero, e la connessione che parte. Lo chiama `main.gd`
## quando mostra la BBS, come `terminal.arm()`/`post_photo_menu.arm()`. Ricarica anche le
## aree e RICOSTRUISCE l'elenco visibile con la notte corrente, così nuovi messaggi
## compaiono col passare delle notti e i letti riflettono i save fatti nella sessione.
##
## NON emette la coppia `wait_activity_*`: quella la fa `activate()`, che `main.gd` chiama
## all'apertura. `arm()` è la messa a punto della vista; `activate()` è il fatto misurato.
func arm() -> void:
	_cursor = 0
	_reading = false
	_scroll = 0
	_body_lines = PackedStringArray()
	_load_boards()
	_rebuild_rows()
	_start_handshake()
	queue_redraw()


## Emette `wait_activity_started(&"forum")` UNA sola volta (guardia `_active`). Lo chiama
## `main.gd` all'apertura, come la moka/la cupola emettono la propria coppia. L'emissione
## non produce nessun feedback visibile.
func activate() -> void:
	if _active:
		return
	_active = true
	Events.wait_activity_started.emit(ACTIVITY)


## Emette `wait_activity_ended(&"forum")` UNA sola volta (guardia `_active`). Lo chiama
## `main.gd` in OGNI percorso di chiusura (tasto, interact, alba, notte nuova difensiva),
## così la coppia è sempre bilanciata — tranne il quit a BBS aperta, che lascia uno
## `started` senza `ended`: è l'abbandono, un dato per la 3.6, non un buco.
func deactivate() -> void:
	if not _active:
		return
	_active = false
	Events.wait_activity_ended.emit(ACTIVITY)
	# L'handshake, se ancora in corso alla chiusura, si spegne: non deve continuare a
	# suonare da una BBS parcheggiata e spenta.
	_stop_handshake()


## Costruisce lo stream di beep in codice: identico al terminale — è lo stesso computer.
## Un'onda quadra breve a bassa frequenza, il clic secco di un terminale.
func _install_beep() -> void:
	_beep = AudioStreamPlayer.new()
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var frames := 900               # ~40 ms
	var data := PackedByteArray()
	data.resize(frames)
	var period := 22050 / 660       # ~660 Hz, onda quadra
	for i in frames:
		var env := 1.0 - float(i) / float(frames)
		var high := (i % period) < (period / 2)
		var amp := 90.0 * env
		var v := int(amp) if high else int(-amp)
		data[i] = (v + 256) % 256   # 8-bit signed → byte
	wav.data = data
	_beep.stream = wav
	_beep.volume_db = -6.0
	add_child(_beep)


## Costruisce lo stream dell'handshake del modem 56k in codice: nessun asset (provvisorio,
## coerente con la memoria sugli asset). Due toni ruvidi che si alternano rapidi — non una
## nota, il verso stridulo di due modem che si accordano. In loop: parte all'`arm()` e si
## ferma quando la connessione «si stabilisce» (fine `_connect_timer`) o alla chiusura.
func _install_handshake() -> void:
	_handshake = AudioStreamPlayer.new()
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	var frames := 22050              # ~1 s in loop
	wav.loop_begin = 0
	wav.loop_end = frames
	var data := PackedByteArray()
	data.resize(frames)
	# Due frequenze che si alternano ogni ~120 ms: il carrier che cerca l'aggancio.
	var seg := 2646                  # ~120 ms per segmento
	var p_a := 22050 / 1200          # tono grave
	var p_b := 22050 / 2100          # tono acuto
	for i in frames:
		var use_a := (i / seg) % 2 == 0
		var period := p_a if use_a else p_b
		# Un po' di ruvidità: XOR di una seconda onda più veloce, così suona sporco.
		var high := (i % period) < (period / 2)
		var buzz := (i % 37) < 18
		var on := high != buzz
		var amp := 55.0
		var v := int(amp) if on else int(-amp)
		data[i] = (v + 256) % 256
	wav.data = data
	_handshake.stream = wav
	_handshake.volume_db = -10.0
	add_child(_handshake)


## Il timer della connessione: one-shot, tempo REALE (`Engine.time_scale` non lo tocca,
## perché usa un `SceneTreeTimer`? No — un `Timer` figlio conta col tempo di gioco). Qui
## si vuole tempo reale, quindi si imposta `process_callback` non basta: il modo pulito è
## `ignore_time_scale` sul timer. Un `Timer` nodo NON ha quell'opzione; per restare
## semplici si accetta che F1–F4 in debug lo accelerino come ogni altro `Timer` del
## progetto (moka, cupola), coerente con loro. La durata è un valore di rituale, non di
## layout, e la verifica è d'operatore (si sente).
func _install_connect_timer() -> void:
	_connect_timer = Timer.new()
	_connect_timer.one_shot = true
	_connect_timer.wait_time = HANDSHAKE_SEC
	_connect_timer.timeout.connect(_on_connected)
	add_child(_connect_timer)


## Avvia l'handshake: la vista mostra CONNECTING, il rumore parte, il timer conta.
func _start_handshake() -> void:
	_connecting = true
	if _handshake != null and _handshake.stream != null and _audio_is_audible():
		_handshake.play()
	_connect_timer.start()


## La connessione si è stabilita: ferma il rumore, esce dalla vista CONNECTING, apre
## l'elenco. Un beep secco segna l'aggancio.
func _on_connected() -> void:
	_connecting = false
	_stop_handshake()
	_play_beep()
	queue_redraw()


func _stop_handshake() -> void:
	if _handshake != null and _handshake.playing:
		_handshake.stop()


func _play_beep() -> void:
	if _beep != null and _audio_is_audible():
		_beep.play()


## Se c'è un'uscita audio VERA. In headless (cancello, banco, import) il driver è `Dummy`:
## un suono avviato che l'engine spegne a forza lascia un WARNING. Gemello di
## `DomeActivity._audio_is_audible`.
func _audio_is_audible() -> bool:
	return DisplayServer.get_name() != "headless"


## Legge `forum.tres` e tiene le board. FORUM ASSENTE/ILLEGGIBILE (I/O matrix): `load`
## torna `null`; la BBS mostra le aree vuote senza crash, e avvisa su canale 1 — è un
## errore di programma (un dato di gioco mancante), non un fatto per il giocatore. Il
## vetro resta pulito: nessun codice d'errore sul CRT.
func _load_boards() -> void:
	_boards = []
	var forum := load(FORUM_PATH) as ForumData
	if forum == null:
		push_error("[bbs] forum assente o illeggibile: %s" % FORUM_PATH)
		return
	for board in forum.boards:
		if board != null:
			_boards.append(board)


## Ricostruisce la lista piatta dei messaggi VISIBILI alla notte corrente. Ogni board
## filtra i propri con `available(night)`; l'ordine è board dopo board, messaggio dopo
## messaggio, come nel `.tres`. `_row_board_index` mappa ogni riga alla sua board per
## disegnarne l'intestazione al cambio.
func _rebuild_rows() -> void:
	_rows = []
	_row_board_index = PackedInt32Array()
	var night := _current_night()
	for bi in _boards.size():
		for msg in _boards[bi].available(night):
			_rows.append(msg)
			_row_board_index.append(bi)
	_cursor = clampi(_cursor, 0, maxi(0, _rows.size() - 1))


## La notte corrente per il filtro dei messaggi. Passa da `Game.run.night_index` quando
## c'è una notte; se non c'è (nessuna notte montata), ripiega su
## `profile.nights_completed + 1`, cioè la notte che comincerebbe adesso — così il filtro
## è sempre definito. Puro rispetto alla BBS: legge solo `Game`, non conosce la notte.
func _current_night() -> int:
	if Game.run != null:
		return Game.run.night_index
	return Game.profile.nights_completed + 1


func _unhandled_input(event: InputEvent) -> void:
	# Durante l'handshake la BBS non risponde ai comandi di navigazione: si sta
	# connettendo. Il tasto back/quit invece esce comunque — non si resta in ostaggio
	# di una connessione.
	if event.is_action_pressed(&"bbs_back") or event.is_action_pressed(&"bbs_open"):
		if _reading:
			# Dalla lettura si torna all'elenco; dall'elenco si esce dalla BBS.
			_close_reading()
		else:
			closed.emit()
		get_viewport().set_input_as_handled()
		return

	if _connecting:
		# Connessione in corso: gli altri comandi sono inerti finché non aggancia.
		return

	if _reading:
		_reading_input(event)
		return

	_list_input(event)


## Input nella vista ELENCO: su/giù scorrono i messaggi, conferma apre la lettura.
func _list_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu_up"):
		_move_cursor(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"menu_down"):
		_move_cursor(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"menu_confirm"):
		_open_reading()
		get_viewport().set_input_as_handled()


## Input nella vista LETTURA: su/giù scorrono il corpo (scroll esplicito). Il tasto
## back/quit (gestito sopra) torna all'elenco.
func _reading_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu_up"):
		_scroll_body(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"menu_down"):
		_scroll_body(1)
		get_viewport().set_input_as_handled()


func _move_cursor(delta: int) -> void:
	if _rows.is_empty():
		return
	_cursor = (_cursor + delta + _rows.size()) % _rows.size()
	_play_beep()
	queue_redraw()


## Scorre il corpo di `delta` righe, CLAMPATO agli estremi (nessun wrap: si arriva in
## cima o in fondo e ci si ferma). L'indicatore ▲/▼ dirà se c'è altro.
func _scroll_body(delta: int) -> void:
	var max_scroll := maxi(0, _body_lines.size() - BODY_WINDOW)
	var next := clampi(_scroll + delta, 0, max_scroll)
	if next == _scroll:
		return
	_scroll = next
	_play_beep()
	queue_redraw()


## Apre la vista di lettura sul messaggio selezionato e lo MARCA letto (salvato via
## `Game.mark_forum_read`, idempotente). Manda a capo il corpo UNA volta, qui, e azzera
## lo scroll. Nessun effetto se la lista è vuota.
func _open_reading() -> void:
	if _rows.is_empty():
		return
	var msg := _rows[_cursor]
	# Marca letto PRIMA di disegnare: da questo momento la riga nell'elenco tornerà in
	# `DIM`. `mark_forum_read` è idempotente e salva una volta — nessuna doppia scrittura
	# se il messaggio era già letto.
	Game.mark_forum_read(msg.id)
	_body_lines = _wrap(msg.body, WRAP_WIDTH)
	_scroll = 0
	_reading = true
	_play_beep()
	queue_redraw()


## Torna dalla lettura all'elenco. La BBS resta aperta (non emette `ended`): chiudere la
## BBS è un altro gesto (back dall'elenco), che emette `closed`.
func _close_reading() -> void:
	_reading = false
	_body_lines = PackedStringArray()
	_scroll = 0
	_play_beep()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)
	# CORNICE a linea singola, IDENTICA al terminale — è lo stesso computer.
	draw_rect(Rect2(Vector2(3, 3), DESIGN_SIZE - Vector2(6, 6)), DIM, false, 1.0)

	# INTESTAZIONE in INGLESE (NFR10): la voce di una BBS del 1999.
	_text(Vector2(9, 16), "CYGNUS BBS  v1.0", DIM, 11)
	draw_line(Vector2(6, 24), Vector2(DESIGN_SIZE.x - 6, 24), DIM, 1.0)

	if _connecting:
		_draw_connecting()
		return

	if _reading:
		_draw_reading()
		return

	_draw_list()


## La vista dell'handshake: mentre il modem si accorda. Testo EN (voce macchina); il
## rumore lo si sente. Nessun codice d'errore, nessuna barra di caricamento: è un'attesa
## dichiarata, non un progresso da riempire.
func _draw_connecting() -> void:
	_text(Vector2(9, 40), "DIALING 0335-BBS...", FG, 12)
	_text(Vector2(9, 58), "MODEM 56K HANDSHAKE", DIM, 11)
	_text(Vector2(9, 100), "CONNECTING", SEL, 14)
	_text(Vector2(9, 182), "esc cancel", DIM, 10)


## La vista ELENCO: le aree come intestazioni EN, i messaggi numerati con soggetto (IT) e
## autore. Letti in `DIM`, non letti in `FG`; il selezionato in `SEL`. NESSUN contatore di
## non letti: la distinzione è per riga, non un badge da svuotare.
func _draw_list() -> void:
	if _rows.is_empty():
		_text(Vector2(9, 60), "NO MESSAGES", DIM, 12)
		_text(Vector2(9, 182), "esc quit", DIM, 10)
		return

	var y := 34
	var last_board := -1
	for i in _rows.size():
		var bi := _row_board_index[i]
		if bi != last_board:
			# Intestazione dell'area (EN), quando la board cambia rispetto alla riga prima.
			_text(Vector2(9, y), _boards[bi].title, DIM, 11)
			y += 13
			last_board = bi
		var msg := _rows[i]
		var selected := i == _cursor
		var read := Game.profile.has_read(msg.id)
		var mark := ">" if selected else " "
		# Selezionato vince sul colore letto/non-letto: risalta comunque. Non selezionato:
		# `DIM` se letto, `FG` se no — visibile se lo cerchi, non un badge.
		var col := SEL if selected else (DIM if read else FG)
		# Il soggetto si taglia (con `…`) prima della colonna dell'autore, a x=196: 24
		# caratteri a 11px stanno entro ~150px e non ci finiscono sopra. Non è troncamento
		# silenzioso del CONTENUTO — il corpo si legge intero nella vista di lettura; qui è
		# solo l'anteprima dell'elenco, e il taglio è marcato dal `…`.
		var line := "%s %s" % [mark, _clip(msg.subject, 24)]
		_text(Vector2(9, y), line, col, 11)
		_text(Vector2(196, y), _clip(msg.author, 8), DIM, 10)
		y += 13

	_text(Vector2(9, 182), "up/down  enter read  esc quit", DIM, 10)


## La vista LETTURA: soggetto (IT) e corpo (IT) scorribile. Lo SCROLL È ESPLICITO — un
## triangolo su dice che c'è altro sopra, uno giù che c'è altro sotto, ciascuno con la
## scritta MORE. Nessuna riga troncata in silenzio: si vede sempre se il messaggio
## continua. È l'AC che la 2.2 ha pagato: si verifica guardando, non stimando.
func _draw_reading() -> void:
	if _rows.is_empty():
		return
	var msg := _rows[_cursor]
	# Soggetto e autore (IT / handle) in cima.
	_text(Vector2(9, 38), _clip(msg.subject, 38), SEL, 12)
	_text(Vector2(9, 52), "da %s" % msg.author, DIM, 10)
	draw_line(Vector2(6, 58), Vector2(DESIGN_SIZE.x - 6, 58), DIM, 1.0)

	# La finestra di righe del corpo, a partire da `_scroll`.
	var y := 72
	var last := mini(_scroll + BODY_WINDOW, _body_lines.size())
	for i in range(_scroll, last):
		_text(Vector2(9, y), _body_lines[i], FG, 11)
		y += 13

	# INDICATORI DI SCROLL ESPLICITI. Il triangolo si disegna come POLIGONO, non come
	# glifo di font: un carattere ▲/▼ dipende dal fallback del `SystemFont` e su questa
	# build non renderizzava — è precisamente il troncamento silenzioso che questa storia
	# esiste per non fare. Un poligono si vede sempre. Accanto, la scritta MORE (EN, voce
	# macchina) rende l'indicazione inequivocabile anche a chi non nota la freccia.
	var more_above := _scroll > 0
	var more_below := last < _body_lines.size()
	# Il MORE di sopra sta NELLA fascia dell'intestazione (sopra il divisorio a y=58),
	# accanto all'autore: così non copre mai una riga di corpo. Il MORE di sotto sta nel
	# piede, accanto al suggerimento. Entrambi fuori dal flusso del testo.
	if more_above:
		_draw_arrow(Vector2(238, 46), true)
		_text(Vector2(202, 52), "MORE", SEL, 9)
	if more_below:
		_draw_arrow(Vector2(238, 166), false)
		_text(Vector2(202, 172), "MORE", SEL, 9)

	var hint := "up/down scroll  esc back" if (more_above or more_below) else "esc back"
	_text(Vector2(9, 182), hint, DIM, 10)


## Un piccolo triangolo pieno come indicatore di scroll: `up` vero punta in su (c'è altro
## sopra), falso in giù (c'è altro sotto). Poligono e non glifo, così non dipende dal
## font — vedi il commento in `_draw_reading`.
func _draw_arrow(tip: Vector2, up: bool) -> void:
	var h := 5.0
	var w := 4.0
	var pts := PackedVector2Array()
	if up:
		pts.append(tip)
		pts.append(tip + Vector2(-w, h))
		pts.append(tip + Vector2(w, h))
	else:
		pts.append(tip)
		pts.append(tip + Vector2(-w, -h))
		pts.append(tip + Vector2(w, -h))
	draw_colored_polygon(pts, SEL)


## Manda a capo `text` a parole entro `width` caratteri, RISPETTANDO gli a-capo espliciti
## del corpo (i paragrafi): ogni `\n` del `.tres` spezza, e dentro ogni paragrafo si
## avvolge a parole. Monospace, quindi contare i caratteri basta a stare nel vetro —
## come il terminale. Nessun testo perso: una parola più lunga di `width` finisce
## comunque su una riga sua (non si scarta).
func _wrap(text: String, width: int) -> PackedStringArray:
	var out := PackedStringArray()
	for paragraph in text.split("\n", true):
		if paragraph.is_empty():
			# Un a-capo vuoto (riga di stacco fra paragrafi) resta una riga vuota.
			out.append("")
			continue
		var line := ""
		for word in paragraph.split(" ", false):
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


## Taglia una stringa a `n` caratteri per stare nella colonna. NON è troncamento
## silenzioso del CORPO — quello si scorre; è solo l'anteprima dell'elenco (soggetto) e
## l'handle, che nel corpo si leggono per intero. Se taglia, mette un `…` visibile.
func _clip(s: String, n: int) -> String:
	if s.length() <= n:
		return s
	return s.substr(0, n - 1) + "…"


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
