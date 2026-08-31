## Banco delle porte: l'anta non ti passa dentro, e non ti sparа indietro.
##
## Il difetto era visibile solo giocando - ci si mette davanti a una porta che si
## apre verso di noi, si preme E, e l'anta ci passa dentro. La prima cura scostava
## chi era nel giro con un `move_and_collide` solo, e ne ha introdotto un secondo
## altrettanto visibile: mezzo metro in un fotogramma, cioe' un teletrasporto.
##
## Qui si mette un corpo dove il giocatore si troverebbe, si apre, e si guarda la
## rotazione FOTOGRAMMA PER FOTOGRAMMA controllando tre cose:
##
##   1. l'anta non compenetra mai il corpo, in nessun fotogramma;
##   2. il corpo non viene mai spostato piu' in fretta di un passo di corsa;
##   3. a fine corsa o e' fuori dal raggio dell'anta, o l'anta si e' fermata prima.
##
## Si prova anche il contrario, che e' meta' del valore del banco: un corpo dal
## lato opposto NON deve essere spostato, o ogni porta diventerebbe un pistone.
##
##     Godot --headless --script tools/prova_porte.gd --quit
extends SceneTree

## Piu' di cosi' non e' scostare, e' sparare indietro. Un uomo che cammina fa 1,4
## m/s: l'anta puo' spostarti come una camminata, non come una spinta.
const VELOCITA_MASSIMA := 1.6

## mezza capsula piu' un dito: il corpo poggia sul pavimento, non ci affonda
const ALTEZZA := 0.90

## quanti fotogrammi si lascia girare l'anta prima di tirare le somme
const CORSA := 120

var _scena: Node3D = null
var _corpo: CharacterBody3D = null
var _porte: Array[Door] = []
var _guasti: Array[String] = []

var _giri := 0
var _quale := 0
var _fase := 0
var _restano := 0
var _chiusa := Transform3D()
var _portata := 0.0
var _prima := Vector3.ZERO

## Dov'era il corpo il FOTOGRAMMA SCORSO. Non si puo' misurare uno spostamento
## leggendo la posizione due volte nello stesso istante: il callback di questo
## banco gira PRIMA dei nodi, quindi fra le due letture la porta non ha ancora
## mosso niente e la velocita' risultava zero sempre. Il banco passava anche con
## la spinta istantanea rimessa apposta - cioe' proprio col difetto che esiste per
## trovare - e questo si vede solo iniettandolo.
var _era := Vector3.ZERO

## Quanto il corpo si e' mosso in tutta la corsa. Serve al terzo controllo.
var _mosso := 0.0


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


## SERVE UN PASSO DI FISICA PRIMA DI PROVARE. `move_and_collide` chiede al server
## fisico dove sta il corpo: appena istanziata la scena quel server non ha ancora
## visto niente, il movimento non avviene e il banco accusa un difetto che non c'e'.
func _physics_process(delta: float) -> bool:
	_giri += 1
	if _giri < 3:
		return false
	if _porte.is_empty():
		for nodo in _scena.get_children():
			var p := nodo as Door
			if p != null:
				_porte.append(p)
		_quanto_girano()
	if _quale >= _porte.size():
		return _conclusione()

	var porta := _porte[_quale]
	match _fase:
		0:
			_apparecchia(porta, +1)      # nel settore che l'anta spazza
			_fase = 1
		1:
			_sorveglia(porta, delta, true)
			_restano -= 1
			if _restano <= 0:
				_bilancio(porta)
				# ci si toglie di mezzo: da qui in poi niente la trattiene
				_posa(_corpo, porta.global_position + Vector3(0.0, 30.0, 0.0))
				_restano = CORSA
				_fase = 2
		2:
			_restano -= 1
			if _restano <= 0:
				_finisce(porta)
				_apparecchia(porta, -1)  # dalla parte opposta
				_fase = 3
		3:
			_sorveglia(porta, delta, false)
			_restano -= 1
			if _restano <= 0:
				if _corpo.global_position.distance_to(_prima) > 0.01:
					_guasti.append("%s: spinge anche chi sta dalla parte opposta"
						% porta.name)
				_quale += 1
				_fase = 0
	return false


