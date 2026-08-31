## Ci si siede al monitor del blockout, e si guarda cosa si vede.
##
## MISURA E FOTOGRAFA, e servono tutte e due. I numeri dicono se il corpo è
## arrivato dove doveva — è l'unica cosa che un `assert` può sapere — ma non
## dicono se lo schermo è inquadrato bene, e quello è precisamente ciò per cui la
## postazione esiste. Il difetto del `Seat` a segno invertito, che ha inquadrato
## metà schermo per due storie, era corretto in ogni suo numero.
##
## E' UNA SCENA E NON UNO `--script`, ed e' obbligatorio: `--script` non monta gli
## autoload, e `crt/crt_screen.gd` emette `Events.screen_registered`. Senza `Events`
## quel file non compila, il nodo del vetro nasce come `Node3D` nudo, e la sonda
## misurerebbe una postazione che non esiste dicendo che e' rotta.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/prova_postazione.tscn
##
## Scrive user://postazione.png, cioè
## %APPDATA%/Godot/app_userdata/<progetto>/postazione.png
extends Node

const FUORI := "user://postazione.png"
## Quanto si aspetta al massimo che la transizione finisca, in SECONDI.
##
## SI ASPETTA IL FATTO, NON UN CONTEGGIO, ed è una correzione di questa stessa
## sessione. La prima stesura contava sessanta fotogrammi «perché mezzo secondo a
## 60 fps sono trenta»: solo che questa finestra non ha il vsync e ne macina
## cinquecento al secondo, così sessanta fotogrammi sono un decimo di secondo. La
## sonda ha fotografato la camera a metà corsa e ha riferito `seduti: false` con la
## testa a 14 cm dal sedile — cioè ha dato per rotta una postazione che
## funzionava. Un tempo che dipende da quanto va veloce la macchina non è una
## misura.
const LIMITE := 3.0

var _fase := 0
var _conto := 0
var _tempo := 0.0
var _scena: Node3D


func _ready() -> void:
	# Differito: dentro `_ready()` la radice sta ancora montando i propri figli e
	# `add_child()` viene rifiutato.
	_monta.call_deferred()


func _monta() -> void:
	var scena: Node3D = load("res://world/blockout.tscn").instantiate()
	# PRIMA in albero, POI scena corrente: `set_current_scene()` rifiuta un nodo che
	# non sia già figlio della radice. `world/desk_station.gd` legge `current_scene`
	# per sapere se la postazione è sua, e lo legge differito di un frame proprio
	# perché questo ordine e quello del motore sono opposti.
	#
	# E non `change_scene_to_file()`, che sarebbe la via normale: quella LIBERA la
	# scena corrente, cioè questa sonda, che sparirebbe prima di misurare qualsiasi
	# cosa.
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena


