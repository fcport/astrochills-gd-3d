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

## L'interfaccia di vendita. `preload` come il riepilogo e la rivelazione: è un
## Control di `night/`, deve esistere in ogni build. NON è una fase — la prova
## meccanica (nessun nome di fase qui) resta verde: `night/` può dipendere da `photo/`
## e da sé stesso.
const SALE := preload("res://night/photo_sale.gd")

## Il menu post-foto. `preload` come il riepilogo, la rivelazione e la vendita: è un
## Control di `night/` e deve esistere in ogni build. NON è una fase — la prova
## meccanica (nessun nome di fase qui) resta verde: `night/` può dipendere da sé
## stesso. È l'anello che chiude il ciclo notturno e lo riapre a un punto diverso del
## piano, senza che questo file nomini mai una fase: i quattro rami muovono gli indici
## del `NightPlan`, non un `preload` né un `match` su `key()`.
const MENU := preload("res://night/post_photo_menu.gd")

## Il roster dei committenti. `load` e non `preload`: è un DATO in `data/`, e il caso
## «roster assente» è previsto (I/O matrix) — un `preload` di un file mancante
## romperebbe la compilazione, `load` restituisce `null` e la notte prosegue a base.
const ROSTER_PATH := "res://data/clients/roster.tres"

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

## L'interfaccia di vendita, quando c'è. Come `_stacking`: un `Control` di `night/`
## mostrato sul CRT, posseduto e liberato dall'orchestratore. Non è una fase.
var _sale: Control

## Il menu post-foto, quando c'è. Come `_sale`: un `Control` di `night/` mostrato sul
## CRT, posseduto e liberato dall'orchestratore. Non è una fase. *chiudi ed esplora* lo
## lascia vivo (present-gated) fino all'alba, perché risedendosi ricompaia (FR4).
var _menu: Control

## Il payout base della foto in vendita, calcolato in `_enter_sale` e usato in
## `_on_sale_confirmed`: il ramo del rifiuto paga esattamente questo, senza
## ricalcolarlo. `_sale_photo_id` è l'indice del record da mettere in `photo_sold`.
var _sale_base := 0
var _sale_photo_id := 0

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

## Il modo che la vendita aveva alla nascita, per la stessa ragione degli altri:
## sospenderla lo sostituisce con `DISABLED`, riprenderla lo rimette.
var _sale_mode := Node.PROCESS_MODE_INHERIT

## Il modo che il menu post-foto aveva alla nascita, per la stessa ragione degli
## altri: sospenderlo lo sostituisce con `DISABLED`, riprenderlo lo rimette.
var _menu_mode := Node.PROCESS_MODE_INHERIT

## Le `key()` delle fasi di SETUP, imparate a runtime. Si popola in `_on_phase_finished`
## quando una fase conclude mentre `_in_setup` è ancora true (Design Notes): sono
## esattamente le chiavi che *rifai setup* azzera (FR18), senza che questo file nomini
## una fase. La `key()`, MAI `name`: Godot rinomina in `@Phase@2`.
var _setup_phase_keys: Dictionary = {}

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
	# Come il riepilogo e la rivelazione: una vendita di una notte prima farebbe
	# mentire `has_phase()` e resterebbe a schermo. La libera chi l'ha creata.
	if _sale != null:
		_sale.queue_free()
		_sale = null
	# Come gli altri Control: un menu post-foto di una notte prima farebbe mentire
	# `has_phase()` e resterebbe a schermo. Lo libera chi l'ha creato.
	if _menu != null:
		_menu.queue_free()
		_menu = null
	# Le chiavi di setup si imparano ogni notte da capo: quelle della notte prima non
	# valgono per un `NightPlan` che potrebbe essere cambiato.
	_setup_phase_keys.clear()

	# LA COMMESSA SI DECIDE ORA, all'inizio della notte, e vive su `NightRun`
	# (spec: «determinata all'inizio della notte»). Il roster è un DATO in `data/`,
	# letto con `load`: se manca — o non ha abilitati — `Commission.choose` torna `{}`
	# e ogni vendita andrà a base ×1.0, senza crash. Un avviso su canale 1, il gioco
	# prosegue (I/O matrix, riga «roster assente»).
	var roster := load(ROSTER_PATH) as ClientRoster
	var clients: Array = roster.clients if roster != null else []
	if roster == null:
		Log.warn("night", "roster committenti assente (%s): nessuna commessa stanotte" % ROSTER_PATH)
	Game.run.commission = Commission.choose(clients, Game.run.night_index)

	_enter_next()


