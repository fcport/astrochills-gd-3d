## L'OCCHIO NEL CIELO GUARDA DAVVERO TE?
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_occhio.tscn
##
## Come `tools/prova_tentacolo.gd`, questa sonda non dice se la cosa è bella — per
## quello c'è `tools/scatta_occhio.gd`. Dice se sono a posto le cose che possono
## essere sbagliate in silenzio, cioè quelle che a occhio si vedono solo quando
## sono sbagliate di molto:
##
##   1. IL TASTO. `F6` apre un occhio nel mondo, lo stesso tasto lo chiude, e alla
##      fine il nodo se ne va. Tre punti che si rompono senza dirlo: `main.gd` che non
##      installa lo strumento, l'evento che non arriva, il nodo che resta in scena
##      invisibile dopo essersi chiuso.
##   2. STA DOVE DEVE. A `DISTANZA` dalla porta, a cinquanta gradi d'altezza, e tutto
##      dentro il `far` della camera: la pelle va indietro di trecento metri e passa
##      i tremila, e una testa oltre il piano di taglio si vedrebbe mozzata da un
##      cerchio. È il vincolo che ha deciso la distanza quando l'occhio è cresciuto.
##   3. COMPARE SUBITO. Al secondo secondo il bulbo deve essere già mezzo disco: è la
##      lezione del tentacolo, che per venti secondi non si vedeva e veniva ritirato
##      da chi ripremeva il tasto.
##   4. LA PUPILLA RESTA ORIZZONTALE, sempre — mentre cerca, mentre insegue, con la
##      testa inclinata. La testa DEVE essere inclinata, o la prova non prova niente.
##   5. CERCA, POI TROVA. Nei primi secondi aperto lo sguardo si sposta davvero, e
##      non esce mai dai trenta gradi; dopo, punta la camera entro mezzo grado, e se
##      la camera si sposta la ritrova.
##   6. LE PALPEBRE CHIUDONO E NON TAGLIANO LA PUPILLA. Chiuse, quella di sopra copre
##      quella di sotto da un capo all'altro; aperte, la pupilla più larga che ci sia
##      sta dentro l'apertura quando guarda dritto.
##
## IL TEMPO SI MUOVE A MANO: `Occhio.passo()` esiste per questo.
extends Node

const PASSO := 1.0 / 60.0

## Come in `debug/occhio.gd` — ricopiati apposta: se là cambiano, qui si fallisce e
## non si misura in silenzio un altro posto.
const DA := Vector3(10.6, 1.7, 10.6)
const AZIMUT := 30.0
const ALTEZZA := 50.0

## Quanta aria deve restare fra la testa e il piano di taglio della camera.
const MARGINE_FAR := 0.9

## Il bulbo, nel punto più basso, deve stare almeno così in alto sull'orizzonte.
const BULBO_ALMENO := 12.0

## Quanto deve essersi spostato lo sguardo mentre cerca, perché si dica che cerca.
const CERCA_ALMENO := 0.15

## Entro quanto deve puntare la camera, e in quanti secondi deve ritrovarla.
const MIRA := 0.0087
const RITROVA_IN := 3.0

## Di quanto la pupilla deve stare dentro l'apertura, in radianti.
const DENTRO_ALMENO := 0.02

var _guasti := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[occhio] GUASTO: " + msg)


func _premi(tasto: Key) -> void:
	var giu := InputEventKey.new()
	giu.keycode = tasto
	giu.pressed = true
	Input.parse_input_event(giu)
	Input.flush_buffered_events()
	var su := InputEventKey.new()
	su.keycode = tasto
	su.pressed = false
	Input.parse_input_event(su)
	Input.flush_buffered_events()


func _occhio_in(n: Node) -> Occhio:
	if n == null:
		return null
	for f in n.get_children():
		if f is Occhio:
			return f as Occhio
	return null


