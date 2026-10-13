## Uno scatto qualunque dentro l'osservatorio, per GUARDARE un oggetto appena messo.
## Le altre `scatta_*` hanno le loro viste scritte dentro, perché fotografano sempre
## la stessa cosa; questa le prende da fuori, perché serve per la prima occhiata.
##
##     VISTA="12.0,1.6,3.7>12.0,0.9,1.9;11.0,1.7,3.6>12.0,1.0,2.0" Godot_v4.7.2-stable_win64.exe --path . tools/scatta_vista.tscn
##
## Ogni vista è `da>verso`, in coordinate di gioco, separate da `;`. Salva
## `user://vista_0.png`, `user://vista_1.png`... SENZA `--headless`: lo scatto vuole la
## finestra. Una scena e non uno `--script`, come `scatta_soglie.gd`.
extends Node


func _ready() -> void:
	_scatta.call_deferred()


func _scatta() -> void:
	var viste := _viste(OS.get_environment("VISTA"))
	if viste.is_empty():
		print("[scatto] manca VISTA=\"x,y,z>x,y,z;...\"")
		get_tree().quit()
		return
	var scena: Node = load("res://world/blockout.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	var giocatore := scena.get_node_or_null("Player")
	if giocatore != null:
		giocatore.queue_free()
	var cam := Camera3D.new()
	cam.fov = 60.0
	scena.add_child(cam)
	cam.current = true
	for _i in 30:
		await get_tree().physics_frame
	_accendi_tutto(get_tree().root)
	for i in viste.size():
		cam.global_position = viste[i][0]
		cam.look_at(viste[i][1], Vector3.UP)
		for _j in 12:
			await get_tree().process_frame
		var fuori := "user://vista_%d.png" % i
		get_tree().root.get_texture().get_image().save_png(fuori)
		print("[scatto] salvato %s" % ProjectSettings.globalize_path(fuori))
	get_tree().quit()


func _viste(testo: String) -> Array:
	var fuori := []
	for pezzo in testo.split(";", false):
		var due := pezzo.split(">")
		if due.size() != 2:
			continue
		fuori.append([_punto(due[0]), _punto(due[1])])
	return fuori


func _punto(testo: String) -> Vector3:
	var n := testo.split(",")
	return Vector3(float(n[0]), float(n[1]), float(n[2]))


func _accendi_tutto(n: Node) -> void:
	if n.name == "Accesa" and n is Node3D:
		(n as Node3D).visible = true
	for f in n.get_children():
		_accendi_tutto(f)
