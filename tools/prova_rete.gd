## IL FUNGO ROSSO STACCA DAVVERO TUTTO?
##
## LA DOMANDA, E PERCHE' NON E' OVVIA. Il quadro spegne le lampade che ha in
## elenco, e l'elenco lo scrive il generatore. Il difetto che questo impianto puo'
## avere e' uno solo, ed e' silenzioso: una lampada FUORI DALL'ELENCO. Resta accesa
## a corrente staccata, non da' nessun errore, e si nota solo passando davanti a
## quella stanza - cioe' magari mai.
##
## PERCIO' NON SI CONTROLLA L'ELENCO, SI CONTROLLA LA SCENA. La sonda cerca da sola
## OGNI luce dell'albero, di qualunque tipo e ovunque sia, e pretende che dopo lo
## scatto siano tutte spente. E' l'unico controllo che non si da' ragione da solo:
## chiedere al quadro se ha spento le lampade del quadro e' ricopiare la sua stessa
## lista in due posti.
##
## E SI CONTROLLA ANCHE IL RITORNO, che e' la meta' che di solito manca: riattaccando
## deve tornare accesa esattamente la roba che era accesa prima, non tutta e non
## niente.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_rete.tscn
extends Node

var _scena: Node
var _t := 0.0
var _fatto := false
var _guasti := 0


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
	await _prova()
	get_tree().quit()


## LE TRE LUCI CHE NON SONO DELL'IMPIANTO, e restano accese per forza.
##
## Non e' una scorciatoia per far passare la prova: sono tre cose che la corrente
## dell'osservatorio non alimenta e non potrebbe. La LUNA e il CIELO stanno fuori
## dal contatore; la luce di PROSSIMITA' non e' una lampada affatto - e' l'aiuto
## di lettura che segue la testa del giocatore, e non ha un interruttore da
## nessuna parte. Ogni altra luce che sopravviva allo scatto e' un difetto.
const NON_DELL_IMPIANTO := ["Luna", "LuceCielo", "Prossimita"]


## Tutte le luci dell'albero che stanno FACENDO luce adesso.
##
## `visible_in_tree` E NON `visible`: il quadro spegne il nodo padre `Accesa`, non
## la `Light3D` che ci sta sotto. Guardando solo la luce si vedrebbe `visible =
## true` per sempre, e questa sonda direbbe che non si spegne mai niente.
func _accese(n: Node, fuori: Array[Light3D]) -> void:
	if (n is Light3D and (n as Light3D).is_visible_in_tree()
			and not NON_DELL_IMPIANTO.has(n.name)):
		fuori.append(n as Light3D)
	for f in n.get_children():
		_accese(f, fuori)


func _elenco() -> Array[Light3D]:
	var out: Array[Light3D] = []
	_accese(get_tree().root, out)
	return out


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[rete] GUASTO: " + msg)


## IL DITO CI ARRIVA? Un pulsante che il raggio del giocatore non trova e' un
## pulsante che non esiste, e non lo dice nessun errore: davanti al quadro non
## compare il prompt e basta. E' successo con il fungo - il bersaglio dell'anta gli
## stava davanti - e si e' visto solo mirandolo in uno scatto.
##
## SI TIRA IL RAGGIO VERO, dalla stessa quota e con la stessa portata di quello del
## giocatore, e si guarda CHI risponde per primo.
func _si_riesce_a_mirarlo(fungo: MainsButton) -> void:
	var da := fungo.global_position + Vector3(0.0, 0.24, 0.85)
	var q := PhysicsRayQueryParameters3D.create(da, fungo.global_position)
	q.collision_mask = Interactable.LAYER_INTERACTABLE
	var colpo := fungo.get_world_3d().direct_space_state.intersect_ray(q)
	if colpo.is_empty():
		_guasto("mirando il fungo il raggio non incontra nessun interagibile")
		return
	var chi: Node = colpo["collider"]
	print("[rete] mirando il fungo il raggio trova %s" % chi.name)
	if chi != fungo:
		_guasto("mirando il fungo si prende %s: il pulsante non e' premibile" % chi.name)


