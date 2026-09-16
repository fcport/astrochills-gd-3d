## CAMMINANDO FUORI TREMA TUTTO?
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_passi_prato.tscn
##
## Federico, il 2026-09-16: «quando cammino fuori trema tutto, sembra che inciampi su
## qualcosa ogni volta, è un po' come se l'erba facesse impatto». Dentro no.
##
## SI CAMMINA DAVVERO, con l'azione `move_forward` premuta, e si registra a ogni
## passo di fisica dove sta il corpo e dove sta il terreno sotto di lui. Due tratti
## dritti della stessa lunghezza: uno sul prato mosso, e uno di CONFRONTO sulla
## fascia piatta lungo la facciata sud, che è terreno della stessa maglia ma a quota
## zero. Se tremano tutti e due il colpevole è il corpo; se trema solo il primo è il
## terreno.
##
## COSA SI CONTA. Un terreno fatto di triangoli da un metro cambia pendenza a ogni
## spigolo, e salendo e scendendo la velocità verticale cambia di conseguenza: a
## due metri e mezzo al secondo, su queste gobbe, di un decimo di metro al secondo
## per spigolo. È il massimo che un corpo che SEGUE il terreno può fare. Uno
## scossone è un salto di velocità verticale molto più grande di così in un solo
## passo di fisica: il corpo che si stacca e ricade, o che viene spinto su.
extends Node

const PASSO_FISICA := 1.0 / 60.0

## Oltre questo salto di velocità verticale in un passo, è un colpo e non una
## pendenza (vedi la testata).
const SCOSSONE := 0.35

## I tratti: nome, partenza, arrivo (x, z). Il prato mosso sta a z = 19, lontano
## dall'edificio e dall'auto; la fascia piatta a z = 11, un metro e mezzo fuori dalla
## facciata sud, dove `FormaPrato` tiene il terreno a zero.
##
## LA DIAGONALE DI CORSA attraversa gli spigoli di traverso — i triangoli sono tagliati
## lungo una diagonale, e un tratto parallelo agli assi ne incontra solo di due tipi —
## e a velocità quasi doppia: è il caso in cui l'aggancio al pavimento ha più strada
## da recuperare in un passo.
const TRATTI := [
	["prato mosso", Vector2(-3.0, 19.0), Vector2(20.0, 19.0), false],
	["diagonale corsa", Vector2(-3.0, 24.0), Vector2(19.0, 15.0), true],
	["fascia piatta", Vector2(1.0, 11.0), Vector2(17.0, 11.0), false],
]

var _guasti := 0


func _ready() -> void:
	_prova.call_deferred()


func _prato_di(n: Node) -> Prato:
	if n is Prato:
		return n as Prato
	for f in n.get_children():
		var p := _prato_di(f)
		if p != null:
			return p
	return null


func _prova() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 10:
		await get_tree().physics_frame

	var g := Player.find_in(get_tree())
	var prato := _prato_di(get_tree().root)
	if g == null or prato == null:
		print("[passi] manca il giocatore o il prato: la prova non vale")
		get_tree().quit(1)
		return
	var q := FormaPrato.quote(prato.estensione, prato.piatti, prato.recinto)
	# MANOPOLE PER CERCARE IL COLPEVOLE: rimettono il corpo com'era in altri momenti
	# senza toccare la scena. `MARGINE` è il `safe_margin`, `AGGANCIO` il
	# `floor_snap_length`.
	if OS.get_environment("MARGINE") != "":
		g.safe_margin = float(OS.get_environment("MARGINE"))
	if OS.get_environment("AGGANCIO") != "":
		g.floor_snap_length = float(OS.get_environment("AGGANCIO"))
	if OS.get_environment("FERMA") != "":
		g.floor_stop_on_slope = OS.get_environment("FERMA") == "1"
	if OS.get_environment("MAPPA") == "1":
		var col := prato.get_node("Col") as CollisionShape3D
		var n := FormaPrato.vertici(prato.estensione)
		var hm := HeightMapShape3D.new()
		hm.map_width = n.x
		hm.map_depth = n.y
		hm.map_data = q
		col.shape = hm
		col.position = Vector3(prato.estensione.position.x + (n.x - 1) * 0.5, 0.0,
			prato.estensione.position.y + (n.y - 1) * 0.5)
		for _i in 3:
			await get_tree().physics_frame
		print("[passi] prato con HeightMapShape3D")
	print("[passi] safe_margin %.3f  floor_snap_length %.3f  floor_stop_on_slope %s" % [
		g.safe_margin, g.floor_snap_length, g.floor_stop_on_slope])

	for tratto in TRATTI:
		await _cammina(g, prato, q, String(tratto[0]), tratto[1] as Vector2, tratto[2] as Vector2,
			bool(tratto[3]))

	print("")
	print("[passi] %s" % ("TUTTO A POSTO" if _guasti == 0 else "%d GUASTI" % _guasti))
	get_tree().quit(1 if _guasti > 0 else 0)