func _prova() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 6:
		await get_tree().physics_frame
	var mondo := scena.get_node_or_null("%SubViewport")

	var g := Player.find_in(get_tree())
	if g == null or mondo == null:
		_guasto("niente giocatore o niente mondo: non c'è chi guarda")
		get_tree().quit(1)
		return
	g.set_physics_process(false)
	g.set_process(false)
	g.global_position = DA - Vector3.UP * 1.65
	var cam := g.camera()

	# --- 1. il tasto --------------------------------------------------------------
	if scena.get_node_or_null("Occhio") == null:
		_guasto("main.gd non installa debug/occhio.gd: F6 non risponde")
	_premi(KEY_F6)
	for _f in 3:
		await get_tree().process_frame
	var dal_tasto := _occhio_in(mondo)
	if dal_tasto == null:
		_guasto("premuto F6, nel mondo non è comparso nessun occhio")
	else:
		print("[occhio] F6: si apre «%s», fase %s" % [dal_tasto.name, dal_tasto.fase()])
		_premi(KEY_F6)
		await get_tree().process_frame
		if dal_tasto.fase() != "SVANISCE" and dal_tasto.fase() != "SI_CHIUDE":
			_guasto("ripremuto F6, l'occhio è in %s invece di chiudersi" % dal_tasto.fase())
		dal_tasto.set_process(false)
		var passi := 0
		while dal_tasto.fase() != "NIENTE" and passi < 2000:
			dal_tasto.passo(0.1)
			passi += 1
		for _f in 3:
			await get_tree().process_frame
		if is_instance_valid(dal_tasto):
			_guasto("chiuso e svanito, il nodo è ancora in scena")
		else:
			print("[occhio] F6 di nuovo: si chiude, svanisce e il nodo se ne va")

	# --- 2. dove sta --------------------------------------------------------------
	var o := (load("res://world/occhio.tscn") as PackedScene).instantiate() as Occhio
	mondo.add_child(o)
	o.set_process(false)
	o.colloca(DA, AZIMUT, ALTEZZA)
	var verso := o.global_position - DA
	var altezza := rad_to_deg(asin(verso.normalized().y))
	var azimut := rad_to_deg(atan2(verso.x, verso.z))
	print("[occhio] centro a %.0f m, %.1f° d'altezza, %.1f° d'azimut" % [
		verso.length(), altezza, azimut])
	if absf(verso.length() - Occhio.DISTANZA) > 1.0 or absf(altezza - ALTEZZA) > 0.1 \
			or absf(azimut - AZIMUT) > 0.1:
		_guasto("non sta dove `colloca()` dice")
	var basso := (verso - Vector3.UP * Occhio.RAGGIO).normalized()
	var bulbo_basso := rad_to_deg(asin(basso.y))
	if bulbo_basso < BULBO_ALMENO:
		_guasto("il bulbo scende a %.1f° sull'orizzonte" % bulbo_basso)
	var lontano := _punto_piu_lontano(o, DA)
	print("[occhio] punto più lontano della testa a %.0f m, far della camera %.0f m" % [
		lontano, cam.far])
	if lontano > cam.far * MARGINE_FAR:
		_guasto("la testa arriva a %.0f m, oltre il %d%% del far (%.0f)" % [
			lontano, int(MARGINE_FAR * 100.0), cam.far])
	var rollio := o.testa().global_basis.orthonormalized().x.y
	if absf(rollio) < 0.1:
		_guasto("la testa non è inclinata (%.3f): la pupilla orizzontale non si prova" % rollio)

	# --- 3. compare subito ----------------------------------------------------------
	o.apri()
	var t := 0.0
	while t < 2.0:
		o.passo(PASSO)
		t += PASSO
	print("[occhio] dopo 2 s: bulbo presente al %d%%" % int(o.presenza_bulbo() * 100.0))
	if o.presenza_bulbo() < 0.5:
		_guasto("dopo due secondi il bulbo è al %d%%: sembra che il tasto non faccia niente" % [
			int(o.presenza_bulbo() * 100.0)])

	# --- 4 e 5. la pupilla, lo sguardo --------------------------------------------
	var storta := 0.0
	var fuori := 0.0
	var primo := Vector3.ZERO
	var girato := 0.0
	var aperto_a := -1.0
	var agganciato_a := -1.0
	while t < 60.0:
		o.passo(PASSO)
		t += PASSO
		storta = maxf(storta, absf(o.asse_pupilla().y))
		fuori = maxf(fuori, (-o.global_basis.orthonormalized().z).angle_to(o.sguardo()))
		if o.apertura() > 0.0 and aperto_a < 0.0:
			aperto_a = t
			primo = o.sguardo()
		if aperto_a > 0.0 and t - aperto_a < Occhio.CERCA_PER:
			girato = maxf(girato, primo.angle_to(o.sguardo()))
		if aperto_a > 0.0 and t - aperto_a > Occhio.CERCA_PER and agganciato_a < 0.0:
			if o.sguardo().angle_to(_verso_camera(o, cam)) < MIRA:
				agganciato_a = t
	print("[occhio] pupilla: asse al massimo %.5f fuori dall'orizzontale" % storta)
	if storta > 1e-3:
		_guasto("la pupilla si inclina (%.4f)" % storta)
	print("[occhio] cercando si è girato di %.1f°, mai oltre %.1f° dalla testa" % [
		rad_to_deg(girato), rad_to_deg(fuori)])
	if girato < CERCA_ALMENO:
		_guasto("nei primi %.0f s aperto lo sguardo non si sposta: non cerca" % Occhio.CERCA_PER)
	if fuori > Occhio.SGUARDO_MASSIMO + 0.01:
		_guasto("lo sguardo esce di %.1f° dalla testa" % rad_to_deg(fuori))
	if agganciato_a < 0.0:
		_guasto("non aggancia mai la camera (errore %.2f°)" % rad_to_deg(
				o.sguardo().angle_to(_verso_camera(o, cam))))
	else:
		print("[occhio] aggancia la camera %.1f s dopo che ha smesso di cercare" % [
			agganciato_a - aperto_a - Occhio.CERCA_PER])

	# LA CAMERA SI SPOSTA DI TRECENTOCINQUANTA METRI: la ritrova? Tanti, e non è una
	# passeggiata possibile: a duemilaseicento metri, trenta passi sul prato girano la
	# direzione di mezzo grado, che sta dentro la tolleranza e si «ritrova» senza
	# muovere niente. Trecentocinquanta sono otto gradi, cioè un colpo del bulbo e poi
	# l'inseguimento: le due metà del filtro.
	g.global_position += Vector3(350.0, 0.0, 0.0)
	var ritrovata := -1.0
	var dopo := 0.0
	while dopo < RITROVA_IN + 2.0:
		o.passo(PASSO)
		dopo += PASSO
		if ritrovata < 0.0 and o.sguardo().angle_to(_verso_camera(o, cam)) < MIRA:
			ritrovata = dopo
	if ritrovata < 0.0 or ritrovata > RITROVA_IN:
		_guasto("spostata la camera, lo sguardo non la ritrova in %.0f s" % RITROVA_IN)
	else:
		print("[occhio] spostata la camera di 350 m, ritrovata in %.2f s" % ritrovata)
	g.global_position = DA - Vector3.UP * 1.65

	# --- 6. le palpebre -----------------------------------------------------------
	var coperto := INF
	var b := -Occhio.LATO_PALPEBRA
	while b <= Occhio.LATO_PALPEBRA:
		coperto = minf(coperto, o.margine(false, b, 0.0) - o.margine(true, b, 0.0))
		b += 0.01
	print("[occhio] chiuse, la palpebra di sopra copre quella di sotto di almeno %.1f°" % [
		rad_to_deg(coperto)])
	if coperto <= 0.0:
		_guasto("chiuse, fra le palpebre resta uno spiraglio")
	var dentro := _pupilla_dentro(o)
	print("[occhio] aperto e dilatato, la pupilla sta %.1f° dentro le palpebre" % rad_to_deg(dentro))
	if dentro < DENTRO_ALMENO:
		_guasto("guardando dritto le palpebre tagliano la pupilla (%.2f°)" % rad_to_deg(dentro))

	# --- e se ne va --------------------------------------------------------------
	var svanito := [false]
	o.svanito.connect(func() -> void: svanito[0] = true)
	o.chiudi()
	var fine := 0.0
	while not svanito[0] and fine < 30.0:
		o.passo(PASSO)
		fine += PASSO
	if not svanito[0] or o.presenza() > 0.0:
		_guasto("chiuso, non svanisce")
	else:
		print("[occhio] chiuso e svanito in %.1f s" % fine)
	o.queue_free()

	print("[occhio] %s" % ("TUTTO A POSTO" if _guasti == 0 else "%d GUASTI" % _guasti))
	get_tree().quit(1 if _guasti > 0 else 0)


