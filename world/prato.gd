## IL PRATO, costruito all'avvio dalla sua forma: il terreno, la collisione e l'erba.
##
## PRIMA ERA UNA SCATOLA da quarantotto metri per quarantaquattro, verde e piatta,
## generata insieme ai muri. Adesso è una maglia da un metro che sale e scende come
## dice `FormaPrato` - la terrazza del recinto e la scarpata fino al terreno vero - con
## sopra qualche migliaio di ciuffi d'erba.
##
## IL COLORE DEL TERRENO LO DÀ IL PANORAMA: la stessa trama della sua griglia, con la
## ghiaia e il viottolo dove dicono le sue maschere (`Panorama._griglia`). Col materiale
## suo il prato era un tappeto d'erba diverso da tutto quello che gli stava attorno.
##
## QUELLO CHE SI VEDE E QUELLO SU CUI SI CAMMINA SONO LA STESSA MAGLIA: la collisione
## nasce dagli stessi triangoli della mesh, e i ciuffi si posano sulla maglia, non
## sulla formula.
##
## L'ERBA È UN CIUFFO VERO, non una forma inventata: `tools/erba_blender.py`
## fotografa di fianco i ciuffi di `grass_medium_02` (Poly Haven, CC0) e li mette in
## fila in una texture. Qui ogni ciuffo è due rettangoli incrociati con quella foto
## sopra, come l'erba della PlayStation.
class_name Prato
extends StaticBody3D

const TEXTURE_CIUFFI := "res://assets/textures/erba_ciuffi.png"
const SHADER_ERBA := preload("res://world/shaders/erba.gdshader")

## Una quota di impronta che vuol dire «dove il terreno già sta» (`quote_piatti`).
const SUL_TERRENO := -9999.0

## Il lato del rettangolo di un ciuffo, in metri: è il lato della fotografia di
## `tools/erba_blender.py` (LATO_M), e il banco controlla che i due numeri coincidano.
## Diversi, l'erba verrebbe tutta più grande o più piccola del vero.
const LATO_CIUFFO := 0.42

## Di quanto la base di un ciuffo sta sotto il terreno. Su un pendio un rettangolo che
## poggia col bordo resta sospeso da una parte.
const INTERRATO := 0.015

## Le due tinte fra cui sta ogni ciuffo, moltiplicate sul colore della fotografia. A
## novembre un prato di montagna è metà verde e metà paglia.
const VERDE := Color(0.70, 1.0, 0.70)
const SECCO := Color(1.0, 0.95, 0.80)

## Il rettangolo di prato, in pianta: x, z, larghezza, profondità. I LATI STANNO SULLE
## RIGHE DELLA GRIGLIA DEL PANORAMA, che sotto il prato non c'è: un lato a metà di una
## sua casella lascerebbe un buco lungo tutto il bordo. Lo controlla il banco.
@export var estensione := Rect2(-35.5, -45.25, 90.0, 95.0)
## La rete, come poligono chiuso: dentro la terrazza, fuori la scarpata.
@export var recinto := PackedVector2Array()
## Le impronte attorno a cui il terreno resta piatto: l'edificio e l'auto.
@export var piatti: Array[Rect2] = []
## A che quota sta ogni impronta, in coordinate del prato: l'edificio a zero. `SUL_TERRENO`
## vuol dire dove il posto già sta, al centro dell'impronta: è l'auto sulla sterrata.
@export var quote_piatti := PackedFloat32Array()
## Dove l'erba non cresce: sotto l'edificio, che ha i pavimenti, e sotto l'auto.
@export var senza_erba: Array[Rect2] = []
## La ghiaia, dove l'erba non cresce: il piazzale e lo slargo del cancello.
@export var ghiaia: Array[PackedVector2Array] = []
## Fin dove l'erba passa la rete, in metri: oltre è la scarpata, col terreno del panorama.
@export var erba_oltre := 3.0
@export var materiale: Material
@export var seme := 1999
@export var ciuffi_per_m2 := 12.0


var _sito: FormaPrato.Sito
var _q := PackedFloat32Array()


func _ready() -> void:
	var q := FormaPrato.quote(sito())
	_q = q
	var mesh := _terreno(q)
	var vista := MeshInstance3D.new()
	vista.name = "Terreno"
	vista.mesh = mesh
	vista.material_override = materiale
	add_child(vista)
	var forma := CollisionShape3D.new()
	forma.name = "Col"
	forma.shape = mesh.create_trimesh_shape()
	add_child(forma)
	_erba(q)


## Quello che decide la forma del prato: le misure del generatore, e il terreno vero del
## panorama, che il prato legge prima che il panorama si costruisca.
func sito() -> FormaPrato.Sito:
	if _sito != null:
		return _sito
	_sito = FormaPrato.Sito.new()
	_sito.estensione = estensione
	_sito.recinto = recinto
	_sito.base = position.y
	if ResourceLoader.exists(Panorama.DATI):
		var dati := load(Panorama.DATI) as PanoramaDati
		if dati != null and dati.vicino_lato > 0:
			_sito.rilievo = dati
	# le impronte che stanno dove stanno: la quota del posto al loro centro, senza piatti
	var quote := quote_piatti.duplicate()
	for k in mini(quote.size(), piatti.size()):
		if quote[k] <= SUL_TERRENO + 1.0:
			quote[k] = FormaPrato.altezza(piatti[k].get_center(), _sito)
	_sito.piatti = piatti
	_sito.quote_piatti = quote
	return _sito


