## Il GOTO — portare il telescopio sul soggetto scelto.
##
## IL GESTO, IN UNA RIGA: dici al software dove vuoi andare, la montatura ci va,
## e l'oggetto arriva quasi al centro. Il «quasi» è tutta la fase.
##
## PERCHÉ NON È UN'ANIMAZIONE. Sarebbe stato facile far comparire l'oggetto al
## centro dell'inquadratura e chiamarlo GOTO. Ma un GOTO vero atterra dove il
## modello di puntamento della montatura lo porta, e quel modello è imperfetto per
## due ragioni che il giocatore ha già incontrato: quanto male ha centrato la
## stella nella fase 5, e il fatto che l'asse polare sia storto di otto decimi di
## grado. Il secondo è il più istruttivo — l'errore RICRESCE man mano che ci si
## allontana dalla stella su cui si è sincronizzato, ed è il motivo per cui negli
## osservatori si sincronizza di nuovo prima di ogni soggetto.
##
## L'INQUADRATURA DELLA CCD È PICCOLA, e vederlo è metà di quello che questa fase
## insegna. Il campo del cercatore è cinque gradi; il chip della ST-8 dietro
## millecinquecento millimetri di focale ne inquadra mezzo scarso. Un GOTO
## sbagliato di un grado — che sembra poco — mette l'oggetto due inquadrature
## fuori. È esattamente la ragione per cui si centra nel cercatore e non nella
## camera.
##
## LO STATO OSSERVABILE È DOVE SI VEDE L'OGGETTO, e viene solo da `truth`
## (ADR-001). La fase non conosce il modello di puntamento: lo passa alla sorgente
## nell'input e riceve indietro una posizione nel campo.
##
## E RISINCRONIZZA ALLA CONFERMA, che è ciò che si fa davvero: una volta portato
## l'oggetto al centro, quel puntamento è la miglior taratura disponibile in
## quella zona di cielo. Il soggetto dopo partirà da lì.
##
## NON DÀ PUNTEGGIO — «si passa o si ripete», come la fase della cupola. Il prezzo
## di una sincronizzazione fatta male non è un voto: è il tempo che si passa a
## rincorrere l'oggetto dentro il cercatore, a ogni foto della notte.
class_name PhaseGoto
extends Phase

## Quanto in fretta si sposta il tubo con le frecce, in gradi al secondo. Lo
## stesso della fase 5: è la stessa pulsantiera.
const VELOCITA := 0.5

## Quanto è largo il campo del cercatore, in gradi.
const CAMPO := 5.0

## L'INQUADRATURA DELLA CAMERA, in gradi. NON è un numero scelto: la ST-8 ha un
## chip da 1530x1020 pixel di 9 micron, cioè 13,8 x 9,2 mm, e dietro i 1500 mm di
## focale del Newton da 30 cm f/5 sono 0,53 x 0,35 gradi. Tutte e due le cifre
## stanno nel GDD, e se un giorno cambierà il telescopio cambieranno insieme.
const INQUADRATURA := Vector2(0.526, 0.351)

## Sotto questo spostamento non si riannuncia il puntamento al mondo.
const PASSO_ANNUNCIO := 0.01

@export var truth: GotoTruthSource

@onready var _screen: Control = %GotoScreen

var _truth_input := GotoInput.new()

## LO STATO OSSERVABILE. Una sola assegnazione in tutto il file, in `_process()`.
var _scarto := Vector2.ZERO

## Di quanto il giocatore ha spostato il tubo a mano rispetto al puntamento
## comandato. NON è il comando: il comando insegue il soggetto, che si muove.
var _correzione := Vector2.ZERO

var _in_viaggio := false
var _annunciato := Vector2(INF, INF)

var _run: NightRun
var _done := false
var _irraggiungibile := false


func key() -> StringName:
	return &"goto"


func setup(run: NightRun, _ctx: Dictionary) -> void:
	_run = run


func _ready() -> void:
	if truth == null:
		push_error("[goto] truth source non iniettata")
		assert(false, "phase senza truth source")
		return
	if _run == null:
		push_error("[goto] la fase non ha ricevuto la notte")
		assert(false, "phase senza run")
		return
	Events.telescope_slewing_changed.connect(_su_moto)
	# IL MODELLO DI PUNTAMENTO ARRIVA DALLA NOTTE, non dal payload: «rifai setup»
	# svuota il payload e rifà la fase 5, e le due cose devono restare d'accordo.
	_truth_input.target_id = _run.selected_target_id
	_truth_input.sync_done = _run.sync_done
	_truth_input.sync_point_deg = _run.sync_point_deg
	_truth_input.sync_error_deg = _run.pointing_error_deg
	_aggiorna_ingresso(0.0)
	_annuncia()


