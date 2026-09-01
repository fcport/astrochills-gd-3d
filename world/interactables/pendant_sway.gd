## La pulsantiera DONDOLA: un pendolo smorzato appeso alla propria staffa.
##
## PERCHÉ ESISTE. Un oggetto appeso a un cavo che sta immobile come una mensola è
## la cosa che dice al giocatore «questo è finto» prima ancora che la guardi bene.
## Non serve a niente, non cambia nessun esito, ed è esattamente per questo che si
## nota: è l'unica parte della stanza che risponde a chi la tocca.
##
## È UN PENDOLO VERO E NON UNA CURVA REGISTRATA: ω' = −(g/L)·sin θ − c·ω. Costa due
## righe come un'animazione a mano e in cambio non si ripete mai uguale — due colpi
## ravvicinati si sommano, uno in controtempo la ferma. Una curva registrata
## ripartirebbe da capo a ogni pressione, che è il modo in cui si riconosce.
##
## GIRA ATTORNO AL PROPRIO Z, cioè oscilla PARALLELA AL MURO. Il verso non è
## indifferente: appesa a quindici centimetri dall'intonaco, se dondolasse avanti e
## indietro entrerebbe nel muro a metà corsa. Di lato ha tutto lo spazio che vuole.
##
## LO SPINGONO I PULSANTI, ognuno dalla sua parte — APRE la manda in un verso,
## CHIUDE nell'altro — perché è quello che fa un pollice: la spinta è di traverso,
## non lungo il cavo.
class_name PendantSway
extends Node3D

## Lunghezza equivalente del pendolo, in metri: il cavo più mezzo corpo. Da questa
## esce il periodo, e il periodo è quello che si riconosce come «pesante» o «finto».
const LUNGHEZZA := 0.45

## Quanto si smorza. A 2,3 si ferma in tre o quattro oscillazioni: un cavo di gomma
## non è un pendolo di Foucault, e una pulsantiera che oscilla per mezzo minuto
## diventa un fastidio invece che un dettaglio.
const SMORZAMENTO := 2.3

## Quanto la scuote una pressione, in radianti al secondo.
const SPINTA := 0.7

## Oltre questo angolo non va, in radianti: dodici gradi. Serve a non farla
## sbandierare quando qualcuno pigia i due tasti a raffica.
const MASSIMO := 0.21

## Sotto questa velocità e questo angolo si considera ferma e si smette di
## calcolare: senza, resta un tremolio sotto il millesimo di grado per sempre.
const QUIETE := 0.0015

var _angolo := 0.0
var _velocita := 0.0
var _riposo := Basis.IDENTITY


func _ready() -> void:
	_riposo = transform.basis
	Events.dome_button_changed.connect(_on_button)
	set_process(false)


func _on_button(direction: int) -> void:
	# Allo zero — cioè al rilascio — la spinta è metà e al contrario: il dito che
	# si stacca la lascia andare, non la spinge.
	_velocita += SPINTA * (float(direction) if direction != 0 else -signf(_angolo) * 0.5)
	set_process(true)


func _process(delta: float) -> void:
	# Passo fisso e sottopassi: a trenta fotogrammi un pendolo integrato con Eulero
	# esplicito GUADAGNA energia a ogni giro invece di perderla, e invece di
	# fermarsi si mette a sbandierare. Tre sottopassi bastano.
	for _i in 3:
		var d := delta / 3.0
		_velocita -= (9.81 / LUNGHEZZA) * sin(_angolo) * d
		_velocita -= SMORZAMENTO * _velocita * d
		_angolo = clampf(_angolo + _velocita * d, -MASSIMO, MASSIMO)
	transform.basis = _riposo * Basis(Vector3.BACK, _angolo)
	if absf(_angolo) < QUIETE and absf(_velocita) < QUIETE:
		_angolo = 0.0
		_velocita = 0.0
		transform.basis = _riposo
		set_process(false)
