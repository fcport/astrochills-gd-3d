## LA MOKA FA IL CAFFÈ COME LO SI FA? La si compra, la si prende, la si mette sul fuoco, si
## accende, si aspetta, si versa in una tazza, si beve; e una tazza piena lanciata si svuota
## (D-244).
##
## SI CAMMINA TUTTO CON LE MANI DEL GIOCATORE, invece di chiamare le funzioni: il suo raggio,
## il suo prompt, il suo E e il suo destro. Il difetto che Federico ha trovato era proprio
## questo — «premi, fa il caffè» — una sequenza che esisteva nel codice e non nelle mani. Se
## da nessun punto il raggio trova la manopola, la sonda lo dice.
##
## LE DOMANDE:
##    0. il negozio la vende
##    1. senza possesso non c'è: invisibile e senza collisione
##    2. comprandola compare, e non sta dentro il bancone
##    3. sui fuochi non c'è più una moka disegnata
##    4. la si prende
##    5. vicino ai fuochi la riga dice «Metti la moka sul fuoco», ed E ce la mette
##    6. la manopola si mira e accende il fuoco giusto
##    7. sul fuoco acceso il caffè sale: tre tazze, e la coppia C4 si apre una volta
##    8. ripresa, guardando una tazza vuota la riga dice «Versa», ed E versa
##    9. la tazza piena si prende e col destro si beve, e la coppia C4 si chiude
##   10. una tazza piena lanciata si svuota
##   11. la casa se ne ricorda: le dosi nella moka, il fuoco spento, la tazza vuota
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_moka.tscn
extends Node

## La griglia dei posti da cui provare a guardare qualcosa, e quanto lontano.
const PASSO := 0.2
const INTORNO := 6

## Il corpo della moka per la domanda 2, meno un paio di millimetri di franco.
const CORPO_ALTO := 0.198
const CORPO_LARGO := 0.089

var _guasti := 0
var _aperte := 0
var _chiuse := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[moka] GUASTO: " + msg)


func _ok(msg: String) -> void:
	print("[moka] ok: " + msg)


