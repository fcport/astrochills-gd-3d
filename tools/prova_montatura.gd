## IL CENTRO DELLA CUPOLA SI TOCCA DOVE SI VEDE.
##
## DA DOVE VIENE. Federico, in partita, con una foto scattata dalla passerella
## verso il telescopio: «altre hitbox qui non vanno bene». È il secondo tempo
## della storia della ringhiera (`prova_ringhiera.gd`): sistemato il bordo di
## fuori, restava quello di dentro.
##
## COS'ERA. Il vuoto centrale è tappato da un OTTAGONO — due scatole da 1,24 m
## girate di 45 gradi l'una sull'altra, `geometria.py` — mentre l'impalcato che
## si vede finisce su un CERCHIO di raggio 0,875. Un ottagono inscritto in un
## cerchio lo tocca in otto punti e rientra di 25 cm a mezza faccia: camminando
## lungo il bordo interno il muro invisibile va avanti e indietro di un quarto di
## metro, con otto spigoli in cui infilarsi. E quei 25 cm non si vedono: lì c'è
## il pozzo aperto, e in fondo il telescopio.
##
## PERCHÉ NESSUN CONTROLLO L'AVEVA VISTO. `verifica_passerella` misura la LUCE
## fra parapetto e pieno centrale, cioè quanto passaggio resta: un metro, e passa
## — un ottagono largo il giusto lascia passare benissimo. La domanda che non
## faceva nessuno non è «quanto è largo il passaggio» ma «dove finisce il muro,
## rispetto a dove finisce il pavimento che si vede».
##
## TRE DOMANDE:
##   1. IL PROFILO INTERNO. Si mette la capsula sulla mezzeria dell'anello e la si
##      spinge DENTRO, a ogni mezzo grado. Il raggio a cui si ferma è il muro che
##      il giocatore sente: se ondeggia, il pieno è un poligono, e camminandoci lo
##      si sente.
##   2. LO SCARTO DAL VISIBILE. Allo stesso mezzo grado si cerca dove finisce il
##      PAVIMENTO, tastando con un raggio la CORAZZA — la copia della geometria
##      che si vede (`world/corazza.gd`). La differenza fra i due è quanto muro
##      invisibile c'è, ed è il numero che dice se ci si ferma sul bordo o in
##      mezzo al niente.
##   3. IL GIRO. Si cammina davvero, appoggiati al bordo interno, tutto l'anello.
##      Dove l'avanzamento crolla, lì ci si incastra.
##
## IL DIFETTO SI RIMETTE: `OTTAGONO=1` spegne il cilindro e rimonta in memoria le
## due scatole di prima. Senza quel confronto un referto che dice «si cammina» non
## distingue il merito della cura dal fatto che nessuno abbia provato a camminarci.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_montatura.tscn
##     OTTAGONO=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_montatura.tscn
##     TRACCIA=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_montatura.tscn
extends Node

## Il centro della cupola in pianta e le quote della passerella: gli stessi numeri
## di `tools/geometria.py`. Qui non si genera niente, si misura.
const CX := 2.6
const CZ := 2.5
const R_PASS := 1.4
const W_PASS := 1.05
const CALPESTIO := 0.59

## Dove finisce il pavimento che si vede: il bordo interno dell'impalcato.
const BORDO_VISTO := R_PASS - W_PASS / 2.0

## Il raggio della capsula del giocatore, da `world/player/player.tscn`.
const RAGGIO_CAPSULA := 0.3

## Quanto muro invisibile si tollera fra dove ci si ferma e dove finisce il
## pavimento, in metri. Tre centimetri sono il margine di sicurezza della fisica
## più la tastatura; un quarto di metro è il difetto.
const SCARTO_MAX := 0.03

## Quanto può ondeggiare il raggio del muro prima che si senta camminandoci.
const ONDA_MAX := 0.005

## Ogni quanti gradi si tasta.
const PASSO_GRADI := 0.5

## Quanto si spinge DENTRO la direzione di marcia, in gradi: appoggiati al bordo,
## non paralleli. È il gesto che si incastra.
const APPOGGIO_GRADI := 30.0

## Quanto può scendere l'avanzamento di un singolo passo, rispetto a quello che si
## avrebbe camminando liberi, prima che si chiami incastro.
const CROLLO := 0.45

var _spazio: PhysicsDirectSpaceState3D
var _guasti := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[montatura] GUASTO: " + msg)


func _angolo(p: Vector3) -> float:
	return atan2(p.z - CZ, p.x - CX)


