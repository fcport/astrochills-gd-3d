## Punto d'ingresso. Il mondo 3D vive dentro un SubViewport a bassa risoluzione,
## riscalato con filtro nearest.
##
## È la tecnica PS1 più fedele, ed è anche la strada scelta per ottenere un
## post-effect a schermo intero senza CompositorEffect — che in Compatibility
## non esiste. Il vincolo del renderer spinge nella direzione giusta.
##
## CHI CHIAMA `crt.show_control()` È QUESTO FILE. Era il rilievo m6 del readiness
## report — «la 1.3 non dice chi lo chiama prima che `night/` esista» — e la
## risposta viene dalla tabella dei confini, che dà il permesso a uno solo:
## `world/` non può conoscere `phases/`, `crt/` non può conoscere `phases/`,
## `phases/` non può conoscere `world/`. Il punto d'ingresso può tutto, ed è
## l'unico che può. Quando arriverà `night/night_session.gd` eredita questo punto
## di chiamata senza spostarlo: la fase parla `Control` e non sa dove finisca.
##
## LA SEQUENZA DELLA POSTAZIONE È ADR-003, E L'ORDINE NON È DECORATIVO.
##   1. `player.set_enabled(false)` — il controllo si toglie PRIMA di muovere
##      qualunque cosa;
##   2. `desk.toggle()` — il corpo si aggancia al `Marker3D` e la camera
##      interpola, mezzo secondo, con il FOV che si stringe a 42°;
##   3. su `seated` — e solo lì — lo schermo comincia a ricevere input.
## All'uscita l'inverso, e il controller torna acceso solo su `left`.
##
## IL PASSO 1 PRIMA DEL 2 È UN REQUISITO FISICO. Alla postazione `desk_camera`
## porta l'origine del corpo a y = −0,46 m, sotto il pavimento: è corretto, la
## camera atterra sul `Seat`, e regge SOLO perché da spento
## `Player._physics_process()` esce subito e non simula più. Con il controller
## ancora acceso la depenetrazione risputerebbe fuori il corpo portandosi via la
## camera. È una decisione della code review della 1.2: non disfarla.
##
## IL CONTROLLO È DI UNO SOLO ALLA VOLTA, e non è una scelta di comodo.
## `W`, `A`, `S`, `D` e `ENTER` sono legati sia al movimento sia alle due viti
## della fase polare: con entrambi attivi, camminare girerebbe le viti. Le azioni
## polari non si possono rinominare, perché `phases/polar/phase_polar.gd` le
## nomina e la prova dell'AC2 della storia 1.1 richiede che quel file non cambi.
## Quindi comanda uno solo alla volta: si entra nella fase interagendo col
## monitor, e il controller del giocatore si spegne.
##
## SEDUTO NON È FINITO, e sono due stati diversi che prima coincidevano. `ENTER`
## CONCLUDE l'allineamento; `E` alza dalla sedia e basta. Alzarsi SOSPENDE la
## fase — `process_mode = PROCESS_MODE_DISABLED` — invece di liberarla: lo stato
## resta dov'è e al ritorno lo schermo mostra quello vero, non uno ricostruito.
## Vedi `_set_phase_running()`, che è dove quella regola vive per intero.
##
## LO STATO DEI TASTI NON SEGUE IL CONTROLLO. `Input.get_axis` e
## `Input.get_vector` leggono lo stato fisico della tastiera, che non sa nulla di
## chi sia abilitato: chi entra nella fase tenendo premuto `W` per camminare si
## troverebbe la vite di altitudine che gira da sola, e chi esce tenendo premuto
## `W` per girare la vite si troverebbe il giocatore che parte in avanti. Per
## questo ogni scambio rilascia le azioni: vedi `_release_all_actions()`.
##
## LA MISURA DEL MONDO NON SI DICHIARA NELLA SCENA. `WorldViewport` è un
## SubViewportContainer con `stretch = true`, e un container di quel tipo impone
## sempre al proprio SubViewport la misura `container / stretch_shrink` — su
## finestra 1280x720 con shrink 2 fa 640x360. Qualunque `size` scritto a mano sul
## SubViewport viene sovrascritto al primo ridimensionamento: è un numero morto
## che mente a chi tara il look PS1, e per questo non c'è.
##
## QUELLO CHE RESTA DEL PONTE è l'orchestrazione, non lo schermo. Il CRT vero
## c'è, e `ScreenHost`/`ScreenViewport` — il CRT povero della 1.2 — sono stati
## smontati con la storia 1.3. Manca ancora chi decida quale fase venga dopo:
## `night/` non esiste, e l'epica 2 mette `night_session` al posto di `_advance`.
extends Node

