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

## Il terminale gestionale (3.2). La SCENA si preload: appartiene al gioco, non a
## `debug/`, e deve esistere in ogni build. È l'unica cosa di `terminal/` che questo
## file nomina — il ponte world↔night↔terminal vive qui, l'unico punto che può
## conoscere entrambe le sponde. `night/` non conosce `terminal/`, e viceversa.
const TERMINAL := preload("res://terminal/terminal.tscn")

## La BBS (3.7), il secondo programma diegetico del PC — gemello del terminale. Stessa
## lifecycle: posseduto qui, mostrato sul CRT sopra il contenuto della notte, gated
## sull'attesa. È l'unica cosa di `bbs/` che questo file nomina — il ponte world↔night↔bbs
## vive qui, l'unico punto che può conoscere entrambe le sponde. `night/` non conosce
## `bbs/`, e viceversa.
const BBS := preload("res://bbs/bbs.tscn")

## Percorsi, NON preload. `const ... preload` risolve al caricamento dello script,
## in ogni build: con un preload gli strumenti di debug — e con l'iniettore anche
## `wandering_drift.tres` — finirebbero comunque dentro l'export di release, che
## è esattamente ciò che FR37 vieta. La guardia `OS.is_debug_build()` ferma
## l'istanziazione, non il caricamento. Con `load()` dietro la guardia, in
## release questi file non vengono nemmeno aperti.
## Quanto dura mezza dissolvenza. Mezzo secondo per lato: abbastanza da leggersi
## come un salto di tempo, poco abbastanza da non far aspettare chi ha appena
## deciso di andare a dormire.
const FADE_SEC := 0.5

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

## Il letto. È l'unico modo di far cominciare la notte dopo, e vale per lui la
## stessa divisione del monitor: `world/` lo possiede, questo file decide quando
## merita un prompt.
var _bed: Bed

## Il velo nero delle dissolvenze. Sta sopra il mondo ma SOTTO gli strumenti di
## debug, che entrano in albero dopo: chi sviluppa deve poter leggere l'overlay
## anche a schermo nero.
@onready var _fade: ColorRect = %Fade

## Vero dall'alba fino all'inizio della notte successiva. È la sola condizione che
## accende il letto: dormire con una posa in corso chiuderebbe la notte a metà, e
## nessuno ha ancora deciso cosa debba succedere in quel caso.
var _dawn := false

## Vero mentre la dissolvenza sta girando. Senza, una seconda `E` sul letto
## partirebbe a metà transizione e smonterebbe una notte già smontata.
var _sleeping := false

## Dove il giocatore stava all'avvio, catturato dalla scena in `_ready()`. È il
## posto in cui lo rimette il risveglio.
var _player_start: Transform3D

## Chi decide cosa si fa stanotte. Vive sotto questo nodo, ma non conosce il
## mondo che gli sta intorno.
var _night: NightSession

## Il terminale gestionale, posseduto da questo ponte. Istanziato una volta e
## riusato: aprirlo lo mostra sul CRT sopra ciò che `night/` mostrava, chiuderlo
## ripristina il contenuto della notte. Non è figlio di questo nodo finché non lo si
## mostra — `show_control()` lo reparenta nel viewport del CRT.
var _terminal: Control

## Vero mentre il terminale è mostrato sul CRT, sopra il contenuto della notte. È lo
## stato che il ponte sgancia alla chiusura, all'alba, e all'inizio della notte nuova.
var _terminal_open := false

## La BBS, posseduta da questo ponte come il terminale. Istanziata una volta e riusata:
## aprirla la mostra sul CRT sopra ciò che `night/` mostrava, chiuderla ripristina il
## contenuto della notte. Non è figlia di questo nodo finché non la si mostra —
## `show_control()` la reparenta nel viewport del CRT.
var _bbs: Control

## Vero mentre la BBS è mostrata sul CRT. MUTUAMENTE ESCLUSIVA col terminale: al più uno
## dei due è aperto, così due Control non si contendono il viewport (Design Notes).
var _bbs_open := false