## Mette il corpo dove una persona sta davvero per premere E - da un lato o
## dall'altro del battente - e interagisce.
##
## LE DUE POSIZIONI SI SCRIVONO PER ESTESO, non specchiando un angolo. Specchiando,
## il corpo "dalla parte opposta" finiva a trentacinque centimetri dal filo
## dell'anta chiusa: piu' vicino del margine, quindi la porta lo sfiorava chiudendosi
## e il banco lo chiamava pistone. Non era un difetto della porta, era il banco che
## metteva una persona addosso al battente e pretendeva che non la toccasse.
## `lungo` e' la distanza dal cardine misurata sull'anta, `scarto` quella dal piano
## della porta: positivo dalla parte verso cui si apre.
func _apparecchia(porta: Door, dove: int) -> void:
	var lungo := 0.45
	var scarto := 0.42 if dove > 0 else -0.65
	_chiusa = Transform3D(Basis(Vector3.UP, porta.get("_chiusa_y")), porta.global_position)
	# in coordinate dell'anta chiusa +X e' il battente; la punta gira verso -Z per
	# `verso` positivo, quindi lo scarto va contro il verso
	var punto: Vector3 = _chiusa * Vector3(lungo, 0.0, -scarto * signf(porta.verso))
	_prima = Vector3(punto.x, ALTEZZA, punto.z)
	_posa(_corpo, _prima)
	var col := porta.get_node(^"Col") as CollisionShape3D
	_portata = (col.shape as BoxShape3D).size.x + Door.MARGINE
	porta.interacted.emit(_corpo)
	_era = Vector3.ZERO
	_mosso = 0.0
	_restano = CORSA


## Un fotogramma di sorveglianza: nessuna compenetrazione, nessuno strappo.
func _sorveglia(porta: Door, delta: float, nel_giro: bool) -> void:
	var loc := _chiusa.affine_inverse() * _corpo.global_position
	var raggio := Vector2(loc.x, loc.z).length()
	var angolo := rad_to_deg(atan2(-loc.z * signf(porta.verso), loc.x))
	var anta := rad_to_deg(porta.rotation.y - porta.get("_chiusa_y")) * signf(porta.verso)
	if raggio < _portata - 0.01 and raggio > 0.05:
		var mezzo := rad_to_deg(asin(clampf(Door.MARGINE / raggio, 0.0, 1.0)))
		# meta' margine: il MARGINE e' l'aria che si vuole lasciare, non lo spessore
		# del corpo - toccare a meta' margine non e' ancora compenetrare
		if absf(angolo - anta) < mezzo * 0.5:
			_guasti.append("%s: l'anta e' a %.0f gradi e il corpo a %.0f, si passano dentro"
				% [porta.name, anta, angolo])
	if nel_giro and _era != Vector3.ZERO:
		var quanto := _corpo.global_position.distance_to(_era)
		if quanto / maxf(delta, 0.001) > VELOCITA_MASSIMA:
			_guasti.append("%s: scosta a %.1f m/s, che non e' un passo indietro"
				% [porta.name, quanto / maxf(delta, 0.001)])
		_mosso += quanto
	_era = _corpo.global_position


## A corsa finita: o il corpo e' fuori dalla portata dell'anta, o l'anta si e'
## fermata prima di arrivargli addosso. In un locale stretto vale la seconda.
func _bilancio(porta: Door) -> void:
	var loc := _chiusa.affine_inverse() * _corpo.global_position
	var raggio := Vector2(loc.x, loc.z).length()
	var angolo := rad_to_deg(atan2(-loc.z * signf(porta.verso), loc.x))
	var anta := rad_to_deg(porta.rotation.y - porta.get("_chiusa_y")) * signf(porta.verso)
	print("  %-26s si apre a %2.0f gradi, il corpo scostato di %.2f m"
		% [porta.name, anta, _mosso])

	# LA PORTA SI DEVE ANCHE APRIRE. Fermarsi a filo di chi ha aperto e' la cura
	# giusta quando dietro c'e' un muro, ed e' anche il modo perfetto di nascondere
	# una spinta che non funziona piu': senza scostare nessuno l'anta si ferma a sei
	# gradi e tutti i controlli di sicurezza passano, perche' una porta che non si
	# apre non fa male a nessuno. Se non si e' aperta, allora il corpo si DEVE essere
	# mosso - o contro un muro, o fuori dai piedi.
	if anta < porta.apertura_gradi - 1.0 and _mosso < 0.02:
		_guasti.append("%s: si ferma a %.0f gradi e non ha scostato nessuno"
			% [porta.name, anta])

	# e comunque l'anta non deve arrivare addosso a chi e' rimasto nel settore
	if raggio > _portata - 0.02:
		return
	var mezzo := rad_to_deg(asin(clampf(Door.MARGINE / maxf(raggio, 0.05), 0.0, 1.0)))
	if anta > angolo - mezzo + 0.5:
		_guasti.append("%s: il corpo resta a %.2f m dal cardine e l'anta arriva a %.0f "
			% [porta.name, raggio, anta] + "gradi, contro i %.0f del corpo" % angolo)