const PHASE_POLAR := preload("res://phases/polar/phase_polar.tscn")

## Percorsi, NON preload. `const ... preload` risolve al caricamento dello script,
## in ogni build: con un preload gli strumenti di debug — e con l'iniettore anche
## `wandering_drift.tres` — finirebbero comunque dentro l'export di release, che
## è esattamente ciò che FR37 vieta. La guardia `OS.is_debug_build()` ferma
## l'istanziazione, non il caricamento. Con `load()` dietro la guardia, in
## release questi file non vengono nemmeno aperti.
const DEBUG_OVERLAY_PATH := "res://debug/debug_overlay.tscn"
const RENDER_TUNING_PATH := "res://debug/render_tuning.gd"
const LIE_INJECTOR_PATH := "res://debug/lie_injector.gd"

@onready var _container: SubViewportContainer = %WorldViewport
@onready var _world: SubViewport = %SubViewport
@onready var _phase_host: Node = %PhaseHost

var _phase: Phase

## I `process_mode` che la fase e il suo `Control` avevano quando sono nati.
## Sospendere li sostituisce, riprendere li rimette: vedi `_set_phase_running()`.
var _phase_mode := Node.PROCESS_MODE_INHERIT
var _screen_mode := Node.PROCESS_MODE_INHERIT

## Lo schermo diegetico e la postazione davanti a cui ci si siede. Si risolvono
## in `_ready()` e restano: senza di loro non si entra in nessuna fase.
var _crt: CrtScreen
var _desk: DeskCamera


func _ready() -> void:
	Game.start_night(1)
	Log.info("main", "avvio — renderer %s" % RenderingServer.get_video_adapter_api_version())
	# LO STATO INIZIALE SI DICHIARA, non si eredita. `_enabled` nasce `true` nello
	# script del giocatore e la cattura del mouse sta nel suo `_ready()`: due posti
	# scollegati, e nessuno dei due è la sequenza di avvio. Questa riga la dice
	# dove si legge — e rilascia le azioni prima del primo frame, così una build
	# non parte con un tasto che risulta premuto da chissà quando.
	_set_world_active(true)
	_connect_monitor()
	if OS.is_debug_build():
		_install_debug_tools()


## Il monitor si trova per GRUPPO, mai per percorso di nodo: un percorso si
## romperebbe al primo spostamento, ed è precisamente ciò che l'AC3 della storia
## 1.2 vieta. Il gruppo sopravvive a spostamenti, rinomine e annidamenti diversi.
##
## E SI CERCA, invece di aspettare `Events.screen_registered`. `CrtScreen` emette
## quel segnale nel proprio `_ready()`, e l'albero si costruisce
## profondità-prima: quando il mondo è istanziato dentro `main.tscn` l'emissione
## avviene PRIMA di questo `_ready()`. Chi nasce qui non la riceve mai. Il
## ripiego è cercare — vale per `CrtMonitor` come per `Player`.
func _connect_monitor() -> void:
	var monitor := CrtMonitor.find_in(get_tree())
	if monitor == null:
		# Canale 1: è un errore di programma. Senza monitor la fase è
		# irraggiungibile, e il giocatore girerebbe per la stanza senza capire.
		push_error("[main] nessun CrtMonitor nel gruppo '%s'" % CrtMonitor.GROUP)
		return
	_crt = monitor.screen()
	if _crt == null:
		push_error("[main] il CrtMonitor non ha uno schermo")
		return
	_setup_desk()
	if _desk == null:
		return  # `_setup_desk()` ha già detto perché

	# CI SI COLLEGA SOLO A POSTAZIONE MONTATA. Collegare prima di sapere se la
	# postazione esiste trasforma una diagnosi in uno spam: l'errore uscirebbe a
	# ogni singola pressione di `E`, e la causa vera — detta una volta all'avvio —
	# finirebbe sepolta sotto le sue stesse conseguenze.
	monitor.interacted.connect(_on_monitor_interacted)