## La fase corrente, o `null`. La usano gli strumenti di debug, che raggiungono
## l'orchestratore passando dal punto d'ingresso.
func current_phase() -> Phase:
	return _phase


## Se c'è qualcosa da fare al monitor adesso.
func has_phase() -> bool:
	return _phase != null or _summary != null or _stacking != null or _sale != null or _menu != null


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

	# La vendita è present-gated come la rivelazione: sospenderla alla postazione
	# vuota ferma il suo `_unhandled_input` (che gira solo mentre `process_mode` è
	# attivo). Vive nel `SubViewport` del CRT, non è figlia di niente che erediti,
	# quindi va sospesa a parte — come il `Control` di una fase.
	if _sale != null and is_instance_valid(_sale):
		_sale.process_mode = _sale_mode if present else Node.PROCESS_MODE_DISABLED

	# Il menu post-foto è present-gated come la vendita: sospenderlo alla postazione
	# vuota ferma il suo `_unhandled_input`. È ciò che fa ricomparire il menu
	# risedendosi dopo *chiudi ed esplora* — sospeso mentre si è via, ripreso al
	# ritorno. Vive nel `SubViewport` del CRT, non è figlio di niente che erediti.
	if _menu != null and is_instance_valid(_menu):
		_menu.process_mode = _menu_mode if present else Node.PROCESS_MODE_DISABLED

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
	# `revealed` → la vendita, DIFFERITO: `revealed` nasce dentro `_process` della
	# rivelazione, e liberare la rivelazione lì dentro sarebbe liberare un nodo dentro
	# la propria callback — lo stesso motivo per cui ogni transizione qui è differita.
	# La qualità e l'indice si legano ora: il record esiste già, e la vendita non deve
	# ri-aggregare niente.
	_stacking.revealed.connect(
		_enter_sale.bind(quality, int(record.get(Photo.KEY_ID))), CONNECT_DEFERRED)
	_crt.show_control(_stacking)
	set_player_present(_player_present)

	Log.info("night", "stack — foto %d registrata, qualità %d" % [record.get(Photo.KEY_ID), quality])


## La rivelazione è completa: si passa alla vendita. Libera la rivelazione (che
## `revealed` ha finito di usare), calcola il payout base dalla curva segnaposto, e
## mette la schermata di vendita sul CRT. Present-gated come tutto il resto: nasce
## ferma se il giocatore non è alla postazione.
##
## `_ended` GUARDIA: l'alba può essere arrivata nella finestra fra `revealed` e questo
## `call_deferred`. Se la notte è chiusa, `_close_night` ha già liberato la rivelazione
## e mostrato il riepilogo — la vendita non deve scavalcarlo.
func _enter_sale(quality: int, photo_id: int) -> void:
	if _ended:
		return
	if _stacking != null:
		_stacking.queue_free()
		_stacking = null

	# LA CURVA È UN DATO, letta SEMPRE da `Tuning.payout_tiers` (mai `load()` diretto):
	# se è vuota `tier_payout` torna 0, come `quality` su vuoto — non si inventa un
	# numero (I/O matrix, riga «curva assente»).
	_sale_base = PhotoPayout.new().tier_payout(quality, Tuning.payout_tiers)
	_sale_photo_id = photo_id

	_sale = SALE.new()
	_sale_mode = _sale.process_mode
	_sale.set_readout(
		String(_ctx.get(Photo.CTX_TARGET, "")), quality, _sale_base, Game.run.commission)
	# Signal DIRETTO: l'ascoltatore è uno solo, questo orchestratore.
	_sale.confirmed.connect(_on_sale_confirmed)
	# `dismissed` → il menu post-foto, DIFFERITO: nasce nell'input della vendita che
	# `_on_sale_dismissed` sta per liberare, e non si libera un nodo dentro la propria
	# callback (NFR16).
	_sale.dismissed.connect(_on_sale_dismissed, CONNECT_DEFERRED)
	_crt.show_control(_sale)
	set_player_present(_player_present)

	Log.info("night", "vendita — foto %d, base %d lire" % [photo_id, _sale_base])


