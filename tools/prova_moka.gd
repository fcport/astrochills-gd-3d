## LA MOKA C'È DAVVERO? Compare comprandola, si vede, ci si arriva, e non sta dentro
## il bancone.
##
## PERCHÉ UNA SONDA PER UNA CAFFETTIERA. Perché è il primo articolo che il negozio
## vende davvero, e la catena che porta dalle lire all'oggetto è lunga: il terminale
## marca il possesso, `Game.profile` lo salva, `moka.gd` lo legge in `_ready()` e
## ascolta `item_purchased`, il generatore la posa sul bancone. Ognuno dei quattro
## anelli si rompe in silenzio — l'oggetto resta invisibile, e il giocatore ha speso
## ottomila lire per niente.
##
## ED È GIÀ SUCCESSO A UN OGGETTO DI QUESTO PROGETTO, due volte: il letto che non si
## poteva usare, e la moka stessa, che è stata tolta dalla stanza (D-183) perché
## nessuno l'aveva guardata prima di posarla.
##
## LE DOMANDE:
##   1. SENZA POSSESSO NON C'È. Invisibile, spenta, e nessun prompt: chi non l'ha
##      comprata non deve trovarsi una moka in cucina.
##   2. COMPRANDOLA COMPARE, e senza ricaricare la scena: `moka.gd` ascolta il bus.
##   3. NON STA DENTRO IL BANCONE. Il piano della cucina è modellato — lavello,
##      fuochi, alzatina — e le coordinate della moka sono derivate dal mobile, non
##      guardate. Un oggetto mezzo dentro il lavello si vede solo entrando in cucina.
##   4. CI SI ARRIVA. Da almeno un punto in cui ci si sta in piedi, il raggio del
##      giocatore la trova. Si usa IL SUO raggio, non uno nostro.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_moka.tscn
extends Node

## Il passo della griglia attorno alla moka, e quanto lontano si prova a stare.
const PASSO := 0.25
const INTORNO := 8

## Quanto in alto sopra il piano si cerca un ostacolo: il corpo della moka, meno un
## paio di millimetri di franco. Se qui dentro c'è già qualcosa, la moka ci sta dentro.
const CORPO_ALTO := 0.198
const CORPO_LARGO := 0.089

var _guasti := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[moka] GUASTO: " + msg)


