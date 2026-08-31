## Fase 8 — messa a fuoco.
##
## IL GESTO, IN UNA RIGA: muovi il focheggiatore finché le stelle sono punti.
##
## È la seconda fase del ciclo foto, e la prima in cui il giocatore cerca qualcosa
## invece di eseguirlo. Nessuno gli dice dove sia il fuoco: vede sette stelle e
## quanto sono grosse, e le stringe. Il traguardo è visibile a occhio senza che
## nessuno lo scriva — la stessa proprietà per cui la fase polare funziona.
##
## LA CURVA A V SI DISEGNA DA SOLA, e non è un ornamento: è la cosa che insegna la
## fase. Ogni posizione visitata lascia un punto sul grafico, e dopo tre passate il
## giocatore VEDE la forma — due rami che scendono verso un minimo — e capisce da
## che parte andare. È così che si mette a fuoco davvero, e non c'è un tutorial che
## lo spieghi meglio del grafico stesso.
##
## LO STATO OSSERVABILE È IL DIAMETRO DELLE STELLE, e viene solo da `truth`
## (ADR-001). La fase non sa dove sia il fuoco — non ha nessun campo che lo
## contenga — e non potrebbe dirlo nemmeno volendo: muove il focheggiatore, chiede
## quanto sono grosse le stelle, e disegna. Una sorgente bugiarda può quindi
## impedire alle stelle di stringersi del tutto senza che questo file cambi, che è
## la rottura che il GDD promette per questa fase.
##
## IL NUMERO SULLO SCHERMO NON AIUTA, ed è deliberato. Il display mostra la
## posizione dell'encoder con uno scostamento estratto a caso a ogni montaggio:
## sono passi veri, si muovono col focheggiatore, ma non dicono dove sia il fuoco.
## Senza lo scostamento il giocatore imparerebbe un numero invece di una curva —
## e la fase diventerebbe «porta il display a 0», cioè niente.
##
## `runs_in_background()` resta `false`: mettere a fuoco è un gesto con le mani.
class_name PhaseFocus
extends Phase

## Fin dove arriva il focheggiatore, in passi, dal centro della corsa.
const TRAVEL := 900.0

## Passi al secondo, tenendo premuto.
##
## DUECENTO, e il numero viene da un conto e non dal gusto: la corsa intera è 1800
## passi, cioè nove secondi da un fermo all'altro — abbastanza per una passata di
## ricognizione senza che diventi un viaggio. E la zona dentro cui il punteggio è
## pieno è larga circa 124 passi, cioè sei decimi di secondo di dito: si centra,
## ma bisogna guardare.
const STEP_RATE := 200.0

## Ogni quanti passi si segna un punto sul grafico.
##
## Non a ogni fotogramma: a 60 fps una passata intera lascerebbe seicento punti
## sovrapposti, che è una riga spessa e non una curva. Ogni dodici passi la V si
## legge come una fila di puntini, che è come la disegnano gli autofocus veri.
const SAMPLE_STEP := 12.0

## Quanti punti si tengono. Oltre, i più vecchi cadono: chi ha girovagato per un
## minuto non deve ritrovarsi il grafico impastato.
const MAX_SAMPLES := 240

@export var truth: FocusTruthSource

@onready var _screen: Control = %FocusScreen

var _truth_input := FocusInput.new()

## LO STATO OSSERVABILE. Una sola assegnazione in tutto il file, in `_process()`.
var _hfd := 0.0

## Dov'è il focheggiatore. Non è stato osservabile: è il comando: quanto il
## giocatore ha girato la manopola.
var _position := 0.0

## Lo scostamento del display, estratto a ogni montaggio. Vedi la testa del file.
var _encoder_offset := 0

## I punti visitati: x = posizione, y = diametro osservato.
var _samples: PackedVector2Array = PackedVector2Array()
var _last_sampled := INF

var _done := false


func key() -> StringName:
	return &"focus"


func _ready() -> void:
	if truth == null:
		# Canale 1: errore di programma. L'orchestratore salta la fase invece di
		# lasciare la notte ferma su uno schermo che non risponde.
		push_error("[focus] truth source non iniettata")
		assert(false, "phase senza truth source")
		return

	# SI PARTE SEMPRE FUORI FUOCO, e mai dalla stessa parte. Un focheggiatore che
	# nasce a metà corsa regalerebbe la risposta alla prima notte; uno che nasce
	# sempre a destra la regalerebbe alla seconda.
	var lontananza := randf_range(TRAVEL * 0.35, TRAVEL * 0.85)
	_position = lontananza if randf() < 0.5 else -lontananza
	_encoder_offset = randi_range(2000, 9000)
	_truth_input.position = _position


