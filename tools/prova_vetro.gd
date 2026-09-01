## Il pannello di una fase finisce DENTRO il monitor, o vive solo nelle sonde?
##
## LA DOMANDA NON SI CHIUDE LEGGENDO IL CODICE. Le sonde delle singole fasi —
## `prova_fuoco` per prima — staccano il pannello e se lo mettono in un
## `CanvasLayer` ingrandito tre volte: serve a giudicare il DISEGNO a 256x192, e
## non prova niente sul gioco. Che quel `Control` finisca poi nel `SubViewport` del
## CRT lo fa una riga sola, in `night/night_session.gd`, e una riga sola si può
## sempre rompere senza che nessuna delle sonde di fase se ne accorga.
##
## QUESTA SONDA NON MONTA NIENTE. Carica il gioco vero, si siede al monitor come
## farebbe il giocatore, gioca la notte — apre la cupola tenendo premuto, poi INVIO
## a ogni fase — finché arriva quella chiesta, e fotografa la FINESTRA INTERA. Se
## il pannello è nel vetro, si vede nel vetro, in mezzo alla stanza.
##
## È una scena e non uno `--script`: senza autoload non c'è né `Events` né la notte.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/prova_vetro.tscn
##
## FINO=<chiave> si ferma a quella fase invece che al fuoco.
## Scrive user://vetro.png.
extends Node

const FUORI := "user://vetro.png"

## Oltre questo tempo si smette e si dice a che fase si era rimasti.
const LIMITE := 90.0

## Quanto si aspetta prima di premere INVIO su una fase che si vuole solo passare.
## Non zero: una fase appena montata non ha ancora disegnato niente, e chiuderla
## nel fotogramma in cui nasce proverebbe che la notte scorre, non che si vede.
const RESPIRO := 1.6

## COME SI SUPERA LA FASE DELL'ACCENSIONE, che con il solo INVIO non finisce mai:
## il cursore resta sulla prima riga e le altre due non le collega nessuno. Accendi
## e collega la montatura, scendi, accendi e collega la camera, scendi, collega la
## ruota, e l'ultimo INVIO chiude. Non e' una scorciatoia: e' esattamente quello che
## fa il giocatore, tasto per tasto.
const COPIONE_STARTUP: Array[StringName] = [
	&"startup_act", &"startup_act", &"startup_down",
	&"startup_act", &"startup_act", &"startup_down",
	&"startup_act", &"startup_act",
]

## Quanto si gioca la fase d'arrivo prima dello scatto. Al fuoco serve: un
## pannello fotografato appena montato mostra il riquadro del grafico vuoto, cioè
## la meta' meno interessante di quello che si vuole guardare.
const ASSAGGIO := 2.5

var _scena: Node
var _fino := &"focus"
var _corrente := &""
var _tempo := 0.0
var _da_quando := 0.0
var _ultimo_invio := 0.0
var _conto := 0
var _seduto := false
var _premuto := false
var _arrivato := false
var _ultimo_secondo := 0
var _battuta := 0
var _posto := Vector3.INF


func _ready() -> void:
	_monta.call_deferred()


func _monta() -> void:
	var quale := OS.get_environment("FINO")
	if not quale.is_empty():
		_fino = StringName(quale)
	print("[vetro] fino alla fase '%s'" % _fino)
	# L'ASCOLTO PRIMA DELL'ALBERO, e non è pignoleria: `add_child()` esegue il
	# `_ready()` del gioco lì per lì, e quel `_ready()` avvia la notte e monta la
	# prima fase. Collegandosi dopo, l'annuncio della cupola era gia' passato e la
	# sonda restava novanta secondi ad aspettare una fase che stava lavorando.
	Events.phase_started.connect(_su_fase)
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	_scena = scena


