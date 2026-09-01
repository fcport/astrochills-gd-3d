## I battenti della cupola: quello che si muove quando la fase apre la fessura.
##
## COSA FA, IN UNA RIGA: ascolta `Events.dome_aperture_changed` e mette i battenti
## dove il fatto dice che sono.
##
## NON CONOSCE LA FASE, e non può: `phases/` e `world/` non si nominano a vicenda.
## Il condotto è il bus, e porta un FATTO — «l'apertura vale 0,37» — non un
## comando. La differenza si vede il giorno in cui il battente lo muoverà
## qualcos'altro: un interruttore in cupola, un temporizzatore, un upgrade. Quel
## qualcosa annuncerà lo stesso fatto e questo file non cambierà di una riga.
##
## OGNI BATTENTE HA LA SUA CORSA, dichiarata come uno SCOSTAMENTO dalla posa in
## cui è stato messo in scena. La posa in scena è la cupola CHIUSA — è così che
## comincia una notte — e ad apertura piena il battente è alla posa più lo
## scostamento. Due meccanismi in uno:
##
##   `open_offset`        quanto trasla, in metri (battenti che scorrono);
##   `open_rotation_deg`  quanto ruota, in gradi (battenti che girano sul guscio).
##
## SERVONO ENTRAMBI perché i due mondi hanno cupole diverse: quella segnaposto di
## `world/rooms/dome.tscn` sono due lastre di tetto che si scostano, quella
## modellata di `tools/cupola_blender.py` sono due gusci che ruotano attorno
## all'asse X passando oltre lo zenit. Un solo meccanismo avrebbe voluto dire
## riscrivere questo file al trasloco.
##
## I BATTENTI ARRIVANO PER `NodePath` E NON COME FIGLI, e non è pigrizia: nel
## mondo modellato vivono DENTRO la scena importata dal .glb, dove non si possono
## riappendere altrove senza rifare l'importazione a ogni rigenerazione.
class_name DomeShutter
extends Node3D

## Chi ha bisogno di questi battenti li trova per GRUPPO, mai per percorso: stessa
## regola di `IndoorsVolume`, della moka, del monitor.
const GROUP := &"dome_shutter"

## Quanto in fretta il battente insegue il valore annunciato, in frazioni di corsa
## al secondo.
##
## PIÙ VELOCE DEL MOTORE DELLA FASE, e non a caso: mentre il giocatore tiene
## premuto, l'apertura cresce di 0,16 al secondo e questo limite non morde mai —
## il battente sta esattamente dove il pannello dice. Morde solo sui SALTI: la
## cupola che si richiude all'alba, o un *rifai setup* che riporta l'apertura a
## zero di colpo. Senza limite quei due casi sarebbero uno scatto; con il limite
## sono una chiusura di tre secondi e mezzo, che è come si chiude una cupola.
const FOLLOW_SPEED := 0.30

## I battenti, nell'ordine. Gli scostamenti sotto sono paralleli a questa lista.
@export var leaves: Array[NodePath] = []

## Di quanto trasla ogni battente, in metri e nel sistema del PADRE del battente,
## fra chiusa e tutta aperta. Nel sistema del padre e non in quello del battente:
## si somma alla sua origine, che nel padre è espressa.
@export var open_offset: Array[Vector3] = []

## Di quanto ruota ogni battente, in gradi, fra chiusa e tutta aperta.
@export var open_rotation_deg: Array[Vector3] = []

## Dove il mondo crede che sia il battente adesso.
var _current := 0.0

## La chiave della fase che, quando c'è, comanda lei il motore.
##
## SÌ, QUESTO FILE NOMINA UNA FASE, ed è l'unica eccezione alla regola per cui
## `world/` non sa che `phases/` esista. La ragione è concreta: il quadro deve
## funzionare SEMPRE — anche a notte inoltrata, quando la fase 1 è finita da un
## pezzo e il giocatore torna in cupola perché sono arrivate le nuvole. Ma finché
## la fase è viva è LEI che integra il comando (è il suo stato osservabile, ADR-001)
## e due integratori sullo stesso motore vorrebbero dire cupola a doppia velocità.
## Si nomina la chiave e si sta zitti: non si chiama niente, non si cerca niente.
const PHASE_KEY := &"dome"

## Quanto corre il motore quando è questo file a comandarlo, in frazioni di corsa
## al secondo. È lo stesso numero di `HonestShutter.motor_speed`, ed è la stessa
## cupola: se un giorno il motore cambierà, cambieranno tutti e due, e il banco
## misura solo il primo. È il prezzo dichiarato di avere due padroni dello stesso
## meccanismo in due momenti diversi della notte.
const MOTOR_SPEED := 0.16

