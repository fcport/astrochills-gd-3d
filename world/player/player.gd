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
## L'ACCOVACCIATA È L'UNICA ECCEZIONE, e va detta qui perché contraddice il
## paragrafo sopra. Accovacciarsi ABBASSA l'occhio: non c'è modo di farlo senza
## muovere `_cam.position.y`, e fingere il contrario sarebbe peggio che
## dichiararlo. Restano vere le due cose che contano davvero: la camera non si
## riparenta mai e non prende mai una trasformata globale propria — si muove solo
## la sua `y` locale, fra `EYE_HEIGHT` e `CROUCH_EYE_HEIGHT`.
##
## E `set_enabled(false)` RIMETTE IN PIEDI prima di spegnersi, così l'aritmetica
## di `desk_camera` legge sempre l'offset da fermo. Senza, sedersi al monitor da
## accovacciati farebbe atterrare la camera 60 cm sotto il sedile.
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

## Altezza dell'occhio da accovacciati. Sessanta centimetri sotto: abbastanza da
## guardare sotto un tavolo e dietro un mobile, che è a cosa serve.
const CROUCH_EYE_HEIGHT := 1.05

## Altezza della capsula in piedi e accovacciati. La prima DEVE combaciare con
## `player.tscn`, e `_ready()` lo verifica: se divergono, ci si alza dentro il
## soffitto o non ci si passa sotto una porta.
const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.1

## Velocità verticale iniziale del salto. A 3,6 m/s con la gravità di progetto si
## sale di 66 cm: quanto basta a vedere sopra un mobile, non tanto da scavalcarlo.
## Un salto più alto trasformerebbe l'osservatorio in un posto da attraversare
## saltando, che è l'opposto di come si vuole che si cammini.
const JUMP_SPEED := 3.6

## Metri al secondo da accovacciati.
const CROUCH_SPEED := 1.1

## Quanto in fretta l'occhio e la capsula scendono e salgono. Istantaneo darebbe
## uno scatto; lento sembrerebbe di affondare nel pavimento.
const CROUCH_LERP := 12.0

## Metri al secondo camminando. L'osservatorio è un posto dove si sta, e il passo
## lo dice — ma la stanza va anche attraversata, e farlo non deve annoiare.
##
## 2.0 e non 2.6: a 2.6 si trotta. Il numero non è stato ragionato, è stato
## trovato camminando con `Shift+F8`/`Shift+F9` e leggendo l'overlay `F12` finché
## il passo non sembrava un passo. È l'unico modo in cui questi numeri si trovano:
## il 2.6 di prima era stato scelto senza guardare, e si vedeva.
static var walk_speed := 2.5

## Metri al secondo tenendo SHIFT. NON è uno scatto sportivo e non c'è stamina:
## è la scorciatoia di chi sa già dove sta andando e non vuole rifare il giro
## della stanza al rallentatore. Il gioco resta lento; è il giocatore che a volte
## ha fretta, ed è una cortesia lasciarglielo dire.
##
## Tarabile come il passo, con `Shift+F10`/`Shift+F11`.
static var sprint_speed := 4.5

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
	&"sprint", &"jump", &"crouch",
]

## Chi ha bisogno del giocatore lo trova per GRUPPO, mai per percorso di nodo né
## per nome unico dall'esterno della sua scena. È la stessa regola che l'AC3
## impone al monitor, e non c'è ragione perché valga per uno e non per l'altro:
## un nome unico risolto da fuori si rompe allo stesso modo, al primo
## spostamento, e con un solo `push_error` a runtime a dirlo.
const GROUP := &"player"

@onready var _cam: Camera3D = %Camera
@onready var _forma: CollisionShape3D = $Collision
@onready var _ray: RayCast3D = %InteractRay
@onready var _prompt: InteractionPrompt = %InteractionPrompt
## Il mirino: sta al centro e dice dove punta il raggio. Vedi `crosshair.gd`.
##
## PER PERCORSO E NON CON `%`: il nome unico si risolve nel PROPRIETARIO della
## scena, e il proprietario di quel Control e' `crosshair.tscn`, non il
## giocatore. Dichiararlo unico anche qui non basta - il risultato e' un
## `%Mirino` che non esiste e un errore a ogni avvio.
@onready var _mirino: Crosshair = $Crosshair/Mirino

var _enabled := true

## Il giocatore ha chiesto lui il cursore, e non glielo si riprende alle spalle.
## Senza questa memoria, uscire da una fase ricatturerebbe il mouse anche a chi
## l'aveva appena liberato per usare un'altra finestra.
var _mouse_free := false

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

