## IL RECINTO: la rete metallica verde attorno al prato, un modulo dopo l'altro.
##
## PRIMA ERANO QUATTRO MURI GRIGI alti uno e quaranta, generati insieme alle pareti. Nelle
## foto del sito il prato è chiuso da una rete a maglia romboidale plastificata verde su
## pali, e quella è adesso: il modulo di `tools/recinto_blender.py` (la rete di Poly Haven
## tagliata a un metro e mezzo) ripetuto lungo i lati, con il vano del cancello.
##
## I LATI SONO QUELLI VERI: cinque, come li disegna la Carta Tecnica Regionale attorno
## all'edificio, col cancello sullo spigolo dove arriva la sterrata (`geometria.py`, il
## posto vero). Prima era un rettangolo col varco dove capitava.
##
## LA COLLISIONE NON È QUI. Restano i blocchi `Rec` di `gen_blockout.py`, invisibili: sono
## quelli su cui il gioco ha sempre misurato i percorsi a piedi, e una rete che si lascia
## attraversare fra un palo e l'altro sarebbe un'altra cosa da collaudare.
##
## OGNI PALO STA SUL PRATO, non a quota zero: la rete segue le onde del terreno come una
## rete vera, pannello per pannello.
class_name Recinto
extends Node3D

const MODELLO := "res://assets/models/recinto.glb"
const SHADER_RETE := preload("res://world/shaders/rete.gdshader")
## La larghezza del pannello, in metri: `LARGO_M` di `tools/recinto_blender.py`.
const MODULO := 1.91
## Il verde della plastificazione, moltiplicato sulla zincatura del modello.
const VERDE := Color(0.34, 0.58, 0.38)
## Quanto la rete e i pali entrano nel terreno.
const INTERRATO := 0.05

## Gli spigoli della rete in pianta, in giro: il poligono è chiuso.
@export var spigoli := PackedVector2Array()
## Il vano del cancello: i due capi, su uno dei lati.
@export var cancello := PackedVector2Array()
## Il prato, su cui poggiano i pali.
@export var prato: Prato


func _ready() -> void:
	var scena := load(MODELLO) as PackedScene
	if scena == null:
		# Canale 1: nessuno ha lanciato `tools/recinto_blender.py`. Restano i muri invisibili.
		push_error("[recinto] manca %s: lancia tools/recinto_blender.py" % MODELLO)
		return
	var radice := scena.instantiate()
	var rete := _mesh(radice, "Rete")
	var palo := _mesh(radice, "Palo")
	radice.free()
	if rete == null or palo == null:
		return
	var lati := tratti(spigoli, cancello)
	var pannelli: Array[Transform3D] = []
	var pali: Array[Transform3D] = []
	for lato: Array in lati:
		var a: Vector2 = lato[0]
		var b: Vector2 = lato[1]
		var lungo := a.distance_to(b)
		var n := maxi(1, ceili(lungo / MODULO))
		var d := (b - a) / lungo
		var giro := Basis(Vector3.UP, atan2(-d.y, d.x))
		for k in n + 1:
			var p := a.lerp(b, float(k) / n)
			pali.append(Transform3D(Basis.IDENTITY, Vector3(p.x, _suolo(p), p.y)))
			if k == n:
				continue
			var q := a.lerp(b, float(k + 1) / n)
			var y := minf(_suolo(p), _suolo(q))
			var base := giro.scaled(Vector3(lungo / n / MODULO, 1.0, 1.0))
			pannelli.append(Transform3D(base, Vector3(p.x, y, p.y)))
	_multimesh("Reti", rete, pannelli)
	_multimesh("Pali", palo, pali)


## I tratti di rete da tirare: i lati del poligono, meno il vano del cancello. Statica, e
## la usa anche il banco.
static func tratti(poligono: PackedVector2Array, vano: PackedVector2Array) -> Array:
	var fatti := []
	var n := poligono.size()
	for k in n:
		var a := poligono[k]
		var b := poligono[(k + 1) % n]
		var su_questo := vano.size() == 2
		for q in vano:
			if Geometry2D.get_closest_point_to_segment(q, a, b).distance_to(q) > 0.01:
				su_questo = false
		if not su_questo:
			fatti.append([a, b])
			continue
		# il capo del vano più vicino ad `a` chiude il primo pezzo, l'altro apre il secondo
		var primo := vano[0] if a.distance_to(vano[0]) < a.distance_to(vano[1]) else vano[1]
		var secondo := vano[1] if primo == vano[0] else vano[0]
		if a.distance_to(primo) > 0.05:
			fatti.append([a, primo])
		if secondo.distance_to(b) > 0.05:
			fatti.append([secondo, b])
	return fatti


func _suolo(p: Vector2) -> float:
	if prato == null:
		return -INTERRATO
	return prato.position.y + FormaPrato.altezza(p, prato.sito()) - INTERRATO


## La mesh con i materiali verdi, e la maglia con `rete.gdshader`. Il filo è di tre
## millimetri: a quattro metri è meno di un pixel, e una trasparenza a soglia lo cancellava
## del tutto - restavano i pali in mezzo al prato. Il retino da solo lo diradava fino a una
## polvere verde; col recupero della copertura si vede la rete. A fusione, migliaia di
## rombi si ordinerebbero male; da dietro, con una faccia sola, sparirebbe.
func _mesh(radice: Node, nome: String) -> Mesh:
	var nodo := radice.find_child(nome, true, false) as MeshInstance3D
	if nodo == null:
		push_error("[recinto] in %s manca %s" % [MODELLO, nome])
		return null
	var mesh := nodo.mesh.duplicate() as Mesh
	for s in mesh.get_surface_count():
		var mat := mesh.surface_get_material(s) as BaseMaterial3D
		if mat == null:
			continue
		if mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			var maglia := ShaderMaterial.new()
			maglia.shader = SHADER_RETE
			maglia.set_shader_parameter("maglia", mat.albedo_texture)
			maglia.set_shader_parameter("tinta", VERDE)
			maglia.set_shader_parameter("scala", mat.uv1_scale)
			maglia.set_shader_parameter("spostamento", mat.uv1_offset)
			mesh.surface_set_material(s, maglia)
			continue
		mat = mat.duplicate() as BaseMaterial3D
		mat.albedo_color = VERDE
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.surface_set_material(s, mat)
	return mesh


func _multimesh(nome: String, mesh: Mesh, dove: Array[Transform3D]) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = dove.size()
	for i in dove.size():
		mm.set_instance_transform(i, dove[i])
	var vista := MultiMeshInstance3D.new()
	vista.name = nome
	vista.multimesh = mm
	add_child(vista)
