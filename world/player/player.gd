## Il giocatore in prima persona: cammina nell'osservatorio e guarda intorno.
##
## LA CAMERA È LA TESTA, e non si stacca mai dal corpo (ADR-003, NFR21). Non
## esiste in questo file — né altrove nel progetto — una riga che la riparenti o
## le assegni una trasformata globale propria. Guardare la stanza da un punto
## dove il giocatore non è romperebbe l'unica cosa che il gioco vende: la
## presenza in quel luogo.
##
## IMBARDATA SUL CORPO, BECCHEGGIO SULLA CAMERA — e non è una preferenza di
## stile. `crt/desk_camera.gd` è già scritto e alla storia 1.3 interpolerà
## `_player.global_transform` prendendo la SOLA imbardata
## (`Basis(Vector3.UP, euler.y)`) e `_cam.rotation:x` separatamente. Un
## controller che mettesse il beccheggio sul corpo, o l'imbardata sulla camera,
## romperebbe quella transizione — e lo farebbe in silenzio, mesi dopo, quando
## nessuno collegherebbe più le due cose.
##
## Per la stessa ragione la camera ha una `position` locale COSTANTE: è l'offset
## della testa, e `desk_camera` ci fa aritmetica sopra
## (`target.origin = seat_xf.origin - target.basis * _cam.position`) presumendo
## che sia l'unica cosa che separa l'origine del corpo dall'occhio.
class_name Player
extends CharacterBody3D

## Altezza dell'occhio da terra, in metri.
##
## Sceglierla qui la fissa per tutto il gioco: il `Marker3D` `Seat` di
## `crt_screen.tscn` sta 9 cm sopra il centro dello schermo, e alla 1.3 la camera
## atterrerà lì. Il centro del CRT deve quindi stare all'altezza occhi da seduto
## meno 9 cm — vedi le misure della stanza in `computer_room.tscn`.
const EYE_HEIGHT := 1.65

## Metri al secondo. Si cammina, non si corre: niente sprint, niente scatto.
## L'osservatorio è un posto dove si sta, e il passo lo dice.
const WALK_SPEED := 2.6

## Quanto in fretta la velocità raggiunge quella voluta. Un valore alto rende il
## controllo immediato senza far sembrare il giocatore su una pista di ghiaccio.
const ACCELERATION := 12.0

## Radianti di rotazione per pixel di movimento del mouse.
const MOUSE_SENSITIVITY := 0.0022

## Il beccheggio si ferma prima della verticale. Senza questo la testa si
## ribalta, e `desk_camera` interpolerebbe da un angolo assurdo.
const PITCH_LIMIT := deg_to_rad(89.0)

## Quanto lontano si può interagire, in metri.
##
## È corta apposta. ADR-003 dice «sei già davanti al monitor, altrimenti non
## potresti interagirci»: alla storia 1.3 interagire col monitor porterà il corpo
## al `Marker3D` `Seat`, che sta 44 cm davanti allo schermo. Se si potesse
## interagire da tre metri quel movimento sarebbe un teletrasporto, e lo spirito
## dell'ADR sarebbe violato anche rispettandone la lettera.
const INTERACT_RANGE := 1.2

@onready var _cam: Camera3D = %Camera
@onready var _ray: RayCast3D = %InteractRay
@onready var _prompt: InteractionPrompt = %InteractionPrompt

var _enabled := true
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

## L'interagibile che il giocatore sta guardando adesso, o null.
var _focus: Interactable = null


func _ready() -> void:
	_ray.target_position = Vector3(0.0, 0.0, -INTERACT_RANGE)
	_capture_mouse()


## La camera del giocatore, per chi deve portarla altrove SENZA staccarla dal
## corpo — cioè `crt/desk_camera.gd`, alla storia 1.3.
func camera() -> Camera3D:
	return _cam


## Accende e spegne il controller.
##
## È il primo passo della sequenza di ADR-003 («il controller del giocatore si
## disabilita»), e nella storia 1.2 serve già: mentre la fase polare è attiva il
## giocatore non deve camminare, perché WASD comanda le viti.
func set_enabled(value: bool) -> void:
	if _enabled == value:
		return
	_enabled = value
	if _enabled:
		_capture_mouse()
	else:
		# La velocità va azzerata, non lasciata com'era: senza, riattivando il
		# controller il giocatore ripartirebbe alla velocità che aveva quando è
		# stato spento, e sembrerebbe spinto.
		velocity = Vector3.ZERO
		# E il prompt sparisce: un controller spento che lascia a schermo «[E]
		# Usa il monitor» inviterebbe a premere un tasto che non risponde.
		_set_focus(null)
		# Il cursore torna visibile: se il giocatore non guarda più intorno,
		# tenerglielo catturato è solo un modo per non fargli chiudere la finestra.
		_release_mouse()


func is_enabled() -> bool:
	return _enabled


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		# IMBARDATA SUL CORPO.
		rotate_y(-motion.relative.x * MOUSE_SENSITIVITY)
		# BECCHEGGIO SULLA CAMERA, e solo la rotazione: la posizione locale non
		# si tocca mai.
		_cam.rotation.x = clampf(
			_cam.rotation.x - motion.relative.y * MOUSE_SENSITIVITY,
			-PITCH_LIMIT, PITCH_LIMIT)
		return

	if event.is_action_pressed(&"interact"):
		if _focus != null:
			_focus.interact(self)
		return

	if event.is_action_pressed(&"ui_release_mouse"):
		_release_mouse()
	elif event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_capture_mouse()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	var wish := Vector3.ZERO
	if _enabled:
		# Azioni DICHIARATE nell'InputMap, mai keycode grezzi: il polling di
		# keycode era la scorciatoia dello spike, dichiarata tale, e non va
		# ereditata.
		var input := Input.get_vector(
			&"move_left", &"move_right", &"move_forward", &"move_back")
		wish = (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()

	var target := wish * WALK_SPEED
	velocity.x = move_toward(velocity.x, target.x, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, target.z, ACCELERATION * delta)

	move_and_slide()
	_update_focus()


## Cosa sto guardando. Il raggio parte dalla camera, quindi «guardare» e
## «puntare» sono la stessa cosa e non c'è un secondo criterio da tenere allineato.
func _update_focus() -> void:
	if not _enabled:
		return
	var hit: Interactable = null
	if _ray.is_colliding():
		hit = _ray.get_collider() as Interactable
		if hit != null and not hit.can_interact():
			hit = null
	_set_focus(hit)


func _set_focus(value: Interactable) -> void:
	if _focus == value:
		return
	_focus = value
	if _focus == null:
		_prompt.hide_prompt()
	else:
		_prompt.show_prompt(_focus.prompt())


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
