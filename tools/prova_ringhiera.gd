## LA RINGHIERA DELLA PASSERELLA SI TOCCA DOVE SI VEDE, E CI SI CAMMINA SENZA
## INCASTRARSI. Misurato, non raccontato.
##
## DA DOVE VIENE. Federico, giocando: «le hitbox della passerella, quella tonda,
## sono terribili: mi ci incastro sempre e si vedono i poligoni fatti in maniera
## molto sloppy. È incomprensibile dove si può toccare, e tante volte senti che
## stai scattando quando tocchi la passerella».
##
## COS'ERA. `geometria.py` girava ogni concio dell'anello di `-(ang + pi/2)`, cioè
## dell'angolo della TANGENTE, mentre `rot_y` vuole quello del RAGGIO: ogni pezzo
## si montava di un quarto di giro. L'impalcato calpestabile diventava un nastro
## di 43 cm in mezzo a un pavimento che se ne vedeva 105, e i conci del parapetto
## diventavano ventun ALETTE alte un metro piantate di traverso sul bordo, ognuna
## sporgente 27 cm dentro il passaggio, con mezzo metro di niente fra l'una e
## l'altra. Da fuori la ringhiera si vede tonda e continua: si camminava contro
## una cosa che non c'entrava niente con quello che si vedeva.
##
## PERCHÉ NESSUN CONTROLLO L'AVEVA VISTO. `verifica_passerella` percorreva la
## sola MEZZERIA dell'anello, e un concio girato copre la mezzeria lo stesso.
## Adesso quel controllo guarda tutta la larghezza e l'orientamento di ogni
## pezzo; questa sonda guarda la stessa cosa dall'altro capo, cioè in gioco, con
## la capsula vera del giocatore.
##
## DUE DOMANDE:
##   1. IL PROFILO. Si mette la capsula sulla mezzeria dell'anello e la si spinge
##      in fuori, a ogni mezzo grado. Il raggio a cui si ferma È il muro che il
##      giocatore sente: se ondeggia, la ringhiera è un poligono e camminandoci
##      lo si sente.
##   2. LA SALITA. Si sale la scala dal pavimento della sala, come si arriva
##      quassù la prima volta, e si guarda se si arriva davvero sull'impalcato.
##   3. IL GIRO. Si cammina davvero, appoggiati alla ringhiera come si fa, da un
##      capo all'altro del varco della scala. Si guarda quanto si avanza a ogni
##      passo di fisica: dove crolla, lì ci si incastra.
##
## IL DIFETTO SI RIMETTE: `CONCI_GIRATI=1` rigira di novanta gradi ogni concio
## dell'anello, all'avvio e in memoria, e riporta la passerella a com'era. Senza
## quel confronto un referto che dice «si cammina» non distingue il merito della
## cura dal fatto che nessuno abbia provato a camminarci.
##
## E IL SECONDO DIFETTO ANCHE: `MARGINE_MILLIMETRO=1` riporta il `safe_margin`
## del corpo al millimetro di fabbrica. Con quello, anche una ringhiera fatta
## bene si incastra a ogni giunto — vedi l'intestazione di
## `world/player/player.tscn`, dove il numero vive.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_ringhiera.tscn
##     CONCI_GIRATI=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_ringhiera.tscn
##     MARGINE_MILLIMETRO=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_ringhiera.tscn
##     TRACCIA=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_ringhiera.tscn
extends Node

## Il centro della cupola in pianta e le quote della passerella: gli stessi numeri
## di `tools/geometria.py`. Qui non si genera niente, si misura.
const CX := 2.6
const CZ := 2.5
const R_PASS := 1.4
const CALPESTIO := 0.59

## Il raggio a cui la capsula deve fermarsi contro il parapetto: faccia interna
## del corrente (1,89) meno il raggio della capsula.
const MURO_ATTESO := 1.89 - 0.3

## Quanto può ondeggiare quel raggio prima che si senta camminandoci, in metri.
## Con settantadue lati la freccia dell'arco vale 1,8 mm; mezzo centimetro è già
## largo, ed è il punto in cui questa sonda comincia a dire di no.
const ONDA_MAX := 0.005

