## LA COLLISIONE VERA DELL'EDIFICIO, per le cose che ci si posano sopra.
##
## IL PROBLEMA, e perché è rimasto invisibile per un anno. La collisione di questa
## scena la genera `gen_blockout.py` da `geometria.py`, e ogni mobile è UN BLOCCO
## PIENO alto quanto il suo pezzo più alto. Per camminare è perfetto: non si
## attraversa una fila di sedie, non si passa dentro un carrello, e il giocatore
## non ha mai modo di accorgersi che quel blocco è pieno dove il mobile è vuoto.
##
## Poi sono arrivati gli oggetti che cadono, e ogni cima finta è diventata un
## posto dove la roba resta sospesa. Federico ha fotografato prima un termos e poi
## una radiolina a mezz'aria sopra il carrello del proiettore, e ha scritto
## «hitbox non sistemate». Misurato: su 84 blocchi di arredo, 31 fanno appoggiare
## dove non c'è niente — le due file di sedie e il carrello sono allo ZERO PER
## CENTO di materiale sulla propria cima.
##
## PERCHÉ NON SI CORREGGONO I BLOCCHI. Si potrebbe dichiarare, mobile per mobile,
## la forma vera: sedile a 0,45 più schienale sottile, carrello a due ripiani. Ma
## sono trenta mobili, ognuno con la sua forma, e ogni numero sarebbe indovinato
## guardando un modello che qualcun altro ha fatto — cioè trenta occasioni di
## sbagliare in silenzio, e un lavoro da rifare ogni volta che un modello cambia.
##
## QUI SI FA IL CONTRARIO: si prende la geometria che si VEDE e la si dà al motore
## com'è. Ogni mesh visibile diventa una collisione a triangoli, su un layer suo,
## e gli oggetti che si posano collidono con quella invece che con gli ingombri.
## Da quel momento la regola è una sola e non ha eccezioni: **ci si appoggia dove
## si vede**. Nessun numero da tarare, nessun mobile da dichiarare, e un modello
## nuovo porta con sé la propria collisione.
##
## IL GIOCATORE RESTA SUGLI INGOMBRI, ed è voluto. Camminare su una geometria a
## triangoli vuol dire incastrarsi fra le gambe di una sedia, salire su una pila
## di libri, restare appesi a uno spigolo: tutti problemi che i blocchi grezzi non
## hanno, e che risolverli costerebbe più di quanto valgano. I blocchi sono giusti
## per il corpo e sbagliati per gli oggetti; adesso ognuno ha i suoi.
##
## QUANTO COSTA. Duecentoquarantamila triangoli di collisione statica, costruiti
## una volta all'avvio. Una trimesh statica in Godot vive dentro un BVH e non
## pesa sul passo di fisica finché nessuno la tocca; a toccarla sono sette oggetti.
## Il tempo di costruzione è stampato all'avvio: se un giorno dovesse crescere,
## si vede lì.
class_name Corazza
extends Node3D

## Il layer della geometria vera. Il quarto, dopo mondo, giocatore e interagibili.
## `Interactable` non lo dichiara perché non è un layer di interazione: è dove
## vive una seconda copia del mondo, quella fatta come si vede.
const LAYER_APPOGGI := 1 << 3

const GROUP := &"corazza"


static func find_in(tree: SceneTree) -> Corazza:
	return tree.get_first_node_in_group(GROUP) as Corazza


func _ready() -> void:
	add_to_group(GROUP)
	# DIFFERITO: le mesh dell'edificio arrivano da scene istanziate, e dentro
	# `_ready()` l'albero le sta ancora montando. Costruire adesso vorrebbe dire
	# corazzare mezzo edificio, e non dirlo.
	_costruisci.call_deferred()


