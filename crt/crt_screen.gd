## Uno schermo CRT diegetico: un Control renderizzato dentro il mondo 3D.
##
## Non sa MAI cosa sta mostrando. Riceve un Control — può essere una fase, il
## negozio, il terminale — ed è questo che rende indolore l'upgrade futuro al
## raycast sul mesh (ADR-003).
class_name CrtScreen
extends Node3D

@onready var _viewport: SubViewport = %Viewport
@onready var _mesh: MeshInstance3D = %ScreenMesh
@onready var seat: Marker3D = %Seat


func _ready() -> void:
	var mat := _mesh.get_surface_override_material(0) as ShaderMaterial
	if mat == null:
		push_error("[crt] ScreenMesh senza ShaderMaterial")
		return
	mat.set_shader_parameter("screen_tex", _viewport.get_texture())

	# Le scanline si derivano dalla risoluzione, non si scelgono a mano.
	# Un numero di scanline pari all'altezza del viewport significa un ciclo di
	# seno per pixel: non sono righe, è rumore. Metà altezza è il massimo che il
	# campionamento regge.
	mat.set_shader_parameter("scanline_count", float(_viewport.size.y) * 0.5)

	Events.screen_registered.emit(self)


## Mostra un Control sullo schermo.
##
## REGOLA: il CRT non libera MAI ciò che mostra. Dopo reparent() il Control non
## è più figlio della fase, ma la proprietà resta sua — è la fase a liberarlo
## quando viene distrutta (NOTIFICATION_PREDELETE, vedi core/phase.gd). Un
## queue_free() qui distruggerebbe l'interfaccia di una fase che sta ancora
## girando in background.
func show_control(c: Control) -> void:
	for child in _viewport.get_children():
		_viewport.remove_child(child)
	if c == null:
		return
	if c.get_parent() != null:
		c.reparent(_viewport)
	else:
		_viewport.add_child(c)
	c.set_anchors_preset(Control.PRESET_FULL_RECT)


func viewport_size() -> Vector2i:
	return _viewport.size
