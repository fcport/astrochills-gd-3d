## IL PANORAMA: il terreno vero attorno all'osservatorio, fino a quarantacinque
## chilometri, costruito all'avvio dai numeri di `tools/prendi_panorama.py`.
##
## PRIMA, oltre il prato non c'era niente: il profilo all'orizzonte era il bordo del
## prato stesso, quarantotto metri di erba sospesi nel cielo. Adesso ci sono Monte San
## Lorenzo alle spalle, la valle del Conca, il Carpegna, San Marino e il mare, dove
## stanno davvero rispetto all'edificio.
##
## DUE PEZZI, PERCHÉ SONO DUE PROBLEMI DIVERSI.
##
##   * LA GRIGLIA VICINA, ottocento metri attorno, è terreno come il prato: opaca, con la
##     collisione nei primi `raggio_collisione` metri, e ci si cammina sopra. DOVE C'È IL
##     PRATO NON C'È: il prato è la terrazza del recinto e la scarpata, e lungo il suo bordo
##     legge questa stessa superficie (`PanoramaDati.quota_griglia`), quindi le due maglie
##     si toccano su una linea. Prima la griglia stava sotto il prato trentacinque
##     centimetri più giù e ne prendeva la quota lungo il bordo, e tutto attorno al prato
##     si vedeva un gradino.
##
##   * GLI ANELLI LONTANI non si possono disegnare come il resto. Il buffer di profondità
##     ha la sua precisione vicino alla camera, che parte da cinque centimetri: a trenta
##     chilometri due creste distanti un chilometro l'una dall'altra hanno la stessa
##     profondità, e si mescolerebbero a strisce. Allora gli anelli NON SCRIVONO la
##     profondità e si disegnano DAL PIÙ LONTANO AL PIÙ VICINO, come un pittore: la cresta
##     davanti copre quella dietro perché viene dopo. L'ordine sta negli indici della mesh,
##     che la scheda video rispetta, e vale da qualunque punto del prato, perché un anello
##     comincia a settecento metri e sul prato ci si sposta di venti. La profondità la
##     LEGGONO: quello che è vicino - l'edificio, gli alberi, la griglia - li copre.
##     Per venire dopo il cielo stanno fra i trasparenti, per primi.
class_name Panorama
extends StaticBody3D

const DATI := "res://assets/panorama/panorama.tres"
const COLORE_VICINO := "res://assets/panorama/vicino_colore.jpg"
const COLORE_LONTANO := "res://assets/panorama/lontano_colore.jpg"
const MASCHERE := "res://assets/panorama/vicino_maschere.png"
## Di cosa è fatto il terreno vicino: vedi `panorama_vicino.gdshader`. L'asfalto è la
## guaina dei tetti, che da una strada di campagna a notte non si distingue.
const TRAME := {
	"prato": "res://assets/textures/prato/color.jpg",
	"sterrata": "res://assets/textures/sterrata/color.jpg",
	"sottobosco": "res://assets/textures/sottobosco/color.jpg",
	"asfalto": "res://assets/textures/tetto/color.jpg",
}
const SHADER_VICINO := preload("res://world/shaders/panorama_vicino.gdshader")
const SHADER_LONTANO := preload("res://world/shaders/panorama_lontano.gdshader")
const MODELLI_ALBERI := "res://assets/models/alberi.glb"
const SAGOME_ALBERI := "res://assets/panorama/alberi_sagome.png"
const SHADER_SAGOMA := preload("res://world/shaders/albero_sagoma.gdshader")
const SHADER_LUCI := preload("res://world/shaders/luci_paesi.gdshader")

## Di quanto gli anelli stanno sotto la griglia dove le due si sovrappongono: così la
## griglia, che scrive la profondità, vince sempre.
const SOTTO_LA_GRIGLIA := 4.0

## GLI ALBERI. Entro `RAGGIO_3D` metri dall'osservatorio sono i modelli veri di
## `tools/alberi_blender.py`; oltre, la loro foto di fianco su due rettangoli incrociati.
## VICINO È SOLO L'ALBERO SCANSIONATO (`Albero0`): le querce del set hanno il tronco
## ritorto e le radici fuori terra, e da dieci metri sembrano creature. Da lontano la loro
## chioma larga è quello che serve a variare il bosco, e restano fra le sagome.
## I due numeri della foto sono quelli di `alberi_blender.py` (LATO_M, BASE_M).
const RAGGIO_3D := 60.0
const LATO_SAGOMA := 16.0
const BASE_SAGOMA := 0.5
const VARIANTI_ALBERI := 4
## Quanto il piede di un albero sta sotto il terreno: su un pendio un tronco appoggiato
## con il suo centro resterebbe sospeso dalla parte a valle.
const INTERRATO := 0.35
## Attorno al recinto gli alberi non ci sono: il prato è sfalciato. In metri dalla rete.
const MARGINE_RECINTO := 2.0

