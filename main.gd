## Punto d'ingresso. Il mondo 3D vive dentro un SubViewport a bassa risoluzione,
## riscalato con filtro nearest.
##
## È la tecnica PS1 più fedele, ed è anche la strada scelta per ottenere un
## post-effect a schermo intero senza CompositorEffect — che in Compatibility
## non esiste. Il vincolo del renderer spinge nella direzione giusta.
##
## L'ORCHESTRAZIONE NON È PIÙ QUI, e questo file è tornato a fare il suo mestiere.
## `night/night_session.gd` possiede il piano della notte, le fasi, l'orologio e
## l'alba; qui restano il mondo, la postazione e gli strumenti di debug. È la
## chiusura del ponte che la storia 1.1 aveva dichiarato temporaneo.
##
## IL CONFINE CHE RENDE NECESSARIO QUESTO FILE. `night/` non può conoscere
## `world/` — lo dice la tabella dei confini — ma il monitor CRT vive proprio lì,
## in `world/interactables/`. Il punto d'ingresso è l'unico che conosce entrambe
## le sponde: trova il `CrtScreen` per gruppo e lo consegna all'orchestratore in
## `configure()`. Da lì in poi è `night/` a chiamare `show_control()`, perché il
## TIPO `CrtScreen` appartiene a `crt/`, che è nella sua colonna. L'eredità era
## stata dichiarata dalla 1.3 come chiusura del rilievo m6, ed è questa.
##
## CHI FA COSA SUL CRT, che è la divisione meno ovvia di questo file:
##   il CONTENUTO è dell'orchestratore — `show_control()` segue la fase;
##   la POSTAZIONE è di questo file — `set_input_enabled()` e `set_live()`
##   seguono il giocatore, che si siede e si alza.
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
## fase invece di liberarla: lo stato resta dov'è e al ritorno lo schermo mostra
## quello vero, non uno ricostruito. Qui si dice soltanto SE il giocatore è alla
## postazione (`NightSession.set_player_present`); cosa comporti per la fase lo
## decide l'orchestratore, che è l'unico a possederla.
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
## IL TEMPO SCORRE ANCHE STANDO FERMI, ed è una divergenza dichiarata da FR6
## rispetto a `economia.md §13`, che prevedeva un tempo consumato solo dalle
## azioni. Per un MVP che esiste per misurare l'attesa è la scelta giusta: stare
## fermi DEVE costare tempo, altrimenti l'attesa non è misurabile.
extends Node

## Il piano della notte e l'orchestratore che lo esegue. La SCENA si preload:
## appartiene al gioco, non a `debug/`, e deve esistere in ogni build.
const NIGHT_SESSION := preload("res://night/night_session.tscn")
const NIGHT_PLAN_PATH := "res://data/night_plan.tres"

## Percorsi, NON preload. `const ... preload` risolve al caricamento dello script,
## in ogni build: con un preload gli strumenti di debug — e con l'iniettore anche
## `wandering_drift.tres` — finirebbero comunque dentro l'export di release, che
## è esattamente ciò che FR37 vieta. La guardia `OS.is_debug_build()` ferma
## l'istanziazione, non il caricamento. Con `load()` dietro la guardia, in
## release questi file non vengono nemmeno aperti.
const DEBUG_OVERLAY_PATH := "res://debug/debug_overlay.tscn"
const RENDER_TUNING_PATH := "res://debug/render_tuning.gd"
const LIE_INJECTOR_PATH := "res://debug/lie_injector.gd"
const TIME_CONTROL_PATH := "res://debug/time_control.gd"

@onready var _container: SubViewportContainer = %WorldViewport
@onready var _world: SubViewport = %SubViewport

## Lo schermo diegetico e la postazione davanti a cui ci si siede. Si risolvono
## in `_ready()` e restano: senza di loro non si entra in nessuna fase.
var _crt: CrtScreen
var _desk: DeskCamera
var _monitor: CrtMonitor