func _process(d: float) -> void:
	if _scena == null:
		return
	_conto += 1
	if _arrivato:
		# Sei fotogrammi di margine: il `SubViewport` del CRT non ridisegna a
		# comando, e uno scatto preso troppo presto fotografa il fotogramma prima.
		if _conto > 6:
			_scatta()
		return

	_tempo += d
	if _posto == Vector3.INF:
		var p0 := Player.find_in(get_tree())
		if p0 != null:
			# DOVE SI ERA, prima di andare in cupola: la sedia sta li', e chi non ci
			# torna fotografa un muro. La prima stesura di questa sonda si sedeva
			# subito e poi si teletrasportava al quadro, e lo scatto finale inquadrava
			# il quadro della cupola invece del monitor.
			_posto = p0.global_position
		return
	if _tempo > LIMITE:
		print("[vetro] NON CI SI ARRIVA: dopo %.0f s si è fermi su '%s'"
			% [LIMITE, _corrente if _corrente != &"" else &"nessuna fase"])
		_fine()
		return
	if _corrente == &"":
		return

	if _corrente == _fino:
		# La fase d'arrivo si gioca un poco, poi si fotografa.
		if _tempo - _da_quando < ASSAGGIO:
			if _fino == &"focus":
				Input.action_press(&"focus_out")     # vedi `_apri_la_cupola`
			return
		Input.action_release(&"focus_out")
		_arrivato = true
		_conto = 0
		return

	if _corrente == &"dome":
		_apri_la_cupola()
		return
	_avanza()


## Si siede come il giocatore: `E` sul monitor. Chi monta le fasi è il piano della
## notte, che qui non si tocca — è tutto il senso di questa sonda.
func _siediti() -> void:
	var monitor := CrtMonitor.find_in(get_tree())
	if monitor == null:
		print("[vetro] NESSUN MONITOR nel gioco")
		_fine()
		return
	monitor.interact(Player.find_in(get_tree()))
	_seduto = true
	print("[vetro] seduti dopo %.2f s" % _tempo)


## La cupola non si passa con INVIO: la fase non lascia uscire finché non è aperta.
## SI RIPREME A OGNI FOTOGRAMMA, e non e' ridondanza: quando la finestra perde il
## fuoco — cioe' quasi sempre, se la si lancia mentre si lavora in un'altra —
## Godot rilascia da se' tutte le azioni premute. Premuto una volta sola, il
## comando spariva e il referto diceva «battente 0.000, tasto false, fase gira»:
## il meccanismo era sano, era la mano della sonda ad aprirsi.
func _apri_la_cupola() -> void:
	# LA CUPOLA SI APRE DAL QUADRO IN CUPOLA (D-171, D-174): si mira il pulsante
	var quadro := _pulsante_apre()
	if quadro == null:
		print("[vetro] NON C'E' IL PULSANTE della cupola")
		_fine()
		return
	var p := Player.find_in(get_tree())
	if p == null:
		print("[vetro] NON C'E' IL GIOCATORE")
		_fine()
		return
	# SI RIMIRA A OGNI FOTOGRAMMA: dopo il teletrasporto la capsula si assesta, e
	# una mira vecchia di un frame passa sopra il pulsante.
	var q := quadro.global_position
	# DAVANTI AL PULSANTE, LUNGO LA SUA NORMALE: il quadro sta sul muro ovest e
	# guarda verso +X, e chi si mettesse «un po' piu' a sud» lo vedrebbe di taglio.
	var davanti := -quadro.global_transform.basis.z
	davanti = Vector3(davanti.x, 0.0, davanti.z).normalized()
	var dove := q + davanti * 0.85
	p.global_position = Vector3(dove.x, 0.0, dove.z)
	p.look_at(Vector3(q.x, 0.0, q.z), Vector3.UP)
	var cam := p.camera()
	if cam != null:
		cam.look_at(q, Vector3.UP)
	# Lo stato si tiene, l'evento si ripete finche' non fa presa: il raggio del
	# giocatore si aggiorna nel tick di fisica, e il primo `E` dopo un teletrasporto
	# arriva a un raggio che punta ancora dove stava prima.
	Input.action_press(&"interact")
	if not quadro.is_held():
		var e := InputEventAction.new()
		e.action = &"interact"
		e.pressed = true
		Input.parse_input_event(e)
	var s := DomeShutter.find_in(get_tree())
	if s == null:
		print("[vetro] NESSUN BATTENTE nel gioco")
		_fine()
		return
	if int(_tempo) > _ultimo_secondo:
		_ultimo_secondo = int(_tempo)
		print("[vetro]   %2d s: battente %.3f  pulsante premuto %s"
			% [_ultimo_secondo, s.aperture(), quadro.is_held()])
	if s.aperture() >= 0.999:
		Input.action_release(&"interact")


