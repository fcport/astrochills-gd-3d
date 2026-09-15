## Uno scatto delle macchie di caffè, per GUARDARLE (D-251). `prova_mocio.gd` dice che la macchia
## c'è, dove sta e quando se ne va, non come si vede. Qui ce ne sono tre sul pavimento della
## cucina — una tazza versata, una lanciata, una lanciata e pulita a metà — fotografate da in piedi
## e da vicino.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/scatta_macchia.tscn
##
## SENZA `--headless`: lo scatto vuole la finestra. Salva `user://macchia_in_piedi.png` e
## `user://macchia_vicina.png`. Con `SCATTO_LUCI=spente` le luci restano come le accende la scena.
##
## UNA SCENA E NON UNO `--script`, come invece `scatto_cupola.gd`: da `--script` gli autoload non
## esistono, e il mondo senza `Log` e `Game` non compila. Le macchie si mettono nel mondo in
## memoria (`Game.mondo`) prima di montare la scena, e la memoria della casa le rifà da lì: nessun
## file scritto, e la partita è quella delle sonde.
extends Node

## Da in piedi si guarda da ovest, dentro la cucina: il muro sud sta a z 4,00, e la prima stesura
## ci metteva la camera dietro. L'ultima vista è il mocio, dall'ingresso del magazzino verso
## l'angolo in fondo dove sta appoggiato.
const VISTE := [
	["macchia_in_piedi", Vector3(9.10, 1.65, 3.44), Vector3(-45.0, -90.0, 0.0)],
	["macchia_vicina", Vector3(10.67, 0.75, 3.95), Vector3(-60.0, 0.0, 0.0)],
	["mocio_magazzino", Vector3(3.70, 1.50, 7.30), Vector3(-24.0, -157.0, 0.0)],
]


func _ready() -> void:
	_scatta.call_deferred()


func _scatta() -> void:
	Game.mondo.macchie = [
		_voce(Vector3(10.25, 0.0, 3.44), 0.4, false, 12.3, 1.0),
		_voce(Vector3(10.67, 0.0, 3.44), 2.1, true, 57.9, 1.0),
		_voce(Vector3(11.10, 0.0, 3.44), 4.0, true, 33.1, 0.5),
	]
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
	# LE LUCI SI ACCENDONO DOPO, per la ragione scritta in `scatto_cupola.gd`: gli interruttori
	# riapplicano il loro stato nel `_ready`, e accese prima tornerebbero spente.
	if OS.get_environment("SCATTO_LUCI") != "spente":
		_accendi_tutto(get_tree().root)
	print("[scatto] macchie in scena: %d" % get_tree().get_nodes_in_group(Macchia.GRUPPO).size())
	for vista in VISTE:
		cam.global_position = vista[1]
		cam.rotation_degrees = vista[2]
		for _i in 12:
			await get_tree().process_frame
		var fuori := "user://%s.png" % vista[0]
		get_tree().root.get_texture().get_image().save_png(fuori)
		print("[scatto] salvato %s" % ProjectSettings.globalize_path(fuori))
	get_tree().quit()


func _voce(dove: Vector3, giro: float, schizzata: bool, seme: float, sporco: float) -> Dictionary:
	return {&"xf": Macchia.trasformata_su(dove, Vector3.UP, giro),
		&"raggio": Macchia.raggio_per(1.0, schizzata), &"seme": seme,
		&"schizzata": schizzata, &"sporco": sporco}


func _accendi_tutto(n: Node) -> void:
	if n.name == "Accesa" and n is Node3D:
		(n as Node3D).visible = true
	for f in n.get_children():
		_accendi_tutto(f)