## Chi decide cosa si fa stanotte. Vive sotto questo nodo, ma non conosce il
## mondo che gli sta intorno.
var _night: NightSession


func _ready() -> void:
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
	# LA NOTTE COMINCIA PER ULTIMA, a mondo montato: l'orchestratore mostra
	# subito la prima fase sul CRT, e il CRT deve già esistere.
	_begin_night()


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
	_monitor = monitor


## Monta l'orchestratore e gli consegna lo schermo.
##
## È l'unico punto in cui le due sponde si toccano: qui si sa dove vive il monitor
## (`world/`, trovato per gruppo) e si conosce chi deve mostrarci sopra le fasi
## (`night/`, che il mondo non può nominare). Da qui in poi non si incontrano più.
## OGNI USCITA ANTICIPATA SPEGNE IL MONITOR, e non è una rifinitura. Senza,
## `Interactable.enabled` resterebbe al `true` della scena: il prompt «[E] Usa il
## monitor» inviterebbe a premere un tasto su una postazione che non esiste, e
## `_on_monitor_interacted()` risponderebbe con un `push_error` a ogni pressione
## — lo spam che `_connect_monitor()` si dà la pena di evitare, e per giunta con
## un messaggio che indica la causa sbagliata. La causa vera è detta una volta,
## qui, e il mondo resta coerente con essa.
func _begin_night() -> void:
	if _crt == null:
		_refresh_monitor()
		return  # `_connect_monitor()` ha già detto perché
	var plan := load(NIGHT_PLAN_PATH) as NightPlan
	if plan == null:
		push_error("[main] piano della notte assente o illeggibile: %s" % NIGHT_PLAN_PATH)
		_refresh_monitor()
		return
	# SI CONFIGURA PRIMA DI MONTARE. Un orchestratore che non sa su quale schermo
	# lavora non è mezzo montato: è un oggetto che farebbe rispondere `true` a
	# `_night != null` a chiunque lo chieda, per il resto della sessione.
	var night := NIGHT_SESSION.instantiate() as NightSession
	night.plan = plan
	if not night.configure(_crt):
		night.queue_free()
		_refresh_monitor()
		return  # l'orchestratore ha già detto perché
	_night = night
	add_child(_night)
	_night.plan_exhausted.connect(_on_plan_exhausted)
	# Il monitor si accende e si spegne con il lavoro: vedi `_refresh_monitor()`.
	Events.phase_started.connect(func(_k: StringName) -> void: _refresh_monitor())
	Events.dawn_reached.connect(_refresh_monitor)
	Game.start_night(1)
	_night.begin()
	_refresh_monitor()


## Il monitor promette solo ciò che può mantenere.
##
## `Interactable.enabled` è già nel contratto degli interagibili, e `can_interact()`
## lo legge: da spento il monitor non mostra il prompt e non risponde a `E`.
## Serve perché finito l'allineamento — e finché l'alba non porta il riepilogo —
## sul CRT non c'è niente, ma il prompt «[E] Usa il monitor» continuerebbe a
## comparire su un oggetto che non fa nulla. Un interagibile che invita a premere
## un tasto inerte è la cosa che `world/interactables/` esiste per non fare.
##
## Lo decide il punto d'ingresso perché è l'unico che vede entrambe le sponde:
## `world/` non sa cosa sia una fase, e `night/` non sa cosa sia un monitor.
func _refresh_monitor() -> void:
	if _monitor == null:
		return
	_monitor.enabled = _night != null and _night.has_phase()


## Non c'è più niente da fare al monitor: chi è seduto si rialza.
##
## L'orchestratore sa che il piano è finito, ma non sa che qualcuno è alla
## postazione — `night/` non conosce `world/`, e il giocatore vive lì. Senza
## questa riga chi ha appena concluso l'ultima fase resterebbe seduto davanti a
## uno schermo vuoto, senza controllo e senza un motivo visibile per premere `E`.
##
## Differita perché `plan_exhausted` arriva dentro l'avanzamento di una fase che
## si sta smontando, e una transizione non si avvia dentro il teardown di
## un'altra.
func _on_plan_exhausted() -> void:
	_refresh_monitor()
	if _desk != null and _desk.is_seated:
		_stand_up.call_deferred()


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


