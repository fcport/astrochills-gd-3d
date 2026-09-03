## SI TORNA A CASA DAVVERO? Ci si cammina, ci si mette davanti, e si guarda.
##
## PERCHÉ SERVE UNA SONDA PER UN'AUTO. Perché è l'unico modo di far cominciare la
## notte dopo, e i modi in cui una cosa così si rompe non danno nessun errore: il
## prompt che non compare mai, l'oggetto che si accende quando non deve, il
## parcheggio dietro un recinto. In tutti e tre i casi il giocatore gira per il
## prato e non succede niente.
##
## ED È GIÀ SUCCESSO, con il letto che stava qui prima: il primo letto costruito in
## questo progetto NON si poteva usare, e non per un errore di codice — per una
## geometria che nessuno aveva provato guardandola. `prova_letto.gd` è nata da
## quello; questa ne è l'erede, e fa le stesse domande a un oggetto diverso.
##
## TRE DOMANDE:
##   1. NASCE SPENTA. Un'auto usabile a mezzanotte chiude la notte con la posa a
##      metà — la accende `main.gd` all'alba, e solo allora.
##   2. IL PROMPT COMPARE. Si gira attorno all'auto a passo di venticinque
##      centimetri, e da almeno un punto in cui ci si sta in piedi il raggio del
##      giocatore deve trovarla. Si usa IL SUO raggio, non uno nostro: portata,
##      maschera e altezza dell'occhio vivono in `world/player/player.tscn`, e
##      ricopiarli qui vorrebbe dire provare un'auto diversa da quella che si gioca.
##   3. CI SI ARRIVA A PIEDI. Dal punto in cui il giocatore nasce — cioè da dove è
##      sceso arrivando — si cammina fino al parcheggio, tenendo premuto avanti come
##      farebbe lui. Sono venti metri di prato: se in mezzo c'è il recinto, o un
##      pezzo di edificio, si vede qui.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_macchina.tscn
extends Node

## Il passo della griglia in cui si prova a stare in piedi, attorno all'auto. Passo
## grosso: non si cerca il pixel, si cerca se ESISTE un posto da cui si arriva.
const PASSO := 0.25

## Quanto lontano dall'auto si prova a stare, in caselle per lato.
const INTORNO := 8

## La maglia con cui si allaga il pavimento cercando la strada per il parcheggio, e
## quanto vicino all'auto deve arrivare l'onda perché valga. Il tetto e' il numero
## di caselle oltre il quale si smette di cercare: il prato e' grande, e se dopo
## quindicimila caselle il parcheggio non si e' toccato, non lo si tocca.
const MAGLIA := 0.30
const ARRIVATO := 1.60
const TETTO := 15000

## Quanto dislivello si accetta fra due caselle vicine: un gradino piu' alto un
## `CharacterBody3D` non lo sale (D-033), quindi non e' pavimento che continua.
const GRADINO := 0.25

var _guasti := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[macchina] GUASTO: " + msg)


func _v(p: Vector3) -> String:
	return "%.2f, %.2f, %.2f" % [p.x, p.y, p.z]


