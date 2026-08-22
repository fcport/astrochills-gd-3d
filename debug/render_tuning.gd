## I comandi con cui l'estetica PS1 è stata tarata sul campo il 2026-08-21.
##
## Venivano da `main.gd` dello spike. Quando `spike/` è stata cancellata non sono
## spariti con lei: i valori che hanno prodotto (`stretch_shrink = 2`,
## `snap_resolution = 665`) sono stati scelti guardando lo schermo, e il giorno in
## cui andranno ritarati sul gioco vero servirà di nuovo poterli muovere a caldo.
##
## TASTI — spostati sotto Shift rispetto allo spike. `F1`-`F4` sono riservati al
## controllo del tempo (FR35, storia 2.1) e non vanno occupati nemmeno per poco;
## `F9` e `F12` sono gli strumenti veri.
##
##   Shift+F1 / Shift+F2   risoluzione del mondo (stretch_shrink)
##   Shift+F3              filtro di upscale nearest <-> linear
##   Shift+F5 / Shift+F6   jitter dei vertici (snap_resolution)
##   Shift+F7              jitter di fatto spento
##
## Il comando del jitter oggi non ha bersaglio: senza `spike/` non esiste
## geometria 3D nel viewport, e la stanza vera arriva con la storia 1.2. Non è un
## errore ed è meglio non trattarlo come tale — degrada in silenzio e aspetta.
extends Node

const SNAP_STEP := 1.25
const SNAP_OFF := 8192.0
const SNAP_MIN := 16.0

var _container: SubViewportContainer
var _world: SubViewport

## Ultimo valore impostato, così l'overlay può mostrarlo anche quando non c'è
## ancora niente da far tremolare.
var snap_resolution := 665.0


func configure(container: SubViewportContainer, world: SubViewport) -> void:
	_container = container
	_world = world


func filter_name() -> String:
	if _container == null:
		return "?"
	return "NEAREST" if _container.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST else "LINEAR"


func shrink() -> int:
	return _container.stretch_shrink if _container != null else 0


func world_size() -> Vector2i:
	return _world.size if _world != null else Vector2i.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or not key.shift_pressed:
		return

	match key.keycode:
		# shrink() e non _container.stretch_shrink: l'argomento si valuta PRIMA di
		# entrare in _set_shrink, quindi la guardia contro null che sta là dentro
		# non verrebbe mai raggiunta e il tasto solleverebbe un errore invece di
		# degradare in silenzio — che è ciò che questo file promette di fare
		# finché non esiste una stanza da tarare.
		KEY_F1:
			_set_shrink(shrink() - 1)
		KEY_F2:
			_set_shrink(shrink() + 1)
		KEY_F3:
			_toggle_filter()
		KEY_F5:
			_set_snap(snap_resolution / SNAP_STEP)
		KEY_F6:
			_set_snap(snap_resolution * SNAP_STEP)
		KEY_F7:
			_set_snap(SNAP_OFF)


func _set_shrink(v: int) -> void:
	if _container == null:
		return
	_container.stretch_shrink = clampi(v, 1, 12)
	Log.debug("debug", "stretch_shrink = %d" % _container.stretch_shrink)


func _toggle_filter() -> void:
	if _container == null:
		return
	_container.texture_filter = (
		CanvasItem.TEXTURE_FILTER_LINEAR
		if _container.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST
		else CanvasItem.TEXTURE_FILTER_NEAREST
	)
	Log.debug("debug", "filtro upscale = %s" % filter_name())


## Cerca i materiali PS1 nel viewport del mondo e ci scrive dentro. Se non ne
## trova — ed è il caso di questa storia — non è un errore: la stanza non c'è
## ancora.
func _set_snap(v: float) -> void:
	snap_resolution = clampf(v, SNAP_MIN, SNAP_OFF)
	var touched := 0
	if _world != null:
		for m in _collect_materials(_world):
			m.set_shader_parameter("snap_resolution", snap_resolution)
			touched += 1
	Log.debug("debug", "snap_resolution = %.0f (%d materiali)" % [snap_resolution, touched])


func _collect_materials(node: Node) -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	var mi := node as MeshInstance3D
	if mi != null:
		var mat := mi.material_override as ShaderMaterial
		if mat != null:
			out.append(mat)
	for child in node.get_children():
		out.append_array(_collect_materials(child))
	return out
