## GLI ORRORI ARRIVANO, FANNO QUELLO CHE DEVONO, E SE NE VANNO?
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_orrori.tscn
##
## Per ognuno degli otto tasti `Ctrl+F1`…`Ctrl+F8` (`debug/orrori.gd`) la sonda preme il
## tasto per davvero, guarda che l'orrore sia entrato nel mondo e che nessun altro
## strumento abbia risposto allo stesso tasto — `Ctrl+F1` non deve rimettere il tempo a
## velocità reale, `Ctrl+F5` non deve calare il tentacolo — poi fa passare il tempo a mano,
## misura la cosa che può essere sbagliata in silenzio, ripreme il tasto e aspetta che se
## ne vada e che il nodo sia liberato.
##
## Non dice se sono belli: per quello c'è `tools/scatta_orrori.gd`. Le misure, una per
## orrore:
##   F1 LE NUBI stanno sulla camera e si accendono e si spengono del tutto.
##   F2 L'INCHIOSTRO esce grumo e diventa nube: piccolo al terzo secondo, largo al trentesimo.
##   F3 LE VENTOSE passano alte DAVANTI a chi le ha chiamate, non allo zenit né dietro.
##   F4 LE BRACCIA escono da sotto il terreno vero, dove da chi le chiama l'orizzonte è
##      basso, salgono con la spalla sotto terra e il palmo verso chi guarda, stanno dentro
##      la cupola degli altri orrori, ogni mano fa gesti suoi coi tempi di una mano grande,
##      e la mano si apre a ventaglio e si chiude con le dita sul palmo.
##   F5 L'OCCHIO NELL'OCULARE lo vede la camera dell'oculare e non quella del giocatore, sta
##      davanti alla bocca del tubo, guarda altrove e poi scatta su chi guarda, la pupilla è
##      orizzontale nell'inquadratura e si stringe.
##   F6 L'OCCHIO NELLA POSA sta nella foto sopra il soggetto e non sulla carta, lascia davanti
##      le stelle, viene uguale ogni volta, la stampa esce e se lo ricorda, e la prossima
##      foto rivelata consuma l'infestazione una volta sola.
##   F7 LA MONTATURA punta chi le sta accanto e lo segue quando si sposta, non per un passo;
##      il conto da verso a coordinate orarie si prova piazzando la montatura vera, anche
##      sotto l'orizzonte.
##   F8 IL COLORE: la pietra arriva alta davanti e scende senza salti accendendo il paesaggio,
##      resta nel cratere che ha fatto, il colore si allarga a macchie e non a cerchio fino a prendersi il
##      prato, illumina attorno con bagliore e foschia, se ne va in una colonna che arriva al
##      cielo, lascia la cenere — nell'erba e per terra — e alla fine restituisce il prato e
##      l'ambiente com'erano.
extends Node

const PASSO := 1.0 / 30.0
## Da dove si guarda: fuori dalla porta, verso nord.
const DA := Vector3(10.6, 0.0, 10.6)

var _guasti := 0
var _mondo: Node
var _orrori: Node
var _camera: Camera3D


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[orrori] GUASTO: " + msg)


func _premi(tasto: Key) -> void:
	for giu in [true, false]:
		var e := InputEventKey.new()
		e.keycode = tasto
		e.ctrl_pressed = true
		e.pressed = giu
		Input.parse_input_event(e)
		Input.flush_buffered_events()


func _prova() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 8:
		await get_tree().physics_frame
	_mondo = scena.get_node_or_null("%SubViewport")
	_orrori = scena.get_node_or_null("Orrori")
	if _orrori == null:
		_guasto("main.gd non installa debug/orrori.gd")
		get_tree().quit(1)
		return
	var g := Player.find_in(get_tree())
	g.set_physics_process(false)
	g.set_process(false)
	g.global_position = DA
	g.rotation = Vector3(0.0, PI, 0.0)
	_camera = g.camera()
	await get_tree().process_frame

	await _nubi()
	await _inchiostro()
	await _ventose()
	await _braccia()
	await _oculare()
	await _posa()
	await _montatura()
	await _colore()

	print("[orrori] %s" % ("TUTTO A POSTO" if _guasti == 0 else "%d GUASTI" % _guasti))
	get_tree().quit(1 if _guasti > 0 else 0)


## Preme il tasto e restituisce l'orrore entrato, col tempo fermo.
func _arriva(tasto: Key, nome: String) -> Orrore:
	var tempo_prima := Engine.time_scale
	_premi(tasto)
	for _f in 2:
		await get_tree().process_frame
	var o: Orrore = _orrori.aperto(tasto)
	if o == null:
		_guasto("%s: premuto Ctrl+F%d, non è arrivato niente" % [nome, tasto - KEY_F1 + 1])
		return null
	if o.get_parent() != _mondo:
		_guasto("%s: non sta nel mondo" % nome)
	o.set_process(false)
	if Engine.time_scale != tempo_prima:
		_guasto("%s: Ctrl+F%d ha cambiato anche il tempo" % [nome, tasto - KEY_F1 + 1])
	for n in _mondo.get_children():
		if n is Tentacolo or (n is Occhio and not (n.get_parent() is Orrore)):
			_guasto("%s: il tasto ha risposto anche a tentacolo o occhio" % nome)
			n.free()
	return o


