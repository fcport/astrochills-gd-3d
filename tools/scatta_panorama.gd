## IL PANORAMA, fotografato dal prato verso i quattro punti cardinali.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/scatta_panorama.tscn
##
## Serve una FINESTRA VERA, come gli altri scatti. `GIORNO=1` accende un Sole finto e
## spegne l'adattamento al buio: di notte il terreno è giusto che si veda appena, e per
## giudicare quote, cuciture e colori serve guardarlo in piena luce. Il gioco non ha un
## giorno, e questo Sole esiste solo qui. `LUNA=` come in `scatta_orrori.gd`; `SOLO=nord`
## fa una vista sola. Gli scatti vanno in `_confronto/40_panorama_*.png`.
extends Node

const CARTELLA := "res://_confronto/"
## Dove si sta, e verso dove si guarda: piedi, azimut, altezza dello sguardo, campo.
const VISTE := {
	# davanti alla facciata, come chi esce: verso il cancello, e verso nord
	"porta": [Vector3(10.0, 0.0, 12.5), 263.0, -2.0, 75.0],
	"nord": [Vector3(10.6, 0.0, 12.0), 0.0, 2.0, 75.0],
	# sul piazzale a quattro metri dalla facciata, di fronte: la ghiaia contro il muro
	"facciata": [Vector3(11.3, 0.0, 13.8), 135.0, -4.0, 75.0],
	# sullo slargo fuori dal cancello, verso l'edificio: la foto di Street View
	"cancello": [Vector3(-6.0, 0.0, 24.5), 95.0, -6.0, 75.0],
	# sulla sterrata oltre il recinto, verso l'auto e il cancello
	"strada": [Vector3(9.0, 0.0, 32.0), 208.0, -6.0, 75.0],
	# dal fondo della terrazza, verso la valle, e dal ciglio lungo la scarpata
	"valle": [Vector3(14.0, 0.0, -13.0), 160.0, -4.0, 75.0],
	"ovest": [Vector3(3.0, 0.0, 15.0), 270.0, 0.0, 75.0],
	# dall'alto, per vedere le cuciture fra prato, griglia e anelli
	"alto": [Vector3(45.0, 60.0, -45.0), 284.0, -38.0, 75.0],
}

var _g: Player
var _scena: Node


func _ready() -> void:
	_scatta.call_deferred()


func _aspetta(secondi: float) -> void:
	var fine := Time.get_ticks_msec() + int(secondi * 1000.0)
	while Time.get_ticks_msec() < fine:
		await get_tree().process_frame


func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var dove := CARTELLA + "40_panorama_%s.png" % nome
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(dove))
	print("[panorama] %s" % dove)


## I piedi SUL TERRENO: la y della vista è quanto stare sopra il suolo, che fuori dal
## prato sale e scende di decine di metri.
func _guarda(piedi: Vector3, azimut: float, altezza: float, campo: float) -> void:
	var spazio := _g.get_world_3d().direct_space_state
	var domanda := PhysicsRayQueryParameters3D.create(
		Vector3(piedi.x, 2000.0, piedi.z), Vector3(piedi.x, -2000.0, piedi.z))
	domanda.exclude = [_g.get_rid()]
	var colpo := spazio.intersect_ray(domanda)
	var suolo: float = (colpo["position"] as Vector3).y if not colpo.is_empty() else 0.0
	_g.global_position = Vector3(piedi.x, suolo + piedi.y, piedi.z)
	var cam := _g.camera()
	cam.current = true
	cam.fov = campo
	var d := Luna.direzione(altezza, azimut)
	_g.rotation = Vector3(0.0, atan2(-d.x, -d.z), 0.0)
	cam.rotation.x = deg_to_rad(altezza)


func _scatta() -> void:
	var t0 := Time.get_ticks_msec()
	_scena = load("res://main.tscn").instantiate()
	get_tree().root.add_child(_scena)
	get_tree().current_scene = _scena
	print("[panorama] scena pronta in %d ms" % (Time.get_ticks_msec() - t0))
	for _i in 30:
		await get_tree().physics_frame
	_g = Player.find_in(get_tree())
	_g.set_process(false)
	_g.set_physics_process(false)
	_g.set_process_unhandled_input(false)
	var giorno := OS.get_environment("GIORNO") == "1"
	var luna := LuceDiLuna.find_in(get_tree())
	if luna != null:
		var forzatura := OS.get_environment("LUNA")
		if forzatura != "vera":
			luna.set_process(false)
			luna.light_energy = float(forzatura) if forzatura != "" else 0.70
	if giorno:
		for n in get_tree().root.find_children("*", "DarkAdaptation", true, false):
			n.set_process(false)
		var amb := get_viewport().world_3d.environment
		if amb == null:
			var we := get_tree().root.find_children("*", "WorldEnvironment", true, false)
			amb = (we[0] as WorldEnvironment).environment
		amb.tonemap_exposure = 1.0
		amb.ambient_light_energy = 0.6
		amb.ambient_light_color = Color(0.75, 0.82, 1.0)
		var sole := DirectionalLight3D.new()
		sole.light_energy = 2.2
		_scena.add_child(sole)
		sole.global_basis = Basis.looking_at(-Luna.direzione(35.0, 160.0), Vector3.UP)
	var solo := OS.get_environment("SOLO")
	_guarda(VISTE["nord"][0], VISTE["nord"][1], VISTE["nord"][2], VISTE["nord"][3])
	await _aspetta(2.0 if giorno else 60.0)
	for nome: String in VISTE:
		if solo != "" and solo != nome:
			continue
		var v: Array = VISTE[nome]
		_guarda(v[0], v[1], v[2], v[3])
		await _aspetta(1.5)
		print("[panorama] %s: %d fotogrammi al secondo" % [nome, Engine.get_frames_per_second()])
		await _foto(("giorno_" if giorno else "notte_") + nome)
	get_tree().quit()