## L'ultimo valore annunciato dal bus: dove il battente deve arrivare.
var _target := 0.0

## Che cosa sta tenendo premuto una mano sul quadro, e se c'è una fase che comanda.
var _button := 0
var _phase_alive := false

## I nodi risolti una volta sola, con la loro posa da cupola chiusa.
var _leaves: Array[Node3D] = []
var _closed: Array[Transform3D] = []


func _ready() -> void:
	add_to_group(GROUP)
	_resolve()

	Events.dome_aperture_changed.connect(_on_aperture_changed)
	# ALL'ALBA LA CUPOLA SI CHIUDE, e non è un ornamento: senza, il battente
	# resterebbe aperto per sempre: la notte dopo la fase ricomincerebbe da un
	# pannello che dice CLOSED con il cielo già in vista, e il giocatore avrebbe
	# ragione a non credere più al pannello. Chiudere all'alba è anche quello che
	# si fa con una cupola vera.
	Events.dawn_reached.connect(_on_dawn)
	Events.dome_button_changed.connect(_on_button)
	Events.phase_started.connect(_on_phase_started)
	Events.phase_finished.connect(_on_phase_finished)

	# La posa di partenza è quella di scena — cupola chiusa — e la si applica
	# comunque: `_apply` a zero non muove niente, ma lascia il nodo in uno stato
	# noto invece che in quello che l'editor si è ricordato.
	_apply(0.0)


func _process(delta: float) -> void:
	# QUANDO NESSUNA FASE COMANDA, COMANDA IL QUADRO. È ciò che rende i due pulsanti
	# un comando vero e non la scenografia di una fase: a notte inoltrata, con la
	# fase 1 finita da ore, premere CHIUDE deve chiudere la cupola.
	if not _phase_alive and _button != 0:
		_target = clampf(_target + MOTOR_SPEED * _button * delta, 0.0, 1.0)
		Events.dome_aperture_changed.emit(_target)

	if is_equal_approx(_current, _target):
		return
	_current = move_toward(_current, _target, FOLLOW_SPEED * delta)
	_apply(_current)


## Il fatto dal bus. Si prende il valore e basta: chi l'ha detto non interessa.
func _on_aperture_changed(fraction: float) -> void:
	_target = clampf(fraction, 0.0, 1.0)


func _on_button(direction: int) -> void:
	_button = signi(direction)


func _on_phase_started(key: StringName) -> void:
	if key == PHASE_KEY:
		_phase_alive = true


func _on_phase_finished(key: StringName, _score: int) -> void:
	if key == PHASE_KEY:
		_phase_alive = false


func _on_dawn() -> void:
	_target = 0.0


## Quanto è aperta la cupola nel mondo, 0-1. Per le sonde e per il banco: chi
## guarda da fuori deve poter chiedere, non frugare.
func aperture() -> float:
	return _current


## Risolve i battenti e si ricorda la posa da cupola chiusa.
##
## GLI SCARTI DI LUNGHEZZA SI GRIDANO. Tre liste parallele scritte a mano in un
## .tscn sono il posto ideale per una riga in meno, e una riga in meno qui vuol
## dire un battente che non si muove — senza errori, senza log, senza niente:
## esattamente il guasto che questo progetto ha già pagato due volte.
func _resolve() -> void:
	if open_offset.size() != leaves.size() or open_rotation_deg.size() != leaves.size():
		push_error("[cupola] %d battenti ma %d traslazioni e %d rotazioni"
			% [leaves.size(), open_offset.size(), open_rotation_deg.size()])
		return
	for p in leaves:
		var n := get_node_or_null(p) as Node3D
		if n == null:
			push_error("[cupola] battente non trovato: %s" % p)
			return
		_leaves.append(n)
		_closed.append(n.transform)


## Mette ogni battente alla frazione di corsa data.
##
## SI INTERPOLA DALLA POSA CHIUSA, sempre, e non si accumula sulla posa corrente:
## accumulando, l'errore di un fotogramma resterebbe addosso al battente per tutta
## la notte, e cento aperture e chiusure lo porterebbero via dal guscio.
func _apply(f: float) -> void:
	for i in _leaves.size():
		var base := _closed[i]
		var giri := open_rotation_deg[i] * f
		var b := base.basis * Basis.from_euler(Vector3(
			deg_to_rad(giri.x), deg_to_rad(giri.y), deg_to_rad(giri.z)))
		_leaves[i].transform = Transform3D(b, base.origin + open_offset[i] * f)


## Il battente della scena, o `null` se non ce n'è. Stessa firma di
## `IndoorsVolume.find_in`.
static func find_in(tree: SceneTree) -> DomeShutter:
	return tree.get_first_node_in_group(GROUP) as DomeShutter
