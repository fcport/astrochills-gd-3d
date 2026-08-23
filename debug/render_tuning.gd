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
##   Shift+F8 / Shift+F9   passo del giocatore (metri al secondo)
##
## Il comando del jitter ha un bersaglio dalla storia 1.2: la stanza computer, i
## suoi arredi e la scocca del monitor usano tutti `material_override` su
## `ps1.gdshader`, che è la sola forma che `_collect_materials()` sa raccogliere.
## Se un giorno il log dicesse «0 materiali», la causa da guardare per prima è una
## mesh nuova finita su `surface_material_override/0`.
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
		KEY_F8:
			_step_walk(-0.2)
		KEY_F9:
			_step_walk(0.2)
		KEY_F10:
			_step_sprint(-0.2)
		KEY_F11:
			_step_sprint(0.2)
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


## Cerca i materiali PS1 nel viewport del mondo e ci scrive dentro. Il conteggio
## nel log è per MeshInstance3D, non per materiale distinto: la stanza condivide
## un materiale fra più pareti, e quello stesso materiale viene scritto — e
## contato — una volta per ogni mesh che lo usa.
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


## Il passo, cambiato mentre si cammina. E' il solo modo di trovarlo: un numero di
## metri al secondo non dice niente finche' non lo si prova dentro la stanza vera.
func _step_walk(delta_speed: float) -> void:
	Player.walk_speed = clampf(Player.walk_speed + delta_speed, 0.4, 6.0)
	Log.debug("render", "passo %.1f m/s" % Player.walk_speed)


## Lo scatto si tara separatamente dal passo, e non come un multiplo: sono due
## sensazioni diverse — quanto il posto è lento e quanto il giocatore ha fretta —
## e legarle costringerebbe a scegliere quale delle due sacrificare.
func _step_sprint(delta_speed: float) -> void:
	Player.sprint_speed = clampf(Player.sprint_speed + delta_speed, 0.4, 12.0)
	Log.debug("render", "scatto %.1f m/s" % Player.sprint_speed)
