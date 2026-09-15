## IL MOCIO PULISCE? Si lancia una tazza piena, si guarda dov'è finito il caffè, si va a prendere
## il mocio in magazzino e lo si passa sulla macchia tenendo il destro (D-251).
##
## CON LE MANI DEL GIOCATORE dove conta, come `prova_moka.gd`: il suo raggio e il suo E per
## prendere, il suo destro tenuto e mollato per pulire. Il lancio no: `prova_moka.gd` lancia la
## tazza chiamando `lancia()`, e qui interessa dove va il caffè, non la barra del sinistro.
##
## LE DOMANDE:
##    0. la sonda gira sulla partita delle sonde
##    1. il mocio sta in magazzino, appoggiato al muro, e dopo cinque secondi è ancora lì
##    2. una tazza piena lanciata lascia una macchia sola, per terra, grande quanto uno schizzo
##    3. la casa se ne ricorda: nel file c'è, e rimontando la scena la macchia torna dov'era
##    4. il mocio si prende col raggio del giocatore
##    5. da in piedi, guardando la macchia, la riga offre il destro: il mocio arriva a terra
##    6. col destro tenuto le frange vanno sulla macchia, e in pochi secondi non c'è più; il gesto
##       continua finché il destro è giù (D-252)
##    7. mollato il destro, il mocio torna in mano
##    8. la casa se ne ricorda: nel file non ci sono più macchie
##    9. si pulisce anche dove non c'è niente: sul pavimento nudo la riga offre il destro, e le
##       frange vanno a terra (D-252)
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_mocio.tscn
extends Node

## La griglia dei posti da cui provare a guardare qualcosa, come in `prova_moka.gd`.
const PASSO := 0.2
const INTORNO := 6

## Il magazzino netto fra i muri, in pianta: `SALA_MAGAZZINO` in `geometria.py`.
const MAGAZZINO := Rect2(3.45, 6.60, 1.35, 2.80)

var _guasti := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[mocio] GUASTO: " + msg)


func _ok(msg: String) -> void:
	print("[mocio] ok: " + msg)


