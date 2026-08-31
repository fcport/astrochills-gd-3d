## Il letto si può usare davvero? Ci si mette davanti e si guarda.
##
## PERCHÉ SERVE UNA SONDA PER UN LETTO. `bed.tscn` racconta nella propria testa un
## difetto già pagato: il primo letto costruito in questo progetto NON si poteva
## usare, e non per un errore di codice — per una geometria che nessuno aveva
## provato guardandola. Il raggio dell'interazione parte dall'occhio, a 1,65, ed è
## lungo 1,2 m; l'unica superficie del letto abbastanza alta da essere inquadrata è
## la spalliera. Se il letto sta in una stanza in cui non ci si può mettere davanti
## alla spalliera, il prompt non compare mai e la notte dopo è irraggiungibile.
##
## Nel magazzino il letto occupa il muro est per intero e lascia libero solo il
## pezzo davanti alla porta: che ci si arrivi è precisamente la cosa da misurare.
##
## SI USA IL RAGGIO DEL GIOCATORE, non uno nostro. Portata, maschera, altezza
## dell'occhio: sono tre numeri che vivono in `world/player/player.tscn`, e
## ricopiarli qui vorrebbe dire provare un letto diverso da quello che si gioca.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_letto.tscn
extends Node

## La griglia di punti in cui si prova a stare in piedi, attorno al letto. Passo
## grosso: non si cerca il pixel, si cerca se ESISTE un posto da cui si arriva.
const PASSO := 0.25

var _scena: Node3D
var _fatto := false


func _ready() -> void:
	_monta.call_deferred()


func _monta() -> void:
	var scena: Node3D = load("res://world/blockout.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	_scena = scena


func _process(_d: float) -> void:
	if _scena == null or _fatto:
		return
	_fatto = true

	var letto := Bed.find_in(get_tree())
	if letto == null:
		print("[letto] NESSUN LETTO nel gruppo '%s'" % Bed.GROUP)
		get_tree().quit()
		return
	# NASCE SPENTO — lo accende `main.gd` all'alba — e spento `can_interact()` dice
	# no a chiunque. Provarlo così vorrebbe dire provare che il letto è spento.
	letto.enabled = true

	var giocatore := Player.find_in(get_tree())
	var camera := giocatore.camera()
	var raggio := giocatore.find_child("InteractRay", true, false) as RayCast3D
	if raggio == null:
		print("[letto] il giocatore non ha un InteractRay")
		get_tree().quit()
		return

	# La spalliera: il pezzo alto del letto, e l'unico bersaglio possibile.
	var spalliera := letto.get_node_or_null(^"Headboard") as MeshInstance3D
	var bersaglio: Vector3 = (spalliera.global_position if spalliera != null
		else letto.global_position + Vector3(0, 0.5, 0))
	print("[letto] letto a %s, spalliera a %s"
		% [_v(letto.global_position), _v(bersaglio)])

	# Si gira attorno al letto a distanza di braccio e si prova ogni punto. La
	# stanza fermerà il giocatore dove ci sono i muri: quello che interessa è se
	# ALMENO UN punto raggiungibile vede la spalliera.
	var buoni := 0
	var migliore := 99.0
	# I MODI DI NON ARRIVARCI SONO TRE, e vanno distinti: non ci si sta in piedi, il
	# raggio non tocca niente (troppo lontano), il raggio tocca qualcos'altro. Un
	# referto che dicesse solo «non si arriva» lascerebbe cercare il guasto a caso.
	var occupati := 0
	var vuoti := 0
	var chi := {}
	for dx in range(-6, 7):
		for dz in range(-6, 7):
			var p := letto.global_position + Vector3(dx * PASSO, 0.0, dz * PASSO)
			if _dentro_un_muro(giocatore, p):
				occupati += 1
				continue
			giocatore.global_position = p
			giocatore.force_update_transform()
			camera.look_at(bersaglio, Vector3.UP)
			camera.force_update_transform()
			raggio.force_raycast_update()
			if not raggio.is_colliding():
				vuoti += 1
				continue
			var urto: Node = raggio.get_collider()
			if urto != letto:
				chi[urto.name] = int(chi.get(urto.name, 0)) + 1
			if urto == letto:
				buoni += 1
				var d := p.distance_to(bersaglio)
				if d < migliore:
					migliore = d
				if buoni <= 3:
					print("[letto] si arriva da %s (%.2f m dalla spalliera)" % [_v(p), d])
	print("[letto] provati %d punti: %d occupati da qualcosa, %d senza nessun urto"
		% [13 * 13, occupati, vuoti])
	for n in chi:
		print("[letto]   il raggio finiva in %s (%d volte)" % [n, chi[n]])
	if buoni == 0:
		print("[letto] NON SI ARRIVA: nessun punto in piedi vede la spalliera")
	else:
		print("[letto] %d punti buoni, il piu' vicino a %.2f m" % [buoni, migliore])
	get_tree().quit()


## Se il corpo del giocatore, messo lì, sarebbe dentro qualcosa. Serve a scartare i
## punti in cui non si può stare in piedi: provarli conterebbe come «ci si arriva»
## da dentro un muro.
func _dentro_un_muro(giocatore: Player, p: Vector3) -> bool:
	var forma := giocatore.get_node_or_null(^"Collision") as CollisionShape3D
	if forma == null or forma.shape == null:
		return false
	var par := PhysicsShapeQueryParameters3D.new()
	par.shape = forma.shape
	# SOLLEVATA DI CINQUE CENTIMETRI, e non e' una furbizia: la capsula e' alta 1,8
	# e sta a 0,9 dai piedi, quindi il suo fondo tocca il pavimento ESATTAMENTE. Il
	# pavimento e' sul layer 1 come tutto il resto, e un contatto tangente conta
	# come intersezione: senza il sollevamento tutti e centosessantanove i punti
	# risultavano occupati, e la sonda dichiarava irraggiungibile un letto che non
	# aveva ancora provato.
	par.transform = Transform3D(Basis.IDENTITY, p + Vector3(0, forma.position.y + 0.05, 0))
	par.collision_mask = 1
	par.exclude = [giocatore.get_rid()]
	return not giocatore.get_world_3d().direct_space_state.intersect_shape(par, 1).is_empty()


func _v(p: Vector3) -> String:
	return "%.2f, %.2f, %.2f" % [p.x, p.y, p.z]
