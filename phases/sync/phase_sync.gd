## Fase 5 — sincronizzazione del puntamento.
##
## IL GESTO, IN UNA RIGA: il software manda la montatura su una stella nota, la
## stella non è dove dovrebbe, tu la centri e premi SYNC.
##
## PERCHÉ ESISTE, ED È LA COSA MENO OVVIA DI TUTTA LA NOTTE. Una montatura che si
## accende non sa dove sta guardando: gli encoder partono da un valore qualunque,
## e chiederle di andare su M13 la porta un paio di gradi in là. Non è un guasto e
## non è una simulazione di difficoltà — è come funzionavano (e funzionano) le
## montature, e chi ci lavorava lo dava per scontato come mettere in moto l'auto.
## Sincronizzare vuol dire dirle «quello che stai inquadrando adesso è la tale
## stella»: da quel momento gli encoder sono agganciati al cielo.
##
## LA FASE PIÙ CORTA CHE INSEGNA DI PIÙ. Dopo averla fatta una volta, il GOTO
## smette di essere magia — si capisce che il telescopio non «sa» dove sono le
## cose, sa solo contare passi da un punto che gli hai indicato tu.
##
## LO STATO OSSERVABILE È DOVE APPARE LA STELLA, e viene solo da `truth`
## (ADR-001). La fase non sa di quanto siano sfasati gli encoder — non ha nessun
## campo che lo contenga — e non potrebbe dirlo nemmeno volendo: muove il tubo,
## chiede dove si vede la stella, e disegna.
##
## IL PUNTEGGIO È L'ERRORE RESIDUO, e non si vede subito: si vede DOPO, come
## l'oggetto scentrato che arriva dal GOTO. È la promessa del GDD, e regge perché
## `NightRun.pointing_error_deg` sopravvive a questa fase.
##
## COME PARLA AL MONDO. La montatura vive in `world/`, che a questa cartella è
## vietato: la fase non la cerca e non la conosce. Dice sul bus dove ha mandato il
## tubo (`telescope_aim_changed`) e ascolta se il ferro è ancora in viaggio
## (`telescope_slewing_changed`). Stesso giro della cupola, e per la stessa ragione.
class_name PhaseSync
extends Phase

## Quanto in fretta si sposta il tubo con le frecce, in gradi al secondo.
##
## MEZZO GRADO, che è lento e deve esserlo: le pulsantiere delle montature hanno
## una velocità di centraggio apposta, distinta da quella di spostamento, perché
## centrare a velocità di GOTO è impossibile. Con un campo da cinque gradi su
## duecentoquaranta pixel, mezzo grado al secondo sono ventiquattro pixel al
## secondo — si arriva al centro in tre o quattro secondi e ci si ferma dove si
## vuole.
const VELOCITA := 0.5

## Quanto è largo il campo del cercatore, in gradi. Cinque gradi è il campo di un
## cercatore vero, ed è largo abbastanza da contenere lo sfasamento peggiore.
const CAMPO := 5.0

## Sotto questo errore il punteggio è pieno, sopra l'altro è zero. In gradi.
##
## OTTO PRIMI D'ARCO PER IL PIENO, e non zero: centrare a occhio in un reticolo
## illuminato arriva a qualche primo, e chiedere l'esattezza trasformerebbe una
## fase di mestiere in una lotteria di precisione. È la stessa clausola con cui il
## fuoco dà cento prima del minimo assoluto.
const ERRORE_BUONO := 0.13
const ERRORE_PESSIMO := 0.80

## Sotto questo spostamento non si riannuncia il puntamento al mondo. Un grado
## ogni cento è mezzo pixel sul cercatore: sotto, il tubo non si sta muovendo.
const PASSO_ANNUNCIO := 0.01

@export var truth: SyncTruthSource

@onready var _screen: Control = %SyncScreen

var _truth_input := SyncInput.new()

## LO STATO OSSERVABILE. Una sola assegnazione in tutto il file, in `_process()`.
var _scarto := Vector2.ZERO

## Quello che segnano gli encoder: il comando, non un'osservazione.
var _encoder := Vector2.ZERO

## Il tubo sta ancora viaggiando verso la stella.
var _in_viaggio := false

## L'ultimo puntamento annunciato al mondo, per non riempire il bus.
var _annunciato := Vector2(INF, INF)

var _run: NightRun
var _done := false


func key() -> StringName:
	return &"sync"


## Sulla scheda del software di ripresa: «SOLVE», il plate solving. La chiave intera non entra in
## una scheda.
func tab_label() -> String:
	return "SOLVE"


func setup(run: NightRun, _ctx: Dictionary) -> void:
	_run = run


