## IL PRATO SOTTO LE PORTE, per GUARDARLO. Federico: «perché c'è l'erba dentro l'osservatorio?».
##
## Il prato corre sotto tutta la casa, tre centimetri sotto i pavimenti, e i pavimenti si
## ritirano di mezzo muro: sotto la porta fra corridoio e spazio divulgazione, e sotto
## l'ingresso, il vano aveva l'erba per tutto lo spessore del muro. `verifica_soglie()` in
## `gen_blockout.py` dice che adesso sotto ogni porta c'è pavimento; se si VEDE lo dice questo
## scatto, dal corridoio e da dentro l'ingresso, con le porte aperte.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/scatta_soglie.tscn
##
## SENZA `--headless`: lo scatto vuole la finestra. Salva `user://soglia_corridoio.png` e
## `user://soglia_ingresso.png`. Una scena e non uno `--script`, come `scatta_macchia.gd`.
extends Node

## Il vano del corridoio sta sul muro x 8,25, da z 4,92 a 5,98; quello dell'ingresso sul muro
## z 9,50, da x 10,00 a 11,20. Si guarda in giù, da un passo prima.
const VISTE := [
	["soglia_corridoio", Vector3(7.40, 1.60, 5.45), Vector3(-55.0, -90.0, 0.0)],
	["soglia_ingresso", Vector3(10.60, 1.60, 8.40), Vector3(-55.0, 180.0, 0.0)],
]


func _ready() -> void:
	_scatta.call_deferred()


func _scatta() -> void:
	var scena: Node = load("res://world/blockout.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	# Il giocatore muoverebbe la camera: qui serve un punto fermo.
	var giocatore := scena.get_node_or_null("Player")
	if giocatore != null:
		giocatore.queue_free()
	var cam := Camera3D.new()
	cam.fov = 55.0
	scena.add_child(cam)
	cam.current = true
	for _i in 30:
		await get_tree().physics_frame
	# Le porte aperte, o l'anta chiusa copre proprio la striscia da guardare.
	var porte := 0
	for n in _tutti(scena):
		if n is Door:
			(n as Door).set_open(true, true)
			porte += 1
	# LE LUCI SI ACCENDONO DOPO, per la ragione scritta in `scatto_cupola.gd`.
	_accendi_tutto(get_tree().root)
	print("[scatto] porte aperte: %d" % porte)
	for vista in VISTE:
		cam.global_position = vista[1]
		cam.rotation_degrees = vista[2]
		for _i in 12:
			await get_tree().process_frame
		var fuori := "user://%s.png" % vista[0]
		get_tree().root.get_texture().get_image().save_png(fuori)
		print("[scatto] salvato %s" % ProjectSettings.globalize_path(fuori))
	get_tree().quit()


func _tutti(n: Node) -> Array[Node]:
	var out: Array[Node] = [n]
	for f in n.get_children():
		out.append_array(_tutti(f))
	return out


func _accendi_tutto(n: Node) -> void:
	if n.name == "Accesa" and n is Node3D:
		(n as Node3D).visible = true
	for f in n.get_children():
		_accendi_tutto(f)
