## Fase 10 — la posa: configurare la sequenza e lasciarla lavorare.
##
## È una fase di FOTO autonoma (ADR-002): l'orchestratore la istanzia, si collega
## a `finished`, e non sa cosa faccia dentro. Non conosce nessun'altra fase — il
## target arriva dalla 2.2 come dato nel `ctx` di `setup()`, MAI per import da
## `phases/targeting/`.
##
## IL CUORE DELL'MVP: si imposta la posa, la si avvia, e ci si ALLONTANA mentre la
## macchina lavora da sola. `runs_in_background()` → true: la fase resta viva sotto
## `PhaseHost` quando il giocatore va via, continua a `_process`, e al ritorno il
## CRT mostra lo stato VERO, non ricostruito.
##
## LO STATO OSSERVABILE È IL CONTEGGIO DEI FRAME, e viene SOLO da `truth.sample()`
## con un'unica assegnazione, in `_process` (ADR-001 / FR16). La fase non calcola
## i frame per conto proprio: passa alla sorgente il tempo trascorso e legge ciò
## che torna. Una sorgente bugiarda potrebbe falsare il conteggio senza che questo
## file cambi, che è l'unica prova che conti.
##
## IL TEMPO VIENE DAL CLOCK, non da un accumulatore. `_start_min = run.elapsed_min`
## all'avvio; ogni frame `elapsed = run.elapsed_min - _start_min`. Riusa
## l'accumulatore autorevole di `NightClock` → pausa e `Engine.time_scale` valgono
## gratis, e nessuna formula duplicata (il difetto rinviato dalla 2.1).
##
## IN BACKGROUND NON SI ASSUME DI ESSERE VISIBILI: niente `get_viewport().size`,
## niente accesso alla camera, nessun lavoro pesante per frame. Si fa solo
## aritmetica sul tempo (AC3). Il suono di fine sequenza NON è figlio di questa
## fase: vive nel mondo (`world/`) e ascolta `Events.phase_finished` filtrando su
## `&"imaging"` — è il luogo che possiede il suono, non la fase.
##
## E ASCOLTA UN FATTO SOLO: se la camera è ancora avvitata al fuoco
## (`Events.camera_mounted_changed`). Svitarla porta via il cavo, e senza cavo non
## c'è più niente da cui scaricare i frame: la sequenza muore, e quello che aveva
## acquisito muore con lei. Il collegamento si rifà riavvitandola.
##
## NON SI SPARISCE IN SILENZIO. Chi smonta la camera è in cupola, non alla
## postazione: il guasto resta sul vetro finché non lo si legge da seduti, che è
## anche quello che fa un software vero — una finestra d'errore che aspetta un OK.
## Un pannello tornato al menu da solo direbbe che la posa non c'è più senza dire
## perché.
##
## QUESTA FASE ANNUNCIA DUE FATTI SUL BUS, e non li annunciava: `sequence_started`
## quando il giocatore preme START, `sequence_ended` quando la sequenza si conclude o
## quando la fase viene smontata a sequenza in corso. Il montaggio della fase NON è
## l'inizio della posa, e chi nel mondo si accendeva su `phase_started(&"imaging")`
## si accendeva troppo presto. Vedi `autoloads/events.gd`.
class_name PhaseImaging
extends Phase

## Il punteggio al MINIMO dichiarato dal target. Chi integra esattamente quanto
## richiesto ha una foto onesta, non una eccellente: il resto se lo guadagna
## restando aperto più a lungo.
const SCORE_AT_MINIMUM := 60

## Quante volte il minimo servono per il punteggio pieno. A 2x il target è
## sfruttato quanto serve; oltre, la notte si consuma e la foto non migliora —
## ed è quella la decisione, non un premio a chi aspetta di più.
const FULL_SCORE_RATIO := 2.0

## Indici dei due campi configurabili, nell'ordine di scorrimento su/giù. Stessi
## valori attesi dalla vista.
const FIELD_EXPOSURE := 0
const FIELD_FRAMES := 1
const FIELD_COUNT := 2

