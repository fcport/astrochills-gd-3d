## La macchina di Gerardo (D-287): parcheggiata sullo slargo accanto alla tua, e alla
## fine del giro se ne va giù per la sterrata con i fari accesi.
##
## È LA 500 CON UN'ALTRA VERNICE, finché non ce n'è una sua: la carrozzeria si ridipinge
## qui, sul materiale della lamiera, e il resto del modello resta quello dell'auto del
## giocatore. Il modello è un segnaposto con una licenza che non si spedisce (vedi
## `tools/cinquecento_blender.py`), e questa è un'occasione in più per ricordarsene.
##
## NON GUIDA UNA FISICA, SEGUE LA STRADA. La strada è una polilinea in pianta
## (`GiroGerardo.strada`, la sterrata di OpenStreetMap); l'auto avanza lungo di essa e
## punta un punto qualche metro più avanti, così le curve si arrotondano da sole. La quota
## e il beccheggio li legge dal terreno sotto le due ruote, con due raggi.
class_name AutoDiGerardo
extends StaticBody3D

## Il materiale della lamiera nel .glb della 500: l'unico che si ridipinge.
const LAMIERA := "fiatMI_1272010001_002"

## Blu medio, una tinta di serie della 500 F. Gerardo non ha la macchina rossa.
const VERNICE := Color(0.16, 0.24, 0.42)

## Andatura sulla sterrata, in m/s: venti all'ora, quanto si fa su un fondo di ghiaia in
## discesa, di notte. Ci arriva in `SPUNTO` secondi.
const ANDATURA := 5.5
const SPUNTO := 4.0

## Quanto avanti guarda sulla strada per decidere dove puntare il muso.
const MIRA := 3.5

## Mezzo passo fra le ruote, per leggere il beccheggio dal terreno.
const MEZZO_PASSO := 1.0

## Quanto aspetta fra l'accensione dei fari e la partenza: il tempo di mettere in moto.
const MESSA_IN_MOTO := 2.0

@onready var _modello: Node3D = $Modello
@onready var _fari: FariCinquecento = $Fari


func _ready() -> void:
	for n in _modello.find_children("*", "MeshInstance3D", true, false):
		_ridipingi(n as MeshInstance3D)


func _ridipingi(mesh: MeshInstance3D) -> void:
	for i in mesh.get_surface_override_material_count():
		var m := mesh.get_active_material(i) as StandardMaterial3D
		if m == null or m.resource_name != LAMIERA:
			continue
		var nuova := m.duplicate() as StandardMaterial3D
		nuova.albedo_color = VERNICE
		mesh.set_surface_override_material(i, nuova)


## Posa l'auto in un punto della pianta, con il muso a `gradi` (zero è verso +x, come
## l'auto del giocatore), alla quota del terreno.
func posa(dove: Vector2, gradi: float) -> void:
	# il nodo nasce a quota zero, sotto lo slargo: i raggi devono partire da sopra
	global_position = Vector3(dove.x, 30.0, dove.y)
	_metti(dove, Vector2.from_angle(deg_to_rad(gradi) * -1.0))


## Accende i fari, mette in moto e percorre `strada` fino in fondo. Torna quando è arrivata.
func parti(strada: PackedVector2Array) -> void:
	_fari.accendi(true)
	await get_tree().create_timer(MESSA_IN_MOTO, false).timeout
	var lunghezza := 0.0
	for i in strada.size() - 1:
		lunghezza += strada[i].distance_to(strada[i + 1])
	var fatta := 0.0
	var andatura := 0.0
	while fatta < lunghezza:
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time()
		andatura = minf(ANDATURA, andatura + ANDATURA / SPUNTO * delta)
		fatta += andatura * delta
		var qui := lungo(strada, fatta)
		var avanti := lungo(strada, fatta + MIRA)
		_metti(qui, avanti - qui)


func _metti(dove: Vector2, muso: Vector2) -> void:
	if muso.length_squared() < 1e-6:
		return
	var f := muso.normalized()
	var davanti := _quota(dove + f * MEZZO_PASSO)
	var dietro := _quota(dove - f * MEZZO_PASSO)
	var avanti3 := Vector3(f.x, (davanti - dietro) / (2.0 * MEZZO_PASSO), f.y).normalized()
	# il muso del modello guarda +x: la base ha +x lungo la strada, e z = x × y
	var lato := avanti3.cross(Vector3.UP).normalized()
	var su := lato.cross(avanti3).normalized()
	global_transform = Transform3D(Basis(avanti3, su, lato), Vector3(dove.x, (davanti + dietro) / 2.0, dove.y))


## Il punto della polilinea a `s` metri dall'inizio; oltre la fine, l'ultimo.
static func lungo(strada: PackedVector2Array, s: float) -> Vector2:
	for i in strada.size() - 1:
		var tratto := strada[i].distance_to(strada[i + 1])
		if s <= tratto:
			return strada[i].lerp(strada[i + 1], s / tratto)
		s -= tratto
	return strada[strada.size() - 1]


## La quota del terreno sotto un punto della pianta, saltando l'auto stessa. Il raggio
## parte due metri sopra l'auto e non dal cielo: lungo la sterrata ci sono gli alberi, e
## una chioma colpita dall'alto la farebbe saltare sopra i rami.
func _quota(p: Vector2) -> float:
	var spazio := get_world_3d().direct_space_state
	var domanda := PhysicsRayQueryParameters3D.create(
			Vector3(p.x, global_position.y + 2.0, p.y), Vector3(p.x, global_position.y - 40.0, p.y))
	domanda.collision_mask = 1
	domanda.exclude = [get_rid()]
	var colpo := spazio.intersect_ray(domanda)
	return (colpo["position"] as Vector3).y if not colpo.is_empty() else global_position.y
