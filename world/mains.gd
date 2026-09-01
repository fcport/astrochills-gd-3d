## LA CORRENTE DELL'OSSERVATORIO: c'è o non c'è.
##
## COS'È. Il quadro in facciata è il punto da cui l'edificio prende corrente, ed è
## uno solo: un pulsante a fungo, rosso, che stacca tutto. Il GDD lo aveva già
## scritto — «il contatore, in facciata, governa PC, monitor, montatura e luci, e
## nel 1999 si riarma a mano, e per farlo bisogna uscire al buio» — e questo nodo
## è la metà di quel fatto che oggi esiste: le luci.
##
## PERCHÉ STA SUL QUADRO E NON È UN AUTOLOAD. La corrente non è uno stato astratto
## del gioco: è un oggetto sul muro, con una posizione e una serratura. Chi vuole
## sapere se c'è corrente lo chiede al quadro; chi vuole cambiarla ci deve andare
## davanti. Un autoload avrebbe reso possibile staccare la corrente da qualunque
## punto del codice, che è precisamente la cosa da non poter fare.
##
## STACCARE NON GIRA GLI INTERRUTTORI, e questa è la parte che sembra un dettaglio
## e non lo è. Quando torna la corrente, si riaccende quello che era acceso PRIMA —
## non tutto, e non niente. È come funziona un impianto vero, ed è anche l'unica
## versione che non irrita: chi aveva spento la sala divulgazione non se la ritrova
## accesa al ritorno.
##
## E UN INTERRUTTORE PREMUTO AL BUIO NON SI PERDE. Se il giocatore gira una placca
## mentre la corrente è staccata, la lampada resta spenta (non c'è corrente) ma la
## POSIZIONE dell'interruttore cambia — e si vede quando la corrente torna. Senza
## questo, un deviatore premuto durante il blackout tornava fuori fase, e il
## giocatore lo doveva premere due volte senza capire perché.
class_name Mains
extends Node3D

const GROUP := &"mains"

## Tutte le lampade dell'edificio. Le scrive il generatore del blockout, che le
## legge dalla stessa fonte da cui nascono le plafoniere: un elenco raccolto a
## runtime per prossimità o per tipo sarebbe la solita ricerca che funziona finché
## qualcuno non aggiunge una luce.
@export var luci: Array[NodePath] = []

## Se l'osservatorio nasce sotto tensione. Sì: la sera si arriva e la corrente c'è
## — staccarla è un gesto del giocatore, non lo stato iniziale.
@export var acceso_all_inizio: bool = true

var _acceso := true

## Le lampade che erano accese quando la corrente è stata staccata, e che vanno
## riaccese quando torna. È anche la memoria delle placche girate al buio.
var _da_riaccendere: Array[Node3D] = []


func _ready() -> void:
	add_to_group(GROUP)
	_acceso = acceso_all_inizio


static func find_in(tree: SceneTree) -> Mains:
	return tree.get_first_node_in_group(GROUP) as Mains


## C'è corrente adesso.
func acceso() -> bool:
	return _acceso


## Stacca o riattacca. Restituisce lo stato NUOVO.
func commuta() -> bool:
	if _acceso:
		_stacca()
	else:
		_riattacca()
	# UN FATTO SUL BUS, e non un comando a qualcuno: oggi lo ascolta il monitor,
	# domani lo ascolteranno il PC e la montatura — che è il resto di quello che
	# il GDD affida al contatore, e che non esiste ancora.
	Events.mains_changed.emit(_acceso)
	return _acceso


func _stacca() -> void:
	_acceso = false
	_da_riaccendere.clear()
	for n in _lampade():
		if n.visible:
			_da_riaccendere.append(n)
			n.visible = false


func _riattacca() -> void:
	_acceso = true
	for n in _da_riaccendere:
		if is_instance_valid(n):
			n.visible = true
	_da_riaccendere.clear()


## Come sarà quella lampada quando torna la corrente. Serve alle placche, che al
## buio non possono leggere lo stato dalle lampade — sono tutte spente.
func tornera_accesa(percorsi: Array[NodePath], base: Node) -> bool:
	for p in percorsi:
		var n := base.get_node_or_null(p) as Node3D
		if n != null:
			return _da_riaccendere.has(n)
	return false


## Il giocatore ha girato una placca mentre la corrente è staccata: la lampada non
## si accende, ma l'interruttore sì.
func segna(percorsi: Array[NodePath], base: Node, accesa: bool) -> void:
	for p in percorsi:
		var n := base.get_node_or_null(p) as Node3D
		if n == null:
			continue
		if accesa and not _da_riaccendere.has(n):
			_da_riaccendere.append(n)
		elif not accesa:
			_da_riaccendere.erase(n)


func _lampade() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for p in luci:
		var n := get_node_or_null(p) as Node3D
		if n != null:
			out.append(n)
	return out
