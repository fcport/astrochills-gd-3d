## LA STAMPA ESCE, SI PRENDE, SI APPENDE, E DOMANI È ANCORA LÌ?
##
## PERCHÉ UNA SONDA. La catena è lunga e ogni anello si rompe in silenzio: la notte
## annuncia la foto, la stampante la sente, la pagina esiste, la carta esce dalla
## macchina e non dal mobile, la si raggiunge, un muro vero dice di sì e un pavimento di
## no, e il registro la rimette dov'era. Nessuno di questi guasti dà un errore: danno una
## stampa che non c'è, o una foto a mezz'aria.
##
## LE DOMANDE:
##   1. LA FOTO RIVELATA ESCE dalla stampante, un po' alla volta, e alla fine si prende.
##   2. SI STRAPPA prendendola, e va in mano.
##   3. UN MURO DICE DI SÌ: da qualche punto della sala, guardando una parete, il prompt
##      dice «Appendi»; appesa sta ferma, a piombo, a filo del muro e girata verso chi
##      l'ha appesa — e il raggio del giocatore la ritrova.
##   4. IL PAVIMENTO DICE DI NO.
##   5. IL POSTO GIÀ PRESO DICE DI NO: una seconda stampa non si appende sopra la prima.
##   6. IL REGISTRO LA RIMETTE DOV'ERA, appesa allo stesso muro, al millimetro.
##   7. LA CODA: due foto di fila fanno due stampe, e la prima non strappata cade dove ci
##      si arriva.
##
## IL SAVE VERO SI METTE DA PARTE, e si rimette a posto alla fine: la stampante scrive il
## registro sul profilo del giocatore, e una sonda che lo lasciasse sporco regalerebbe a
## chi gioca dopo tre stampe che non ha mai fatto.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_stampa.tscn
extends Node

const SALVATAGGIO := "user://saves/profile.tres"
const COPIA := "user://saves/profile.prova_stampa.tres"

var _guasti := 0
var _c_era_il_save := false
var _scena: Node
var _giocatore: Player
var _stampante: Stampante


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[stampa] GUASTO: " + msg)


func _aspetta(secondi: float) -> void:
	var fine := Time.get_ticks_msec() + int(secondi * 1000.0)
	while Time.get_ticks_msec() < fine:
		await get_tree().physics_frame


func _stampe() -> Array[Stampa]:
	var tutte: Array[Stampa] = []
	for n in get_tree().get_nodes_in_group(Stampa.GRUPPO):
		if n is Stampa and not n.is_queued_for_deletion():
			tutte.append(n as Stampa)
	return tutte


func _nuova(prima: Array[Stampa]) -> Stampa:
	for s in _stampe():
		if not prima.has(s):
			return s
	return null


func _v(p: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]


## Mette il giocatore lì, girato così, e gli rimette in mano quello che ha in mano: un
## teletrasporto di tre metri è più lungo dello strappo della mano, e senza questa riga la
## stampa cadrebbe per terra a metà sonda.
func _metti(dove: Vector3, imbardata: float, beccheggio: float) -> void:
	_giocatore.global_position = dove
	_giocatore.rotation.y = imbardata
	_giocatore.camera().rotation.x = beccheggio
	var in_mano := _giocatore.get("_in_mano") as Carryable
	if in_mano != null:
		in_mano.global_position = _giocatore.camera().global_position \
			- _giocatore.camera().global_basis.z * 0.5


## Ci si sta in piedi, lì? La capsula del giocatore contro il mondo che lo ferma.
func _ci_si_sta(dove: Vector3) -> bool:
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.30
	capsula.height = Player.STAND_HEIGHT
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = capsula
	q.transform = Transform3D(Basis.IDENTITY, dove + Vector3.UP * (Player.STAND_HEIGHT * 0.5 + 0.05))
	q.collision_mask = Interactable.LAYER_WORLD
	var spazio := (_scena.get_viewport() as Viewport).world_3d.direct_space_state
	return spazio.intersect_shape(q, 1).is_empty()


