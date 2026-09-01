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
const ATTACCO := "user://quadro_attacco.png"

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
var _gia_controllato := false
var _fermo_da := Vector3.INF
var _fermo_deriva := 0.0
var _tremito_da := Vector3.INF
var _tremito := 0.0
var _tremito_dopo := 0.0


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
			# A RIPOSO NON SI MUOVE, ed è il difetto che ha fatto buttare la versione
			# precedente: dondolava come un pendolo, il bersaglio scappava sotto il
			# mirino e il prompt lampeggiava a ogni oscillazione. Si guarda per mezzo
			# secondo senza toccare niente e si pretende che non cambi un millesimo.
			_mira(_apre)
			var qui := _apre.global_position
			if _fermo_da == Vector3.INF:
				_fermo_da = qui
			elif qui.distance_to(_fermo_da) > 0.0002:
				_guasti += 1
				_fermo_deriva = maxf(_fermo_deriva, qui.distance_to(_fermo_da))
			if _tempo - _da_quando > 0.5:
				if _fermo_deriva > 0.0:
					print("[quadro] A RIPOSO SI MUOVE DI %.1f mm   <-- ATTESO: ferma"
						% (_fermo_deriva * 1000.0))
				else:
					print("[quadro] ok: a riposo il comando sta fermo")
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
			_tieni_premuto(_apre)
			# DUE FINESTRE, E SERVONO TUTTE E DUE. La vibrazione deve esserci
			# SUBITO e non deve esserci DOPO: e' la differenza fra uno scatto di
			# partenza e una convulsione, e la prima versione che tremava sempre
			# passava un controllo scritto con la sola prima finestra.
			var ora := _apre.global_position
			if _tremito_da != Vector3.INF:
				var passo := ora.distance_to(_tremito_da)
				if _tempo - _da_quando < 0.40:
					_tremito = maxf(_tremito, passo)
				elif _tempo - _da_quando > 1.00:
					_tremito_dopo = maxf(_tremito_dopo, passo)
			_tremito_da = ora
			var s := DomeShutter.find_in(get_tree())
			if not _scattato and s != null and s.aperture() > 0.2:
				_scattato = true
				_scatta()
			if s != null and s.aperture() >= 0.999:
				print("[quadro] cupola aperta in %.2f s tenendo premuto APRE"
					% (_tempo - _da_quando))
				_verifica("il pulsante risulta schiacciato mentre lo tieni",
					_apre.is_held())
				# IL PROMPT SPARISCE MENTRE TIENI. «[E] Apri la cupola» che resta
				# scritto mentre la cupola si sta gia' aprendo si legge come «non
				# ha funzionato, ripremi»: il giocatore molla e ripreme a vuoto.
				# Il prompt e' funzione di `can_interact()`, quindi si verifica li'.
				_verifica("mentre tieni, il tasto non chiede piu' niente",
					not _apre.can_interact())
				# ALLA PARTENZA DA' UNO SCATTO. È l'altra metà del controllo «a
				# riposo sta fermo», che da solo lo passerebbe anche un oggetto
				# morto: si pretende un movimento che a riposo sarebbe un guasto.
				_verifica("alla partenza del motore il comando da' uno scatto",
					_tremito > 0.0002)
				# E POI LA PIANTA LI'. Questo è il controllo che manca alla versione
				# buttata: tremava per tutti i sei secondi dell'apertura, e a
				# schermo sembrava una convulsione. Un secondo dopo lo scatto, col
				# tasto ancora premuto, deve essere ferma come a riposo.
				_verifica("un secondo dopo, lo scatto è finito",
					_tremito_dopo <= 0.0002)
				print("[quadro] scatto %.2f mm nei primi 0,4 s, %.2f mm dopo un secondo"
					% [_tremito * 1000.0, _tremito_dopo * 1000.0])
				_molla()
				_avanti()
			elif int(_tempo - _da_quando) % 4 == 3 and _conto % 60 == 0:
				print("[quadro]   premuto %s  E premuto %s  giocatore acceso %s  a %.2f m"
					% [_apre.is_held(), Input.is_action_pressed(&"interact"),
						_player.get("_enabled"),
						_player.global_position.distance_to(_apre.global_position)])
			elif _tempo - _da_quando > LIMITE:
				print("[quadro] NON SI APRE: dopo %.0f s l'apertura e' %.3f, premuto %s"
					% [LIMITE, s.aperture() if s != null else -1.0, _apre.is_held()])
				_fine()
		3:
			# LASCIANDO IL TASTO IL MOTORE SI FERMA: è il comando a uomo presente.
			_verifica("mollato E, il pulsante si rialza", not _apre.is_held())
			_verifica("mollato E, il tasto torna a chiedere", _apre.can_interact())
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
			_tieni_premuto(_chiude)
			var s2 := DomeShutter.find_in(get_tree())
			if _tempo - _da_quando > 2.0:
				_molla()
				print("[quadro] due secondi di CHIUDE a fase finita: apertura %.3f"
					% s2.aperture())
				_verifica("a fase finita il pulsante CHIUDE chiude davvero",
					s2.aperture() < 0.98)
				_scatta_attacco()
				_avanti()
		6:
			# un fotogramma di respiro perche' la camera si assesti, poi la foto
			_scatta(ATTACCO)
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
	_chi_c_e_intorno()
	print("[quadro] camera: %s   strato del pulsante: %d   puo' interagire: %s"
		% ["c'e'" if _cam != null else "MANCA", _apre.collision_layer,
			_apre.can_interact()])
	_c_e_aria_davanti(_apre, "APRE")
	_c_e_aria_davanti(_chiude, "CHIUDE")
	_sporge_piu_di_quanto_rientra(_apre, "APRE")
	_sporge_piu_di_quanto_rientra(_chiude, "CHIUDE")
	return true


