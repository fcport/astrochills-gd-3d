## Punto d'ingresso. Il mondo 3D vive dentro un SubViewport a bassa risoluzione,
## riscalato con filtro nearest.
##
## È la tecnica PS1 più fedele, ed è anche la strada scelta per ottenere un
## post-effect a schermo intero senza CompositorEffect — che in Compatibility
## non esiste. Il vincolo del renderer spinge nella direzione giusta.
##
## PONTE DICHIARATO E TEMPORANEO. La stanza adesso c'è (storia 1.2), ma il
## `Control` della fase non è ancora sul CRT diegetico: ci arriva con la 1.3.
## Fino ad allora questo file fa da orchestratore povero e `ScreenViewport` fa da
## CRT povero — a 256x192, la stessa misura del monitor vero, perché
## un'interfaccia che sta comoda a 640x360 e non ci sta a 256x192 sembrerebbe
## finita e non lo sarebbe.
##
## IL CONTROLLO È DI UNO SOLO ALLA VOLTA, e non è una scelta di comodo.
## `W`, `A`, `S`, `D` e `ENTER` sono legati sia al movimento sia alle due viti
## della fase polare: con entrambi attivi, camminare girerebbe le viti. Le azioni
## polari non si possono rinominare, perché `phases/polar/phase_polar.gd` le
## nomina e la prova dell'AC2 della storia 1.1 richiede che quel file non cambi.
## Quindi comanda uno solo alla volta: si entra nella fase interagendo col
## monitor, e il controller del giocatore si spegne.
##
## Quello che si spegne è il CONTROLLO, non il mondo: l'osservatorio resta in
## scena e continua a essere renderizzato dietro il pannello della fase. È voluto
## — alla 1.3 il giocatore sarà seduto davanti al CRT e dovrà vedersi intorno la
## stanza — e il costo di quel render pass è il rilievo M4, dichiarato e non
## aperto qui.
##
## LO STATO DEI TASTI NON SEGUE IL CONTROLLO. `Input.get_axis` e
## `Input.get_vector` leggono lo stato fisico della tastiera, che non sa nulla di
## chi sia abilitato: chi entra nella fase tenendo premuto `W` per camminare si
## troverebbe la vite di altitudine che gira da sola, e chi esce tenendo premuto
## `W` per girare la vite si troverebbe il giocatore che parte in avanti. Per
## questo ogni scambio rilascia le azioni: vedi `_release_all_actions()`.
##
## Spegnere il controller non è lavoro che la 1.3 butterà: ADR-003 comincia
## esattamente con «il controller del giocatore si disabilita». Qui c'è il primo
## passo di quella sequenza; la 1.3 aggiunge l'aggancio al `Marker3D`, il tween
## della camera e il passaggio dell'input al `SubViewport`.
##
## LA MISURA DEL MONDO NON SI DICHIARA NELLA SCENA. `WorldViewport` è un
## SubViewportContainer con `stretch = true`, e un container di quel tipo impone
## sempre al proprio SubViewport la misura `container / stretch_shrink` — su
## finestra 1280x720 con shrink 2 fa 640x360. Qualunque `size` scritto a mano sul
## SubViewport viene sovrascritto al primo ridimensionamento: è un numero morto
## che mente a chi tara il look PS1, e per questo non c'è.
##
## Quando arriverà `night/night_session.gd`, questo file gli cede il lavoro senza
## che la fase se ne accorga: la fase parla `Control`, e non sa dove finisca.
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
@onready var _screen_viewport: SubViewport = %ScreenViewport
@onready var _screen_host: SubViewportContainer = %ScreenHost
@onready var _phase_host: Node = %PhaseHost

var _phase: Phase


func _ready() -> void:
	Game.start_night(1)
	Log.info("main", "avvio — renderer %s" % RenderingServer.get_video_adapter_api_version())
	# LO STATO INIZIALE SI DICHIARA, non si eredita. Prima stava in tre posti
	# scollegati — `visible = false` nella scena, `_enabled = true` nello script
	# del giocatore, la cattura del mouse nel suo `_ready` — e bastava aprire
	# `main.tscn`, rimettere visibile lo `ScreenHost` e salvare per consegnare
	# una build che parte con l'interfaccia della fase a schermo e il giocatore
	# che cammina sotto.
	_set_world_active(true)
	_connect_monitor()
	if OS.is_debug_build():
		_install_debug_tools()


## Il monitor si trova per GRUPPO, mai per percorso di nodo: un percorso si
## romperebbe al primo spostamento, ed è precisamente ciò che l'AC3 della storia
## 1.2 vieta. Il gruppo sopravvive a spostamenti, rinomine e annidamenti diversi.
func _connect_monitor() -> void:
	var monitor := CrtMonitor.find_in(get_tree())
	if monitor == null:
		# Canale 1: è un errore di programma. Senza monitor la fase è
		# irraggiungibile, e il giocatore girerebbe per la stanza senza capire.
		push_error("[main] nessun CrtMonitor nel gruppo '%s'" % CrtMonitor.GROUP)
		return
	monitor.interacted.connect(_on_monitor_interacted)


func _on_monitor_interacted(_by: Node3D) -> void:
	if _phase != null:
		return
	_enter_phase(PHASE_POLAR)


## Dà o toglie il controllo al giocatore, e mostra o nasconde il pannello della
## fase. Il mondo resta renderizzato in entrambi i casi: vedi l'intestazione.
##
## Il giocatore si risolve PRIMA di toccare qualunque cosa. Mutare la visibilità
## e accorgersi solo dopo che il giocatore non c'è lascerebbe l'interfaccia della
## fase a schermo con il controller ancora acceso sotto — cioè esattamente il
## doppio comando che tutto questo esiste per impedire.
func _set_world_active(active: bool) -> void:
	var player := Player.find_in(get_tree())
	if player == null:
		push_error("[main] nessun Player nel gruppo '%s'" % Player.GROUP)
		return
	_release_all_actions()
	_screen_host.visible = not active
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
		_show(null)
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
	# senza un solo messaggio.
	if not _phase_can_run(p):
		push_error("[main] fase %s non configurata: non le si cede il controllo" % p.key())
		p.queue_free()
		return

	_phase = p
	# screen() dopo: il Control si risolve in _ready della fase.
	_show(p.screen())
	_set_world_active(false)
	Events.phase_started.emit(p.key())


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


## Mima `crt/crt_screen.gd::show_control()`, e ne eredita la regola:
## NON LIBERA MAI ciò che mostra. Dopo reparent() il Control non è più figlio
## della fase, ma la proprietà resta sua — è `Phase` a liberarlo quando viene
## distrutta (`NOTIFICATION_PREDELETE`).
## Un queue_free() qui distruggerebbe l'interfaccia di una fase ancora viva.
func _show(c: Control) -> void:
	for child in _screen_viewport.get_children():
		_screen_viewport.remove_child(child)
	if c == null:
		return
	if c.get_parent() != null:
		c.reparent(_screen_viewport)
	else:
		_screen_viewport.add_child(c)
	c.set_anchors_preset(Control.PRESET_FULL_RECT)


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
		_show(null)
		_phase = null

	# LA FASE ESCE DI SCENA PRIMA CHE IL CONTROLLO TORNI: vedi `_dispose()`.
	_dispose(phase)

	if was_current:
		# Il giocatore riprende il controllo, e torna in piedi nella stanza.
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
## della review della 1.1, e qui torna utile.
func _dispose(phase: Phase) -> void:
	if phase.get_parent() != null:
		phase.get_parent().remove_child(phase)
	phase.queue_free()
