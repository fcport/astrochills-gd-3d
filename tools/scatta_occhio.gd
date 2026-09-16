## L'OCCHIO NEL CIELO, fotografato da dove lo si vedrebbe.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/scatta_occhio.tscn
##
## Serve una FINESTRA VERA, come `tools/scatta_tentacolo.gd`, e per le stesse ragioni:
## la camera è quella del giocatore, la Luna resta dov'è e le si alza solo l'energia
## (`LUNA=`, di base 0,70), e prima di aprirlo si aspetta che l'occhio del giocatore
## si faccia al buio (`ATTESA=`, di base 62 secondi; per un'occhiata veloce se ne
## può dare meno, sapendo che la scena esce più scura di come la vedrebbe chiunque).
##
## `tools/prova_occhio.gd` misura: dove sta, dove guarda, se la pupilla resta
## orizzontale, se le palpebre chiudono. Questo risponde all'altra domanda — se la
## cosa si legge come un occhio, contro il cielo di notte, da un uomo in piedi.
##
## UNO SCATTO È UN TELEOBIETTIVO, e non è quello che vede un giocatore: serve a
## guardare da vicino le cose che a campo pieno sono tre pixel — il filo della
## pupilla, il riflesso della Luna, il bordo della palpebra — e a capire se un
## difetto c'è o se è solo piccolo.
extends Node

const CARTELLA := "res://_confronto/"

## Come in `debug/occhio.gd`.
const DA := Vector3(10.6, 1.7, 10.6)
const AZIMUT := 30.0
const ALTEZZA := 50.0

## Gli scatti: nome, da dove (null = dalla porta), campo verticale in gradi, secondo
## dall'apertura, e verso dove: null è il centro dell'occhio, un vettore è una
## direzione. `CHIUDI_A` è quando gli si chiede di chiudersi.
##
## DUE SCATTI NON GUARDANO L'OCCHIO, e sono quelli che dicono quanto è grande: chi esce
## dalla porta guarda dritto davanti a sé, e chi alza appena la testa guarda a
## trenta gradi. Inquadrato al centro un occhio sta sempre bene; la domanda è quanto
## cielo si prende quando non lo si sta cercando.
##
## E UNO GUARDA IL CANTO, dove le due palpebre si incontrano sull'orlo: è il punto in
## cui tre superfici si toccano, e a campo pieno è troppo piccolo per giudicarlo.
const SCATTI := [
	["compare", null, 75.0, 6.0],
	["chiuso", null, 75.0, 19.5],
	["spiraglio", null, 75.0, 23.0],
	["cerca", null, 75.0, 27.0],
	["uscendo", null, 75.0, 30.0, Vector3(0.0, 0.08, 1.0)],
	["alzando_la_testa", null, 75.0, 31.5, Vector3(0.29, 0.58, 0.76)],
	["ti_guarda", null, 75.0, 33.0],
	["ti_guarda_da_vicino", null, 16.0, 34.0],
	["il_canto", null, 12.0, 35.0, "canto"],
	["dal_piazzale", Vector3(21.0, 1.7, 28.0), 75.0, 38.0],
	["dal_piazzale_da_vicino", Vector3(21.0, 1.7, 28.0), 16.0, 41.0],
	["si_chiude", null, 75.0, 46.5],
	["svanisce", null, 75.0, 52.0],
]
const CHIUDI_A := 45.0

var _camera: Camera3D


func _ready() -> void:
	_scatta.call_deferred()


func _scatta() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 30:
		await get_tree().process_frame

	var g := Player.find_in(get_tree())
	if g == null:
		print("[occhio] niente giocatore: non c'è da dove guardare")
		get_tree().quit(1)
		return
	g.set_process(false)
	g.set_physics_process(false)
	g.set_process_unhandled_input(false)
	_camera = g.get_node_or_null("Camera") as Camera3D

	var luna := LuceDiLuna.find_in(get_tree())
	if luna != null:
		luna.set_process(false)
		# `LUNA=vera` lascia la luce della notte com'è: è come la vedrà il giocatore.
		var forzatura := OS.get_environment("LUNA")
		if forzatura != "vera":
			luna.light_energy = float(forzatura) if forzatura != "" else 0.70
		var verso_luna := luna.global_basis.orthonormalized().z
		print("[occhio] Luna a %.0f° d'altezza, energia %.2f" % [
			rad_to_deg(asin(clampf(verso_luna.y, -1.0, 1.0))), luna.light_energy])

	var o := (load("res://world/occhio.tscn") as PackedScene).instantiate() as Occhio
	var attesa := float(OS.get_environment("ATTESA")) if OS.get_environment("ATTESA") != "" else 62.0
	_inquadra(DA, DA + Vector3(0.5, 0.45, 0.87) * 100.0, 75.0, g)
	var atteso := 0.0
	while atteso < attesa:
		await get_tree().process_frame
		atteso += get_process_delta_time()

	scena.get_node("%SubViewport").add_child(o)
	o.colloca(DA, AZIMUT, ALTEZZA)
	o.apri()

	var passato := 0.0
	var chiesto := false
	for s in SCATTI:
		var quando := float(s[3])
		while passato < quando:
			await get_tree().process_frame
			passato += get_process_delta_time()
			if not chiesto and passato >= CHIUDI_A:
				o.chiudi()
				chiesto = true
		var da: Vector3 = DA if s[1] == null else s[1]
		var a := o.global_position
		if s.size() > 4 and s[4] is Vector3:
			a = da + (s[4] as Vector3).normalized() * 100.0
		elif s.size() > 4:
			a = o.global_position + o.testa().global_basis * Vector3(
					sin(Occhio.CANTO), 0.0, -cos(Occhio.CANTO))
		_inquadra(da, a, float(s[2]), g)
		await get_tree().process_frame
		await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		var dove := CARTELLA + "29_occhio_%s.png" % s[0]
		img.save_png(ProjectSettings.globalize_path(dove))
		print("[occhio] %5.1f s  %-9s presenza %.2f  apertura %.2f  pupilla %.2f×%.2f  %s" % [
			passato, o.fase(), o.presenza(), o.apertura(), o.pupilla().x, o.pupilla().y, dove])
	get_tree().quit()


func _inquadra(da: Vector3, a: Vector3, campo: float, g: Node3D) -> void:
	g.global_position = Vector3(da.x, da.y - 1.7, da.z)
	if _camera != null:
		_camera.fov = campo
		_camera.look_at_from_position(da, a, Vector3.UP)
