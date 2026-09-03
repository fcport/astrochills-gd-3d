## UNA COSA CADUTA SI RITROVA. Misurato sul pavimento vero, non sperato.
##
## DA DOVE VIENE. Federico, in partita, con la foto dell'angolo fra la cassettiera
## della stampante e il rack: «mi è caduta la camera qui e l'ho persa per sempre».
## Il registro della sua partita diceva un'altra cosa — «la camera era finita dove
## non ci si arriva (8.09, -0.00, 0.17): rimessa al fuoco» — e tutte e due hanno
## ragione: la rete del D-217 l'aveva salvata, e lui non poteva saperlo. Una
## sparizione silenziosa e un oggetto perduto si giocano nello stesso modo.
##
## COS'ERA, misurato da questa sonda: DIECI METRI QUADRI del pavimento di questa
## casa, in cinquantatre pozze, sono posti da cui una cosa a terra non si riprende
## e in cui una cosa a terra ci può arrivare rotolando. Non sono voragini:
## sono le fessure fra un mobile e il muro e fra due mobili affiancati — il
## giocatore è largo sessanta e il braccio arriva a un metro e venti, una borraccia
## è larga dieci e rotola dove capita. La camera aveva una rete tutta sua; la
## borraccia, il termos e la tazza non avevano niente.
##
## TRE DOMANDE:
##   1. LA MAPPA. Si passa tutto il pavimento a maglia di quindici centimetri e si
##      chiede al gioco — non a una copia della regola — se da lì una cosa si
##      riprenderebbe. È una misura, non un giudizio: le fessure esistono perché
##      esistono i mobili.
##   2. LA PROMESSA. In ognuna delle pozze più grandi si lascia cadere una cosa
##      vera e si aspetta. Dopo, deve essere prendibile. Questo sì è un giudizio.
##   3. E NON DEVE SEMBRARE UNA SPARIZIONE: lo spostamento si misura, e non deve
##      superare il tetto che la rete si è data. Oggi il peggio è mezzo metro,
##      dietro la pattumiera; il resto è un palmo.
##   4. E IL PUNTO DEL REGISTRO, cioè l'angolo esatto in cui è finita la camera di
##      Federico: lì la camera deve restare, raggiungibile, invece di tornarsene
##      al telescopio senza dire niente.
##   5. E DALLA PASSERELLA NON DEVE CADERE NIENTE, che è la cura alla radice del
##      secondo smarrimento: il fermapiede.
##
## IL DIFETTO SI RIMETTE: `SI_PERDE=1` spegne la rete su tutto quello che si
## prende in mano, e la casa torna quella in cui la camera si perde.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_smarrimenti.tscn
##     SI_PERDE=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_smarrimenti.tscn
##     TRACCIA=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_smarrimenti.tscn
extends Node

## La maglia con cui si passa il pavimento, in metri.
const PASSO := 0.15

## L'ingombro della pianta da passare, in metri: tutto l'edificio e il suo intorno.
const DA := Vector2(0.2, 0.2)
const A := Vector2(18.0, 10.0)

## Quanto in alto sta il centro di una cosa posata per terra. È il termos, che è
## la cosa con cui si prova: mezzo cilindro da 30,8 cm.
const CENTRO_A_TERRA := 0.154

## Quante pozze si provano davvero, dalla più grande in giù.
const QUANTE_POZZE := 8

## Quanto può spostare la rete, e NON è un numero scelto qui: è il suo stesso
## tetto di ricerca (`Carryable.RIPESCAGGIO`) più quel poco che una cosa scivola
## assestandosi. Serve a prendere due cose — il giorno in cui qualcuno allarga il
## tetto a tre metri, e il caso in cui la cosa ripescata rotoli via da sola.
##
## LA MISURA, oggi: il peggio è 53 cm, dietro la pattumiera della cucina, dove il
## primo posto buono è di là dal secchio. Gli altri sono tutti 15 cm, cioè un
## palmo: la cosa non ci stava nella fessura, e sta di fianco.
const SPOSTAMENTO_MAX := 1.15

## Quanto si aspetta che la rete guardi e agisca, in passi di fisica. CINQUE
## SECONDI, non uno e mezzo: la rete guarda sei decimi dopo che la cosa si e'
## fermata, e se la sposta la cosa cade, si riassesta e viene riguardata. Nelle
## fessure peggiori ci vogliono due giri, e con l'attesa corta si leggeva «persa»
## una cosa che stava ancora venendo ripescata.
const ATTESA := 300

## Il centro della cupola in pianta e le quote della passerella: gli stessi numeri
## di `tools/geometria.py`.
const CUPOLA := Vector2(2.6, 2.5)
const R_PASS := 1.4
const R_EST := 1.925
const CALPESTIO := 0.59

