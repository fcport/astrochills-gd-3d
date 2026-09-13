## Fase 2 — accensione e collegamento della strumentazione.
##
## IL GESTO, IN UNA RIGA: dai corrente agli apparecchi, e falli riconoscere al
## software. Quando rispondono tutti e tre, la notte può cominciare.
##
## NON È UNA SEQUENZA DA IMPARARE A MEMORIA, ed è la differenza fra questa fase e
## la stessa fase scritta male. Non c'è un ordine scritto da nessuna parte e non
## c'è niente da ricordare: c'è un bus che risponde o non risponde, e uno schermo
## che dice quale porta è muta. Chi legge quello che c'è scritto arriva in fondo la
## prima notte. È diagnosi — il mestiere vero di chi accende un osservatorio — e
## non la recita di una filastrocca.
##
## L'ORDINE CONTA LO STESSO, ma come CONSEGUENZA e non come regola. Aprire la
## porta a un apparecchio spento la lascia in mano a un driver che ci ha già
## parlato e non ci riprova: accendere l'interruttore dopo non serve, ci vuole il
## RESET. È quello che fa un bus seriale vero, ed è l'unica ragione per cui questa
## fase può essere sbagliata.
##
## LA RUOTA PORTAFILTRI NON HA UN INTERRUTTORE: prende corrente dalla camera. Lo
## schermo non lo scrive da nessuna parte — dice solo che la sua porta è muta — e
## il giocatore lo deduce. È il solo pezzo di mestiere di questa fase, ed è per
## questo che c'è.
##
## LO STATO OSSERVABILE È CHI RISPONDE, e viene solo da `truth` (ADR-001): una
## maschera di bit, una sola assegnazione in `_process()`. La fase non deduce mai
## «è acceso, quindi risponde» — quella deduzione è del bus, e il giorno in cui il
## bus mentirà lo schermo mostrerà la bugia senza che questo file cambi.
##
## NON DÀ PUNTEGGIO: `score()` è 100 sempre, com'è scritto nel GDD per questa fase
## — «si passa o si ripete». Non c'è un modo di collegare BENE una camera.
##
## `runs_in_background()` resta `false`: sono interruttori, e gli interruttori
## vogliono una mano.
class_name PhaseStartup
extends Phase

## Gli apparecchi, nell'ordine in cui stanno sullo schermo.
##
## TRE E NON SETTE. Ogni riga in più è un giro di manopola in più a notte per
## sempre, e questa fase costa quindici minuti di notte sulla carta: tre righe con
## una dipendenza fra due di esse contengono già tutto quello che la fase sa
## insegnare. La quarta sarebbe solo tassa.
const NAMES: Array[String] = ["MOUNT", "CAMERA", "FILTER"]

## Su che porta sta ciascuno. È scenografia, e insieme l'unico indirizzo che il
## giocatore ha per capire di quale muto sta parlando lo schermo.
const PORTS: Array[String] = ["COM1", "LPT1", "CFW"]

## Chi ha un interruttore proprio.
##
## È IL GEMELLO DI `fed_by` NELLA SORGENTE, e la ripetizione è voluta: qui serve a
## non offrire un comando che l'apparecchio non ha, lì a decidere chi risponde.
## Sono due domande diverse — che cosa posso premere, e che cosa succede — e
## tenerle insieme vorrebbe dire lasciare alla fase la decisione sull'osservabile.
const HAS_SWITCH: Array[bool] = [true, true, false]

## Quanto ci mette il software ad aprire una porta.
##
## UN SECONDO E DUE DECIMI, e non è un ritardo messo lì per far sembrare la fase
## più lunga: è il tempo che rende LEGGIBILE il nesso fra quello che hai premuto e
## quello che è successo. Senza, la riga cambia stato nello stesso fotogramma del
## tasto, e l'esito sembra una proprietà del tasto.
const LINK_SECONDS := 1.2

## Quanto ci mette a rilasciare una porta appesa.
const RESET_SECONDS := 0.8