## Monta la postazione. `DeskCamera` non ha una scena e nessuno la istanziava: è
## keeper dal primo giorno, e questa è la storia che la accende.
##
## `add_child()` NON È FACOLTATIVO. `create_tween()` lega il Tween allo SceneTree
## del nodo: da orfano restituisce un Tween che non riceve mai un tick, la
## transizione parte e non finisce mai, e `seated` — emesso dopo
## `await t.finished` — non arriva. Il giocatore resterebbe seduto per sempre,
## senza controllo e senza input. `DeskCamera.toggle()` ha una guardia che lo
## dice forte, ma la guardia è la rete: il posto giusto è questa riga.
func _setup_desk() -> void:
	var player := Player.find_in(get_tree())
	if player == null:
		push_error("[main] nessun Player nel gruppo '%s'" % Player.GROUP)
		return
	var desk := DeskCamera.new()
	desk.name = "DeskCamera"
	# `camera()` è impalcatura dichiarata dalla storia 1.2, fatta per questa
	# riga: la camera si RAGGIUNGE, non si riparenta. `_crt.seat` è pubblico in
	# `crt_screen.gd` per la stessa ragione.
	#
	# L'ESITO SI GUARDA, e `_desk` resta nullo se la configurazione è fallita.
	# Una postazione montata a metà è peggio di una assente: da fuori
	# `_desk != null` la fa sembrare pronta, e alla prima `E` il controllo
	# verrebbe tolto al giocatore PRIMA che `toggle()` rifiuti di partire — nessun
	# tween, nessun segnale, e nessun modo di rialzarsi. Con `_desk` nullo il
	# rifiuto arriva in `_on_monitor_interacted`, che è prima di toccare qualunque
	# cosa. Correzione della code review del 2026-08-22.
	if not desk.configure(player, player.camera(), _crt.seat):
		desk.free()
		return
	desk.seated.connect(_on_seated)
	desk.left.connect(_on_left)
	add_child(desk)
	_desk = desk


## `E` sul monitor. È l'unico ingresso, e da qui in poi ha due significati che
## dipendono da cosa c'è già: comincia un allineamento, oppure torna a uno
## lasciato a metà.
##
## RI-SEDERSI È IL FLUSSO NORMALE, non un caso limite. Fino alla 1.2 una fase
## viva faceva uscire questa funzione senza fare niente; adesso il ciclo
## «siediti → alzati → risiediti» è il modo in cui si gioca.
func _on_monitor_interacted(_by: Node3D) -> void:
	if _crt == null or _desk == null:
		# La postazione non è montata: non si cede il controllo a un giocatore
		# che poi non potrebbe né vedere né rialzarsi. Stessa logica di
		# `_phase_can_run()`, e stessa ragione.
		push_error("[main] postazione non montata: non si entra nella fase")
		return
	if _phase != null:
		_sit_down()
		return
	_enter_phase(PHASE_POLAR)