func _raggio(p: Vector3) -> float:
	return Vector2(p.x - CX, p.z - CZ).length()


## La capsula del giocatore in piedi. Da `world/player/player.tscn`.
func _capsula() -> CapsuleShape3D:
	var forma := CapsuleShape3D.new()
	forma.radius = RAGGIO_CAPSULA
	forma.height = 1.8
	return forma


## Fin dove entra la capsula spinta verso il centro, e contro cosa si ferma. Si
## parte dalla mezzeria dell'anello, mezzo corpo sopra il calpestio: appoggiata al
## pavimento toccherebbe sempre l'impalcato, e l'impalcato non è la domanda.
func _tasta(ang: float) -> Array:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _capsula()
	q.collision_mask = 1
	q.margin = 0.0
	var dir := Vector3(cos(ang), 0.0, sin(ang))
	var da := Vector3(CX, CALPESTIO + 0.92, CZ) + dir * R_PASS
	q.transform = Transform3D(Basis.IDENTITY, da)
	q.motion = -dir * 1.0
	var f := _spazio.cast_motion(q)
	var r: float = R_PASS - float(f[0]) * 1.0
	q.transform = Transform3D(Basis.IDENTITY, da - dir * (float(f[1]) * 1.0 + 0.005))
	var nome := "il vuoto"
	for c in _spazio.intersect_shape(q, 4):
		var n := c["collider"] as Node
		if n != null:
			nome = n.name
			break
	return [r, nome]


## DOVE FINISCE IL PAVIMENTO CHE SI VEDE. Non si legge da `geometria.py`: si tasta
## la CORAZZA, cioè la geometria visibile data al motore com'è
## (`world/corazza.gd`). Un raggio verso il basso trova l'impalcato finché
## l'impalcato c'è; per bisezione si trova il raggio in cui smette.
## IL FONDO DELLA PASSERELLA VA ESCLUSO, e trovarlo è costato una misura
## sbagliata. `FondoPasserella` è il tappo invisibile che impedisce alla roba
## caduta di finire sotto l'impalcato (vedi `gen_blockout.py`): non è geometria
## che si vede, ma sta sullo STESSO layer della corazza e la sua faccia superiore
## è proprio a filo del calpestio. Senza escluderlo il raggio trova pavimento
## dappertutto, e questa sonda risponde che il bordo del pavimento non esiste.
var _da_ignorare: Array[RID] = []


func _c_e_pavimento(ang: float, r: float) -> bool:
	var p := Vector3(CX + r * cos(ang), CALPESTIO + 0.30, CZ + r * sin(ang))
	var q := PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * 0.60)
	q.collision_mask = Corazza.LAYER_APPOGGI
	q.exclude = _da_ignorare
	var h := _spazio.intersect_ray(q)
	return not h.is_empty() and (h["position"] as Vector3).y > CALPESTIO - 0.05


func _bordo(ang: float) -> float:
	var dentro := BORDO_VISTO - 0.30     # qui sotto non c'è più niente
	var fuori := R_PASS                  # qui sotto c'è di sicuro
	if not _c_e_pavimento(ang, fuori):
		return NAN
	for _i in 14:
		var m := (dentro + fuori) / 2.0
		if _c_e_pavimento(ang, m):
			fuori = m
		else:
			dentro = m
	return fuori


## IL DIFETTO SI RIMETTE. Si spegne il cilindro e si rimontano le due scatole
## dell'ottagono: 1,24 x 2,60 x 1,24, una dritta e una a 45 gradi, come le
## scriveva `geometria.py`.
func _rimetti_ottagono(radice: Node) -> void:
	for n in radice.find_children("PienoCentrale", "StaticBody3D", true, false):
		(n as StaticBody3D).collision_layer = 0
	var lato := BORDO_VISTO * sqrt(2.0)
	for g in [0.0, PI / 4.0]:
		var c := StaticBody3D.new()
		c.name = "OttagonoDiPrima%d" % int(g * 100.0)
		var f := CollisionShape3D.new()
		var s := BoxShape3D.new()
		s.size = Vector3(lato, 2.60, lato)
		f.shape = s
		c.add_child(f)
		radice.add_child(c)
		c.global_transform = Transform3D(Basis(Vector3.UP, g), Vector3(CX, 1.30, CZ))