## IL CAPPUCCIO SPORGE PIU' DI QUANTO RIENTRA?
##
## Se la corsa supera la sporgenza, premendo il tasto SPARISCE dentro la propria
## targhetta: il giocatore lo tiene premuto e non vede piu' niente sotto il dito.
## E' successo - `TRAVEL` era 12 mm su un cappuccio che ne sporgeva 8 - e nessuno
## dei controlli di questa sonda lo vedeva: il pulsante risultava schiacciato, si
## rialzava, la cupola si apriva. Si e' visto SOLO guardando lo scatto, dove il
## tasto verde semplicemente non c'era, e il sintomo sembrava un problema di colore.
##
## Si misura sulle mesh: quanto il cappuccio avanza, lungo il proprio +Z, oltre il
## pezzo nero piu' avanzato (la targhetta e la ghiera, che sono lo stesso materiale).
func _sporge_piu_di_quanto_rientra(b: DomeButton, come: String) -> void:
	var modello := b.get_parent().get_node_or_null("Modello")
	if modello == null:
		return
	var avanti := b.global_transform.basis.z
	var cappuccio := _quanto_avanza(modello.get_node_or_null(NodePath(b.name)), avanti)
	# IL RIFERIMENTO E' LA TARGHETTA, e il nome del materiale conta. Misurava contro
	# `Gomma`, che era la targhetta finche' non l'ho separata: diventata `PlasticaNera`,
	# il confronto e' scivolato sul soffietto - che sta trenta centimetri piu' in su -
	# e la sporgenza «misurata» e' passata da 9 mm a 23. Il controllo continuava a
	# dire ok e non guardava piu' niente. Un controllo che si indebolisce da solo e'
	# peggio di uno che manca: quello che manca almeno si vede.
	var nero := _quanto_avanza(
		modello.get_node_or_null(NodePath("PlasticaNera")), avanti)
	var sporgenza := cappuccio - nero
	if sporgenza > DomeButton.TRAVEL:
		print("[quadro] ok: %s sporge %.0f mm e rientra di %.0f: resta visibile premuto"
			% [come, sporgenza * 1000.0, DomeButton.TRAVEL * 1000.0])
		return
	_guasti += 1
	print("[quadro] %s SPARISCE QUANDO LO PREMI: sporge %.0f mm e rientra di %.0f"
		% [come, sporgenza * 1000.0, DomeButton.TRAVEL * 1000.0]
		+ "   <-- ATTESO: sporgenza maggiore della corsa")


