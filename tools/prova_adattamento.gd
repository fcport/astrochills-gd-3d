## Quali lampade "vede" l'adattamento al buio, e cosa ferma il raggio.
##
## `world/player/luce_prossimita.gd` decide se è buio CHIEDENDO ALLE LAMPADE:
## quanta ne arriva qui, e se da qui si vedono. La seconda metà è un raggio, e un
## raggio che non incontra quello che dovrebbe è invisibile: la lampada torna a
## contare, l'adattamento si azzera, e in partita si vede solo l'effetto — la
## stanza che smette di aprirsi addosso — mai la causa.
##
## Questa sonda mette il giocatore davanti a ogni porta CHIUSA, da tutte e due le
## parti, e stampa la somma e chi la fa, con il nodo che ha fermato il raggio.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/prova_adattamento.tscn
##
## PORTE=<pezzo di nome> guarda solo quelle; LUCI=<pezzo> accende solo quelle.
extends Node

## Quanto lontano dal battente si mette il giocatore, sui due lati.
##
## UNA GRIGLIA E NON UN PUNTO, e la differenza e' tutta qui: davanti alla porta il
## raggio verso la lampada di la' e' ripido e prende il battente in pieno. Chi
## CAMMINA lungo il corridoio passa di sbieco, e di sbieco il raggio puo' scavalcare
## il battente o sfilarsi di lato. Provare il punto comodo e' il modo di dire che
## va tutto bene.
const DISTANZE := [0.6, 1.0, 1.5, 2.2, 3.0]
## Di quanto ci si sposta di lato rispetto alla mezzeria della porta.
const LATI := [-1.6, -1.0, -0.5, 0.0, 0.5, 1.0, 1.6]

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
	var filtro := OS.get_environment("LUCI")
	if not filtro.is_empty():
		_solo(_scena, filtro)
	var giocatore := Player.find_in(get_tree())
	var luce: LuceProssimita = giocatore.get_node("Camera/LuceProssimita") if \
		giocatore.get_node_or_null("Camera/LuceProssimita") != null else _trova_luce(giocatore)
	if luce == null:
		print("[adattamento] nessuna LuceProssimita sul giocatore")
		get_tree().quit()
		return
	print("[adattamento] soglie: buio sotto %.2f, chiaro sopra %.2f"
		% [LuceProssimita.BUIO, LuceProssimita.CHIARO])

	var quali := OS.get_environment("PORTE")
	for porta in _porte(_scena):
		if not quali.is_empty() and not (quali in String(porta.name)):
			continue
		# il centro del battente, e la sua normale: la porta e' chiusa
		var mezza := 0.45
		var col := porta.get_node_or_null(^"Col") as CollisionShape3D
		if col != null and col.shape is BoxShape3D:
			mezza = (col.shape as BoxShape3D).size.x * 0.5
		var centro: Vector3 = porta.global_position + porta.global_transform.basis.x * mezza
		print("\n=== %s ===" % porta.name)
		for verso in [1.0, -1.0]:
			for d in DISTANZE:
				for lato in LATI:
					var p: Vector3 = (centro
						+ porta.global_transform.basis.z * verso * d
						+ porta.global_transform.basis.x * lato)
					p.y = 0.0
					giocatore.global_position = p
					giocatore.force_update_transform()
					luce.force_update_transform()
					_conta(luce, porta)
	get_tree().quit()