## Il pulsante che apre, fra i due del quadro.
func _pulsante_apre() -> DomeButton:
	for b in DomeButton.all_in(get_tree()):
		var p := b as DomeButton
		if p != null and p.direction > 0:
			return p
	return null

## INVIO, e non una volta sola: una fase che non l'ha ancora ricevuto — perché
## stava nascendo, perché il gating dell'input non era ancora acceso — resterebbe
## lì per sempre, e la sonda direbbe «fermi su polar» per una ragione che non è
## quella che sta cercando.
func _avanza() -> void:
	if _tempo - _da_quando < RESPIRO or _tempo - _ultimo_invio < RESPIRO:
		return
	_ultimo_invio = _tempo
	if _corrente == &"startup":
		if _battuta < COPIONE_STARTUP.size():
			_manda(COPIONE_STARTUP[_battuta])
			_battuta += 1
			return
	# UN TASTO E NON UN'AZIONE. `action_press` non genera nessun evento — mette solo
	# lo stato — e le conferme si leggono in `_unhandled_input`, che senza evento non
	# viene mai chiamato. Ma nemmeno un `InputEventAction` va bene: si riconosce dal
	# NOME dell'azione, e `dome_confirm` non e' `polar_finish` anche se stanno sullo
	# stesso tasto. La sonda deve premere INVIO, non nominare l'azione: cosi' ogni
	# fase ci legge la propria conferma, com'e' scritto in `project.godot`.
	var e := InputEventKey.new()
	e.physical_keycode = KEY_ENTER
	e.pressed = true
	Input.parse_input_event(e)


## Manda un'azione per nome. Serve alle fasi che hanno piu' di un tasto: il tasto
## fisico va bene per le conferme, ma non per dire «scendi di una riga».
func _manda(azione: StringName) -> void:
	var e := InputEventAction.new()
	e.action = azione
	e.pressed = true
	Input.parse_input_event(e)


## Se la fase montata sta girando o e' sospesa. Una fase sospesa non legge tasti.
func _stato_fase() -> String:
	var sess := get_tree().get_first_node_in_group(&"night_session")
	var p := _trova_fase(get_tree().root)
	if p == null:
		return "non trovata"
	return "gira" if p.can_process() else "SOSPESA"


func _trova_fase(n: Node) -> Phase:
	var p := n as Phase
	if p != null:
		return p
	for f in n.get_children():
		var t := _trova_fase(f)
		if t != null:
			return t
	return null


func _su_fase(chiave: StringName) -> void:
	print("[vetro] %5.2f s  fase '%s' montata sul vetro" % [_tempo, chiave])
	_corrente = chiave
	_da_quando = _tempo
	_premuto = false
	if chiave != &"dome" and not _seduto:
		# La cupola e' aperta: si torna alla postazione e ci si siede, che e' quello
		# che il giocatore fa appena finito di tenere premuto.
		var p0 := Player.find_in(get_tree())
		if p0 != null and _posto != Vector3.INF:
			p0.global_position = _posto
		_siediti()
	if chiave == _fino and chiave == &"focus":
		# Si muove il focheggiatore, se no il grafico è un riquadro vuoto.
		Input.action_press(&"focus_out")


func _scatta() -> void:
	if DisplayServer.get_name() == "headless":
		print("[vetro] headless: nessuno scatto")
		_fine()
		return
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(FUORI)
		print("[vetro] scatto in %s" % ProjectSettings.globalize_path(FUORI))
	_fine()


func _fine() -> void:
	get_tree().quit()