## Ripreme il tasto e fa passare il tempo finché se ne va; poi controlla che il nodo sia
## liberato. `anche` sono altri nodi da far avanzare insieme.
func _se_ne_va(tasto: Key, o: Orrore, nome: String, al_massimo: float,
		anche: Callable = Callable()) -> void:
	_premi(tasto)
	await get_tree().process_frame
	# c'è chi se ne va SUBITO, nel tasto stesso — la posa, l'oculare non guardato — e al
	# fotogramma dopo il nodo è già liberato
	if not is_instance_valid(o):
		print("[orrori] %s: se ne va subito, nodo liberato" % nome)
		return
	if not o.in_uscita() and o.attivo():
		_guasto("%s: ripremuto il tasto, non se ne va" % nome)
	var t := 0.0
	while o.attivo() and t < al_massimo:
		o.passo(PASSO)
		if anche.is_valid():
			anche.call(PASSO)
		t += PASSO
	if o.attivo():
		_guasto("%s: dopo %.0f s è ancora lì" % [nome, al_massimo])
		return
	for _f in 3:
		await get_tree().process_frame
	if is_instance_valid(o):
		_guasto("%s: se n'è andato, ma il nodo è ancora in scena" % nome)
	else:
		print("[orrori] %s: se ne va in %.1f s, nodo liberato" % [nome, t])


func _avanti(o: Orrore, secondi: float, anche: Callable = Callable()) -> void:
	var t := 0.0
	while t < secondi:
		o.passo(PASSO)
		if anche.is_valid():
			anche.call(PASSO)
		t += PASSO


# --- F1 ------------------------------------------------------------------------------

func _nubi() -> void:
	var o := (await _arriva(KEY_F1, "nubi")) as OrroreNubi
	if o == null:
		return
	_avanti(o, OrroreNubi.ENTRA + 1.0)
	if o.global_position.distance_to(_camera.global_position) > 0.01:
		_guasto("nubi: la cupola non sta sulla camera")
	if o.get_node_or_null("Nubi") == null:
		_guasto("nubi: nessuna cupola")
	print("[orrori] nubi: accese al %d%%" % int(o.forza() * 100.0))
	if o.forza() < 1.0:
		_guasto("nubi: dopo %.0f s non sono accese del tutto" % (OrroreNubi.ENTRA + 1.0))
	await _se_ne_va(KEY_F1, o, "nubi", OrroreNubi.ESCE + 2.0)


# --- F2 ------------------------------------------------------------------------------

func _inchiostro() -> void:
	var o := (await _arriva(KEY_F2, "inchiostro")) as OrroreInchiostro
	if o == null:
		return
	_avanti(o, 3.0)
	var grumo := o.raggio()
	_avanti(o, 27.0)
	var nube := o.raggio()
	print("[orrori] inchiostro: raggio %.1f° al terzo secondo, %.1f° al trentesimo" % [
		rad_to_deg(grumo), rad_to_deg(nube)])
	if absf(grumo - OrroreInchiostro.GRUMO) > 0.01:
		_guasto("inchiostro: al terzo secondo non è il grumo (%.3f)" % grumo)
	if nube < 0.5:
		_guasto("inchiostro: al trentesimo secondo non si è allargato (%.3f)" % nube)
	await _se_ne_va(KEY_F2, o, "inchiostro", OrroreInchiostro.VIA + 2.0)


# --- F3 ------------------------------------------------------------------------------

func _ventose() -> void:
	var o := (await _arriva(KEY_F3, "ventose")) as OrroreVentose
	if o == null:
		return
	var mat := (o.get_node("Ventose") as MeshInstance3D).material_override as ShaderMaterial
	var inizio: Vector3 = mat.get_shader_parameter("inizio")
	var asse: Vector3 = mat.get_shader_parameter("asse")
	var piu_alto := Vector3.ZERO
	for k in 181:
		var a := PI * k / 180.0
		var p := inizio * cos(a) + asse.cross(inizio) * sin(a)
		if p.y > piu_alto.y:
			piu_alto = p
	var altezza := rad_to_deg(asin(piu_alto.y))
	var az_camera := Orrore.azimut_di(-_camera.global_basis.z)
	var scarto := wrapf(Orrore.azimut_di(piu_alto) - az_camera, -180.0, 180.0)
	print("[orrori] ventose: il braccio passa a %.0f° d'altezza, %.0f° di lato da chi guarda" % [
		altezza, scarto])
	if altezza < 50.0 or altezza > 70.0 or absf(scarto) > 15.0:
		_guasto("ventose: il percorso non passa alto davanti")
	_avanti(o, 10.0)
	if absf(o.testa() - OrroreVentose.VELOCITA * 10.0) > 0.01:
		_guasto("ventose: la punta non avanza alla sua velocità")
	await _se_ne_va(KEY_F3, o, "ventose", OrroreVentose.LASCIA + 2.0)


# --- F4 ------------------------------------------------------------------------------