func _ready() -> void:
	Log.info("main", "avvio — renderer %s" % RenderingServer.get_video_adapter_api_version())
	# LO STATO INIZIALE SI DICHIARA, non si eredita. `_enabled` nasce `true` nello
	# script del giocatore e la cattura del mouse sta nel suo `_ready()`: due posti
	# scollegati, e nessuno dei due è la sequenza di avvio. Questa riga la dice
	# dove si legge — e rilascia le azioni prima del primo frame, così una build
	# non parte con un tasto che risulta premuto da chissà quando.
	_set_world_active(true)
	_connect_monitor()
	_connect_bed()
	# LE POSIZIONI DI PARTENZA SI CATTURANO ORA, prima che qualcuno cammini: la
	# notte successiva rimette il giocatore dove la prima l'aveva trovato, e
	# «dove» è ciò che la scena dichiara, non una costante ricopiata qui.
	_capture_player_start()
	# GLI ASCOLTI DI `Events` STANNO QUI E NON IN `_begin_night()`, e la differenza
	# si vede solo alla seconda notte: `_begin_night()` viene richiamata a ogni
	# risveglio, e una `connect()` là dentro accumulerebbe un ascoltatore per
	# notte. Alla quinta, ogni `phase_started` aggiornerebbe il monitor cinque
	# volte — invisibile finché non lo è più.
	Events.phase_started.connect(func(_k: StringName) -> void: _refresh_affordances())
	Events.dawn_reached.connect(_on_dawn_reached)
	# LA POSA FINISCE E LO SCHERMO TORNA ALLA NOTTE. Adesso che terminale e BBS si
	# aprono DURANTE la posa, la fine della sequenza è il momento in cui `night/` si
	# riprende il vetro per la rivelazione: senza questo, il Control aperto verrebbe
	# sfrattato dal viewport restando marcato «aperto» — e per la telemetria della 3.6
	# una lettura del forum continuerebbe a correre attraverso stack, vendita e menu.
	Events.sequence_ended.connect(_on_sequence_ended)
	_setup_terminal()
	_setup_bbs()
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
		_refresh_affordances()
		return  # `_connect_monitor()` ha già detto perché
	var plan := load(NIGHT_PLAN_PATH) as NightPlan
	if plan == null:
		push_error("[main] piano della notte assente o illeggibile: %s" % NIGHT_PLAN_PATH)
		_refresh_affordances()
		return
	# SI CONFIGURA PRIMA DI MONTARE. Un orchestratore che non sa su quale schermo
	# lavora non è mezzo montato: è un oggetto che farebbe rispondere `true` a
	# `_night != null` a chiunque lo chieda, per il resto della sessione.
	var night := NIGHT_SESSION.instantiate() as NightSession
	night.plan = plan
	if not night.configure(_crt):
		night.queue_free()
		_refresh_affordances()
		return  # l'orchestratore ha già detto perché
	_night = night
	add_child(_night)
	_night.plan_exhausted.connect(_on_plan_exhausted)
	_start_new_night()


## Fa cominciare una notte sull'orchestratore già montato.
##
## L'ORCHESTRATORE SI RIUSA, NON SI RIFÀ, e non è un'economia: `begin()` è scritta
## per essere richiamata — ripulisce il contesto, il riepilogo, la rivelazione, la
## vendita e il menu della notte prima, e rifà ripartire l'orologio. Costruirne uno
## nuovo a ogni risveglio lascerebbe il vecchio a possedere dei `Control` che il
## CRT ha reparentato: non sono più suoi figli, `queue_free()` non se li porta via,
## e resterebbero appesi al viewport per il resto della partita. Misurato con una
## sonda, prima di scegliere questa via.
##
## E `_dawn` si azzera QUI: l'alba della notte precedente non vale per questa. Il
## letto si rispegne, e si riaccenderà quando anche questa notte sarà finita.
func _start_new_night() -> void:
	_dawn = false
	# DIFENSIVO: una notte nuova comincia col terminale sganciato. La notte prima può
	# essere finita con il terminale aperto e l'alba lo ha già sganciato senza
	# ripristinare (il riepilogo vince); ma se un percorso non previsto lo lasciasse
	# marcato, il flag mentirebbe alla notte nuova. Non si ripristina niente qui: si
	# azzera soltanto lo stato, che è ciò che una notte pulita deve trovare.
	_terminal_open = false
	# La BBS, come il terminale: si sgancia lo stato e la si riparcheggia spenta. Si
	# chiama `deactivate()` così un `started` eventualmente ancora aperto chiude la
	# propria coppia con `ended` — la telemetria non deve trovare un forum aperto che
	# attraversa il sonno. `deactivate` è idempotente (guardia `_active`): innocuo se
	# non era attivo.
	if _bbs != null:
		_bbs.deactivate()
	_bbs_open = false
	_park_bbs()
	Game.start_night()
	_night.begin()
	_refresh_affordances()


