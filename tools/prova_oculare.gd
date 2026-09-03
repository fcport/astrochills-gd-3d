## SI GUARDA DENTRO IL TELESCOPIO, E SI VEDE DOVE PUNTA?
##
## LA DOMANDA, E PERCHE' NON E' OVVIA. «Guardare nell'oculare» sembra una camera
## in piu' e un tasto, e in un pomeriggio lo si scrive. Le cose che si rompono
## sono altre tre, e nessuna si vede leggendo il codice:
##
##   1. DOVE GUARDA quella camera. L'asse ottico di questo telescopio non e' il
##      -Z di nessun nodo: e' il +Y di `Mira`, che il modellatore appende ad
##      AsseDec misurandolo sui vertici. Una camera messa li' con la posa di
##      default guarda di traverso, e in partita sembra comunque «un pezzo di
##      cielo» - e' lo stesso errore che la camera CCD ha fatto per due settimane
##      senza che nessun controllo se ne accorgesse (vedi `ccd_camera.gd`).
##   2. SE SEGUE IL TUBO. La vista deve stare appesa dentro la gerarchia della
##      montatura: appoggiata fuori, resta ferma mentre il telescopio insegue, e
##      «cosa sta puntando» diventa una bugia dopo dieci secondi.
##   3. SE SI ESCE. Entrare toglie il controllo al giocatore. Se l'uscita non
##      rimette la camera del giocatore e non riaccende il controller, la partita
##      resta ferma in un cerchio nero: il difetto peggiore che questa vista puo'
##      avere, e quello che un occhio distratto scambia per «si e' bloccato».
##
## E LA REGOLA DEL FOCHEGGIATORE, che e' il motivo per cui questa cosa esiste: al
## fuoco ci sta UNA cosa sola. Con la camera CCD avvitata non ci si guarda dentro,
## e il prompt non deve nemmeno comparire.
##
## COSA NON PROVA. Non prova che il cielo sia bello ne' che il campo sia largo
## giusto: quello lo guarda l'operatore negli scatti che questa sonda salva.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_oculare.tscn
##     Godot_v4.7.2-stable_win64.exe --path . tools/prova_oculare.tscn   (con gli scatti)
extends Node

## Dove finiscono gli scatti per l'operatore.
const DENTRO := "user://oculare.png"
const CHIUSA := "user://oculare_chiusa.png"

## Da quanto lontano si prova a mettersi davanti al focheggiatore, in metri,
## misurati in orizzontale. Il fuoco sta a due metri da terra e l'occhio a 1,65:
## piu' di un metro e la diagonale supera la portata dell'interazione.
const GIRO := [0.45, 0.60, 0.75, 0.90]

## Quante direzioni si provano intorno al focheggiatore.
const VERSI := 12

## Quanto puo' sbagliare la direzione della vista rispetto all'asse ottico, in
## gradi. Un decimo: e' zero con il margine di un float, non una tolleranza.
const STORTA := 0.1

var _guasti := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[oculare] GUASTO: " + msg)


func _verifica(cosa: String, ok: bool) -> void:
	if ok:
		print("[oculare] ok: " + cosa)
	else:
		_guasto(cosa)


func _premi() -> void:
	var e := InputEventAction.new()
	e.action = &"interact"
	e.pressed = true
	Input.parse_input_event(e)