## Valori di partenza e passi dei campi. Sono SEGNAPOSTO (FR22): nessuna
## calibrazione qui, solo numeri plausibili da regolare con l'esperimento. Non
## stanno in `Tuning` perché descrivono i limiti dell'interfaccia di questa fase,
## non il bilanciamento della notte.
const EXPOSURE_MIN := 30
const EXPOSURE_MAX := 600
const EXPOSURE_STEP := 30
const EXPOSURE_DEFAULT := 120

const FRAMES_MIN := 1
const FRAMES_MAX := 60
const FRAMES_STEP := 1
const FRAMES_DEFAULT := 20

@export var truth: ImagingTruthSource

@onready var _screen: Control = %ImagingScreen

var _input := ImagingInput.new()

## LO STATO OSSERVABILE. Una sola assegnazione in tutto il file, in _process().
var _state: Dictionary = {}

var _run: NightRun

## Il target che si sta fotografando, arrivato nel `ctx`. Viaggia nel payload verso
## 2.4/2.5.
var _target_id: StringName = &""

## Il minimo di integrazione che il target chiede, in minuti. Arriva dal `ctx`
## (lo mette il targeting, che legge il catalogo): è la sponda contro cui si
## misura la posa, e senza di esso non c'è niente da giudicare.
var _min_exp: int = 0

## I due parametri che il giocatore imposta in configurazione.
var _exposure: int = EXPOSURE_DEFAULT
var _frames_total: int = FRAMES_DEFAULT
var _field: int = FIELD_EXPOSURE

## Config → run: `_started` distingue i due modi, `_start_min` fissa l'istante di
## avvio sul clock della notte.
var _started := false
var _start_min: float = 0.0

var _done := false

## Se la camera è avvitata al fuoco.
##
## NASCE VERA E NON SI CHIEDE A NESSUNO: questa fase non può raggiungere il
## telescopio — `phases/` non conosce `world/` — e tutto quello che sa del ferro le
## arriva da `Events.camera_mounted_changed`. Chi la smonta mentre il modulo è
## aperto lo dice al bus, e da lì in poi il valore è vero.
##
## IL BUCO CHE RESTA, detto invece che sottinteso: una camera smontata PRIMA che
## questo modulo esista — durante il puntamento, per dire — non si sente, perché un
## signal non si riascolta dopo. La posa partirebbe come se la camera ci fosse.
var _camera := true

## La posa è morta perché la camera se n'è andata.
##
## NON È `_done`, che dice soltanto «non c'è più niente da far avanzare». Questo
## dice PERCHÉ, e tiene il guasto sul vetro — e la fase in vita — finché qualcuno
## non lo legge.
var _persa := false


func key() -> StringName:
	return &"imaging"


## Sulla scheda del software di ripresa: «SEQ», la sequenza, come la chiamava MaxIm DL. La chiave intera non entra in
## una scheda.
func tab_label() -> String:
	return "SEQ"


## Sta LAVORANDO solo da START in poi, e solo finché non ha finito. Prima di START
## la fase esiste e mostra il pannello di configurazione: è un momento interattivo, e
## `night/` lo usa per NON aprirci sopra i programmi del PC. Vedi `Phase.is_working()`.
func is_working() -> bool:
	return _started and not _done


func runs_in_background() -> bool:
	return true