## Rifà il conto di `_altrui()` dicendo ad alta voce chi conta e chi no.
func _conta(luce: LuceProssimita, porta: Door) -> void:
	var spazio := luce.get_world_3d().direct_space_state
	var somma := 0.0
	var voci: Array[String] = []
	for L in _lampade(_scena):
		if not L.is_visible_in_tree():
			continue
		var quanto := 0.0
		var dove := Vector3.ZERO
		if L is DirectionalLight3D:
			quanto = L.light_energy
			dove = luce.global_position + L.global_transform.basis.z * 300.0
		elif L is OmniLight3D:
			var o := L as OmniLight3D
			var dist := luce.global_position.distance_to(o.global_position)
			if dist >= o.omni_range or o.omni_range <= 0.0:
				continue
			quanto = o.light_energy * pow(1.0 - dist / o.omni_range, o.omni_attenuation)
			dove = o.global_position
		else:
			continue
		if quanto < 0.02:
			continue
		var q := PhysicsRayQueryParameters3D.create(luce.global_position, dove)
		q.collision_mask = 1
		var colpo := spazio.intersect_ray(q)
		if not colpo.is_empty():
			voci.append("      %-22s %.3f  FERMATA da %s"
				% [_via(L), quanto, colpo["collider"].name])
			continue
		somma += quanto
		# PASSA DENTRO IL VANO? E' la domanda che distingue una perdita da un raggio
		# legittimo. Attraversare il PIANO della porta non vuol dire niente: quel
		# piano e' infinito e taglia mezzo edificio. Quello che conta e' se il punto
		# di attraversamento cade dentro il rettangolo del vano - e allora il raggio
		# ha attraversato una porta chiusa, cioe' un muro.
		var g := porta.global_transform
		var v_ := dove - luce.global_position
		var den := g.basis.z.dot(v_)
		if absf(den) > 1e-6:
			var t_ := g.basis.z.dot(g.origin - luce.global_position) / den
			if t_ > 0.0 and t_ < 1.0:
				var punto := luce.global_position + v_ * t_
				var loc := g.affine_inverse() * punto
				# il vano: dal cardine per tutta l'anta piu' il telaio dei due lati
				var dentro := (loc.x > -0.20 and loc.x < _larga(porta) + 0.20 and loc.y > 0.0 and loc.y < 2.10)
				if dentro:
					voci.append("      %-22s %.3f  PERDE dal vano: a quota %.3f, scostamento %.3f"
						% [_via(L), quanto, punto.y, loc.x])
					continue
		voci.append("      %-22s %.3f  arriva (per altra via)" % [_via(L), quanto])
	var stato := "BUIO" if somma <= LuceProssimita.BUIO else \
		("chiaro" if somma >= LuceProssimita.CHIARO else "penombra")
	print("  a %.2f %.2f %.2f -> somma %.3f (%s)"
		% [luce.global_position.x, luce.global_position.y, luce.global_position.z, somma, stato])
	for v in voci:
		print(v)


## Quanto e' larga l'anta, letta dalla sua collisione.
func _larga(porta: Door) -> float:
	var col := porta.get_node_or_null(^"Col") as CollisionShape3D
	if col != null and col.shape is BoxShape3D:
		return (col.shape as BoxShape3D).size.x
	return 0.90


func _via(n: Node) -> String:
	var p := n.get_parent()
	var pp := p.get_parent() if p != null else null
	return "%s/%s/%s" % [pp.name if pp != null else "?", p.name if p != null else "?", n.name]


func _porte(n: Node, fuori: Array[Door] = []) -> Array[Door]:
	var d := n as Door
	if d != null:
		fuori.append(d)
	for f in n.get_children():
		_porte(f, fuori)
	return fuori


func _lampade(n: Node, fuori: Array[Light3D] = []) -> Array[Light3D]:
	var L := n as Light3D
	if L != null and not (L is LuceProssimita):
		fuori.append(L)
	for f in n.get_children():
		_lampade(f, fuori)
	return fuori


func _trova_luce(n: Node) -> LuceProssimita:
	var L := n as LuceProssimita
	if L != null:
		return L
	for f in n.get_children():
		var t := _trova_luce(f)
		if t != null:
			return t
	return null


## Spegne tutte le lampade tranne quelle il cui percorso contiene `quali`.
func _solo(n: Node, quali: String) -> void:
	if n.name == "Accesa" and n is Node3D:
		(n as Node3D).visible = quali in String(n.get_path())
	for f in n.get_children():
		_solo(f, quali)
