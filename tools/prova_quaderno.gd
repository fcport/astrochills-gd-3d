## SI TROVA IL QUADERNO, SI APRE, SI SFOGLIA, SI RICHIUDE?
##
## LA DOMANDA, E PERCHE' NON BASTA LEGGERE IL CODICE. Le cose che si rompono sono
## quattro, e nessuna dà errore:
##
##   1. SE LO SI MIRA. Un quaderno alto due centimetri e mezzo, posato su una
##      consolle accanto a una cassa di monitor: da certe parti il raggio del
##      giocatore trova il monitor, o il piano, e il prompt non compare mai.
##   2. SE SI APRE CON UN TASTO SOLO. La stessa pressione di `E` passa dal
##      giocatore e poi, nello stesso giro, dal quaderno: senza la guardia del
##      fotogramma si apre e si richiude subito, e sembra rotto.
##   3. SE SI SFOGLIA dal tasto, non solo chiamando la funzione.
##   4. SE SI ESCE. Aperto, il controllo del giocatore è sospeso: se chiudendo non
##      torna, la partita resta ferma davanti a una pagina.
##
## COSA NON PROVA: che le pagine si leggano. Quello lo guarda l'operatore negli
## scatti — la stanza con il quaderno sulla consolle, la prima coppia di pagine,
## una coppia in mezzo e l'ultima. Che nessuna pagina esca dal foglio lo dice il
## banco (`_check_quaderno`), in colonne.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_quaderno.tscn
##     Godot_v4.7.2-stable_win64.exe --path . tools/prova_quaderno.tscn   (con gli scatti)
extends Node

const SCATTI := "user://shots/"

## Da quanto lontano, in pianta, ci si prova a mettere davanti al quaderno. Il piano
## sta a 0,75 e l'occhio a 1,65: oltre il metro la diagonale supera la portata.
const GIRO := [0.55, 0.65, 0.75, 0.85]
const VERSI := 16

var _guasti := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[quaderno] GUASTO: " + msg)


func _verifica(cosa: String, ok: bool) -> void:
	if ok:
		print("[quaderno] ok: " + cosa)
	else:
		_guasto(cosa)


func _premi(azione: StringName) -> void:
	var e := InputEventAction.new()
	e.action = azione
	e.pressed = true
	Input.parse_input_event(e)
	var su := InputEventAction.new()
	su.action = azione
	su.pressed = false
	Input.parse_input_event(su)


func _scatta(nome: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(SCATTI + nome)
		print("[quaderno] scatto in %s" % ProjectSettings.globalize_path(SCATTI + nome))


## Mette il giocatore dove il suo raggio trova il quaderno. Torna la riga del prompt,
## o vuota se da nessun posto lo si vede.
##
## SOLO DA TERRA: un punto sopra la consolle ha «pavimento» a 0,75, e un giocatore
## nato lì il quaderno lo guarderebbe dall'alto come nessuno potrà mai fare.
func _mettiti_davanti(player: Player, q: Quaderno) -> String:
	var cam := player.camera()
	var bersaglio := q.global_position + Vector3.UP * 0.02
	var spazio := player.get_world_3d().direct_space_state
	for d in GIRO:
		for k in VERSI:
			var ang := TAU * float(k) / float(VERSI)
			var x: float = bersaglio.x + cos(ang) * (d as float)
			var z: float = bersaglio.z + sin(ang) * (d as float)
			var giu := PhysicsRayQueryParameters3D.create(
				Vector3(x, bersaglio.y + 1.0, z), Vector3(x, bersaglio.y - 2.0, z))
			giu.collision_mask = Interactable.LAYER_WORLD
			var suolo := spazio.intersect_ray(giu)
			if suolo.is_empty() or (suolo["position"] as Vector3).y > 0.10:
				continue
			var dove: Vector3 = suolo["position"]
			player.global_position = dove
			player.look_at(Vector3(bersaglio.x, dove.y, bersaglio.z), Vector3.UP)
			if cam != null:
				cam.look_at(bersaglio, Vector3.UP)
			await get_tree().physics_frame
			await get_tree().physics_frame
			if player.focus() == q:
				print("[quaderno] mirato da (%.2f, %.2f), a %.2f m in pianta" % [x, z, d])
				return q.prompt()
	return ""


func _prova() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCATTI))
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 6:
		await get_tree().physics_frame

	var q := Quaderno.find_in(get_tree())
	var player := Player.find_in(get_tree())
	if q == null or player == null:
		print("[quaderno] manca un pezzo (quaderno=%s giocatore=%s)" % [q != null, player != null])
		get_tree().quit(1)
		return
	_verifica("il quaderno ha %d pagine" % q.quante_pagine(), q.quante_pagine() > 0)

	# --- SI MIRA ---------------------------------------------------------------
	var riga := await _mettiti_davanti(player, q)
	if riga.is_empty():
		_guasto("da nessuno dei %d posti intorno alla consolle il raggio del giocatore "
			% (GIRO.size() * VERSI) + "trova il quaderno: il prompt non comparirebbe mai")
		get_tree().quit(1)
		return
	print("[quaderno] il prompt dice: «%s»" % riga)
	await _scatta("quaderno_consolle.png")

	# --- SI APRE CON UN TASTO SOLO ------------------------------------------------
	_premi(&"interact")
	for _i in 4:
		await get_tree().process_frame
	_verifica("premendo E il quaderno si apre, e resta aperto", q.aperto())
	_verifica("il controllo del giocatore è sospeso", not player.is_enabled())
	await _scatta("quaderno_p01.png")

	# --- SI SFOGLIA --------------------------------------------------------------
	_premi(&"move_right")
	for _i in 3:
		await get_tree().process_frame
	_verifica("D gira la pagina (%d)" % q.pagina(), q.pagina() == 2)
	await _scatta("quaderno_p03.png")
	_premi(&"move_left")
	for _i in 3:
		await get_tree().process_frame
	_verifica("A la riporta indietro (%d)" % q.pagina(), q.pagina() == 0)
	_premi(&"move_left")
	for _i in 3:
		await get_tree().process_frame
	_verifica("dalla prima non si va più indietro", q.pagina() == 0)

	for k in range(2, q.quante_pagine(), 2):
		q.sfoglia(1)
		await _scatta("quaderno_p%02d.png" % (k + 1))
	var ultima := q.pagina()
	q.sfoglia(1)
	_verifica("dall'ultima non si va più avanti (%d)" % q.pagina(), q.pagina() == ultima)

	# --- SI ESCE -----------------------------------------------------------------
	_premi(&"interact")
	for _i in 4:
		await get_tree().process_frame
	_verifica("premendo E il quaderno si chiude", not q.aperto())
	_verifica("il giocatore riprende il controllo", player.is_enabled())

	if _guasti == 0:
		print("[quaderno] ok: si trova, si apre, si sfoglia e si richiude")
	else:
		print("[quaderno] GUASTO: %d controlli falliti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)
