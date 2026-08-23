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
##
## DA QUELLA ARITMETICA DISCENDE UNA COSA CHE VA DETTA QUI, perché è dove
## qualcuno la cercherà. Il `Marker3D` `Seat` del CRT sta a 1,19 m da terra e
## l'occhio a 1,65 m sopra l'origine del corpo: per far atterrare la camera sul
## sedile, `desk_camera` dovrà portare l'origine del corpo a −0,46 m, cioè sotto
## il pavimento. È corretto — la camera finisce dove deve — ma funziona solo
## perché da spento questo controller NON simula più fisica: senza quella
## garanzia la depenetrazione risputerebbe fuori il corpo e la camera schizzerebbe
## via dal sedile. Vedi `set_enabled()` e `_physics_process()`.
class_name Player
extends CharacterBody3D

## Altezza dell'occhio da terra, in metri. È IL CONTRATTO, e `player.tscn` è dove
## il numero vive davvero: `_ready()` verifica che coincidano e lo dice forte se
## non coincidono. Non lo riscrive — vedi `_ready()` per il perché, che discende
## dall'AC1.
##
## Sceglierla qui la fissa per tutto il gioco: il `Marker3D` `Seat` di
## `crt_screen.tscn` sta 9 cm sopra il centro dello schermo, e alla 1.3 la camera
## atterrerà lì. Il centro del CRT deve quindi stare all'altezza occhi da seduto
## meno 9 cm — vedi le misure della stanza in `computer_room.tscn`.
const EYE_HEIGHT := 1.65

## Metri al secondo camminando. L'osservatorio è un posto dove si sta, e il passo
## lo dice — ma la stanza va anche attraversata, e farlo non deve annoiare.
##
## 2.0 e non 2.6: a 2.6 si trotta. Il numero non è stato ragionato, è stato
## trovato camminando con `Shift+F8`/`Shift+F9` e leggendo l'overlay `F12` finché
## il passo non sembrava un passo. È l'unico modo in cui questi numeri si trovano:
## il 2.6 di prima era stato scelto senza guardare, e si vedeva.
static var walk_speed := 2.0

## Metri al secondo tenendo SHIFT. NON è uno scatto sportivo e non c'è stamina:
## è la scorciatoia di chi sa già dove sta andando e non vuole rifare il giro
## della stanza al rallentatore. Il gioco resta lento; è il giocatore che a volte
## ha fretta, ed è una cortesia lasciarglielo dire.
##
## Tarabile come il passo, con `Shift+F10`/`Shift+F11`.
static var sprint_speed := 4.0

## Quanto in fretta la velocità raggiunge quella voluta. Un valore alto rende il
## controllo immediato senza far sembrare il giocatore su una pista di ghiaccio.
const ACCELERATION := 12.0

## Radianti di rotazione per pixel del viewport del mondo.
##
## Del VIEWPORT, non della finestra: `WorldViewport` è un `SubViewportContainer`
## con `stretch = true` e `stretch_shrink = 2`, e un container di quel tipo
## riscala `relative` con l'inversa del proprio fattore prima di consegnare
## l'evento. Il fattore è costante, quindi la sensibilità non cambia
## ridimensionando la finestra — ma raddoppierebbe se un giorno lo shrink
## passasse a 1.
const MOUSE_SENSITIVITY := 0.0022

## Il beccheggio si ferma prima della verticale. Senza questo la testa si
## ribalta, e `desk_camera` interpolerebbe da un angolo assurdo.
const PITCH_LIMIT := deg_to_rad(89.0)

## Quanto lontano si può interagire, in metri. È la SORGENTE DI VERITÀ della
## portata: `_ready()` la scrive nel raggio, la scena non la ripete.
##
## È corta apposta. ADR-003 dice «sei già davanti al monitor, altrimenti non
## potresti interagirci»: alla storia 1.3 interagire col monitor porterà il corpo
## al `Marker3D` `Seat`, che sta 44 cm davanti allo schermo. Se si potesse
## interagire da tre metri quel movimento sarebbe un teletrasporto, e lo spirito
## dell'ADR sarebbe violato anche rispettandone la lettera.
const INTERACT_RANGE := 1.2

