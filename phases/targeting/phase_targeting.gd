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

## La commessa di stanotte in una riga, o "" se non ce n'è una aperta. La compone
## l'orchestratore e la consegna nel `ctx`: qui si mostra e basta.
var _commission_line := ""

## La sigla del soggetto richiesto, per l'evidenza nella striscia indice.
var _commission_target := ""


func key() -> StringName:
	return &"targeting"


## Chiamato dall'orchestratore PRIMA di entrare nell'albero. Si tiene la notte:
## `run.elapsed_min` è la sorgente dell'ora, e `run.selected_target_id` è la casa
## persistente della scelta.
func setup(run: NightRun, ctx: Dictionary) -> void:
	_run = run
	# La commessa arriva già scritta dall'orchestratore: `phases/` non può conoscere
	# `photo/`, dove vivono le chiavi della commessa. Vedi `Phase.CTX_COMMISSION_LINE`.
	_commission_line = String(ctx.get(Phase.CTX_COMMISSION_LINE, ""))
	_commission_target = String(ctx.get(Phase.CTX_COMMISSION_TARGET, ""))


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

	# `_run` NON PUO' DEGRADARE. Assumere `now_min = 0` significherebbe dire «sono
	# le 21:00» a una fase che non sa che ora e': una schermata perfettamente
	# plausibile e interamente sbagliata, con M13 e M57 dichiarati non visibili
	# per una ragione inventata. E' lo stesso motivo per cui `NightClock.begin()`
	# restituisce `false` invece di partire da un'ora qualsiasi.
	if _run == null:
		push_error("[targeting] setup() non chiamato: nessuna notte da cui leggere l'ora")
		assert(false, "phase senza run")
		return

	_input.now_min = _run.elapsed_min

	_catalog = truth.sample(_input)  # UNICA assegnazione di _catalog — ADR-001

	# UN CATALOGO VUOTO E' UNA FINE, NON UN'ATTESA. Restando muta la fase non
	# emetterebbe mai `finished`: ENTER inerte, `_advance()` mai chiamato, e la
	# notte ferma su uno schermo morto fino all'alba — la «notte muta» che
	# `night_session` si da' la pena di prevenire quando una fase e' mal
	# configurata. La sua guardia pero' scatta su `truth == null`, e un catalogo
	# svuotato a fase avviata le passa sotto.
	if _catalog.is_empty():
		_finish_empty()
		return

	_cursor = clampi(_cursor, 0, _catalog.size() - 1)
	_screen.set_readout(_catalog, _cursor, _commission_line, _commission_target)


func _unhandled_input(event: InputEvent) -> void:
	# `truth == null` va guardato anche qui. In release gli assert spariscono:
	# `_process` esce subito, ma senza questa riga ENTER emetterebbe comunque
	# `finished`, e un errore di configurazione diventerebbe un esito diegetico
	# plausibile, registrato nel save come se la fase fosse stata giocata.
	# `is_instance_valid(_screen)` vale qui esattamente per la ragione che
	# `_process` scrive due funzioni piu' su: se l'host libera il Control, i rami
	# su/giu' chiamerebbero `set_readout()` su un'istanza morta. Una guardia che
	# vale in una funzione e non nell'altra e' una guardia dimenticata.
	if _done or truth == null or _catalog.is_empty() or not is_instance_valid(_screen):
		return

	# AZIONI PROPRIE, non le `ui_*`. La polare fa lo stesso con `polar_finish`, e
	# non per gusto: `ui_accept` include ENTER, l'ENTER del tastierino E LA BARRA
	# SPAZIATRICE, mentre il piede dello schermo promette «ENTER CONFIRM». Peggio,
	# `ui_accept` e' il tasto con cui ci si siede alla postazione: ereditarlo
	# significa che l'ENTER premuto per sedersi puo' confermare il primo bersaglio
	# prima che il catalogo sia stato letto.
	if event.is_action_pressed(&"targeting_up"):
		_cursor = (_cursor - 1 + _catalog.size()) % _catalog.size()
		_screen.set_readout(_catalog, _cursor, _commission_line, _commission_target)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"targeting_down"):
		_cursor = (_cursor + 1) % _catalog.size()
		_screen.set_readout(_catalog, _cursor, _commission_line, _commission_target)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"targeting_confirm"):
		_finish()
		get_viewport().set_input_as_handled()


func screen() -> Control:
	return _screen


func score() -> int:
	return NEUTRAL_SCORE


## La chiusura per catalogo vuoto. CANALE 2: il giocatore legge sul vetro perche'
## la fase e' finita subito, invece di restare davanti a uno schermo inerte.
## `ok` e' false — non c'e' stata nessuna scelta — e il punteggio e' zero.
func _finish_empty() -> void:
	_done = true
	push_error("[targeting] catalogo vuoto: la fase si chiude senza scelta")
	finished.emit(PhaseResult.new(false, "No targets in tonight's catalog.", 0, {}))


func _finish() -> void:
	_done = true
	# La sorgente esclude gia' i target senza id (`_validate`), quindi qui il
	# ripiego non dovrebbe mai scattare. Resta perche' `truth` e' sostituibile:
	# una sorgente futura non e' tenuta a validare come questa.
	var target_id: StringName = _catalog[_cursor].get(&"id", &"")
	if target_id.is_empty():
		# NON un `return`: uscire di qui con `_done = true` e senza emettere
		# `finished` lascerebbe la notte ferma esattamente come il catalogo vuoto.
		push_error("[targeting] la sorgente ha restituito un target senza id")
		finished.emit(PhaseResult.new(false, "The catalog entry is unreadable.", 0, {}))
		return

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