## Il monitor e il letto promettono solo ciò che possono mantenere.
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
func _refresh_affordances() -> void:
	if _monitor != null:
		_monitor.enabled = _night != null and _night.has_phase()
	# IL LETTO SEGUE LA REGOLA OPPOSTA AL MONITOR, ed è la simmetria che rende la
	# stanza leggibile senza spiegazioni: quando c'è lavoro si può usare il
	# monitor, quando la notte è finita si può andare a dormire. I due non
	# invitano mai insieme.
	#
	# MA ESISTE UNA FINESTRA IN CUI NESSUNO DEI DUE INVITA, e va detta invece che
	# scoperta: fra il piano esaurito e l'alba il monitor è spento e il letto non
	# è ancora acceso. Non è un buco da tappare — è l'attesa, cioè la cosa che
	# l'epica 3 esiste per riempire. Accendere il letto lì dentro darebbe al
	# giocatore un modo di saltarla, e l'MVP smetterebbe di misurare ciò per cui
	# esiste.
	if _bed != null:
		_bed.enabled = _dawn and not _sleeping


## Il letto si trova per GRUPPO, come il monitor e per la stessa ragione.
##
## La sua assenza è canale 1: senza letto la notte 2 è irraggiungibile e il
## giocatore girerebbe per la stanza senza capire perché non succede niente.
func _connect_bed() -> void:
	var bed := Bed.find_in(get_tree())
	if bed == null:
		push_error("[main] nessun Bed nel gruppo '%s'" % Bed.GROUP)
		return
	bed.interacted.connect(_on_bed_interacted)
	_bed = bed


## Dove il giocatore comincia, letto dalla SCENA e non da una costante.
##
## Serve al risveglio: la notte nuova rimette il corpo dove la scena lo aveva
## messo, e chi sposta il giocatore nell'editor sposta anche il risveglio senza
## dover sapere che questa funzione esiste.
func _capture_player_start() -> void:
	var player := Player.find_in(get_tree())
	if player == null:
		return  # `_set_world_active()` ha già detto perché
	_player_start = player.global_transform


## La sequenza è finita: chi era aperto sopra di lei si chiude, e `reshow_current()`
## rimette a schermo ciò che la notte mostra. Vale anche per la posa smontata a metà
## (alba, *rifai setup*), che è il caso in cui `sequence_ended` arriva da `_exit_tree`.
func _on_sequence_ended() -> void:
	if _terminal_open:
		_close_terminal()
	if _bbs_open:
		_close_bbs()


## L'alba è arrivata: da adesso si può andare a dormire.
##
## SE IL TERMINALE È APERTO ALL'ALBA, si sgancia lo stato SENZA ripristinare: `night/`
## ha già mostrato il riepilogo sul CRT, e il riepilogo vince (I/O matrix). Ripristinare
## `reshow_current()` qui riporterebbe a schermo il contenuto della notte scavalcando il
## riepilogo appena montato. Si scarta lo stato «terminale aperto» e basta.
func _on_dawn_reached() -> void:
	_dawn = true
	# Il terminale, se era aperto, si riparcheggia sotto questo nodo senza ripristinare il
	# contenuto della notte (il riepilogo vince). `night/` all'alba mostra il riepilogo,
	# che rimuove il terminale dal viewport: riportarlo qui evita di lasciarlo orfano.
	if _terminal_open:
		_terminal_open = false
		_park_terminal()
	# La BBS all'alba: stesso trattamento del terminale. Si sgancia lo stato SENZA
	# ripristinare (il riepilogo vince), e si chiama `deactivate()` per emettere `ended` —
	# la sessione di lettura finisce quando l'alba porta il riepilogo. `main.gd` chiama
	# `deactivate` in OGNI percorso di chiusura, così la coppia resta bilanciata.
	if _bbs_open:
		_bbs_open = false
		if _bbs != null:
			_bbs.deactivate()
		_park_bbs()
	_refresh_affordances()


## `E` sul letto: si dorme, e domani è un'altra notte.
func _on_bed_interacted(_by: Node3D) -> void:
	_sleep()