## Chiamato dall'orchestratore PRIMA di entrare nell'albero. Si tiene la notte
## (`run.elapsed_min` è la sorgente del tempo) e legge il target dal `ctx`.
func setup(run: NightRun, ctx: Dictionary) -> void:
	_run = run
	# FR12 / ADR-002: il target arriva come DATO nel ctx, mai per import. Se manca —
	# targeting saltato o malconfigurato — la posa parte comunque con id vuoto
	# (segnaposto) e lo si dice una volta: è canale 1, un errore di programma, non
	# un esito che il giocatore legge sul vetro.
	_target_id = ctx.get(&"target_id", &"")
	if _target_id.is_empty():
		push_error("[imaging] setup senza target_id nel ctx: uso un id vuoto (segnaposto)")

	# 2.6 — scatta ancora ripresenta la STESSA configurazione: se il ctx porta già
	# esposizione e conteggio frame (rientro dopo una vendita, senza rifare il
	# targeting), la posa riparte da quei valori invece che dai default. Assenti (primo
	# scatto) → i default restano. Chiavi grezze, nessun import da `photo/`: sono dati
	# in ingresso. `clampi` ai limiti dell'interfaccia, che un ctx malformato non li
	# violi.
	if ctx.has(&"exposure_sec"):
		_exposure = clampi(int(ctx[&"exposure_sec"]), EXPOSURE_MIN, EXPOSURE_MAX)
	if ctx.has(&"frame_count"):
		_frames_total = clampi(int(ctx[&"frame_count"]), FRAMES_MIN, FRAMES_MAX)

	# Il minimo del target: dato in ingresso come il target stesso, mai un import da
	# `phases/targeting/`. Zero o assente significa «nessun minimo dichiarato», e in
	# quel caso la posa non si giudica (vedi `exposure_score`).
	_min_exp = maxi(int(ctx.get(&"min_exp", 0)), 0)


func _ready() -> void:
	if truth == null:
		# Canale 1: è un errore di programma, non un esito. Il giocatore non lo
		# vedrà mai. Come nel targeting: la fase non emetterà `finished`.
		push_error("[imaging] truth source non iniettata")
		assert(false, "phase senza truth source")
		return
	# IL FERRO PARLA DA QUI IN POI. Il collegamento con la camera è l'unica cosa del
	# mondo che questa fase ascolta, e la ascolta dal bus: `phases/` non conosce
	# `world/`, e il nodo della camera non è raggiungibile da qui nemmeno volendo.
	Events.camera_mounted_changed.connect(_su_camera)
	# All'ingresso si mostra il pannello di configurazione: nessun frame ancora.
	if is_instance_valid(_screen):
		_screen.set_readout(_config_readout())