func _prova() -> void:
	_c_era_il_save = FileAccess.file_exists(SALVATAGGIO)
	if _c_era_il_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SALVATAGGIO),
			ProjectSettings.globalize_path(COPIA))
	Game.profile.photo_prints.clear()

	_scena = load("res://main.tscn").instantiate()
	get_tree().root.add_child(_scena)
	get_tree().current_scene = _scena
	for _i in 20:
		await get_tree().physics_frame

	_stampante = Stampante.find_in(get_tree())
	_giocatore = Player.find_in(get_tree())
	if _stampante == null or _giocatore == null:
		_guasto("manca %s: la prova non vale" % ("la stampante" if _stampante == null else "il giocatore"))
		_chiudi()
		return
	_stampante.secondi = 0.5
	var fessura: Transform3D = _stampante.get("_uscita")
	print("[stampa] la stampante sta a %s, la carta esce a %s" % [
		_v(_stampante.global_position), _v(fessura.origin)])
	if fessura.origin.y < _stampante.global_position.y + 0.03:
		_guasto("la fessura è a %.3f, il piano del mobile a %.3f: la carta esce dal mobile, "
			% [fessura.origin.y, _stampante.global_position.y] + "non dalla stampante")

	# --- 1. LA FOTO RIVELATA ESCE ------------------------------------------
	var prima := _stampe()
	Events.photo_revealed.emit(0, &"m42", 2)
	await get_tree().physics_frame
	var s := _nuova(prima)
	if s == null:
		_guasto("photo_revealed non ha fatto uscire niente")
		_chiudi()
		return
	print("[stampa] 1. esce %s, stato %s" % [s.nome, Stampa.Stato.keys()[s.stato]])
	if s.stato != Stampa.Stato.IN_STAMPA:
		_guasto("appena rivelata la foto dovrebbe essere in stampa")
	await _aspetta(1.0)
	if s.stato != Stampa.Stato.ATTACCATA:
		_guasto("dopo la stampa è %s e non ATTACCATA" % Stampa.Stato.keys()[s.stato])
	var basso := s.global_position - s.global_basis.y * Stampa.ALTEZZA * 0.5
	print("[stampa]    uscita tutta: centro %s, bordo basso %s, si prende da terra: %s" % [
		_v(s.global_position), _v(basso), s.si_riesce_a_prendere()])
	if basso.distance_to(fessura.origin) > 0.01:
		_guasto("il bordo basso non sta sulla fessura (%.1f cm)" % (basso.distance_to(fessura.origin) * 100))
	if not s.si_riesce_a_prendere():
		_guasto("la stampa appena uscita non si raggiunge da nessun posto")

	# --- 2. SI STRAPPA -------------------------------------------------------
	_giocatore.call("_prendi", s)
	await _aspetta(0.3)
	print("[stampa] 2. strappata: stato %s, in mano %s, ferma %s" % [
		Stampa.Stato.keys()[s.stato], s.in_mano(), s.freeze])
	if s.stato != Stampa.Stato.LIBERA or not s.in_mano() or s.freeze:
		_guasto("prenderla doveva strapparla e metterla in mano")

	# --- 3. UN MURO DICE DI SÌ -------------------------------------------------
	#
	# SI CERCA INVECE DI SCEGLIERE: una griglia di posti in cui ci si sta in piedi attorno
	# alla stampante, sedici direzioni ciascuno, guardando dritto. Quanti dicono sì è anche
	# la misura di «qualsiasi muro»: se fossero due, la regola sarebbe troppo stretta.
	var provati := 0
	var buoni: Array = []
	var x := 5.6
	while x <= 8.0:
		var z := 0.8
		while z <= 3.0:
			var dove := Vector3(x, 0.0, z)
			if _ci_si_sta(dove):
				for k in 16:
					_metti(dove, TAU * k / 16.0, 0.0)
					provati += 1
					var d := s.dove_appenderla()
					if not d.is_empty():
						buoni.append([dove, TAU * k / 16.0, (d[&"su"] as Node).name])
			z += 0.4
		x += 0.4
	print("[stampa] 3. guardando dritto da %d posti e direzioni, %d dicono «Appendi»" % [provati, buoni.size()])
	for b in buoni.slice(0, 6):
		print("[stampa]    da %s a %.0f gradi, su %s" % [_v(b[0]), rad_to_deg(b[1]), b[2]])
	if buoni.is_empty():
		_guasto("in tutta la sala non c'è un muro su cui appendere")
		_chiudi()
		return

	var scelto: Array = buoni[buoni.size() / 2]
	_metti(scelto[0], scelto[1], 0.0)
	await _aspetta(0.5)
	var riga := s.prompt_posa()
	print("[stampa]    il prompt dice «%s»" % riga)
	if not riga.begins_with("Appendi"):
		_guasto("guardando il muro buono il prompt non dice Appendi")
	s.posa()
	await _aspetta(0.3)
	var n := s.global_basis.z
	var tasta := PhysicsRayQueryParameters3D.create(s.global_position + n * 0.05,
		s.global_position - n * 0.05, Corazza.LAYER_APPOGGI, [s.get_rid()])
	var muro := s.get_world_3d().direct_space_state.intersect_ray(tasta)
	var scosta := s.global_position.distance_to(muro["position"]) if not muro.is_empty() else INF
	var verso_chi := (_giocatore.camera().global_position - s.global_position).dot(n)
	print("[stampa]    appesa a %s: stato %s, ferma %s, a %.1f mm dal muro, piombo %.4f, verso chi guarda %s" % [
		s.get_parent().name, Stampa.Stato.keys()[s.stato], s.freeze, scosta * 1000.0,
		s.global_basis.y.dot(Vector3.UP), verso_chi > 0.0])
	if s.stato != Stampa.Stato.APPESA or not s.freeze:
		_guasto("dopo posa() la stampa non è appesa")
	if scosta > 0.006:
		_guasto("appesa staccata dal muro di %.1f mm" % (scosta * 1000.0))
	if s.global_basis.y.dot(Vector3.UP) < 0.999:
		_guasto("appesa storta")
	if verso_chi <= 0.0:
		_guasto("appesa con la foto verso il muro")
	await _aspetta(0.2)
	if _giocatore.mirato() != s:
		_guasto("appesa, il raggio del giocatore non la ritrova (mira %s)" % _giocatore.mirato())
	var posto := s.global_transform
	var su_cosa := s.get_parent()

	# --- 4. IL PAVIMENTO DICE DI NO ------------------------------------------
	_giocatore.call("_prendi", s)
	await _aspetta(0.3)
	_metti(scelto[0], scelto[1], deg_to_rad(-70.0))
	await _aspetta(0.3)
	print("[stampa] 4. staccata (%s, figlia di %s) e guardando per terra: «%s»" % [
		Stampa.Stato.keys()[s.stato], s.get_parent().name, s.prompt_posa()])
	if s.prompt_posa().begins_with("Appendi"):
		_guasto("il pavimento dice Appendi")
	if s.get_parent() != _stampante.get_parent():
		_guasto("staccata, la stampa è rimasta figlia del muro")

	# --- 5. IL POSTO GIÀ PRESO DICE DI NO --------------------------------------
	_metti(scelto[0], scelto[1], 0.0)
	await _aspetta(0.3)
	s.posa()
	prima = _stampe()
	Events.photo_revealed.emit(1, &"m31", 3)
	await _aspetta(1.0)
	var seconda := _nuova(prima)
	if seconda == null:
		_guasto("la seconda foto non è uscita")
	else:
		_giocatore.call("_prendi", seconda)
		_metti(scelto[0], scelto[1], 0.0)
		await _aspetta(0.5)
		print("[stampa] 5. davanti alla prima, con la seconda in mano: «%s»" % seconda.prompt_posa())
		if seconda.prompt_posa().begins_with("Appendi"):
			_guasto("la seconda si appenderebbe sopra la prima")
		seconda.lascia()

	# --- 6. IL REGISTRO LA RIMETTE DOV'ERA ------------------------------------
	await _aspetta(Stampante.ATTESA_SALVATAGGIO + 1.5)
	var registro := Game.profile.photo_prints.duplicate(true)
	var appese := registro.filter(func(v: Dictionary) -> bool: return v.get(&"appesa", false))
	print("[stampa] 6. nel registro %d stampe, %d appese, su «%s»" % [
		registro.size(), appese.size(), appese[0].get(&"su", "?") if not appese.is_empty() else "-"])
	if registro.size() != _stampe().size() or appese.size() != 1:
		_guasto("il registro non corrisponde alle stampe in giro")
	for t in _stampe():
		t.queue_free()
	await get_tree().physics_frame
	_stampante.ripristina(registro)
	await _aspetta(0.5)
	var tornata: Stampa = null
	for t in _stampe():
		if t.stato == Stampa.Stato.APPESA:
			tornata = t
	if tornata == null:
		_guasto("dopo il ripristino non c'è nessuna stampa appesa")
	else:
		var scarto := tornata.global_position.distance_to(posto.origin)
		print("[stampa]    tornata su %s, a %.2f mm da dov'era" % [tornata.get_parent().name, scarto * 1000.0])
		if tornata.get_parent() != su_cosa or scarto > 0.001:
			_guasto("il ripristino non l'ha rimessa sullo stesso muro allo stesso posto")

	# --- 7. LA CODA ------------------------------------------------------------
	prima = _stampe()
	Events.photo_revealed.emit(2, &"m13", 1)
	Events.photo_revealed.emit(3, &"m57", 3)
	await _aspetta(0.8)
	var terza := _nuova(prima)
	await _aspetta(3.0)
	var nuove := _stampe().filter(func(t: Stampa) -> bool: return not prima.has(t))
	print("[stampa] 7. due foto di fila: %d stampe nuove; la prima è %s a %s, si prende: %s" % [
		nuove.size(), Stampa.Stato.keys()[terza.stato] if terza != null else "-",
		_v(terza.global_position) if terza != null else "-",
		terza.si_riesce_a_prendere() if terza != null else false])
	if nuove.size() != 2:
		_guasto("due foto di fila non hanno fatto due stampe")
	if terza != null and (terza.stato != Stampa.Stato.LIBERA or not terza.si_riesce_a_prendere()):
		_guasto("la prima non strappata doveva cadere dove ci si arriva")

	_chiudi()


func _chiudi() -> void:
	# IL SAVE DI CHI GIOCA TORNA COM'ERA, o sparisce se prima non c'era.
	if _c_era_il_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(COPIA),
			ProjectSettings.globalize_path(SALVATAGGIO))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(COPIA))
	elif FileAccess.file_exists(SALVATAGGIO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SALVATAGGIO))
	print("[stampa] %s" % ("tutto a posto" if _guasti == 0 else "%d guasti" % _guasti))
	get_tree().quit(1 if _guasti > 0 else 0)