func _prova() -> void:
	# --- 0. LA PARTITA DELLE SONDE ------------------------------------------------
	if Game.partita != SaveManager.PARTITA_SONDE:
		_guasto("la sonda gira sulla partita «%s», non su quella delle sonde" % Game.partita)
	var scena: Node = await _monta()
	var giocatore := Player.find_in(get_tree())
	var mocio := Mocio.find_in(get_tree())
	if mocio == null:
		_guasto("in scena non c'è il mocio")
		_fine()
		return

	# --- 1. IN MAGAZZINO, APPOGGIATO, E CI RESTA -----------------------------------
	var p0 := mocio.global_position
	await get_tree().create_timer(5.0).timeout
	var pende := rad_to_deg(acos(clampf(mocio.global_basis.y.dot(Vector3.UP), -1.0, 1.0)))
	var scivolato := mocio.global_position.distance_to(p0)
	print("[mocio] in magazzino a %s, pende di %.1f gradi, in cinque secondi si è mosso di %.1f cm"
		% [_v(mocio.global_position), pende, scivolato * 100.0])
	if not MAGAZZINO.has_point(Vector2(p0.x, p0.z)):
		_guasto("il mocio non sta in magazzino")
	elif scivolato > 0.03 or pende > 20.0:
		_guasto("il mocio non sta appoggiato: è scivolato o caduto")
	else:
		_ok("il mocio sta in magazzino appoggiato al muro, e ci resta")

	# --- 2. LA TAZZA LANCIATA LASCIA LA MACCHIA ------------------------------------
	var tazza := _cosa("TazzaCucina") as Tazza
	tazza.riempi_a(1.0)
	var vista := await _mettiti(giocatore, tazza._centro(),
		func() -> bool: return giocatore.mirato() == tazza)
	if not vista:
		_guasto("la tazza della cucina non si mira da nessun posto")
		_fine()
		return
	await _premi(giocatore, &"interact")
	if giocatore.tenuto() != tazza:
		_guasto("E non ha preso la tazza")
		_fine()
		return
	var bersaglio: Vector3 = await _lancio_libero(giocatore, tazza)
	if bersaglio == Vector3.INF:
		_guasto("in cucina non c'è un posto da cui lanciarla verso il pavimento libero")
		_fine()
		return
	var partenza := tazza.global_position
	tazza.lancia(bersaglio - tazza.global_position, Vector3.ZERO)
	var nata := await _aspetta(func() -> bool: return _macchie().size() > 0, 4.0)
	await get_tree().create_timer(0.5).timeout
	var macchie := _macchie()
	if not nata:
		_guasto("lanciata piena, per terra non c'è nessuna macchia (tazza a %.2f)" % tazza.livello)
		_fine()
		return
	var macchia := macchie[0]
	var atteso := Macchia.raggio_per(1.0, true)
	print("[mocio] lanciata da %s verso %s: %d macchia a %s, raggio %.1f cm, normale %s"
		% [_v(partenza), _v(bersaglio), macchie.size(), _v(macchia.global_position),
			macchia.raggio * 100.0, _v(macchia.global_basis.y)])
	# SE LA MACCHIA STA SOTTO LA MANO, la tazza si è rovesciata al primo passo: il lancio non è
	# mai partito.
	if Vector2(macchia.global_position.x - partenza.x, macchia.global_position.z - partenza.z).length() < 0.2:
		_guasto("la macchia sta sotto la mano: la tazza si è rovesciata prima di volare")
	if macchie.size() != 1:
		_guasto("una tazza ha fatto %d macchie" % macchie.size())
	if not tazza.vuota():
		_guasto("la macchia c'è ma la tazza è ancora piena")
	if macchia.global_position.y > 0.10 or macchia.global_basis.y.dot(Vector3.UP) < 0.95:
		_guasto("la macchia non sta per terra")
	elif not is_equal_approx(macchia.raggio, atteso):
		_guasto("raggio %.3f invece di %.3f, quello di uno schizzo" % [macchia.raggio, atteso])
	else:
		_ok("la tazza lanciata ha lasciato una macchia per terra, grande quanto uno schizzo")

	# --- 3. LA CASA SE NE RICORDA ------------------------------------------------------
	var dove := macchia.global_position
	await get_tree().create_timer(3.0).timeout
	var file := SaveManager.SAVES_DIR.path_join(SaveManager.PARTITA_SONDE) \
		.path_join(SaveManager.WORLD_FILE)
	var letto := SaveManager.new().load_world(file)
	if letto.macchie.size() != 1:
		_guasto("nel file ci sono %d macchie invece di una" % letto.macchie.size())
	scena.queue_free()
	await get_tree().process_frame
	Game.mondo = SaveManager.new().load_world(file)
	scena = await _monta()
	giocatore = Player.find_in(get_tree())
	mocio = Mocio.find_in(get_tree())
	macchie = _macchie()
	if macchie.size() != 1:
		_guasto("rimontata la scena ci sono %d macchie invece di una" % macchie.size())
		_fine()
		return
	macchia = macchie[0]
	var scarto := macchia.global_position.distance_to(dove)
	print("[mocio] rimontata la scena, la macchia è a %.1f cm da dov'era" % (scarto * 100.0))
	if scarto > 0.01 or not is_equal_approx(macchia.raggio, atteso):
		_guasto("la macchia non è tornata com'era")
	else:
		_ok("la casa si ricorda la macchia")

	# --- 4. IL MOCIO SI PRENDE -----------------------------------------------------------
	var mirato := await _mettiti(giocatore, mocio._centro(),
		func() -> bool: return giocatore.mirato() == mocio)
	if mirato:
		await _premi(giocatore, &"interact")
	if giocatore.tenuto() != mocio:
		_guasto("il mocio non si prende (mirato da qualche posto: %s)" % mirato)
		_fine()
		return
	_ok("il mocio si prende")

	# --- 5. DA IN PIEDI LA RIGA OFFRE IL DESTRO --------------------------------------
	var y_macchia := macchia.global_position.y
	# SULLA MACCHIA, NON SOLO SUL PAVIMENTO: da quando il mocio pulisce dovunque (D-252) il destro
	# lo offre ogni pezzo di pavimento, e senza la seconda domanda la sonda si fermerebbe al primo.
	var da_pulire := await _mettiti(giocatore, macchia.global_position,
		func() -> bool: return mocio.puo_usare() \
			and Macchia.sotto(get_tree(), mocio.sguardo(), Mocio.RAGGIO_FRANGE) != null, mocio)
	var riga: String = giocatore._prompt.riga()
	var lontano := Vector2(giocatore.global_position.x - macchia.global_position.x,
		giocatore.global_position.z - macchia.global_position.z).length()
	print("[mocio] in piedi a %.2f m dalla macchia, occhio a %.2f: «%s»"
		% [lontano, giocatore.camera().global_position.y, riga])
	if not da_pulire:
		_guasto("da nessun posto in piedi il mocio arriva sulla macchia")
		_fine()
		return
	if not riga.contains("[DESTRO]"):
		_guasto("il mocio arriva sulla macchia ma la riga non offre il destro")
	else:
		_ok("da in piedi la riga offre il destro")

	# --- 6. COL DESTRO TENUTO LA MACCHIA SE NE VA -------------------------------------
	var giu := InputEventAction.new()
	giu.action = &"usa"
	giu.pressed = true
	giocatore._unhandled_input(giu)
	await get_tree().physics_frame
	if not mocio.in_gesto():
		_guasto("il destro non ha fatto cominciare a pulire")
	var basso := INF
	var inizio := Time.get_ticks_msec()
	var pulita := false
	while Time.get_ticks_msec() - inizio < 12000:
		await get_tree().physics_frame
		basso = minf(basso, mocio.global_position.y - y_macchia)
		if _macchie().is_empty():
			pulita = true
			break
	var secondi := (Time.get_ticks_msec() - inizio) / 1000.0
	print("[mocio] frange scese fino a %.1f cm dalla macchia; pulita %s in %.1f s"
		% [basso * 100.0, pulita, secondi])
	if basso > 0.05:
		_guasto("le frange non sono arrivate a terra")
	if not pulita:
		_guasto("dopo dodici secondi di destro la macchia è ancora lì")
	else:
		_ok("col destro tenuto la macchia se n'è andata")
	for _i in 10:
		await get_tree().physics_frame
	if not mocio.in_gesto():
		_guasto("pulita la macchia il gesto si è fermato, col destro ancora giù")
	else:
		_ok("pulita la macchia, col destro giù si continua a pulire")

	# --- 7. MOLLATO, TORNA IN MANO -------------------------------------------------------
	var su := InputEventAction.new()
	su.action = &"usa"
	su.pressed = false
	giocatore._unhandled_input(su)
	for _i in 60:
		await get_tree().physics_frame
	var presa := giocatore._trasformata_mano()
	var dalla_mano := mocio.global_position.distance_to(presa.origin - presa.basis.y * Mocio.PRESA)
	if mocio.in_gesto() or giocatore.tenuto() != mocio or dalla_mano > 0.3:
		_guasto("mollato il destro il mocio non è tornato in mano (a %.2f m)" % dalla_mano)
	else:
		_ok("mollato il destro il mocio è tornato in mano")

	# --- 8. E LA CASA SE NE RICORDA ----------------------------------------------------
	await get_tree().create_timer(3.0).timeout
	letto = SaveManager.new().load_world(file)
	if not letto.macchie.is_empty():
		_guasto("pulita la macchia, nel file ce ne sono ancora %d" % letto.macchie.size())
	else:
		_ok("nel file non ci sono più macchie")

	# --- 9. ANCHE DOVE NON C'È NIENTE ------------------------------------------------------
	#
	# Lo sguardo è ancora dove stava la macchia, e adesso lì c'è solo pavimento.
	for _i in 4:
		await get_tree().physics_frame
	riga = giocatore._prompt.riga()
	if not _macchie().is_empty() or not mocio.puo_usare() or not riga.contains("[DESTRO]"):
		_guasto("sul pavimento nudo il destro non si offre: «%s»" % riga)
	else:
		giocatore._unhandled_input(giu)
		basso = INF
		for _i in 90:
			await get_tree().physics_frame
			basso = minf(basso, mocio.global_position.y - y_macchia)
		var pulendo := mocio.in_gesto()
		giocatore._unhandled_input(su)
		print("[mocio] sul pavimento nudo: frange scese fino a %.1f cm, gesto in corso %s"
			% [basso * 100.0, pulendo])
		if not pulendo or basso > 0.05:
			_guasto("sul pavimento nudo il mocio non va a terra")
		else:
			_ok("si pulisce anche dove non c'è niente")
	_fine()