## L'angolo in cui è finita la camera di Federico, copiato dal registro della sua
## partita: «la camera era finita dove non ci si arriva (8.09, -0.00, 0.17)». È la
## fessura fra la cassettiera della stampante, il rack e i due muri.
const PUNTO_DEL_REGISTRO := Vector3(8.09, 0.0, 0.17)

var _spazio: PhysicsDirectSpaceState3D
var _metro: Carryable
var _guasti := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[smarrimenti] GUASTO: " + msg)


## Il pavimento sotto questo punto, sulla geometria che si VEDE: è lì che le cose
## si posano (vedi `world/corazza.gd`).
func _suolo(x: float, z: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 2.2, z), Vector3(x, -0.5, z))
	q.collision_mask = Corazza.LAYER_APPOGGI
	q.exclude = [_metro.get_rid()]
	var h := _spazio.intersect_ray(q)
	if h.is_empty():
		return NAN
	return (h["position"] as Vector3).y


## LÌ UNA COSA CI STA? Serve a scartare i punti che sono dentro qualcosa.
##
## Un raggio che scende dentro un muro trova il pavimento lo stesso — una trimesh
## non ha un dentro, e il raggio esce dalla faccia inferiore a quota zero — quindi
## la mappa contava come «pavimento» anche lo spessore dei muri e la pancia dei
## mobili. Non sono posti in cui una cosa finisce: sono posti in cui non entra.
## Misurato: una pozza intera, quella del corridoio del magazzino, era il muro.
func _ci_sta_qualcosa(x: float, y: float, z: float) -> bool:
	var palla := SphereShape3D.new()
	palla.radius = 0.08
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = palla
	q.transform = Transform3D(Basis.IDENTITY, Vector3(x, y + 0.10, z))
	q.collision_mask = Corazza.LAYER_APPOGGI
	q.exclude = [_metro.get_rid()]
	return _spazio.intersect_shape(q, 1).is_empty()


## Il giocatore ci sta in piedi? Serve a sapere se in quella fessura una cosa ci
## può arrivare: se lì intorno non ci si cammina, non ci rotola niente.
func _camminabile(x: float, y: float, z: float) -> bool:
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.30
	capsula.height = Player.STAND_HEIGHT
	var dove := PhysicsShapeQueryParameters3D.new()
	dove.shape = capsula
	dove.transform = Transform3D(Basis.IDENTITY,
		Vector3(x, y + Player.STAND_HEIGHT / 2.0 + Carryable.FRANCO_SUOLO, z))
	dove.collision_mask = Interactable.LAYER_WORLD
	return _spazio.intersect_shape(dove, 1).is_empty()


