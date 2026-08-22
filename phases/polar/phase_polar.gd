## Fase 3 — allineamento polare col metodo della deriva.
##
## Il primo pezzo di mestiere vero del gioco: una stella nel reticolo, due viti,
## e la pazienza di guardare. È la fase più lunga e meditativa, e stabilisce il
## ritmo di tutte le notti.
##
## IL CICLO, IN UN GESTO SOLO. La stella scivola. Giri le viti e la vedi
## rallentare mentre hai ancora il dito sul tasto. Quando è ferma, hai finito —
## e resta ferma dov'è, che non è per forza il centro del reticolo. Non c'è
## nessun passaggio intermedio da ricordarsi, e non ce n'è bisogno: l'obiettivo
## è visibile a occhio, senza che nessuno lo scriva.
##
## LA SORGENTE DÀ UNA VELOCITÀ, LA FASE LA INTEGRA. È la scelta che rende
## immediato il riscontro, e va dichiarata perché tocca il senso di ADR-001:
## lo stato osservabile che viene da `truth` è la VELOCITÀ di deriva, e la
## posizione della stella è la sua accumulazione nel tempo — una somma pura
## dell'uscita di `truth`, senza un solo altro ingresso. La fase non calcola mai
## niente a partire dalle viti: le passa a `truth` e integra ciò che torna. Una
## sorgente bugiarda resta perciò in grado di far derivare la stella in direzioni
## impossibili senza che questo file cambi, che è l'unica prova che conti.
##
## IL RITAGLIO A SCHERMO NON STA QUI. Oltre il bordo del reticolo non c'è più
## schermo su cui mostrare la stella, ma quello è un fatto di disegno e vive
## nella vista. Se il limite stesse qui, una sorgente bugiarda resterebbe chiusa
## dentro un cerchio tracciato dalla fase — e ADR-001 sarebbe rotto dalla porta
## di servizio, con lo stato osservabile che dipende anche da una costante nostra.
##
## `runs_in_background()` non è sovrascritto: resta `false` ereditato da `Phase`.
## È la fase 10 a dover restare viva quando il giocatore se ne va, non questa.
class_name PhasePolar
extends Phase

## Escursione massima delle viti, in arcominuti.
const SCREW_LIMIT := 4.0

## Sotto questa velocità la stella è ferma a occhio, e vale la pena dirlo.
const STEADY := 0.02

## Soglia sotto la quale la macchina si lamenta, in inglese e senza drammi.
const POOR_ALIGNMENT := 50

@export var truth: PolarTruthSource

## Disallineamento di partenza. Sono dati di scena e non di `Tuning`: descrivono
## questa istanza della fase, non il bilanciamento della notte.
@export var start_azimuth: float = 1.4
@export var start_altitude: float = -0.9

## Arcominuti di vite per secondo di pressione. Le viti si girano, non si
## scattano: tenere premuto è il gesto giusto per una fase che vuole calma.
@export var screw_speed: float = 0.6

@onready var _screen: Control = %PolarScreen

var _truth_input := PolarInput.new()

## LO STATO OSSERVABILE. Una sola assegnazione in tutto il file, in _process().
var _drift := Vector2.ZERO

## Dove sta la stella, in arcominuti dal centro del reticolo. È l'integrale di
## `_drift` e nient'altro: nessun altro termine entra qui dentro — e adesso il
## commento è vero, perché il ritaglio a schermo è passato alla vista.
var _star := Vector2.ZERO

var _elapsed := 0.0

## Storico per il punteggio: x = istante, y = velocità osservata, z = durata del
## frame. La durata serve perché la media pesi i SECONDI e non i fotogrammi.
var _samples: Array[Vector3] = []

var _done := false


func key() -> StringName:
	return &"polar"


func _ready() -> void:
	if truth == null:
		# Canale 1: è un errore di programma, non un esito. Il giocatore non lo
		# vedrà mai.
		push_error("[polar] truth source non iniettata")
		assert(false, "phase senza truth source")
		return
	_truth_input.azimuth = start_azimuth
	_truth_input.altitude = start_altitude


func _process(delta: float) -> void:
	# `_screen` è protetto quanto `truth`: se il nodo unico si perde — rinominato,
	# spostato fuori dalla scena, liberato dall'host che lo ospitava — senza
	# guardia si deriferirebbe un'istanza morta sessanta volte al secondo.
	if _done or truth == null or not is_instance_valid(_screen):
		return

	_turn_screws(delta)

	_drift = truth.sample(_truth_input, delta)  # UNICA assegnazione di _drift — ADR-001

	# L'integrale: la stella si sposta di quanto la deriva dice, e di nient'altro.
	_star += _drift * delta

	_record(delta)
	_screen.set_readout(_star, _drift, _screws(), score(), is_steady())