func _suolo(prato: Prato, q: PackedFloat32Array, x: float, z: float) -> float:
	return prato.position.y + FormaPrato.quota(Vector2(x, z), prato.estensione, q)


func _cammina(g: Player, prato: Prato, q: PackedFloat32Array, nome: String,
		da: Vector2, a: Vector2, corsa: bool) -> void:
	Input.action_release(&"move_forward")
	Input.action_release(&"sprint")
	var verso := (a - da).normalized()
	g.velocity = Vector3.ZERO
	g.global_position = Vector3(da.x, _suolo(prato, q, da.x, da.y) + 0.02, da.y)
	# `move_forward` spinge lungo il -Z del corpo: si gira il corpo perché -Z guardi
	# dove si vuole andare
	g.rotation = Vector3(0.0, atan2(-verso.x, -verso.y), 0.0)
	for _i in 20:
		await get_tree().physics_frame
	if not g.is_enabled():
		g.set_enabled(true)
	g.set("_mouse_free", false)

	Input.action_press(&"move_forward")
	if corsa:
		Input.action_press(&"sprint")
	var lunghezza := da.distance_to(a)
	var ys := PackedFloat32Array()
	var sopra := PackedFloat32Array()
	var stacchi := 0
	var era_a_terra := true
	var partito := Vector2(g.global_position.x, g.global_position.z)
	var passi := 0
	while passi < 1200:
		await get_tree().physics_frame
		passi += 1
		var p := g.global_position
		ys.append(p.y)
		sopra.append(p.y - _suolo(prato, q, p.x, p.z))
		var a_terra := g.is_on_floor()
		if OS.get_environment("SERIE") == "1" and nome == "prato mosso" and passi >= 40 and passi < 100:
			print("  %3d  x %6.2f  sopra %+.4f  a_terra %s  vy %+.3f  normale %s" % [
				passi, p.x, p.y - _suolo(prato, q, p.x, p.z), a_terra, g.velocity.y,
				g.get_floor_normal().snapped(Vector3.ONE * 0.001)])
		if era_a_terra and not a_terra:
			stacchi += 1
		era_a_terra = a_terra
		if Vector2(p.x, p.z).distance_to(partito) >= lunghezza:
			break
	Input.action_release(&"move_forward")
	Input.action_release(&"sprint")

	var fatti := Vector2(g.global_position.x, g.global_position.z).distance_to(partito)
	# salti di velocità verticale fra un passo e il successivo, dalla traiettoria
	var scossoni := 0
	var peggiore := 0.0
	for k in range(2, ys.size()):
		var v1 := (ys[k - 1] - ys[k - 2]) / PASSO_FISICA
		var v2 := (ys[k] - ys[k - 1]) / PASSO_FISICA
		var salto := absf(v2 - v1)
		peggiore = maxf(peggiore, salto)
		if salto > SCOSSONE:
			scossoni += 1
	var basso := 1e9
	var alto := -1e9
	for h in sopra:
		basso = minf(basso, h)
		alto = maxf(alto, h)
	print("[passi] %-16s %.1f m in %d passi | stacchi da terra %d | scossoni %d (peggiore %.2f m/s) | corpo sul terreno da %+.3f a %+.3f m" % [
		nome, fatti, ys.size(), stacchi, scossoni, peggiore, basso, alto])
	if scossoni > 0:
		_guasto("%s: %d scossoni in %.1f m, il peggiore %.2f m/s di salto verticale"
			% [nome, scossoni, fatti, peggiore])


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[passi] GUASTO: " + msg)
