## QUELLO CHE SI POSA SI FERMA, E SI FERMA SOPRA IL PIANO E NON DENTRO.
##
## Federico: «ho appoggiato la borraccia e la camera CCD su un plico di fogli e
## trema moltissimo».
##
## COS'ERA, e non erano i fogli. Il solutore di Godot lascia affondare un corpo
## appoggiato fino a `contact_max_allowed_penetration` — di fabbrica UN
## CENTIMETRO — e da lì in poi lo respinge. A regime il corpo non si ferma: si
## assesta PROPRIO SU QUELLA SOGLIA, cioè in un ciclo limite a due tick,
## dentro-fuori-dentro-fuori a trenta hertz. Misurato sulla consolle nuda: il
## fondo del termos dieci millimetri sotto il piano, velocità che sbatte fra 0,003
## e 0,043 m/s a ogni tick, rotazione fino a 0,27 rad/s, e mai un momento di sonno
## in quattro secondi.
##
## SUL PLICO DI FOGLI SI VEDE PIÙ CHE ALTROVE per una ragione sola: il plico è
## spesso dieci millimetri esatti, quindi la roba posata lì sopra non affonda «un
## po'» — lo attraversa tutto e va a vibrare sul legno, in mezzo alla carta. Ma il
## difetto è di tutta la casa, e questa sonda lo misura in tre posti per dirlo.
##
## TRE POSTI, e il terzo è quello che i primi due non possono dire:
##   1. la consolle nuda — un piano solo, il caso semplice;
##   2. il plico di fogli — tre facce orizzontali alla stessa identica quota, che
##      è il posto che Federico ha trovato;
##   3. una cosa sopra un'altra cosa — due corpi impilati, che è il caso in cui
##      un margine troppo stretto farebbe danno invece che bene.
##
## E POI SI GUARDA LA CASA COM'È: il termos, la tazza, il piattino, le bottiglie
## e la radiolina stanno dove il mondo li ha messi all'avvio, e dopo tre secondi
## devono dormire tutti. Un `Carryable` sveglio è un oggetto che trema.
##
## IL DIFETTO SI RIMETTE: `PENETRAZIONE_DI_FABBRICA=1` riporta i due numeri del
## solutore a quelli di Godot. Senza quel confronto un referto che dice «sta
## fermo» non distingue il merito della cura dal fatto che nessuno abbia guardato.
##
## E I DUE NUMERI SI RITROVANO: `MANOPOLE=1` spazza il raggio di riciclo dei
## contatti e riposa la sonda a ogni valore, sul piano e su una pila. È da lì che
## vengono le tabelle scritte in `project.godot`, sezione `[physics]` — chi li
## cambia rilancia quello, non tira a indovinare.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_tremore.tscn
##     PENETRAZIONE_DI_FABBRICA=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_tremore.tscn
##     MANOPOLE=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_tremore.tscn
##     TRACCIA=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_tremore.tscn
extends Node

## Quanti secondi si lascia assestare il corpo prima di guardarlo.
const ASSESTAMENTO := 4.0

## E per quanti se ne misura il tremito, dopo.
const OSSERVAZIONE := 1.5

## Quanto può ancora muoversi un oggetto che si considera posato, in m/s.
const FERMO := 0.005

## E di quanto può stare sotto il piano su cui è appoggiato, in metri. Due
## millimetri non si vedono; un centimetro attraversa un plico di fogli.
const AFFONDAMENTO := 0.003

## Da quanto sopra il piano lo si lascia andare: due centimetri, cioè posarlo,
## non lasciarlo cadere da un metro.
const DA_SOPRA := 0.02

## Due facce orizzontali sono ALLA STESSA QUOTA se distano meno di così.
const COINCIDENTI := 0.001

var _spazio: PhysicsDirectSpaceState3D
var _guasti := 0
## Smorzamento angolare da imporre alla sonda, o -1 per quello del Carryable.
var _smorzo := -1.0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[tremore] GUASTO: " + msg)


func _mesh(n: Node, fuori: Array[MeshInstance3D]) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).is_visible_in_tree():
		fuori.append(n as MeshInstance3D)
	for f in n.get_children():
		_mesh(f, fuori)