## Il prato, di cui la griglia prende la forma lungo il bordo.
@export var prato: Prato
## Fin dove ci si cammina sopra, in metri dall'osservatorio: tutta la griglia. Con 250 m,
## tre minuti a piedi, si arrivava dove il terreno si vede e non regge, e si cadeva.
@export var raggio_collisione := 790.0
## Quanti metri copre un quadro di ogni trama: li scrive `gen_blockout.py` dai FONTE.txt,
## come per il materiale del prato.
@export var righello_prato := 2.0
@export var righello_sterrata := 2.0
@export var righello_sottobosco := 2.0
@export var righello_asfalto := 2.0

var dati: PanoramaDati
## Le quote della griglia vicina.
var _q := PackedFloat32Array()


func _ready() -> void:
	dati = load(DATI) as PanoramaDati
	if dati == null or dati.vicino_lato == 0:
		# Canale 1: nessuno ha lanciato lo script. Il gioco resta com'era, il prato nel vuoto.
		push_error("[panorama] manca %s: lancia tools/prendi_panorama.py" % DATI)
		return
	_q = dati.vicino_quote
	_griglia(_q)
	_anelli()
	_alberi()
	_luci()


## La quota del terreno in un punto (x, z), COME È DISEGNATO: sul prato dove c'è, sulla
## griglia con la sua stessa diagonale, oltre sugli anelli. Serve a posare le cose sul
## panorama.
func quota(p: Vector2) -> float:
	if prato != null:
		var sul_prato := prato.quota_mondo(p)
		if not is_nan(sul_prato):
			return sul_prato
	var n := dati.vicino_lato
	var locale := (p - dati.ancora + Vector2.ONE * dati.vicino_mezzo) / dati.vicino_passo
	if locale.x >= 0.0 and locale.y >= 0.0 and locale.x <= n - 1 and locale.y <= n - 1:
		var i := clampi(int(floor(locale.x)), 0, n - 2)
		var j := clampi(int(floor(locale.y)), 0, n - 2)
		var u := locale.x - i
		var v := locale.y - j
		var h00 := _q[j * n + i]
		var h10 := _q[j * n + i + 1]
		var h01 := _q[(j + 1) * n + i]
		var h11 := _q[(j + 1) * n + i + 1]
		if u >= v:
			return h00 + u * (h10 - h00) + v * (h11 - h10)
		return h00 + v * (h01 - h00) + u * (h11 - h01)
	var d := p - dati.ancora
	var raggi := dati.lontano_raggi
	var s := dati.lontano_settori
	var fk := clampf(log(d.length() / raggi[0]) / log(raggi[1] / raggi[0]), 0.0, raggi.size() - 1.001)
	var ft := fposmod(atan2(d.x, d.y) / TAU * s, float(s))
	var k := int(fk)
	var t := int(ft)
	var a := lerpf(dati.lontano_quote[k * s + t], dati.lontano_quote[k * s + (t + 1) % s], ft - t)
	var b := lerpf(dati.lontano_quote[(k + 1) * s + t], dati.lontano_quote[(k + 1) * s + (t + 1) % s], ft - t)
	return lerpf(a, b, fk - k)


func _punto(i: int, j: int) -> Vector2:
	return dati.ancora + Vector2(i, j) * dati.vicino_passo - Vector2.ONE * dati.vicino_mezzo