func _prova() -> void:
	Events.wait_activity_started.connect(func(w: StringName) -> void:
		if w == Moka.ACTIVITY:
			_aperte += 1
	)
	Events.wait_activity_ended.connect(func(w: StringName) -> void:
		if w == Moka.ACTIVITY:
			_chiuse += 1
	)
	if Game.partita != SaveManager.PARTITA_SONDE:
		_guasto("la sonda gira sulla partita «%s», non su quella delle sonde" % Game.partita)

	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 30:
		await get_tree().physics_frame

	var moka := Moka.find_in(get_tree())
	var giocatore := Player.find_in(get_tree())
	var tazza := _cosa("TazzaCucina") as Tazza
	var fornelli: Array[Fornello] = []
	for n in get_tree().get_nodes_in_group(Fornello.GROUP):
		fornelli.append(n as Fornello)
	# PER NOME COME STRINGA: fra due `StringName` il minore non è l'alfabetico, e con
	# l'ordine sbagliato «il secondo fuoco» era il terzo.
	fornelli.sort_custom(func(a: Fornello, b: Fornello) -> bool:
		return String(a.name) < String(b.name))
	if moka == null or giocatore == null or tazza == null or fornelli.size() != 4:
		print("[moka] manca qualcosa: moka %s, giocatore %s, tazza %s, fornelli %d"
			% [moka != null, giocatore != null, tazza != null, fornelli.size()])
		get_tree().quit(1)
		return

	# --- 0. IL NEGOZIO LA VENDE --------------------------------------------
	var catalogo := load("res://data/catalog/catalog.tres") as ItemCatalog
	var sigle := PackedStringArray()
	for it in catalogo.for_category(&"personal"):
		sigle.append(String(it.id))
	if not sigle.has("moka"):
		_guasto("il terminale non vende la moka: in PERSONAL c'è {%s}" % ", ".join(sigle))
	else:
		_ok("il negozio la vende")

	# --- 1. SENZA POSSESSO NON C'È -----------------------------------------
	if moka.visible or moka.collision_layer != 0:
		_guasto("la moka c'è senza averla comprata: visibile %s, layer %d"
			% [moka.visible, moka.collision_layer])
	else:
		_ok("senza averla comprata non c'è")

	# --- 2. COMPRANDOLA COMPARE --------------------------------------------
	var da_spenta := moka.global_position
	Game.profile.mark_owned(Moka.ITEM)
	Events.item_purchased.emit(Moka.ITEM)
	for _i in 3:
		await get_tree().physics_frame
	if not moka.visible or moka.collision_layer == 0:
		_guasto("comprata, la moka non compare")
	else:
		_ok("comprata, compare a %s" % _v(moka.global_position))
	# SI GUARDA DOVE SI FERMA, non dove compare: adesso è un corpo che cade, e un bancone
	# che non la regge si vede solo lasciandola un secondo. Si misura anche il piano sotto
	# di lei, così un «dentro il mobile» dice di quanto e perché.
	for _i in 60:
		await get_tree().physics_frame
	var giu_moka := PhysicsRayQueryParameters3D.create(moka.global_position + Vector3.UP * 0.5,
		moka.global_position - Vector3.UP * 0.5)
	giu_moka.collision_mask = Corazza.LAYER_APPOGGI
	giu_moka.exclude = [moka.get_rid()]
	var piano := giocatore.get_world_3d().direct_space_state.intersect_ray(giu_moka)
	print("[moka] spenta stava a quota %.3f; comprata, dopo un secondo sta a %.3f, e il piano sotto è a %s"
		% [da_spenta.y, moka.global_position.y,
			"%.3f" % (piano["position"] as Vector3).y if not piano.is_empty() else "niente"])
	_nel_mobile(moka, giocatore)

	# --- 3. SUI FUOCHI NON C'È PIÙ UNA MOKA DISEGNATA ----------------------
	#
	# Si scende col raggio sul centro di ogni bruciatore, sulla geometria che si vede: la
	# prima cosa che si incontra dev'essere il bruciatore, a filo della griglia, non la
	# cima di una caffettiera venti centimetri più su.
	var spazio := giocatore.get_world_3d().direct_space_state
	var alti := 0
	for f in fornelli:
		var giu := PhysicsRayQueryParameters3D.create(f.centro() + Vector3.UP * 0.5,
			f.centro() - Vector3.UP * 0.1)
		giu.collision_mask = Corazza.LAYER_APPOGGI
		giu.exclude = [moka.get_rid()]
		var colpo := spazio.intersect_ray(giu)
		if colpo.is_empty():
			_guasto("%s: sotto il fuoco non c'è niente — il bruciatore non sta dove dice" % f.name)
		elif (colpo["position"] as Vector3).y > f.centro().y + 0.02:
			alti += 1
			_guasto("%s: sul fuoco c'è qualcosa alto %.0f cm" % [f.name,
				((colpo["position"] as Vector3).y - f.centro().y) * 100.0])
	if alti == 0:
		_ok("sui quattro fuochi non c'è niente sopra la griglia")

	# --- 4. LA SI PRENDE ---------------------------------------------------
	if not await _mettiti(giocatore, moka.global_position + Vector3.UP * 0.1,
			func() -> bool: return giocatore.mirato() == moka):
		_guasto("da nessun punto il raggio trova la moka sul bancone")
		_fine()
		return
	await _premi(giocatore, &"interact")
	if giocatore.tenuto() != moka:
		_guasto("E sulla moka non la prende")
		_fine()
		return
	_ok("presa")

	# --- 5. SUL FUOCO -------------------------------------------------------
	var fuoco := fornelli[1]
	var sul_fuoco := func() -> bool:
		return moka.prompt_posa() == "Metti la moka sul fuoco" \
			and Fornello.guardato(get_tree(), moka.punto_mirato(), Moka.PORTATA_FUOCO) == fuoco
	if not await _mettiti(giocatore, fuoco.centro(), sul_fuoco, moka):
		_guasto("da nessun punto la riga dice «Metti la moka sul fuoco» sopra %s" % fuoco.name)
		_fine()
		return
	await _premi(giocatore, &"interact")
	await _aspetta(func() -> bool: return false, 1.0)
	if Fornello.sotto_a(get_tree(), moka.global_position) != fuoco:
		_guasto("E non l'ha messa sul fuoco: sta a %s, il fuoco a %s"
			% [_v(moka.global_position), _v(fuoco.centro())])
		_fine()
		return
	_ok("sul fuoco, e ci resta: %s" % _v(moka.global_position))

	# --- 6. LA MANOPOLA ------------------------------------------------------
	if not await _mettiti(giocatore, fuoco.global_position,
			func() -> bool: return giocatore.focus() == fuoco):
		_guasto("da nessun punto il raggio trova la manopola di %s" % fuoco.name)
		_fine()
		return
	await _premi(giocatore, &"interact")
	if not fuoco.acceso:
		_guasto("E sulla manopola non accende il fuoco")
		_fine()
		return
	var altri_accesi := fornelli.filter(func(f: Fornello) -> bool: return f != fuoco and f.acceso)
	if not altri_accesi.is_empty():
		_guasto("la manopola ha acceso anche un altro fuoco")
	_ok("la manopola accende %s" % fuoco.name)

	# --- 7. IL CAFFÈ SALE ----------------------------------------------------
	#
	# A otto volte il tempo: quaranta secondi di gioco sono cinque di sonda. Il tempo si
	# rimette a posto comunque, anche se il caffè non sale.
	# CON LO STRUMENTO DI F1–F4, che alza anche i passi di fisica: scrivendo solo
	# `Engine.time_scale` il passo si allunga e la moka rimbalza giù dal fuoco (D-245).
	var tempo: GDScript = load("res://debug/time_control.gd")
	tempo.accelera(8.0)
	var salito := await _aspetta(func() -> bool: return moka.dosi == Moka.TAZZINE, 12.0)
	tempo.accelera(1.0)
	if not salito:
		_guasto("dopo %.0f secondi di gioco sul fuoco acceso il caffè non è salito: cottura %.2f"
			% [12.0 * 8.0, moka.cottura])
		_fine()
		return
	_ok("il caffè è salito: %d tazze" % moka.dosi)
	if _aperte != 1:
		_guasto("la coppia C4 si è aperta %d volte, non una" % _aperte)
	await _mettiti(giocatore, fuoco.global_position,
		func() -> bool: return giocatore.focus() == fuoco)
	await _premi(giocatore, &"interact")
	if fuoco.acceso:
		_guasto("il fuoco non si spegne")

	# --- 8. VERSARE ---------------------------------------------------------
	if not await _mettiti(giocatore, moka.global_position + Vector3.UP * 0.1,
			func() -> bool: return giocatore.mirato() == moka):
		_guasto("la moka sul fuoco non si riprende")
		_fine()
		return
	await _premi(giocatore, &"interact")
	if not await _mettiti(giocatore, tazza.bocca(),
			func() -> bool: return giocatore.bersaglio_mano() == tazza, moka):
		_guasto("con la moka in mano, da nessun punto guardare la tazza fa versare")
		_fine()
		return
	var riga := _riga(giocatore)
	if not riga.contains("Versa"):
		_guasto("guardando la tazza la riga dice «%s»" % riga)
	print("[moka] si versa stando a %s, la tazza a %s" % [_v(giocatore.global_position),
		_v(tazza.global_position)])
	await _premi(giocatore, &"interact")
	# IL GESTO SI GUARDA MENTRE SUCCEDE: se il caffè non arriva, la domanda è dove si è
	# fermata la moka, e contro cosa. Un campione ogni quarto di secondo.
	var campioni := 0
	while moka.in_gesto() and campioni < 24:
		for _i in 15:
			await get_tree().physics_frame
		campioni += 1
		var becco := moka.global_transform * Moka.BECCO
		var scarto := Vector2(becco.x - tazza.bocca().x, becco.z - tazza.bocca().z).length()
		var tocca := PackedStringArray()
		for corpo in moka.get_colliding_bodies():
			tocca.append(String(corpo.name))
		print("[moka]   t %.2f  becco a %.1f cm dalla bocca (in pianta), %.1f cm sopra; moka a %.1f cm da dove la vuole la mano; tocca {%s}"
			% [moka._versa_t, scarto * 100.0, (becco.y - tazza.bocca().y) * 100.0,
				moka.global_position.distance_to(moka._mano.origin) * 100.0, ", ".join(tocca)])
	if tazza.livello < 0.99 or moka.dosi != Moka.TAZZINE - 1:
		_guasto("dopo il gesto la tazza è a %.2f e nella moka restano %d dosi"
			% [tazza.livello, moka.dosi])
	else:
		_ok("versato: tazza piena, nella moka restano %d dosi" % moka.dosi)

	# --- 9. BERE ------------------------------------------------------------
	await _premi(giocatore, &"interact")
	if giocatore.tenuto() != null:
		_guasto("con la tazza già piena E non posa la moka")
	await _aspetta(func() -> bool: return false, 1.0)
	if not await _mettiti(giocatore, tazza.global_position + Vector3.UP * 0.03,
			func() -> bool: return giocatore.mirato() == tazza):
		_guasto("la tazza piena non si riprende")
		_fine()
		return
	await _premi(giocatore, &"interact")
	await _aspetta(func() -> bool: return false, 0.3)
	riga = _riga(giocatore)
	if not riga.contains("[DESTRO]"):
		_guasto("con la tazza piena in mano la riga non dice del destro: «%s»" % riga)
	await _premi(giocatore, &"usa")
	await _aspetta(func() -> bool: return not tazza.in_gesto(), 5.0)
	if not tazza.vuota():
		_guasto("dopo aver bevuto la tazza è ancora a %.2f" % tazza.livello)
	elif _chiuse != 1:
		_guasto("bevuto, ma la coppia C4 si è chiusa %d volte" % _chiuse)
	else:
		_ok("bevuto, e la coppia C4 si chiude")

	# --- 10. LANCIATA PIENA SI SVUOTA ----------------------------------------
	if giocatore.tenuto() == tazza:
		tazza.riempi_a(1.0)
		var avanti := -giocatore.camera().global_basis.z
		tazza.lancia(avanti + Vector3.UP * 0.3, giocatore.velocity)
		await _aspetta(func() -> bool: return false, 2.5)
		if not tazza.vuota():
			_guasto("lanciata piena, la tazza è ancora a %.2f" % tazza.livello)
		else:
			_ok("lanciata piena, si è svuotata")
	else:
		_guasto("la tazza non era più in mano per lanciarla")

	# --- 11. LA CASA SE NE RICORDA -------------------------------------------
	await _aspetta(func() -> bool: return false, 3.0)
	var file := SaveManager.SAVES_DIR.path_join(SaveManager.PARTITA_SONDE) \
		.path_join(SaveManager.WORLD_FILE)
	var mondo := SaveManager.new().load_world(file)
	var voce_moka: Dictionary = mondo.oggetti.get("Moka", {})
	var voce_fuoco: Dictionary = mondo.oggetti.get(String(fuoco.name), {})
	if int(voce_moka.get(&"dosi", -1)) != Moka.TAZZINE - 1:
		_guasto("nel file la moka ha %s dosi" % voce_moka.get(&"dosi", "nessuna voce"))
	elif voce_fuoco.is_empty() or bool(voce_fuoco.get(&"acceso", true)):
		_guasto("nel file %s non risulta spento: %s" % [fuoco.name, voce_fuoco])
	else:
		_ok("la casa ricorda %d dosi nella moka e il fuoco spento" % voce_moka[&"dosi"])
	_fine()