## Ciò che nessuno ha gestito arriva allo schermo, e solo da seduti.
## DURANTE LA TRANSIZIONE NON PASSA UN COMANDO, e questa funzione chiude un
## blocco senza ritorno che la sequenza di ADR-003 crea da sé.
##
## La fase riprende col gesto, quindi nei mezzi secondi in cui la camera scivola
## verso la postazione è già viva e già in ascolto: un `ENTER` premuto lì dentro
## la CONCLUDE mentre il tween sta ancora andando. `_advance()` troverebbe una
## postazione che non è né in piedi né seduta, e il giocatore resterebbe seduto
## davanti a uno schermo svuotato, senza controller.
##
## `_input()` e non `_unhandled_input()` perché tutti gli `_input` dell'albero
## precedono qualunque `_unhandled_input`: è l'unico stadio in cui questo file
## arriva prima della fase, che sta sotto `PhaseHost` e legge `polar_finish` da
## `_unhandled_input`. (Dentro lo stesso stadio la propagazione va dai nodi più
## profondi verso la radice, quindi qui si arriva comunque ultimi: è la
## precedenza fra STADI a fare il lavoro, non la posizione nell'albero.)
##
## SI INGOIANO SOLO I COMANDI DI GIOCO, cioè le azioni dell'`InputMap`. `F9`,
## `F12` e i tasti di taratura sono keycode grezzi letti da `debug/`, non
## azioni: restano raggiungibili anche a metà transizione, perché chi sviluppa
## non deve chiedersi perché lo strumento non ha risposto — e con l'iniettore,
## che dopo l'iniezione lascia la fase identica a prima, quel dubbio non si
## risolverebbe da solo.
##
## QUELLO CHE QUESTA FUNZIONE NON PUÒ FERMARE, e va detto perché è stato
## misurato: `Input.get_axis()` e `Input.is_action_pressed()` leggono lo stato
## del singleton, che viene aggiornato PRIMA della propagazione ai viewport.
## `set_input_as_handled()` non lo tocca. Chi preme una vite mentre la camera
## scivola verso il monitor la gira davvero — misurato: azimut da 1,4000 a
## 1,1935 in 0,35 s — e i secondi della transizione entrano nella finestra del
## punteggio. È coerente con il fatto che la fase stia girando, ed è il prezzo
## dichiarato di farla ripartire col gesto invece che all'arrivo: lo schermo che
## il giocatore sta raggiungendo mostra il presente e non un fermo immagine.
## Ciò che NON passa è `ENTER`, che la concluderebbe.
func _input(event: InputEvent) -> void:
	if _desk == null or not _desk.is_busy():
		return
	for action in InputMap.get_actions():
		if event.is_action(action):
			get_viewport().set_input_as_handled()
			return


## `E` per alzarsi si legge QUI, e non in `_unhandled_input()`.
##
## Il punto d'ingresso è l'antenato di `PhaseHost` e del mondo, e la propagazione
## va dai nodi profondi verso la radice: in `_unhandled_input` arriva sempre per
## ultimo. Basta che una fase — o un `Control` diegetico dentro il CRT, che è
## precisamente ciò per cui `CrtScreen.push()` esiste — consumi un evento perché
## questo file non lo veda più, e il gesto per alzarsi smetta di funzionare: il
## giocatore resterebbe seduto senza un tasto per uscirne. `_shortcut_input()`
## gira dopo `_input` e PRIMA di ogni `_unhandled_input`, e nessuna fase lo
## implementa: qui il punto d'ingresso vince per costruzione, non per fortuna.
## Correzione della code review del 2026-08-22.
##
## LO STESSO TASTO IN ENTRAMBI I VERSI. `E` porta alla postazione e ne riporta
## via; `ENTER` resta l'unico gesto che CONCLUDE l'allineamento. Un tasto nuovo
## sarebbe il sesto del gioco e nessun documento lo chiede; `ESC` è già
## `ui_release_mouse`, e la review della 1.2 ha registrato che collide con la UI
## di pausa dell'epica 2 — dargli un terzo significato aggraverebbe una voce già
## aperta, e «annulla» è per giunta il contrario di ciò che alzarsi fa.
##
## Da seduti il controller del giocatore è spento, e con lui il suo lettore di
## `interact`: leggerlo qui non gli toglie niente.
##
## UN LIMITE DA SAPERE, misurato: questo stadio riceve solo `InputEventKey`,
## `InputEventShortcut` e `InputEventJoypadButton`. Un `InputEventAction`
## sintetico — quelli che si fabbricano con `Input.parse_input_event()` per
## pilotare il gioco da una sonda — non ci arriva mai. Nel gioco `E` è un tasto e
## il problema non esiste; chi scrive una sonda deve premere l'evento vero
## dell'`InputMap`, non inventarne uno.
func _shortcut_input(event: InputEvent) -> void:
	if _desk == null or not _desk.is_seated:
		return
	if event.is_action_pressed(&"interact"):
		_stand_up()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _desk == null or not _desk.is_seated:
		return

	# L'INPUT ENTRA NEL SUBVIEWPORT SOLO DA SEDUTI, ed è la clausola dell'AC1.
	# Il cancello vero sta in `crt/`: qui si decide solo QUANDO bussare. Oggi
	# nessun Control del progetto gestisce input — la fase polare legge le viti
	# con `Input.get_axis()`, che non passa da nessun viewport — quindi questa
	# riga non ha ancora un destinatario. Esiste perché la clausola resti
	# verificabile, e perché il primo `Button` diegetico trovi la strada fatta
	# invece di essere scoperta da chi non saprà perché non funziona.
	if _crt != null:
		_crt.push(event)