func _braccia() -> void:
	var o := (await _arriva(KEY_F4, "braccia")) as OrroreBraccia
	if o == null:
		return
	var bracci := o.bracci()
	if bracci.size() != OrroreBraccia.BRACCI.size():
		_guasto("braccia: %d bracci invece di %d" % [bracci.size(), OrroreBraccia.BRACCI.size()])
		return
	for b in bracci:
		b.set_process(false)
	var tutti := func(dt: float) -> void:
		for b in bracci:
			b.passo(dt)
	var da := _camera.global_position
	var alto := func(p: Vector3) -> float:
		return rad_to_deg(asin((p - da).normalized().y))
	var terreno := Orrore.trova(get_tree().root, "Panorama") as Panorama
	if terreno == null:
		_guasto("braccia: nel mondo non c'è il panorama")
		return
	# quanto un punto sta sopra il terreno che ha sotto: negativo, sotto terra
	var fuori := func(p: Vector3) -> float:
		return p.y - terreno.quota(Vector2(p.x, p.z))
	tutti.call(PASSO)
	var prima := -INF
	for b in bracci:
		for p in b.punte_nel_mondo():
			prima = maxf(prima, fuori.call(p))
	_avanti(o, 11.0 + BraccioUmano.DURATA_SALE + 2.0, tutti)
	var piu_basso := INF
	var piu_lontano := 0.0
	var spalla_piu_alta := -INF
	var polso_piu_basso := INF
	var cerchio := OrroreBraccia.orizzonte(da, terreno, o.get_world_3d().direct_space_state)
	for b in bracci:
		if b.uscito() < 0.99:
			_guasto("braccia: un braccio non è salito del tutto (%.2f)" % b.uscito())
		var cima := -INF
		for p in b.punte_nel_mondo():
			if is_nan(p.x) or is_nan(p.y) or is_nan(p.z):
				_guasto("braccia: una punta non è un numero")
				break
			cima = maxf(cima, alto.call(p))
			piu_lontano = maxf(piu_lontano, p.distance_to(da))
		piu_basso = minf(piu_basso, cima)
		spalla_piu_alta = maxf(spalla_piu_alta, fuori.call(b.spalla_nel_mondo()))
		# QUANTO IL POLSO STA SOPRA L'ORIZZONTE, terreno e alberi, verso quel braccio
		var polso := b.polso_nel_mondo()
		var sopra: float = alto.call(polso) - OrroreBraccia.orizzonte_verso(cerchio, Orrore.azimut_di(polso - da))
		polso_piu_basso = minf(polso_piu_basso, sopra)
		# IL PALMO VERSO CHI GUARDA: una mano di taglio è una lama
		var verso_di_me := (da - b.polso_nel_mondo()).normalized()
		if b.palmo_nel_mondo().dot(verso_di_me) < 0.5:
			_guasto("braccia: %s non mostra il palmo" % b.name)
	var az_sguardo := Orrore.azimut_di(-_camera.global_basis.z)
	var az_braccia := Orrore.azimut_di(bracci[2].global_position - da)
	print("[orrori] braccia: prima di salire le punte stanno %.0f m sotto terra; salite, le cime stanno almeno a %.1f°, la spalla più alta %.0f m sotto terra, il polso più basso %.1f° sopra l'orizzonte, il punto più lontano a %.0f m; escono a %.0f° da dove si guarda" % [
		-prima, piu_basso, -spalla_piu_alta, polso_piu_basso, piu_lontano,
		wrapf(az_braccia - az_sguardo, -180.0, 180.0)])
	if prima > 0.0:
		_guasto("braccia: prima di salire le punte stanno già fuori dal terreno")
	if spalla_piu_alta > 0.0:
		_guasto("braccia: la spalla sta fuori dal terreno")
	# DALLA PORTA VERSO NORD COLLINA E BOSCO coprono il cielo fino a quaranta gradi, e i polsi,
	# a venti, ci restavano dietro: fuori dagli alberi del recinto spuntavano le dita, e
	# sembravano mani di persona dietro la siepe. Tre gradi: la mano intera e l'attacco
	# dell'avambraccio, anche nello spicchio stretto fra la casa e il bosco.
	if polso_piu_basso < 3.0:
		_guasto("braccia: un polso resta dietro il terreno o gli alberi vicini")
	if piu_basso < 8.0:
		_guasto("braccia: una cima resta sotto gli otto gradi")
	if piu_lontano > Orrore.CUPOLA:
		_guasto("braccia: escono dalla cupola degli orrori del cielo")
	# LA MANO SI APRE E SI CHIUDE, e chiudendosi le dita vanno SUL PALMO. È la misura che
	# dice se le ossa si piegano dalla parte giusta: con il verso sbagliato le dita si
	# rovesciano all'indietro, e il pugno misurato sul polso sembrerebbe lo stesso.
	# OGNI MANO FA LA SUA COSA: per un minuto si guarda che gesto fa ognuna e come ha la
	# mano, e due braccia non devono fare la stessa cosa. Si misura sulla prossimale
	# dell'indice e sul polso, che sono quello che cambia fra un gesto e l'altro.
	var gesti_visti := {}
	var tutte_uguali := 0
	var campioni: Array = []
	for _b in bracci:
		campioni.append(PackedFloat32Array())
	for i in int(60.0 / PASSO):
		tutti.call(PASSO)
		if i % 15 != 0:
			continue
		var adesso := {}
		for k in bracci.size():
			var bk := bracci[k]
			gesti_visti[bk.gesto()] = true
			adesso[bk.gesto()] = true
			var pose: PackedFloat32Array = bk.get("_posa_ora")
			campioni[k].append(pose[3 * 3 + 1])
			campioni[k].append(pose[15])
		if adesso.size() == 1:
			tutte_uguali += 1
	var piu_simili := INF
	for a0 in bracci.size():
		for a1 in range(a0 + 1, bracci.size()):
			var diff := 0.0
			for j in campioni[a0].size():
				diff += absf(campioni[a0][j] - campioni[a1][j])
			piu_simili = minf(piu_simili, diff / maxf(campioni[a0].size(), 1))
	print("[orrori] braccia: in un minuto %d gesti diversi, istanti con tutte le mani nello stesso gesto %d; le due mani più simili differiscono in media di %.0f°" % [
		gesti_visti.size(), tutte_uguali, piu_simili])
	if gesti_visti.size() < 5:
		_guasto("braccia: le mani fanno pochi gesti")
	# I TEMPI DI UNA MANO GRANDE: la radice di quante volte è più grande di una vera
	var lente := PackedFloat32Array()
	for bk in bracci:
		lente.append(bk.lentezza())
	print("[orrori] braccia: fanno i gesti da %.0f a %.0f volte più piano di una mano vera" % [
		Array(lente).min(), Array(lente).max()])
	if Array(lente).min() < 20.0:
		_guasto("braccia: le mani gesticolano coi tempi di una persona")
	if tutte_uguali > 0:
		_guasto("braccia: a un certo punto tutte le mani fanno la stessa cosa")
	if piu_simili < 10.0:
		_guasto("braccia: due mani fanno lo stesso movimento")

	# LA MANO SI APRE E SI CHIUDE, e chiudendosi le dita vanno SUL PALMO. È la misura che
	# dice se le ossa si piegano dalla parte giusta: con il verso sbagliato le dita si
	# rovesciano all'indietro, e il pugno misurato sul polso sembrerebbe lo stesso.
	var b0 := bracci[1]
	b0.fai(BraccioUmano.Gesto.STRINGE)
	var aperta := {}
	var chiusa := {}
	var lento := b0.lentezza()
	for i in int(((BraccioUmano.TRANSIZIONE + BraccioUmano.STRINGE_PERIODO_MAX) * lento + 1.0) / PASSO):
		tutti.call(PASSO)
		if i * PASSO < BraccioUmano.TRANSIZIONE * lento:
			continue
		var c := b0.chiusa()
		if c < BraccioUmano.APERTA + 0.01 and aperta.is_empty():
			aperta = _mano(b0)
		if c > BraccioUmano.STRETTA - 0.01 and chiusa.is_empty():
			chiusa = _mano(b0)
	if aperta.is_empty() or chiusa.is_empty():
		_guasto("braccia: in un giro intero la mano non si è aperta e chiusa (aperta %s, chiusa %s)" % [
			not aperta.is_empty(), not chiusa.is_empty()])
	else:
		print("[orrori] braccia: le punte stanno dal polso a %.0f m aperta e %.0f chiusa; ogni dito va verso il palmo col coseno %+.2f aperta e %+.2f chiusa; il ventaglio aperta %.0f° e chiusa %.0f°" % [
			aperta.lontane, chiusa.lontane, aperta.palmo, chiusa.palmo, aperta.ventaglio, chiusa.ventaglio])
		if chiusa.lontane > aperta.lontane * 0.75:
			_guasto("braccia: chiusa, la mano non si stringe")
		if chiusa.palmo < 0.4 or chiusa.palmo < aperta.palmo + 0.3:
			_guasto("braccia: le dita non si chiudono sul palmo")
		if aperta.ventaglio < chiusa.ventaglio + 8.0:
			_guasto("braccia: aperta, la mano non si allarga")
	await _se_ne_va(KEY_F4, o, "braccia", BraccioUmano.DURATA_SCENDE + 3.0, tutti)


