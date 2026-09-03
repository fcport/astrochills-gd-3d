## UN OGGETTO POSATO SI FERMA DOVE SI VEDE - E DA LI' SI RIPRENDE?
##
## DUE DOMANDE, E LA SECONDA E' ARRIVATA DOPO. La prima e' la caduta: dove si
## ferma una cosa lasciata andare sopra un mobile. La seconda l'ha trovata
## Federico giocando, ed e' il seguito esatto della prima: «ho preso la borraccia
## dalla stanza di controllo, l'ho messa sul carrello dove c'e' il proiettore, e
## non potevo piu' prendere la borraccia». Si posava dove si vede, e da li' non si
## riprendeva piu'.
##
## STANNO NELLA STESSA SONDA PERCHE' SONO LO STESSO POSTO. Servono la stessa
## scena, lo stesso oggetto e soprattutto la stessa ricerca - i blocchi la cui
## cima e' aria - e una seconda sonda vorrebbe dire ricopiare quella ricerca e
## lasciare che le due copie invecchino ognuna per conto suo. Qui l'oggetto cade,
## e appena e' fermo gli si gira intorno per vedere se lo si puo' ancora prendere.
##
## LA DOMANDA. La collisione di questa scena la genera `gen_blockout.py` da
## `geometria.py`, e ogni mobile e' UN BLOCCO PIENO alto quanto il suo pezzo piu'
## alto. Per camminare e' perfetto e per un anno e' bastato. Poi sono arrivati gli
## oggetti che cadono, e ogni cima finta e' diventata un posto dove la roba resta
## sospesa: Federico ha fotografato prima un termos e poi una radiolina a
## mezz'aria sopra il carrello del proiettore.
##
## LA CURA E' `world/corazza.gd`: una seconda collisione, fatta con la geometria
## che si VEDE, su cui cadono gli oggetti mentre il giocatore continua a
## camminare sugli ingombri. Questa sonda misura se funziona, e lo fa nel modo in
## cui il difetto e' comparso: LASCIANDO CADERE QUALCOSA.
##
## SI PROVA DOVE FA PIU' MALE. I bersagli non sono scelti a mano: si cercano i
## blocchi la cui cima e' quasi tutta aria - si guarda, maglia per maglia, quanto
## in basso sta la geometria vera - e si lascia cadere una sonda proprio li'. Un
## armadio non direbbe niente, perche' sopra un armadio le due collisioni
## coincidono.
##
## I DIFETTI SI RIMETTONO, uno per domanda: `SUGLI_INGOMBRI=1` riporta gli oggetti
## a cadere sui blocchi grezzi, ed e' il comportamento di prima della corazza;
## `MIRA_SUGLI_INGOMBRI=1` riporta la mira a fermarsi sugli ingombri, ed e' il
## comportamento con cui la borraccia spariva.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_appoggi.tscn
##     SUGLI_INGOMBRI=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_appoggi.tscn
##     MIRA_SUGLI_INGOMBRI=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_appoggi.tscn
extends Node

## Il passo con cui si guarda la cima di un blocco, in metri.
const MAGLIA := 0.05

## Quanto sotto la cima puo' stare la geometria perche' la maglia conti come
## piena: una mesh puo' essere piu' magra della sua collisione di un dito.
const SOTTO := 0.05

## Sotto questa frazione di maglie piene, la cima del blocco e' aria.
const VUOTO := 0.20

## Quanto puo' restare sopra la geometria vera un oggetto posato, in metri.
const TOLLERANZA := 0.06

## Da quanto lontano si prova a guardare l'oggetto posato, in metri, misurati in
## orizzontale. Piu' della portata dell'interazione non ha senso provarlo - a
## quella distanza non si prende niente, ed e' giusto cosi' - e piu' vicino di
## mezzo metro il giocatore sta dentro il mobile.
const GIRO_INTORNO := [0.55, 0.70, 0.85]

## Quante direzioni si provano intorno all'oggetto. Otto: i quattro lati e i
## quattro angoli. Un carrello si guarda da dove ci si arriva, e da che parte sia
## non lo sa nessuno qui dentro.
const VERSI := 8

var _guasti := 0
var _spazio: PhysicsDirectSpaceState3D
## Quanti oggetti si e' provato a riprendere, e quanti si sono lasciati prendere.
var _ripresi := 0
var _tentati := 0
## Da quanti posti, nell'ultimo giro, un giocatore in piedi avrebbe davvero potuto
## provarci: ci sta con la capsula E ha l'oggetto dentro la portata del raggio.
## Zero vuol dire che il caso non era provabile, non che la mira ha sbagliato.
var _posti_utili := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[appoggi] GUASTO: " + msg)