## Quante righe di registro restano sullo schermo.
##
## QUATTRO, che è quanto ci vuole per contenere la storia di uno sbaglio intero:
## la porta aperta a vuoto, l'interruttore acceso dopo, il rilascio, il secondo
## tentativo. Chi torna al monitor dopo essersi distratto ritrova lì che cosa
## stava facendo — che è l'unico servizio che un registro deve rendere.
const LOG_LINES := 4

@export var truth: StartupTruthSource

@onready var _screen: Control = %StartupScreen

var _truth_input := StartupInput.new()

## LO STATO OSSERVABILE: la maschera di chi risponde. Una sola assegnazione in
## tutto il file, in `_process()` — ADR-001.
var _answering := 0

## Dove sta il cursore.
var _cursor := 0

## Quale riga sta lavorando, e quanto le manca. -1 quando non lavora nessuno.
var _busy := -1
var _busy_left := 0.0
var _busy_reset := false

var _done := false

## Che cosa ha detto il software, dalla più vecchia alla più nuova.
var _log: Array[String] = []

## La riga che ha appena finito di lavorare, in attesa di sapere com'è andata.
## Il verdetto arriva da `truth`, e `truth` parla solo dopo, in `_process`.
var _appena := -1
var _appena_reset := false


func key() -> StringName:
	return &"startup"


## Sulla scheda del software di ripresa: «BOOT», l'avvio del PC. La chiave intera non entra in
## una scheda.
func tab_label() -> String:
	return "BOOT"


func _ready() -> void:
	if truth == null:
		# Canale 1: errore di programma. L'orchestratore salta la fase invece di
		# lasciare la notte ferma su uno schermo che non risponde.
		push_error("[startup] truth source non iniettata")
		assert(false, "phase senza truth source")
		return
	_truth_input.powered_when.resize(NAMES.size())
	# CHI SONO GLI APPARECCHI LO DICE LA FASE, una volta sola: la vista non li
	# conosce, e scriverli anche là vorrebbe dire che un giorno lo schermo dirà un
	# nome e il messaggio d'errore un altro.
	if is_instance_valid(_screen):
		_screen.set_devices(NAMES, PORTS, HAS_SWITCH)


func _process(delta: float) -> void:
	# `_screen` è protetto quanto `truth`: un nodo unico che si perde si
	# dereferenzierebbe sessanta volte al secondo.
	if _done or truth == null or not is_instance_valid(_screen):
		return

	_truth_input.seconds_running += delta
	_avanza_il_lavoro(delta)

	_answering = truth.sample(_truth_input, delta)     # UNICA assegnazione — ADR-001

	_registra()
	_screen.set_readout(_truth_input.powered, _truth_input.attempted, _answering,
		_cursor, _busy, _messaggio(), _log)


func _unhandled_input(event: InputEvent) -> void:
	# `truth == null` va guardato anche qui: in release gli `assert` spariscono, e
	# senza questa riga INVIO chiuderebbe la fase su una notte in cui non è
	# collegato niente.
	if _done or truth == null:
		return
	if event.is_action_pressed(&"startup_up"):
		_cursor = wrapi(_cursor - 1, 0, NAMES.size())
	elif event.is_action_pressed(&"startup_down"):
		_cursor = wrapi(_cursor + 1, 0, NAMES.size())
	elif event.is_action_pressed(&"startup_reset"):
		_resetta()
	elif event.is_action_pressed(&"startup_act"):
		# TUTTO COLLEGATO: lo stesso tasto va avanti. Un tasto in più solo per
		# uscire sarebbe un tasto che si usa una volta a notte e si dimentica in
		# tutte le altre.
		if is_ready():
			_finish()
		else:
			_agisci()


func screen() -> Control:
	return _screen


## Nessun punteggio: si passa o si ripete. Vedi la testa del file.
func score() -> int:
	return 100


## Rispondono tutti. Per il banco e per le sonde.
func is_ready() -> bool:
	return _answering == (1 << NAMES.size()) - 1


## Chi risponde adesso. Per il banco e per le sonde.
func answering() -> int:
	return _answering


