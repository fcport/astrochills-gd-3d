## Alla partenza del motore la pulsantiera dà UNO SCATTO, e poi si spegne da sola.
##
## TRE VERSIONI, E LE PRIME DUE ERANO SBAGLIATE PER LO STESSO MOTIVO: il movimento
## durava. La prima dondolava come un pendolo — il bersaglio si spostava sotto il
## mirino, il prompt lampeggiava a ogni oscillazione e il giocatore lo leggeva come
## «non ha funzionato». La seconda tremava per tutto il tempo in cui il motore
## girava: ampiezza dieci volte questa, e a schermo sembrava una convulsione.
##
## Quello che serve è un TRANSITORIO. Un motore che parte dà uno strappo e poi si
## regolarizza: mezzo millimetro, tre decimi di secondo, e sparisce. Non è un moto,
## è un evento — e un evento non ha tempo di dare fastidio a niente.
##
## SI SPEGNE DA SÉ ANCHE SE TIENI PREMUTO. È la differenza che conta rispetto alla
## versione di prima: la vibrazione non racconta «il motore sta girando», racconta
## «il motore è partito». Del fatto che stia girando se ne accorge già chi guarda la
## cupola aprirsi, che è dove deve stare l'occhio.
class_name PendantTremor
extends Node3D

## Quanto si sposta al colpo più forte, in metri. Mezzo millimetro su un corpo largo
## sei centimetri: alla prima occhiata non si sa nemmeno di averlo visto.
const AMPIEZZA := 0.0006

## Quanto si inclina, in radianti: nove centesimi di grado.
const TORSIONE := 0.0016

## Le due frequenze, in hertz. SONO DUE E NON COMMENSURABILI apposta: una sola
## darebbe un'oscillazione pulita, cioè un'animazione, e si riconosce subito.
const HZ_A := 26.0
const HZ_B := 37.5

## In quanto si spegne: a ogni `SPEGNIMENTO` secondi l'ampiezza si divide per e.
## A 0,085 lo scatto è finito in tre decimi di secondo — il tempo di accorgersene.
const SPEGNIMENTO := 0.085

## Sotto questa frazione si smette di calcolare e si torna esattamente a riposo.
## ESATTAMENTE: lasciare l'ultimo residuo vorrebbe dire un bersaglio spostato di
## frazioni di millimetro per sempre, che nessuno vede e che non torna più indietro.
const QUIETE := 0.03

var _forza := 0.0
var _t := 0.0
var _riposo := Transform3D.IDENTITY


func _ready() -> void:
	_riposo = transform
	Events.dome_button_changed.connect(_on_button)
	set_process(false)


## SOLO ALLA PARTENZA, non al rilascio: il bus dice zero quando il dito si alza, e
## un motore che si ferma si spegne invece di strappare.
func _on_button(direction: int) -> void:
	if direction == 0:
		return
	_forza = 1.0
	_t = 0.0
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	_forza *= exp(-delta / SPEGNIMENTO)
	if _forza < QUIETE:
		_forza = 0.0
		transform = _riposo
		set_process(false)
		return
	var a := sin(_t * TAU * HZ_A)
	var b := sin(_t * TAU * HZ_B)
	transform = _riposo.translated_local(
		Vector3(a * AMPIEZZA, b * AMPIEZZA * 0.6, 0.0) * _forza)
	transform.basis = _riposo.basis * Basis(Vector3.BACK, b * TORSIONE * _forza)