## Fin dove arriva una mesh lungo una direzione, in metri dall'origine del mondo.
func _quanto_avanza(n: Node, verso: Vector3) -> float:
	var m := n as MeshInstance3D
	if m == null:
		return 0.0
	var scatola := m.get_aabb()
	var piu_avanti := -INF
	for i in 8:
		piu_avanti = maxf(piu_avanti,
			(m.global_transform * scatola.get_endpoint(i)).dot(verso))
	return piu_avanti


## IL TASTO GUARDA DENTRO LA STANZA, O DENTRO IL MURO?
##
## E' il difetto che si e' gia' presentato due volte e che nessun altro controllo di
## questa sonda vede: un comando montato al contrario si trova lo stesso col raggio
## — il giocatore gli arriva dall'altra parte e ne colpisce il DIETRO — e si preme
## lo stesso. Passa tutto, e in gioco si vede una scatola gialla girata verso
## l'intonaco con i tasti sepolti dentro il muro.
##
## Si chiede al mondo tirando un raggio dal centro del tasto NEL VERSO IN CUI IL
## CAPPUCCIO SPORGE: davanti a un comando ci deve essere aria. Mezzo metro basta,
## ed e' meno della portata del braccio.
func _c_e_aria_davanti(b: DomeButton, come: String) -> void:
	var avanti := b.global_transform.basis.z
	var q := PhysicsRayQueryParameters3D.create(
		b.global_position, b.global_position + avanti * 0.5)
	q.collision_mask = Interactable.LAYER_WORLD
	var urto := _cam.get_world_3d().direct_space_state.intersect_ray(q)
	if urto.is_empty():
		print("[quadro] ok: %s sporge verso la stanza" % come)
		return
	_guasti += 1
	print("[quadro] %s SPORGE CONTRO %s a %.2f m   <-- ATTESO: aria davanti al tasto"
		% [come, (urto["collider"] as Node).name,
			b.global_position.distance_to(urto["position"] as Vector3)])


## CHI C'E' INTORNO AL QUADRO, e a che distanza.
##
## Gia' servita due volte: la prima posa era dentro il vano di una porta, la seconda
## dietro l'angolo di uno stipite. Le tuple di `geometria.py` dicono dove comincia un
## muro, non che cosa gli sta appeso, e dedurre l'una dall'altra e' il modo in cui si
## sbaglia di mezzo metro.
func _chi_c_e_intorno() -> void:
	var qui := _apre.global_position
	var vicini: Array[String] = []
	_raccogli(get_tree().root, qui, vicini)
	vicini.sort()
	print("[quadro] intorno al pulsante, entro 1,5 m:")
	for r in vicini.slice(0, 14):
		print("[quadro]   %s" % r)


func _raccogli(n: Node, qui: Vector3, dentro: Array[String]) -> void:
	var t := n as Node3D
	if t != null and not (t is DomeButton) and t.global_position != Vector3.ZERO:
		var d := t.global_position.distance_to(qui)
		if d < 1.5:
			dentro.append("%.2f m  %-22s %-24s %s"
				% [d, t.name, t.get_parent().name if t.get_parent() != null else "-",
					_v(t.global_position)])
	for f in n.get_children():
		_raccogli(f, qui, dentro)


## Mette il giocatore davanti al pulsante e glielo fa guardare.
##
## LA TESTA E IL CORPO SI GIRANO SEPARATAMENTE: il corpo fa l'imbardata, la camera
## il beccheggio. Girando tutto il corpo verso un bersaglio più alto dei piedi si
## inclina anche la camera, che sta un metro e settanta più su, e si finisce a
## fotografare il tetto — già pagato una volta.
func _mira(b: DomeButton) -> void:
	var p := b.global_position
	# DAVANTI AL PULSANTE, LUNGO LA SUA NORMALE, e non «un po' piu' a sud»: il
	# comando sta sul muro ovest e guarda verso +X. La prima stesura metteva il
	# giocatore sempre a -Z e lo faceva guardare di taglio: nella foto si vedeva il
	# quadro di profilo e mezzo schermo dentro il muro.
	#
	# IL VERSO E' +Z E NON -Z: il cappuccio sporge lungo il proprio +Z, ed e' quello
	# il davanti. Con il segno vecchio - che era giusto per il quadro di primitive,
	# fatto al contrario - la sonda piazzava il giocatore DENTRO IL MURO, dall'altra
	# parte. Tutti i controlli passavano lo stesso (fuori dall'edificio c'e' aria, e
	# il raggio della sonda il pulsante lo trovava) e falliva solo la pressione
	# vera, perche' il raggio DEL GIOCATORE sbatteva prima nell'intonaco.
	var davanti := b.global_transform.basis.z
	davanti = Vector3(davanti.x, 0.0, davanti.z).normalized()
	var dove := p + davanti * VICINO
	_player.global_position = Vector3(dove.x, 0.0, dove.z)
	_player.look_at(Vector3(p.x, 0.0, p.z), Vector3.UP)
	if _cam != null:
		_cam.look_at(p, Vector3.UP)
	if not _gia_controllato:
		_gia_controllato = true
		_c_e_da_stare_in_piedi(dove)