## L'azione che la riga sotto il cursore sa fare in questo momento.
##
## UNA SOLA AZIONE PER RIGA, e contestuale: accendi ciò che è spento, collega ciò
## che è acceso, resetta ciò che è appeso. Tre tasti distinti vorrebbero dire che
## il giocatore deve sapere in che stato è la riga PRIMA di premere — e quello
## stato è esattamente la cosa che sta cercando di capire.
func _agisci() -> void:
	if _busy >= 0:
		return
	var i := _cursor
	var bit := 1 << i
	if HAS_SWITCH[i] and _truth_input.powered & bit == 0:
		# L'interruttore è un interruttore: scatta e basta, senza attese.
		_truth_input.powered |= bit
		_scrivi("POWER ON: %s" % NAMES[i])
		return
	if _truth_input.attempted & bit != 0:
		return                       # o risponde, o è appesa: tocca al RESET
	_busy = i
	_busy_left = LINK_SECONDS
	_busy_reset = false


## Rilascia la porta della riga sotto il cursore, e dimentica com'era il mondo
## quando ci si è provato: è ciò che permette un secondo tentativo onesto.
func _resetta() -> void:
	if _busy >= 0:
		return
	var i := _cursor
	if _truth_input.attempted & (1 << i) == 0:
		return
	_busy = i
	_busy_left = RESET_SECONDS
	_busy_reset = true


func _avanza_il_lavoro(delta: float) -> void:
	if _busy < 0:
		return
	_busy_left -= delta
	if _busy_left > 0.0:
		return
	var bit := 1 << _busy
	_appena = _busy
	_appena_reset = _busy_reset
	if _busy_reset:
		_truth_input.attempted &= ~bit
		_truth_input.powered_when[_busy] = 0
	else:
		# SI FOTOGRAFA L'ALIMENTAZIONE DI ADESSO, e questa riga è tutta la fase:
		# quello che il driver trova sulla porta nell'istante in cui la apre è
		# quello con cui poi dovrà convivere.
		_truth_input.attempted |= bit
		_truth_input.powered_when[_busy] = _truth_input.powered
	_busy = -1


## Il verdetto sull'ultima porta toccata, scritto nel registro.
##
## SI SCRIVE DOPO AVER SENTITO `truth`, e non nel momento in cui il driver
## finisce: chi ha risposto lo sa il bus, e questa fase lo scopre come lo scopre
## il giocatore — guardando la maschera che le è tornata indietro. Scriverlo prima
## vorrebbe dire che il registro racconta le intenzioni invece dei fatti, e il
## giorno in cui il bus mentirà il registro coprirebbe la bugia.
func _registra() -> void:
	if _appena < 0:
		return
	var i := _appena
	_appena = -1
	if _appena_reset:
		_scrivi("PORT %s RELEASED" % PORTS[i])
		return
	if _answering & (1 << i) != 0:
		_scrivi("%s LINKED ON %s" % [NAMES[i], PORTS[i]])
	else:
		_scrivi("NO RESPONSE ON %s" % PORTS[i])


func _scrivi(riga: String) -> void:
	_log.append(riga)
	while _log.size() > LOG_LINES:
		_log.remove_at(0)


## Che cosa lo schermo ha da dire, in inglese perché è la lingua delle macchine.
##
## DICE SOLO CHE COSA STA FACENDO ADESSO: che cosa non risponde è già scritto nel
## registro e nella colonna LINK, e dirlo una terza volta vorrebbe dire riempire
## lo schermo di se stesso. Quello che nessuna di queste righe dirà mai è il
## PERCHÉ: «no response on CFW» è quello che stamperebbe il software vero, e
## «accendi prima la camera» trasformerebbe una deduzione in una lettura.
func _messaggio() -> String:
	if _busy >= 0:
		var che := "RESETTING" if _busy_reset else "CONNECTING TO"
		return "%s %s ON %s..." % [che, NAMES[_busy], PORTS[_busy]]
	if is_ready():
		return "ALL DEVICES READY - ENTER TO CONTINUE"
	return ""


func _finish() -> void:
	_done = true
	# CANALE 2 — esito diegetico, in inglese, mai da push_error. Qui non c'è niente
	# da dichiarare: rispondono tutti, che è l'unico modo in cui si esce.
	finished.emit(PhaseResult.new(true, "", score()))