func _fine() -> void:
	Engine.time_scale = 1.0
	print("[moka] %d guasti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)


func _v(p: Vector3) -> String:
	return "%.2f, %.2f, %.2f" % [p.x, p.y, p.z]


func _cosa(nome: String) -> Carryable:
	for n in get_tree().get_nodes_in_group(Carryable.GROUP):
		if n.name == nome:
			return n as Carryable
	return null


func _riga(giocatore: Player) -> String:
	return (giocatore.get_node(^"%InteractionPrompt") as InteractionPrompt).riga()


## Un tasto, come lo riceve il giocatore. Si passa dal suo `_unhandled_input` e non dal
## viewport: la domanda è cosa fa il giocatore con E, non se Godot consegna gli eventi.
func _premi(giocatore: Player, azione: StringName) -> void:
	var giu := InputEventAction.new()
	giu.action = azione
	giu.pressed = true
	giocatore._unhandled_input(giu)
	await get_tree().physics_frame
	var su := InputEventAction.new()
	su.action = azione
	su.pressed = false
	giocatore._unhandled_input(su)
	await get_tree().physics_frame


## Aspetta che `condizione` sia vera, al massimo `secondi` di orologio.
func _aspetta(condizione: Callable, secondi: float) -> bool:
	var fine := Time.get_ticks_msec() + int(secondi * 1000.0)
	while Time.get_ticks_msec() < fine:
		if condizione.call():
			return true
		await get_tree().physics_frame
	return condizione.call()


## Mette il giocatore in piedi in un posto da cui guarda `guarda` e `va_bene` risponde sì,
## provando i posti più vicini per primi. Se tiene qualcosa, glielo rimette in mano: un
## oggetto tenuto non si teletrasporta col giocatore, lo insegue, e dall'altra parte della
## cucina resterebbe impigliato nel bancone.
func _mettiti(giocatore: Player, guarda: Vector3, va_bene: Callable,
		tenuto: Carryable = null) -> bool:
	var piedi := Vector3(guarda.x, 0.0, guarda.z)
	var punti: Array[Vector3] = []
	for dx in range(-INTORNO, INTORNO + 1):
		for dz in range(-INTORNO, INTORNO + 1):
			var p := piedi + Vector3(dx * PASSO, 0.0, dz * PASSO)
			var d := p.distance_to(piedi)
			if d >= 0.3 and d <= 1.2:
				punti.append(p)
	punti.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return a.distance_to(piedi) < b.distance_to(piedi))
	# MENTRE SI CERCA, QUELLO CHE SI TIENE NON URTA NIENTE: a ogni posto provato gli si
	# rimette la mano, e la mano passa anche sopra il tavolo — la prima corsa di questa sonda
	# ha rovesciato la tazza a forza di cercare da dove guardarla. Alla fine torna com'era.
	var maschera := tenuto.collision_mask if tenuto != null else 0
	if tenuto != null:
		tenuto.collision_mask = 0
	var trovato := false
	for p in punti:
		if _dentro_qualcosa(giocatore, p):
			continue
		giocatore.velocity = Vector3.ZERO
		giocatore.global_position = p
		giocatore.look_at(Vector3(guarda.x, p.y, guarda.z), Vector3.UP)
		giocatore.camera().look_at(guarda, Vector3.UP)
		if tenuto != null:
			tenuto.global_transform = giocatore._trasformata_mano()
			tenuto.linear_velocity = Vector3.ZERO
		for _i in 4:
			await get_tree().physics_frame
		if va_bene.call():
			trovato = true
			break
	if tenuto != null:
		tenuto.collision_mask = maschera
		tenuto.global_transform = giocatore._trasformata_mano()
		tenuto.linear_velocity = Vector3.ZERO
		for _i in 2:
			await get_tree().physics_frame
	return trovato


