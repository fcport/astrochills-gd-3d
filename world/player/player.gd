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

## DOVE STA LA MANO: davanti all'occhio, in basso e SULLA DESTRA, in metri.
##
## I 55 cm sono la distanza a cui si tiene una cosa che si sta guardando — più
## vicino si va di occhi incrociati, più lontano è un braccio teso, che è un
## altro gesto e stanca a vederlo. Sta dentro `INTERACT_RANGE` di proposito: ciò
## che si può raccogliere lo si può anche posare dov'è, senza fare un passo.
##
## GIÙ E A DESTRA, E NON AL CENTRO, perché non ci sono braccia da disegnare e non
## ce ne saranno: al centro esatto l'oggetto sta sospeso in mezzo alla faccia,
## copre il mirino e metà di dove si sta andando, e la mancanza della mano si
## nota. Spostato nell'angolo in basso a destra legge come «lo sto portando» e
## lascia libera la stanza — è dove ogni gioco in prima persona tiene quello che
## hai in mano, per la stessa ragione e da trent'anni.
##
## I NUMERI SI TARANO GUARDANDO, e questi vanno verificati d'operatore su
## `tools/banco_mani.tscn`: a 55 cm il bordo destro del campo cade intorno ai 42
## cm, quindi 22 porta l'oggetto circa a metà strada verso il bordo — visibile
## intero, e fuori dal centro.
const DISTANZA_MANO := 0.55
const ALTEZZA_MANO := -0.16
const LATO_MANO := 0.22

## Con quanta forza il giocatore sposta ciò che urta camminando, in newton-secondi
## per chilo. Un oggetto per terra che non si smuove quando ci cammini dentro
## denuncia la finzione più di quanto la fisica la costruisca: la lattina va presa
## a calci anche da chi non aveva intenzione di raccoglierla.
##
## Proporzionale alla massa, quindi l'impulso dà la stessa VELOCITÀ a tutti: due
## e mezzo, cioè poco più della camminata. Un valore fisso manderebbe le cose
## leggere in orbita e non muoverebbe le pesanti.
const SPINTA := 2.5

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

## Se il corpo e' fermo mentre la testa resta libera. Vedi `set_movement_locked`.
var _movement_locked := false

## Il giocatore ha chiesto lui il cursore, e non glielo si riprende alle spalle.
## Senza questa memoria, uscire da una fase ricatturerebbe il mouse anche a chi
## l'aveva appena liberato per usare un'altra finestra.
var _mouse_free := false

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

## L'interagibile che il giocatore sta guardando adesso, o null.
var _focus: Interactable = null

## L'oggetto da raccogliere che sta guardando adesso, o null.
##
## DUE VARIABILI E NON UNA, e non è pigrizia: `Interactable` è uno `StaticBody3D`
## e `Carryable` un `RigidBody3D`, che in GDScript non hanno nessun antenato
## comune sotto `PhysicsBody3D`. Tenerli in un solo campo vorrebbe dire tipizzarlo
## `Node` e chiamare i metodi per nome — cioè scoprire a runtime, e in silenzio,
## quello che qui si scopre compilando.
var _mirato: Carryable = null

## Quello che ha in mano, o null. Uno solo: si hanno due mani ma un solo mirino,
## e non c'è un gesto per dire in quale delle due.
var _in_mano: Carryable = null