## OGNI COLLISIONE STA APPESA ALLA PROPRIA MESH, e non a un corpo unico.
##
## LA PRIMA STESURA LE METTEVA TUTTE INSIEME sotto uno `StaticBody3D` solo,
## copiando la `global_transform` di ogni mesh al momento della costruzione. Per
## un muro va bene: un muro sta fermo. Per un'ANTA no — e le ante di questa casa
## sono dieci. La corazza si costruisce all'avvio, quando le porte sono chiuse:
## da lì in poi la sagoma dell'anta chiusa restava piantata nel vano per tutta la
## partita, mentre l'anta vera girava via.
##
## E IL DIFETTO ERA INVISIBILE A CHI CAMMINA. Il giocatore collide con gli
## INGOMBRI, dove il vano è aperto, e passa; l'oggetto che ha in mano collide con
## QUESTA copia, e sbatteva contro l'anta che non c'è più. Federico ha provato a
## portare fuori una borraccia dallo studio e non passava dalla porta: «un muro
## invisibile». Era la fotografia di un'anta chiusa.
##
## MISURATO, con un raggio nel centro di ogni vano a porta spalancata: tutte e
## dieci ostruite su questo layer, tutte e dieci libere sugli ingombri.
##
## Appendendo la forma alla mesh, la collisione eredita le trasformazioni di chi
## la porta: l'anta gira e la sua sagoma gira con lei, la cupola ruota e il
## telescopio insegue senza lasciare croste dietro di sé. Costa un corpo statico
## per mesh invece di uno solo — nel BVH è la stessa cosa, cambia solo chi tiene
## il pennello.
##
## IL DIFETTO SI RIMETTE: `CORAZZA_FERMA=1` torna al corpo unico con le forme
## congelate dove le mesh stavano all'avvio. Serve a `tools/prova_varchi.gd`, che
## senza di questo non potrebbe dimostrare di saper vedere il muro invisibile.
func _costruisci() -> void:
	var quando := Time.get_ticks_msec()
	var ferma := OS.get_environment("CORAZZA_FERMA") == "1"
	var unico: StaticBody3D = null
	if ferma:
		unico = StaticBody3D.new()
		unico.name = "Triangoli"
		unico.collision_layer = LAYER_APPOGGI
		unico.collision_mask = 0
		add_child(unico)
	var mesh: Array[MeshInstance3D] = []
	_raccogli(get_tree().root, mesh)
	var facce := 0
	var corpi := 0
	for m in mesh:
		if m.mesh == null:
			continue
		var forma := m.mesh.create_trimesh_shape()
		if forma == null:
			continue
		var nodo := CollisionShape3D.new()
		nodo.shape = forma
		if ferma:
			unico.add_child(nodo)
			# DOPO `add_child`, non prima: `global_transform` su un nodo fuori
			# dall'albero non fa niente e non lo dice.
			nodo.global_transform = m.global_transform
		else:
			var corpo := StaticBody3D.new()
			corpo.name = "Corazza"
			# LAYER SÌ, MASCHERA NO: questa copia del mondo deve poter essere
			# COLPITA e non deve cercare niente. Una maschera diversa da zero la
			# farebbe partecipare a collisioni che il mondo vero sta già
			# risolvendo, due volte.
			corpo.collision_layer = LAYER_APPOGGI
			corpo.collision_mask = 0
			corpo.add_child(nodo)
			# FIGLIO DELLA MESH, a trasformata identità: così la forma sta dove
			# sta la mesh adesso E dove starà dopo, senza che nessuno debba
			# aggiornarla.
			m.add_child(corpo)
			corpi += 1
		facce += int(forma.get_faces().size() / 3.0)
	Log.info("corazza", "%d mesh, %d triangoli di collisione in %s, in %d ms"
		% [mesh.size(), facce,
		   "un corpo solo FERMO (difetto rimesso)" if ferma else "%d corpi" % corpi,
		   Time.get_ticks_msec() - quando])


## Ogni mesh visibile dell'albero, TRANNE quelle che stanno dentro un oggetto che
## si prende in mano.
##
## Senza quell'esclusione un `Carryable` si corazzerebbe da solo: la sua mesh
## finirebbe fra i triangoli fissi, e resterebbe una crosta immobile nel punto in
## cui l'oggetto si trovava all'avvio — contro cui gli altri oggetti sbattono e
## dentro cui quello vero rientra appena lo si sposta.
func _raccogli(n: Node, fuori: Array[MeshInstance3D]) -> void:
	if n is Carryable:
		return
	if n is MeshInstance3D and (n as MeshInstance3D).is_visible_in_tree():
		fuori.append(n as MeshInstance3D)
	for f in n.get_children():
		_raccogli(f, fuori)