func _conclusione() -> bool:
	print("\nporte provate: %d, guasti: %d" % [_porte.size(), _guasti.size()])
	for g in _guasti:
		print("  " + g)
	quit(1 if _guasti.size() > 0 else 0)
	return true


## Sposta il corpo E LO DICE AL SERVER FISICO.
##
## Scrivere `global_position` aggiorna il nodo, non il server: `move_and_collide`
## chiede al server, trova il corpo dove stava un istante prima e crede di
## sbattere subito contro qualcosa.
func _posa(corpo: CharacterBody3D, dove: Vector3) -> void:
	corpo.global_position = dove
	corpo.force_update_transform()
	PhysicsServer3D.body_set_state(corpo.get_rid(),
		PhysicsServer3D.BODY_STATE_TRANSFORM, corpo.global_transform)


## L'ANTA DEVE FINIRE LA CORSA QUANDO CHI L'HA APERTA SI SPOSTA. Fermarsi a filo di
## chi apre e' voluto - dietro c'e' un muro - ma e' voluto come una PAUSA, non come
## una posa: la promessa scritta in `door.gd` e' che il conto si rifa' ogni
## fotogramma. Se non fosse vera, ogni porta stretta resterebbe socchiusa per sempre
## e sembrerebbe rotta, che e' esattamente come la si vede giocando.
func _finisce(porta: Door) -> void:
	var anta := rad_to_deg(porta.rotation.y - porta.get("_chiusa_y")) * signf(porta.verso)
	if anta < porta.apertura_gradi - 1.0:
		_guasti.append("%s: tolto di mezzo il corpo resta a %.0f gradi invece di %.0f"
			% [porta.name, anta, porta.apertura_gradi])


## Quanti gradi l'anta gira A VUOTO prima di sbattere in qualcosa.
##
## E' il tetto vero dell'apertura e NON si deduce dalla pianta: dipende da cosa nel
## frattempo e' finito dietro la porta. Si prova la scatola dell'anta grado per
## grado contro tutto il resto della scena - e la si stringe di due centimetri per
## lato, perche' sfiorare il telaio non e' sbattere.
func _quanto_girano() -> void:
	var spazio := _scena.get_world_3d().direct_space_state
	for porta in _porte:
		var col := porta.get_node(^"Col") as CollisionShape3D
		var box := col.shape as BoxShape3D
		var prova := BoxShape3D.new()
		prova.size = Vector3(box.size.x - 0.04, box.size.y - 0.04, box.size.z)
		var par := PhysicsShapeQueryParameters3D.new()
		par.shape = prova
		par.exclude = [porta.get_rid(), _corpo.get_rid()]
		var y0: float = porta.get("_chiusa_y")
		var g := 0.0
		var libera := 130.0
		while g <= 130.0:
			var t := Transform3D(Basis(Vector3.UP, y0 + deg_to_rad(g) * signf(porta.verso)),
				porta.global_position)
			par.transform = t * col.transform
			if not spazio.intersect_shape(par, 1).is_empty():
				libera = g - 1.0
				break
			g += 1.0
		print("  %-26s gira libera fino a %3.0f gradi (si ferma a %.0f)"
			% [porta.name, libera, porta.apertura_gradi])
		if libera < porta.apertura_gradi:
			_guasti.append("%s: si apre a %.0f gradi ma sbatte gia' a %.0f"
				% [porta.name, porta.apertura_gradi, libera])
	print("")
