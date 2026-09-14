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

## Gradi di cielo per minuto di notte: quindici l'ora, il giro della Terra. Sta già scritto
## in `TempoSiderale`, `HonestCatalog` e `HonestPointing`; questa cartella non può nominare
## `world/`, e questa è la quarta copia dello stesso quarto di grado (vedi `TempoSiderale`).
const CIELO_GRADI_AL_MINUTO := 0.25

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

## I minuti della notte quando la fase ha mandato il tubo sulla stella. Da lì il cielo gira,
## e la montatura con lui: vedi `_annuncia()`.
var _minuti_zero := 0.0


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
	_minuti_zero = _minuti()
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


## Muove il tubo con W A S D.
##
## `get_axis` E NON QUATTRO `if`, per la ragione del focheggiatore: tenendo
## premute due direzioni opposte il tubo sta fermo, che è quello che fa un motore
## a cui chiedi due cose contrarie.
##
## LA STELLA VA DALLA PARTE OPPOSTA AL TUBO, e non si corregge il segno per
## «renderlo intuitivo»: è quello che succede guardando in un oculare, ed è la
## prima cosa che si impara a un telescopio.
func _muovi(delta: float) -> void:
	# SI ASCOLTA SOLO A FINESTRA DAVANTI. `Input.get_axis` legge la tastiera, non il
	# fuoco: senza questa riga W A S D muoverebbero il tubo anche con la BBS in primo
	# piano, che scorre con gli stessi tasti. Se la fase ascolta lo decide
	# l'orchestratore accendendole `_unhandled_input` (`NightSession.set_player_present`),
	# e qui si legge quella decisione invece di rifarla.
	if not is_processing_unhandled_input():
		_truth_input.seconds_still += delta
		return
	var dx := Input.get_axis(&"aim_left", &"aim_right")
	var dy := Input.get_axis(&"aim_down", &"aim_up")
	if is_zero_approx(dx) and is_zero_approx(dy):
		_truth_input.seconds_still += delta
		return
	_encoder += Vector2(dx, dy) * VELOCITA * delta
	_truth_input.encoder_deg = _encoder
	_truth_input.seconds_still = 0.0


## Dice al mondo dove è stato mandato il tubo, se si è spostato abbastanza.
##
## CON IL CIELO CHE È GIRATO NEL FRATTEMPO (D-246). La stella di taratura ha l'angolo orario
## di quando la fase è partita, e il cercatore resta giusto così: stella e tubo girano
## insieme, e lo scarto che si vede non cambia. La montatura nel mondo invece insegue il
## cielo, e un angolo orario fermo per lei è un comando di tornare indietro. Federico:
## «il primo movimento che faccio mi dice slewing e poi non lo dice più». Misurato con
## `tools/prova_solve.gd`: dopo otto secondi fermi il tubo aveva inseguito 1,2 gradi, il
## primo tasto lo rimandava indietro di quasi tre, oltre il mezzo grado che accende la
## scritta — e il tubo perdeva la stella. I tasti dopo stavano sotto la soglia perché
## ognuno rimetteva il conto a zero. La GOTO non l'ha mai avuto: a ogni fotogramma
## ricalcola il soggetto all'ora della notte.
func _annuncia() -> void:
	var dove := truth.aim(_encoder) + Vector2(_cielo_girato(), 0.0)
	if _annunciato.distance_to(dove) < PASSO_ANNUNCIO:
		return
	_annunciato = dove
	Events.telescope_aim_changed.emit(dove.x, dove.y)


## Di quanto è girato il cielo da quando la fase è partita, in gradi di angolo orario.
func _cielo_girato() -> float:
	return (_minuti() - _minuti_zero) * CIELO_GRADI_AL_MINUTO


func _minuti() -> float:
	return _run.elapsed_min if _run != null else 0.0


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
		# All'angolo orario di ADESSO, come lo scrive la GOTO risincronizzandosi: il punto
		# tarato è dove la stella sta quando si preme SYNC, non dove stava all'inizio.
		_run.sync_point_deg = truth.catalog_position() + Vector2(_cielo_girato(), 0.0)
		_run.pointing_error_deg = _scarto
	# CANALE 2 — esito diegetico, in inglese. Una sincronizzazione mediocre non è
	# un fallimento: `ok` resta true e la notte va avanti con i GOTO che arrivano
	# storti, che è precisamente il prezzo che si è scelto di pagare.
	var reason := ""
	if _scarto.length() > ERRORE_PESSIMO:
		reason = "pointing model is rough: expect targets off-centre"
	finished.emit(PhaseResult.new(true, reason, s))