## LA NOTTE NUOVA NON RICARICA LA SCENA, e la differenza conta.
##
## Ricaricare sarebbe stato più corto da scrivere, e avrebbe buttato via anche il
## mondo: la stanza si ricostruirebbe da capo, gli strumenti di debug si
## rimonterebbero, e la taratura PS1 trovata con Shift+F1..F7 tornerebbe ai valori
## del file a ogni risveglio. Qui non muore niente: l'orchestratore ricomincia, il
## giocatore torna al suo posto, e il mondo resta quello di prima. L'osservatorio
## non va a dormire.
##
## `await` dentro una risposta a un segnale è legittimo: la funzione ritorna al
## primo `await` e riprende da sé. `_sleeping` protegge la finestra.
func _sleep() -> void:
	if _sleeping or _night == null:
		return
	_sleeping = true
	# Il letto si spegne PRIMA della dissolvenza, non dopo: fra l'inizio del nero
	# e la fine della transizione passa mezzo secondo di gioco vivo, e una seconda
	# `E` lì dentro entrerebbe in una notte che si sta già smontando.
	_refresh_affordances()
	_set_world_active(false)
	await _fade_to(1.0)
	# A SCHERMO NERO, e in quest'ordine: il giocatore torna al suo posto prima che
	# la notte nuova cominci, così il primo fotogramma dopo la dissolvenza è già
	# quello giusto e non c'è un frame in cui si vede la stanza dal punto in cui ci
	# si era addormentati.
	_place_player_at_start()
	_start_new_night()
	await _fade_to(0.0)
	_sleeping = false
	_set_world_active(true)
	_refresh_affordances()


## Rimette il giocatore dove la scena lo aveva messo, sguardo compreso.
##
## LO SGUARDO ANCHE, e non è pignoleria: chi si addormenta guardando il soffitto
## si sveglierebbe guardando il soffitto, e il primo fotogramma della notte nuova
## sarebbe un intonaco. Il beccheggio vive sulla camera (mai sul corpo — vedi
## l'intestazione di `player.gd`), quindi va azzerato lì.
func _place_player_at_start() -> void:
	var player := Player.find_in(get_tree())
	if player == null:
		return
	player.velocity = Vector3.ZERO
	player.global_transform = _player_start
	var cam := player.camera()
	if cam != null:
		cam.rotation.x = 0.0


## Porta il velo nero all'opacità voluta e aspetta che ci sia arrivato.
##
## Il Tween nasce da questo nodo — `create_tween()` su un orfano non riceve mai un
## tick, e l'`await` non tornerebbe più: il gioco resterebbe a metà dissolvenza,
## senza controllo. È la stessa trappola documentata su `_setup_desk()`.
func _fade_to(alpha: float) -> void:
	if _fade == null:
		return
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, FADE_SEC)
	await t.finished


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
	_refresh_affordances()
	if _desk != null and _desk.is_seated:
		_stand_up.call_deferred()


## Istanzia il terminale e ne ascolta l'uscita. Una volta sola, all'avvio: il terminale
## si riusa a ogni apertura invece di rifarsi, come l'orchestratore della notte.
##
## LO SI PARCHEGGIA SOTTO QUESTO NODO, spento, invece di lasciarlo orfano. `show_control`
## lo reparenta nel viewport del CRT quando lo si apre; alla chiusura `_close_terminal`
## lo riporta qui. Così l'albero lo possiede sempre e lo libera all'uscita: un Control
## istanziato e mai aggiunto all'albero resterebbe orfano e verrebbe segnalato come
## risorsa ancora in uso alla chiusura del gioco. Parcheggiato e spento (`DISABLED`,
## `hide()`) non processa e non si disegna finché non è mostrato.
func _setup_terminal() -> void:
	_terminal = TERMINAL.instantiate() as Control
	if _terminal == null:
		push_error("[main] terminale non istanziabile")
		return
	# `closed` → chiude il terminale e ripristina il contenuto della notte. DIFFERITO
	# (NFR16): `closed` nasce dentro l'`_unhandled_input` del terminale, e `_close_terminal`
	# lo riparenta fuori dal viewport del CRT — riparentare il nodo dentro la propria
	# callback d'input è ciò che tutta la notte evita con `CONNECT_DEFERRED`. Differendo,
	# il terminale finisce il suo input in pace e il ripristino gira al tick successivo.
	_terminal.closed.connect(_close_terminal, CONNECT_DEFERRED)
	_terminal.hide()
	_terminal.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_terminal)