func _griglia(q: PackedFloat32Array) -> void:
	var n := dati.vicino_lato
	var passo := dati.vicino_passo
	var vertici := PackedVector3Array()
	var normali := PackedVector3Array()
	vertici.resize(n * n)
	normali.resize(n * n)
	for j in n:
		for i in n:
			var k := j * n + i
			var p := _punto(i, j)
			vertici[k] = Vector3(p.x, q[k], p.y)
			var ovest := q[j * n + maxi(i - 1, 0)]
			var est := q[j * n + mini(i + 1, n - 1)]
			var sud := q[maxi(j - 1, 0) * n + i]
			var nord := q[mini(j + 1, n - 1) * n + i]
			normali[k] = Vector3(ovest - est, 2.0 * passo, sud - nord).normalized()
	# SOLO DENTRO IL CERCHIO: gli anelli cominciano poco dentro, e un quadrato farebbe
	# gli spigoli che sporgono sopra di loro. E NON SOTTO IL PRATO.
	var indici := PackedInt32Array()
	var solidi := PackedVector3Array()
	var r2 := dati.vicino_mezzo * dati.vicino_mezzo
	var rc2 := raggio_collisione * raggio_collisione
	var buco := _sotto_il_prato()
	for j in n - 1:
		for i in n - 1:
			var c := _punto(i, j) + Vector2.ONE * passo * 0.5 - dati.ancora
			if c.length_squared() > r2:
				continue
			if buco.has_point(c + dati.ancora):
				continue
			var a := j * n + i
			for t in [a, a + 1, a + n + 1, a, a + n + 1, a + n]:
				indici.append(t)
			if c.length_squared() <= rc2:
				for t in [a, a + 1, a + n + 1, a, a + n + 1, a + n]:
					solidi.append(vertici[t])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertici
	arrays[Mesh.ARRAY_NORMAL] = normali
	arrays[Mesh.ARRAY_INDEX] = indici
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_VICINO
	mat.set_shader_parameter("colore", load(COLORE_VICINO))
	mat.set_shader_parameter("maschere", load(MASCHERE))
	mat.set_shader_parameter("centro", dati.ancora)
	mat.set_shader_parameter("mezzo", dati.vicino_mezzo)
	mat.set_shader_parameter("medio", dati.colore_vicino_medio)
	for nome: String in TRAME:
		mat.set_shader_parameter(nome, load(TRAME[nome]))
	mat.set_shader_parameter("righello_prato", righello_prato)
	mat.set_shader_parameter("righello_sterrata", righello_sterrata)
	mat.set_shader_parameter("righello_sottobosco", righello_sottobosco)
	mat.set_shader_parameter("righello_asfalto", righello_asfalto)
	if prato != null:
		mat.set_shader_parameter("origine_prato", prato.estensione.position)
		# IL PRATO SI VESTE COME LA GRIGLIA: stessa trama, stesso satellite, la ghiaia dove
		# dicono le maschere. Due materiali diversi si vedevano come due terreni.
		var terreno := prato.get_node_or_null("Terreno") as MeshInstance3D
		if terreno != null:
			terreno.material_override = mat
	var vista := MeshInstance3D.new()
	vista.name = "Vicino"
	vista.mesh = mesh
	vista.material_override = mat
	vista.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(vista)
	var forma := ConcavePolygonShape3D.new()
	forma.set_faces(solidi)
	var col := CollisionShape3D.new()
	col.name = "Col"
	col.shape = forma
	add_child(col)


## Il rettangolo delle caselle della griglia che il prato copre, allargato di un
## centimetro. I lati del prato devono stare sulle righe della griglia: se non ci stanno si
## grida e la griglia resta intera, e lungo il bordo torna il gradino.
func _sotto_il_prato() -> Rect2:
	if prato == null:
		return Rect2()
	var e := prato.estensione
	var da := (e.position - dati.ancora + Vector2.ONE * dati.vicino_mezzo) / dati.vicino_passo
	var quante := e.size / dati.vicino_passo
	var storto := absf(da.x - roundf(da.x)) + absf(da.y - roundf(da.y)) 		+ absf(quante.x - roundf(quante.x)) + absf(quante.y - roundf(quante.y))
	if storto > 1e-3:
		push_error("[panorama] il prato %s non sta sulle righe della griglia (passo %.1f da %s)"
			% [e, dati.vicino_passo, dati.ancora])
		return Rect2()
	return e.grow(0.01)


