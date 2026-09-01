## UN OGGETTO POSATO SI FERMA DOVE SI VEDE, O SULLA CIMA FINTA DEL BLOCCO?
##
## LA DOMANDA. La collisione di questa scena la genera `gen_blockout.py` da
## `geometria.py`, e ogni mobile e' UN BLOCCO PIENO alto quanto il suo pezzo piu'
## alto. Per camminare e' perfetto e per un anno e' bastato. Poi sono arrivati gli
## oggetti che cadono, e ogni cima finta e' diventata un posto dove la roba resta
## sospesa: Federico ha fotografato prima un termos e poi una radiolina a
## mezz'aria sopra il carrello del proiettore.
##
## LA CURA E' `world/corazza.gd`: una seconda collisione, fatta con la geometria
## che si VEDE, su cui cadono gli oggetti mentre il giocatore continua a
## camminare sugli ingombri. Questa sonda misura se funziona, e lo fa nel modo in
## cui il difetto e' comparso: LASCIANDO CADERE QUALCOSA.
##
## SI PROVA DOVE FA PIU' MALE. I bersagli non sono scelti a mano: si cercano i
## blocchi la cui cima e' quasi tutta aria - si guarda, maglia per maglia, quanto
## in basso sta la geometria vera - e si lascia cadere una sonda proprio li'. Un
## armadio non direbbe niente, perche' sopra un armadio le due collisioni
## coincidono.
##
## IL DIFETTO SI RIMETTE: `SUGLI_INGOMBRI=1` riporta gli oggetti a cadere sui
## blocchi grezzi, ed e' il comportamento di prima.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_appoggi.tscn
##     SUGLI_INGOMBRI=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_appoggi.tscn
extends Node

## Il passo con cui si guarda la cima di un blocco, in metri.
const MAGLIA := 0.05

## Quanto sotto la cima puo' stare la geometria perche' la maglia conti come
## piena: una mesh puo' essere piu' magra della sua collisione di un dito.
const SOTTO := 0.05

## Sotto questa frazione di maglie piene, la cima del blocco e' aria.
const VUOTO := 0.20

## Quanto puo' restare sopra la geometria vera un oggetto posato, in metri.
const TOLLERANZA := 0.06

var _guasti := 0
var _spazio: PhysicsDirectSpaceState3D


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[appoggi] GUASTO: " + msg)


func _corpi(n: Node, fuori: Array[StaticBody3D]) -> void:
	if n is StaticBody3D:
		fuori.append(n as StaticBody3D)
	for f in n.get_children():
		_corpi(f, fuori)


## A che quota si ferma una cosa lasciata cadere qui, secondo la collisione
## indicata. E' la domanda che questa sonda fa tre volte con maschere diverse:
## alla geometria vera, agli ingombri, e all'oggetto vero.
func _quota(x: float, z: float, da: float, maschera: int) -> float:
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, da, z), Vector3(x, -0.5, z))
	q.collision_mask = maschera
	var colpo := _spazio.intersect_ray(q)
	return (colpo["position"] as Vector3).y if not colpo.is_empty() else -1e9


## L'impronta e la cima di un corpo fatto di una sola scatola.
func _scatola(c: StaticBody3D) -> AABB:
	var forme := 0
	var trovata := AABB()
	for f in c.get_children():
		var forma := f as CollisionShape3D
		if forma == null or forma.shape == null:
			continue
		forme += 1
		var box := forma.shape as BoxShape3D
		if box == null:
			return AABB()
		var xf := forma.global_transform
		var mezzo := box.size * 0.5
		var mn := Vector3.INF
		var mx := -Vector3.INF
		for i in 8:
			var p := xf * Vector3(
				mezzo.x if (i & 1) else -mezzo.x,
				mezzo.y if (i & 2) else -mezzo.y,
				mezzo.z if (i & 4) else -mezzo.z)
			mn = mn.min(p)
			mx = mx.max(p)
		trovata = AABB(mn, mx - mn)
	return trovata if forme == 1 else AABB()


