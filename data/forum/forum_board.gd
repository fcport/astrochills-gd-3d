## Un'area (board) del forum della BBS: un titolo e i suoi messaggi. SOLO DATI, quasi.
##
## Sul modello di `data/catalog/item_catalog.gd`: una Resource con un `@export Array`
## che referenzia i `.tres` dei messaggi. La BBS riceve la board e chiede `available()`
## — questo file raccoglie e filtra, non decide cosa disegnare a schermo.
##
## `available` È LOGICA PURA e collaudabile al banco: data una board fissa e una notte,
## torna sempre gli stessi messaggi. Il filtro `appears_from_night` è reale — è la
## regola «nuovi messaggi col passare delle notti» resa codice, non un commento.
class_name ForumBoard
extends Resource

## Sigla stabile della board (es. &"equipment").
@export var id: StringName = &""

## Il titolo dell'area, in INGLESE — come le categorie del terminale (`PERSONAL`,
## `FACILITIES`): è la voce di una macchina, non testo scritto da una persona.
@export var title: String = ""

## I messaggi, iniettati dal `.tres`. L'ordine è quello del file: stabile e diffabile,
## come il roster dei committenti e gli item del catalogo.
@export var messages: Array[ForumMessage] = []

## I messaggi visibili a `night`: quelli con `appears_from_night <= night`, nell'ordine
## del `.tres`. FILTRO PURO — nessun accesso ad autoload, nessuno SceneTree: dato un
## elenco fisso e una notte, torna sempre gli stessi messaggi (collaudabile al banco).
func available(night: int) -> Array[ForumMessage]:
	var out: Array[ForumMessage] = []
	for msg in messages:
		if msg == null:
			continue
		if msg.appears_from_night <= night:
			out.append(msg)
	return out