## Apre o chiude il terminale, gated sull'attesa. È il tasto `terminal_open`.
##
## GATED SU `is_waiting()`: mai sovrapposto a una fase interattiva o alla
## vendita/rivelazione — aprirlo lì e poi ripristinare rischierebbe di disturbare uno
## stato vivo. Il menu post-foto NON conta come stato vivo da proteggere: è l'attesa, e
## il terminale è un secondo programma aperto sopra di esso.
func _toggle_terminal() -> void:
	if _terminal_open:
		_close_terminal()
		return
	if _terminal == null or _crt == null or _night == null:
		return
	# MUTUA ESCLUSIONE con la BBS (3.7): il terminale si apre solo se la BBS è chiusa, così
	# due Control non si contendono il viewport. Il simmetrico è in `_toggle_bbs`.
	if _bbs_open:
		return
	if not _night.is_waiting():
		# Non si è in attesa (una fase interattiva è a schermo): il tasto non apre nulla.
		return
	# Riacceso all'apertura: parcheggiato era `DISABLED` e nascosto. `show_control` lo
	# reparenta nel viewport del CRT; da seduti lo schermo è già vivo e con l'input
	# aperto, quindi l'`_unhandled_input` del terminale riceve gli eventi inoltrati.
	_terminal.show()
	_terminal.process_mode = Node.PROCESS_MODE_INHERIT
	_crt.show_control(_terminal)
	_terminal.arm()
	_terminal_open = true


## Chiude il terminale e chiede a `night/` di ri-mostrare il proprio contenuto (il menu
## post-foto, o niente). Idempotente: chiamarlo a terminale già chiuso non fa nulla.
##
## Lo chiama `closed()` del terminale (tasto back/quit), il secondo `terminal_open`, e
## `interact` prima di alzarsi. NON lo chiama l'alba, che sgancia lo stato senza
## ripristinare (il riepilogo vince).
func _close_terminal() -> void:
	if not _terminal_open:
		return
	_terminal_open = false
	# `reshow_current()` chiama `show_control()` del contenuto della notte, che RIMUOVE il
	# terminale dal viewport senza liberarlo (regola di proprietà del CRT). Va riportato
	# sotto questo nodo, spento, o resterebbe orfano — vivo ma fuori dall'albero, segnalato
	# alla chiusura del gioco. Si riparcheggia PRIMA di `reshow_current`, così il viewport
	# è già libero quando la notte mostra il proprio Control.
	_park_terminal()
	if _night != null:
		_night.reshow_current()


## Riporta il terminale sotto questo nodo, spento e nascosto, da dovunque si trovi:
## mostrato nel viewport del CRT (parent = il viewport) o già orfano (parent = null,
## quando il riepilogo dell'alba l'ha già rimosso dal viewport). `reparent` vuole un
## parent; se non c'è, `add_child`. Così il terminale è sempre posseduto dall'albero e
## liberato all'uscita, e non compare mai come risorsa ancora in uso alla chiusura.
func _park_terminal() -> void:
	if _terminal == null:
		return
	var parent := _terminal.get_parent()
	if parent == self:
		pass
	elif parent != null:
		_terminal.reparent(self)
	else:
		add_child(_terminal)
	_terminal.hide()
	_terminal.process_mode = Node.PROCESS_MODE_DISABLED


## Istanzia la BBS e ne ascolta l'uscita. Una volta sola, all'avvio: la BBS si riusa a
## ogni apertura invece di rifarsi, come il terminale e l'orchestratore della notte.
## Parcheggiata sotto questo nodo, spenta (`DISABLED`, `hide()`), finché non la si mostra.
func _setup_bbs() -> void:
	_bbs = BBS.instantiate() as Control
	if _bbs == null:
		push_error("[main] BBS non istanziabile")
		return
	# `closed` → chiude la BBS e ripristina il contenuto della notte. DIFFERITO (NFR16),
	# per la stessa ragione del terminale: `closed` nasce dentro l'`_unhandled_input` della
	# BBS, e `_close_bbs` la reparenta fuori dal viewport del CRT — riparentare il nodo
	# dentro la propria callback d'input è ciò che tutta la notte evita con `CONNECT_DEFERRED`.
	_bbs.closed.connect(_close_bbs, CONNECT_DEFERRED)
	_bbs.hide()
	_bbs.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_bbs)