## L'interagibile che il giocatore sta guardando adesso, o null.
var _focus: Interactable = null

## Se il giocatore è accovacciato adesso.
var _accovacciato := false


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
	# La capsula si DUPLICA prima di toccarla. Le risorse di una scena sono
	# condivise fra le sue istanze: modificando quella originale, un secondo
	# giocatore — o una scena di prova aperta di fianco — si accovaccerebbe
	# insieme a questo.
	_forma.shape = _forma.shape.duplicate()
	var capsula := _forma.shape as CapsuleShape3D
	if capsula == null:
		push_error("[player] la collisione non è una capsula: l'accovacciata non funziona")
	elif not is_equal_approx(capsula.height, STAND_HEIGHT):
		push_error("[player] capsula alta %.3f, STAND_HEIGHT dice %.3f" % [
			capsula.height, STAND_HEIGHT])
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
		# E SI RIMETTE IN PIEDI, subito e senza interpolazione: da qui in poi
		# `desk_camera` fa aritmetica su `_cam.position`, e deve trovarci
		# l'offset da fermo. Vedi l'intestazione.
		_accovacciato = false
		_applica_altezza(1.0)


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

	# ACCOVACCIATA. Si legge come stato continuo, come lo sprint, e ci si rialza
	# solo se sopra la testa c'è posto: senza il controllo, alzarsi sotto una
	# consolle incastra il giocatore dentro il piano.
	var vuole_giu := _is_controlling() and Input.is_action_pressed(&"crouch")
	if vuole_giu:
		_accovacciato = true
	elif _accovacciato and _c_e_spazio_sopra():
		_accovacciato = false
	_applica_altezza(clampf(CROUCH_LERP * delta, 0.0, 1.0))

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0
		# SALTO. Solo da fermi in piedi e con i piedi per terra: saltare
		# accovacciati vorrebbe dire alzarsi a mezz'aria dentro quello sotto cui
		# ci si era infilati.
		if _is_controlling() and not _accovacciato and Input.is_action_just_pressed(&"jump"):
			velocity.y = JUMP_SPEED

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
	if _accovacciato:
		speed = CROUCH_SPEED
	var target := wish * speed
	velocity.x = move_toward(velocity.x, target.x, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, target.z, ACCELERATION * delta)

	move_and_slide()
	_set_focus(_look_at_interactable())


## Porta capsula e occhio verso l'altezza voluta. `t` è quanto avvicinarsi in
## questo tick: 1.0 ci arriva subito.
func _applica_altezza(t: float) -> void:
	var capsula := _forma.shape as CapsuleShape3D
	if capsula == null:
		return
	var h_voluta := CROUCH_HEIGHT if _accovacciato else STAND_HEIGHT
	var occhio_voluto := CROUCH_EYE_HEIGHT if _accovacciato else EYE_HEIGHT
	capsula.height = lerpf(capsula.height, h_voluta, t)
	# La capsula è centrata a metà della propria altezza, o abbassandola i piedi
	# finirebbero sotto il pavimento invece che la testa sotto il soffitto.
	_forma.position.y = capsula.height * 0.5
	_cam.position.y = lerpf(_cam.position.y, occhio_voluto, t)


## C'è abbastanza spazio sopra la testa per rialzarsi in piedi?
##
## Si guarda in su dal pavimento fino all'altezza da fermo: un raggio basta,
## perché quello che blocca l'alzata è un piano orizzontale sopra la testa - una
## consolle, un ripiano, un architrave - non un ostacolo di fianco.
func _c_e_spazio_sopra() -> bool:
	var spazio := get_world_3d().direct_space_state
	var da := global_position + Vector3.UP * 0.1
	var a := global_position + Vector3.UP * (STAND_HEIGHT + 0.05)
	var domanda := PhysicsRayQueryParameters3D.create(da, a)
	domanda.collision_mask = Interactable.LAYER_WORLD
	domanda.exclude = [get_rid()]
	return spazio.intersect_ray(domanda).is_empty()


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
	# Il mirino si apre e il prompt compare insieme, dallo STESSO punto: sono due
	# facce della stessa notizia - «questo si puo' usare» - e tenerle in due posti
	# e' il modo sicuro di vederle divergere.
	_mirino.set_attivo(_focus != null)
	if _focus == null:
		_prompt.hide_prompt()
	else:
		_prompt.show_prompt(_focus.prompt())


func _release_own_actions() -> void:
	for action in OWN_ACTIONS:
		Input.action_release(action)


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