## Il giocatore ha confermato la vendita. QUI vivono le mutazioni di `Game.run` e
## l'emissione su `Events` (spec: la logica pura non tocca lo stato).
##
## `fulfill` true ⟺ commessa applicabile e accettata: le lire sono `base * mult`
## arrotondato. Altrimenti — nessuna commessa, o commessa rifiutata (SELL OPEN) — è il
## base ×1.0. Il rifiuto non ha un ramo che sottrae: paga il base come chi non aveva
## commessa, e non scrive da nessuna parte di aver rifiutato (NFR20).
func _on_sale_confirmed(fulfill: bool) -> void:
	# La COMPOSIZIONE del payout è pura e vive in `PhotoPayout.sale_lire` (unica
	# sorgente di verità, collaudata al banco): qui non c'è un ramo `if fulfill` che la
	# duplichi. `mult` si legge sempre — è irrilevante quando `fulfill` è false.
	var mult := float(Game.run.commission.get(Commission.MULTIPLIER, 1.0))
	var lire := PhotoPayout.new().sale_lire(_sale_base, mult, fulfill)

	# Payout IMMEDIATO e PER-FOTO: accreditato ora, su questa foto, non aggregato di
	# fine notte.
	Game.run.wallet_lire += lire
	# `photo_id` è un `int` (Photo.KEY_ID); il signal lo vuole `StringName`. Si
	# converte all'emissione — l'MVP non ha bisogno di un UUID.
	Events.photo_sold.emit(StringName(str(_sale_photo_id)), lire)

	if _sale != null and is_instance_valid(_sale):
		_sale.show_sold(lire)

	Log.info("night", "venduta — foto %d, %d lire (fulfill %s)" % [_sale_photo_id, lire, fulfill])


# ---------------------------------------------------------------- il menu post-foto

## La vendita è stata congedata: si passa al menu post-foto. Differito perché
## `dismissed` nasce nell'input della vendita che `_enter_menu` sta per liberare, e una
## transizione non si avvia dentro l'input del nodo che la avvia (NFR16).
func _on_sale_dismissed() -> void:
	_enter_menu.call_deferred()


## Mette il menu post-foto sul CRT. Libera la vendita (che `dismissed` ha finito di
## usare) e monta il menu, present-gated come tutto il resto: nasce fermo se il
## giocatore non è alla postazione.
##
## `_ended` GUARDIA: l'alba può essere arrivata nella finestra fra `dismissed` e questo
## `call_deferred`. Se la notte è chiusa, `_close_night` ha già liberato la vendita e
## mostrato il riepilogo — il menu non deve scavalcarlo.
func _enter_menu() -> void:
	if _ended:
		return
	if _sale != null and is_instance_valid(_sale):
		_sale.queue_free()
		_sale = null

	_menu = MENU.new()
	# Il modo si registra appena il Control esiste, prima che il gating lo sospenda.
	_menu_mode = _menu.process_mode
	_crt.show_control(_menu)
	# `chosen` → il rientro nel piano, DIFFERITO: nasce dentro l'input del menu, e i
	# rami che liberano il menu non devono farlo dentro la sua stessa callback (NFR16).
	_menu.chosen.connect(_on_menu_chosen, CONNECT_DEFERRED)
	set_player_present(_player_present)

	Log.info("night", "menu post-foto aperto")


