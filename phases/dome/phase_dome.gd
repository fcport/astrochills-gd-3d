## Fase 1 — apertura della cupola, dal pannello di controllo.
##
## LA PRIMA COSA CHE SI FA IN UNA NOTTE, e non si fa al computer (D-171). Nel '99
## una cupola comandata dal PC della sala controllo esisteva — Digital Dome Works —
## ma era roba da osservatorio ricco: a Monte San Lorenzo il portello si apre da un
## quadro a muro, in cupola. Il PC non sa nemmeno che la cupola esista, e quando
## saprà comandarla sarà perché qualcuno ha speso trecentomila lire (l'upgrade
## della fase 1 nel GDD).
##
## QUESTA FASE NON HA UNO SCHERMO, ed è la prima. `screen()` restituisce `null`, e
## il CRT resta spento finché la cupola non è aperta: la sera comincia alzandosi e
## salendo in cupola, non sedendosi. È il rituale vero, e costa al giocatore
## esattamente quello che costava a chi ci lavorava.
##
## DUE PULSANTI A UOMO PRESENTE, sul quadro: il motore va solo finché tieni il
## dito. Le cupole si comandano così perché un battente da qualche quintale che si
## muove da solo mentre nessuno guarda è un modo di rompere un telescopio.
##
## COSA VEDE IL GIOCATORE: la cupola che si apre sopra la sua testa, mentre tiene
## premuto. Non c'è nessun numero da guardare, e non ne serve nessuno — la fessura
## che si allarga sul cielo è il migliore indicatore di corsa che esista.
##
## `runs_in_background()` è `true`, e QUI è obbligatorio: il giocatore non è alla
## postazione, è in cupola. Una fase sospesa quando la sedia è vuota non
## riceverebbe mai il comando che sta aspettando.
##
## NON DÀ PUNTEGGIO, e lo dichiara: `score()` è 100 sempre. È il caso della fase 4
## del GDD, «nessun punteggio: si passa o si ripete» — non c'è niente da fare bene
## o male, c'è solo da farlo. Fingere una metrica qui vorrebbe dire inventarsi una
## bravura che il gesto non contiene.
##
## COME PARLA AL MONDO, E COME IL MONDO LE PARLA. La cupola e il quadro vivono in
## `world/`, che a questa cartella è vietato: la fase non li cerca e non li
## conosce. Il giro si chiude sul bus, in due fatti e nessun comando — il quadro
## dice che una mano tiene premuto (`dome_button_changed`), la fase dice dove sta
## il battente (`dome_aperture_changed`). Chi in giro per il mondo ha un battente
## lo mette lì.
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

	Events.dome_button_changed.connect(_on_button)

	# SI ANNUNCIA LA POSIZIONE DI PARTENZA, e non è una formalità: la fase e il
	# mondo devono partire d'accordo. Rifacendo il setup (storia 2.6) questa fase
	# ricomincia da capo, con il battente a zero, mentre in cupola è rimasto
	# aperto: senza questa riga il pannello direbbe CLOSED e il cielo si vedrebbe
	# lo stesso. Con questa riga la cupola si richiude, che è ciò che «rifare il
	# setup» vuol dire.
	_report()


func _process(delta: float) -> void:
	if _done or truth == null:
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

	# LA FASE SI CHIUDE DA SÉ A FINE CORSA, e non c'è nessun tasto di conferma:
	# quello che si vede sopra la testa È la conferma. Da qui in poi la notte punta,
	# mette a fuoco ed espone, e con il tubo sotto un guscio chiuso sarebbero tre
	# fasi giocate contro un coperchio.
	if is_open():
		_finish()


## NESSUNO SCHERMO, e vedi la testa del file: il PC dell'osservatorio non sa che
## la cupola esista. Il pannello disegnato per questa fase non è stato buttato —
## `dome_screen.gd` resta nel repository — perché è esattamente quello che
## comparirà sul CRT il giorno in cui si comprerà il comando del portello dalla
## sala controllo. È il contenuto di un upgrade già scritto nel GDD, non codice
## morto.
func screen() -> Control:
	return null


## Il giocatore è in cupola, non alla postazione: sospendere questa fase quando la
## sedia è vuota vorrebbe dire non farla girare mai.
func runs_in_background() -> bool:
	return true


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


## LA FASE NON LEGGE PIÙ LA TASTIERA, e non deve: i pulsanti stanno su un quadro
## a muro, e chi li tiene premuti è un oggetto del mondo. Qui arriva solo il fatto.
## L'interblocco dei due pulsanti (premuti insieme, il motore sta fermo) vive nel
## quadro, dov'è il quadro elettrico vero.
func _on_button(direction: int) -> void:
	_truth_input.command = signi(direction)


func _read_command(delta: float) -> void:
	# Il cronometro del motore si azzera quando il comando si stacca, e cresce solo
	# mentre gira: è la stessa contabilità di `seconds_since_correction`, al
	# contrario. Nessuna sorgente dell'MVP lo legge (vedi `DomeInput`).
	var verso := _truth_input.command
	_truth_input.seconds_running = (_truth_input.seconds_running + delta) if verso != 0 else 0.0


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