## Dà o toglie il controllo al giocatore. Il mondo resta renderizzato in entrambi
## i casi: alla postazione il giocatore DEVE vedersi intorno la stanza.
##
## Il giocatore si risolve PRIMA di toccare qualunque cosa. Accorgersi solo dopo
## che il giocatore non c'è lascerebbe la fase attiva con il controller ancora
## acceso sotto — cioè esattamente il doppio comando che tutto questo esiste per
## impedire.
func _set_world_active(active: bool) -> void:
	var player := Player.find_in(get_tree())
	if player == null:
		push_error("[main] nessun Player nel gruppo '%s'" % Player.GROUP)
		return
	_release_all_actions()
	player.set_enabled(active)


## Rilascia ogni azione dell'`InputMap` al momento dello scambio.
##
## Si itera l'`InputMap` invece di elencare i nomi: elencarli qui significherebbe
## ricopiare in questo file le azioni della fase polare, che vivono in
## `phases/polar/phase_polar.gd` e che nessuno deve duplicare. Un'azione
## rilasciata resta tale finché il tasto non viene alzato e ripremuto, che è
## esattamente il comportamento voluto — chi teneva il dito giù deve rialzarlo
## per ricominciare.
func _release_all_actions() -> void:
	for action in InputMap.get_actions():
		Input.action_release(action)


## Porta il giocatore alla postazione. Passi 1 e 2 di ADR-003; il 3 è su
## `_on_seated()`, che scatta a interpolazione finita.
func _sit_down() -> void:
	if _desk == null or _desk.is_seated:
		return
	_set_world_active(false)
	# La fase riprende col GESTO, non con la fine dell'interpolazione: mentre ti
	# siedi il programma sta già girando, e lo schermo che stai raggiungendo
	# mostra il presente invece di un fermo immagine di mezzo secondo prima. Per
	# la stessa ragione lo schermo torna vivo adesso: se aspettasse `seated`, la
	# transizione si guarderebbe un fermo immagine e l'interfaccia comparirebbe di
	# scatto all'arrivo. L'input invece aspetta davvero `seated`, perché quello è
	# ciò che l'AC1 chiede — e l'input è l'unica delle tre cose che l'AC nomina.
	if _crt != null:
		_crt.set_live(true)
	_set_phase_running(true)
	_desk.toggle()


## Alza dalla postazione SENZA concludere niente. È il gesto che l'AC5 chiede e
## che fino alla 1.2 non esisteva: l'unica uscita era `ENTER`, che per contratto
## conclude l'allineamento ed emette il punteggio.
func _stand_up() -> void:
	if _desk == null or not _desk.is_seated:
		return
	if _crt != null:
		_crt.set_input_enabled(false)
	_set_phase_running(false)
	# Lo schermo si ferma DOPO la fase, e non prima: così l'ultimo fotogramma che
	# resta sul vetro è quello di una fase già ferma. Il frame concesso da
	# `set_live(false)` qui non cambia un pixel — la fase è sospesa e nessun
	# ridisegno è in coda — e serve davvero solo in `_advance()`, dove il viewport
	# è stato appena svuotato.
	if _crt != null:
		_crt.set_live(false)
	_desk.toggle()


func _on_seated() -> void:
	# SE NEL FRATTEMPO NON C'È PIÙ UNA FASE, non si resta seduti davanti al nulla.
	# Una fase può concludersi da sola durante la transizione — oggi non succede,
	# perché `_input()` non lascia passare `polar_finish` mentre la camera scivola,
	# ma una fase futura può emettere `finished` senza che nessuno prema niente. In
	# quel caso `_advance()` ha giustamente lasciato stare una postazione a metà
	# corsa, e tocca a questo callback chiudere il giro: senza, il giocatore
	# resterebbe seduto, senza controller, davanti a uno schermo svuotato e con il
	# cancello dell'input riaperto sul niente. Correzione della code review del
	# 2026-08-22, che è anche ciò che rende vera la promessa scritta in `_advance()`.
	#
	# Differita perché non si avvia una transizione dentro il callback di quella
	# appena finita.
	if _phase == null:
		_stand_up.call_deferred()
		return

	# QUI, e non un frame prima: «l'input passa al SubViewport solo a
	# interpolazione finita, mai prima» (AC1).
	if _crt != null:
		_crt.set_input_enabled(true)