func _ready() -> void:
	if truth == null:
		# Canale 1: errore di programma. L'orchestratore salta la fase invece di
		# lasciare la notte ferma su uno schermo che non risponde.
		push_error("[sync] truth source non iniettata")
		assert(false, "phase senza truth source")
		return
	Events.telescope_slewing_changed.connect(_su_moto)
	# IL SOFTWARE MANDA GLI ENCODER SULLA STELLA, e il ferro va dove va. È tutta
	# la fase in due righe: il comando è esatto, il risultato no.
	_encoder = truth.catalog_position()
	_truth_input.encoder_deg = _encoder
	_annuncia()


func _exit_tree() -> void:
	# UN TUBO CHE VIAGGIA NON DEVE SOPRAVVIVERE ALLA FASE. Smontando a metà slew
	# — l'alba, o «rifai setup» — il mondo resterebbe convinto che qualcuno stia
	# ancora aspettando l'arrivo.
	if _in_viaggio:
		Events.telescope_slewing_changed.emit(false)


func _process(delta: float) -> void:
	if _done or truth == null or not is_instance_valid(_screen):
		return

	_muovi(delta)

	_scarto = truth.sample(_truth_input, delta)     # UNICA assegnazione — ADR-001

	_annuncia()
	_screen.set_readout(truth.star_label(), _scarto, CAMPO, score(),
		_in_viaggio, _centrata())


func _unhandled_input(event: InputEvent) -> void:
	# `truth == null` va guardato anche qui: in release gli `assert` spariscono, e
	# senza questa riga INVIO chiuderebbe la fase con un errore mai misurato.
	if _done or truth == null:
		return
	if event.is_action_pressed(&"aim_sync"):
		# NON SI SINCRONIZZA SU UNA STELLA CHE NON SI STA ANCORA GUARDANDO. A
		# metà slew il campo mostra quello che il software CREDE, e un SYNC lì
		# aggancerebbe gli encoder al niente.
		if _in_viaggio:
			return
		_finish()


func screen() -> Control:
	return _screen


## LA METRICA DELLA FASE 5: di quanto è rimasta scentrata la stella, e nient'altro.
func score() -> int:
	var e := _scarto.length()
	if e <= ERRORE_BUONO:
		return 100
	if e >= ERRORE_PESSIMO:
		return 0
	return roundi(100.0 * (1.0 - (e - ERRORE_BUONO) / (ERRORE_PESSIMO - ERRORE_BUONO)))


## L'errore residuo adesso, in gradi. Per il banco e per le sonde.
func errore() -> float:
	return _scarto.length()


## La stella è dentro il cerchietto del reticolo: è il traguardo che si vede.
func _centrata() -> bool:
	return _scarto.length() <= ERRORE_BUONO


## Muove il tubo con le frecce.
##
## `get_axis` E NON QUATTRO `if`, per la ragione del focheggiatore: tenendo
## premute due direzioni opposte il tubo sta fermo, che è quello che fa un motore
## a cui chiedi due cose contrarie.
##
## LA STELLA VA DALLA PARTE OPPOSTA AL TUBO, e non si corregge il segno per
## «renderlo intuitivo»: è quello che succede guardando in un oculare, ed è la
## prima cosa che si impara a un telescopio.
func _muovi(delta: float) -> void:
	var dx := Input.get_axis(&"aim_left", &"aim_right")
	var dy := Input.get_axis(&"aim_down", &"aim_up")
	if is_zero_approx(dx) and is_zero_approx(dy):
		_truth_input.seconds_still += delta
		return
	_encoder += Vector2(dx, dy) * VELOCITA * delta
	_truth_input.encoder_deg = _encoder
	_truth_input.seconds_still = 0.0


## Dice al mondo dove è stato mandato il tubo, se si è spostato abbastanza.
func _annuncia() -> void:
	var dove := truth.aim(_encoder)
	if _annunciato.distance_to(dove) < PASSO_ANNUNCIO:
		return
	_annunciato = dove
	Events.telescope_aim_changed.emit(dove.x, dove.y)


func _su_moto(muove: bool) -> void:
	_in_viaggio = muove


func _finish() -> void:
	_done = true
	var s := score()
	# IL MODELLO DI PUNTAMENTO DI STANOTTE, scritto dove sopravvive alla fase: è
	# ciò che rende vera la promessa del GDD, che l'errore di questa fase si veda
	# DOPO. Il GOTO lo legge da lì, e non da un payload che «rifai setup» svuota.
	if _run != null:
		_run.sync_done = true
		_run.sync_point_deg = truth.catalog_position()
		_run.pointing_error_deg = _scarto
	# CANALE 2 — esito diegetico, in inglese. Una sincronizzazione mediocre non è
	# un fallimento: `ok` resta true e la notte va avanti con i GOTO che arrivano
	# storti, che è precisamente il prezzo che si è scelto di pagare.
	var reason := ""
	if _scarto.length() > ERRORE_PESSIMO:
		reason = "pointing model is rough: expect targets off-centre"
	finished.emit(PhaseResult.new(true, reason, s))
