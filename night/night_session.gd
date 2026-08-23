## L'orchestratore della notte: setup una volta, foto a ogni scatto, poi l'alba.
##
## NON SA COSA FANNO LE FASI, ed è tutto ADR-002: «l'orchestratore le istanzia, si
## collega a `finished(result)`, e non sa cosa facciano dentro». La prova è
## meccanica e va tenuta verde: **in questo file non compare il nome di nessuna
## fase** — nessun `preload`, nessun `match` su `key()`. Le fasi arrivano dal
## `NightPlan`, che è un `.tres`, perché gli upgrade che automatizzano una fase
## devono poter cancellare una riga da un dato invece di modificare questo file.
##
## COSA CONOSCE E COSA NO. La tabella dei confini gli concede `core/`, le cartelle
## delle fasi e delle foto, e `crt/`; gli vieta la cartella del mondo. Per questo il `CrtScreen`
## non se lo cerca: glielo passa il punto d'ingresso in `configure()`, che è
## l'unico a poter conoscere entrambe le sponde. Il monitor è un oggetto del
## mondo, ma il TIPO `CrtScreen` appartiene a `crt/`, che è un sistema generico —
## ed è questa distinzione a rendere lecito che l'orchestratore chiami
## `show_control()`. Il confine si prova con un grep sul nome di quella cartella
## dentro questa, e deve restare a zero — per questo qui non la si nomina nemmeno
## nei commenti.
##
## `Events.screen_registered` NON è la strada, benché l'architettura la proponga:
## `CrtScreen` emette nel proprio `_ready()`, l'albero si costruisce
## profondità-prima, e questo nodo nasce dopo. Chi arriva tardi non aspetta un
## annuncio — e chi lo cerca per gruppo è `main.gd`, che può.
##
## LA POSTAZIONE NON È SUA. Chi si siede, chi cammina, chi ha il controllo vive
## nel mondo, e passa da `main.gd`. Questo file sa soltanto se il giocatore è alla
## postazione (`set_player_present`), e ne ricava se la fase debba girare o
## restare ferma. La coreografia di ADR-003 è rimasta dov'era, perché tagliarla a
## metà riaprirebbe i due blocchi senza ritorno che la code review della 1.3 ha
## chiuso.
##
## L'ALBA È UN SECONDO INGRESSO. Non arriva da un `PhaseResult`: arriva
## dall'orologio, e non chiede permesso a niente — smonta la fase in corso senza
## aspettarla, perché è ciò che l'AC chiede.
class_name NightSession
extends Node

## Il riepilogo dell'alba. `preload` e non `load`: appartiene a `night/` come
## questo file, e deve esistere in ogni build — a differenza di `debug/`, che
## FR37 tiene fuori dalla release e per cui la regola è l'opposta.
const SUMMARY := preload("res://night/night_summary.gd")

## La rivelazione dello stack. `preload` come il riepilogo: appartiene a `night/` e
## deve esistere in ogni build. Preload di un Control di `night/`, NON di una fase —
## la prova meccanica (nessun nome di fase in questo file) resta verde: `night/` può
## dipendere da `photo/` e da sé stesso, non deve nominare `phases/`.
const REVEAL := preload("res://night/stacking_reveal.gd")

## Il piano non ha altro da dare, per adesso.
##
## Signal DIRETTO e non `Events`: l'ascoltatore è uno solo e si sa chi è — il
## punto d'ingresso, che è l'unico a poter far rialzare il giocatore. Serve
## perché senza di lui chi ha appena concluso l'ultima fase resterebbe seduto
## davanti a uno schermo vuoto e senza controllo: l'orchestratore sa che non c'è
## più niente da fare, ma non sa che qualcuno è seduto a guardare.
##
## Non viene emesso all'alba: il riepilogo è qualcosa da leggere, e chi è alla
## postazione deve poterci restare.
signal plan_exhausted()

## Quali fasi, e in che ordine. È un dato: vedi `core/night_plan.gd`.
@export var plan: NightPlan

@onready var _host: Node = %PhaseHost
@onready var _clock: NightClock = %NightClock

var _crt: CrtScreen
var _phase: Phase
var _summary: Control

## La rivelazione dello stack, quando c'è. È un `Control` di `night/` mostrato sul
## CRT come `_summary`: l'orchestratore lo possiede, lo mostra e lo libera. Non è
## una fase — non entra in `_phase`, non emette `finished`, non scrive punteggi.
var _stacking: Control

## Ciò che una fase lascia a quelle dopo di lei. `PhaseResult.payload` entra qui,
## e da qui esce in `Phase.setup(run, ctx)`: è il solo canale previsto, perché
## una fase non importa mai da un'altra fase (ADR-002).
var _ctx: Dictionary = {}

