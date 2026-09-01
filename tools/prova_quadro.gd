## I due pulsanti della cupola: si MIRANO e si tengono premuti, come nel gioco.
##
## PERCHÉ QUESTA SONDA È STATA RIFATTA. La prima chiamava `interact()` sul quadro a
## mano, saltando il raggio con cui il giocatore trova le cose. Diceva «tutto a
## posto» su un oggetto che in gioco non rispondeva: il raggio arriva a 1,20 m e il
## quadro stava a 1,35 di altezza, cioè sotto la linea di mira di chi guarda
## avanti. Una sonda che salta il pezzo che si rompe non è una sonda.
##
## Adesso si fa quello che fa il giocatore: gli si mette la testa davanti al
## pulsante, gli si fa mirare, e si tiene premuto `E`. Se il raggio non lo trova,
## la sonda lo dice.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/prova_quadro.tscn
##
## Scrive user://quadro.png: il quadro visto da chi lo sta usando.
extends Node

const FUORI := "user://quadro.png"

## Quanto si aspetta al massimo che la cupola arrivi a fine corsa.
const LIMITE := 20.0

## A che distanza si mette il giocatore. Sotto la portata del raggio (1,20 m).
const VICINO := 0.85

var _scena: Node
var _player: Node3D
var _cam: Camera3D
var _apre: DomeButton
var _chiude: DomeButton
var _tempo := 0.0
var _conto := 0
var _guasti := 0
var _passo := 0
var _da_quando := 0.0
var _scattato := false


func _ready() -> void:
	_monta.call_deferred()


func _monta() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	_scena = scena


func _process(d: float) -> void:
	if _scena == null:
		return
	_conto += 1
	_tempo += d
	if _conto < 5:
		return

	if _apre == null and not _trova():
		return

	match _passo:
		0:
			_mira(_apre)
			_avanti()
		1:
			# SI RIMIRA A OGNI FOTOGRAMMA. Dopo il teletrasporto la capsula del
			# giocatore si assesta sul pavimento di un centimetro, e la mira fatta un
			# frame prima non punta piu' dove puntava: il raggio passava quattro gradi
			# sopra il pulsante e trovava la scatola dietro.
			_mira(_apre)
			# IL RAGGIO LO TROVA? È la domanda che la prima sonda non ha mai fatto.
			var visto := _mirato()
			_verifica("mirando APRE il raggio trova il pulsante giusto", visto == _apre)
			if visto != null:
				print("[quadro] il prompt dice: «%s»" % visto.prompt())
			_avanti()
		2:
			_mira(_apre)
			_tieni_premuto()
			var s := DomeShutter.find_in(get_tree())
			if not _scattato and s != null and s.aperture() > 0.2:
				_scattato = true
				_scatta()
			if s != null and s.aperture() >= 0.999:
				print("[quadro] cupola aperta in %.2f s tenendo premuto APRE"
					% (_tempo - _da_quando))
				_verifica("il pulsante risulta schiacciato mentre lo tieni",
					_apre.is_held())
				_molla()
				_avanti()
			elif _tempo - _da_quando > LIMITE:
				print("[quadro] NON SI APRE: dopo %.0f s l'apertura e' %.3f, premuto %s"
					% [LIMITE, s.aperture() if s != null else -1.0, _apre.is_held()])
				_fine()
		3:
			# LASCIANDO IL TASTO IL MOTORE SI FERMA: è il comando a uomo presente.
			_verifica("mollato E, il pulsante si rialza", not _apre.is_held())
			_mira(_chiude)
			_avanti()
		4:
			_mira(_chiude)
			_verifica("mirando CHIUDE il raggio trova l'altro pulsante",
				_mirato() == _chiude)
			_avanti()
		5:
			_mira(_chiude)
			# E QUI SI PROVA LA COSA CHE PRIMA NON FUNZIONAVA: la fase 1 è finita da
			# un pezzo, e il quadro deve comandare lo stesso.
			_tieni_premuto()
			var s2 := DomeShutter.find_in(get_tree())
			if _tempo - _da_quando > 2.0:
				_molla()
				print("[quadro] due secondi di CHIUDE a fase finita: apertura %.3f"
					% s2.aperture())
				_verifica("a fase finita il pulsante CHIUDE chiude davvero",
					s2.aperture() < 0.98)
				print("[quadro] %s" % ("tutto a posto" if _guasti == 0
					else "%d COSE NON TORNANO" % _guasti))
				_fine()