func _fine() -> void:
	print("[mocio] %d guasti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)


func _monta() -> Node:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 30:
		await get_tree().physics_frame
	return scena


func _cosa(nome: String) -> Carryable:
	for n in get_tree().get_nodes_in_group(Carryable.GROUP):
		if n.name == nome and not n.is_queued_for_deletion():
			return n as Carryable
	return null


func _macchie() -> Array[Macchia]:
	var out: Array[Macchia] = []
	for n in get_tree().get_nodes_in_group(Macchia.GRUPPO):
		if not n.is_queued_for_deletion():
			out.append(n as Macchia)
	return out


## Un posto da cui lanciare la tazza sul pavimento libero, e il punto verso cui lanciarla. Prima
## da dove si è, poi spostandosi, i posti più vicini per primi. LA PRIMA CORSA LANCIAVA DA SOPRA IL
## TAVOLO: la tazza sfiorava il bordo, si rovesciava lì, e il caffè finiva sul piano.
func _lancio_libero(giocatore: Player, tazza: Tazza) -> Vector3:
	var da := giocatore.global_position
	var punti: Array[Vector3] = []
	for dx in range(-10, 11):
		for dz in range(-10, 11):
			var p := da + Vector3(dx * 0.25, 0.0, dz * 0.25)
			if p.distance_to(da) <= 2.5:
				punti.append(p)
	punti.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return a.distance_to(da) < b.distance_to(da))
	var maschera := tazza.collision_mask
	tazza.collision_mask = 0
	var trovato := Vector3.INF
	for p in punti:
		if _dentro_qualcosa(giocatore, p):
			continue
		giocatore.velocity = Vector3.ZERO
		giocatore.global_position = p
		tazza.global_transform = giocatore._trasformata_mano()
		tazza.linear_velocity = Vector3.ZERO
		for _i in 3:
			await get_tree().physics_frame
		trovato = _pavimento_libero(giocatore, tazza, p == punti[punti.size() - 1])
		if trovato != Vector3.INF:
			break
	tazza.collision_mask = maschera
	for _i in 3:
		await get_tree().physics_frame
	return trovato