## Ogni quanti gradi si tasta il muro.
const PASSO_GRADI := 0.5

## Quanto si spinge in fuori la direzione di marcia, in gradi: appoggiati alla
## ringhiera, non paralleli. È il gesto che si incastrava.
const APPOGGIO_GRADI := 30.0

## Il varco della scala, in gradi di gioco: da qui a qui non c'è ringhiera, e non
## deve essercene. Il giro si fa da un capo all'altro, non attraverso.
const VARCO_DA := 70.0
const VARCO_A := 110.0

## Quanto può scendere l'avanzamento di un singolo passo, rispetto a quello che
## si avrebbe camminando liberi, prima che si chiami incastro.
const CROLLO := 0.45

var _spazio: PhysicsDirectSpaceState3D
var _guasti := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[ringhiera] GUASTO: " + msg)


func _angolo(p: Vector3) -> float:
	return atan2(p.z - CZ, p.x - CX)


func _raggio(p: Vector3) -> float:
	return Vector2(p.x - CX, p.z - CZ).length()


## La capsula del giocatore in piedi. Da `world/player/player.tscn`.
func _capsula() -> CapsuleShape3D:
	var forma := CapsuleShape3D.new()
	forma.radius = 0.3
	forma.height = 1.8
	return forma


## Fin dove arriva la capsula spinta in fuori partendo dalla mezzeria, e contro
## cosa si ferma. Si parte due centimetri sopra il calpestio: appoggiata al
## pavimento la capsula toccherebbe sempre l'impalcato, e l'impalcato non è la
## domanda.
func _tasta(ang: float) -> Array:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _capsula()
	q.collision_mask = 1
	q.margin = 0.0
	var dir := Vector3(cos(ang), 0.0, sin(ang))
	var da := Vector3(CX, CALPESTIO + 0.92, CZ) + dir * R_PASS
	q.transform = Transform3D(Basis.IDENTITY, da)
	q.motion = dir * 1.2
	var f := _spazio.cast_motion(q)
	var r: float = R_PASS + f[0] * 1.2
	q.transform = Transform3D(Basis.IDENTITY, da + dir * (f[1] * 1.2 + 0.005))
	var nome := "il vuoto"
	for c in _spazio.intersect_shape(q, 4):
		var n := c["collider"] as Node
		if n != null:
			nome = n.name
			break
	return [r, nome]


## IL DIFETTO SI RIMETTE. Rigira di novanta gradi ogni concio dell'anello, che è
## esattamente quello che faceva il `-(ang + pi/2)` di `geometria.py`.
func _rigira() -> int:
	var girati := 0
	for n in get_tree().root.find_children("*", "StaticBody3D", true, false):
		var c := n as StaticBody3D
		if c.name.begins_with("Pass") or c.name.begins_with("ParapettoEst"):
			c.global_basis = c.global_basis.rotated(Vector3.UP, PI / 2.0)
			girati += 1
	return girati