func _prova() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 20:
		await get_tree().physics_frame
	var player := Player.find_in(get_tree())
	if player == null:
		print("[montatura] il giocatore non c'è: la prova non vale")
		get_tree().quit(1)
		return
	if Corazza.find_in(get_tree()) == null:
		print("[montatura] la corazza non c'è: non si può chiedere dove si vede il pavimento")
		get_tree().quit(1)
		return
	_spazio = player.get_world_3d().direct_space_state
	for n in scena.find_children("FondoPasserella", "StaticBody3D", true, false):
		_da_ignorare.append((n as StaticBody3D).get_rid())
	if _da_ignorare.is_empty():
		_guasto("il fondo della passerella non c'è più: o è stato tolto, o ha "
			+ "cambiato nome, e questa sonda misurerebbe il pavimento sbagliato")
	if OS.get_environment("OTTAGONO") == "1":
		_rimetti_ottagono(scena)
		await get_tree().physics_frame
		print("[montatura] DIFETTO RIMESSO: al posto del cilindro le due scatole dell'ottagono")

	_profilo()
	await _oculare(player)
	await _giro(player)
	print("[montatura] %d guasti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)


## Il muro che si tocca dalla parte del centro, e quanto dista dal bordo del
## pavimento che si vede. È la stessa misura presa due volte: una con la capsula
## sugli ingombri, una con un raggio sulla corazza.
func _profilo() -> void:
	var passi := int(360.0 / PASSO_GRADI)
	var mn := INF
	var mx := -INF
	var scarto_mx := -INF
	var dove_mx := 0.0
	var senza_bordo := 0
	var contro := {}
	var traccia := OS.get_environment("TRACCIA") == "1"
	for i in passi:
		var ang := TAU * i / passi
		var f := _tasta(ang)
		var r: float = f[0]
		mn = minf(mn, r)
		mx = maxf(mx, r)
		contro[f[1]] = int(contro.get(f[1], 0)) + 1
		var b := _bordo(ang)
		if is_nan(b):
			senza_bordo += 1
			continue
		# dove ci si ferma col guscio della capsula, meno dove finisce il pavimento
		var s := b - (r - RAGGIO_CAPSULA)
		if s > scarto_mx:
			scarto_mx = s
			dove_mx = 360.0 * i / passi
		if traccia and i % 20 == 0:
			print("[montatura/traccia] %5.1f gradi: muro %.4f, bordo visto %.4f, scarto %+.1f mm, contro %s"
				% [360.0 * i / passi, r, b, s * 1000.0, f[1]])
	print("[montatura] muro interno: raggio da %.4f a %.4f (atteso %.4f), ONDA %.1f mm, %d pezzi distinti"
		% [mn, mx, BORDO_VISTO + RAGGIO_CAPSULA, (mx - mn) * 1000.0, contro.size()])
	print("[montatura] scarto dal pavimento che si vede: al massimo %.1f mm, a %.0f gradi"
		% [scarto_mx * 1000.0, dove_mx])
	if senza_bordo > 0:
		_guasto("in %d punti su %d sotto la mezzeria dell'anello non c'è pavimento visibile"
			% [senza_bordo, passi])
	if mx - mn > ONDA_MAX:
		_guasto("il muro interno ondeggia di %.0f mm fra %.3f e %.3f: il pieno centrale è un poligono"
			% [(mx - mn) * 1000.0, mn, mx])
	if scarto_mx > SCARTO_MAX:
		_guasto("ci si ferma fino a %.0f cm prima che finisca il pavimento (a %.0f gradi): "
			% [scarto_mx * 100.0, dove_mx] + "è muro invisibile")


## E DA LÌ SI ARRIVA ANCORA ALL'OCULARE. È la domanda che il cilindro poteva
## rovinare: sui mezzi lati dell'ottagono ci si avvicinava venti centimetri di
## più, e la portata dell'interazione è di 1,20 m contati dall'occhio. Un muro
## fatto meglio che allontana il giocatore dalla cosa per cui esiste la stanza
## sarebbe una cura peggiore del male.
##
## SI PARTE DAL PEZZO, non da un punto scritto a mano: si chiede dov'è l'oculare,
## si va sull'anello nella sua stessa direzione, ci si mette al raggio più dentro
## in cui la capsula ci sta davvero — quello misurato qui sopra — e si guarda se
## il gioco lo mette a fuoco. `prova_oculare.gd` fa un'altra domanda: teletrasporta
## il giocatore addosso al pezzo, anche dentro un muro, e prova il MECCANISMO.
func _oculare(player: Player) -> void:
	var oc := Oculare.find_in(get_tree())
	var ccd := CcdCamera.find_in(get_tree())
	if oc == null or ccd == null:
		_guasto("manca un pezzo (oculare=%s ccd=%s): non si può chiedere se ci si arriva"
			% [oc != null, ccd != null])
		return
	# AL FUOCO CI STA UNA COSA SOLA, e a partita nuova c'è la camera CCD: con
	# quella avvitata l'oculare non si usa, e chiedere se ci si arriva non
	# avrebbe senso. Si smonta come la smonta chi gioca (vedi
	# `prova_oculare.gd`, che di questo scambio fa la sua prima domanda).
	ccd.prendi(player)
	ccd.lascia()
	for _i in 30:
		await get_tree().physics_frame
	var b := oc.global_position
	var ang := _angolo(b)
	var r: float = _tasta(ang)[0]
	var dove := Vector3(CX + r * cos(ang), CALPESTIO, CZ + r * sin(ang))
	player.velocity = Vector3.ZERO
	player.global_position = dove
	player.look_at(Vector3(b.x, dove.y, b.z), Vector3.UP)
	var cam := player.camera()
	if cam != null:
		cam.look_at(b, Vector3.UP)
	for _i in 4:
		await get_tree().physics_frame
	var occhio := cam.global_position if cam != null else player.global_position
	var messo: Node = player.focus()
	var nome_messo := "niente"
	if messo != null:
		nome_messo = messo.name
	print("[montatura] oculare: sta a %.3f dal centro e a y %.2f; fermi a %.3f dal centro, "
		% [_raggio(b), b.y, r]
		+ "%.2f m dall'occhio (la portata è %.2f), a fuoco «%s»"
		% [occhio.distance_to(b), Player.INTERACT_RANGE, nome_messo])
	if player.focus() != oc:
		_guasto("dall'anello non si arriva più all'oculare: fermi a %.3f dal centro, "
			% r + "l'oculare è a %.2f m e la portata è %.2f"
			% [occhio.distance_to(b), Player.INTERACT_RANGE])


## Un giro dell'anello appoggiati al bordo interno. L'avanzamento di ogni passo si
## confronta con quello di chi cammina libero: è il numero che dice se ci si
## incastra, e dove. Qui il giro è intero — dalla parte di dentro il varco della
## scala non c'è.
func _giro(player: Player) -> void:
	var arco := TAU
	player.velocity = Vector3.ZERO
	player.global_position = Vector3(CX + R_PASS, CALPESTIO + 0.02, CZ)
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
	while girato < arco and passi < 2400:
		var t := _angolo(player.global_position) + PI / 2.0 + deg_to_rad(APPOGGIO_GRADI)
		player.rotation.y = atan2(-cos(t), -sin(t))
		await get_tree().physics_frame
		passi += 1
		var nuovo := _angolo(player.global_position)
		var d := wrapf(nuovo - ang, -PI, PI)
		ang = nuovo
		girato += d
		var r := _raggio(player.global_position)
		var atteso := libera * dt / maxf(r, 0.1)
		if traccia and player.velocity.length() < 0.001:
			var det := ""
			for c in player.get_slide_collision_count():
				var u := player.get_slide_collision(c)
				det += "  [%s n=%s prof=%.4f]" % [
					(u.get_collider() as Node).name, u.get_normal(), u.get_depth()]
			print("[montatura/traccia] passo %d, ang %.2f, r %.4f: velocità azzerata%s"
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

	# I PASSI CHE BASTEREBBERO: l'arco percorso AL RAGGIO DEL MURO, non a quello
	# della mezzeria. Appoggiati al bordo interno si cammina venti centimetri più
	# in dentro, e il giro è più corto.
	var liberi := int(arco * (BORDO_VISTO + RAGGIO_CAPSULA) / (libera * dt))
	print("[montatura] giro interno: %.0f gradi su %.0f in %d passi (camminando liberi ne servirebbero %d)"
		% [rad_to_deg(girato), rad_to_deg(arco), passi, liberi])
	if girato < arco:
		_guasto("il giro non si chiude: fermo a %.0f gradi dopo %d passi"
			% [rad_to_deg(ang), passi])
	if incastri.is_empty():
		print("[montatura] nessun passo sotto il %.0f%% dell'avanzamento libero" % (CROLLO * 100.0))
	else:
		_guasto("ci si impunta in %d punti del giro (%s); il peggiore a %.0f gradi, "
			% [incastri.size(), incastri.keys(), peggiore[1]]
			+ "avanzato il %.0f%% di quanto doveva, raggio %.3f, contro %s"
			% [peggiore[0] * 100.0, peggiore[3], peggiore[2]])
