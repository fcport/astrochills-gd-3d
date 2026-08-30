## Chi fa luce da solo, e dove sta.
##
## Serviva perche' al buio comparivano due puntini bianchi che nessuna lampada
## spiegava: non erano riflessi (si vedevano a luci spente) e non erano le
## applique esterne (il muro davanti c'e', verificato blocco per blocco). Un
## puntino che si vede al buio e' una SUPERFICIE EMISSIVA, e l'unico modo di
## sapere quale e' chiederlo alla scena invece di dedurlo.
##
##     Godot --headless --script tools/trova_emissivi.gd --quit
extends SceneTree


func _init() -> void:
	var scena: Node3D = load("res://world/blockout.tscn").instantiate()
	get_root().add_child(scena)
	var trovati: Array[String] = []
	_scava(scena, trovati)
	trovati.sort()
	print("\nsuperfici emissive nella scena: %d" % trovati.size())
	for riga in trovati:
		print("  " + riga)
	quit()


func _scava(nodo: Node, dentro: Array[String]) -> void:
	var mesh := nodo as MeshInstance3D
	if mesh != null and mesh.mesh != null:
		for i in mesh.mesh.get_surface_count():
			# l'override della scena vince sul materiale del .glb, come in gioco
			var mat: Material = mesh.get_active_material(i)
			var std := mat as StandardMaterial3D
			if std == null or not std.emission_enabled:
				continue
			if std.emission_energy_multiplier <= 0.0:
				continue
			# la posizione si ricava risalendo i padri, non con global_position:
			# in _init la scena non e' ancora dentro l'albero e quella tornerebbe
			# la matrice identita' per tutti - cioe' tutti nell'origine.
			var p: Vector3 = _dove(mesh)
			dentro.append("(%6.2f,%6.2f,%6.2f)  energia %.2f  colore %s  %s"
				% [p.x, p.y, p.z, std.emission_energy_multiplier,
				   std.emission, _via(mesh)])
	for figlio in nodo.get_children():
		_scava(figlio, dentro)


## La posizione nel mondo, moltiplicando le trasformazioni dei padri.
func _dove(nodo: Node3D) -> Vector3:
	var t := Transform3D.IDENTITY
	var n: Node = nodo
	while n != null:
		var n3 := n as Node3D
		if n3 != null:
			t = n3.transform * t
		n = n.get_parent()
	return t.origin


## Il percorso dalla radice: senza, due mesh con lo stesso nome sono
## indistinguibili, ed e' esattamente il caso delle applique.
func _via(nodo: Node) -> String:
	var pezzi: Array[String] = []
	var n: Node = nodo
	while n != null and n.get_parent() != null:
		pezzi.push_front(n.name)
		n = n.get_parent()
	return "/".join(pezzi)
