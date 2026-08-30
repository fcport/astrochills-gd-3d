## Banco delle porte: chi apre non deve prendersi l'anta in faccia.
##
## Il difetto era visibile solo giocando - ci si mette davanti a una porta che si
## apre verso di noi, si preme E, e l'anta ci passa dentro. Qui si mette un corpo
## esattamente dove il giocatore si troverebbe (davanti al vano, dal lato verso
## cui l'anta gira), si apre, e si controlla che sia finito FUORI dal settore che
## l'anta spazza.
##
## Si prova anche il contrario, che e' meta' del valore del banco: un corpo dal
## lato opposto NON deve essere spostato, o ogni porta diventerebbe un pistone.
##
##     Godot --headless --script tools/prova_porte.gd --quit
extends SceneTree

## SERVE UN PASSO DI FISICA PRIMA DI PROVARE. `move_and_collide` chiede al server
## fisico dove sta il corpo: appena istanziata la scena quel server non ha ancora
## visto niente, il movimento non avviene e il banco accusa un difetto che non
## c'e'. Due frame bastano.
var _scena: Node3D = null
var _corpo: CharacterBody3D = null
var _giri := 0

## mezza capsula piu' un dito: il corpo poggia sul pavimento, non ci affonda
const ALTEZZA := 0.90


func _init() -> void:
	var scena: Node3D = load("res://world/blockout.tscn").instantiate()
	get_root().add_child(scena)
	var corpo := CharacterBody3D.new()
	var forma := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.30
	capsula.height = 1.70
	forma.shape = capsula
	corpo.add_child(forma)
	scena.add_child(corpo)
	_scena = scena
	_corpo = corpo


func _physics_process(_d: float) -> bool:
	_giri += 1
	if _giri < 3:
		return false
	var scena := _scena
	var corpo := _corpo
	var provate := 0
	var guasti: Array[String] = []
	for nodo in scena.get_children():
		var porta := nodo as Door
		if porta == null:
			continue
		provate += 1
		# a meta' anta, in mezzo al settore: e' dove si sta per premere E
		var meta := deg_to_rad(porta.apertura_gradi * 0.5) * signf(porta.verso)
		var chiusa := Transform3D(Basis(Vector3.UP, porta.rotation.y), porta.global_position)
		# Basis(UP, theta) porta +X verso -Z, ed e' proprio la' che l'anta gira:
		# il corpo "nel giro" va messo con l'angolo dello stesso segno del verso
		var dentro: Vector3 = chiusa * (Basis(Vector3.UP, meta) * Vector3(0.55, 0.0, 0.0))
		# la capsula sta ALTA MEZZA CAPSULA: a y=0 ne resta meta' dentro il
		# pavimento, e un corpo compenetrato non si muove di un millimetro
		_posa(corpo, Vector3(dentro.x, ALTEZZA, dentro.z))
		porta.interacted.emit(corpo)
		var dopo := chiusa.affine_inverse() * corpo.global_position
		var raggio := Vector2(dopo.x, dopo.z).length()
		# NON BASTA GUARDARE IL RAGGIO. In un locale stretto la spinta si ferma
		# contro il muro e la porta si apre di meno: allora il corpo resta vicino
		# al cardine ed e' comunque al sicuro, perche' l'anta non arriva fin li'.
		# Quello che conta e' l'unica cosa che conta davvero - dove finisce la
		# punta dell'anta rispetto a chi ha aperto.
		var col := porta.get_node(^"Col") as CollisionShape3D
		var lunga: float = (col.shape as BoxShape3D).size.x
		var dopo2 := chiusa.affine_inverse() * corpo.global_position
		var ang_corpo := atan2(-dopo2.z * signf(porta.verso), dopo2.x)
		# l'angolo BERSAGLIO, non quello corrente: subito dopo l'interazione il
		# tween non e' ancora partito e l'anta e' ancora chiusa - misurarla adesso
		# farebbe passare il banco sempre, che e' peggio di non averlo.
		var ang_anta := deg_to_rad(porta.get("_apertura_utile"))
		var lontano := raggio > lunga + Door.MARGINE - 0.02
		var mezzo := asin(clampf(Door.MARGINE / maxf(raggio, 0.05), 0.0, 1.0))
		if not lontano and ang_anta > ang_corpo - mezzo + 0.01:
			guasti.append("%s: l'anta arriva a %.0f gradi e chi ha aperto sta a %.0f"
				% [porta.name, rad_to_deg(ang_anta), rad_to_deg(ang_corpo)])
		# e chi sta dall'altra parte non si deve muovere di un millimetro
		var fuori: Vector3 = chiusa * (Basis(Vector3.UP, -meta) * Vector3(0.55, 0.0, 0.0))
		var prima := Vector3(fuori.x, ALTEZZA, fuori.z)
		_posa(corpo, prima)
		porta.interacted.emit(corpo)
		if corpo.global_position.distance_to(prima) > 0.001:
			guasti.append("%s: spinge anche chi sta dalla parte opposta" % porta.name)

	print("\nporte provate: %d, guasti: %d" % [provate, guasti.size()])
	for g in guasti:
		print("  " + g)
	quit()
	return true


## Sposta il corpo E LO DICE AL SERVER FISICO.
##
## Scrivere `global_position` aggiorna il nodo, non il server: `move_and_collide`
## chiede al server, trova il corpo dove stava un istante prima e crede di
## sbattere subito contro qualcosa. Fuori dal banco non si vede perche' fra un
## fotogramma e l'altro la sincronizzazione avviene da sola - qui i sette
## controlli stanno dentro lo stesso fotogramma.
func _posa(corpo: CharacterBody3D, dove: Vector3) -> void:
	corpo.global_position = dove
	corpo.force_update_transform()
	PhysicsServer3D.body_set_state(corpo.get_rid(),
		PhysicsServer3D.BODY_STATE_TRANSFORM, corpo.global_transform)
