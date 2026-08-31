## Fase 1 — apertura della cupola, dal pannello di controllo.
##
## LA PRIMA COSA CHE SI FA IN UNA NOTTE, e la prima che si è potuta fare davvero:
## il livellamento e il bilanciamento sono gesti sulla montatura, e la montatura
## in gioco non si tocca ancora. La cupola invece ha un motore e un pannello, e il
## pannello sta sul PC — cioè esattamente dove il giocatore è già seduto.
##
## COMANDO A UOMO PRESENTE, e non è una scelta di comodo: le cupole vere si aprono
## tenendo premuto, perché un battente da qualche quintale che si muove da solo
## mentre nessuno guarda è un modo di rompere un telescopio. Tenere premuto è
## anche l'idioma già stabilito dalla fase polare — «le viti si girano, non si
## scattano» — e per la stessa ragione: è il gesto di una fase che vuole calma.
##
## COSA VEDE IL GIOCATORE, E DOVE. Sul CRT vede il pannello: la corsa, la
## percentuale, lo spicchio di cielo che si allarga fra i due battenti. In cupola,
## se ci va dopo, vede la fessura aperta sul cielo — che prima non c'era. Le due
## cose non si guardano insieme, ed è giusto così: si comanda da una stanza e si
## verifica in un'altra, come in un osservatorio vero.
##
## NON DÀ PUNTEGGIO, e lo dichiara: `score()` è 100 sempre. È il caso della fase 4
## del GDD, «nessun punteggio: si passa o si ripete» — non c'è niente da fare bene
## o male, c'è solo da farlo. Fingere una metrica qui vorrebbe dire inventarsi una
## bravura che il gesto non contiene.
##
## COME PARLA AL MONDO. La cupola vive in `world/`, che a questa cartella è
## vietato: la fase non la cerca e non la conosce. Annuncia sul bus DOVE STA IL
## BATTENTE (`Events.dome_aperture_changed`), e chi in giro per il mondo ha un
## battente lo mette lì. È lo stesso verso di `sequence_started`: un fatto detto a
## voce alta, non un comando dato a qualcuno.
##
## `runs_in_background()` resta `false`: il motore va finché c'è un dito sul
## comando, e un dito sul comando vuole qualcuno alla postazione.
class_name PhaseDome
extends Phase

## Sopra questa apertura il battente è a fine corsa e la fase si può chiudere.
##
## Non è 1.0 esatto per la ragione di sempre con i float: l'integrale arriva a
## 0,99999 e poi a 1,00001 a seconda del passo, e un confronto secco `>= 1.0`
## renderebbe il traguardo dipendente dal frame rate.
const FULLY_OPEN := 0.999

## Sotto questa variazione non si annuncia niente al mondo.
##
## SERVE PERCHÉ IL SEGNALE NON DIVENTI UN RUMORE: senza, il bus porterebbe sessanta
## volte al secondo lo stesso numero anche a battente fermo, e chiunque ci si
## colleghi domani pagherebbe quel traffico per sempre. Mezzo millesimo di corsa è
## sotto il pixel: un battente che si muove di meno non si sta muovendo.
const REPORT_STEP := 0.0005

@export var truth: DomeTruthSource

@onready var _screen: Control = %DomeScreen

var _truth_input := DomeInput.new()

## LO STATO OSSERVABILE: la velocità che la sorgente ha restituito. Una sola
## assegnazione in tutto il file, in `_process()` — ADR-001.
var _speed := 0.0

## Dove sta il battente: l'integrale di `_speed` e nient'altro. Nessun altro
## termine entra qui dentro, e in particolare non ci entra il tasto: il comando
## passa da `truth`, e una sorgente che decidesse di ignorarlo resterebbe libera
## di farlo senza che questo file cambi.
var _aperture := 0.0

## L'ultimo valore annunciato al mondo, per non ripetersi.
var _reported := -1.0

var _done := false


func key() -> StringName:
	return &"dome"