## Le misure di una mano, sulle quattro dita: quanto stanno lontane le punte dal polso, in
## media; da che parte va ogni dito dalla sua nocca — il coseno con il palmo, +1 dritto sul
## palmo, 0 teso, -1 rovesciato sul dorso; e l'angolo fra il mignolo e l'indice.
##
## NON QUANTO LE PUNTE STANNO DALLA PARTE DEL PALMO: in un pugno le punte tornano a toccare
## il palmo, e misurate dal polso stanno dove stavano da tese. La prima stesura della sonda
## misurava quello, e dava la mano per rotta.
func _mano(b: BraccioUmano) -> Dictionary:
	var polso := b.polso_nel_mondo()
	var palmo := b.palmo_nel_mondo()
	var punte := b.punte_nel_mondo()
	var nocche := b.nocche_nel_mondo()
	var lontane := 0.0
	var sul_palmo := 0.0
	for k in 4:
		lontane += punte[k].distance_to(polso) / 4.0
		sul_palmo += (punte[k] - nocche[k]).normalized().dot(palmo) / 4.0
	var ventaglio := rad_to_deg((punte[0] - nocche[0]).angle_to(punte[3] - nocche[3]))
	return {"lontane": lontane, "palmo": sul_palmo, "ventaglio": ventaglio}


func _mesh_di(n: Node) -> Array[MeshInstance3D]:
	var fuori: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		fuori.append(n as MeshInstance3D)
	for f in n.get_children():
		fuori.append_array(_mesh_di(f))
	return fuori


# --- F5 ------------------------------------------------------------------------------