func _corpi(n: Node, fuori: Array[StaticBody3D]) -> void:
	if n is StaticBody3D:
		fuori.append(n as StaticBody3D)
	for f in n.get_children():
		_corpi(f, fuori)


## A che quota si ferma una cosa lasciata cadere qui, secondo la collisione
## indicata. E' la domanda che questa sonda fa tre volte con maschere diverse:
## alla geometria vera, agli ingombri, e all'oggetto vero.
func _quota(x: float, z: float, da: float, maschera: int) -> float:
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, da, z), Vector3(x, -0.5, z))
	q.collision_mask = maschera
	var colpo := _spazio.intersect_ray(q)
	return (colpo["position"] as Vector3).y if not colpo.is_empty() else -1e9


## L'impronta e la cima di un corpo fatto di una sola scatola.
func _scatola(c: StaticBody3D) -> AABB:
	var forme := 0
	var trovata := AABB()
	for f in c.get_children():
		var forma := f as CollisionShape3D
		if forma == null or forma.shape == null:
			continue
		forme += 1
		var box := forma.shape as BoxShape3D
		if box == null:
			return AABB()
		var xf := forma.global_transform
		var mezzo := box.size * 0.5
		var mn := Vector3.INF
		var mx := -Vector3.INF
		for i in 8:
			var p := xf * Vector3(
				mezzo.x if (i & 1) else -mezzo.x,
				mezzo.y if (i & 2) else -mezzo.y,
				mezzo.z if (i & 4) else -mezzo.z)
			mn = mn.min(p)
			mx = mx.max(p)
		trovata = AABB(mn, mx - mn)
	return trovata if forme == 1 else AABB()


## I blocchi la cui cima e' quasi tutta aria, dal piu' bugiardo in giu'.
func _cime_finte(corpi: Array[StaticBody3D]) -> Array:
	var fuori := []
	for c in corpi:
		var box := _scatola(c)
		var cima := box.position.y + box.size.y
		# Solo i mobili: sopra i due metri sono muri e soffitti, sotto i venti
		# centimetri zoccoli e soglie, e su nessuno dei due si posa niente.
		if box.size == Vector3.ZERO or cima < 0.20 or cima > 2.00:
			continue
		if box.size.x < 0.20 or box.size.z < 0.20:
			continue
		var maglie := 0
		var piene := 0
		# DOVE SI PROVERA' A POSARE: la maglia vuota con la geometria PIU' ALTA,
		# cioe' quella ancora sul mobile e piu' lontana dalla cima finta. La prima
		# stesura teneva l'ultima maglia vuota che capitava, e capitava di essere
		# oltre il bordo del mobile: si lasciava cadere la sonda accanto al
		# carrello invece che sopra, e il referto diceva «geometria vera 0,00»
		# indicando il pavimento.
		var centro := Vector2(box.position.x, box.position.z)
		var meglio := -1e9
		var x := box.position.x + MAGLIA * 0.5
		while x < box.position.x + box.size.x:
			var z := box.position.z + MAGLIA * 0.5
			while z < box.position.z + box.size.z:
				maglie += 1
				var q := _quota(x, z, cima + SOTTO, Corazza.LAYER_APPOGGI)
				if q >= cima - SOTTO:
					piene += 1
				elif q > meglio:
					meglio = q
					centro = Vector2(x, z)
				z += MAGLIA
			x += MAGLIA
		if maglie > 0 and float(piene) / maglie < VUOTO:
			fuori.append([c.name, cima, float(piene) / maglie, centro])
	fuori.sort_custom(func(a, b): return a[2] < b[2])
	return fuori