## Apre o chiude la BBS, gated sull'attesa e MUTUAMENTE ESCLUSIVA col terminale. È il
## tasto `bbs_open`.
##
## GATED SU `is_waiting()`, come il terminale: mai sovrapposta a una fase interattiva o
## alla vendita/rivelazione. MUTUA ESCLUSIONE: si apre solo se il terminale è chiuso, così
## due Control non si contendono il viewport. `activate()` emette `wait_activity_started`.
func _toggle_bbs() -> void:
	if _bbs_open:
		_close_bbs()
		return
	if _bbs == null or _crt == null or _night == null:
		return
	if _terminal_open:
		# Il terminale è aperto: la BBS non si apre (mutua esclusione). Si finisce col
		# terminale prima.
		return
	if not _night.is_waiting():
		# Non si è in attesa (una fase interattiva è a schermo): il tasto non apre nulla.
		return
	_bbs.show()
	_bbs.process_mode = Node.PROCESS_MODE_INHERIT
	_crt.show_control(_bbs)
	_bbs.arm()
	# `activate()` DOPO `arm()`: `arm` mette a punto la vista (e avvia l'handshake),
	# `activate` è il fatto misurato — emette `wait_activity_started(&"forum")`.
	_bbs.activate()
	_bbs_open = true


## Chiude la BBS e chiede a `night/` di ri-mostrare il proprio contenuto (il menu
## post-foto, o niente). Idempotente: chiamarlo a BBS già chiusa non fa nulla.
##
## Lo chiama `closed()` della BBS (tasto back/quit dall'elenco), il secondo `bbs_open`, e
## `interact` prima di alzarsi. NON lo chiama l'alba, che sgancia lo stato senza
## ripristinare (il riepilogo vince) ma chiama comunque `deactivate()`.
func _close_bbs() -> void:
	if not _bbs_open:
		return
	_bbs_open = false
	# `deactivate()` emette `wait_activity_ended(&"forum")` (idempotente): la coppia si
	# chiude qui, come su ogni percorso di chiusura.
	if _bbs != null:
		_bbs.deactivate()
	# Si riparcheggia PRIMA di `reshow_current`, così il viewport è già libero quando la
	# notte mostra il proprio Control. Stessa regola di proprietà del CRT del terminale.
	_park_bbs()
	if _night != null:
		_night.reshow_current()


## Riporta la BBS sotto questo nodo, spenta e nascosta, da dovunque si trovi — mostrata
## nel viewport del CRT o già orfana (quando il riepilogo dell'alba l'ha rimossa). Gemello
## di `_park_terminal`: `reparent` se ha un parent, `add_child` se orfana. Così la BBS è
## sempre posseduta dall'albero e liberata all'uscita, e non compare mai come risorsa
## ancora in uso alla chiusura.
func _park_bbs() -> void:
	if _bbs == null:
		return
	var parent := _bbs.get_parent()
	if parent == self:
		pass
	elif parent != null:
		_bbs.reparent(self)
	else:
		add_child(_bbs)
	_bbs.hide()
	_bbs.process_mode = Node.PROCESS_MODE_DISABLED


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

	# IL TERMINALE SI APRE E SI CHIUDE QUI, prima di `_unhandled_input`, per la stessa
	# ragione per cui `interact` si legge qui: `_shortcut_input` gira dopo `_input` e
	# PRIMA di ogni `_unhandled_input`, e nessun Control lo implementa. Intercettando
	# `terminal_open` qui il tasto non raggiunge il Control sotto (il menu post-foto),
	# che altrimenti lo vedrebbe come input non gestito. Correzione preventiva sul
	# modello del commento di `_stand_up`.
	if event.is_action_pressed(&"terminal_open"):
		_toggle_terminal()
		get_viewport().set_input_as_handled()
		return

	# La BBS si apre e si chiude QUI, accanto al terminale e per la stessa ragione:
	# `_shortcut_input` gira dopo `_input` e PRIMA di ogni `_unhandled_input`, e nessun
	# Control lo implementa. Intercettando `bbs_open` qui il tasto non raggiunge il Control
	# sotto. La mutua esclusione è SIMMETRICA e vive nei due toggle: `_toggle_bbs` si apre
	# solo se il terminale è chiuso, e `_toggle_terminal` si apre solo se la BBS è chiusa
	# (ciascun toggle rifiuta se l'altro è aperto). Così al più uno dei due è a schermo, e
	# due Control non si contendono mai il viewport.
	if event.is_action_pressed(&"bbs_open"):
		_toggle_bbs()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(&"interact"):
		# `interact` (E) alza SEMPRE; se il terminale o la BBS sono aperti, prima li si
		# chiude e si ripristina il contenuto della notte, così ci si rialza da uno stato
		# coerente e non con un Control ancora marcato aperto sotto lo schermo fermo. Al
		# più uno dei due è aperto (mutua esclusione), ma chiuderli entrambi è innocuo
		# (idempotenti) e non dipende dall'invariante.
		if _terminal_open:
			_close_terminal()
		if _bbs_open:
			_close_bbs()
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