## Fase 3 — raffreddamento della camera CCD.
##
## IL GESTO, IN UNA RIGA: scegli quanto freddo chiedere, e aspetti.
##
## IL MESTIERE NON È ASPETTARE, È SCEGLIERE. Un chip caldo fa rumore, e il rumore
## si dimezza ogni sei gradi in meno: quindi più freddo è meglio, e la tentazione è
## chiedere il minimo assoluto. Ma un Peltier scende di tanto sotto l'ambiente e
## non di più, e quello che gli chiedi oltre non lo ottiene: resta al massimo, non
## ci arriva, e la temperatura ONDEGGIA. Una temperatura che ondeggia non è un
## dettaglio estetico — i dark si scattano alla stessa temperatura delle pose, e
## una serie di dark presa mentre il sensore balla non corrisponde più a niente.
##
## COME SI CAPISCE DOV'È IL LIMITE: guardando la percentuale, non la temperatura.
## Il pannello mostra quanto sta lavorando la cella, ed è l'unica lettura che dice
## se quello che hai chiesto si può TENERE. Nessuno scrive da nessuna parte che
## sopra il novanta per cento non si regge: si vede, perché lì la temperatura
## comincia a ballare. È la stessa diagnosi della fase 2, con un numero al posto di
## una porta muta.
##
## LO STATO OSSERVABILE È LA TEMPERATURA, e viene solo da `truth` (ADR-001): la
## sorgente restituisce una VELOCITÀ e la fase la integra, come la deriva polare e
## come il battente della cupola. La seconda lettura — quanto lavora la cella — è
## anch'essa della sorgente: la fase non la calcola, la chiede.
##
## IL PUNTEGGIO SI MISURA SU QUANTO SEI SCESO DALLA PARTENZA, non su una
## temperatura assoluta. La fase non sa quanto faccia freddo in cupola — non ha
## nessun campo che lo contenga — e non deve saperlo: registra la temperatura del
## primo fotogramma, che è quella dell'ambiente perché la cella è ancora spenta, e
## conta i gradi da lì. Il giorno in cui la notte avrà un meteo, questa fase non
## cambierà di una riga.
##
## `runs_in_background()` è `true`, ed è la fase che se lo merita più di tutte:
## imposti il setpoint, e mentre il sensore scende puoi andare a fare il caffè. È
## quello che fa chiunque abbia mai raffreddato una camera.
class_name PhaseCooling
extends Phase

## Di quanto si muove il setpoint a ogni pressione, in gradi.
const STEP := 1.0

## Fin dove si può chiedere. Cinque gradi sopra lo zero e sessanta sotto: il primo
## perché un setpoint sopra l'ambiente non vuol dire niente, il secondo perché è
## sotto qualunque cosa una cella a due stadi possa fare, e la fase deve lasciarti
## sbagliare per farti vedere che cosa succede.
const SETPOINT_MAX := 5.0
const SETPOINT_MIN := -60.0

## Su quanti secondi si guarda l'escursione della temperatura.
##
## DIECI SECONDI, e la ragione è la stessa degli otto della fase polare: una misura
## di stabilità presa su un istante non è una misura di stabilità. Il numero però
## non è a gusto — viene dal periodo della deriva, che è di ventisei secondi: su una
## finestra corta, chi confermasse mentre la temperatura passa dal massimo la
## troverebbe ferma e si porterebbe via il punteggio pieno di una camera che sta
## ballando. Con dieci secondi non c'è nessun istante del ciclo in cui sembri
## stabile.
const WINDOW := 10.0

## Ogni quanti secondi si segna un punto della storia. Sessanta al secondo
## sarebbero una riga spessa; sei al secondo sono una curva.
const SAMPLE_STEP := 0.16

## Quanti punti di storia si tengono: la finestra del grafico, quaranta secondi.
const MAX_SAMPLES := 250

@export var truth: CoolingTruthSource

@onready var _screen: Control = %CoolingScreen

var _truth_input := CoolingInput.new()

## LO STATO OSSERVABILE. Una sola assegnazione in tutto il file, in `_process()`.
var _temperature := 0.0

## La seconda lettura, anch'essa da `truth`: quanto lavora la cella.
var _duty := 0.0

## La temperatura di partenza, cioè quella della cupola: è il riferimento del
## punteggio, e la ragione per cui questa fase non ha bisogno di sapere che tempo
## faccia. Chiesta a `truth` una volta sola, in `_ready`.
var _start := INF

## La storia recente: x = secondi, y = temperatura. Serve al grafico e alla misura
## di stabilità.
var _samples: PackedVector2Array = PackedVector2Array()
var _last_sampled := -INF

var _done := false


func key() -> StringName:
	return &"cooling"


func _ready() -> void:
	if truth == null:
		# Canale 1: errore di programma. L'orchestratore salta la fase invece di
		# lasciare la notte ferma su un pannello che non risponde.
		push_error("[cooling] truth source non iniettata")
		assert(false, "phase senza truth source")
		return
	# SI PARTE CON LA CELLA SPENTA, e il setpoint a zero non è «zero gradi»: è il
	# valore neutro da cui il giocatore deve comunque muoversi. Chi non tocca niente
	# ottiene una camera tiepida, che è esattamente quello che merita.
	_truth_input.setpoint = 0.0
	# E SI PARTE DALLA TEMPERATURA DELLA CUPOLA, che la sorgente conosce e la fase
	# no. Senza questa riga il sensore nasceva a zero gradi: il punteggio contava i
	# gradi scesi da uno zero inventato, e chiedendo meno ventotto ne mancavano tre
	# per il pieno — un difetto che dal codice non si vedeva e dal referto sì.
	_temperature = truth.ambient_temperature()
	_truth_input.temperature = _temperature
	_start = _temperature