## I `process_mode` che la fase e il suo `Control` avevano quando sono nati.
## Sospendere li sostituisce, riprendere li rimette: imporre `INHERIT` alla
## ripresa cancellerebbe in silenzio un `PROCESS_MODE_ALWAYS` dichiarato dalla
## fase. È una correzione della code review della 1.3.
var _phase_mode := Node.PROCESS_MODE_INHERIT
var _screen_mode := Node.PROCESS_MODE_INHERIT

## Il modo che la rivelazione aveva alla nascita, per la stessa ragione degli altri
## due: sospenderla lo sostituisce con `DISABLED`, riprenderla lo rimette. Imporre
## `INHERIT` alla ripresa andrebbe bene qui — il Control nasce `INHERIT` — ma si
## salva comunque per non deviare dal modello della fase e del suo schermo.
var _stacking_mode := Node.PROCESS_MODE_INHERIT

var _setup_index := 0
var _photo_index := 0
var _in_setup := true
var _player_present := false
var _ended := false


func _ready() -> void:
	_clock.dawn.connect(_on_dawn)


## Dice all'orchestratore su quale schermo lavora. Torna `false` se non può.
func configure(crt: CrtScreen) -> bool:
	if crt == null:
		push_error("[night] configure() senza CrtScreen: la notte non ha uno schermo")
		return false
	if plan == null:
		push_error("[night] configure() senza NightPlan: la notte non ha un piano")
		return false
	_crt = crt
	return true


## Comincia la notte. Il punto d'ingresso ha già chiamato `Game.start_night()`.
func begin() -> void:
	if _crt == null or plan == null:
		push_error("[night] begin() prima di configure()")
		return
	if not _clock.begin(Game.run):
		return
	_setup_index = 0
	_photo_index = 0
	_in_setup = true
	_ended = false
	# Anche ciò che una notte LASCIA, non solo dove era arrivata. `_ctx` col
	# payload della notte prima finirebbe in `Phase.setup()` della prima fase di
	# questa; un `_summary` non nullo fa mentire `has_phase()` prima ancora che
	# esista una fase. Il riepilogo lo libera chi lo ha creato: il CRT non libera
	# mai ciò che mostra, e nessun altro lo possiede.
	_ctx.clear()
	if _summary != null:
		_summary.queue_free()
		_summary = null
	# Come il riepilogo: uno `_stacking` non nullo di una notte prima farebbe
	# mentire `has_phase()` prima che esista qualcosa da fare, e resterebbe a
	# schermo. Lo libera chi lo ha creato — il CRT non libera mai ciò che mostra.
	if _stacking != null:
		_stacking.queue_free()
		_stacking = null
	_enter_next()


## La fase corrente, o `null`. La usano gli strumenti di debug, che raggiungono
## l'orchestratore passando dal punto d'ingresso.
func current_phase() -> Phase:
	return _phase


## Se c'è qualcosa da fare al monitor adesso.
func has_phase() -> bool:
	return _phase != null or _summary != null or _stacking != null


func clock() -> NightClock:
	return _clock


## Se il giocatore è alla postazione.
##
## Lo legge l'overlay, passando dal punto d'ingresso: fino alla 2.1 una fase
## sospesa e una che gira si vedevano identiche in `F12`, ed è la voce rinviata
## che il Task 7 chiedeva di chiudere o di rimandare per iscritto.
func player_present() -> bool:
	return _player_present


## Il giocatore è arrivato alla postazione, o se n'è andato.
##
## SOSPENDERE NON È LIBERARE, ed è la regola stabilita dalla storia 1.3. Sono due
## assi distinti:
##
##   ASCOLTARE — segue SEMPRE la postazione. Nessuna fase si comanda da un'altra
##   stanza, nemmeno una che gira in background: `runs_in_background()` dice che
##   una fase continua a LAVORARE quando il giocatore se ne va, non che resti
##   raggiungibile dalla cucina.
##
##   GIRARE — qui `runs_in_background()` esenta davvero, ed è ciò su cui la fase
##   10 dell'epica 3 poggerà.
##
## Il `Control` va sospeso a parte: dopo `show_control()` vive nel `SubViewport`
## del CRT e non è più figlio della fase, quindi non eredita niente da lei.
func set_player_present(present: bool) -> void:
	_player_present = present

	# La rivelazione dello stack è present-gated come uno schermo di fase: avanza
	# (`_process`) solo alla postazione, così l'immagine emerge SOTTO GLI OCCHI del
	# giocatore e non nel vuoto mentre lui è in cucina. Vive nel `SubViewport` del
	# CRT, non è figlio di niente che erediti, quindi va sospesa a parte — come il
	# `Control` di una fase. Non ha `runs_in_background()`: l'emersione È il guardare.
	if _stacking != null and is_instance_valid(_stacking):
		_stacking.process_mode = _stacking_mode if present else Node.PROCESS_MODE_DISABLED

	if _phase == null:
		return

	var s := _phase.screen()
	var has_screen := s != null and is_instance_valid(s)

	_phase.set_process_input(present)
	_phase.set_process_unhandled_input(present)

	if not present and _phase.runs_in_background():
		return
	if present:
		_phase.process_mode = _phase_mode
		if has_screen:
			s.process_mode = _screen_mode
		return
	_phase.process_mode = Node.PROCESS_MODE_DISABLED
	if has_screen:
		s.process_mode = Node.PROCESS_MODE_DISABLED


