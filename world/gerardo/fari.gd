## I fari di una 500 (D-287): due proiettori davanti, e dietro i vetri rossi che si
## accendono. Li usano tutte e due le auto — quella di Gerardo quando se ne va, e la tua
## all'arrivo della prima notte, che lo illumina mentre ti aspetta sullo slargo.
##
## I FANALINI SONO VETRI CHE BRILLANO, NON LAMPADE. Una luce rossa vera, anche piccola,
## faceva sul prato una pozza larga quanto quella dei fari: un fanalino si vede, non
## illumina. Si accende l'emissione dei vetri del modello — il rosso dietro, il vetro dei
## proiettori davanti — e resta una luce minima, perché da vicino il terreno sotto il
## paraurti si tinge davvero.
class_name FariCinquecento
extends Node3D

## I vetri del modello che si accendono, per nome di materiale, con il loro colore.
const VETRI := {
	"fiatred_glass": Color(1.0, 0.06, 0.03),
	"fiatMI_Glass_Light1": Color(1.0, 0.93, 0.78),
}
const ENERGIA_VETRI := 2.5

var _vetri: Array[StandardMaterial3D] = []


func _ready() -> void:
	var modello := get_parent().get_node_or_null(^"Modello")
	if modello != null:
		for n in modello.find_children("*", "MeshInstance3D", true, false):
			_prendi_vetri(n as MeshInstance3D)
	accendi(visible)


## I vetri si duplicano: il materiale del .glb è condiviso con l'altra 500, e accendere i
## fanalini di una accenderebbe anche quelli dell'altra.
func _prendi_vetri(mesh: MeshInstance3D) -> void:
	for i in mesh.get_surface_override_material_count():
		var m := mesh.get_active_material(i) as StandardMaterial3D
		if m == null or not VETRI.has(m.resource_name):
			continue
		var proprio := m.duplicate() as StandardMaterial3D
		proprio.emission = VETRI[m.resource_name]
		mesh.set_surface_override_material(i, proprio)
		_vetri.append(proprio)


func accendi(accesi: bool) -> void:
	visible = accesi
	for m in _vetri:
		m.emission_enabled = accesi
		m.emission_energy_multiplier = ENERGIA_VETRI