## DAVANTI AL COMANDO CI SI STA IN PIEDI?
##
## E' il vincolo che due pose sbagliate di fila non hanno rispettato, e che nessuna
## tupla di `geometria.py` contiene: un quadro puo' essere su un muro libero e avere
## davanti la passerella, il parapetto o un mobile. Si chiede al motore, con la
## stessa capsula del giocatore.
func _c_e_da_stare_in_piedi(dove: Vector3) -> void:
	var forma := CapsuleShape3D.new()
	forma.radius = 0.30
	forma.height = 1.80
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = forma
	# ALZATA DI CINQUE CENTIMETRI: una capsula che tocca il pavimento conta il
	# pavimento come intersezione, e direbbe «occupato» dappertutto.
	q.transform = Transform3D(Basis.IDENTITY, Vector3(dove.x, 0.95, dove.z))
	q.collision_mask = Interactable.LAYER_WORLD
	q.exclude = [_player.get_rid()]
	var urti := _cam.get_world_3d().direct_space_state.intersect_shape(q, 8)
	var nomi: Array[String] = []
	for u in urti:
		var n := u["collider"] as Node
		if n != null and not (n is DomeButton) and n.name != "Modello":
			nomi.append(n.name)
	if nomi.is_empty():
		print("[quadro] ok: davanti al comando si sta in piedi")
	else:
		_guasti += 1
		print("[quadro] DAVANTI AL COMANDO NON CI SI STA: %s   <-- ATTESO: libero"
			% ", ".join(nomi))


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
func _tieni_premuto(b: DomeButton) -> void:
	# LO STATO SI TIENE, L'EVENTO SI RIPETE FINCHE' NON FA PRESA. Il raggio del
	# giocatore si aggiorna nel tick di FISICA: l'evento mandato nel fotogramma in
	# cui la sonda lo ha appena spostato arriva a un raggio che punta ancora dove
	# stava prima, e va perso. Un giocatore vero ripreme; questa sonda anche.
	Input.action_press(&"interact")
	if b.is_held():
		return
	var e := InputEventAction.new()
	e.action = &"interact"
	e.pressed = true
	Input.parse_input_event(e)


func _molla() -> void:
	Input.action_release(&"interact")


func _avanti() -> void:
	_passo += 1
	_da_quando = _tempo


func _scatta(dove: String = FUORI) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(dove)
		print("[quadro] scatto in %s" % ProjectSettings.globalize_path(dove))


## LA SECONDA FOTO GUARDA L'ATTACCO, e serve quanto la prima.
##
## Il cavo esce da una scatola di derivazione un metro sopra i tasti: inquadrando
## il pulsante non ci si vede mai, e per un giro intero e' rimasta un cubo grigio
## che nessuno guardava perche' nessuna foto la conteneva. Si scatta da tre passi
## indietro, con la camera alzata sull'attacco.
func _scatta_attacco() -> void:
	if _cam == null:
		return
	var p := _apre.global_position
	var avanti := _apre.global_transform.basis.z
	avanti = Vector3(avanti.x, 0.0, avanti.z).normalized()
	var dove := p + avanti * 1.9
	_player.global_position = Vector3(dove.x, 0.0, dove.z)
	_player.look_at(Vector3(p.x, 0.0, p.z), Vector3.UP)
	_cam.look_at(Vector3(p.x, p.y + 0.45, p.z), Vector3.UP)


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