# ---------------------------------------------------------------- il piano

## La prossima scena da eseguire, o `null` se per adesso non c'è più niente.
##
## Le fasi di **setup** si fanno una volta per notte; quelle di **foto** una volta
## per scatto. La distinzione sta nei due array del `NightPlan`, non in un `if`
## qui dentro — ed è questo che rende vera la promessa «automatizzare una fase
## sarà cancellare una riga dal `.tres`».
func _next_scene() -> PackedScene:
	if _in_setup:
		while _setup_index < plan.setup_phases.size():
			var s := plan.setup_phases[_setup_index]
			_setup_index += 1
			if s != null:
				return s
			# UNA CASELLA VUOTA NON È UNA FINE. `Array[PackedScene]` accetta uno
			# slot mai riempito, e restituirlo come `null` farebbe passare un
			# errore di dato per una scelta di design: la notte finirebbe a metà
			# senza una riga di log. Il `.tres` è il punto di estensione
			# principale del progetto, e si edita a mano.
			push_error("[night] casella vuota fra le fasi di setup: la salto")
		_in_setup = false
		_photo_index = 0
	while _photo_index < plan.photo_phases.size():
		var s := plan.photo_phases[_photo_index]
		_photo_index += 1
		if s != null:
			return s
		push_error("[night] casella vuota fra le fasi di foto: la salto")
	return null


## Entra nella fase successiva, o lascia la notte in attesa dell'alba.
##
## OGGI `photo_phases` È VUOTO, e non è un difetto: le fasi di foto arrivano con
## le storie 2.2 e 2.3. Finito il setup non resta niente da fare, lo schermo si
## svuota e la notte prosegue fino all'alba — che è esattamente la promessa
## dell'epica, «a ogni storia la notte è giocabile, semplicemente finisce un po'
## prima». Ciò che riapre il ciclo delle foto è il menu post-foto della 2.6.
func _enter_next() -> void:
	if _ended:
		return
	var scene := _next_scene()
	if scene == null:
		_finish_photo_cycle()
		return
	_enter_phase(scene)


## Il ciclo delle foto si è esaurito. Se nel `ctx` c'è una foto — e non se n'è già
## rivelata una — si conduce lo stacking; altrimenti si svuota il vetro e si
## avverte il punto d'ingresso, il comportamento di quando `photo_phases` era vuoto.
##
## CHE CI SIA UNA FOTO LO DICE IL DATO, non il nome di una fase (ADR-002): lo si
## chiede a `Photo.is_photo(_ctx)`, che guarda esposizione e conteggio frame nel
## payload accumulato. Qui non compare nessun nome di fase, come promette la testa
## di questo file.
##
## `_stacking == null` GUARDIA CONTRO LA DOPPIA RIVELAZIONE: `_enter_next` può
## essere ri-accodato (una fase in ritardo, un `call_deferred`), e senza la guardia
## costruirebbe un secondo stack — e registrerebbe la stessa foto due volte.
func _finish_photo_cycle() -> void:
	if Photo.is_photo(_ctx) and _stacking == null:
		_enter_stacking()
		return
	_crt.show_control(null)
	plan_exhausted.emit()