## I blocchi la cui cima e' quasi tutta aria, dal piu' bugiardo in giu'.
func _cime_finte(corpi: Array[StaticBody3D]) -> Array:
	var fuori := []
	for c in corpi:
		var box := _scatola(c)
		var cima := box.position.y + box.size.y
		# Solo i mobili: sopra i due metri sono muri e soffitti, sotto i venti
		# centimetri zoccoli e soglie, e su nessuno dei due si posa niente.
		if box.size == Vector3.ZERO or cima < 0.20 or cima > 2.00:
			continue
		if box.size.x < 0.20 or box.size.z < 0.20:
			continue
		var maglie := 0
		var piene := 0
		# DOVE SI PROVERA' A POSARE: la maglia vuota con la geometria PIU' ALTA,
		# cioe' quella ancora sul mobile e piu' lontana dalla cima finta. La prima
		# stesura teneva l'ultima maglia vuota che capitava, e capitava di essere
		# oltre il bordo del mobile: si lasciava cadere la sonda accanto al
		# carrello invece che sopra, e il referto diceva «geometria vera 0,00»
		# indicando il pavimento.
		var centro := Vector2(box.position.x, box.position.z)
		var meglio := -1e9
		var x := box.position.x + MAGLIA * 0.5
		while x < box.position.x + box.size.x:
			var z := box.position.z + MAGLIA * 0.5
			while z < box.position.z + box.size.z:
				maglie += 1
				var q := _quota(x, z, cima + SOTTO, Corazza.LAYER_APPOGGI)
				if q >= cima - SOTTO:
					piene += 1
				elif q > meglio:
					meglio = q
					centro = Vector2(x, z)
				z += MAGLIA
			x += MAGLIA
		if maglie > 0 and float(piene) / maglie < VUOTO:
			fuori.append([c.name, cima, float(piene) / maglie, centro])
	fuori.sort_custom(func(a, b): return a[2] < b[2])
	return fuori


func _prova() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 6:
		await get_tree().physics_frame
	_spazio = (Player.find_in(get_tree())).get_world_3d().direct_space_state

	if Corazza.find_in(get_tree()) == null:
		print("[appoggi] la corazza non c'e': la prova non vale")
		get_tree().quit(1)
		return

	var corpi: Array[StaticBody3D] = []
	_corpi(get_tree().root, corpi)
	var finte := _cime_finte(corpi)
	print("[appoggi] %d blocchi di arredo, %d con la cima quasi tutta aria"
		% [corpi.size(), finte.size()])
	# SONDA CIECA: se nessun blocco ha la cima finta non c'e' niente da provare, e
	# questa sonda passerebbe anche con la corazza spenta.
	if finte.size() < 3:
		_guasto("SONDA CIECA: solo %d blocchi con la cima finta, non bastano a "
			% finte.size() + "distinguere la geometria vera dagli ingombri")

	# Su ognuno si lascia cadere un oggetto vero - non un raggio: un raggio prova
	# la collisione, un corpo prova anche che ci si fermi sopra.
	var quanti := mini(finte.size(), 6)
	for k in quanti:
		var caso: Array = finte[k]
		var nome: String = caso[0]
		var cima: float = caso[1]
		var dove: Vector2 = caso[3]
		var vera := _quota(dove.x, dove.y, cima + 0.30, Corazza.LAYER_APPOGGI)
		var sasso := Carryable.new()
		sasso.name = "Sonda"
		sasso.nome = "la sonda"
		sasso.mass = 0.5
		var forma := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.06, 0.06, 0.06)
		forma.shape = box
		forma.position = Vector3(0.0, 0.03, 0.0)
		sasso.add_child(forma)
		get_tree().current_scene.add_child(sasso)
		sasso.global_position = Vector3(dove.x, cima + 0.40, dove.y)
		if OS.get_environment("SUGLI_INGOMBRI") == "1":
			# IL DIFETTO: si torna a cadere sugli ingombri, cioe' sui blocchi
			# grezzi. E' come stava prima della corazza, ed e' il confronto senza
			# il quale «la sonda si e' fermata a 0,75» non direbbe se il merito e'
			# della geometria vera o del caso.
			sasso.collision_mask = Interactable.LAYER_WORLD
		for _i in 150:
			await get_tree().physics_frame
		var finito := sasso.global_position.y
		print("[appoggi] %-16s cima del blocco %.2f, geometria vera %.2f, "
			% [nome, cima, vera] + "la sonda si ferma a %.2f" % finito)
		if finito > vera + TOLLERANZA:
			_guasto("sopra %s la sonda resta a %.2f invece che a %.2f: e' "
				% [nome, finito, vera] + "appoggiata sulla cima finta del blocco")
		sasso.queue_free()

	if _guasti == 0:
		print("[appoggi] ok: si posa dove si vede, non sulla cima degli ingombri")
	else:
		print("[appoggi] GUASTO: %d controlli falliti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)