func _process(_delta: float) -> void:
	# SOLO IN RUN. In configurazione non c'è nulla da far avanzare: il pannello si
	# ridisegna dai comandi, non ogni frame. `_screen` è protetto quanto `truth`: se
	# il nodo unico si perde — rinominato, spostato, liberato dall'host — senza
	# guardia si deriferirebbe un'istanza morta ogni frame. E in background la fase
	# NON assume di essere visibile: qui non si tocca camera né viewport, si fa solo
	# aritmetica sul tempo.
	if _done or not _started or truth == null or not is_instance_valid(_screen):
		return

	# `_run` NON PUO' DEGRADARE. Senza la notte non c'è orologio da cui leggere il
	# tempo trascorso, e assumere zero direbbe «la posa è appena partita» per sempre.
	if _run == null:
		push_error("[imaging] setup() non chiamato: nessuna notte da cui leggere il tempo")
		assert(false, "phase senza run")
		return

	# Il tempo dal CLOCK, non da un accumulatore: `run.elapsed_min` è l'orologio
	# della notte, e sottrarre l'istante d'avvio dà i minuti di posa — pausa e
	# time_scale gratis. Il tempo per frame lo calcola `_game_min_per_frame()`
	# dall'esposizione scelta, e la scala viene SEMPRE da `Tuning`, mai con `load()`.
	_input.elapsed_since_start_min = _run.elapsed_min - _start_min
	_input.frames_total = _frames_total
	_input.min_per_frame = _game_min_per_frame()

	_state = truth.sample(_input)  # UNICA assegnazione di _state — ADR-001

	_screen.set_readout(_run_readout())

	if bool(_state.get(&"done", false)):
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	# LA POSA PERSA HA UN COMANDO SOLO: preso atto. Sta PRIMA della guardia su
	# `_done` — che è già vero, perché non c'è più niente da far avanzare — proprio
	# perché la fase è rimasta a schermo apposta, e questo tasto è la sua unica
	# uscita. Lo stesso ENTER che avvia la sequenza: chi è seduto ne conosce già uno.
	if _persa:
		if event.is_action_pressed(&"imaging_start"):
			get_viewport().set_input_as_handled()
			_arrenditi()
		return

	# `truth == null` va guardato anche qui. In release gli assert spariscono:
	# `_process` esce subito, ma senza questa riga ENTER avvierebbe comunque la
	# sequenza, e un errore di configurazione diventerebbe uno stato plausibile.
	# `is_instance_valid(_screen)` vale qui per la stessa ragione: i rami di config
	# chiamano `set_readout()` su un'istanza che l'host potrebbe aver liberato.
	if _done or truth == null or not is_instance_valid(_screen):
		return

	# In RUN l'input è inerte: la sequenza lavora da sola, non si tocca. È anche ciò
	# che rende sicuro allontanarsi — non c'è tasto che la disturbi.
	if _started:
		return

	# AZIONI PROPRIE, non le `ui_*`: `imaging_start` è ENTER esplicito, come
	# `targeting_confirm`, e non la barra spaziatrice o l'ENTER con cui ci si siede.
	if event.is_action_pressed(&"imaging_prev"):
		_field = (_field - 1 + FIELD_COUNT) % FIELD_COUNT
		_screen.set_readout(_config_readout())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"imaging_next"):
		_field = (_field + 1) % FIELD_COUNT
		_screen.set_readout(_config_readout())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"imaging_dec"):
		_adjust(-1)
		_screen.set_readout(_config_readout())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"imaging_inc"):
		_adjust(1)
		_screen.set_readout(_config_readout())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"imaging_start"):
		# SENZA CAMERA NON SI ESPONE. Un avvio concesso adesso conterebbe i frame di
		# una camera che non c'è: il pannello lo rifiuta e dice cosa fare — riavvitarla
		# rifà il collegamento, e START torna a funzionare da sé.
		if not _camera:
			_screen.set_readout(_config_readout())
			get_viewport().set_input_as_handled()
			return
		_start()
		get_viewport().set_input_as_handled()


func screen() -> Control:
	return _screen


func score() -> int:
	return exposure_score(total_min(), _min_exp)


## Quanti minuti di integrazione produce la configurazione corrente.
##
## È la regola scelta da Federico: TEMPO TOTALE = FRAME x ESPOSIZIONE. Prima i due
## campi erano scollegati da tutto — la posa durava `min_per_frame` fissi a frame,
## quindi l'esposizione non cambiava né la durata né il punteggio, e alla domanda
## «perché dovrei cambiarla?» non c'era risposta. Adesso ce n'è una sola e vale per
## entrambi i campi: cambiano quanto integri, e quanto integri è la foto.
func total_min() -> float:
	return float(_frames_total) * float(_exposure) / 60.0


## Quanti minuti di GIOCO dura un frame. La posa dura quanto integra — un frame da
## 120 secondi occupa due minuti di notte — riscalato da `Tuning.pose_time_scale`,
## che è la manopola con cui si tara quanto pesa l'attesa senza toccare la fisica.
func _game_min_per_frame() -> float:
	return maxf(float(_exposure) / 60.0 * Tuning.pose_time_scale, 0.001)


## Dal tempo integrato al punteggio, 0-100. PURA e statica: si collauda al banco
## senza SceneTree, come le sorgenti di verità.
##
## LA CURVA, e perché questa. Sotto il minimo dichiarato dal target la foto è
## rumorosa e il punteggio scende in proporzione, fino a zero: mancare il minimo
## non è un mezzo successo. Al minimo esatto vale `SCORE_AT_MINIMUM` — onesta, non
## eccellente. Da lì sale fino a 100 al doppio del minimo, e lì si ferma: oltre, il
## giocatore sta solo consumando la notte, e premiarlo trasformerebbe la scelta in
## un'ottimizzazione con una sola risposta.
##
## `min_exp <= 0` significa «nessun minimo dichiarato»: non si giudica, e si torna
## il punteggio pieno invece di inventare una bocciatura da un dato mancante.
static func exposure_score(total: float, min_exp: int) -> int:
	if min_exp <= 0:
		return 100
	if total <= 0.0:
		return 0
	var ratio := total / float(min_exp)
	if ratio < 1.0:
		return clampi(roundi(SCORE_AT_MINIMUM * ratio), 0, SCORE_AT_MINIMUM)
	var gain := (100.0 - SCORE_AT_MINIMUM) * (ratio - 1.0) / (FULL_SCORE_RATIO - 1.0)
	return clampi(roundi(SCORE_AT_MINIMUM + gain), SCORE_AT_MINIMUM, 100)