func _verso_camera(o: Occhio, cam: Camera3D) -> Vector3:
	return (cam.global_position - o.global_position).normalized()


func _punto_piu_lontano(o: Occhio, da: Vector3) -> float:
	var pelle := o.testa().get_node("Pelle") as MeshInstance3D
	var arrays := pelle.mesh.surface_get_arrays(0)
	var punti: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var xf := pelle.global_transform
	var massimo := 0.0
	for p in punti:
		massimo = maxf(massimo, (xf * p).distance_to(da))
	return massimo


## La pupilla più larga che ci sia, col bulbo che guarda dritto davanti alla testa:
## di quanto il suo contorno sta dentro le due palpebre, al punto più stretto. Il
## contorno si campiona in coordinate del bulbo, si porta nel mondo e poi nella testa,
## dove i margini sono definiti.
func _pupilla_dentro(o: Occhio) -> float:
	var avanti := -o.global_basis.orthonormalized().z
	var bulbo := Basis.looking_at(avanti, Vector3.UP)
	var testa := o.testa().global_basis.orthonormalized().inverse()
	var w := Occhio.PUPILLA_LARGA.x
	var h := Occhio.PUPILLA_LARGA.y
	var minimo := INF
	for k in 128:
		var a := TAU * k / 128.0
		var c := cos(a)
		var s := sin(a)
		# la superellisse di esponente tre dello shader, in coordinate polari
		var r := 1.0 / pow(pow(absf(c) / w, 3.0) + pow(absf(s) / h, 3.0), 1.0 / 3.0)
		var x := r * c
		var y := r * s
		var locale := Vector3(x, y, -sqrt(maxf(1.0 - x * x - y * y, 0.0)))
		var d := (testa * (bulbo * locale)).normalized()
		var beta := asin(clampf(d.x, -1.0, 1.0))
		var alfa := atan2(d.y, -d.z)
		minimo = minf(minimo, o.margine(true, beta, 1.0) - alfa)
		minimo = minf(minimo, alfa - o.margine(false, beta, 1.0))
	return minimo