func _on_left() -> void:
	# E il controller torna attivo solo a transizione conclusa, che è l'altra
	# metà della stessa clausola.
	_set_world_active(true)


## SOSPENDERE NON È LIBERARE, ed è la regola che questa storia stabilisce.
##
## SONO DUE ASSI, non uno, e tenerli distinti è ciò che rende il precedente
## utilizzabile dalla fase 10 dell'epica 3:
##
##   ASCOLTARE — segue SEMPRE la postazione. Nessuna fase si comanda da un'altra
##   stanza. Vale anche per una fase che gira in background: `runs_in_background()`
##   dice che continua a LAVORARE quando il giocatore se ne va, non che resti
##   raggiungibile dalla cucina. Senza questa distinzione un `ENTER` premuto in
##   corridoio chiuderebbe una fase in background — cioè esattamente il difetto
##   che questa funzione dichiara di chiudere. Correzione della code review del
##   2026-08-22.
##
##   GIRARE — qui `runs_in_background()` esenta davvero. Per la polare è `false`
##   e va lasciato `false`: «è la fase 10 a dover restare viva quando il giocatore
##   se ne va, non questa».
##
## `PROCESS_MODE_DISABLED` ferma `_process` e `_physics_process`, e quindi
## `_turn_screws`, che legge WASD a ogni frame e altrimenti girerebbe le viti
## mentre il giocatore cammina in cucina.
##
## IL MODO PRECEDENTE SI SALVA E SI RIPRISTINA, invece di imporre
## `PROCESS_MODE_INHERIT` alla ripresa. Una fase — o il suo `Control` — può aver
## dichiarato `PROCESS_MODE_ALWAYS` per sopravvivere alla UI di pausa che l'epica
## 2 porterà: sovrascriverlo la cancellerebbe al primo sedersi, in silenzio e per
## sempre. Anche questa è della code review.
##
## LO STATO RESTA A SCHERMO PERCHÉ IL RENDER TARGET LO CONSERVA, non perché
## `_draw` continui a girare: con lo schermo fermo (`CrtScreen.set_live(false)`)
## non si ridisegna niente. È la seconda clausola dell'AC5 — al ritorno si vede
## lo stato vero, non uno ricostruito — e non si salva né si ripristina niente:
## `_star`, `_truth_input` e `_samples` non si sono mai mossi.
##
## IL CONTROL VA SOSPESO A PARTE, e questo è il dettaglio che si perde: dopo
## `show_control()` vive nel `SubViewport` del CRT e NON è più figlio della fase,
## quindi non eredita niente da lei. `polar_screen` ha un `_process` proprio che
## depone un punto di scia ogni 0,08 s: senza questa riga continuerebbe a
## deporre punti nella stessa posizione, e «punti fitti vuol dire quasi fermo»
## racconterebbe una bugia mentre il giocatore è dall'altra parte della casa.
func _set_phase_running(running: bool) -> void:
	if _phase == null:
		return
	var s := _phase.screen()
	var has_screen := s != null and is_instance_valid(s)

	# Primo asse: l'ascolto. Sempre, background o no.
	_phase.set_process_input(running)
	_phase.set_process_unhandled_input(running)

	# Secondo asse: girare.
	if not running and _phase.runs_in_background():
		return
	if running:
		_phase.process_mode = _phase_mode
		if has_screen:
			s.process_mode = _screen_mode
		return
	_phase.process_mode = Node.PROCESS_MODE_DISABLED
	if has_screen:
		s.process_mode = Node.PROCESS_MODE_DISABLED


## Gli strumenti di debug non esistono in release: `OS.is_debug_build()` è falso e
## questi nodi non entrano mai nell'albero. `F9` e `F12` semplicemente non
## rispondono, perché non c'è nessuno ad ascoltarli.
func _install_debug_tools() -> void:
	var render: Node = (load(RENDER_TUNING_PATH) as GDScript).new()
	render.name = "RenderTuning"
	render.configure(_container, _world)
	add_child(render)

	var injector: Node = (load(LIE_INJECTOR_PATH) as GDScript).new()
	injector.name = "LieInjector"
	injector.configure(self)
	add_child(injector)

	var overlay := (load(DEBUG_OVERLAY_PATH) as PackedScene).instantiate()
	overlay.configure(self, render)
	add_child(overlay)