func _process(delta: float) -> void:
	# `_screen` è protetto quanto `truth`: un nodo unico che si perde si
	# dereferenzierebbe sessanta volte al secondo.
	if _done or truth == null or not is_instance_valid(_screen):
		return

	_move_focuser(delta)

	_hfd = truth.sample(_truth_input, delta)        # UNICA assegnazione — ADR-001

	_record()
	_screen.set_readout(_position, _hfd, encoder(), _samples, score(), _moving())


func _unhandled_input(event: InputEvent) -> void:
	# `truth == null` va guardato anche qui: in release gli `assert` spariscono, e
	# senza questa riga INVIO chiuderebbe la fase con un punteggio calcolato su un
	# diametro che nessuno ha mai misurato.
	if _done or truth == null:
		return
	if event.is_action_pressed(&"focus_done"):
		_finish()


func screen() -> Control:
	return _screen


## LA METRICA DELLA FASE 8: quanto sono piccole le stelle alla fine, e nient'altro.
##
## Non quanto ci hai messo, non quante passate hai fatto, non quanto sei vicino al
## punto giusto in passi — quello sarebbe misurare la posizione, cioè una cosa che
## la fase conosce e il giocatore no. Si misura ciò che si vede.
##
## PIENO PRIMA DEL MINIMO ASSOLUTO. `focus_best_hfd` sta un filo sopra il diametro
## che l'ottica può dare: chiedere il minimo esatto vorrebbe dire chiedere un passo
## esatto su milleottocento, e trasformare una fase di mestiere in una lotteria di
## precisione. Sotto quella soglia si prende 100 e si va avanti.
func score() -> int:
	# NESSUNA MISURA NON È MISURA PERFETTA. Prima del primo `_process` il diametro
	# vale zero — nessuno l'ha ancora chiesto — e zero è meglio del minimo
	# possibile: chi premesse INVIO nel fotogramma in cui la fase compare si
	# porterebbe via 100 senza aver toccato niente. È la stessa clausola che la fase
	# polare scrive al contrario, e per la stessa ragione.
	if _samples.is_empty():
		return 0
	var buono := Tuning.focus_best_hfd
	var pessimo := Tuning.focus_max_hfd
	if pessimo <= buono:
		return 0
	return roundi(100.0 * (1.0 - clampf((_hfd - buono) / (pessimo - buono), 0.0, 1.0)))


## Il diametro osservato adesso. Per il banco e per le sonde.
func hfd() -> float:
	return _hfd


## Quello che c'è scritto sul display del focheggiatore: passi veri, origine
## arbitraria. Vedi la testa del file.
func encoder() -> int:
	return roundi(_position) + _encoder_offset


func _moving() -> bool:
	return (Input.is_action_pressed(&"focus_in")
		or Input.is_action_pressed(&"focus_out"))


## Muove il focheggiatore, e lo ferma ai fermi meccanici.
##
## `get_axis` E NON DUE `if`: tenendo premuti tutti e due i versi il focheggiatore
## sta fermo, che è ciò che fa un motore a cui chiedi due cose opposte. Con due
## `if` in fila vincerebbe l'ultimo che ho scritto, cioè il caso.
func _move_focuser(delta: float) -> void:
	var verso := Input.get_axis(&"focus_in", &"focus_out")
	if is_zero_approx(verso):
		_truth_input.seconds_since_move += delta
		return
	_position = clampf(_position + verso * STEP_RATE * delta, -TRAVEL, TRAVEL)
	_truth_input.position = _position
	_truth_input.seconds_since_move = 0.0


## Segna il punto visitato, se ci si è spostati abbastanza.
##
## SI REGISTRA QUELLO CHE `truth` HA DETTO, non una previsione: il grafico è la
## storia delle misure, e se la sorgente mentisse il grafico mostrerebbe la
## bugia — che è esattamente ciò che deve fare.
func _record() -> void:
	if absf(_position - _last_sampled) < SAMPLE_STEP:
		return
	_last_sampled = _position
	_samples.append(Vector2(_position, _hfd))
	if _samples.size() > MAX_SAMPLES:
		_samples.remove_at(0)


func _finish() -> void:
	_done = true
	var s := score()
	# CANALE 2 — esito diegetico, in inglese, mai da push_error. Un fuoco mediocre
	# non è un fallimento: `ok` resta true e la notte va avanti con stelle un po'
	# gonfie, che è precisamente il prezzo che si è scelto di pagare.
	var reason := ""
	if _samples.is_empty():
		reason = "no focus run recorded"
	elif _hfd > Tuning.focus_max_hfd:
		reason = "stars out of focus"
	finished.emit(PhaseResult.new(true, reason, s))