func _exit_tree() -> void:
	if _in_viaggio:
		Events.telescope_slewing_changed.emit(false)


func _process(delta: float) -> void:
	if _done or truth == null or not is_instance_valid(_screen):
		return

	_muovi(delta)
	_aggiorna_ingresso(delta)

	_scarto = truth.sample(_truth_input, delta)     # UNICA assegnazione — ADR-001

	# UN SOGGETTO SOTTO LA GRONDA NON SI PUNTA, e il software di un osservatorio
	# vero si rifiuta di provarci. Non dovrebbe succedere — il planetario non lo
	# offre nemmeno — ma è l'ultima rete prima di puntare il tubo contro un muro.
	var alt := truth.target_altitude(_truth_input)
	_irraggiungibile = not is_nan(alt) and alt < SkyGeometry.ORIZZONTE_CUPOLA
	if not _irraggiungibile:
		_annuncia()

	_screen.set_readout(String(_truth_input.target_id).to_upper(), _scarto, CAMPO,
		INQUADRATURA, alt, _in_viaggio, _inquadrato(), _irraggiungibile)


func _unhandled_input(event: InputEvent) -> void:
	if _done or truth == null:
		return
	if not event.is_action_pressed(&"aim_sync"):
		return
	if _irraggiungibile:
		_finish(false, "target is below the dome horizon: pick another one")
		return
	# NON SI CONFERMA UN'INQUADRATURA CHE NON CONTIENE IL SOGGETTO, e non è una
	# severità di design: fotografare un oggetto fuori dal chip produce un'immagine
	# di cielo vuoto, e la fase dopo metterebbe a fuoco su niente.
	if _in_viaggio or not _inquadrato():
		return
	_finish(true, "")


func screen() -> Control:
	return _screen


## Nessun punteggio: si passa o si ripete. Vedi la testa del file.
func score() -> int:
	return 100


## Lo scarto residuo adesso, in gradi. Per il banco e per le sonde.
func errore() -> float:
	return _scarto.length()


## Il soggetto è dentro l'inquadratura della camera.
##
## RETTANGOLO E NON CERCHIO: il chip è rettangolare, e in declinazione ci sta un
## terzo di grado contro il mezzo dell'altro senso. Un cerchio direbbe una bugia
## comoda proprio nell'unico punto in cui il giocatore deve essere preciso.
func _inquadrato() -> bool:
	return (absf(_scarto.x) <= INQUADRATURA.x * 0.5
		and absf(_scarto.y) <= INQUADRATURA.y * 0.5)


func _muovi(delta: float) -> void:
	var dx := Input.get_axis(&"aim_left", &"aim_right")
	var dy := Input.get_axis(&"aim_down", &"aim_up")
	if is_zero_approx(dx) and is_zero_approx(dy):
		return
	_correzione += Vector2(dx, dy) * VELOCITA * delta


## GLI ENCODER INSEGUONO IL SOGGETTO, e non stanno fermi dove sono arrivati: la
## montatura insegue il moto del cielo, e senza questa riga l'oggetto scapperebbe
## dall'inquadratura mentre lo si centra. La correzione a mano si somma sopra.
func _aggiorna_ingresso(_delta: float) -> void:
	_truth_input.now_min = _run.elapsed_min
	var p := truth.target_position(_truth_input)
	if is_nan(p.x):
		return
	_truth_input.encoder_deg = p + _correzione


func _annuncia() -> void:
	var dove := truth.aim(_truth_input)
	if _annunciato.distance_to(dove) < PASSO_ANNUNCIO:
		return
	_annunciato = dove
	Events.telescope_aim_changed.emit(dove.x, dove.y)


func _su_moto(muove: bool) -> void:
	_in_viaggio = muove


func _finish(ok: bool, reason: String) -> void:
	_done = true
	# SI RISINCRONIZZA SUL SOGGETTO, e vedi la testa del file: dopo aver portato
	# l'oggetto al centro, QUESTO è il punto meglio tarato del cielo. Il soggetto
	# dopo partirà da qui, e sarà tanto più preciso quanto più è vicino.
	if ok and _run != null:
		_run.sync_done = true
		_run.sync_point_deg = truth.target_position(_truth_input)
		_run.pointing_error_deg = _scarto
	finished.emit(PhaseResult.new(ok, reason, score()))