## Aggrega la qualità, registra la foto, e mette la rivelazione sul vetro.
##
## LA QUALITÀ È AGGREGAZIONE PURA (AC2): `PhotoQuality` legge `run.phase_scores` —
## dove l'ereditarietà vive già come persistenza — e restituisce un `int`. Il record
## va in `Game.run.photos` col suo indice: è il canale-dati verso la 2.5. Lo
## stacking NON scrive in `phase_scores` né emette `phase_finished`: non è una fase
## che compone la foto, è dove la foto si aggrega.
##
## Il gating si arma alla fine con `set_player_present(_player_present)`, come per
## una fase appena montata: la rivelazione nasce ferma se il giocatore non c'è.
func _enter_stacking() -> void:
	var quality := PhotoQuality.new().aggregate(Game.run.phase_scores)
	var record := Photo.from_ctx(_ctx, quality, Game.run.photos.size())
	Game.run.photos.append(record)

	_stacking = REVEAL.new()
	# Il modo si registra appena il Control esiste, prima che il gating lo sospenda.
	_stacking_mode = _stacking.process_mode
	_stacking.set_readout(String(_ctx.get(Photo.CTX_TARGET, "")), quality)
	_crt.show_control(_stacking)
	set_player_present(_player_present)

	Log.info("night", "stack — foto %d registrata, qualità %d" % [record.get(Photo.KEY_ID), quality])


func _enter_phase(scene: PackedScene) -> void:
	var node := scene.instantiate()
	if node == null:
		push_error("[night] scena del piano non istanziabile: la salto")
		_enter_next.call_deferred()
		return
	var p := node as Phase
	if p == null:
		# Si prosegue, come nel ramo della fase mal configurata più sotto e per
		# la stessa ragione: una fase persa è meglio di una notte bloccata. E si
		# libera il nodo costruito — `instantiate()` lo crea comunque, il cast
		# fallito lo lascia soltanto senza nessuno che lo referenzi.
		push_error("[night] il piano contiene una scena che non è una Phase: la salto")
		node.queue_free()
		_enter_next.call_deferred()
		return

	# setup() PRIMA di entrare nell'albero, come vuole il contratto. `_ctx` è ciò
	# che le fasi precedenti hanno lasciato nel proprio `payload`.
	p.setup(Game.run, _ctx)
	p.finished.connect(_on_phase_finished.bind(p))
	_host.add_child(p)

	# LA GUARDIA CHE IMPEDISCE UNA NOTTE MUTA. Una fase mal configurata non
	# emetterà mai `finished`: la notte resterebbe ferma su di lei fino all'alba,
	# e in release gli `assert` non ci sono a dirlo. Si salta e si prosegue: una
	# fase persa è meglio di una notte bloccata.
	if not _phase_can_run(p):
		push_error("[night] fase %s non configurata: la salto" % p.key())
		# `remove_child()` prima di `queue_free()`, per la stessa ragione scritta
		# in `_dispose()`: `queue_free` è differita a fine frame, e da sola
		# lascerebbe questa fase nell'albero — in `_process` e in ascolto —
		# insieme a quella che `_enter_next` sta per montare al suo posto.
		_host.remove_child(p)
		p.queue_free()
		_enter_next.call_deferred()
		return

	_phase = p
	# I modi si registrano appena la fase esiste, prima che qualcuno la sospenda.
	_phase_mode = p.process_mode
	var scr := p.screen()
	_screen_mode = scr.process_mode if scr != null else Node.PROCESS_MODE_INHERIT

	# screen() DOPO add_child: si risolve nel `_ready()` della fase, e
	# `show_control()` fa un `reparent()`, che vuole il nodo già nell'albero.
	_crt.show_control(scr)
	# La fase nasce ferma se il giocatore non è alla postazione.
	set_player_present(_player_present)
	Events.phase_started.emit(p.key())


## Se una fase è in condizione di girare davvero.
##
## Si interroga per nome e non con un metodo del contratto `Phase`, perché
## aggiungerlo vorrebbe dire farlo implementare dalla fase polare — e quel file
## non deve cambiare di una riga: è la prova dell'AC2 della storia 1.1,
## rieseguibile con `git diff` da quando esiste il repository. Il nome della sua
## cartella non si scrive nemmeno in un commento, per la ragione detta in cima.
func _phase_can_run(p: Phase) -> bool:
	if &"truth" in p and p.get(&"truth") == null:
		return false
	return true


func _on_phase_finished(result: PhaseResult, phase: Phase) -> void:
	# Una fase che non è più quella corrente non ha voce: il suo `finished` in
	# ritardo scriverebbe un punteggio e porterebbe via lo schermo a quella viva.
	if phase != _phase:
		return

	# Si registra ciò che la fase HA DICHIARATO in `result`, non ciò che
	# risponderebbe se la si richiamasse: un `score()` non idempotente
	# scriverebbe nel save un numero diverso da quello che ha emesso.
	# key(), MAI name: Godot rinomina in @PhasePolar@2, e con «rifai setup» della
	# storia 2.6 succede davvero — con quella chiave finirebbe nel salvataggio.
	Game.run.phase_scores[phase.key()] = result.score
	Events.phase_finished.emit(phase.key(), result.score)

	# Ciò che questa fase lascia a quelle dopo di lei. È il canale di FR12.
	_ctx.merge(result.payload, true)

	if not result.ok:
		Log.warn("night", "fase %s conclusa con ok = false" % phase.key())
	# `reason` NON compare qui: è canale 2, lo legge il giocatore sul CRT e non
	# entra mai nel log di dev.
	Log.info("night", "fase %s conclusa — punteggio %d" % [phase.key(), result.score])

	# Mai liberare un nodo dentro la sua stessa callback.
	_advance.call_deferred(phase)