func _scatta(dove: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(dove)
		print("[oculare] scatto in %s" % ProjectSettings.globalize_path(dove))


## Mette il giocatore in un posto da cui il suo raggio trova l'oculare. Torna la
## riga del prompt, o una stringa vuota se da nessuna parte lo si vede.
##
## SI GIRA INTORNO invece di scegliere «davanti»: il focheggiatore di un
## newtoniano sta in cima al tubo e guarda di lato, e da che parte cada dipende da
## dove il telescopio sta puntando. Un posto scritto a mano varrebbe per una posa
## sola.
func _mettiti_davanti(player: Player, oc: Oculare) -> String:
	var cam := player.camera()
	var bersaglio := oc.global_position
	var spazio := player.get_world_3d().direct_space_state
	for d in GIRO:
		for k in VERSI:
			var ang := TAU * float(k) / float(VERSI)
			var x: float = bersaglio.x + cos(ang) * (d as float)
			var z: float = bersaglio.z + sin(ang) * (d as float)
			# IL PAVIMENTO SOTTO QUEL PUNTO, che in cupola non e' quota zero: c'e'
			# la passerella, e nascere sotto di lei vorrebbe dire guardare il
			# telescopio attraverso il grigliato.
			var giu := PhysicsRayQueryParameters3D.create(
				Vector3(x, bersaglio.y, z), Vector3(x, bersaglio.y - 3.0, z))
			giu.collision_mask = Interactable.LAYER_WORLD
			var suolo := spazio.intersect_ray(giu)
			if suolo.is_empty():
				continue
			var dove: Vector3 = suolo["position"]
			player.global_position = dove
			player.look_at(Vector3(bersaglio.x, dove.y, bersaglio.z), Vector3.UP)
			if cam != null:
				cam.look_at(bersaglio, Vector3.UP)
			await get_tree().physics_frame
			await get_tree().physics_frame
			if player.focus() == oc:
				return oc.prompt()
	return ""


func _prova() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 6:
		await get_tree().physics_frame

	var oc := Oculare.find_in(get_tree())
	var ccd := CcdCamera.find_in(get_tree())
	var player := Player.find_in(get_tree())
	var mount := TelescopeMount.find_in(get_tree())
	if oc == null or ccd == null or player == null or mount == null:
		print("[oculare] manca un pezzo (oculare=%s ccd=%s giocatore=%s montatura=%s)"
			% [oc != null, ccd != null, player != null, mount != null])
		get_tree().quit(1)
		return

	# --- AL FUOCO CI STA UNA COSA SOLA -------------------------------------
	_verifica("con la camera CCD avvitata non ci si guarda dentro",
		ccd.montata() and not oc.can_interact())

	# Si smonta come la smonta chi gioca: prendendola in mano. Poi la si posa, e
	# cade dove capita - che e' quello che succede davvero.
	ccd.prendi(player)
	ccd.lascia()
	for _i in 30:
		await get_tree().physics_frame
	_verifica("smontata la camera, l'oculare si puo' usare",
		not ccd.montata() and oc.can_interact())

	# --- IL GESTO ----------------------------------------------------------
	var riga := await _mettiti_davanti(player, oc)
	if riga.is_empty():
		_guasto("da nessuno dei %d posti intorno al focheggiatore il raggio del "
			% (GIRO.size() * VERSI) + "giocatore trova l'oculare: in partita il "
			+ "prompt non comparirebbe mai")
		print("[oculare] GUASTO: %d controlli falliti" % _guasti)
		get_tree().quit(1)
		return
	print("[oculare] il prompt dice: «%s»" % riga)

	_premi()
	await get_tree().process_frame
	await get_tree().physics_frame
	_verifica("premendo E si guarda dentro", oc.dentro())
	_verifica("il controllo del giocatore e' sospeso", not player.is_enabled())

	var cam := _camera_corrente()
	_verifica("la camera corrente e' quella dell'oculare",
		cam != null and cam.name == "Oculare")

	# --- DOVE GUARDA -------------------------------------------------------
	if cam != null:
		var scarto := rad_to_deg((-cam.global_basis.z).angle_to(mount.direzione()))
		_verifica("la vista sta sull'asse ottico (scarto %.4f gradi)" % scarto,
			scarto <= STORTA)

	# --- SEGUE IL TUBO -----------------------------------------------------
	# Si sposta la montatura di trenta gradi e si guarda se la vista ci va
	# insieme. E' la prova che la camera sta DENTRO la gerarchia e non appoggiata
	# accanto: una camera lasciata fuori resterebbe puntata dov'era, e la vista
	# direbbe una cosa che il telescopio non sta piu' facendo.
	if cam != null:
		var prima := -cam.global_basis.z
		var dove := mount.dove()
		mount.piazza(dove.x + 30.0, dove.y - 15.0)
		await get_tree().process_frame
		await get_tree().physics_frame
		var poi := -cam.global_basis.z
		var girata := rad_to_deg(prima.angle_to(poi))
		var scarto2 := rad_to_deg(poi.angle_to(mount.direzione()))
		_verifica("spostando la montatura la vista si sposta con lei (%.1f gradi)"
			% girata, girata > 5.0)
		_verifica("e resta sull'asse ottico (scarto %.4f gradi)" % scarto2,
			scarto2 <= STORTA)

	# --- SI VEDE IL CIELO? Lo guarda l'operatore ----------------------------
	# A cupola chiusa dentro l'oculare c'e' il buio della calotta, ed e' la
	# risposta giusta: si scatta prima quella, poi si apre e si aspetta che la
	# fessura arrivi dove guarda il tubo.
	for _i in 20:
		await get_tree().process_frame
	_scatta(CHIUSA)
	Events.dome_aperture_changed.emit(1.0)
	var azimut := DomeAzimuth.find_in(get_tree())
	# QUALCHE FOTOGRAMMA PRIMA DI CHIEDERE L'ERRORE: la cupola calcola dove deve
	# andare nel proprio `_process`, e chiesto nello stesso fotogramma in cui si e'
	# aperta risponde «zero» perche' non ha ancora guardato il telescopio. Con
	# quello zero l'attesa finisce subito e si scatta una foto della calotta.
	for _i in 10:
		await get_tree().process_frame
	# IL TEMPO SI ACCELERA COME LO ACCELERA IL GIOCO. La calotta gira lenta - e' un
	# motore da mezza tonnellata, e deve sembrarlo - quindi da riposo a dove punta
	# il tubo ci mette piu' di un minuto. Il gioco ha gia' F1-F4 per accelerare il
	# tempo: qui si usa la stessa manopola invece di aspettare, e la si rimette a
	# uno prima di scattare, o la foto uscirebbe con il mosso di una cupola che
	# corre.
	var pazienza := 0
	Engine.time_scale = 10.0
	while azimut != null and azimut.errore() > 1.0 and pazienza < 3000:
		pazienza += 1
		await get_tree().process_frame
	Engine.time_scale = 1.0
	if azimut != null:
		print("[oculare] la fessura e' a %.1f gradi dal telescopio dopo %d fotogrammi"
			% [azimut.errore(), pazienza])
	for _i in 20:
		await get_tree().process_frame
	_scatta(DENTRO)

	# --- E SI ESCE ---------------------------------------------------------
	_premi()
	await get_tree().process_frame
	await get_tree().physics_frame
	_verifica("premendo E di nuovo si esce", not oc.dentro())
	_verifica("il giocatore riprende il controllo", player.is_enabled())
	var tornata := _camera_corrente()
	_verifica("e la camera torna quella del giocatore",
		tornata != null and tornata == player.camera())

	if _guasti == 0:
		print("[oculare] ok: si guarda dentro il telescopio e si torna fuori")
	else:
		print("[oculare] GUASTO: %d controlli falliti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)


## La camera che il viewport del mondo sta usando adesso. Si chiede al VIEWPORT e
## non si tiene un elenco: `current` su una camera ne spegne un'altra senza dirlo
## a nessuno, e l'unico che sa com'e' finita e' lui.
func _camera_corrente() -> Camera3D:
	var player := Player.find_in(get_tree())
	if player == null:
		return null
	return player.get_viewport().get_camera_3d()