## Il corpo della moka interseca qualcosa di solido? Sulla geometria che si vede, sollevato
## di mezzo centimetro perché appoggiare è toccare. Si esclude la moka stessa: adesso sta
## anche lei sul layer degli appoggi, come tutto quello che si prende in mano.
func _nel_mobile(moka: Moka, giocatore: Player) -> void:
	var forma := BoxShape3D.new()
	forma.size = Vector3(CORPO_LARGO, CORPO_ALTO, CORPO_LARGO)
	var par := PhysicsShapeQueryParameters3D.new()
	par.shape = forma
	par.transform = Transform3D(Basis.IDENTITY,
		moka.global_position + Vector3(0, CORPO_ALTO / 2.0 + 0.005, 0))
	par.collision_mask = Corazza.LAYER_APPOGGI
	par.exclude = [giocatore.get_rid(), moka.get_rid()]
	par.margin = 0.0
	var dentro := giocatore.get_world_3d().direct_space_state.intersect_shape(par, 4)
	if dentro.is_empty():
		_ok("sta sul bancone, non dentro")
		return
	var chi := PackedStringArray()
	for d in dentro:
		var n := d.get("collider") as Node
		chi.append(String(n.name) if n != null else "?")
	_guasto("la moka è dentro qualcosa: %s" % ", ".join(chi))


## Se il corpo del giocatore, messo lì, sarebbe dentro qualcosa. Sollevato di cinque
## centimetri: il fondo della capsula tocca il pavimento, e un contatto tangente conta.
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