## Il giocatore ha scelto quanto rifare. Ogni ramo è un RIENTRO nel piano a un punto
## diverso, e il rientro NON nomina nessuna fase (ADR-002): muove `_in_setup` e gli
## indici del `NightPlan`, mai un `preload` né un `match` su `key()`.
##
## L'INVARIANTE DEL PIANO che questi indici codificano: la prima fase foto seleziona
## il target, le successive lo catturano. Indice foto 1 = si salta la selezione del
## target (stesso target); indice foto 0 = si rifà anche la selezione (cambia target).
##
## `_ended` GUARDIA: una scelta differita in arrivo dopo l'alba trova la notte chiusa
## e si ignora — `_close_night` ha già liberato il menu e mostrato il riepilogo.
func _on_menu_chosen(option: int) -> void:
	if _ended:
		return
	match option:
		MENU.OPTION_SHOOT_AGAIN:
			# Stesso target, stessa configurazione: `_ctx` resta intatto, e la fase che
			# cattura lo ripresenta come valori di partenza. Si salta la selezione del
			# target (indice foto 1).
			_free_menu()
			_in_setup = false
			_photo_index = 1
			_enter_next()
		MENU.OPTION_CHANGE_TARGET:
			# Si riparte dalla prima fase foto (indice foto 0), quella che seleziona il
			# target. I punteggi di setup restano ereditati in `phase_scores`.
			_free_menu()
			_in_setup = false
			_photo_index = 0
			_enter_next()
		MENU.OPTION_REDO_SETUP:
			# Si azzerano SOLO i punteggi delle fasi di setup (per `key()` imparata a
			# runtime, FR18): le fasi foto non si toccano, le riscrive la riesecuzione.
			# `_ctx` si svuota — il target e la configurazione vanno rifatti da capo.
			for k: StringName in _setup_phase_keys:
				Game.run.phase_scores.erase(k)
			_free_menu()
			_ctx.clear()
			_in_setup = true
			_setup_index = 0
			_photo_index = 0
			_enter_next()
		MENU.OPTION_CLOSE:
			# NON si libera il menu (FR4): lo si lascia vivo e present-gated, così
			# risedendosi ricompare e si può scattare ancora senza rifare nulla.
			# `arm()` lo ripulisce perché alla riapertura sia di nuovo interattivo.
			# `plan_exhausted` avverte il punto d'ingresso di far rialzare il giocatore.
			_menu.arm()
			plan_exhausted.emit()


## Toglie il menu di scena e lo libera. `show_control(null)` PRIMA di liberare, come
## per la vendita e la rivelazione: dopo `reparent()` il Control non è più figlio di
## niente, e resterebbe a schermo appartenendo a qualcosa che non esiste più.
func _free_menu() -> void:
	if _menu == null:
		return
	if _crt != null:
		_crt.show_control(null)
	_menu.queue_free()
	_menu = null


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

	# SI IMPARANO QUI LE CHIAVI DI SETUP, senza nominare una fase (Design Notes).
	# `_in_setup` è ancora true SOLO mentre lo scan del piano è nelle fasi di setup:
	# le fasi di setup concludono con `_in_setup == true`, le foto con false.
	# Registrare la `key()` sotto questa guardia dà l'insieme delle chiavi di setup —
	# per `key()`, MAI `name` (FR18) — ed è esattamente ciò che *rifai setup* cancella.
	if _in_setup:
		_setup_phase_keys[phase.key()] = true

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

	# La vendita, se è a schermo all'alba, la libera chi la possiede — prima che il
	# riepilogo la sostituisca, altrimenti resterebbe orfana nel viewport. Stesso
	# motivo della rivelazione qui sopra.
	if _sale != null:
		_sale.queue_free()
		_sale = null

	# Il menu post-foto, se è a schermo all'alba (aperto, o lasciato vivo da *chiudi
	# ed esplora*), la libera chi lo possiede — prima che il riepilogo lo sostituisca.
	# Stesso motivo della vendita qui sopra. Una scelta differita in arrivo trova
	# `_ended` true in `_on_menu_chosen` e si ignora.
	if _menu != null:
		_menu.queue_free()
		_menu = null

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