func _oculare() -> void:
	var o := (await _arriva(KEY_F5, "oculare")) as OrroreNellOculare
	if o == null:
		return
	var ocu := Oculare.find_in(get_tree())
	var g := Player.find_in(get_tree())
	if ocu == null or ocu.camera() == null:
		_guasto("oculare: in scena manca l'oculare")
		return
	var cam := ocu.camera()
	if _camera.cull_mask & OrroreNellOculare.STRATO:
		_guasto("oculare: la camera del giocatore vede il layer dell'occhio")
	if not (cam.cull_mask & OrroreNellOculare.STRATO):
		_guasto("oculare: la camera dell'oculare non vede il layer dell'occhio")
	# si guarda dentro davvero, come col tasto: la camera dell'oculare diventa quella corrente
	ocu.call("_su_interazione", g)
	await get_tree().process_frame
	var occhio := o.occhio()
	if occhio == null:
		_guasto("oculare: guardando dentro non c'è nessun occhio")
		ocu.call("_su_interazione", g)
		return
	occhio.set_process(false)
	var avanza := func(dt: float) -> void:
		occhio.passo(dt)
	var distanza := occhio.global_position.distance_to(cam.global_position)
	var sull_asse := rad_to_deg((occhio.global_position - cam.global_position).normalized().angle_to(-cam.global_basis.z))
	for mesh in _mesh_di(occhio):
		if mesh.layers != OrroreNellOculare.STRATO:
			_guasto("oculare: una parte dell'occhio sta su un layer che il giocatore vede")
			break
	if o.luce() == null or o.luce().light_cull_mask != OrroreNellOculare.STRATO:
		_guasto("oculare: la luce dell'occhio illumina anche il resto del mondo")
	var verso_te := func() -> float:
		return rad_to_deg(occhio.sguardo().angle_to((cam.global_position - occhio.global_position).normalized()))
	var altrove: float = verso_te.call()
	var pupilla_prima := occhio.pupilla().y
	_avanti(o, OrroreNellOculare.ALTROVE + 0.6, avanza)
	var trovato: float = verso_te.call()
	_avanti(o, OrroreNellOculare.SI_ACCORGE + 1.5, avanza)
	var pupilla_dopo := occhio.pupilla().y
	var storta := rad_to_deg(asin(clampf(absf(occhio.asse_pupilla().dot(cam.global_basis.y)), 0.0, 1.0)))
	print("[orrori] oculare: occhio a %.2f m dalla camera e %.2f° dall'asse; guarda a %.0f° da te, poi a %.1f°; pupilla da %.2f a %.2f, storta di %.1f° nell'inquadratura" % [
		distanza, sull_asse, altrove, trovato, pupilla_prima, pupilla_dopo, storta])
	if absf(distanza - OrroreNellOculare.DISTANZA) > 0.01 or sull_asse > 0.5:
		_guasto("oculare: l'occhio non sta davanti alla bocca del tubo")
	if altrove < 15.0:
		_guasto("oculare: appena entrati ti guarda già")
	if trovato > 3.0:
		_guasto("oculare: non ti trova")
	if pupilla_dopo > pupilla_prima * 0.6:
		_guasto("oculare: trovato, la pupilla non si stringe")
	if storta > 1.0:
		_guasto("oculare: la pupilla è storta nell'inquadratura")
	ocu.call("_su_interazione", g)
	await _se_ne_va(KEY_F5, o, "oculare", 20.0, avanza)
	if not (_camera.cull_mask & OrroreNellOculare.STRATO):
		_guasto("oculare: andato via, la camera del giocatore non ha riavuto il suo layer")


# --- F6 ------------------------------------------------------------------------------