func _prova() -> void:
	# SI PARTE SENZA AVERLA COMPRATA, e va forzato: il profilo è persistito, e su una
	# partita in cui la moka è già stata comprata la domanda 1 passerebbe da sola
	# senza aver misurato niente. Si toglie il possesso PRIMA di montare la scena,
	# perché `moka.gd` lo legge in `_ready()`.
	Game.profile.owned_items.erase(&"moka")

	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 20:
		await get_tree().physics_frame

	var moka := Moka.find_in(get_tree())
	if moka == null:
		print("[moka] NESSUNA MOKA nel gruppo '%s': il negozio venderebbe un oggetto "
			% Moka.GROUP + "che non esiste")
		get_tree().quit(1)
		return
	var giocatore := Player.find_in(get_tree())
	if giocatore == null:
		print("[moka] il giocatore non c'è: la prova non vale")
		get_tree().quit(1)
		return
	print("[moka] la moka sta a %s" % _v(moka.global_position))

	# --- 0. IL NEGOZIO LA VENDE --------------------------------------------
	#
	# L'ANELLO PIÙ FACILE DA DIMENTICARE. `implemented` nel `.tres` è il filtro vero:
	# a falso la moka esiste nel mondo e non compare nel menu, e il giocatore non ha
	# nessun modo di arrivarci. È l'errore opposto a quello di ieri — allora si
	# vendeva quello che non c'era, e adesso si rischia di non vendere quello che c'è.
	var catalogo := load("res://data/catalog/catalog.tres") as ItemCatalog
	var sigle := PackedStringArray()
	for it in catalogo.for_category(&"personal"):
		sigle.append(String(it.id))
	print("[moka] il negozio, in PERSONAL, vende: {%s}" % ", ".join(sigle))
	if not sigle.has("moka"):
		_guasto("il terminale non mostra la moka: `implemented` è ancora falso, e "
			+ "l'oggetto in cucina non si può comprare in nessun modo")
	else:
		print("[moka] ok: il negozio non è più vuoto")

	# --- 1. SENZA POSSESSO NON C'È -----------------------------------------
	if moka.visible or moka.can_interact():
		_guasto("la moka si vede (o si usa) senza averla comprata: visibile %s, "
			% moka.visible + "usabile %s" % moka.can_interact())
	else:
		print("[moka] ok: chi non l'ha comprata non ce l'ha in cucina")

	# --- 2. COMPRANDOLA COMPARE --------------------------------------------
	#
	# SI COMPRA COME COMPRA IL TERMINALE: si marca il possesso e si annuncia. Non si
	# chiama niente sulla moka — è lei che deve accorgersene, ed è esattamente
	# l'anello che si sta provando.
	Game.profile.owned_items.append(&"moka")
	Events.item_purchased.emit(&"moka")
	await get_tree().physics_frame
	if not moka.visible:
		_guasto("comprata, la moka resta invisibile: `item_purchased` non arriva")
	elif not moka.can_interact():
		_guasto("comprata, la moka si vede ma non si usa")
	else:
		print("[moka] ok: comprata, compare — e la riga dice «%s»" % moka.prompt())

	# --- 3. NON STA DENTRO IL BANCONE --------------------------------------
	_nel_mobile(moka, giocatore)

	# --- 4. CI SI ARRIVA ---------------------------------------------------
	await _davanti(giocatore, moka)

	print("[moka] %d guasti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)


func _v(p: Vector3) -> String:
	return "%.2f, %.2f, %.2f" % [p.x, p.y, p.z]


## Il corpo della moka interseca qualcosa di solido?
##
## SI GUARDA LA CORAZZA, non gli ingombri: gli ingombri sono le scatole su cui
## cammina il giocatore, e il piano della cucina lì è una scatola piena — la moka
## posata sopra ci sarebbe dentro per definizione. La corazza è la geometria che si
## VEDE (D-205), ed è quella che dice se la moka è dentro il lavello.
##
## E SI SOLLEVA DI MEZZO CENTIMETRO, perché appoggiare è toccare: una scatola posata
## esattamente sul piano lo interseca in modo tangente, e un contatto tangente conta
## come intersezione. Senza il franco questa domanda risponderebbe «dentro» sempre.
func _nel_mobile(moka: Moka, giocatore: Player) -> void:
	var forma := BoxShape3D.new()
	forma.size = Vector3(CORPO_LARGO, CORPO_ALTO, CORPO_LARGO)
	var par := PhysicsShapeQueryParameters3D.new()
	par.shape = forma
	par.transform = Transform3D(Basis.IDENTITY,
		moka.global_position + Vector3(0, CORPO_ALTO / 2.0 + 0.005, 0))
	par.collision_mask = Corazza.LAYER_APPOGGI
	par.exclude = [giocatore.get_rid()]
	par.margin = 0.0
	var dentro := giocatore.get_world_3d().direct_space_state.intersect_shape(par, 4)
	if dentro.is_empty():
		print("[moka] ok: il corpo non tocca niente — sta sul piano, non dentro")
		return
	var chi := PackedStringArray()
	for d in dentro:
		var n := d.get("collider") as Node
		chi.append(n.name if n != null else "?")
	_guasto("la moka è dentro qualcosa: %s. Le sue coordinate sono derivate dal "
		% ", ".join(chi) + "bancone, ma sul bancone c'è del modellato")


## Da qualche parte, stando in piedi, il raggio del giocatore trova la moka?
## Stessa domanda e stesso metodo di `prova_macchina.gd`.
func _davanti(giocatore: Player, moka: Moka) -> void:
	var buoni := 0
	var migliore := 99.0
	var da_dove := Vector3.ZERO
	var occupati := 0
	var chi := {}
	# Si mira il CORPO, non il piede: il raggio parte dall'occhio e la moka è alta
	# diciassette centimetri — puntando l'origine si mira il piano di lavoro.
	var bersaglio := moka.global_position + Vector3(0, 0.100, 0)
	for dx in range(-INTORNO, INTORNO + 1):
		for dz in range(-INTORNO, INTORNO + 1):
			var p := Vector3(moka.global_position.x + dx * PASSO, 0.0,
				moka.global_position.z + dz * PASSO)
			if _dentro_qualcosa(giocatore, p):
				occupati += 1
				continue
			giocatore.velocity = Vector3.ZERO
			giocatore.global_position = p
			var cam := giocatore.camera()
			if cam == null:
				continue
			giocatore.look_at(Vector3(bersaglio.x, p.y, bersaglio.z), Vector3.UP)
			cam.look_at(bersaglio, Vector3.UP)
			await get_tree().physics_frame
			await get_tree().physics_frame
			var messo: Node = giocatore.focus()
			if messo == moka:
				buoni += 1
				var d := p.distance_to(moka.global_position)
				if d < migliore:
					migliore = d
					da_dove = p
			elif messo != null:
				chi[messo.name] = int(chi.get(messo.name, 0)) + 1
	var quanti := (2 * INTORNO + 1) * (2 * INTORNO + 1)
	print("[moka] provati %d punti attorno alla moka: %d occupati, %d buoni"
		% [quanti, occupati, buoni])
	for n in chi:
		print("[moka]   da qualche punto il raggio trovava %s (%d volte)" % [n, chi[n]])
	if buoni == 0:
		_guasto("da nessun punto in cui ci si sta in piedi il raggio trova la moka: "
			+ "in partita il prompt non comparirebbe mai")
	else:
		print("[moka] ok: il prompt compare da %d punti, il più vicino a %.2f m (%s)"
			% [buoni, migliore, _v(da_dove)])


## Se il corpo del giocatore, messo lì, sarebbe dentro qualcosa. Sollevato di cinque
## centimetri per la stessa ragione scritta in `prova_macchina.gd`: il fondo della
## capsula tocca il pavimento esattamente, e un contatto tangente conta.
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
