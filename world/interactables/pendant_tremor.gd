## La pulsantiera TREMA mentre il motore gira, e sta ferma tutto il resto del tempo.
##
## PRIMA DONDOLAVA, ED ERA UNA PESSIMA IDEA. Un pendolo smorzato è realistico e in
## gioco era ingestibile: il bersaglio si spostava sotto il mirino, il raggio lo
## perdeva e lo ritrovava, e il prompt lampeggiava a ogni oscillazione. Il giocatore
## leggeva quel lampeggio come «non ha funzionato» e si metteva a inseguire
## l'oggetto invece di guardare la cupola — cioè il dettaglio che doveva dare vita
## alla stanza rubava l'attenzione al motivo per cui la stanza esiste.
##
## LA DIFFERENZA FRA TREMARE E DONDOLARE È DOVE STA IL BERSAGLIO. Un dondolio
## sposta il centro: dopo un secondo il tasto è altrove e bisogna rimirare. Un
## tremito oscilla ATTORNO al centro con ampiezza sotto il paio di millimetri: il
## bersaglio resta dov'è, e quello che si vede è che l'oggetto è vivo.
##
## E TREMA SOLO SOTTO CARICO, che è anche l'unica cosa vera: la vibrazione non ce
## l'ha la pulsantiera, ce l'ha il motore della cupola, e le arriva su per il cavo.
## Ferma la cupola, ferma la mano — quindi il momento in cui il tremito potrebbe
## dare fastidio alla mira, cioè quando si sta mirando, è esattamente quello in cui
## non c'è.
class_name PendantTremor
extends Node3D

## Quanto si sposta, in metri. Un millimetro e mezzo su un corpo largo sei
## centimetri: si vede come ronzio, non come movimento.
const AMPIEZZA := 0.0015

## Quanto si inclina, in radianti: un quinto di grado.
const TORSIONE := 0.0035

## Le due frequenze, in hertz. SONO DUE E NON COMMENSURABILI apposta: una sola
## darebbe un'oscillazione pulita, cioè un'animazione, e si riconosce dopo mezzo
## secondo. Due che non si chiudono mai danno un battito che non si ripete.
const HZ_A := 17.0
const HZ_B := 23.5

## In quanto entra e in quanto esce, in secondi. L'uscita è più lenta dell'entrata
## perché un motore che parte strappa e uno che si ferma si spegne.
const ENTRATA := 0.10
const USCITA := 0.22

var _acceso := false
var _forza := 0.0
var _t := 0.0
var _riposo := Transform3D.IDENTITY


func _ready() -> void:
	_riposo = transform
	Events.dome_button_changed.connect(_on_button)
	set_process(false)


func _on_button(direction: int) -> void:
	_acceso = direction != 0
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	var voluta := 1.0 if _acceso else 0.0
	_forza = move_toward(_forza, voluta, delta / (ENTRATA if _acceso else USCITA))
	if _forza <= 0.0:
		# FERMA VUOL DIRE ESATTAMENTE FERMA: si rimette la posa di riposo invece di
		# lasciare l'ultimo residuo, o resterebbe uno scarto di frazioni di
		# millimetro che nessuno vede e che sposta il bersaglio per sempre.
		transform = _riposo
		set_process(false)
		return
	var a := sin(_t * TAU * HZ_A)
	var b := sin(_t * TAU * HZ_B)
	transform = _riposo.translated_local(
		Vector3(a * AMPIEZZA, b * AMPIEZZA * 0.6, 0.0) * _forza)
	transform.basis = _riposo.basis * Basis(Vector3.BACK, b * TORSIONE * _forza)
