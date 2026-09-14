## LA CASA SI RICORDA? Si sposta una tazza, si aspetta, e si guarda se il file lo sa; poi
## si rimonta la scena da capo — come un riavvio — e si guarda se la tazza è tornata dove
## la si era lasciata invece che dove la mette la scena (D-243).
##
## LE DOMANDE:
##   1. LA SONDA GIRA SULLA PARTITA DELLE SONDE, e la trova vuota. Se girasse sulla vera,
##      ogni prova sposterebbe le tazze di Federico.
##   2. UNA COSA SPOSTATA FINISCE NEL FILE, da sola, qualche secondo dopo essersi fermata.
##   3. RIMONTANDO LA SCENA LA COSA È DOVE LA SI ERA LASCIATA, letta dal file.
##   4. UNA COSA MAI TOCCATA RESTA DOVE LA METTE LA SCENA.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_memoria.tscn
extends Node

var _guasti := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[memoria] GUASTO: " + msg)


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


func _prova() -> void:
	# --- 1. LA PARTITA DELLE SONDE ------------------------------------------
	print("[memoria] partita «%s»" % Game.partita)
	if Game.partita != SaveManager.PARTITA_SONDE:
		_guasto("la sonda gira sulla partita «%s», non su quella delle sonde" % Game.partita)
	if not Game.mondo.oggetti.is_empty():
		_guasto("la partita delle sonde non parte vuota: %d voci" % Game.mondo.oggetti.size())

	var scena: Node = await _monta()
	var tazza := _cosa("TazzaCucina")
	var termos := _cosa("Termos")
	if tazza == null or termos == null:
		print("[memoria] la tazza o il termos non ci sono: la prova non vale")
		get_tree().quit(1)
		return
	var termos_scena := termos.global_position

	# --- 2. SPOSTATA, FINISCE NEL FILE --------------------------------------
	#
	# Venti centimetri più in là sullo stesso tavolo, un dito sopra, con una spinta verso
	# il basso: cade, si ferma, e non c'è nessuno a chiamare niente. È la tazza a dover
	# accorgersi di essersi mossa.
	# SI ASPETTA CHE LA CASA SI SIA ASSESTATA: all'avvio le cose cadono del millimetro che le
	# separa dai piani, e quella prima fermata la memoria la scarta apposta (D-243). Spinta
	# prima, la tazza si confonderebbe con l'assestamento — cosa che a un giocatore, che non
	# tocca niente nel primo secondo, non succede.
	await get_tree().create_timer(1.5).timeout
	var prima := tazza.global_position
	tazza.global_position = prima + Vector3(0.20, 0.03, 0.0)
	tazza.linear_velocity = Vector3(0.0, -0.3, 0.0)
	await get_tree().create_timer(4.0).timeout
	var lasciata := tazza.global_position
	print("[memoria] la tazza stava a %s, adesso a %s" % [_v(prima), _v(lasciata)])

	var file := SaveManager.SAVES_DIR.path_join(SaveManager.PARTITA_SONDE) \
		.path_join(SaveManager.WORLD_FILE)
	if not FileAccess.file_exists(file):
		_guasto("dopo quattro secondi %s non esiste: la tazza si è mossa e nessuno l'ha scritto" % file)
		_fine()
		return
	var letto := SaveManager.new().load_world(file)
	var voce: Dictionary = letto.oggetti.get("TazzaCucina", {})
	if voce.is_empty():
		_guasto("nel file non c'è la tazza: %s" % ", ".join(letto.oggetti.keys()))
	else:
		var xf: Transform3D = voce[&"xf"]
		var scarto := xf.origin.distance_to(lasciata)
		print("[memoria] nel file la tazza sta a %s (%.1f cm da dov'è)" % [_v(xf.origin), scarto * 100.0])
		if scarto > 0.02:
			_guasto("il file ricorda la tazza a %.1f cm da dov'è davvero" % (scarto * 100.0))
		else:
			print("[memoria] ok: la tazza spostata è finita nel file da sola")

	# --- 3. RIMONTATA, È DOVE LA SI ERA LASCIATA ----------------------------
	#
	# COME UN RIAVVIO: la scena se ne va, `Game` rilegge dal disco, la scena torna. Si
	# rilegge il file e non si riusa `Game.mondo` così com'è, perché quello è la memoria
	# del processo: un riavvio vero ha solo il disco.
	scena.queue_free()
	await get_tree().process_frame
	Game.mondo = SaveManager.new().load_world(file)
	await _monta()
	tazza = _cosa("TazzaCucina")
	termos = _cosa("Termos")
	var ritrovata := tazza.global_position
	var scarto_tazza := ritrovata.distance_to(lasciata)
	print("[memoria] rimontata la scena, la tazza sta a %s (%.1f cm da dove era stata lasciata)"
		% [_v(ritrovata), scarto_tazza * 100.0])
	if scarto_tazza > 0.03:
		_guasto("la tazza non è tornata dove era stata lasciata: sta a %.1f cm" % (scarto_tazza * 100.0))
	elif ritrovata.distance_to(prima) < 0.10:
		_guasto("la tazza è tornata al posto della scena, non a quello lasciato")
	else:
		print("[memoria] ok: la tazza è dove la si era lasciata")

	# --- 4. MAI TOCCATO, RESTA DOVE LO METTE LA SCENA -----------------------
	#
	# E NEL FILE NON C'È: all'avvio le cose cadono del millimetro che le separa dai piani, e
	# la prima stesura lo scambiava per uno spostamento — il file si riempiva di tutto.
	if letto.oggetti.has("Termos"):
		_guasto("nel file c'è il termos, che nessuno ha toccato: %s" % ", ".join(letto.oggetti.keys()))
	else:
		print("[memoria] ok: nel file c'è solo quello che è stato toccato: %s"
			% ", ".join(letto.oggetti.keys()))
	var scarto_termos := termos.global_position.distance_to(termos_scena)
	if scarto_termos > 0.03:
		_guasto("il termos, mai toccato, si è spostato di %.1f cm" % (scarto_termos * 100.0))
	else:
		print("[memoria] ok: il termos, mai toccato, è dove lo mette la scena")
	_fine()


func _fine() -> void:
	print("[memoria] %d guasti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)


func _v(p: Vector3) -> String:
	return "%.2f, %.2f, %.2f" % [p.x, p.y, p.z]