func _advance(phase: Phase) -> void:
	var was_current := _phase == phase
	if was_current:
		_phase = null
	_dispose(phase, was_current)
	_enter_next()


## Toglie una fase di scena e la libera.
##
## `show_control(null)` PRIMA di liberare: dopo `reparent()` il `Control` non è
## più figlio della fase, e resterebbe a schermo appartenendo a qualcosa che non
## esiste più. Il contrappeso sta in `core/phase.gd`, che lo libera su
## `NOTIFICATION_PREDELETE` — mai su `_exit_tree()`, che scatta anche su
## un'uscita temporanea.
##
## `remove_child()` PRIMA di `queue_free()`: `queue_free` è differita a fine
## frame, e da sola lascerebbe la fase nell'albero — ancora in `_process`, ancora
## in ascolto — per tutto il resto del frame.
##
## `clear_screen` DICE SE QUESTA FASE POSSIEDE ANCORA IL VETRO, ed è la guardia
## `was_current` che il ponte della 1.1 aveva e che questo file aveva perso:
## svuotare il viewport per conto di una fase già sostituita porterebbe via lo
## schermo a chi ci è arrivato dopo. Il caso non è teorico — `ENTER` premuto nel
## frame dell'alba accoda un `_advance` che gira quando il riepilogo può essere
## già a schermo, e senza questa guardia lo staccherebbe dal vetro lasciando il
## monitor acceso su niente.
func _dispose(phase: Phase, clear_screen: bool) -> void:
	if not is_instance_valid(phase):
		return
	if clear_screen and _crt != null:
		_crt.show_control(null)
	if phase.get_parent() != null:
		phase.get_parent().remove_child(phase)
	phase.queue_free()


# ---------------------------------------------------------------- l'alba

## L'alba chiude la notte, e non chiede il permesso a nessuno.
##
## Smonta la fase in corso **senza registrarne l'esito**: un allineamento
## interrotto dall'alba non è un allineamento riuscito, e inventargli un punteggio
## sarebbe peggio che non averlo. La 2.6 farà lo stesso con il menu post-foto.
func _on_dawn() -> void:
	if _ended:
		return
	# La notte è chiusa DA SUBITO — `_enter_next()` non deve poter montare
	# un'altra fase nella finestra che si apre qui sotto — ma lo smontaggio no.
	_ended = true
	# AC4 dice «sempre `call_deferred`, mai una chiamata diretta dentro la
	# callback», e l'alba è una transizione come le altre: la sola che entri nel
	# flusso di controllo da un'altra porta. Differirla la mette IN FILA con
	# l'`_advance` di una fase che si stesse concludendo nello stesso frame,
	# invece di scavalcarlo — ed è la fila, non la fortuna, a decidere allora chi
	# lascia sul vetro l'ultima cosa.
	_close_night.call_deferred()


func _close_night() -> void:
	if _phase != null:
		var stale := _phase
		_phase = null
		_dispose(stale, true)

	# La rivelazione, se è a schermo all'alba, la libera chi la possiede — e prima
	# che il riepilogo la sostituisca, altrimenti resterebbe orfana nel viewport.
	# `_show_summary` chiama `show_control(_summary)`, che stacca già i figli del
	# viewport; ma il nodo va comunque liberato, o resterebbe vivo fuori dall'albero.
	if _stacking != null:
		_stacking.queue_free()
		_stacking = null

	_show_summary()
	# L'annuncio al resto del mondo va DOPO che la notte è chiusa davvero: chi
	# ascolta — la cupola dell'epica 3, la telemetria — deve trovare uno stato
	# già fermo, non a metà. Sul bus e non diretto, perché gli ascoltatori sono
	# più di due e non si conoscono ancora (rilievo M1).
	Events.dawn_reached.emit()
	Log.info("night", "alba — notte %d chiusa a %s" % [
		Game.run.night_index, _clock.clock_text()])


func _show_summary() -> void:
	_summary = SUMMARY.new()
	_summary.set_readout(Game.run, _clock.clock_text())
	_crt.show_control(_summary)