## Come l'oggetto era girato rispetto alla testa quando l'ho preso.
##
## SI CONSERVA COM'ERA invece di raddrizzarlo. Raccogliendo, l'oggetto scatterebbe
## all'orientamento canonico — la moka che si gira da sola col beccuccio in
## avanti — e quello scatto dice «sono un gioco» a voce alta. Preso storto resta
## storto, e lo si raddrizza girandosi.
var _presa := Basis.IDENTITY

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
## BLOCCA IL CORPO E LASCIA LIBERA LA TESTA.
##
## Serve a chi tiene premuto un comando nel mondo — il pulsante della cupola — e
## nel frattempo vuole guardarsi intorno: il motore va, e tu alzi gli occhi a
## vedere la fessura che si apre sopra di te. Spegnere tutto il controller
## (`set_enabled(false)`) bloccherebbe anche il mouse, che è esattamente la cosa
## che si vuole tenere.
##
## Non tocca la gravità: chi resta bloccato a mezz'aria continua a cadere.
func set_movement_locked(value: bool) -> void:
	_movement_locked = value


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
		# E QUELLO CHE SI HA IN MANO SI POSA. Da spento questo controller non
		# aggiorna più la mano, quindi l'oggetto resterebbe fermo a mezz'aria
		# dove eravamo — e `desk_camera` porta il corpo sotto il pavimento, cioè
		# se lo trascinerebbe dietro nella cantina. Sedersi al monitor con la
		# moka in mano vuol dire posare la moka, come nella vita.
		if _in_mano != null:
			_in_mano.lascia()
		# E il prompt sparisce: un controller spento che lascia a schermo «[E]
		# Usa il monitor» inviterebbe a premere un tasto che non risponde.
		_mostra_mira(null, null)
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
		_mostra_mira(null, null)
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
		# CON LE MANI PIENE, `E` POSA — sempre, anche guardando una porta.
		#
		# È l'unica regola senza ambiguità, e l'alternativa lo mostra: se `E`
		# aprisse la porta quando ne guardo una e posasse quando non ne guardo
		# nessuna, lo stesso tasto farebbe due cose a seconda di dove sto
		# guardando, e posare qualcosa vicino a una porta diventerebbe una lotta.
		# Chi deve aprire una porta posa quello che ha in mano, come nella vita.
		if _in_mano != null:
			# `posa()` E NON `lascia()`: quasi sempre sono la stessa cosa, ma un
			# oggetto che ha un posto suo lo sa e ci va. Vedi `Carryable.posa()`.
			_in_mano.posa()
			return
		# Si rilegge la mira ADESSO invece di fidarsi di `_focus`, che è stato
		# calcolato nell'ultimo tick di fisica. Fra un tick e l'altro il mouse
		# può aver girato la testa di mezzo giro: senza questa riconferma si
		# interagirebbe col monitor guardando la parete.
		_aggiorna_mira()
		if _mirato != null:
			_prendi(_mirato)
		elif _focus != null:
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
		var puo_saltare := _is_controlling() and not _movement_locked and not _accovacciato
		if puo_saltare and Input.is_action_just_pressed(&"jump"):
			velocity.y = JUMP_SPEED

	var wish := Vector3.ZERO
	if _is_controlling() and not _movement_locked:
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
	_spingi_cio_che_urto()
	_aggiorna_mira()
	# LA MANO SI PUNTA DOPO `move_and_slide()`, cioè dopo che il corpo è dove sarà
	# per tutto questo tick. Puntandola prima, l'oggetto inseguirebbe la posizione
	# del fotogramma precedente e resterebbe indietro di un passo — di poco, e
	# sempre, cioè fluttuando dietro la spalla mentre si cammina.
	if _in_mano != null:
		_in_mano.punta(_trasformata_mano())


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


## Cosa sto guardando, e cosa dice il prompt di conseguenza. Il raggio parte dalla
## camera, quindi «guardare» e «puntare» sono la stessa cosa e non c'è un secondo
## criterio da tenere allineato.
##
## UN SOLO RAGGIO PER DUE GERARCHIE: si spara una volta e si prova a leggere ciò
## che ha colpito prima come interagibile e poi come oggetto da raccogliere. Due
## raycast — uno per tipo — sarebbero due risposte che possono divergere, e
## divergono proprio nel caso che conta: una moka appoggiata su un interruttore.
func _aggiorna_mira() -> void:
	if not _is_controlling():
		_mostra_mira(null, null)
		return
	# CON LE MANI PIENE NON SI MIRA NIENTE, perché `E` posa comunque (vedi
	# `_unhandled_input`). Continuare a mostrare «Apri il quadro» mentre l'unica
	# cosa che quel tasto fa è posare la moka sarebbe una riga che mente.
	if _in_mano != null:
		_focus = null
		_mirato = null
		_mirino.set_attivo(true)
		_prompt.show_prompt(_in_mano.prompt_posa())
		return
	# `RayCast3D` aggiorna la propria collisione all'inizio del tick di fisica,
	# cioè PRIMA di `move_and_slide()`: senza questa riga si leggerebbe un
	# risultato calcolato sulla posizione del frame precedente, e al confine
	# della portata il prompt comparirebbe e sparirebbe un frame dopo il
	# giocatore.
	_ray.force_raycast_update()
	if not _ray.is_colliding():
		_mostra_mira(null, null)
		return
	var colpito := _ray.get_collider()
	# Ciò che il raggio colpisce per primo e non è né l'uno né l'altro è un
	# occlusore: un muro davanti al monitor va rispettato, non attraversato.
	var usabile := colpito as Interactable
	if usabile != null and not usabile.can_interact():
		usabile = null
	_mostra_mira(usabile, colpito as Carryable)


