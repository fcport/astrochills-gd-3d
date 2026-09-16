## LA VIA LATTEA, fotografata dal prato in una notte senza Luna.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/scatta_via_lattea.tscn
##
## Serve una finestra vera. `NOTTE=` sceglie la notte del calendario (di base la 22, il
## 7 dicembre 1999, novilunio: la Via Lattea come si vede quando si vede); `ATTESA=` i
## secondi perché l'occhio si faccia al buio (di base 62), come negli altri scatti.
##
## PRIMA DI FOTOGRAFARE, CONTROLLA IL VERSO: prende Deneb e Capella — due stelle sulla Via
## Lattea, una che tramonta a ovest e una che sorge a est — le mette in cielo da ascensione
## retta e declinazione con `TempoSiderale.equatoriale`, e rifà all'indietro il conto dello
## shader. Se l'ascensione retta non torna, la mappa è specchiata o girata, e le foto
## sarebbero belle e sbagliate.
extends Node

const CARTELLA := "res://_confronto/"
## In mezzo al prato, dove caddero la pietra del colore: da lì a nord, a ovest e a est
## il cielo è libero fino al muro di cinta.
const DA := Vector3(1.5, 0.0, 22.0)
## Ascensione retta e declinazione J2000, in gradi.
const DENEB := Vector2(310.358, 45.280)
const CAPELLA := Vector2(79.172, 45.998)

var _g: Player
var _mat: ShaderMaterial


func _ready() -> void:
	_scatta.call_deferred()


func _aspetta(secondi: float) -> void:
	var fine := Time.get_ticks_msec() + int(secondi * 1000.0)
	while Time.get_ticks_msec() < fine:
		await get_tree().process_frame


func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var dove := CARTELLA + "32_via_lattea_%s.png" % nome
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(dove))
	print("[via lattea] %s" % dove)


func _guarda(azimut: float, altezza: float, campo := 90.0) -> void:
	_g.global_position = DA
	var cam := _g.camera()
	cam.current = true
	cam.fov = campo
	var d := Orrore.verso(azimut, altezza)
	_g.rotation = Vector3(0.0, atan2(-d.x, -d.z), 0.0)
	cam.rotation.x = atan2(d.y, Vector2(d.x, d.z).length())


func _scatta() -> void:
	var notte := int(OS.get_environment("NOTTE")) if OS.get_environment("NOTTE") != "" else 22
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 30:
		await get_tree().physics_frame
	_g = Player.find_in(get_tree())
	_g.set_process(false)
	_g.set_physics_process(false)
	_g.set_process_unhandled_input(false)
	var we := Orrore.trova(get_tree().root, "WorldEnvironment") as WorldEnvironment
	_mat = we.environment.sky.sky_material as ShaderMaterial
	var cielo := TempoSiderale.find_in(get_tree())
	cielo.set_process(false)
	var luna := LuceDiLuna.find_in(get_tree())
	luna.set_process(false)
	luna.light_energy = 0.15
	_mat.set_shader_parameter("luna_dir", Vector3.DOWN)
	_mat.set_shader_parameter("luna_luce", 0.0)
	_mat.set_shader_parameter("luna_chiarore", 0.0)
	_mat.set_shader_parameter("giro", 0.0)
	var jd := Luna.istante(notte, 0.0)
	var ar0 := TempoSiderale.equatoriale(0.0, 0.0, jd)
	var ar6 := TempoSiderale.equatoriale(90.0, 0.0, jd)
	_mat.set_shader_parameter("equatore_ar0", ar0)
	_mat.set_shader_parameter("equatore_ar6", ar6)
	print("[via lattea] notte %d, %s alle 21:00; la mappa c'è: %s" % [
		notte, Luna.data_scritta(notte), float(_mat.get_shader_parameter("via_lattea_vera")) > 0.5])
	for stella in [["Deneb", DENEB], ["Capella", CAPELLA]]:
		var rd: Vector2 = stella[1]
		var d := TempoSiderale.equatoriale(rd.x, rd.y, jd)
		# il conto dello shader, all'indietro
		var polo: Vector3 = _mat.get_shader_parameter("polo_celeste")
		var ar := fposmod(rad_to_deg(atan2(d.dot(ar6), d.dot(ar0))), 360.0)
		var dec := rad_to_deg(asin(clampf(d.dot(polo.normalized()), -1.0, 1.0)))
		print("[via lattea] %s: altezza %.1f°, azimut %.1f°; lo shader la legge ad AR %.2f° e dec %.2f° (vera %.2f°, %.2f°)" % [
			stella[0], rad_to_deg(asin(d.y)), fposmod(rad_to_deg(atan2(d.x, d.z)), 360.0), ar, dec, rd.x, rd.y])
	var attesa := OS.get_environment("ATTESA")
	await _aspetta(float(attesa) if attesa != "" else 62.0)

	_guarda(290.0, 40.0)
	await _aspetta(1.0)
	await _foto("ovest")
	_guarda(330.0, 65.0)
	await _aspetta(1.0)
	await _foto("nord_ovest_alto")
	_guarda(40.0, 55.0)
	await _aspetta(1.0)
	await _foto("nord_est")
	_guarda(75.0, 25.0)
	await _aspetta(1.0)
	await _foto("est")
	# LA STESSA, CON LA LUNA: il chiarore di una luna piena alta
	_guarda(290.0, 40.0)
	_mat.set_shader_parameter("luna_chiarore", 0.8)
	await _aspetta(1.0)
	await _foto("ovest_con_la_luna")
	get_tree().quit()