func _prova() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 20:
		await get_tree().physics_frame
	var player := Player.find_in(get_tree())
	if player == null or Corazza.find_in(get_tree()) == null:
		print("[smarrimenti] manca il giocatore o la corazza: la prova non vale")
		get_tree().quit(1)
		return
	_spazio = player.get_world_3d().direct_space_state

	# LA COSA CON CUI SI MISURA è una vera, presa dalla scena: la regola che si
	# vuole provare è la sua, non una copia scritta qui.
	for n in get_tree().get_nodes_in_group(Carryable.GROUP):
		var c := n as Carryable
		if c != null and not (c is CcdCamera):
			_metro = c
			break
	if _metro == null:
		print("[smarrimenti] non c'è niente da prendere in mano: la prova non vale")
		get_tree().quit(1)
		return

	var spente := 0
	if OS.get_environment("SI_PERDE") == "1":
		for n in get_tree().get_nodes_in_group(Carryable.GROUP):
			(n as Carryable).si_puo_perdere = true
			spente += 1
		print("[smarrimenti] DIFETTO RIMESSO: rete spenta su %d cose" % spente)

	var pozze := _mappa()
	await _promessa(pozze)
	await _il_punto_del_registro(player)
	await _dalla_passerella_non_cade()
	print("[smarrimenti] %d guasti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)


## DALLA PASSERELLA NON CADE NIENTE, ed è la cura alla RADICE: sotto il corrente
## basso della ringhiera ci sono cinquanta centimetri d'aria, e una cosa che
## rotola ci passa sotto e finisce nell'anello di pavimento fra la passerella e i
## muri — quarantasette centimetri a nord, dove il giocatore, che ne misura
## sessanta, non ci va mai. Il fermapiede è la lamiera che ogni passerella a
## grigliato ha sul bordo, messa per questo.
##
## SI SPINGE VERSO FUORI a un metro e mezzo al secondo, che è una cosa mollata
## male, non lanciata: un fermapiede alto dodici centimetri ferma quello che
## rotola, e non pretende di fermare quello che vola.
##
## IL DIFETTO SI RIMETTE: `SOPRA_IL_FERMAPIEDE=1` fa partire la cosa da sopra la
## lamiera e a un palmo dal bordo, così non fa in tempo a ricadere sull'impalcato
## prima di arrivarci: scavalca e cade. È il modo di sapere che questa prova
## guarda il fermapiede e non la ringhiera che gli sta sopra.
func _dalla_passerella_non_cade() -> void:
	var sopra := OS.get_environment("SOPRA_IL_FERMAPIEDE") == "1"
	if sopra:
		print("[smarrimenti] DIFETTO RIMESSO: la cosa parte da sopra il fermapiede")
	var caduti := 0
	for gradi in [0.0, 45.0, 180.0, 225.0, 270.0, 315.0]:
		var a := deg_to_rad(gradi)
		var dir := Vector3(cos(a), 0.0, sin(a))
		var alto := 0.15 if sopra else 0.02
		var raggio := (R_EST - 0.08) if sopra else R_PASS
		var da := Vector3(CUPOLA.x, CALPESTIO + alto, CUPOLA.y) + dir * raggio
		_metro.freeze = true
		_metro.global_position = da
		_metro.global_rotation = Vector3.ZERO
		await get_tree().physics_frame
		_metro.freeze = false
		_metro.angular_velocity = Vector3.ZERO
		_metro.linear_velocity = dir * 1.5
		for _k in ATTESA:
			await get_tree().physics_frame
		var q := _metro.global_position
		var giu := q.y < CALPESTIO - 0.20
		if giu:
			caduti += 1
		if OS.get_environment("TRACCIA") == "1" or giu:
			print("[smarrimenti] spinta a %.0f gradi: finisce a %.2f, %.2f, %.2f (%s)"
				% [gradi, q.x, q.y, q.z, "GIU' DALLA PASSERELLA" if giu else "resta su"])
	if caduti > 0:
		_guasto("spinta contro la ringhiera, la roba cade dalla passerella in %d "
			% caduti + "direzioni su 6: il fermapiede non ferma niente")
	else:
		print("[smarrimenti] spinta contro la ringhiera da 6 direzioni, non cade mai")


## IL PUNTO DEL REGISTRO. La partita di Federico ha scritto dove è finita la
## camera; qui la si rimette lì. Non deve tornarsene al fuoco — sparire da sotto
## gli occhi è il difetto che ha raccontato — e deve restare prendibile.
func _il_punto_del_registro(player: Player) -> void:
	var ccd := CcdCamera.find_in(get_tree())
	if ccd == null:
		_guasto("la camera CCD non c'è")
		return
	# si smonta come la smonta chi gioca
	ccd.prendi(player)
	ccd.lascia()
	ccd.freeze = true
	ccd.global_position = PUNTO_DEL_REGISTRO
	ccd.global_rotation = Vector3.ZERO
	await get_tree().physics_frame
	ccd.freeze = false
	ccd.linear_velocity = Vector3.ZERO
	for _k in ATTESA:
		await get_tree().physics_frame
	var mosso := PUNTO_DEL_REGISTRO.distance_to(ccd.global_position)
	print("[smarrimenti] il punto del registro (%.2f, %.2f): la camera ferma a %.0f cm "
		% [PUNTO_DEL_REGISTRO.x, PUNTO_DEL_REGISTRO.z, mosso * 100.0]
		+ "da dov'era, %s, %s"
		% ["montata" if ccd.montata() else "per terra",
			"si prende" if ccd.si_riesce_a_prendere() else "NON si prende"])
	if ccd.montata():
		_guasto("la camera se n'è tornata al fuoco: dove è caduta c'era un posto "
			+ "buono a un palmo, e chi giocava l'ha vista sparire")
	elif not ccd.si_riesce_a_prendere():
		_guasto("la camera resta nell'angolo del rack, dove nessuno la può prendere")


## LA MAPPA. Per ogni punto di pavimento si chiede al gioco se una cosa lì si
## riprenderebbe; i punti di no che confinano con pavimento camminabile si
## raggruppano in pozze. Il confine conta: dentro un armadio chiuso non ci si
## arriva e non ci rotola niente, e chiamarlo difetto sarebbe rumore.
func _mappa() -> Array:
	var t0 := Time.get_ticks_msec()
	var _era := _metro.global_position
	_metro.freeze = true
	_metro.global_position = Vector3(0.0, -50.0, 0.0)   # via dai piedi della misura
	var quota := {}
	var camm := {}
	var persi: Array[Vector2i] = []
	var dentro := 0
	var x := DA.x
	while x < A.x:
		var z := DA.y
		while z < A.y:
			var y := _suolo(x, z)
			if not is_nan(y) and y > -0.02 and y < 0.30 and _ci_sta_qualcosa(x, y, z):
				var c := Vector2i(roundi(x / PASSO), roundi(z / PASSO))
				quota[c] = y
				camm[c] = _camminabile(x, y, z)
				dentro += 1
			z += PASSO
		x += PASSO
	for c in quota:
		var p := Vector3(c.x * PASSO, quota[c] + CENTRO_A_TERRA, c.y * PASSO)
		if _metro.si_riesce_a_prendere(p):
			continue
		var arriva := false
		for dx in range(-4, 5):
			for dz in range(-4, 5):
				var q: Vector2i = c + Vector2i(dx, dz)
				if camm.has(q) and camm[q]:
					arriva = true
					break
			if arriva:
				break
		if arriva:
			persi.append(c)
	_metro.global_position = _era
	_metro.freeze = false

	var pozze: Array = []
	var visti := {}
	for c in persi:
		if visti.has(c):
			continue
		var coda: Array[Vector2i] = [c]
		var gruppo: Array[Vector2i] = []
		visti[c] = true
		while not coda.is_empty():
			var v: Vector2i = coda.pop_back()
			gruppo.append(v)
			for dx in [-1, 0, 1]:
				for dz in [-1, 0, 1]:
					var q: Vector2i = v + Vector2i(dx, dz)
					if not visti.has(q) and persi.has(q):
						visti[q] = true
						coda.append(q)
		pozze.append([gruppo, quota[gruppo[0]]])
	pozze.sort_custom(func(a, b): return a[0].size() > b[0].size())
	print("[smarrimenti] pavimento: %d punti, %d dove una cosa non si riprende e ci "
		% [dentro, persi.size()]
		+ "può arrivare (%.2f m2 in %d pozze), misurato in %d ms"
		% [persi.size() * PASSO * PASSO, pozze.size(), Time.get_ticks_msec() - t0])
	var traccia := OS.get_environment("TRACCIA") == "1"
	for i in pozze.size():
		var g: Array = pozze[i][0]
		if i >= QUANTE_POZZE and not traccia:
			break
		var cc := Vector2.ZERO
		for r in g:
			cc += Vector2(r.x, r.y) * PASSO
		cc /= g.size()
		print("[smarrimenti]   pozza %d: %.2f m2 attorno a (%.2f, %.2f)"
			% [i + 1, g.size() * PASSO * PASSO, cc.x, cc.y])
	return pozze


## LA PROMESSA. In ogni pozza si lascia cadere una cosa vera, si aspetta che la
## rete la guardi, e dopo la si deve poter prendere.
func _promessa(pozze: Array) -> void:
	var quante: int = mini(QUANTE_POZZE, pozze.size())
	if quante == 0:
		print("[smarrimenti] nessuna pozza da provare")
		return
	var peggiore := 0.0
	for i in quante:
		var g: Array = pozze[i][0]
		var y: float = pozze[i][1]
		# IL PUNTO PEGGIORE DELLA POZZA, non il suo centro: si prova il posto in
		# cui una cosa finisce, cioè quello più lontano dal pavimento buono.
		var c: Vector2i = g[int(g.size() / 2.0)]
		var dove := Vector3(c.x * PASSO, y + 0.02, c.y * PASSO)
		_metro.freeze = true
		_metro.global_position = dove
		_metro.global_rotation = Vector3.ZERO
		await get_tree().physics_frame
		_metro.freeze = false
		_metro.linear_velocity = Vector3.ZERO
		_metro.angular_velocity = Vector3.ZERO
		for _k in ATTESA:
			await get_tree().physics_frame
		var mosso := dove.distance_to(_metro.global_position)
		var presa := _metro.si_riesce_a_prendere()
		peggiore = maxf(peggiore, mosso)
		print("[smarrimenti] pozza %d (%.2f, %.2f): %s ferma a %.0f cm da dov'era, %s"
			% [i + 1, dove.x, dove.z, _metro.nome, mosso * 100.0,
				"si prende" if presa else "NON si prende"])
		if not presa:
			_guasto("nella pozza %d (%.2f, %.2f) %s resta dove nessuno la può prendere"
				% [i + 1, dove.x, dove.z, _metro.nome])
	if peggiore > SPOSTAMENTO_MAX:
		_guasto("la rete ha spostato %s di %.0f cm, e il suo tetto di ricerca è %.0f: "
			% [_metro.nome, peggiore * 100.0, SPOSTAMENTO_MAX * 100.0]
			+ "o il tetto è cresciuto, o la cosa ripescata è rotolata via da sola")
	else:
		print("[smarrimenti] la rete non ha mai spostato niente di più di %.0f cm"
			% (peggiore * 100.0))