func _unhandled_input(event: InputEvent) -> void:
	# `truth == null` va guardato anche qui. In release gli assert spariscono:
	# `_process` esce subito, ma senza questa riga ENTER emetterebbe comunque
	# `finished`, e un errore di configurazione diventerebbe un esito diegetico
	# plausibile, registrato nel save come se la fase fosse stata giocata.
	if _done or truth == null:
		return
	if event.is_action_pressed(&"polar_finish"):
		_finish()


func screen() -> Control:
	return _screen


## Ferma a occhio: la stella non si muove più abbastanza da vedersi.
func is_steady() -> bool:
	return _drift.length() < STEADY


## LA METRICA DELLA FASE 3, decisa qui perché si decide scrivendo la fase.
##
## Il punteggio è la velocità di deriva residua media sugli ultimi
## `polar_score_window_sec` secondi: quanto la stella scivola ancora, non quanto
## ci hai messo né quante volte hai corretto — punirli scoraggerebbe il prendersi
## tempo, che è l'unica cosa che questa fase chiede davvero.
##
## La media su una finestra, e non il valore istantaneo, è ciò che impedisce di
## azzerare le viti un attimo prima di chiudere e portarsi via 100: la finestra
## si ricorda ancora com'era. È anche il motivo per cui il punteggio sale piano
## dopo una correzione riuscita, invece di scattare.
func score() -> int:
	var rate := _mean_rate()
	if rate < 0.0:
		return 0
	var worst := Tuning.polar_max_drift_rate
	if worst <= 0.0:
		return 0
	return roundi(100.0 * (1.0 - clampf(rate / worst, 0.0, 1.0)))


func _screws() -> Vector2:
	return Vector2(_truth_input.azimuth, _truth_input.altitude)


func _turn_screws(delta: float) -> void:
	var az := Input.get_axis(&"polar_az_dec", &"polar_az_inc")
	var alt := Input.get_axis(&"polar_alt_dec", &"polar_alt_inc")

	# Si guarda se un tasto è premuto, non se la somma degli assi è zero: tenendo
	# premute due viti opposte `get_axis` restituisce esattamente 0.0, e leggerlo
	# come «fermo» farebbe crescere `seconds_since_correction` mentre il giocatore
	# ha le mani sui comandi.
	var turning := (
		Input.is_action_pressed(&"polar_az_dec")
		or Input.is_action_pressed(&"polar_az_inc")
		or Input.is_action_pressed(&"polar_alt_dec")
		or Input.is_action_pressed(&"polar_alt_inc"))

	if not turning:
		_truth_input.seconds_since_correction += delta
		return

	_truth_input.azimuth = clampf(
		_truth_input.azimuth + az * screw_speed * delta, -SCREW_LIMIT, SCREW_LIMIT)
	_truth_input.altitude = clampf(
		_truth_input.altitude + alt * screw_speed * delta, -SCREW_LIMIT, SCREW_LIMIT)
	_truth_input.seconds_since_correction = 0.0


## Si misura la velocità che `truth` ha restituito, e solo quella. Un punteggio
## che rileggesse le viti per stimare la qualità scavalcherebbe la sorgente dalla
## porta di servizio, e ADR-001 sarebbe rotto lo stesso.
func _record(delta: float) -> void:
	_elapsed += delta
	_samples.append(Vector3(_elapsed, _drift.length(), delta))

	var cutoff := _elapsed - Tuning.polar_score_window_sec
	while not _samples.is_empty() and _samples[0].x < cutoff:
		_samples.remove_at(0)


## -1.0 significa «nessuna osservazione», che è diverso da «deriva zero».
##
## La media pesa ogni campione per la durata del proprio frame, non per il numero
## di frame. Senza il peso lo stesso identico gioco darebbe punteggi diversi a 60
## e a 144 fps, e uno scatto varrebbe punteggio: un frame lungo conterebbe quanto
## uno corto pur coprendo dieci volte il tempo.
func _mean_rate() -> float:
	if _samples.is_empty():
		return -1.0
	var total := 0.0
	var seconds := 0.0
	for s in _samples:
		total += s.y * s.z
		seconds += s.z
	if seconds <= 0.0:
		return -1.0
	return total / seconds


func _finish() -> void:
	_done = true
	var s := score()

	# CANALE 2 — esito diegetico, in inglese, mai da push_error. Un allineamento
	# mediocre non è un fallimento: `ok` resta true e la notte va avanti.
	#
	# «Nessuna misura» non è «misura pessima». Chiudendo prima che `_process`
	# abbia mai girato il punteggio è 0 come per una deriva pessima, ma il motivo
	# è un altro, e darne uno sbagliato significherebbe dichiarare fuori
	# tolleranza una misura che nessuno ha mai preso.
	var reason := ""
	if _mean_rate() < 0.0:
		reason = "no observation recorded"
	elif s < POOR_ALIGNMENT:
		reason = "alignment out of tolerance"
	finished.emit(PhaseResult.new(true, reason, s))