## Gli anelli, dal più lontano al più vicino: vedi in testa al file perché l'ordine È
## il disegno.
func _anelli() -> void:
	var raggi := dati.lontano_raggi
	var s := dati.lontano_settori
	var m := raggi.size()
	var vertici := PackedVector3Array()
	var normali := PackedVector3Array()
	vertici.resize(m * s)
	normali.resize(m * s)
	var fine_griglia := dati.vicino_mezzo + 50.0
	for k in m:
		var r := raggi[k]
		# dove c'è anche la griglia, un po' sotto; da cinquanta metri oltre il suo bordo, no
		var giu := SOTTO_LA_GRIGLIA * (1.0 - smoothstep(raggi[0], fine_griglia, r))
		for t in s:
			var th := TAU * t / s
			vertici[k * s + t] = Vector3(dati.ancora.x + r * sin(th),
				dati.lontano_quote[k * s + t] - giu, dati.ancora.y + r * cos(th))
	for k in m:
		for t in s:
			var p := vertici[k * s + t]
			var dentro := vertici[maxi(k - 1, 0) * s + t]
			var fuori := vertici[mini(k + 1, m - 1) * s + t]
			var sinistra := vertici[k * s + (t + s - 1) % s]
			var destra := vertici[k * s + (t + 1) % s]
			var n := (fuori - dentro).cross(sinistra - destra).normalized()
			normali[k * s + t] = n if n.y > 0.0 else -n
	var indici := PackedInt32Array()
	indici.resize((m - 1) * s * 6)
	var w := 0
	for k in range(m - 2, -1, -1):
		for t in s:
			var a := k * s + t
			var b := k * s + (t + 1) % s
			var c := (k + 1) * s + (t + 1) % s
			var d := (k + 1) * s + t
			for v in [a, c, d, a, b, c]:
				indici[w] = v
				w += 1
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertici
	arrays[Mesh.ARRAY_NORMAL] = normali
	arrays[Mesh.ARRAY_INDEX] = indici
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_LONTANO
	mat.render_priority = Material.RENDER_PRIORITY_MIN
	mat.set_shader_parameter("colore", load(COLORE_LONTANO))
	mat.set_shader_parameter("centro", dati.ancora)
	mat.set_shader_parameter("mezzo", dati.colore_lontano_mezzo)
	mat.set_shader_parameter("medio", dati.colore_lontano_medio)
	var vista := MeshInstance3D.new()
	vista.name = "Lontano"
	vista.mesh = mesh
	vista.material_override = mat
	vista.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# fra i trasparenti per primo, qualunque cosa dica la distanza del suo centro, che
	# sta sull'osservatorio
	vista.sorting_offset = -1.0e6
	vista.sorting_use_aabb_center = false
	add_child(vista)


## Gli alberi: vicino i modelli, lontano le foto. Dove stanno lo dice WorldCover
## (`prendi_panorama.py`); qui si tolgono quelli dentro il recinto e si posano sul terreno.
func _alberi() -> void:
	var scena := load(MODELLI_ALBERI) as PackedScene
	var sagome := load(SAGOME_ALBERI) as Texture2D
	if scena == null or sagome == null:
		# Canale 1: nessuno ha lanciato `tools/alberi_blender.py`. Il panorama resta calvo.
		push_error("[panorama] mancano gli alberi: lancia tools/alberi_blender.py")
		return
	var modelli := _modelli_alberi(scena)
	var rete := prato.recinto if prato != null else PackedVector2Array()
	var vicini: Array[Array] = [[], [], [], []]
	var lontani: Array[Transform3D] = []
	var colonne := PackedFloat32Array()
	for k in dati.alberi.size():
		var a := dati.alberi[k]
		var p := Vector2(a.x, a.z)
		if rete.size() >= 3 and FormaPrato.distanza_poligono(p, rete) < MARGINE_RECINTO:
			continue
		var v := dati.alberi_varianti[k]
		var modello := v % VARIANTI_ALBERI
		var base := Basis(Vector3.UP, v * TAU / 256.0).scaled(Vector3.ONE * a.y)
		var dove := Transform3D(base, Vector3(p.x, quota(p) - INTERRATO, p.y))
		if p.distance_to(dati.ancora) < RAGGIO_3D:
			vicini[0].append(dove)
		else:
			lontani.append(dove)
			colonne.append((modello + 0.5) / VARIANTI_ALBERI)
	for m in VARIANTI_ALBERI:
		if vicini[m].is_empty() or modelli[m] == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = modelli[m]
		mm.instance_count = vicini[m].size()
		for i in vicini[m].size():
			mm.set_instance_transform(i, vicini[m][i])
		var vista := MultiMeshInstance3D.new()
		vista.name = "Alberi%d" % m
		vista.multimesh = mm
		add_child(vista)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _croce()
	mm.instance_count = lontani.size()
	for i in lontani.size():
		mm.set_instance_transform(i, lontani[i])
		mm.set_instance_custom_data(i, Color(colonne[i], 0.0, 0.0, 0.0))
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_SAGOMA
	mat.set_shader_parameter("sagome", sagome)
	mat.set_shader_parameter("varianti", float(VARIANTI_ALBERI))
	var vista := MultiMeshInstance3D.new()
	vista.name = "Sagome"
	vista.multimesh = mm
	vista.material_override = mat
	vista.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(vista)