## La quota del terreno nel mondo, in un punto del prato, come la disegna la maglia. NAN
## fuori: lì il terreno è la griglia del panorama.
func quota_mondo(p: Vector2) -> float:
	if _q.is_empty() or not estensione.has_point(p):
		return NAN
	return position.y + FormaPrato.quota(p, estensione, _q)


## La maglia del terreno. Le NORMALI SI CALCOLANO DALLE QUOTE VICINE e non dal verso dei
## triangoli: la luce del prato è per vertice, e una normale sbagliata lo farebbe nero
## da un lato di ogni gobba.
func _terreno(q: PackedFloat32Array) -> ArrayMesh:
	var n := FormaPrato.vertici(estensione)
	var passo := FormaPrato.PASSO
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in n.y:
		for i in n.x:
			var ovest := q[j * n.x + maxi(i - 1, 0)]
			var est := q[j * n.x + mini(i + 1, n.x - 1)]
			var nord := q[maxi(j - 1, 0) * n.x + i]
			var sud := q[mini(j + 1, n.y - 1) * n.x + i]
			st.set_normal(Vector3(ovest - est, 2.0 * passo, nord - sud).normalized())
			# LE COORDINATE DI TEXTURE SONO IN METRI: quanti metri copre un quadro della
			# mappa lo dice il materiale (`uv1_scale`, scritto da `gen_blockout.py`)
			st.set_uv(Vector2(i, j) * passo)
			st.add_vertex(Vector3(estensione.position.x + i * passo, q[j * n.x + i],
				estensione.position.y + j * passo))
	for j in n.y - 1:
		for i in n.x - 1:
			var a := j * n.x + i
			for k in [a, a + 1, a + n.x + 1, a, a + n.x + 1, a + n.x]:
				st.add_index(k)
	# senza tangenti la mappa delle normali del prato non ha un verso, e non si vede
	st.generate_tangents()
	return st.commit()


func _erba(q: PackedFloat32Array) -> void:
	var foto := load(TEXTURE_CIUFFI) as Texture2D
	if foto == null:
		# Canale 1: manca la texture, cioè nessuno ha lanciato `tools/erba_blender.py`.
		# Il prato resta senza erba invece di riempirsi di rettangoli bianchi.
		push_error("[prato] manca %s: lancia tools/erba_blender.py" % TEXTURE_CIUFFI)
		return
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_ERBA
	mat.set_shader_parameter("ciuffi", foto)
	mat.set_shader_parameter("varianti", float(FormaPrato.VARIANTI))
	var dove := FormaPrato.ciuffi(seme, ciuffi_per_m2, estensione, senza_erba, recinto, erba_oltre,
		ghiaia)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _ciuffo()
	mm.instance_count = dove.size()
	for k in dove.size():
		var c: Array = dove[k]
		var p: Vector2 = c[0]
		var base := Basis(Vector3.UP, c[1]).scaled(Vector3.ONE * float(c[2]))
		mm.set_instance_transform(k, Transform3D(base,
			Vector3(p.x, FormaPrato.quota(p, estensione, q), p.y)))
		# nel rosso la colonna della texture, nel resto la tinta: vedi `erba.gdshader`
		var tinta := VERDE.lerp(SECCO, c[4])
		mm.set_instance_custom_data(k, Color((int(c[3]) + 0.5) / FormaPrato.VARIANTI,
			tinta.r, tinta.g, tinta.b))
	var erba := MultiMeshInstance3D.new()
	erba.name = "Erba"
	erba.multimesh = mm
	erba.material_override = mat
	# migliaia di rettangoli nella mappa delle ombre costano più di quanto si vedano
	erba.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(erba)


## Il ciuffo: due rettangoli incrociati ad angolo retto, con la NORMALE IN SU. Con la
## normale di taglio ogni ciuffo prenderebbe la luce di un muro, e a seconda di come è
## girato sarebbe acceso o spento accanto al prato che gli sta sotto.
func _ciuffo() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mezzo := LATO_CIUFFO / 2.0
	var giu := Vector3(0.0, -INTERRATO, 0.0)
	var su := Vector3(0.0, LATO_CIUFFO - INTERRATO, 0.0)
	for asse: Vector3 in [Vector3.RIGHT, Vector3.BACK]:
		var angoli := [[-asse * mezzo + giu, Vector2(0, 1)], [asse * mezzo + giu, Vector2(1, 1)],
			[asse * mezzo + su, Vector2(1, 0)], [-asse * mezzo + su, Vector2(0, 0)]]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.set_uv(angoli[k][1])
			st.add_vertex(angoli[k][0])
	return st.commit()
