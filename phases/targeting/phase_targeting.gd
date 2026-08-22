## Fase 6 — scegliere cosa fotografare stanotte.
##
## È una fase di FOTO autonoma (ADR-002): l'orchestratore la istanzia, si collega
## a `finished`, e non sa cosa faccia dentro. Non conosce nessun'altra fase, e
## nessun'altra fase la conosce — il target scelto raggiunge l'imaging (2.3) come
## dato nel `payload`, mai per import.
##
## LO STATO OSSERVABILE È IL CATALOGO, e viene SOLO da `truth.sample()` con
## un'unica assegnazione, in `_process` (ADR-001 / FR16). La fase non legge mai i
## `.tres` dei target: li legge la sorgente. L'elenco e la disponibilità di ogni
## target a `now_min` sono ciò che la sorgente restituisce, e nient'altro — una
## sorgente bugiarda potrebbe nascondere o falsare la disponibilità senza che
## questo file cambi, che è l'unica prova che conti.
##
## L'ORA VIENE DA `run.elapsed_min`: minuti dall'inizio della notte (le 21:00).
## Si passa alla sorgente come `now_min`, che confronta le finestre in minuti
## notte-relativi per evitare il wrap di mezzanotte.
##
## `runs_in_background()` non è sovrascritto: resta `false`. Il targeting è una
## scelta che il giocatore fa alla postazione, non un lavoro che continua se se ne
## va — quella è la fase 10.
class_name PhaseTargeting
extends Phase

## Punteggio neutro: il targeting è una scelta, non una prova d'abilità. Nessuna
## metrica di qualità nell'MVP. `night_session` registra comunque
## `phase_scores[&"targeting"]`.
const NEUTRAL_SCORE := 100

@export var truth: TargetingTruthSource

@onready var _screen: Control = %TargetingScreen

var _input := TargetingInput.new()

## LO STATO OSSERVABILE. Una sola assegnazione in tutto il file, in _process().
var _catalog: Array[Dictionary] = []

## Indice del target in dettaglio nel carosello.
var _cursor := 0

var _run: NightRun
var _done := false


func key() -> StringName:
	return &"targeting"


## Chiamato dall'orchestratore PRIMA di entrare nell'albero. Si tiene la notte:
## `run.elapsed_min` è la sorgente dell'ora, e `run.selected_target_id` è la casa
## persistente della scelta.
func setup(run: NightRun, _ctx: Dictionary) -> void:
	_run = run


func _ready() -> void:
	if truth == null:
		# Canale 1: è un errore di programma, non un esito. Il giocatore non lo
		# vedrà mai. Come nella polare: la fase non emetterà `finished`.
		push_error("[targeting] truth source non iniettata")
		assert(false, "phase senza truth source")
		return


func _process(_delta: float) -> void:
	# `_screen` è protetto quanto `truth`: se il nodo unico si perde — rinominato,
	# spostato fuori dalla scena, liberato dall'host che lo ospitava — senza
	# guardia si deriferirebbe un'istanza morta ogni frame.
	if _done or truth == null or not is_instance_valid(_screen):
		return

	_input.now_min = _run.elapsed_min if _run != null else 0.0

	_catalog = truth.sample(_input)  # UNICA assegnazione di _catalog — ADR-001

	if _catalog.is_empty():
		return
	_cursor = clampi(_cursor, 0, _catalog.size() - 1)
	_screen.set_readout(_catalog, _cursor)


func _unhandled_input(event: InputEvent) -> void:
	# `truth == null` va guardato anche qui. In release gli assert spariscono:
	# `_process` esce subito, ma senza questa riga ENTER emetterebbe comunque
	# `finished`, e un errore di configurazione diventerebbe un esito diegetico
	# plausibile, registrato nel save come se la fase fosse stata giocata.
	if _done or truth == null or _catalog.is_empty():
		return

	# Scorrimento del carosello, con wrap agli estremi.
	if event.is_action_pressed(&"ui_up"):
		_cursor = (_cursor - 1 + _catalog.size()) % _catalog.size()
		_screen.set_readout(_catalog, _cursor)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_down"):
		_cursor = (_cursor + 1) % _catalog.size()
		_screen.set_readout(_catalog, _cursor)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_accept"):
		_finish()
		get_viewport().set_input_as_handled()


func screen() -> Control:
	return _screen


func score() -> int:
	return NEUTRAL_SCORE


func _finish() -> void:
	_done = true
	var target_id: StringName = _catalog[_cursor].get(&"id", &"")

	# La scelta sopravvive a save/riapertura senza che `night_session` conosca la
	# chiave del payload: la casa persistente è un campo già in `NightRun`.
	if _run != null:
		_run.selected_target_id = target_id

	# FR12 / ADR-002: l'id viaggia nel payload verso l'imaging. Nessuna fase
	# successiva importa da `phases/targeting/`.
	var payload := {&"target_id": target_id}
	# CANALE 2 — nessun esito da segnalare: la scelta non fallisce mai. `ok` resta
	# true e la notte va avanti.
	finished.emit(PhaseResult.new(true, "", NEUTRAL_SCORE, payload))
