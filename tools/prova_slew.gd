## QUANTE VOLTE SI ACCENDE LA SCRITTA «SLEWING»?
##
## LA DOMANDA, E PERCHE' NON E' ESTETICA. `telescope_slewing_changed` non muove
## solo una scritta: a tubo in viaggio lo schermo NON DISEGNA il soggetto (a meta'
## slew il campo inquadrato non e' quello) e INVIO non conferma. Una montatura che
## si dichiara in viaggio per un fotogramma ogni tre decimi di secondo fa
## lampeggiare l'oggetto e ignora in silenzio una pressione su venti.
##
## COSA SI MISURA: i CAMBI DI STATO sul bus, contati per tre gesti diversi.
##
##     un GOTO vero          si parte e si arriva          2 cambi, ne' piu' ne' meno
##     l'inseguimento        il cielo gira, il tubo segue   0 cambi: non e' un viaggio
##     il centraggio a mano  le frecce, mezzo grado al s.   0 cambi: non e' un viaggio
##
## E LA MONTATURA SI GUIDA A MANO, un fotogramma simulato alla volta, con gli
## stessi numeri delle fasi: la deriva del cielo (`HonestPointing`), la velocita'
## della pulsantiera e il passo con cui la fase riannuncia il puntamento. Sono
## quei tre numeri, insieme alla banda della montatura, a produrre il difetto.
##
## IL DIFETTO SI RIMETTE: `SENZA_ISTERESI=1` porta a zero la soglia di partenza,
## cioe' toglie l'isteresi e riporta il comportamento vecchio. Senza quel
## confronto il referto direbbe «2 cambi» e nessuno saprebbe se e' poco o tanto.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_slew.tscn
extends Node

## Il fotogramma simulato, in secondi. Sessanta al secondo.
const DT := 1.0 / 60.0

## Quanto lontano si manda il tubo per il GOTO di prova, in gradi.
const VIAGGIO := 40.0

## Quanti secondi si sta a guardare l'inseguimento e il centraggio.
const INSEGUIMENTO := 20.0
const CENTRAGGIO := 4.0

var _scena: Node
var _t := 0.0
var _fatto := false
var _guasti := 0

## I cambi di stato contati da quando si e' azzerato.
var _cambi := 0
var _acceso := false


func _ready() -> void:
	_monta.call_deferred()


func _monta() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	_scena = scena


func _process(d: float) -> void:
	if _scena == null or _fatto:
		return
	_t += d
	if _t < 1.5:
		return
	_fatto = true
	_prova()
	get_tree().quit()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[slew] GUASTO: " + msg)


func _su_moto(muove: bool) -> void:
	_cambi += 1
	_acceso = muove


## LA DERIVA DEL CIELO IN SECONDI VERI. Un quarto di grado per minuto di gioco,
## e il gioco corre a `game_min_per_sec`: i due numeri stanno nel gioco, non qui.
func _deriva_al_secondo() -> float:
	return HonestPointing.GRADI_AL_MINUTO * Tuning.game_min_per_sec


## UN FOTOGRAMMA COME LO VIVE LA MONTATURA IN PARTITA: la fase ricalcola dove
## mandare gli encoder, riannuncia sul bus se si e' spostata abbastanza, e la
## montatura fa il suo passo.
func _fotogramma(m: TelescopeMount, bersaglio: Vector2, ultimo: Vector2) -> Vector2:
	if ultimo.distance_to(bersaglio) >= PhaseGoto.PASSO_ANNUNCIO:
		Events.telescope_aim_changed.emit(bersaglio.x, bersaglio.y)
		ultimo = bersaglio
	m._process(DT)
	return ultimo


func _prova() -> void:
	var m := TelescopeMount.find_in(get_tree())
	if m == null:
		print("[slew] la montatura non si trova: la prova non vale")
		return
	if OS.get_environment("SENZA_ISTERESI") == "1":
		m.partenza_gradi = 0.0
		m.banda_morta_gradi = TelescopeMount.ARRIVATO
		print("[slew] SENZA ISTERESI: la montatura si dichiara in viaggio appena "
			+ "il bersaglio si sposta. E' il comportamento vecchio.")
	# SI GUIDA A MANO: un fotogramma alla volta, con un delta fisso. Lasciandola
	# girare da sola i numeri dipenderebbero da quanto e' carica la macchina.
	m.set_process(false)
	Events.telescope_slewing_changed.connect(_su_moto)

	var deriva := _deriva_al_secondo()
	print("[slew] il cielo deriva di %.4f gradi al secondo vero" % deriva)

	# --- UNO: IL GOTO VERO. Si parte da fermi e si va lontano.
	m.piazza(0.0, 60.0)
	var bersaglio := Vector2(VIAGGIO, 45.0)
	var ultimo := Vector2(INF, INF)
	_cambi = 0
	var passi := 0
	# Tanti fotogrammi quanti ne servono al motore, piu' un margine.
	while passi < 900:
		ultimo = _fotogramma(m, bersaglio, ultimo)
		passi += 1
		if passi > 3 and not m.in_moto():
			break
	print("[slew] GOTO di %.0f gradi: %d cambi di stato in %.1f s" % [
		VIAGGIO, _cambi, passi * DT])
	if _cambi == 0:
		print("[slew] SONDA CIECA: un GOTO che non accende mai la scritta vuol "
			+ "dire che questa prova non sta guardando niente")
		return
	if _cambi != 2:
		_guasto("un GOTO deve accendere e spegnere la scritta UNA volta: %d cambi"
			% _cambi)

	# --- DUE: L'INSEGUIMENTO. Il tubo sta sul soggetto e il cielo gira.
	_cambi = 0
	var n := int(INSEGUIMENTO / DT)
	for i in n:
		bersaglio.x += deriva * DT
		ultimo = _fotogramma(m, bersaglio, ultimo)
	print("[slew] inseguendo il cielo per %.0f s: %d cambi di stato" % [
		INSEGUIMENTO, _cambi])
	if _cambi > 0:
		_guasto("inseguire il cielo non e' un viaggio: la scritta lampeggia "
			+ "%.1f volte al secondo" % (_cambi / 2.0 / INSEGUIMENTO))

	# --- TRE: IL CENTRAGGIO A MANO. Freccia premuta, mezzo grado al secondo.
	_cambi = 0
	n = int(CENTRAGGIO / DT)
	for i in n:
		bersaglio.x += (deriva + PhaseGoto.VELOCITA) * DT
		ultimo = _fotogramma(m, bersaglio, ultimo)
	print("[slew] centrando a mano per %.0f s: %d cambi di stato" % [
		CENTRAGGIO, _cambi])
	if _cambi > 0:
		_guasto("centrare a mano non e' un viaggio: la scritta lampeggia "
			+ "%.1f volte al secondo" % (_cambi / 2.0 / CENTRAGGIO))

	# --- E IL TUBO HA DAVVERO SEGUITO? Una montatura che non si muove affatto
	# darebbe zero cambi in tutte e tre le prove, e passerebbe a pieni voti.
	var scarto := absf(m.dove().x - bersaglio.x)
	print("[slew] a fine centraggio il tubo e' a %.4f gradi dal bersaglio" % scarto)
	if scarto > TelescopeMount.ARRIVATO:
		_guasto("il tubo non insegue: resta indietro di %.3f gradi" % scarto)

	if _guasti == 0:
		print("[slew] ok: la scritta si accende per i viaggi e per niente altro")
	else:
		print("[slew] GUASTO: %d controlli falliti" % _guasti)
