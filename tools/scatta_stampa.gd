## Gli scatti della stampa, per GUARDARLA invece di dedurla: mentre esce, uscita, in mano,
## appesa.
##
## `prova_stampa.gd` misura che la carta esca dalla macchina, stia a filo del muro e sia
## girata dalla parte giusta. Non vede se la foto si legge, se i fori del trattore
## sembrano fori, se in mano copre mezzo schermo: quello si guarda, con la finestra.
##
##     Godot_v4.7.2-stable_win64.exe --path . --resolution 1280x720 res://tools/scatta_stampa.tscn
##
## Gli scatti vanno in `user://shots/stampa_*.png`. Il save del giocatore si mette da parte
## e si rimette com'era, come nella sonda. `SCATTO_FARO=1` accende una lampada sulla testa:
## al buio una foto appesa è un rettangolo nero, e per giudicarla serve vederla.
extends Node

const SALVATAGGIO := "user://saves/profile.tres"
const COPIA := "user://saves/profile.scatta_stampa.tres"

## Un posto della sala da cui, guardando dritto, c'è un muro buono: lo ha trovato
## `prova_stampa.gd` (da x 7,20 z 1,60, a 247 gradi, sul muro).
const DAVANTI_AL_MURO := Vector3(7.20, 0.0, 1.60)
const VERSO_IL_MURO := 11.0 / 16.0 * TAU

var _giocatore: Player


func _ready() -> void:
	_scatta.call_deferred()


func _aspetta(secondi: float) -> void:
	var fine := Time.get_ticks_msec() + int(secondi * 1000.0)
	while Time.get_ticks_msec() < fine:
		await get_tree().physics_frame


func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % nome)
	print("[scatto] user://shots/%s.png" % nome)


func _accendi_tutto(n: Node) -> void:
	if n.name == "Accesa" and n is Node3D:
		(n as Node3D).visible = true
	for f in n.get_children():
		_accendi_tutto(f)


## I piedi lì, e gli occhi su `punto`.
func _guarda(piedi: Vector3, punto: Vector3) -> void:
	_giocatore.global_position = piedi
	var d := punto - _giocatore.camera().global_position
	_giocatore.rotation.y = atan2(-d.x, -d.z)
	_giocatore.camera().rotation.x = atan2(d.y, Vector2(d.x, d.z).length())


func _scatta() -> void:
	var c_era := FileAccess.file_exists(SALVATAGGIO)
	if c_era:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SALVATAGGIO),
			ProjectSettings.globalize_path(COPIA))
	Game.profile.photo_prints.clear()

	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 30:
		await get_tree().physics_frame
	_accendi_tutto(scena)
	_giocatore = Player.find_in(get_tree())
	var stampante := Stampante.find_in(get_tree())
	if not OS.get_environment("SCATTO_FARO").is_empty():
		var faro := OmniLight3D.new()
		faro.light_energy = 0.6
		faro.omni_range = 4.0
		_giocatore.camera().add_child(faro)

	stampante.secondi = 4.0
	Events.photo_revealed.emit(0, &"m42", 3)
	var fessura: Transform3D = stampante.get("_uscita")
	_guarda(Vector3(6.46, 0.0, 1.10), fessura.origin + Vector3.UP * 0.10)
	await _aspetta(2.0)
	await _foto("stampa_esce")
	var s: Stampa = null
	for n in get_tree().get_nodes_in_group(Stampa.GRUPPO):
		s = n as Stampa
	# SI ASPETTA LO STATO, NON UN TEMPO: con la finestra i primi fotogrammi compilano gli
	# shader, e quattro secondi d'orologio non sono quattro secondi di gioco. Presa mentre
	# esce, la stampa rifiuta la mano e resta sulla macchina.
	while s.stato != Stampa.Stato.ATTACCATA:
		await get_tree().physics_frame
	await _foto("stampa_uscita")

	_giocatore.call("_prendi", s)
	_giocatore.global_position = DAVANTI_AL_MURO
	_giocatore.rotation.y = VERSO_IL_MURO
	_giocatore.camera().rotation.x = 0.0
	s.global_position = _giocatore.camera().global_position - _giocatore.camera().global_basis.z * 0.5
	await _aspetta(1.0)
	print("[scatto] in mano %s a %s dall'occhio, il prompt dice «%s»" % [
		s.in_mano(), _giocatore.camera().global_transform.affine_inverse() * s.global_position,
		s.prompt_posa()])
	await _foto("stampa_in_mano")
	s.posa()
	await _aspetta(0.3)

	var n := s.global_basis.z
	for passo in [["stampa_appesa", 1.1], ["stampa_appesa_vicino", 0.55]]:
		var piedi: Vector3 = s.global_position + n * float(passo[1])
		piedi.y = 0.0
		_guarda(piedi, s.global_position)
		await _aspetta(0.6)
		await _foto(passo[0])

	if c_era:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(COPIA),
			ProjectSettings.globalize_path(SALVATAGGIO))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(COPIA))
	elif FileAccess.file_exists(SALVATAGGIO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SALVATAGGIO))
	get_tree().quit()