func _posa() -> void:
	# LA COMPOSIZIONE, su tre pagine diverse: una galassia, una nebulosa che riempie il campo,
	# un ammasso globulare piccolo. Nessun pixel cambia sulla carta; l'occhio sta dentro la
	# foto, sopra il soggetto, e non è un disco incollato — le stelle di davanti restano.
	var peggio_fuori := 0
	for pagina_di in [[&"m51", 2], [&"ic1396", 2], [&"m13", 3]]:
		var pagina := (load(Stampa.PAGINA % pagina_di) as Texture2D).get_image()
		if pagina.is_compressed():
			pagina.decompress()
		pagina.convert(Image.FORMAT_RGBA8)
		var r := OcchioNellaPosa.riquadro_foto(pagina)
		var sogg := OcchioNellaPosa.soggetto(pagina, r)
		var composta := OcchioNellaPosa.componi(pagina, 7)
		var ancora := OcchioNellaPosa.componi(pagina, 7)
		var fuori := 0
		var cambiati := 0
		var stelle_rimaste := 0
		var stelle := 0
		var centro: Vector2 = sogg[&"centro"]
		var raggio: float = sogg[&"raggio"]
		for y in pagina.get_height():
			for x in pagina.get_width():
				var prima := pagina.get_pixel(x, y)
				var dopo := composta.get_pixel(x, y)
				if not prima.is_equal_approx(dopo):
					if r.has_point(Vector2i(x, y)):
						cambiati += 1
					else:
						fuori += 1
				if Vector2(x + 0.5, y + 0.5).distance_to(centro) < raggio * 0.5 and OcchioNellaPosa._stella(pagina, x, y):
					stelle += 1
					if dopo.get_luminance() >= prima.get_luminance() - 0.01:
						stelle_rimaste += 1
		peggio_fuori = maxi(peggio_fuori, fuori)
		var disco := PI * raggio * raggio
		print("[orrori] posa: %s, foto in %s, occhio al centro %s con raggio %.0f px (%.0f%% del lato corto); cambiati %d pixel nella foto (%.0f%% del disco), %d sulla carta; stelle davanti %d su %d" % [
			pagina_di[0], r, centro.round(), raggio, 100.0 * raggio / mini(r.size.x, r.size.y),
			cambiati, 100.0 * cambiati / disco, fuori, stelle_rimaste, stelle])
		# le foto sono orizzontali o verticali: M13 sta in piedi
		if maxi(r.size.x, r.size.y) < 150 or mini(r.size.x, r.size.y) < 80:
			_guasto("posa: il riquadro della foto di %s non si trova" % pagina_di[0])
		if cambiati < disco * 0.6:
			_guasto("posa: l'occhio non copre il soggetto di %s" % pagina_di[0])
		if not r.has_point(Vector2i(centro)):
			_guasto("posa: l'occhio di %s è fuori dalla foto" % pagina_di[0])
		if stelle_rimaste < stelle:
			_guasto("posa: l'occhio copre le stelle che gli stanno davanti in %s" % pagina_di[0])
		if composta.get_data() != ancora.get_data():
			_guasto("posa: la stessa stampa non viene uguale due volte")
	if peggio_fuori > 0:
		_guasto("posa: l'occhio è uscito dalla foto sulla carta")

	var stampante := Stampante.find_in(get_tree())
	var prima := get_tree().get_nodes_in_group(Stampa.GRUPPO).size()
	var o := await _arriva(KEY_F6, "posa")
	if o == null or stampante == null:
		return
	for _f in 8:
		await get_tree().process_frame
	var dopo := get_tree().get_nodes_in_group(Stampa.GRUPPO).size()
	var con_occhio := 0
	for n in get_tree().get_nodes_in_group(Stampa.GRUPPO):
		if (n as Stampa).occhio:
			con_occhio += 1
			if not bool((n as Stampa).ricordo(stampante.get_parent()).get(&"occhio", false)):
				_guasto("posa: il registro non si ricorda l'occhio")
	print("[orrori] posa: premuto il tasto, stampe da %d a %d, %d con l'occhio" % [prima, dopo, con_occhio])
	if dopo <= prima or con_occhio == 0:
		_guasto("posa: premuto il tasto, non esce una stampa con l'occhio")
	if not Stampante._infestata({&"dall_alto": "user://stampe/vecchia.png"}):
		_guasto("posa: una stampa della stesura di prima non torna infestata")
	if not stampante.infesta_la_prossima:
		_guasto("posa: la prossima foto rivelata non è armata")
	Events.photo_revealed.emit(9999, &"m51", 2)
	if stampante.infesta_la_prossima:
		_guasto("posa: la foto rivelata non ha consumato l'infestazione")
	await _se_ne_va(KEY_F6, o, "posa", 1.0)


# --- F7 ------------------------------------------------------------------------------

func _montatura() -> void:
	# IL CONTO, sulla trigonometria di `SkyGeometry`, anche sotto l'orizzonte
	var peggio := 0.0
	for alt in [-40.0, -10.0, 5.0, 50.0, 62.0, 75.0, 88.0]:
		for az in [0.0, 24.0, 90.0, 150.0, 210.0, 300.0]:
			var eq := OrroreMontatura.equatoriali(Orrore.verso(az, alt))
			peggio = maxf(peggio, absf(SkyGeometry.altezza(eq.x, eq.y) - alt))
	if peggio > 0.01:
		_guasto("montatura: il conto sbaglia l'altezza di %.3f°" % peggio)
	# E SULLA MONTATURA VERA: la si piazza e le si chiede dove guarda
	var m := TelescopeMount.find_in(get_tree())
	if m == null:
		_guasto("montatura: in scena non c'è")
		return
	var prima := m.dove()
	var peggio_vero := 0.0
	for alt in [-15.0, 55.0, 70.0]:
		for az in [24.0, 120.0, 250.0]:
			var v := Orrore.verso(az, alt)
			var eq := OrroreMontatura.equatoriali(v)
			m.piazza(eq.x, eq.y)
			peggio_vero = maxf(peggio_vero, rad_to_deg(m.direzione().angle_to(v)))
	m.piazza(prima.x, prima.y)
	print("[orrori] montatura: il conto sbaglia l'altezza di %.4f°, la montatura vera guarda a %.2f° dal verso chiesto" % [
		peggio, peggio_vero])
	# DUE GRADI E NON ZERO: il tubo di questo telescopio è storto di 0,951 gradi rispetto
	# al proprio asse (`TelescopeMount`, `AR_ZERO`) e punta sempre un grado più in là
	# finché non lo si sincronizza su una stella — è la fase 3, ed è voluto. Sul conto
	# puro, qui sopra, lo scarto è zero; sulla montatura vera resta quel cono.
	if peggio_vero > 2.0:
		_guasto("montatura: piazzata col conto, guarda altrove (%.2f°)" % peggio_vero)

	var g := Player.find_in(get_tree())
	var o := (await _arriva(KEY_F7, "montatura")) as OrroreMontatura
	if o == null:
		return
	var verso_te := func() -> Vector3:
		return (_camera.global_position - m.apertura()).normalized()
	# TRE GRADI E NON ZERO: fra il tasto e questa riga sono passati due fotogrammi, il tubo
	# è partito, e l'apertura da cui si misura si è spostata con lui
	var girata := rad_to_deg(o.verso_comandato().angle_to(verso_te.call()))
	if girata > 3.0:
		_guasto("montatura: non si gira verso chi le sta accanto (%.2f°)" % girata)
	if o.bersaglio().distance_to(OrroreMontatura.equatoriali(o.verso_comandato())) > 0.01:
		_guasto("montatura: il comando non è il verso che ha chiesto")
	if not m.in_moto():
		_guasto("montatura: non parte")
	# UN PASSO NON BASTA: spostandosi di poco resta dov'è
	var chiesto := o.verso_comandato()
	g.global_position = DA + Vector3(0.05, 0.0, 0.0)
	_avanti(o, OrroreMontatura.REAZIONE + 0.3)
	var fermo := o.verso_comandato().is_equal_approx(chiesto)
	# SPOSTANDOSI DAVVERO, aspetta un istante e ti viene dietro
	g.global_position = DA + Vector3(-6.0, 0.0, 4.0)
	_avanti(o, OrroreMontatura.REAZIONE * 0.5)
	var subito := o.verso_comandato().is_equal_approx(chiesto)
	_avanti(o, OrroreMontatura.REAZIONE)
	var seguito := rad_to_deg(o.verso_comandato().angle_to(verso_te.call()))
	print("[orrori] montatura: spostandosi di 5 cm resta ferma: %s; di sette metri non parte subito: %s, e poi punta a %.2f° da chi guarda" % [
		fermo, subito, seguito])
	if not fermo:
		_guasto("montatura: insegue anche un passo da niente")
	if not subito:
		_guasto("montatura: non aspetta un istante prima di seguire")
	if seguito > 0.01:
		_guasto("montatura: non segue chi si sposta")
	g.global_position = DA
	# la si porta dov'era senza aspettare il motore, e si guarda che l'orrore lo capisca
	_premi(KEY_F7)
	await get_tree().process_frame
	m.piazza(prima.x, prima.y)
	var t := 0.0
	while o.attivo() and t < 3.0:
		o.passo(PASSO)
		t += PASSO
	for _f in 3:
		await get_tree().process_frame
	if is_instance_valid(o) and o.attivo():
		_guasto("montatura: tornata ferma, non se ne va")
	else:
		print("[orrori] montatura: torna dov'era e se ne va")