## L'ANTA SI APRE, E SI PORTA DIETRO QUELLO CHE HA SOPRA. Il fungo e' avvitato
## sulla lamiera: se aprendo il quadro resta dov'era, il bersaglio e il pezzo che
## si vede si sono separati - e il giocatore preme un pulsante che sullo schermo
## sta da un'altra parte.
func _l_anta_si_apre(fungo: MainsButton) -> void:
	var anta := PanelDoor.find_in(get_tree())
	if anta == null:
		_guasto("l'anta del quadro non si trova")
		return
	var prima := fungo.global_position
	var dietro_chiusa := _dietro(anta)
	anta.interact(Player.find_in(get_tree()))
	# Il motore gira a 220 gradi al secondo: mezzo secondo simulato basta e avanza.
	for _i in 40:
		anta._process(0.016)
	var corsa := prima.distance_to(fungo.global_position)
	print("[rete] aprendo il quadro il fungo si sposta di %.3f m (aperta = %s)"
		% [corsa, anta.aperta()])
	if not anta.aperta():
		_guasto("premendo l'anta il quadro non si apre")
	if corsa < 0.10:
		_guasto("il fungo non segue l'anta: resta piantato dov'era")
	# E SI APRE VERSO FUORI. Federico: «il box elettrico si apre dentro il muro». La corsa del
	# fungo non lo vedeva: dentro il muro o verso il prato, si sposta uguale.
	var dietro_aperta := _dietro(anta)
	print("[rete] il punto più indietro dell'anta, dal retro della cassa: chiusa %.3f m, aperta %.3f m"
		% [dietro_chiusa, dietro_aperta])
	if dietro_aperta < -0.01:
		_guasto("aperta, l'anta entra nel muro di %.0f cm" % (-dietro_aperta * 100.0))
	# E RESTA APPESA ALLA CASSA. Federico: «STACCATO». Si apriva verso fuori e dalla parte
	# giusta, ma girava attorno allo spigolo della lamiera invece che alla cerniera, e
	# restava a tre centimetri e mezzo dalla cassa: nessuno dei controlli sopra lo vedeva.
	var stacco := _stacco(anta)
	print("[rete] aperta, l'anta sta a %.1f mm dalla cassa" % (stacco * 1000.0))
	if stacco > 0.01:
		_guasto("aperta, l'anta si stacca dalla cassa di %.1f cm" % (stacco * 100.0))
	# Si richiude: il resto della prova vuole il quadro com'era.
	anta.interact(Player.find_in(get_tree()))
	for _i in 40:
		anta._process(0.016)


## IL PULSANTE DI DENTRO (D-256). Federico: «mi dai la possibilita' qui di staccare tutte le luci
## e riaccenderle?». A quadro aperto si mira, e stacca e riattacca la stessa corrente del fungo; a
## quadro chiuso il raggio trova l'anta, perché dietro la lamiera non si preme niente.
func _quello_dentro(dentro: MainsButton) -> void:
	var anta := PanelDoor.find_in(get_tree())
	var giocatore := Player.find_in(get_tree())
	var chi := _colpito(dentro)
	print("[rete] a quadro chiuso, mirando il pulsante di dentro si prende %s" % _nome(chi))
	if chi != anta:
		_guasto("a quadro chiuso il raggio verso il pulsante di dentro prende %s, non l'anta" % _nome(chi))
	anta.interact(giocatore)
	for _i in 40:
		anta._process(0.016)
	# IL MOTORE FISICO VEDE L'ANTA GIRATA SOLO AL PASSO DOPO: spostare un corpo non lo
	# sposta subito per i raggi. Senza aspettare, il raggio trovava l'anta chiusa - che
	# in gioco, dove i fotogrammi passano, non c'e' piu'.
	await get_tree().physics_frame
	await get_tree().physics_frame
	chi = _colpito(dentro)
	print("[rete] a quadro aperto, mirando il pulsante di dentro si prende %s" % _nome(chi))
	if chi != dentro:
		_guasto("a quadro aperto il pulsante di dentro non si riesce a premere")
	var prima := _elenco().size()
	dentro.interact(giocatore)
	var staccata := _elenco().size()
	dentro.interact(giocatore)
	var ridata := _elenco().size()
	print("[rete] col pulsante di dentro: %d luci accese, poi %d, poi %d" % [prima, staccata, ridata])
	if staccata != 0 or ridata != prima:
		_guasto("il pulsante di dentro non stacca e riattacca la corrente")
	anta.interact(giocatore)
	for _i in 40:
		anta._process(0.016)


## Chi prende per primo un raggio da davanti al quadro, a sessanta centimetri, verso il bersaglio.
func _colpito(bersaglio: Node3D) -> Node:
	var da := bersaglio.global_position + Vector3(0.0, 0.10, 0.60)
	var q := PhysicsRayQueryParameters3D.create(da, bersaglio.global_position)
	q.collision_mask = Interactable.LAYER_INTERACTABLE
	var colpo := bersaglio.get_world_3d().direct_space_state.intersect_ray(q)
	return null if colpo.is_empty() else colpo["collider"]


func _nome(n: Node) -> String:
	return "niente" if n == null else String(n.name)