func _process(_d: float) -> void:
	_conto += 1
	var current_scene := get_tree().current_scene
	if current_scene == null or current_scene == self:
		return
	if _scena == null:
		_scena = current_scene as Node3D
		_conto = 0
		return

	if _fase == 0 and _conto > 4:
		_fase = 1
		_conto = 0
		var monitor := CrtMonitor.find_in(get_tree())
		if monitor == null:
			print("[postazione] NESSUN MONITOR: il gruppo è vuoto")
			_fine()
			return
		var stazione := _scena as DeskStation
		if stazione == null:
			print("[postazione] la radice non è una DeskStation")
			_fine()
			return
		if _scena.get_node_or_null("DeskCamera") == null:
			print("[postazione] la DeskCamera non è stata montata")
			_fine()
			return
		var vetro := monitor.screen()
		var sedile := vetro.seat.global_transform
		print("[postazione] vetro  %s" % _v(vetro.get_node("%ScreenMesh").global_position))
		print("[postazione] sedile %s  beccheggio %.1f gradi"
			% [_v(sedile.origin), rad_to_deg(sedile.basis.get_euler().x)])
		# quanto dell'inquadratura occupa l'immagine, da seduti
		var mesh := vetro.get_node("%ScreenMesh").mesh as QuadMesh
		var lontano := sedile.origin.distance_to(vetro.get_node("%ScreenMesh").global_position)
		print("[postazione] immagine %.3f x %.3f a %.3f m: %.1f gradi su %.1f di campo (%.0f%%)"
			% [mesh.size.x, mesh.size.y, lontano,
				rad_to_deg(2.0 * atan((mesh.size.y * 0.5) / lontano)),
				DeskCamera.SEATED_FOV,
				rad_to_deg(2.0 * atan((mesh.size.y * 0.5) / lontano)) / DeskCamera.SEATED_FOV * 100.0])
		# LUCE=<energia> sovrascrive la luce finta del monitor. Serve a scegliere quel
		# numero MISURANDO invece che a occhio: con 0 si vede il fondo, cioe' quanto
		# della cassa e' illuminato da tutto il resto, e la differenza dice quanta ne
		# aggiunge il monitor. A occhio una cassa beige illuminata e una bruciata sono
		# tutte e due "chiare".
		# SAGOMA=1 dipinge il quad di magenta piatto. Serve a vedere DOVE CADE il
		# rettangolo dell'immagine rispetto al foro della cassa: con lo shader acceso
		# i bordi sono curvi, sfumati e vignettati, e non si sa piu' se un margine
		# storto e' il quad fuori posto o la curvatura del tubo.
		# QUAD=<larghezza>,<altezza> rimisura il vetro senza rigenerare la scena:
		# serve a provare una misura prima di scriverla in geometria.py.
		var q := OS.get_environment("QUAD")
		if not q.is_empty():
			var n := q.split(",")
			var m2 := (vetro.get_node("%ScreenMesh") as MeshInstance3D).mesh as QuadMesh
			m2.size = Vector2(float(n[0]), float(n[1]))
		if not OS.get_environment("SAGOMA").is_empty():
			var sm := vetro.get_node("%ScreenMesh") as MeshInstance3D
			var piatto := StandardMaterial3D.new()
			piatto.albedo_color = Color(1, 0, 1)
			piatto.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			sm.set_surface_override_material(0, piatto)
		var e := OS.get_environment("LUCE")
		if not e.is_empty():
			var l := _scena.get_node_or_null("LuceMonitor") as OmniLight3D
			if l != null:
				l.light_energy = float(e)
		monitor.interact(_scena)
		return

	if _fase == 1:
		_tempo += _d
		var desk_ := (_scena as DeskStation).get_node("DeskCamera") as DeskCamera
		if not desk_.is_seated and _tempo < LIMITE:
			return
		if not desk_.is_seated:
			print("[postazione] NON SEDUTO dopo %.1f s: la transizione non è finita" % LIMITE)
			_fine()
			return
		_fase = 2
		_conto = 0
		var stazione := _scena as DeskStation
		var desk: DeskCamera = stazione.get_node("DeskCamera")
		var vetro := CrtMonitor.find_in(get_tree()).screen()
		var cam := Player.find_in(get_tree()).camera()
		print("[postazione] seduti: %s   schermo vivo: %s   input: %s"
			% [desk.is_seated, vetro.is_live(), vetro.is_input_enabled()])
		print("[postazione] la testa è a %s, il sedile a %s: scarto %.1f mm"
			% [_v(cam.global_position), _v(vetro.seat.global_position),
				cam.global_position.distance_to(vetro.seat.global_position) * 1000.0])
		print("[postazione] FOV %.1f  beccheggio della testa %.1f gradi"
			% [cam.fov, rad_to_deg(cam.rotation.x)])
		return

	if _fase == 2 and _conto > 6:
		var img: Image = get_viewport().get_texture().get_image()
		img.save_png(FUORI)
		print("[postazione] scatto in %s" % ProjectSettings.globalize_path(FUORI))
		_fine()
		return


func _fine() -> void:
	get_tree().quit()


func _v(p: Vector3) -> String:
	return "%.3f, %.3f, %.3f" % [p.x, p.y, p.z]