## La fase corrente, per gli strumenti di debug. Nessuno tranne `debug/` la usa:
## quando ci sarà l'orchestratore vero, la troverà lui sotto PhaseHost.
func current_phase() -> Phase:
	return _phase


func _enter_phase(scene: PackedScene) -> void:
	# UNA FASE PER VOLTA. Senza questo la precedente resterebbe viva sotto
	# PhaseHost: continuerebbe a integrare, ad accumulare campioni e a ricevere
	# `_unhandled_input` — ENTER ne chiuderebbe due — e il suo `finished` in
	# ritardo strapperebbe lo schermo alla fase nuova.
	if _phase != null:
		var stale := _phase
		_phase = null
		if _crt != null:
			_crt.show_control(null)
		_dispose(stale)

	var p := scene.instantiate() as Phase
	# setup() prima di entrare nell'albero, come previsto dal contratto.
	p.setup(Game.run, {})
	p.finished.connect(_on_phase_finished.bind(p))
	_phase_host.add_child(p)

	# LA GUARDIA CHE IMPEDISCE UN BLOCCO SENZA RITORNO, e va PRIMA di togliere il
	# controllo al giocatore. Una fase mal configurata non emetterà mai
	# `finished`: nessuno riaccenderebbe il controller, il cursore resterebbe
	# libero su un gioco che non risponde, e non esiste un tasto per annullare.
	# In debug l'`assert` della fase lo rende evidente; in release gli assert
	# spariscono e il giocatore resterebbe fermo davanti a uno schermo muto,
	# senza un solo messaggio. Con la postazione il danno è peggiore: sarebbe
	# seduto E cieco.
	if not _phase_can_run(p):
		push_error("[main] fase %s non configurata: non le si cede il controllo" % p.key())
		p.queue_free()
		return

	_phase = p
	# LO SCHERMO PRIMA DELLA SEDIA. `show_control()` reparenta il Control nel
	# SubViewport del CRT, e `screen()` si risolve nel `_ready()` della fase: per
	# questo l'ordine `add_child(p)` → `p.screen()` va mantenuto — `reparent()`
	# vuole che il nodo sia già nell'albero.
	# I modi si registrano ADESSO, appena la fase esiste e prima che qualcuno la
	# sospenda: sono ciò che `_set_phase_running(true)` rimetterà al posto suo.
	_phase_mode = p.process_mode
	var scr := p.screen()
	_screen_mode = scr.process_mode if scr != null else Node.PROCESS_MODE_INHERIT

	if _crt != null:
		_crt.show_control(scr)
	Events.phase_started.emit(p.key())
	_sit_down()


## Se una fase è in condizione di girare davvero.
##
## La proprietà si interroga per nome, e non con un metodo del contratto `Phase`,
## perché aggiungerlo vorrebbe dire farlo implementare da
## `phases/polar/phase_polar.gd` — e quel file non deve cambiare di una riga: è
## la prova dell'AC2 della storia 1.1, rieseguibile con `git diff` da quando
## esiste il repository. Nessuna comodità di struttura vale distruggerla.
##
## `&"truth" in p` distingue «la fase non ha una sorgente di verità» da «ce l'ha
## e non l'ha ricevuta»: senza quel controllo, ogni fase futura senza `truth`
## risulterebbe inoperabile.
func _phase_can_run(p: Phase) -> bool:
	if &"truth" in p and p.get(&"truth") == null:
		return false
	return true