## Le mesh dei quattro alberi, con i materiali a soglia. Dal .glb le carte dei rametti
## arrivano trasparenti a fusione, che vuol dire ordinare migliaia di carte per distanza a
## ogni fotogramma e sbagliarne comunque l'ordine dentro la chioma; e con una faccia sola,
## che da dietro sparisce. E LA SCANSIONE ARRIVA SENZA LUCE (`KHR_materials_unlit`, come la
## pubblica Sketchfab per mostrare la foto tale e quale): di notte brillava bianca in mezzo
## al prato buio. Qui prende la luce come tutto il resto.
func _modelli_alberi(scena: PackedScene) -> Array[Mesh]:
	var radice := scena.instantiate()
	var fatti: Array[Mesh] = []
	for m in VARIANTI_ALBERI:
		var nodo := radice.find_child("Albero%d" % m, true, false) as MeshInstance3D
		if nodo == null:
			push_error("[panorama] in %s manca Albero%d" % [MODELLI_ALBERI, m])
			fatti.append(null)
			continue
		var mesh := nodo.mesh.duplicate() as Mesh
		for sup in mesh.get_surface_count():
			var mat := mesh.surface_get_material(sup)
			if mat is BaseMaterial3D:
				var soglia := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
				soglia.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				soglia.alpha_scissor_threshold = 0.5
				soglia.cull_mode = BaseMaterial3D.CULL_DISABLED
				soglia.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
				soglia.metallic = 0.0
				soglia.roughness = 1.0
				mesh.surface_set_material(sup, soglia)
		fatti.append(mesh)
	radice.free()
	return fatti


## Due rettangoli incrociati alti e larghi quanto la foto, con la base del tronco
## nell'origine.
func _croce() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mezzo := LATO_SAGOMA / 2.0
	var giu := Vector3(0.0, -BASE_SAGOMA, 0.0)
	var su := Vector3(0.0, LATO_SAGOMA - BASE_SAGOMA, 0.0)
	for asse: Vector3 in [Vector3.RIGHT, Vector3.BACK]:
		var angoli := [[-asse * mezzo + giu, Vector2(0, 1)], [asse * mezzo + giu, Vector2(1, 1)],
			[asse * mezzo + su, Vector2(1, 0)], [-asse * mezzo + su, Vector2(0, 0)]]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.set_uv(angoli[k][1])
			st.add_vertex(angoli[k][0])
	return st.commit()


## Le luci dei paesi: un punto arancio per lampione, dove `prendi_panorama.py` ha trovato
## case e dall'osservatorio si vedono. Vengono dopo gli anelli fra i trasparenti, che non
## scrivono la profondità: vedi `luci_paesi.gdshader`.
func _luci() -> void:
	if dati.luci.is_empty():
		return
	var quadro := QuadMesh.new()
	quadro.size = Vector2.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = quadro
	mm.instance_count = dati.luci.size()
	for i in dati.luci.size():
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, dati.luci[i]))
		mm.set_instance_custom_data(i, Color(dati.luci_potenza[i], 0.0, 0.0, 0.0))
	# i lampioni stanno sparsi su sessanta chilometri: senza un riquadro che li contenga
	# tutti, Godot li scarterebbe quando il centro esce dall'inquadratura
	mm.custom_aabb = AABB(Vector3(dati.ancora.x - 32000.0, -1000.0, dati.ancora.y - 32000.0),
		Vector3(64000.0, 4000.0, 64000.0))
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_LUCI
	mat.render_priority = Material.RENDER_PRIORITY_MIN + 1
	var vista := MultiMeshInstance3D.new()
	vista.name = "Luci"
	vista.multimesh = mm
	vista.material_override = mat
	vista.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	vista.sorting_offset = -1.0e5
	vista.sorting_use_aabb_center = false
	add_child(vista)