## `E` sul monitor: ci si siede a lavorare.
##
## NON DECIDE COSA C'È DA FARE, e non lo sa. Quello lo decide l'orchestratore, che
## esegue il piano della notte: qui si controlla solo che ci sia qualcosa sullo
## schermo, e ci si siede. Un monitor su cui non c'è niente non merita che si
## tolga il controllo al giocatore.
##
## RI-SEDERSI È IL FLUSSO NORMALE, non un caso limite: il ciclo
## «siediti → alzati → risiediti» è il modo in cui si gioca.
func _on_monitor_interacted(_by: Node3D) -> void:
	if _crt == null or _desk == null or _night == null:
		# La postazione non è montata: non si cede il controllo a un giocatore
		# che poi non potrebbe né vedere né rialzarsi.
		push_error("[main] postazione non montata: non ci si siede")
		return
	if not _night.has_phase():
		return
	_sit_down()


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
	if _night != null:
		_night.set_player_present(true)
	_desk.toggle()


## Alza dalla postazione SENZA concludere niente. È il gesto che l'AC5 chiede e
## che fino alla 1.2 non esisteva: l'unica uscita era `ENTER`, che per contratto
## conclude l'allineamento ed emette il punteggio.
func _stand_up() -> void:
	if _desk == null or not _desk.is_seated:
		return
	if _crt != null:
		_crt.set_input_enabled(false)
	if _night != null:
		_night.set_player_present(false)
	# Lo schermo si ferma DOPO la fase, e non prima: così l'ultimo fotogramma che
	# resta sul vetro è quello di una fase già ferma.
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
	if _night == null or not _night.has_phase():
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

	# `F1`-`F4`: l'apparato sperimentale con cui si tara la durata dell'attesa
	# senza rigiocare la notte a velocità reale (FR35). Non ha bisogno di
	# `configure()`: scrive su `Engine.time_scale` e nient'altro.
	var time: Node = (load(TIME_CONTROL_PATH) as GDScript).new()
	time.name = "TimeControl"
	add_child(time)

	var overlay := (load(DEBUG_OVERLAY_PATH) as PackedScene).instantiate()
	overlay.configure(self, render)
	add_child(overlay)


## La fase corrente, per gli strumenti di debug.
##
## DELEGA, e non è un residuo. `debug/debug_overlay.gd` e `debug/lie_injector.gd`
## raggiungono la fase passando da qui, con il riferimento che ricevono in
## `configure(self)`. Se questo metodo fosse sparito insieme all'orchestrazione,
## l'overlay avrebbe smesso di funzionare a ogni frame; se fosse rimasto
## restituendo sempre `null`, sarebbe stato peggio — l'iniettore `F9`, che esiste
## per dimostrare che ADR-001 regge, avrebbe risposto «nessuna fase attiva»
## mentre una fase c'era. Uno strumento che mente in silenzio è peggio di uno
## rotto.
func current_phase() -> Phase:
	return _night.current_phase() if _night != null else null


## L'orologio della notte, per l'overlay di debug. Stessa ragione di sopra.
func clock() -> NightClock:
	return _night.clock() if _night != null else null


## Se c'è una fase ma nessuno è alla postazione. Stessa ragione di sopra.
##
## Da quando alzarsi SOSPENDE una fase invece di concluderla (storia 1.3), `F12`
## mostrava una fase ferma esattamente come una che gira: lo strumento con cui si
## guarda cosa sta succedendo non distingueva i due stati che la 1.3 ha creato.
func phase_suspended() -> bool:
	if _night == null:
		return false
	return _night.current_phase() != null and not _night.player_present()