func _prova() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 6:
		await get_tree().physics_frame
	var player := Player.find_in(get_tree())
	if player == null:
		print("[ringhiera] il giocatore non c'è: la prova non vale")
		get_tree().quit(1)
		return
	_spazio = player.get_world_3d().direct_space_state
	if OS.get_environment("CONCI_GIRATI") == "1":
		print("[ringhiera] DIFETTO RIMESSO: %d conci rigirati di novanta gradi" % _rigira())
		await get_tree().physics_frame

	_profilo()
	# IL SECONDO DIFETTO SI RIMETTE: `MARGINE_MILLIMETRO=1` riporta il corpo al
	# `safe_margin` di fabbrica, 0,001, ed e' con quello che il giro si paga
	# cento passi di fisica in piu' e trentasette velocita' azzerate. Vedi
	# l'intestazione di `world/player/player.tscn`.
	if OS.get_environment("MARGINE_MILLIMETRO") == "1":
		player.safe_margin = 0.001
		print("[ringhiera] DIFETTO RIMESSO: safe_margin riportato a 0.001")
	print("[ringhiera] safe_margin del corpo: %.3f" % player.safe_margin)
	await _salita(player)
	await _giro(player)
	print("[ringhiera] %d guasti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)


## Il muro che si tocca, girando intorno. Fuori dal varco della scala la capsula
## deve fermarsi sempre allo stesso raggio: quello è il senso di «tonda».
func _profilo() -> void:
	var passi := int(360.0 / PASSO_GRADI)
	var mn := INF
	var mx := -INF
	var quanti := 0
	var buchi := 0
	var contro := {}
	for i in passi:
		var g := 360.0 * i / passi
		if g > VARCO_DA and g < VARCO_A:
			continue                       # lì la ringhiera non c'è, e non deve esserci
		var f := _tasta(TAU * i / passi)
		var r: float = f[0]
		if r > MURO_ATTESO + 0.20:
			buchi += 1                     # si è passati attraverso la ringhiera
			continue
		mn = minf(mn, r)
		mx = maxf(mx, r)
		quanti += 1
		contro[f[1]] = int(contro.get(f[1], 0)) + 1
	if quanti == 0:
		_guasto("il parapetto non si tocca da nessuna parte")
		return
	print("[ringhiera] muro esterno: %d punti su %d, raggio da %.4f a %.4f (atteso %.4f), ONDA %.1f mm, %d pezzi distinti"
		% [quanti, quanti + buchi, mn, mx, MURO_ATTESO, (mx - mn) * 1000.0, contro.size()])
	if buchi > 0:
		_guasto("in %d punti su %d la ringhiera si vede e non si tocca: la capsula passa"
			% [buchi, quanti + buchi])
	if mx - mn > ONDA_MAX:
		_guasto("il muro ondeggia di %.0f mm fra %.3f e %.3f: la ringhiera si tocca a scatti"
			% [(mx - mn) * 1000.0, mn, mx])
	if absf(mn - MURO_ATTESO) > 0.05:
		_guasto("ci si ferma a %.3f invece che a %.3f: c'è qualcosa di traverso sul passaggio"
			% [mn, MURO_ATTESO])


## Si sale dal pavimento della sala fino all'impalcato, camminando dritti su per
## la scala. È il modo in cui si arriva quassù, e passa per il varco: se il varco
## toccato non coincide con quello che si vede, è qui che si sbatte.
func _salita(player: Player) -> void:
	# il piede della rampa: fuori dal bordo dell'impalcato di tutta la sua lunghezza
	var piede := CZ + 1.925 + 1.10
	player.velocity = Vector3.ZERO
	player.global_position = Vector3(CX, 0.05, piede + 0.35)
	player.rotation.y = 0.0        # base a riposo: si guarda lungo -Z, verso la cupola
	for _i in 30:
		await get_tree().physics_frame
	var partenza := player.global_position.y
	Input.action_press(&"move_forward")
	var passi := 0
	while passi < 240 and player.global_position.y < CALPESTIO - 0.02:
		await get_tree().physics_frame
		passi += 1
	Input.action_release(&"move_forward")
	for _i in 10:
		await get_tree().physics_frame
	var q := player.global_position
	print("[ringhiera] salita: da y %.2f a y %.2f in %d passi, raggio d'arrivo %.2f"
		% [partenza, q.y, passi, _raggio(q)])
	if q.y < CALPESTIO - 0.05:
		_guasto("dalla scala non si arriva sull'impalcato: fermo a y %.2f invece di %.2f"
			% [q.y, CALPESTIO])
	elif _raggio(q) > 1.93:
		_guasto("si sale ma non si entra: fermo a %.2f dal centro, l'impalcato "
			% _raggio(q) + "finisce a 1,93")


## Un giro appoggiati alla ringhiera, da un capo all'altro del varco della scala.
## L'avanzamento di ogni passo si confronta con quello di chi cammina libero: è
## il numero che dice se ci si incastra, e dove.
func _giro(player: Player) -> void:
	var arco := deg_to_rad(360.0 - (VARCO_A - VARCO_DA))
	var a0 := deg_to_rad(VARCO_A + 5.0)
	player.velocity = Vector3.ZERO
	player.global_position = Vector3(
		CX + R_PASS * cos(a0), CALPESTIO + 0.02, CZ + R_PASS * sin(a0))
	for _i in 30:
		await get_tree().physics_frame

	var dt := 1.0 / Engine.physics_ticks_per_second
	var libera := Player.walk_speed * cos(deg_to_rad(APPOGGIO_GRADI))
	var ang := _angolo(player.global_position)
	var girato := 0.0
	var passi := 0
	var incastri := {}
	var peggiore := [INF, 0.0, "", 0.0]
	var traccia := OS.get_environment("TRACCIA") == "1"
	Input.action_press(&"move_forward")
	while girato < arco and passi < 1800:
		var t := _angolo(player.global_position) + PI / 2.0 - deg_to_rad(APPOGGIO_GRADI)
		player.rotation.y = atan2(-cos(t), -sin(t))
		await get_tree().physics_frame
		passi += 1
		var nuovo := _angolo(player.global_position)
		var d := wrapf(nuovo - ang, -PI, PI)
		ang = nuovo
		girato += d
		# QUANTO DOVEVA AVANZARE: la velocità di marcia, proiettata sulla tangente
		# (si spinge in fuori di APPOGGIO_GRADI, non si va dritti) e divisa per il
		# raggio a cui ci si trova davvero.
		var r := _raggio(player.global_position)
		var atteso := libera * dt / maxf(r, 0.1)
		# `TRACCIA=1` STAMPA I PASSI IN CUI LA VELOCITA' E' ZERO, con le normali
		# di ogni contatto. E' cosi' che si e' visto che cos'era: a ogni fermata
		# i contatti sono DUE conci consecutivi del parapetto, con le normali a
		# cinque gradi l'una dall'altra e mezzo millimetro di compenetrazione -
		# la capsula incuneata nel giunto. Chi tocca di nuovo questi numeri lo
		# riaccenda invece di indovinare.
		if traccia and player.velocity.length() < 0.001:
			var det := ""
			for c in player.get_slide_collision_count():
				var u := player.get_slide_collision(c)
				det += "  [%s n=%s prof=%.4f]" % [
					(u.get_collider() as Node).name, u.get_normal(), u.get_depth()]
			print("[ringhiera/traccia] passo %d, ang %.2f, r %.4f: velocita' azzerata%s"
				% [passi, rad_to_deg(nuovo), r, det])
		# I PRIMI PASSI NON CONTANO: si parte da fermi, e l'accelerazione del
		# controller ci mette una ventina di tick ad arrivare a regime.
		if passi > 25 and d < atteso * CROLLO:
			var contro := ""
			for c in player.get_slide_collision_count():
				var n := player.get_slide_collision(c).get_collider() as Node
				if n != null and not contro.contains(n.name):
					contro += n.name + " "
			incastri[roundi(rad_to_deg(nuovo))] = true
			if d / atteso < peggiore[0]:
				peggiore = [d / atteso, rad_to_deg(nuovo), contro, r]
	Input.action_release(&"move_forward")

	# I PASSI CHE BASTEREBBERO: l'arco percorso al RAGGIO DEL MURO, non a quello
	# della mezzeria. Appoggiati alla ringhiera si cammina venti centimetri piu'
	# in fuori, e il giro e' piu' lungo: misurarlo sulla mezzeria farebbe sembrare
	# lento anche un giro perfetto.
	var liberi := int(arco * MURO_ATTESO / (libera * dt))
	print("[ringhiera] giro: %.0f gradi su %.0f in %d passi (camminando liberi ne servirebbero %d)"
		% [rad_to_deg(girato), rad_to_deg(arco), passi, liberi])
	if girato < arco:
		_guasto("il giro non si chiude: fermo a %.0f gradi dopo %d passi"
			% [rad_to_deg(ang), passi])
	if incastri.is_empty():
		print("[ringhiera] nessun passo sotto il %.0f%% dell'avanzamento libero" % (CROLLO * 100.0))
	else:
		_guasto("ci si impunta in %d punti del giro (%s); il peggiore a %.0f gradi, "
			% [incastri.size(), incastri.keys(), peggiore[1]]
			+ "avanzato il %.0f%% di quanto doveva, raggio %.3f, contro %s"
			% [peggiore[0] * 100.0, peggiore[3], peggiore[2]])