# --- F8 ------------------------------------------------------------------------------

func _colore() -> void:
	var we := Orrore.trova(get_tree().root, "WorldEnvironment") as WorldEnvironment
	var ambiente: Environment = we.environment if we != null else null
	var ambiente_prima := [ambiente.glow_enabled, ambiente.volumetric_fog_enabled,
		ambiente.volumetric_fog_density] if ambiente != null else []
	var o := (await _arriva(KEY_F8, "colore")) as OrroreColore
	if o == null:
		return
	var prato := Orrore.trova(get_tree().root, "Prato") as Prato
	var erba := (prato.get_node("Erba") as GeometryInstance3D).material_override as ShaderMaterial
	var davanti := -_camera.global_basis.z
	# LA PIETRA ARRIVA, ED È LA STESSA: al primo secondo è alta davanti a chi guarda, poi scende
	# lungo la strada senza salti, accende il paesaggio, e quella che resta nel prato è lei
	_avanti(o, 1.0)
	var testa := o.testa_del_bolide()
	var alto := rad_to_deg(asin(testa.y))
	var di_lato := rad_to_deg(absf(Vector2(testa.x, testa.z).angle_to(Vector2(davanti.x, davanti.z))))
	var lampo := 0.0
	var luce := 0.0
	var salto := 0.0
	var prima := o.pietra().global_position
	var volo := 1.0
	while o.fase() == "CADE" and volo < OrroreColore.ARRIVO + 1.0:
		o.passo(PASSO)
		volo += PASSO
		var ora := o.pietra().global_position
		# quanto si è spostata in un passo, oltre quello che la sua velocità le consente
		salto = maxf(salto, ora.distance_to(prima) - OrroreColore.velocita_partenza() * PASSO * 1.05)
		prima = ora
		lampo = maxf(lampo, (o.get_node("Lampo") as DirectionalLight3D).light_energy)
		luce = maxf(luce, (o.get_node("Luce") as OmniLight3D).light_energy)
	var ultimo_passo := o.pietra().global_position.distance_to(prima)
	o.passo(PASSO)
	var arrivo_salto := o.pietra().global_position.distance_to(prima)
	var fase_caduta := o.fase()
	var buca := float(erba.get_shader_parameter("colore_buca"))
	var pietra := o.pietra().visible
	var nel_prato := Vector2(o.pietra().global_position.x, o.pietra().global_position.z).distance_to(OrroreColore.DOVE)
	var cratere := o.cratere().visible
	print("[orrori] colore: la pietra al primo secondo sta a %.0f° d'altezza e %.0f° di lato, scende senza salti (%.1f m oltre la sua velocità), il paesaggio si accende a %.1f e la luce vicina a %.1f; arriva in %.1f s spostandosi di %.1f m nell'ultimo passo, e resta a %.2f m dalla buca (%s, visibile %s, cratere %s, buca %.1f m)" % [
		alto, di_lato, salto, lampo, luce, volo, arrivo_salto, nel_prato, fase_caduta, pietra, cratere, buca])
	if alto < 15.0 or di_lato > 45.0:
		_guasto("colore: la pietra non arriva alta davanti a chi guarda")
	if salto > 1.0 or arrivo_salto > OrroreColore.VELOCITA_ARRIVO * PASSO * 1.5 + 1.0:
		_guasto("colore: la pietra salta invece di scendere")
	if lampo < 1.0 or luce < 5.0:
		_guasto("colore: scendendo la pietra non accende il paesaggio")
	if fase_caduta != "BRILLA" or not pietra or not cratere or buca <= 0.0 or nel_prato > 0.5:
		_guasto("colore: la pietra non è caduta nel prato")
	# E LA PIETRA È UN SOLIDO: un raggio che scende da sopra si ferma su di lei, non sull'erba
	await get_tree().physics_frame
	await get_tree().physics_frame
	var sopra := o.pietra().global_position + Vector3.UP * 3.0
	var giu := PhysicsRayQueryParameters3D.create(sopra, sopra + Vector3.DOWN * 6.0)
	giu.collision_mask = Interactable.LAYER_WORLD
	var colpo := o.get_world_3d().direct_space_state.intersect_ray(giu)
	var sul_solido: bool = not colpo.is_empty() and colpo["collider"] == o.solido()
	var dal_suolo: float = (colpo["position"] as Vector3).y - o.dove().y if not colpo.is_empty() else 0.0
	print("[orrori] colore: un raggio dall'alto si ferma sulla pietra: %s, %.2f m sopra la buca" % [sul_solido, dal_suolo])
	if not sul_solido or dal_suolo < 0.1:
		_guasto("colore: la pietra non ha un solido, ci si passa attraverso")
	_avanti(o, 30.0)
	var raggio := float(erba.get_shader_parameter("colore_raggio"))
	var forza := float(erba.get_shader_parameter("colore_forza"))
	var dalla_porta := Vector2(o.dove().x, o.dove().z).distance_to(Vector2(DA.x, DA.z))
	# NON UN CERCHIO: a quattro quinti del raggio, girando attorno, si entra e si esce
	var dentro := 0
	for k in 72:
		var q := OrroreColore.DOVE + Vector2.from_angle(TAU * k / 72.0) * raggio * 0.8
		if OrroreColore.fronte(q, OrroreColore.DOVE, raggio) > 0.5:
			dentro += 1
	print("[orrori] colore: la buca sta a %.1f m dalla porta; dopo 30 s l'erba brilla fino a %.1f m, forza %.2f, e a quattro quinti del raggio è presa in %d direzioni su 72" % [
		dalla_porta, raggio, forza, dentro])
	if raggio < 5.0 or forza < 0.99:
		_guasto("colore: l'erba non si è accesa")
	if dentro == 0 or dentro == 72:
		_guasto("colore: il colore si allarga a cerchio")
	# UNA LUCE, NON UNA TINTA: il bagliore e la foschia accesi, e la luce del prato che arriva
	# oltre il colore, sulle pareti
	var chiarore := o.get_node("Chiarore") as OmniLight3D
	var foschia := o.get_node("Foschia") as FogVolume
	print("[orrori] colore: bagliore %s, nebbia volumetrica %s; la luce del prato arriva a %.0f m con energia %.2f; la foschia è larga %.0f m" % [
		ambiente != null and ambiente.glow_enabled, ambiente != null and ambiente.volumetric_fog_enabled,
		chiarore.omni_range, chiarore.light_energy, foschia.size.x])
	if raggio < 12.0:
		_guasto("colore: dopo trenta secondi il colore non si è preso il prato")
	if ambiente == null or not ambiente.glow_enabled or not ambiente.volumetric_fog_enabled:
		_guasto("colore: il bagliore o la foschia dell'ambiente non sono accesi")
	if chiarore.omni_range < raggio or chiarore.light_energy < 0.5 or not foschia.visible:
		_guasto("colore: il prato acceso non illumina attorno")
	_premi(KEY_F8)
	await get_tree().process_frame
	var grigio := 0.0
	var cenere_per_terra := 0.0
	var colonna := 0.0
	var t := 0.0
	while o.attivo() and t < 60.0:
		o.passo(PASSO)
		t += PASSO
		grigio = maxf(grigio, float(erba.get_shader_parameter("colore_cenere")))
		if o.attivo():
			colonna = maxf(colonna, o.colonna_alta())
		if o.cenere_per_terra() != null:
			cenere_per_terra = maxf(cenere_per_terra, o.cenere_per_terra().modulate.a)
	for _f in 3:
		await get_tree().process_frame
	var resta := [float(erba.get_shader_parameter("colore_raggio")),
		float(erba.get_shader_parameter("colore_forza")),
		float(erba.get_shader_parameter("colore_cenere")),
		float(erba.get_shader_parameter("colore_tende")),
		float(erba.get_shader_parameter("colore_buca"))]
	var ambiente_dopo := [ambiente.glow_enabled, ambiente.volumetric_fog_enabled,
		ambiente.volumetric_fog_density] if ambiente != null else []
	print("[orrori] colore: se ne va in %.1f s, la colonna arriva a %.0f m, l'erba è arrivata grigia al %d%% e la terra al %d%%, e resta %s; l'ambiente era %s ed è %s" % [
		t, colonna, int(grigio * 100.0),
		int(cenere_per_terra * 100.0), resta, ambiente_prima, ambiente_dopo])
	if colonna < 1000.0:
		_guasto("colore: la colonna non arriva al cielo")
	if ambiente_dopo != ambiente_prima:
		_guasto("colore: andandosene non rimette l'ambiente com'era")
	if grigio < 0.99:
		_guasto("colore: andandosene non lascia la cenere nell'erba")
	if cenere_per_terra < 0.99:
		_guasto("colore: andandosene non lascia la cenere per terra")
	if resta != [0.0, 0.0, 0.0, 0.0, 0.0]:
		_guasto("colore: il prato non torna com'era")
	if is_instance_valid(o):
		_guasto("colore: il nodo è ancora in scena")