## Cambia il valore del campo attivo di `dir` passi, entro i limiti segnaposto.
func _adjust(dir: int) -> void:
	if _field == FIELD_EXPOSURE:
		_exposure = clampi(_exposure + dir * EXPOSURE_STEP, EXPOSURE_MIN, EXPOSURE_MAX)
	else:
		_frames_total = clampi(_frames_total + dir * FRAMES_STEP, FRAMES_MIN, FRAMES_MAX)


## Passaggio config → run: fissa l'istante d'avvio sul clock della notte. Da qui il
## conteggio è funzione del tempo trascorso, e nient'altro.
func _start() -> void:
	_started = true
	_start_min = _run.elapsed_min if _run != null else 0.0
	# IL FATTO CHE IL MONDO ASPETTAVA. Fino alla review dell'epica 3 il telescopio e la
	# cupola si accendevano su `phase_started(&"imaging")`, che l'orchestratore emette al
	# MONTAGGIO: la montatura ronzava e il tubo ruotava mentre il giocatore stava ancora
	# scegliendo i frame. La sequenza comincia qui, e qui lo si dice.
	Events.sequence_started.emit()


## LA CAMERA SE N'È ANDATA — o è tornata al suo posto.
##
## SVITARLA PORTA VIA IL CAVO, e un cavo che se ne va è un collegamento che si
## rompe: il software non ha più nessuno a cui chiedere i frame. Se la sequenza
## stava lavorando, muore lì; se stava ancora configurando, non parte finché la
## camera non torna avvitata (vedi `_unhandled_input`).
##
## I FRAME SONO PERSI, tutti. Non c'è mezza foto da salvare — quello che c'era
## stava dentro la camera che adesso qualcuno tiene in mano — e la sequenza non
## riprende da dove si era interrotta: si rifà da capo.
##
## `_done` PRIMA DI TUTTO: ferma `_process` e disarma `_exit_tree`, che altrimenti
## emetterebbe un secondo `sequence_ended` quando l'orchestratore libera la fase.
func _su_camera(montata: bool) -> void:
	_camera = montata
	if montata or not is_working():
		return
	_done = true
	_persa = true
	# IL FATTO CHE IL MONDO ASPETTA: il telescopio smette di inseguire, la cupola
	# chiude il suo gate. Una posa morta non è una posa che continua a girare.
	Events.sequence_ended.emit()
	if is_instance_valid(_screen):
		_screen.set_readout(_lost_readout())


## Il guasto è stato letto: la fase si chiude e la notte prosegue.
##
## `ok = false` E PAYLOAD VUOTO, ed è tutto il «le immagini sono andate perse»:
## senza esposizione né conteggio frame nel payload l'orchestratore non conia
## nessuna foto — non c'è niente da impilare, niente da rivelare, niente da vendere.
## Punteggio zero: una posa che non ha consegnato un frame non vale niente.
## `reason` è canale 2 e non entra nel log; quello che il giocatore legge l'ha già
## letto sul vetro.
func _arrenditi() -> void:
	finished.emit(PhaseResult.new(false, "camera scollegata", 0, {}))