func _on_phase_finished(result: PhaseResult, phase: Phase) -> void:
	# Una fase che non è più quella corrente non ha voce. Senza questa guardia il
	# `finished` di una fase già smontata scriverebbe un punteggio nel save e
	# porterebbe via lo schermo alla fase viva.
	if phase != _phase:
		return

	# Si registra ciò che la fase HA DICHIARATO in `result`, non ciò che
	# risponderebbe se la si richiamasse: una fase il cui `score()` non fosse
	# idempotente — dipendente dal tempo, o che ripulisce lo stato alla chiusura —
	# scriverebbe nel save un numero diverso da quello che ha emesso.
	# key(), mai name: Godot rinomina in @PhasePolar@2 e finirebbe nel save.
	Game.run.phase_scores[phase.key()] = result.score
	Events.phase_finished.emit(phase.key(), result.score)

	if not result.ok:
		# Canale 1: una fase che dichiara di non essere riuscita è un fatto per lo
		# sviluppatore. Nessuna fase dell'MVP lo fa, ma il campo esiste e finora
		# nessuno lo leggeva.
		Log.warn("main", "fase %s conclusa con ok = false" % phase.key())

	# `reason` NON compare qui: è canale 2, lo legge il giocatore sul CRT e non
	# entra mai nel log di dev (game-architecture.md, tabella dei due canali).
	Log.info("main", "fase %s conclusa — punteggio %d" % [phase.key(), result.score])
	# Mai liberare un nodo dentro la sua stessa callback.
	_advance.call_deferred(phase)


func _advance(phase: Phase) -> void:
	# show_control(null) PRIMA di liberare la fase: il Control è reparentato e
	# resterebbe orfano a schermo. Ma solo se la fase è ancora quella corrente:
	# svuotare il viewport per conto di una fase già sostituita lascerebbe nera
	# la fase viva.
	var was_current := _phase == phase
	if was_current:
		if _crt != null:
			_crt.set_input_enabled(false)
			_crt.show_control(null)
			# `show_control(null)` svuota il viewport, ma svuotarlo non basta a
			# ripulire ciò che è già a video: serve un frame di rendering. È
			# esattamente il frame che `set_live(false)` concede prima di fermarsi.
			_crt.set_live(false)
		_phase = null

	# LA FASE ESCE DI SCENA PRIMA CHE IL CONTROLLO TORNI: vedi `_dispose()`.
	_dispose(phase)

	if was_current:
		# Il giocatore si alza e torna in piedi nella stanza. Il controllo gli
		# torna su `left`, cioè a transizione conclusa: `ENTER` chiude la fase,
		# non la postazione, e uscire dalla postazione resta il gesto lento che
		# ADR-003 descrive.
		#
		# QUATTRO STRADE, perché il controllo deve tornare una volta sola e non
		# zero. Chi è seduto si alza; chi è già in piedi lo riprende subito; chi è
		# a metà di una transizione NON va toccato — restituirlo adesso
		# significherebbe darlo a un corpo che un tween sta ancora trascinando.
		# In quel caso chiude il giro il callback della transizione: `_on_left()`
		# riaccende il controller, e `_on_seated()` — trovando `_phase` nullo — fa
		# rialzare invece di lasciare il giocatore seduto davanti al niente.
		# Oggi il ramo è irraggiungibile, perché `_input()` non lascia concludere
		# una fase durante la transizione; resta scritto perché una fase futura può
		# emettere `finished` da sola, senza che nessuno prema niente.
		if _desk == null:
			_set_world_active(true)
		elif _desk.is_seated:
			_desk.toggle()
		elif not _desk.is_busy():
			_set_world_active(true)
	# Qui finisce il ponte: senza orchestratore non c'è una fase successiva.
	# L'epica 2 mette `night_session` a questo posto.


## Toglie una fase di scena e la libera.
##
## `remove_child()` PRIMA di `queue_free()`, e non è pignoleria: `queue_free()` è
## differita a fine frame, quindi da sola lascerebbe la fase nell'albero — ancora
## in `_process`, ancora in ascolto — per tutto il resto del frame in cui il
## giocatore ha già ripreso il controllo. È la finestra in cui camminare
## girerebbe le viti, cioè la cosa che questo file esiste per rendere
## impossibile.
##
## Uscire dall'albero è sicuro: `Phase` libera il proprio `Control` su
## `NOTIFICATION_PREDELETE` e non su `_exit_tree()`, proprio perché un'uscita
## temporanea non deve uccidere l'interfaccia di una fase viva. È la lezione
## della review della 1.1, e qui torna utile due volte: una fase sospesa resta
## nell'albero, ma il suo Control vive comunque altrove.
func _dispose(phase: Phase) -> void:
	if phase.get_parent() != null:
		phase.get_parent().remove_child(phase)
	phase.queue_free()