func _ready() -> void:
	if truth == null:
		# Canale 1: è un errore di programma, non un esito. Il giocatore non lo
		# vedrà mai — e l'orchestratore salta la fase invece di lasciare la notte
		# ferma su un pannello che non risponde.
		push_error("[dome] truth source non iniettata")
		assert(false, "phase senza truth source")
		return

	# SI ANNUNCIA LA POSIZIONE DI PARTENZA, e non è una formalità: la fase e il
	# mondo devono partire d'accordo. Rifacendo il setup (storia 2.6) questa fase
	# ricomincia da capo, con il battente a zero, mentre in cupola è rimasto
	# aperto: senza questa riga il pannello direbbe CLOSED e il cielo si vedrebbe
	# lo stesso. Con questa riga la cupola si richiude, che è ciò che «rifare il
	# setup» vuol dire.
	_report()


func _process(delta: float) -> void:
	# `_screen` è protetto quanto `truth`, per la ragione scritta nella fase
	# polare: un nodo unico che si perde si dereferenzierebbe sessanta volte al
	# secondo.
	if _done or truth == null or not is_instance_valid(_screen):
		return

	_read_command(delta)

	_speed = truth.sample(_truth_input, delta)      # UNICA assegnazione — ADR-001

	# L'integrale, e il morsetto: il battente non va oltre la fine corsa né
	# indietro oltre il fermo. Il morsetto sta QUI e non nella sorgente perché è
	# una proprietà del meccanismo — la guida è lunga così — e una sorgente
	# bugiarda deve poter restituire una velocità assurda senza che il battente
	# esca dai binari.
	_aperture = clampf(_aperture + _speed * delta, 0.0, 1.0)
	_truth_input.aperture = _aperture

	_report()
	_screen.set_readout(_aperture, _speed, _truth_input.motor_on, is_open())


func _unhandled_input(event: InputEvent) -> void:
	# `truth == null` va guardato anche qui: in release gli `assert` spariscono, e
	# senza questa riga INVIO emetterebbe comunque `finished` — un errore di
	# configurazione diventerebbe un esito plausibile, scritto nel save.
	if _done or truth == null:
		return
	if is_open() and event.is_action_pressed(&"dome_confirm"):
		_finish()


func screen() -> Control:
	return _screen


## Nessun punteggio: si passa o si ripete. Vedi la testa del file.
func score() -> int:
	return 100


## Il battente è a fine corsa.
func is_open() -> bool:
	return _aperture >= FULLY_OPEN


## Quanto è aperta la cupola, 0-1. Esiste per il banco e per le sonde: leggere
## `_aperture` da fuori sarebbe leggere un dettaglio interno.
func aperture() -> float:
	return _aperture


func _read_command(delta: float) -> void:
	var pressed := Input.is_action_pressed(&"dome_open")
	# Il cronometro del motore si azzera quando il comando si stacca, e cresce solo
	# mentre gira: è la stessa contabilità di `seconds_since_correction`, al
	# contrario. Nessuna sorgente dell'MVP lo legge (vedi `DomeInput`).
	_truth_input.seconds_running = (_truth_input.seconds_running + delta) if pressed else 0.0
	_truth_input.motor_on = pressed


## Dice al mondo dove sta il battente, se si è mosso abbastanza da valere la pena.
##
## I DUE ESTREMI SI ANNUNCIANO SEMPRE. Con il solo confronto sulla soglia, l'ultimo
## fotogramma di corsa — quello che vale meno di mezzo millesimo — resterebbe non
## detto, e in cupola il battente si fermerebbe a un capello dalla fine per sempre.
## Chiuso e aperto sono le due posizioni che devono essere esatte.
func _report() -> void:
	var estremo := _aperture <= 0.0 or _aperture >= 1.0
	if not estremo and absf(_aperture - _reported) < REPORT_STEP:
		return
	if is_equal_approx(_aperture, _reported):
		return
	_reported = _aperture
	Events.dome_aperture_changed.emit(_aperture)


func _finish() -> void:
	_done = true
	# CANALE 2 — esito diegetico, in inglese. Qui non c'è niente da dichiarare: la
	# cupola è aperta, il che è l'unico esito che questa fase conosce.
	finished.emit(PhaseResult.new(true, "", score()))