## Scrive la mira e ne mostra il prompt. I due casi non si sovrappongono mai — un
## corpo è statico o rigido, non tutti e due — ma il metodo li prende insieme
## perché il MIRINO è uno solo, e aprirlo da due punti diversi è il modo sicuro
## di vederlo aperto quando non c'è niente da fare.
func _mostra_mira(usabile: Interactable, oggetto: Carryable) -> void:
	var stesso := usabile == _focus and oggetto == _mirato
	_focus = usabile
	_mirato = oggetto
	var riga := ""
	if _focus != null:
		riga = _focus.prompt()
	elif _mirato != null:
		riga = _mirato.prompt()
	if stesso and riga.is_empty():
		return
	# Il mirino si apre e il prompt compare insieme, dallo STESSO punto: sono due
	# facce della stessa notizia - «questo si puo' usare» - e tenerle in due posti
	# e' il modo sicuro di vederle divergere.
	_mirino.set_attivo(not riga.is_empty())
	if riga.is_empty():
		_prompt.hide_prompt()
	else:
		# Il TESTO si riscrive anche a bersaglio invariato: un interagibile a piu'
		# tempi (la moka, 3.3) cambia riga a ogni azione mentre lo si continua a
		# guardare. Cosi' il prompt segue i tempi del rituale invece di restare
		# congelato al primo. `show_prompt` e' idempotente.
		_prompt.show_prompt(riga)


## Raccoglie un oggetto e si ricorda come lo si è preso.
func _prendi(oggetto: Carryable) -> void:
	_in_mano = oggetto
	# LA PRESA È RELATIVA ALLA TESTA, non assoluta: girandosi, l'oggetto gira con
	# noi mantenendo l'angolo che aveva quando l'abbiamo afferrato. In coordinate
	# del mondo resterebbe invece rivolto a nord mentre gli si cammina intorno.
	_presa = _cam.global_basis.orthonormalized().inverse() \
		* oggetto.global_basis.orthonormalized()
	oggetto.posato.connect(_su_oggetto_posato, CONNECT_ONE_SHOT)
	oggetto.prendi(self)
	oggetto.punta(_trasformata_mano())


## L'oggetto non è più in mano — posato da noi o strappato via da un muro. In
## tutti e due i casi arriva di qui: senza, chi lo teneva continuerebbe a puntare
## una mano a una cosa che è per terra due stanze fa.
func _su_oggetto_posato() -> void:
	_in_mano = null


## Dove la mano vuole l'oggetto, adesso.
func _trasformata_mano() -> Transform3D:
	var testa := _cam.global_transform
	var xf := Transform3D()
	xf.basis = testa.basis.orthonormalized() * _presa
	xf.origin = testa.origin \
		- testa.basis.z * DISTANZA_MANO \
		+ testa.basis.y * ALTEZZA_MANO \
		+ testa.basis.x * LATO_MANO
	return xf


## Spinge i corpi liberi contro cui si è appena camminato.
##
## `CharacterBody3D` NON LO FA DA SÉ, e la cosa sorprende sempre: il corpo cinematico
## scivola contro il rigido e prosegue, il rigido non se ne accorge. Senza queste
## righe si attraverserebbe una pila di scatole senza scomporla — che è il difetto
## che denuncia la finzione più di qualunque texture.
func _spingi_cio_che_urto() -> void:
	for i in get_slide_collision_count():
		var urto := get_slide_collision(i)
		var corpo := urto.get_collider() as RigidBody3D
		if corpo == null:
			continue
		# La NORMALE punta verso di noi: l'oggetto va spinto dall'altra parte.
		# Nel punto dell'urto e non nel centro, così una scatola presa a un
		# angolo gira invece di scivolare via dritta.
		corpo.apply_impulse(
			-urto.get_normal() * SPINTA * corpo.mass,
			urto.get_position() - corpo.global_position)


func _release_own_actions() -> void:
	for action in OWN_ACTIONS:
		Input.action_release(action)


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