## Un punto del pavimento verso cui la tazza, dalla mano, arriva senza toccare niente: la mano non
## sta sopra un mobile, fra l'occhio e la mano non c'è un muro, e una sfera larga quanto la tazza
## percorre la strada fino a terra. Sedici direzioni, tre distanze.
func _pavimento_libero(giocatore: Player, tazza: Tazza, racconta := false) -> Vector3:
	var spazio := giocatore.get_world_3d().direct_space_state
	var mano := tazza.global_position
	var sotto := PhysicsRayQueryParameters3D.create(mano, mano + Vector3.DOWN * 3.0)
	sotto.collision_mask = Corazza.LAYER_APPOGGI
	sotto.exclude = [tazza.get_rid()]
	var terra := spazio.intersect_ray(sotto)
	if terra.is_empty() or absf((terra["position"] as Vector3).y - giocatore.global_position.y) > 0.05:
		return Vector3.INF
	var occhio := PhysicsRayQueryParameters3D.create(giocatore.camera().global_position, mano)
	occhio.collision_mask = Corazza.LAYER_APPOGGI
	occhio.exclude = [tazza.get_rid()]
	if not spazio.intersect_ray(occhio).is_empty():
		return Vector3.INF
	var sfera := SphereShape3D.new()
	sfera.radius = 0.07
	var trovati := PackedStringArray()
	for lontano in [1.0, 1.5, 0.7]:
		for k in 16:
			var a := TAU * float(k) / 16.0
			var fin: Vector3 = giocatore.global_position + Vector3(cos(a), 0.0, sin(a)) * lontano
			var q := PhysicsRayQueryParameters3D.create(tazza.global_position, fin + Vector3.DOWN * 0.1)
			q.collision_mask = Corazza.LAYER_APPOGGI
			q.exclude = [tazza.get_rid(), giocatore.get_rid()]
			var colpo := spazio.intersect_ray(q)
			if colpo.is_empty():
				trovati.append("niente")
				continue
			var p: Vector3 = colpo["position"]
			var chi := colpo["collider"] as Node
			if chi is Carryable:
				trovati.append(String(chi.name))
				continue
			if absf(p.y - giocatore.global_position.y) >= 0.05 \
					or Vector2(p.x - fin.x, p.z - fin.z).length() >= 0.15:
				trovati.append("%s a %.2f" % [String(chi.name) if chi != null else "?", p.y])
				continue
			var par := PhysicsShapeQueryParameters3D.new()
			par.shape = sfera
			par.transform = Transform3D(Basis.IDENTITY, mano)
			par.motion = fin + Vector3.DOWN * 0.1 - mano
			par.collision_mask = Corazza.LAYER_APPOGGI
			par.exclude = [tazza.get_rid(), giocatore.get_rid()]
			var frazioni := spazio.cast_motion(par)
			var arrivo: Vector3 = mano + par.motion * frazioni[1]
			if arrivo.y - giocatore.global_position.y < 0.15 \
					and Vector2(arrivo.x - fin.x, arrivo.z - fin.z).length() < 0.3:
				return fin
			trovati.append("sfera ferma a %s" % _v(arrivo))
	if racconta:
		print("[mocio] il giocatore sta a %s, la mano a %s; il raggio ha trovato: %s"
			% [_v(giocatore.global_position), _v(mano), ", ".join(trovati.slice(0, 16))])
	return Vector3.INF


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


## Mette il giocatore in piedi in un posto da cui guarda `guarda` e `va_bene` risponde sì, i più
## vicini per primi; e se tiene qualcosa glielo rimette in mano. È quella di `prova_moka.gd`.
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
		for _i in 2:
			await get_tree().physics_frame
	return trovato


## Se il corpo del giocatore, messo lì, sarebbe dentro qualcosa.
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


func _v(p: Vector3) -> String:
	return "%.2f, %.2f, %.2f" % [p.x, p.y, p.z]
