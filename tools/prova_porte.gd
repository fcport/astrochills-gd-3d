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

## Se l'allestimento di questa prova regge. Falso quando non si e' trovato un posto
## libero per la persona: le misure che ne escono non dicono niente sulla porta, e
## sommarle ai guasti manderebbe a cercare un difetto che non c'e'.
var _valido := true


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
	_chiusa = Transform3D(Basis(Vector3.UP, porta.get("_chiusa_y")), porta.global_position)
	var col0 := porta.get_node(^"Col") as CollisionShape3D
	var lunga := (col0.shape as BoxShape3D).size.x
	_valido = true
	var punto := Vector3.ZERO
	if dove > 0:
		# NEL SETTORE, MA DOVE UNA PERSONA CI STA. Un punto fisso a quarantacinque
		# centimetri dal cardine e quarantadue dal battente va bene per una porta
		# larga novanta in mezzo a un vano libero, e va male per un'anta larga
		# quarantatre in un angolo: davanti alle due ante dell'armadio quel punto
		# cade dentro il termosifone. Si provano piu' posti e si tiene il primo
		# VUOTO, restando sempre dentro il settore che l'anta spazza - fuori di li'
		# la prova non proverebbe piu' niente.
		var trovato := false
		for l in [0.45, 0.32, 0.60, 0.22, 0.72]:
			for sc in [0.42, 0.52, 0.34, 0.62]:
				if Vector2(l, sc).length() > lunga + Door.MARGINE - 0.03:
					continue
				punto = _chiusa * Vector3(l, 0.0, -sc * signf(porta.verso))
				punto = Vector3(punto.x, ALTEZZA, punto.z)
				if _libera(porta, punto):
					trovato = true
					break
			if trovato:
				break
		if not trovato:
			_guasti.append("BANCO: davanti a %s non c'e' posto per una persona in "
				% porta.name + "nessuno dei punti provati: la prova non vale")
			_valido = false
			punto = _chiusa * Vector3(0.45, 0.0, -0.42 * signf(porta.verso))
			punto = Vector3(punto.x, ALTEZZA, punto.z)
	else:
		# dall'altra parte il punto e' fisso e sta spesso DENTRO un muro - dietro una
		# porta c'e' quasi sempre il muro del vano - ed e' voluto: li' si chiede solo
		# che la porta non lo tocchi, e un corpo fermo dentro un muro resta fermo.
		punto = _chiusa * Vector3(0.45, 0.0, 0.65 * signf(porta.verso))
		punto = Vector3(punto.x, ALTEZZA, punto.z)
	_prima = punto
	_posa(_corpo, _prima)
	var col := porta.get_node(^"Col") as CollisionShape3D
	_portata = (col.shape as BoxShape3D).size.x + Door.MARGINE
	porta.interacted.emit(_corpo)
	_era = Vector3.ZERO
	_mosso = 0.0
	_restano = CORSA


## Il posto dove il banco ha appena messo la persona deve essere VUOTO.
##
## E' un controllo sul banco, non sulla porta, e nasce da due guasti che sembravano
## difetti delle ante dell'armadio: «scosta a 3,5 m/s». Non era l'anta. Il corpo
## veniva posato a quarantadue centimetri dal battente e a quarantacinque dal
## cardine - misure buone per una porta larga novanta, non per un'anta larga
## quarantatre in un angolo - e finiva mezzo dentro il termosifone. Al primo
## `move_and_collide` la fisica lo espelle, e l'espulsione e' istantanea per
## definizione: il banco misurava la spinta della porta e leggeva quella del
## motore.
##
## Un banco che accusa il codice del proprio errore di allestimento e' peggio di
## nessun banco, perche' manda a cercare un guasto che non c'e'. Se non c'e' posto
## per una persona, si dice - e quella prova si salta.
func _libera(porta: Door, punto: Vector3) -> bool:
	var spazio := _scena.get_world_3d().direct_space_state
	var par := PhysicsShapeQueryParameters3D.new()
	var capsula := CapsuleShape3D.new()
	# stretta di un centimetro: SFIORARE un muro non e' esserci dentro, e a filo
	# di parete la capsula tocca sempre
	capsula.radius = 0.29
	capsula.height = 1.70
	par.shape = capsula
	par.transform = Transform3D(Basis(), punto)
	par.exclude = [porta.get_rid(), _corpo.get_rid()]
	return spazio.intersect_shape(par, 1).is_empty()


## Un fotogramma di sorveglianza: nessuna compenetrazione, nessuno strappo.
func _sorveglia(porta: Door, delta: float, nel_giro: bool) -> void:
	if not _valido:
		_era = _corpo.global_position
		return
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
	print("  %-26s si apre a %2.0f gradi, il corpo scostato di %.2f m%s"
		% [porta.name, anta, _mosso, "" if _valido else "   (allestimento non valido)"])
	if not _valido:
		return

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

		# QUELLO CHE L'ANTA TOCCA GIA' DA CHIUSA NON E' UN OSTACOLO: E' IL MOBILE.
		# Un'anta di armadietto sta DENTRO l'impronta del suo armadio - da chiusa e'
		# il fronte del mobile - e senza questo passo il banco la trovava in
		# compenetrazione al grado zero e dichiarava tutte e tre le ante bloccate
		# prima ancora di partire. Vale anche per le porte, dove non cambia niente
		# perche' nessuna tocca il proprio telaio: si vede dal fatto che i loro
		# numeri restano quelli di prima.
		par.transform = Transform3D(Basis(Vector3.UP, y0), porta.global_position) * col.transform
		var suo := par.exclude
		for tocco in spazio.intersect_shape(par, 16):
			suo.append(tocco["rid"])
		par.exclude = suo

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