## A che quota trova qualcosa un raggio verticale, sulla CORAZZA — cioè sulla
## geometria che si vede, che è quella su cui gli oggetti si posano.
func _quota(x: float, z: float, da: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, da, z), Vector3(x, 0.0, z))
	q.collision_mask = Corazza.LAYER_APPOGGI
	var colpo := _spazio.intersect_ray(q)
	return (colpo["position"] as Vector3).y if not colpo.is_empty() else -1.0


## Quante mesh hanno la propria CIMA entro `COINCIDENTI` da `quota`, sopra il
## punto (x, z). Sono le superfici che un oggetto appoggiato lì tocca insieme.
func _sovrapposte(mesh: Array[MeshInstance3D], x: float, z: float, quota: float) -> Array[String]:
	var nomi: Array[String] = []
	for m in mesh:
		var ab := m.global_transform * m.get_aabb()
		if x < ab.position.x - 0.001 or x > ab.position.x + ab.size.x + 0.001:
			continue
		if z < ab.position.z - 0.001 or z > ab.position.z + ab.size.z + 0.001:
			continue
		if absf(ab.position.y + ab.size.y - quota) <= COINCIDENTI:
			nomi.append(m.name)
	return nomi


func _prova() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 20:
		await get_tree().physics_frame
	var player := Player.find_in(get_tree())
	if player == null or Corazza.find_in(get_tree()) == null:
		print("[tremore] scena incompleta: la prova non vale")
		get_tree().quit(1)
		return
	_spazio = player.get_world_3d().direct_space_state

	var spazio := get_tree().root.world_3d.space
	if OS.get_environment("PENETRAZIONE_DI_FABBRICA") == "1":
		PhysicsServer3D.space_set_param(
			spazio, PhysicsServer3D.SPACE_PARAM_CONTACT_MAX_ALLOWED_PENETRATION, 0.01)
		PhysicsServer3D.space_set_param(
			spazio, PhysicsServer3D.SPACE_PARAM_CONTACT_RECYCLE_RADIUS, 0.01)
		print("[tremore] DIFETTO RIMESSO: penetrazione e riciclo riportati a quelli di Godot")
	print("[tremore] penetrazione ammessa %.4f m, raggio di riciclo %.3f m"
		% [PhysicsServer3D.space_get_param(
				spazio, PhysicsServer3D.SPACE_PARAM_CONTACT_MAX_ALLOWED_PENETRATION),
		   PhysicsServer3D.space_get_param(
				spazio, PhysicsServer3D.SPACE_PARAM_CONTACT_RECYCLE_RADIUS)])

	# ---------------------------------------------------------------- il plico
	var mesh: Array[MeshInstance3D] = []
	_mesh(get_tree().root, mesh)
	var cima := -1.0
	var base := -1.0
	var centro := Vector2.ZERO
	for m in mesh:
		if not m.name.to_lower().contains("notepads"):
			continue
		var ab := m.global_transform * m.get_aabb()
		print("[tremore] %-32s %5d triangoli, da y %.4f a y %.4f, spessore %.1f mm"
			% [m.name, int(m.mesh.get_faces().size() / 3.0), ab.position.y,
			   ab.position.y + ab.size.y, ab.size.y * 1000.0])
		if m.name.contains("a4_stack"):
			cima = ab.position.y + ab.size.y
			base = ab.position.y
			centro = Vector2(ab.position.x + ab.size.x / 2, ab.position.z + ab.size.z / 2)
	if cima < 0.0:
		print("[tremore] il plico di fogli non c'è: la prova non vale")
		get_tree().quit(1)
		return
	var insieme := _sovrapposte(mesh, centro.x, centro.y, cima)
	print("[tremore] sul plico la quota %.4f è la cima di %d mesh insieme: %s"
		% [cima, insieme.size(), insieme])

	# ---------------------------------------------------------------- il tremito
	var nudo := _cerca_consolle_nuda(centro, base)
	if nudo == Vector2.ZERO:
		_guasto("non trovo un punto nudo della consolle: manca il termine di paragone")
	else:
		print("[tremore] consolle nuda trovata a (%.3f, %.3f)" % [nudo.x, nudo.y])
		await _posa(nudo, "consolle nuda", null)
	await _posa(centro, "plico di fogli", null)
	# TERZA PROVA: una cosa sopra un'altra cosa. Un margine troppo stretto si vede
	# qui prima che altrove — due corpi che si spingono a vicenda invece di
	# assestarsi — ed è la ragione per cui il millimetro non è un decimo.
	var sotto := _sonda()
	sotto.name = "Base"
	sotto.global_position = Vector3(centro.x, cima + DA_SOPRA, centro.y)
	for _i in int(ASSESTAMENTO * Engine.physics_ticks_per_second):
		await get_tree().physics_frame
	await _posa(centro, "sopra un altro corpo", sotto)
	sotto.queue_free()
	await get_tree().physics_frame
	if OS.get_environment("MANOPOLE") == "1" and nudo != Vector2.ZERO:
		for r in [0.02, 0.03, 0.04, 0.05, 0.06, 0.08]:
			var prima := PhysicsServer3D.space_get_param(
				spazio, PhysicsServer3D.SPACE_PARAM_CONTACT_RECYCLE_RADIUS)
			PhysicsServer3D.space_set_param(
				spazio, PhysicsServer3D.SPACE_PARAM_CONTACT_RECYCLE_RADIUS, r)
			await _posa(nudo, "riciclo %.2f piano" % r, null)
			var fondo := _sonda()
			fondo.name = "Base"
			fondo.global_position = Vector3(centro.x, cima + DA_SOPRA, centro.y)
			for _i in int(ASSESTAMENTO * Engine.physics_ticks_per_second):
				await get_tree().physics_frame
			await _posa(centro, "riciclo %.2f pila" % r, fondo)
			fondo.queue_free()
			await get_tree().physics_frame
			PhysicsServer3D.space_set_param(
				spazio, PhysicsServer3D.SPACE_PARAM_CONTACT_RECYCLE_RADIUS, prima)
	await _tutta_la_casa()
	print("[tremore] %d guasti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)


## E LA ROBA CHE STA GIA' IN GIRO PER LA CASA? È la domanda vera, perché la sonda
## la si posa dove si vuole mentre il termos, la tazza, il piattino e le bottiglie
## stanno dove il mondo li ha messi all'avvio. Dopo qualche secondo devono dormire
## tutti: un `Carryable` sveglio è un oggetto che trema.
func _tutta_la_casa() -> void:
	for _i in int(3.0 * Engine.physics_ticks_per_second):
		await get_tree().physics_frame
	var svegli: Array[String] = []
	var quanti := 0
	for n in get_tree().root.find_children("*", "RigidBody3D", true, false):
		var c := n as Carryable
		if c == null or c.name == "Sonda" or c.name == "Base":
			continue
		# LA CAMERA AVVITATA AL FUOCO NON CONTA: e' `freeze`, appesa al nodo del
		# focheggiatore, e un corpo congelato risulta sveglio per definizione
		# senza muoversi di un micron. Vedi `world/interactables/ccd_camera.gd`.
		if c.freeze:
			continue
		quanti += 1
		if not c.sleeping:
			svegli.append("%s (%.3f m/s, %.2f rad/s)"
				% [c.name, c.linear_velocity.length(), c.angular_velocity.length()])
	print("[tremore] la roba della casa: %d oggetti, %d ancora svegli" % [quanti, svegli.size()])
	if not svegli.is_empty():
		_guasto("dopo tre secondi %d oggetti della casa non si sono fermati: %s"
			% [svegli.size(), svegli])


## Un punto della stessa consolle in cui non c'è niente sopra: il raggio trova il
## PIANO, cioè la quota su cui il plico poggia. È il termine di paragone.
##
## SI GUARDA TUTTA L'IMPRONTA DELLA SONDA, non il centro. Cercando un punto solo
## si finiva sull'ORLO del piano, con mezzo cilindro a sbalzo: quello non è un
## oggetto appoggiato che trema, è un oggetto che sta cadendo, e come termine di
## paragone dice il falso.
func _cerca_consolle_nuda(centro: Vector2, piano: float) -> Vector2:
	for r in [0.25, 0.30, 0.35, 0.40, 0.45, 0.55]:
		for k in 24:
			var a := TAU * k / 24
			var p: Vector2 = centro + Vector2(cos(a), sin(a)) * r
			var piana := true
			for j in 8:
				var b := TAU * j / 8
				var q: Vector2 = p + Vector2(cos(b), sin(b)) * 0.055
				if absf(_quota(q.x, q.y, piano + 0.50) - piano) > 0.002:
					piana = false
					break
			if piana and absf(_quota(p.x, p.y, piano + 0.50) - piano) < 0.002:
				return p
	return Vector2.ZERO


## Il corpo di prova: quello del termos, non una scatola. Cilindro da 5 cm di
## raggio e 30 di altezza, un chilo. Una scatola appoggia su quattro spigoli e
## nasconde proprio il difetto che si sta cercando; un cilindro appoggia su un
## cerchio, che è il caso peggiore e anche quello vero.
func _sonda() -> Carryable:
	var corpo := Carryable.new()
	corpo.name = "Sonda"
	corpo.nome = "la sonda"
	corpo.mass = 1.0
	var forma := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.height = 0.308
	cil.radius = 0.050
	forma.shape = cil
	forma.position = Vector3(0.0, 0.154, 0.0)
	corpo.add_child(forma)
	get_tree().current_scene.add_child(corpo)
	if _smorzo >= 0.0:
		corpo.angular_damp = _smorzo
	return corpo


## Si posa un corpo di prova due centimetri sopra il punto, lo si lascia
## assestare, e poi si guarda per un secondo e mezzo quanto continua a muoversi.
## Con `su` diverso da null si posa sopra QUEL corpo invece che sul piano.
func _posa(dove: Vector2, etichetta: String, su: RigidBody3D) -> void:
	var piano := _quota(dove.x, dove.y, 1.60)
	if su != null:
		piano = su.global_position.y + 0.308
	var corpo := _sonda()
	corpo.global_position = Vector3(dove.x, piano + DA_SOPRA, dove.y)

	var tick := 1.0 / Engine.physics_ticks_per_second
	for _i in int(ASSESTAMENTO / tick):
		await get_tree().physics_frame

	var v_max := 0.0
	var w_max := 0.0
	var y_min := INF
	var y_max := -INF
	var svegli := 0
	var passi := int(OSSERVAZIONE / tick)
	for k in passi:
		await get_tree().physics_frame
		v_max = maxf(v_max, corpo.linear_velocity.length())
		w_max = maxf(w_max, corpo.angular_velocity.length())
		y_min = minf(y_min, corpo.global_position.y)
		y_max = maxf(y_max, corpo.global_position.y)
		if not corpo.sleeping:
			svegli += 1
		if OS.get_environment("TRACCIA") == "1" and k < 20:
			print("[tremore/traccia] %-20s %2d  y %.5f  v %.4f  w %.4f"
				% [etichetta, k, corpo.global_position.y,
				   corpo.linear_velocity.length(), corpo.angular_velocity.length()])
	# CONTRO COSA STA POGGIANDO, per nome: due corpi statici sotto lo stesso
	# oggetto vogliono dire due superfici alla stessa quota, ed e' la prima cosa
	# da guardare quando uno solo di questi posti trema e gli altri no.
	var sopra := []
	for c in corpo.get_colliding_bodies():
		var n := c as Node
		if n != null:
			var chi := n.get_parent()
			sopra.append("%s/%s" % [chi.name if chi != null else "?", n.name])
	var affonda := piano - corpo.global_position.y
	print("[tremore] %-20s: piano %.4f, si ferma %5.1f mm sotto; velocità max %.4f m/s, "
		% [etichetta, piano, affonda * 1000.0, v_max]
		+ "rotazione max %.2f rad/s, sale e scende di %.2f mm, sveglia %d passi su %d, poggia su %s"
		% [w_max, (y_max - y_min) * 1000.0, svegli, passi, sopra])
	# DORMIRE E' LA DEFINIZIONE DI FERMO, e non un dettaglio del motore: un corpo
	# addormentato non viene piu' risolto, quindi non puo' piu' tremare. Finche'
	# resta sveglio con una rotazione sopra la soglia di sonno (8 gradi al
	# secondo) il ciclo limite non finisce mai da solo.
	if svegli > 0 and (v_max > FERMO or (y_max - y_min) > 0.0001):
		_guasto("sul %s la sonda non si ferma: sveglia %d passi su %d, ancora %.3f m/s "
			% [etichetta, svegli, passi, v_max]
			+ "e %.2f rad/s, e sale e scende di %.2f mm"
			% [w_max, (y_max - y_min) * 1000.0])
	if affonda > AFFONDAMENTO:
		_guasto("sul %s la sonda affonda di %.1f mm: si vede attraversare il piano"
			% [etichetta, affonda * 1000.0])
	# SI LIBERA SEMPRE, e la prima stesura non lo faceva: il corpo della prova
	# precedente restava sul piano, e quella dopo gli si posava SOPRA senza dirlo.
	# I referti sembravano buoni e misuravano un'altra cosa.
	corpo.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