## Le azioni che questo controller legge. Servono a rilasciarle in blocco quando
## il controllo torna: vedi `set_enabled()`.
const OWN_ACTIONS: Array[StringName] = [
	&"move_forward", &"move_back", &"move_left", &"move_right", &"interact",
	&"sprint",
]

## Chi ha bisogno del giocatore lo trova per GRUPPO, mai per percorso di nodo né
## per nome unico dall'esterno della sua scena. È la stessa regola che l'AC3
## impone al monitor, e non c'è ragione perché valga per uno e non per l'altro:
## un nome unico risolto da fuori si rompe allo stesso modo, al primo
## spostamento, e con un solo `push_error` a runtime a dirlo.
const GROUP := &"player"

@onready var _cam: Camera3D = %Camera
@onready var _ray: RayCast3D = %InteractRay
@onready var _prompt: InteractionPrompt = %InteractionPrompt

var _enabled := true

## Il giocatore ha chiesto lui il cursore, e non glielo si riprende alle spalle.
## Senza questa memoria, uscire da una fase ricatturerebbe il mouse anche a chi
## l'aveva appena liberato per usare un'altra finestra.
var _mouse_free := false

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

## L'interagibile che il giocatore sta guardando adesso, o null.
var _focus: Interactable = null


func _ready() -> void:
	add_to_group(GROUP)
	# L'ALTEZZA DELL'OCCHIO SI VERIFICA, NON SI RISCRIVE. L'AC1 chiede che nel
	# progetto non esista una riga che sposti la camera da sola, e una riga che la
	# sposta «solo all'avvio» è comunque una riga che la sposta. La posizione
	# resta quindi nella scena, dove si vede lavorando; questa costante è il
	# contratto, e la guardia fa in modo che una divergenza si scopra adesso
	# invece che alla 1.3, quando `desk_camera` farà aritmetica su un numero che
	# nessuno pensava fosse cambiato.
	if not is_equal_approx(_cam.position.y, EYE_HEIGHT):
		push_error("[player] camera a y=%.3f, EYE_HEIGHT dice %.3f" % [
			_cam.position.y, EYE_HEIGHT])
	# Il raggio invece non ha vincoli di questo genere, e la sua portata vive
	# soltanto qui.
	_ray.target_position = Vector3(0.0, 0.0, -INTERACT_RANGE)
	# Il raggio vede anche il MONDO, non solo gli interagibili, e non è uno
	# spreco: senza il layer 1 nessun muro, nessun mobile e nessuna porta
	# occluderebbe la mira, e il primo interagibile appoggiato a una parete
	# sarebbe usabile dalla stanza accanto. Ciò che colpisce e non è un
	# `Interactable` non apre un prompt: fa da schermo, che è il suo mestiere.
	_ray.collision_mask = Interactable.LAYER_WORLD | Interactable.LAYER_INTERACTABLE
	_capture_mouse()


## Il giocatore della scena, o `null` se non c'è.
static func find_in(tree: SceneTree) -> Player:
	return tree.get_first_node_in_group(GROUP) as Player


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
		# I TASTI GIÀ PREMUTI NON CONTANO. Chi ha chiuso la fase tenendo `W` per
		# girare la vite ha ancora il dito giù: senza questo rilascio il
		# giocatore ripartirebbe in avanti da solo, senza aver toccato niente.
		# L'azione resta rilasciata finché il tasto non viene alzato e ripremuto.
		_release_own_actions()
		if not _mouse_free:
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
		# `_mouse_free` non si tocca: registra ciò che ha chiesto LUI, e questo
		# rilascio non è una sua richiesta.
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func is_enabled() -> bool:
	return _enabled


