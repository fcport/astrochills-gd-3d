## L'interruttore della luce: la causa che mancava.
##
## PERCHÉ ESISTE. Fino a ieri le stanze erano illuminate da dieci `OmniLight3D`
## sospese a mezz'aria: nessun apparecchio sopra, nessun comando su un muro. In un
## gioco che si regge tutto sull'essere un posto vero, era l'unica cosa senza una
## causa — e si notava, perché una luce che viene dal nulla e non si può spegnere
## non è una luce, è un'impostazione del motore. Adesso la luce esce da una
## plafoniera e la plafoniera obbedisce a una placca, che è dove ci si aspetta di
## trovarla: sul muro, dal lato della maniglia, a un metro e dieci.
##
## PERCHÉ È UN `Interactable`. Stessa ragione della porta: il contratto esiste per
## non avere due modi di premere `E`. Il raggio parte dalla camera, quindi
## distingue «lo guardo» da «ci sono accanto» — e con un interruttore la
## distinzione conta più che altrove, perché a un interruttore ci si passa davanti
## di continuo senza volerlo toccare.
##
## LE LUCI SONO UN DATO, NON UNA RICERCA. Quali lampade comanda una placca lo
## scrive il generatore del blockout, che lo legge da `LUCI_COMANDATE` in
## `geometria.py` — la stessa fonte da cui nascono la posizione della placca e la
## posizione delle plafoniere. Cercarle a runtime per prossimità sembrerebbe più
## comodo e sarebbe il solito errore: due stanze adiacenti hanno lampade a tre
## metri l'una dall'altra, e un raggio di ricerca che funziona in cucina accende
## anche il corridoio.
##
## COSA NON FA, E DI PROPOSITO. Non persiste nulla e non parla con `Game` né con
## `Events`: accendere una luce non è un'attività della notte, non si misura e non
## si compra. È un gesto, e i gesti che non contano restano locali. Se un giorno
## la luce accesa in una stanza dovrà pesare su qualcosa, quel giorno il fatto
## avrà più di un ascoltatore e passerà da `Events`; oggi non ne ha nessuno.
class_name LightSwitch
extends Interactable

## Le lampade comandate da questa placca. Le scrive il generatore.
@export var luci: Array[NodePath] = []

## Se la stanza parte illuminata. Tutte partono accese: l'osservatorio è in
## servizio, non abbandonato, e chi arriva la sera trova le luci dei locali di
## lavoro già date. Lo spegnere è il gesto del giocatore, non lo stato iniziale.
##
## È SOLO LO STATO INIZIALE, e lo stato corrente non sta qui. Lo stato corrente
## sono le luci: `_accesa()` lo rilegge da loro a ogni scatto. La differenza si
## vede quando due placche comandano le stesse lampade — lo spazio divulgazione ne
## ha due, una alla porta d'ingresso e una a quella del corridoio — perché con uno
## stato locale la seconda placca va fuori fase alla prima pressione della prima e
## da quel momento serve premerla due volte. Sono deviatori, e un deviatore non
## sa in che posizione sta l'altro: sa solo com'è la luce adesso.
@export var accesa: bool = true

## Il locale che questa placca accende, come lo si nomina nel prompt: «la cucina»,
## «il corridoio». Con dieci placche identiche appese a dieci muri, «Accendi» non
## dice niente e le si prova a caso finché non succede qualcosa — che è esattamente
## il difetto per cui la prima versione dell'impianto è stata rifatta.
@export var locale: String = ""

## Emesso a ogni scatto, con lo stato NUOVO. Signal diretto e non `Events`: chi
## ascolta è al più uno e sa quale placca sta guardando (stessa regola di
## `interactable.gd`).
signal commutato(ora_accesa: bool)


func _ready() -> void:
	_applica(accesa)


## Com'è la luce adesso: lo dicono le lampade, non una variabile. Se non ne trova
## nessuna resta l'ultimo valore noto, che è l'unica risposta onesta.
func _accesa() -> bool:
	# SENZA CORRENTE LE LAMPADE NON DICONO NIENTE: sono tutte spente, e leggere lo
	# stato da loro darebbe «spento» a ogni placca dell'edificio. Durante un
	# blackout la posizione dell'interruttore la ricorda il quadro, che e' l'unico
	# a sapere cosa si riaccendera' quando la corrente torna.
	var quadro := Mains.find_in(get_tree())
	if quadro != null and not quadro.acceso():
		return quadro.tornera_accesa(luci, self)
	for percorso in luci:
		var nodo := get_node_or_null(percorso)
		if nodo != null:
			return nodo.visible
	return accesa


## Il prompt dice cosa succederà, non cosa si sta guardando. «Accendi» davanti a
## una stanza al buio è un'informazione; «Interruttore» non è niente.
func prompt() -> String:
	var verbo := "Spegni" if _accesa() else "Accendi"
	return verbo if locale.is_empty() else "%s %s" % [verbo, locale]


func interact(by: Node3D) -> void:
	if not can_interact():
		return
	accesa = not _accesa()
	_applica(accesa)
	commutato.emit(accesa)
	interacted.emit(by)


## Spegnere significa `visible = false` sulla luce, non `light_energy = 0`.
##
## Sono la stessa cosa a vedersi e non a costare: una `OmniLight3D` con energia
## zero resta nella lista delle luci che ogni superficie deve considerare, e in
## una stanza con tre plafoniere spente si paga tre volte per il buio. Invisibile
## esce dal conto. Vale anche per le mesh del diffusore, che sono emissive: un
## neon spento che continua a brillare è peggio di nessun neon.
func _applica(ora_accesa: bool) -> void:
	# A CORRENTE STACCATA L'INTERRUTTORE SCATTA E LA LAMPADA NO, che e' quello che
	# fa un impianto vero. La posizione non si perde: la tiene il quadro, e si vede
	# quando la corrente torna.
	var quadro := Mains.find_in(get_tree())
	if quadro != null and not quadro.acceso():
		quadro.segna(luci, self, ora_accesa)
		return
	for percorso in luci:
		var nodo := get_node_or_null(percorso)
		if nodo == null:
			push_warning("interruttore: la luce %s non esiste" % percorso)
			continue
		nodo.visible = ora_accesa