func _prova() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 6:
		await get_tree().physics_frame
	var player := Player.find_in(get_tree())
	if player == null:
		print("[appoggi] il giocatore non c'e': la prova non vale")
		get_tree().quit(1)
		return
	_spazio = player.get_world_3d().direct_space_state
	# IL DIFETTO DELLA MIRA: a `true` il raggio torna a fermarsi sugli ingombri, e
	# la borraccia sul carrello torna a sparire. Vedi `world/player/player.gd`.
	player.mira_sugli_ingombri = OS.get_environment("MIRA_SUGLI_INGOMBRI") == "1"

	if Corazza.find_in(get_tree()) == null:
		print("[appoggi] la corazza non c'e': la prova non vale")
		get_tree().quit(1)
		return

	var corpi: Array[StaticBody3D] = []
	_corpi(get_tree().root, corpi)
	var finte := _cime_finte(corpi)
	print("[appoggi] %d blocchi di arredo, %d con la cima quasi tutta aria"
		% [corpi.size(), finte.size()])
	# SONDA CIECA: se nessun blocco ha la cima finta non c'e' niente da provare, e
	# questa sonda passerebbe anche con la corazza spenta.
	if finte.size() < 3:
		_guasto("SONDA CIECA: solo %d blocchi con la cima finta, non bastano a "
			% finte.size() + "distinguere la geometria vera dagli ingombri")

	# Su ognuno si lascia cadere un oggetto vero - non un raggio: un raggio prova
	# la collisione, un corpo prova anche che ci si fermi sopra.
	# DIECI E NON SEI: da quando la sonda fa anche la seconda domanda, i casi che
	# contano sono quelli in cui l'oggetto RESTA sul mobile, e la meta' scivola via
	# dai sedili e dai bordi. Con sei blocchi si finiva a provare la mira una volta
	# sola.
	var quanti := mini(finte.size(), 10)
	for k in quanti:
		var caso: Array = finte[k]
		var nome: String = caso[0]
		var cima: float = caso[1]
		var dove: Vector2 = caso[3]
		var vera := _quota(dove.x, dove.y, cima + 0.30, Corazza.LAYER_APPOGGI)
		var sasso := Carryable.new()
		sasso.name = "Sonda"
		sasso.nome = "la sonda"
		sasso.mass = 0.5
		var forma := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.06, 0.06, 0.06)
		forma.shape = box
		forma.position = Vector3(0.0, 0.03, 0.0)
		sasso.add_child(forma)
		get_tree().current_scene.add_child(sasso)
		sasso.global_position = Vector3(dove.x, cima + 0.40, dove.y)
		if OS.get_environment("SUGLI_INGOMBRI") == "1":
			# IL DIFETTO: si torna a cadere sugli ingombri, cioe' sui blocchi
			# grezzi. E' come stava prima della corazza, ed e' il confronto senza
			# il quale «la sonda si e' fermata a 0,75» non direbbe se il merito e'
			# della geometria vera o del caso.
			sasso.collision_mask = Interactable.LAYER_WORLD
		for _i in 150:
			await get_tree().physics_frame
		var finito := sasso.global_position.y
		print("[appoggi] %-16s cima del blocco %.2f, geometria vera %.2f, "
			% [nome, cima, vera] + "la sonda si ferma a %.2f" % finito)
		if finito > vera + TOLLERANZA:
			_guasto("sopra %s la sonda resta a %.2f invece che a %.2f: e' "
				% [nome, finito, vera] + "appoggiata sulla cima finta del blocco")
		else:
			# SECONDA DOMANDA. La si fa dove l'oggetto e' rimasto, qualunque sia
			# la quota: e' `_si_riprende` a dire se da qualche parte, li' intorno,
			# un giocatore in piedi ci arriverebbe.
			var da_dove := await _si_riprende(sasso)
			if _posti_utili == 0:
				# NESSUN POSTO DA CUI PROVARE, e non e' un guasto: una scatola
				# rotolata sotto una sedia sta a mezzo metro da terra, e da in
				# piedi e' fuori dalla portata della mira comunque - 1,60 di
				# occhio contro 1,20 di raggio. A terra ci si arriva
				# accovacciandosi: altro gesto, altra prova.
				print("[appoggi] %-16s ferma a %.2f: da in piedi non ci si "
					% [nome, finito] + "arriva nemmeno senza ingombri, la mira "
					+ "non si prova qui")
			else:
				_tentati += 1
				if da_dove.is_empty():
					_guasto("posata a %.2f dentro il blocco %s - che arriva a "
						% [finito, nome] + "%.2f - la sonda non si riesce piu' a "
						% cima + "mirare da nessuno dei %d posti da cui ci si "
						% _posti_utili + "arriverebbe")
				else:
					_ripresi += 1
					print("[appoggi] %-16s e da li' si riprende: %s"
						% [nome, da_dove])
		sasso.queue_free()

	# SONDA CIECA, il secondo modo: se nessun oggetto e' finito dentro un ingombro
	# non si e' provato niente, e un referto pulito non varrebbe niente.
	if _tentati == 0:
		_guasto("SONDA CIECA: nessun oggetto e' rimasto dentro un ingombro, "
			+ "quindi la mira non e' stata messa alla prova")
	if _guasti == 0:
		print("[appoggi] ok: si posa dove si vede, non sulla cima degli ingombri")
		print("[appoggi] ok: %d oggetti su %d posati dentro un ingombro si "
			% [_ripresi, _tentati] + "possono ancora prendere")
	else:
		print("[appoggi] GUASTO: %d controlli falliti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)


## DA FUORI, QUELLA COSA SI PUO' ANCORA PRENDERE? Torna da dove la si e' vista, o
## una stringa vuota se non la si vede da nessuna parte.
##
## SI CHIEDE AL GIOCATORE, NON AL MOTORE, ed e' la differenza fra questa prova e
## una che non proverebbe niente. Il raggio della mira ha origine, portata,
## maschera e regole sue - e il difetto della borraccia stava proprio li' dentro:
## un raycast rifatto a mano dalla sonda avrebbe detto «si vede benissimo» mentre
## in partita il prompt non compariva. Quindi si mette il giocatore vero davanti
## all'oggetto, si lascia girare un tick di fisica - il suo raggio si aggiorna li'
## - e gli si chiede `mirato()`.
##
## GLI SI GIRA INTORNO, invece di sceglierne il davanti: un carrello in mezzo a
## una sala si guarda da dove capita, e da che parte ci si arrivi non lo sa
## nessuno. Basta UNA posizione buona perche' l'oggetto sia prendibile, e se non
## ce n'e' nemmeno una e' sparito davvero.
##
## SI STA DOVE UN GIOCATORE STAREBBE. La capsula viene provata prima di
## teletrasportarcelo, e non e' pignoleria: dentro l'ingombro il raggio non lo
## colpisce - un `RayCast3D` che parte dentro una forma non la vede - e la sonda
## direbbe «ok» proprio dal punto in cui nessuno puo' stare.
func _si_riprende(sasso: Carryable) -> String:
	var player := Player.find_in(get_tree())
	if player == null:
		return ""
	var cam := player.camera()
	var bersaglio := sasso.global_position + Vector3(0.0, 0.03, 0.0)
	_posti_utili = 0
	for d in GIRO_INTORNO:
		for k in VERSI:
			var ang := TAU * float(k) / float(VERSI)
			var x: float = bersaglio.x + cos(ang) * (d as float)
			var z: float = bersaglio.z + sin(ang) * (d as float)
			var suolo := _quota(x, z, bersaglio.y + 1.2, Interactable.LAYER_WORLD)
			if suolo < -1e8:
				continue
			var dove := Vector3(x, suolo, z)
			if not _c_e_da_stare(dove, player):
				continue
			# E DA QUI CI SI ARRIVA? La portata del raggio e' 1,20 m dall'OCCHIO,
			# che sta a 1,60 da terra: una cosa a mezzo metro d'altezza e' fuori
			# portata da qualunque posizione in piedi, ingombri o no. Contarla
			# come «non si vede» sarebbe accusare la mira di un limite che e'
			# scritto in `INTERACT_RANGE` ed e' voluto.
			var occhio := Vector3(dove.x, dove.y + Player.EYE_HEIGHT, dove.z)
			if occhio.distance_to(bersaglio) > Player.INTERACT_RANGE:
				continue
			# E DA QUI SI VEDE? Fra l'occhio e l'oggetto non deve esserci
			# GEOMETRIA VERA - non gli ingombri, che sono proprio quello che
			# questa prova accusa di essere di troppo. Dietro la testiera del
			# letto una tazza sul materasso e' nascosta davvero, e pretendere di
			# poterla prendere da li' sarebbe pretendere di vedere attraverso il
			# legno. La sonda scarta quei posti; se non ne resta nemmeno uno, il
			# caso non e' provabile e lo dice.
			var vista := PhysicsRayQueryParameters3D.create(occhio, bersaglio)
			vista.collision_mask = Corazza.LAYER_APPOGGI
			# SENZA CONTARE LA SONDA STESSA: da quando gli oggetti stanno sul
			# layer degli appoggi - ci si posa sopra roba - un raggio che punta al
			# loro centro colpisce prima la loro superficie, e ogni posto
			# risulterebbe cieco.
			vista.exclude = [sasso.get_rid()]
			if not _spazio.intersect_ray(vista).is_empty():
				continue
			_posti_utili += 1
			player.global_position = dove
			player.look_at(Vector3(bersaglio.x, dove.y, bersaglio.z), Vector3.UP)
			if cam != null:
				cam.look_at(bersaglio, Vector3.UP)
			await get_tree().physics_frame
			await get_tree().physics_frame
			if player.mirato() == sasso:
				return "da %.2f m, guardando verso %d gradi" % [d, int(rad_to_deg(ang))]
	return ""


## Ci si sta in piedi, qui? Stessa capsula del giocatore, stessa domanda di
## `prova_quadro.gd`: alzata da terra, o il pavimento conterebbe come ostacolo.
func _c_e_da_stare(dove: Vector3, player: Player) -> bool:
	var forma := CapsuleShape3D.new()
	forma.radius = 0.30
	forma.height = 1.80
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = forma
	q.transform = Transform3D(Basis.IDENTITY, Vector3(dove.x, dove.y + 0.95, dove.z))
	q.collision_mask = Interactable.LAYER_WORLD
	q.exclude = [player.get_rid()]
	return _spazio.intersect_shape(q, 1).is_empty()