## Il controllo è attivo solo se il controller è acceso E il cursore è catturato.
## Con il mouse libero non si può girare la testa: continuare a camminare e a
## interagire alla cieca sarebbe peggio che stare fermi.
func _is_controlling() -> bool:
	return _enabled and not _mouse_free


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return

	# Un click ridà il controllo dopo che il cursore era stato liberato. Solo la
	# pressione del tasto sinistro: senza il filtro anche una rotellina — che
	# Godot consegna come `InputEventMouseButton` — ricatturerebbe il cursore
	# senza che il giocatore abbia cliccato niente.
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT and _mouse_free:
			_mouse_free = false
			_capture_mouse()
		return

	if event.is_action_pressed(&"ui_release_mouse"):
		_mouse_free = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_set_focus(null)
		return

	if not _is_controlling():
		return

	if event is InputEventMouseMotion:
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
		# Si rilegge la mira ADESSO invece di fidarsi di `_focus`, che è stato
		# calcolato nell'ultimo tick di fisica. Fra un tick e l'altro il mouse
		# può aver girato la testa di mezzo giro: senza questa riconferma si
		# interagirebbe col monitor guardando la parete.
		_set_focus(_look_at_interactable())
		if _focus != null:
			_focus.interact(self)


func _physics_process(delta: float) -> void:
	# DA SPENTO NON SI SIMULA. Non è un'ottimizzazione: alla storia 1.3
	# `desk_camera` porterà l'origine del corpo sotto il pavimento per far
	# atterrare la camera sul `Seat` (vedi l'intestazione), e un `move_and_slide()`
	# che continuasse a girare lo risputerebbe fuori portandosi via la camera.
	if not _enabled:
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	var wish := Vector3.ZERO
	if _is_controlling():
		# Azioni DICHIARATE nell'InputMap, mai keycode grezzi: il polling di
		# keycode era la scorciatoia dello spike, dichiarata tale, e non va
		# ereditata.
		var input := Input.get_vector(
			&"move_left", &"move_right", &"move_forward", &"move_back")
		wish = (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()

	# SHIFT ACCELERA, e si legge qui e non in `_unhandled_input`: è uno stato
	# continuo («sto tenendo premuto»), non un evento. Letto per azione dichiarata
	# come tutto il resto del movimento, mai per keycode grezzo.
	var speed := sprint_speed if Input.is_action_pressed(&"sprint") else walk_speed
	var target := wish * speed
	velocity.x = move_toward(velocity.x, target.x, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, target.z, ACCELERATION * delta)

	move_and_slide()
	_set_focus(_look_at_interactable())


## Cosa sto guardando. Il raggio parte dalla camera, quindi «guardare» e
## «puntare» sono la stessa cosa e non c'è un secondo criterio da tenere allineato.
func _look_at_interactable() -> Interactable:
	if not _is_controlling():
		return null
	# `RayCast3D` aggiorna la propria collisione all'inizio del tick di fisica,
	# cioè PRIMA di `move_and_slide()`: senza questa riga si leggerebbe un
	# risultato calcolato sulla posizione del frame precedente, e al confine
	# della portata il prompt comparirebbe e sparirebbe un frame dopo il
	# giocatore.
	_ray.force_raycast_update()
	if not _ray.is_colliding():
		return null
	# Ciò che il raggio colpisce per primo e non è un interagibile è un
	# occlusore: un muro davanti al monitor va rispettato, non attraversato.
	var hit := _ray.get_collider() as Interactable
	if hit == null or not hit.can_interact():
		return null
	return hit


func _set_focus(value: Interactable) -> void:
	if _focus == value:
		# Stesso oggetto, ma il TESTO del prompt puo' essere cambiato: un
		# interagibile a piu' tempi (la moka, 3.3) cambia riga a ogni azione
		# mentre lo si continua a guardare. Si rilegge e si ri-mostra, cosi' il
		# prompt segue i tempi del rituale invece di restare congelato al primo.
		# `show_prompt` e' idempotente, quindi ri-chiamarlo ogni tick e' innocuo.
		if _focus != null:
			_prompt.show_prompt(_focus.prompt())
		return
	_focus = value
	if _focus == null:
		_prompt.hide_prompt()
	else:
		_prompt.show_prompt(_focus.prompt())


func _release_own_actions() -> void:
	for action in OWN_ACTIONS:
		Input.action_release(action)


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