func _process(delta: float) -> void:
	# `_screen` è protetto quanto `truth`: un nodo unico che si perde si
	# dereferenzierebbe sessanta volte al secondo.
	if _done or truth == null or not is_instance_valid(_screen):
		return

	_truth_input.seconds_running += delta

	var velocita := truth.sample(_truth_input, delta)
	_temperature += velocita * delta                  # UNICA assegnazione — ADR-001
	_truth_input.temperature = _temperature
	_duty = truth.duty(_truth_input)

	_registra()
	_screen.set_readout(_temperature, _truth_input.setpoint, _duty,
		escursione(), score(), _samples, _truth_input.seconds_running)


func _unhandled_input(event: InputEvent) -> void:
	# `truth == null` va guardato anche qui: in release gli `assert` spariscono, e
	# senza questa riga INVIO chiuderebbe la fase con un punteggio calcolato su una
	# temperatura che nessuno ha mai misurato.
	if _done or truth == null:
		return
	# UN GRADO A PRESSIONE e non `get_axis` ogni fotogramma: il setpoint è una
	# DECISIONE, non una manovra, e le decisioni si prendono una alla volta. Le
	# frecce ripetono da sole se le tieni premute, che è quanto basta per fare
	# trenta gradi senza contarli.
	if event.is_action_pressed(&"cooling_colder"):
		_cambia(-STEP)
	elif event.is_action_pressed(&"cooling_warmer"):
		_cambia(STEP)
	elif event.is_action_pressed(&"cooling_done"):
		_finish()


func screen() -> Control:
	return _screen


## Il sensore scende mentre il giocatore gira per l'osservatorio: vedi la testa.
func runs_in_background() -> bool:
	return true


## LA METRICA DELLA FASE 3: quanto sei sceso, e quanto sta fermo.
##
## DUE FATTORI CHE SI MOLTIPLICANO, e non si sommano: una temperatura bassissima
## che balla non vale «un po' meno» di una buona — non vale niente, perché i dark
## non corrisponderanno. Il prodotto è l'unica forma che dice questo.
##
## NIENTE MISURA, NIENTE PUNTEGGIO: prima del primo `_process` non si è osservato
## nulla, e chi premesse INVIO nel fotogramma in cui la fase compare si porterebbe
## via un voto su una camera che non ha mai raffreddato.
func score() -> int:
	if _start == INF or _samples.is_empty():
		return 0
	var sceso := _start - _temperature
	var buono := Tuning.cooling_full_drop
	var scarso := Tuning.cooling_zero_drop
	if buono <= scarso:
		return 0
	var freddo := clampf((sceso - scarso) / (buono - scarso), 0.0, 1.0)
	return roundi(100.0 * freddo * (1.0 - _instabilita()))


## Quanto ha ballato la temperatura nella finestra: la differenza fra il massimo e
## il minimo, in gradi. Per il pannello, per il banco e per le sonde.
func escursione() -> float:
	var da := _truth_input.seconds_running - WINDOW
	var alto := -INF
	var basso := INF
	for s in _samples:
		if s.x < da:
			continue
		alto = maxf(alto, s.y)
		basso = minf(basso, s.y)
	if alto == -INF:
		return 0.0
	return alto - basso


## La temperatura di adesso. Per il banco e per le sonde.
func temperature() -> float:
	return _temperature


## Quanto lavora la cella, 0-1. Per il banco e per le sonde.
func duty() -> float:
	return _duty


## Quanto pesa l'instabilità, da 0 a 1.
##
## LA SOGLIA NON È ZERO. Un decimo di grado di escursione ce l'ha qualunque
## regolatore vivo, e punirlo vorrebbe dire chiedere al giocatore una perfezione
## che l'apparecchio non può dare. Sopra i sette decimi invece il punteggio è
## sparito del tutto: è l'ordine di grandezza dell'ondeggio di una cella satura, e
## chi ci arriva ha chiesto troppo.
func _instabilita() -> float:
	return clampf((escursione() - 0.15) / 0.55, 0.0, 1.0)


func _cambia(di: float) -> void:
	_truth_input.setpoint = clampf(_truth_input.setpoint + di, SETPOINT_MIN, SETPOINT_MAX)


func _registra() -> void:
	var ora := _truth_input.seconds_running
	if ora - _last_sampled < SAMPLE_STEP:
		return
	_last_sampled = ora
	_samples.append(Vector2(ora, _temperature))
	if _samples.size() > MAX_SAMPLES:
		_samples.remove_at(0)


func _finish() -> void:
	_done = true
	var s := score()
	# CANALE 2 — esito diegetico, in inglese, mai da push_error. Una camera tiepida
	# non è un fallimento: `ok` resta true e la notte va avanti con più rumore, che
	# è il prezzo che si è scelto di pagare.
	var reason := ""
	if _samples.is_empty():
		reason = "cooler never ran"
	elif escursione() > 0.7:
		reason = "sensor temperature unstable"
	elif _start - _temperature < Tuning.cooling_zero_drop:
		reason = "sensor still warm"
	finished.emit(PhaseResult.new(true, reason, s))
