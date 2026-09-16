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
## TORNANDO LA CORRENTE LE PLAFONIERE RESTANO SPENTE (D-260). Federico: «se la corrente
## si stacca, le luci devono comunque essere riaccese». Si riaccendono a mano, placca per
## placca: staccare la corrente costa un giro dell'edificio al buio. Tornano da sole solo
## le cose che una placca non ce l'hanno — le due luci di fuori, le spie delle placche,
## la luce del monitor — e le superfici che brillano da sé.
##
## E AL BUIO UNA PLACCA NON FA NIENTE. Girata a corrente staccata la lampada resta
## spenta, e quando la corrente torna resta spenta lo stesso: la placca dice «Accendi»
## perché lo stato lo leggono le lampade. La versione di prima ricordava la placca
## girata al buio e al ritorno riaccendeva quella stanza sola, fra tutte spente.
class_name Mains
extends Node3D

const GROUP := &"mains"

## Tutte le lampade dell'edificio, tranne le rosse della cupola (D-259). Le scrive il
## generatore del blockout, che le legge dalla stessa fonte da cui nascono le
## plafoniere: un elenco raccolto a runtime per prossimità o per tipo sarebbe la
## solita ricerca che funziona finché qualcuno non aggiunge una luce.
@export var luci: Array[NodePath] = []

## Le lampade che tornano da sole con la corrente: quelle che nessuna placca comanda
## (D-260). Le scrive il generatore, che sa quali lampade comanda ogni placca.
@export var tornano: Array[NodePath] = []

## LE COSE CHE BRILLANO DA SÉ e stanno attaccate alla rete: la spia verde del PC, i
## tasti della pulsantiera, le spie delle placche, l'insegna della sala. Non fanno luce
## e nessuna `Light3D` le rappresenta, ma una spia accesa a corrente staccata tradisce
## l'impianto quanto una plafoniera (D-258). Le scrive il generatore, che le legge dai
## modelli: sono i pezzi con un materiale emissivo.
@export var luminose: Array[NodePath] = []

## Se l'osservatorio nasce sotto tensione. Sì: la sera si arriva e la corrente c'è
## — staccarla è un gesto del giocatore, non lo stato iniziale.
@export var acceso_all_inizio: bool = true

var _acceso := true

## Le lampade senza placca che erano accese allo stacco, e che tornano con la corrente.
var _da_riaccendere: Array[Node3D] = []

## Le superfici luminose spente dallo stacco: [mesh, superficie, materiale di prima].
var _superfici_spente: Array = []


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
	_spegni_superfici()
	_da_riaccendere.clear()
	var da_sole := _nodi(tornano)
	for n in _nodi(luci):
		if n.visible:
			n.visible = false
			if da_sole.has(n):
				_da_riaccendere.append(n)


func _riattacca() -> void:
	_acceso = true
	for voce in _superfici_spente:
		if is_instance_valid(voce[0]):
			(voce[0] as MeshInstance3D).set_surface_override_material(voce[1], voce[2])
	_superfici_spente.clear()
	for n in _da_riaccendere:
		if is_instance_valid(n):
			n.visible = true
	_da_riaccendere.clear()


## Se almeno una di queste lampade prende corrente dal quadro. LE ROSSE DELLA CUPOLA NO
## (D-259): stanno fuori dall'elenco, e la loro placca le comanda anche al buio.
func alimenta(percorsi: Array[NodePath], base: Node) -> bool:
	var mie := _nodi(luci)
	for p in percorsi:
		if mie.has(base.get_node_or_null(p)):
			return true
	return false


## SI SPEGNE L'EMISSIONE, NON IL PEZZO: nascondere la spia lascerebbe un buco nella
## cassa del PC. Ogni superficie emissiva prende una copia del suo materiale con
## l'energia a zero, che è la stessa variante di shader — niente compilazione a
## metà partita — e quando la corrente torna riprende il materiale di prima.
func _spegni_superfici() -> void:
	_superfici_spente.clear()
	for p in luminose:
		var mi := get_node_or_null(p) as MeshInstance3D
		if mi == null:
			push_error("[rete] la superficie luminosa %s non c'è" % p)
			continue
		for s in mi.get_surface_override_material_count():
			var mat := mi.get_active_material(s) as BaseMaterial3D
			if mat == null or not mat.emission_enabled:
				continue
			var spento := mat.duplicate() as BaseMaterial3D
			spento.emission_energy_multiplier = 0.0
			_superfici_spente.append([mi, s, mi.get_surface_override_material(s)])
			mi.set_surface_override_material(s, spento)


func _nodi(percorsi: Array[NodePath]) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for p in percorsi:
		var n := get_node_or_null(p) as Node3D
		if n != null:
			out.append(n)
	return out