func _trova() -> bool:
	_player = Player.find_in(get_tree())
	if _player == null:
		print("[quadro] NON C'E' IL GIOCATORE")
		_fine()
		return false
	_cam = _player.camera()
	for b in DomeButton.all_in(get_tree()):
		var p := b as DomeButton
		if p.direction > 0:
			_apre = p
		else:
			_chiude = p
	if _apre == null or _chiude == null:
		print("[quadro] NON CI SONO I DUE PULSANTI nel mondo")
		_fine()
		return false
	print("[quadro] APRE a %s, CHIUDE a %s"
		% [_v(_apre.global_position), _v(_chiude.global_position)])
	print("[quadro] camera: %s   strato del pulsante: %d   puo' interagire: %s"
		% ["c'e'" if _cam != null else "MANCA", _apre.collision_layer,
			_apre.can_interact()])
	return true


## Mette il giocatore davanti al pulsante e glielo fa guardare.
##
## LA TESTA E IL CORPO SI GIRANO SEPARATAMENTE: il corpo fa l'imbardata, la camera
## il beccheggio. Girando tutto il corpo verso un bersaglio più alto dei piedi si
## inclina anche la camera, che sta un metro e settanta più su, e si finisce a
## fotografare il tetto — già pagato una volta.
func _mira(b: DomeButton) -> void:
	var p := b.global_position
	_player.global_position = Vector3(p.x, 0.0, p.z - VICINO)
	_player.look_at(Vector3(p.x, 0.0, p.z), Vector3.UP)
	if _cam != null:
		_cam.look_at(p, Vector3.UP)


## Che cosa sta guardando adesso il giocatore, chiesto al mondo con un raggio come
## il suo: stessa origine, stessa portata, stesso strato.
func _mirato() -> DomeButton:
	if _cam == null:
		return null
	var spazio := _cam.get_world_3d().direct_space_state
	var da := _cam.global_position
	var a := da - _cam.global_transform.basis.z * Player.INTERACT_RANGE
	var q := PhysicsRayQueryParameters3D.create(da, a)
	q.collision_mask = Interactable.LAYER_INTERACTABLE
	q.collide_with_areas = false
	var hit := spazio.intersect_ray(q)
	if hit.is_empty():
		# SENZA MASCHERA, per sapere se il raggio non colpisce NIENTE o colpisce
		# qualcos'altro: sono due guasti diversi con lo stesso sintomo.
		var q2 := PhysicsRayQueryParameters3D.create(da, a)
		var h2 := spazio.intersect_ray(q2)
		print("[quadro]   il raggio da %s verso %s non trova interagibili; senza filtro: %s"
			% [_v(da), _v(a), h2["collider"].name if not h2.is_empty() else "niente"])
		return null
	return hit["collider"] as DomeButton


## Tiene premuto `E`. Serve sia lo STATO (che il pulsante legge ogni fotogramma)
## sia l'EVENTO (che il giocatore trasforma in `interact`): `action_press` da sola
## non genera eventi, e `parse_input_event` da sola non lascia lo stato premuto.
func _tieni_premuto() -> void:
	if not Input.is_action_pressed(&"interact"):
		Input.action_press(&"interact")
		var e := InputEventAction.new()
		e.action = &"interact"
		e.pressed = true
		Input.parse_input_event(e)


func _molla() -> void:
	Input.action_release(&"interact")


func _avanti() -> void:
	_passo += 1
	_da_quando = _tempo


func _scatta() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(FUORI)
		print("[quadro] scatto in %s" % ProjectSettings.globalize_path(FUORI))


func _verifica(cosa: String, vero: bool) -> void:
	if vero:
		print("[quadro] ok: %s" % cosa)
		return
	_guasti += 1
	print("[quadro] %s   <-- ATTESO, e non e' cosi'" % cosa)


func _v(p: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]


func _fine() -> void:
	get_tree().quit()