func _prova() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 20:
		await get_tree().physics_frame

	var auto := Macchina.find_in(get_tree())
	if auto == null:
		print("[macchina] NESSUNA AUTO nel gruppo '%s': la notte 2 è irraggiungibile"
			% Macchina.GROUP)
		get_tree().quit(1)
		return
	var giocatore := Player.find_in(get_tree())
	if giocatore == null:
		print("[macchina] il giocatore non c'è: la prova non vale")
		get_tree().quit(1)
		return
	var partenza := giocatore.global_position
	print("[macchina] l'auto sta a %s, il giocatore nasce a %s: %.1f m di prato"
		% [_v(auto.global_position), _v(partenza),
			Vector2(auto.global_position.x - partenza.x,
				auto.global_position.z - partenza.z).length()])

	# --- 1. NASCE SPENTA ---------------------------------------------------
	if auto.can_interact():
		_guasto("l'auto è già usabile all'avvio: si potrebbe chiudere la notte a "
			+ "mezzanotte, con la posa a metà")
	else:
		print("[macchina] ok: nasce spenta, la accende l'alba")

	# --- 2. IL PROMPT COMPARE ----------------------------------------------
	auto.enabled = true
	await _davanti(giocatore, auto)

	# --- 3. CI SI ARRIVA A PIEDI -------------------------------------------
	await _a_piedi(giocatore, auto, partenza)

	print("[macchina] %d guasti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)


## Da qualche parte, stando in piedi, il raggio del giocatore trova l'auto?
func _davanti(giocatore: Player, auto: Macchina) -> void:
	var buoni := 0
	var migliore := 99.0
	var da_dove := Vector3.ZERO
	var occupati := 0
	var chi := {}
	for dx in range(-INTORNO, INTORNO + 1):
		for dz in range(-INTORNO, INTORNO + 1):
			var p := Vector3(auto.global_position.x + dx * PASSO, 0.0,
				auto.global_position.z + dz * PASSO)
			if _dentro_qualcosa(giocatore, p):
				occupati += 1
				continue
			giocatore.velocity = Vector3.ZERO
			giocatore.global_position = p
			giocatore.look_at(Vector3(auto.global_position.x, p.y,
				auto.global_position.z), Vector3.UP)
			var cam := giocatore.camera()
			if cam != null:
				cam.look_at(auto.global_position, Vector3.UP)
			await get_tree().physics_frame
			await get_tree().physics_frame
			var messo: Node = giocatore.focus()
			if messo == auto:
				buoni += 1
				var d := p.distance_to(auto.global_position)
				if d < migliore:
					migliore = d
					da_dove = p
			elif messo != null:
				chi[messo.name] = int(chi.get(messo.name, 0)) + 1
	var quanti := (2 * INTORNO + 1) * (2 * INTORNO + 1)
	print("[macchina] provati %d punti attorno all'auto: %d occupati da qualcosa, "
		% [quanti, occupati] + "%d buoni" % buoni)
	for n in chi:
		print("[macchina]   da qualche punto il raggio trovava %s (%d volte)" % [n, chi[n]])
	if buoni == 0:
		_guasto("da nessun punto in cui ci si sta in piedi il raggio del giocatore "
			+ "trova l'auto: in partita il prompt non comparirebbe mai")
	else:
		print("[macchina] ok: il prompt compare da %d punti, il più vicino a %.2f m (%s)"
			% [buoni, migliore, _v(da_dove)])
		print("[macchina] la riga dice: «%s»" % auto.prompt())


## CI SI ARRIVA A PIEDI? Si allaga il pavimento camminabile a partire da dove il
## giocatore nasce, e si guarda se l'onda tocca il parcheggio.
##
## SI ALLAGA INVECE DI CAMMINARE, e la prima stesura camminava: si puntava l'auto e
## si teneva premuto avanti. Ma il giocatore nasce DENTRO l'edificio, in sala di
## divulgazione, e la linea retta verso il parcheggio passa dentro il muro sud e
## dentro la teca dei meteoriti — la sonda diceva «non ci si arriva» misurando la
## propria rotta, non il mondo. Camminare bene vorrebbe dire seguire una rotta, e
## trovarla è esattamente questo allagamento.
##
## LE ANTE NON CONTANO. Una porta chiusa non e' un muro: si apre. Si escludono i
## battenti dall'allagamento, o basterebbe che qualcuno chiudesse la porta
## d'ingresso perche' questa prova accusasse il parcheggio.
func _a_piedi(giocatore: Player, auto: Macchina, partenza: Vector3) -> void:
	var spazio := giocatore.get_world_3d().direct_space_state
	var forma := giocatore.get_node_or_null(^"Collision") as CollisionShape3D
	var scartati: Array[RID] = [giocatore.get_rid()]
	for schema in ["Porta_*", "Anta*"]:
		for n in get_tree().current_scene.find_children(schema, "CollisionObject3D", true, false):
			scartati.append((n as CollisionObject3D).get_rid())
	var meta := Vector2(auto.global_position.x, auto.global_position.z)
	var da := Vector2i(roundi(partenza.x / MAGLIA), roundi(partenza.z / MAGLIA))
	var quote := {da: partenza.y}
	var coda: Array[Vector2i] = [da]
	var toccate := 0
	var arrivato := false
	while not coda.is_empty() and toccate < TETTO:
		var v: Vector2i = coda.pop_front()
		toccate += 1
		var y0: float = quote[v]
		if Vector2(v.x * MAGLIA, v.y * MAGLIA).distance_to(meta) < ARRIVATO:
			arrivato = true
			break
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = v + d
			if quote.has(q):
				continue
			var x := q.x * MAGLIA
			var z := q.y * MAGLIA
			var giu := PhysicsRayQueryParameters3D.create(
				Vector3(x, y0 + GRADINO + 0.05, z), Vector3(x, y0 - GRADINO - 0.05, z))
			giu.collision_mask = Interactable.LAYER_WORLD
			giu.exclude = scartati
			var suolo := spazio.intersect_ray(giu)
			if suolo.is_empty():
				quote[q] = NAN
				continue
			var p: Vector3 = suolo["position"]
			var par := PhysicsShapeQueryParameters3D.new()
			par.shape = forma.shape
			par.transform = Transform3D(Basis.IDENTITY,
				p + Vector3(0, forma.position.y + 0.05, 0))
			par.collision_mask = Interactable.LAYER_WORLD
			par.exclude = scartati
			if not spazio.intersect_shape(par, 1).is_empty():
				quote[q] = NAN
				continue
			quote[q] = p.y
			coda.append(q)
	print("[macchina] a piedi: allagate %d caselle da %.2f m dal punto di nascita"
		% [toccate, MAGLIA])
	if arrivato:
		print("[macchina] ok: dal punto in cui si nasce il pavimento arriva fino all'auto")
	else:
		_guasto("dal punto in cui si nasce non si arriva all'auto: il pavimento "
			+ "camminabile si ferma prima (%d caselle allagate)" % toccate)


## Se il corpo del giocatore, messo lì, sarebbe dentro qualcosa. Serve a scartare i
## punti in cui non si può stare in piedi: provarli conterebbe come «ci si arriva»
## da dentro un muro.
##
## SOLLEVATA DI CINQUE CENTIMETRI, e non è una furbizia: la capsula è alta 1,8 e sta
## a 0,9 dai piedi, quindi il suo fondo tocca il pavimento ESATTAMENTE, e un
## contatto tangente conta come intersezione. Senza il sollevamento risultavano
## occupati tutti i punti, e la sonda dichiarava irraggiungibile una cosa che non
## aveva ancora provato.
func _dentro_qualcosa(giocatore: Player, p: Vector3) -> bool:
	var forma := giocatore.get_node_or_null(^"Collision") as CollisionShape3D
	if forma == null or forma.shape == null:
		return false
	var par := PhysicsShapeQueryParameters3D.new()
	par.shape = forma.shape
	par.transform = Transform3D(Basis.IDENTITY, p + Vector3(0, forma.position.y + 0.05, 0))
	par.collision_mask = Interactable.LAYER_WORLD
	par.exclude = [giocatore.get_rid()]
	return not giocatore.get_world_3d().direct_space_state.intersect_shape(par, 1).is_empty()