## LA POSA SMONTATA A META'. L'alba durante una sequenza, o *rifai setup*, liberano
## questa fase senza che `_finish()` sia mai passato: `phase_finished` non viene emesso
## da nessuno, e prima di questa riga il telescopio restava a inseguire e a ronzare per
## il resto della partita, e la cupola con uno `started` senza il suo `ended`.
##
## `_exit_tree` e non `queue_free`: l'orchestratore fa `remove_child()` prima di
## liberare (lo dice in `_dispose`), quindi questo è il momento in cui la fase esce
## davvero di scena. La guardia `is_working()` rende l'emissione unica: dopo `_finish()`
## `_done` e' vero e qui non si emette due volte.
func _exit_tree() -> void:
	if is_working():
		_done = true
		Events.sequence_ended.emit()


func _config_readout() -> Dictionary:
	return {
		&"running": false,
		&"field": _field,
		&"exposure_sec": _exposure,
		&"frame_count": _frames_total,
		&"target": String(_target_id),
		# LA CONSEGUENZA, non solo i parametri. Il pannello mostrava due numeri e
		# nient'altro: si potevano cambiare senza sapere cosa cambiassero. Questi tre
		# sono la risposta — quanto integri, quanto ne chiede il target, e che foto
		# ne esce — e li calcola la fase, che è la sola a conoscere la regola.
		&"total_min": total_min(),
		&"min_exp": _min_exp,
		&"score": exposure_score(total_min(), _min_exp),
		# Se si può premere START. Il pannello lo dice al posto del footer dei
		# comandi: un tasto che non fa niente e non spiega è peggio di un tasto che
		# manca.
		&"camera": _camera,
	}


## Il pannello del guasto. Riusa `_state` — l'ultimo campione buono — perché il
## conteggio dei frame perduti è quello, e inventarlo qui vorrebbe dire calcolare
## uno stato osservabile fuori da `truth` (ADR-001). `lost` è ciò che la vista
## guarda per prima: vince su `running`.
func _lost_readout() -> Dictionary:
	var out := _state.duplicate()
	out[&"running"] = true
	out[&"lost"] = true
	out[&"target"] = String(_target_id)
	out[&"frames_total"] = _frames_total
	return out


func _run_readout() -> Dictionary:
	# La vista distingue i due modi da `running`, che qui è sempre true. `_state` da
	# `truth` porta frames_done/total/done; il target si aggiunge come contesto.
	var out := _state.duplicate()
	out[&"running"] = true
	out[&"target"] = String(_target_id)
	# Quanto manca, in minuti di notte: i frame che restano per quanto dura ognuno.
	# Si compone qui e non nella vista — la vista non sa cosa sia un minuto di gioco,
	# e la sorgente di verità non deve sapere quanto pesa un frame sull'orologio.
	var left: int = maxi(_frames_total - int(_state.get(&"frames_done", 0)), 0)
	out[&"remaining_min"] = float(left) * _game_min_per_frame()
	return out


## La chiusura. CANALE 2 solo per l'esito: la posa non fallisce mai nell'MVP, `ok`
## resta true — una posa corta non è un fallimento, è una foto peggiore, e la
## differenza la dice il punteggio. Il payload porta target, esposizione e numero
## di frame a 2.4/2.5. `phase_finished` (emesso da `night_session`) resta ciò su cui
## il SUONO del mondo si innesca — una posa interrotta non ha finito niente e non deve
## suonare. Il moto e le attività dell'attesa invece si spengono su `sequence_ended`,
## che arriva anche quando la posa viene smontata a metà.
func _finish() -> void:
	_done = true
	# PRIMA di `finished`: chi ha acceso qualcosa su `sequence_started` lo spegne mentre
	# la fase è ancora quella corrente, non dopo che l'orchestratore ha già montato la
	# rivelazione. Il suono di fine sequenza NON è questo — è `phase_finished`, che
	# l'orchestratore emette solo se la posa ha davvero concluso.
	Events.sequence_ended.emit()
	finished.emit(PhaseResult.new(true, "", score(), {
		&"target_id": _target_id,
		&"exposure_sec": _exposure,
		&"frame_count": _frames_total,
	}))