## Quanto l'anta sta davanti al retro della cassa, nel punto più indietro, in metri: sotto zero è
## dentro il muro. Il quadro ha il retro sul muro e guarda verso il suo +z (vedi
## `quadro_elettrico_blender.py`); si prendono gli otto spigoli di ogni mesh dell'anta, fungo
## compreso, nelle coordinate del quadro.
func _dietro(anta: PanelDoor) -> float:
	var quadro := anta.get_parent() as Node3D
	var nel_quadro := quadro.global_transform.affine_inverse()
	var minimo := INF
	var coda: Array[Node] = [anta._anta]
	while not coda.is_empty():
		var n: Node = coda.pop_back()
		coda.append_array(n.get_children())
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var box := mi.mesh.get_aabb()
		for i in 8:
			minimo = minf(minimo, (nel_quadro * mi.global_transform * box.get_endpoint(i)).z)
	return minimo


## Quanto la lamiera sta lontana dalla cassa, in metri: il vertice dell'anta più vicino a un vertice
## della cassa. Si guardano solo i vertici a meno di sei centimetri dall'asse del cardine, che è
## dove due pezzi incernierati si toccano - tutti contro tutti sarebbero centinaia di milioni.
func _stacco(anta: PanelDoor) -> float:
	var quadro := anta.get_parent() as Node3D
	var nel_quadro := quadro.global_transform.affine_inverse()
	var cassa := quadro.get_node("Modello").find_child("Cassa", true, false) as MeshInstance3D
	var cardine := Vector2(anta.position.x, anta.position.z)
	var lamiera := _vicino_al_cardine(anta._anta as MeshInstance3D, nel_quadro, cardine)
	var scatola := _vicino_al_cardine(cassa, nel_quadro, cardine)
	var minimo := INF
	for p in lamiera:
		for q in scatola:
			minimo = minf(minimo, p.distance_squared_to(q))
	return sqrt(minimo)


func _vicino_al_cardine(mi: MeshInstance3D, nel_quadro: Transform3D, cardine: Vector2) -> PackedVector3Array:
	var fuori := PackedVector3Array()
	var xf := nel_quadro * mi.global_transform
	for s in mi.mesh.get_surface_count():
		for v: Vector3 in mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
			var p := xf * v
			if Vector2(p.x, p.z).distance_to(cardine) < 0.06:
				fuori.append(p)
	return fuori


func _prova() -> void:
	var quadro := Mains.find_in(get_tree())
	if quadro == null:
		print("[rete] il quadro non si trova: la prova non vale")
		return
	# DUE PULSANTI DAL D-256: il fungo sull'anta e quello rosso dentro la cassa. Si
	# distinguono da chi li porta, non dal nome.
	var fungo: MainsButton = null
	var dentro: MainsButton = null
	for n in get_tree().get_nodes_in_group(MainsButton.GROUP):
		if n.get_parent() is PanelDoor:
			fungo = n as MainsButton
		else:
			dentro = n as MainsButton
	if fungo == null:
		print("[rete] il pulsante non si trova: la prova non vale")
		return
	var giocatore := Player.find_in(get_tree())

	_si_riesce_a_mirarlo(fungo)
	_l_anta_si_apre(fungo)
	if dentro == null:
		_guasto("il pulsante dentro il quadro non c'e'")
	else:
		await _quello_dentro(dentro)

	var prima := _elenco()
	print("[rete] a corrente data: %d luci accese nella scena" % prima.size())
	if prima.size() < 5:
		print("[rete] SONDA CIECA: con cosi' poche luci accese non c'e' niente da "
			+ "spegnere, e questa prova passerebbe comunque")

	# SI PREME IL PULSANTE, non si chiama il quadro: fra il dito e la corrente c'e'
	# un interagibile, e se quel filo si stacca il gioco non risponde piu' — che e'
	# il difetto che si vuole vedere.
	fungo.interact(giocatore)
	var dopo := _elenco()
	print("[rete] a corrente staccata: %d luci accese" % dopo.size())
	for l in dopo:
		print("   resta accesa: %s" % l.get_path())
	if not dopo.is_empty():
		_guasto("%d luci non sono in elenco al quadro" % dopo.size())
	if quadro.acceso():
		_guasto("il quadro si dichiara ancora sotto tensione")

	fungo.interact(giocatore)
	var tornate := _elenco()
	print("[rete] a corrente ridata: %d luci accese" % tornate.size())
	if tornate.size() != prima.size():
		_guasto("tornando la corrente si riaccendono %d luci invece di %d"
			% [tornate.size(), prima.size()])
	for l in prima:
		if not tornate.has(l):
			_guasto("%s non si e' riaccesa" % l.name)

	if _guasti == 0:
		print("[rete] ok: il fungo stacca tutta la scena e la rimette com'era")
	else:
		print("[rete] GUASTO: %d controlli falliti" % _guasti)
