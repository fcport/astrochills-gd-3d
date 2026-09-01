## Il quadro a muro apre la cupola? E smette di aprirla se ti allontani?
##
## DUE DOMANDE, E LA SECONDA È QUELLA CHE FA ESISTERE IL QUADRO. Che due pulsanti
## comandino un motore lo prova anche il banco. Il fatto che li si debba tenere
## premuti STANDO LÌ — che non si possa aprire la cupola da seduti in sala
## controllo — è l'intera ragione per cui la fase 1 ha lasciato il CRT (D-171), e
## se il vincolo di distanza non funzionasse la fase sarebbe tornata dov'era senza
## che nessuno se ne accorgesse.
##
## È una scena e non uno `--script`: carica il gioco vero, con la notte e
## l'orchestratore.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/prova_quadro.tscn
##
## Scrive user://quadro.png: il quadro visto da chi lo sta usando.
extends Node

const FUORI := "user://quadro.png"

## Quanto si aspetta al massimo che la cupola arrivi a fine corsa.
const LIMITE := 20.0

## Dove si mette il giocatore per usare il quadro, e dove lo si manda per provare
## che il comando si stacchi. Otto metri sono la sala controllo.
# Un metro e mezzo e non novanta centimetri: a novanta il quadro finisce dietro il
# riquadro del prompt, in basso al centro dello schermo, e la foto sembra mostrare
# un muro nudo. Resta comunque dentro i due metri di REACH.
const VICINO := 1.5
const LONTANO := 8.0

var _scena: Node
var _quadro: DomePanel
var _player: Node3D
var _tempo := 0.0
var _conto := 0
var _guasti := 0
var _finita := false
var _passo := 0
var _scattato := false


func _ready() -> void:
	_monta.call_deferred()


func _monta() -> void:
	Events.phase_finished.connect(func(chiave: StringName, punteggio: int) -> void:
		if chiave == &"dome":
			_finita = true
			print("[quadro] la fase 'dome' si è chiusa da sola con %d" % punteggio))
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

	if _quadro == null:
		_quadro = DomePanel.find_in(get_tree())
		_player = Player.find_in(get_tree())
		if _quadro == null or _player == null:
			print("[quadro] NON C'È IL QUADRO nel mondo (o non c'è il giocatore)")
			_fine()
			return
		print("[quadro] quadro a %s, giocatore a %s"
			% [_v(_quadro.global_position), _v(_player.global_position)])
		_chi_c_e_intorno()
		_avvicina(VICINO)
		return

	match _passo:
		0:
			# Prima di toccare niente: i pulsanti non devono comandare da soli.
			Input.action_press(&"dome_open")
			_verifica("il quadro non preso non comanda niente", _quadro.direction() == 0)
			_quadro.interact(_player)
			_verifica("dopo E il quadro è in mano", _quadro.is_active())
			_passo = 1
		1:
			# SI RIPREME OGNI FOTOGRAMMA: quando la finestra perde il fuoco, Godot
			# rilascia da sé tutte le azioni. È la lezione di `prova_vetro`.
			Input.action_press(&"dome_open")
			var s := DomeShutter.find_in(get_tree())
			if s == null:
				print("[quadro] NESSUN BATTENTE nel mondo")
				_fine()
				return
			if not _scattato and s.aperture() > 0.25:
				_scattato = true
				_scatta()
			if s.aperture() >= 0.999:
				print("[quadro] cupola aperta in %.2f s tenendo premuto" % _tempo)
				_passo = 2
			elif _tempo > LIMITE:
				print("[quadro] NON SI APRE: dopo %.0f s l'apertura è %.3f, comando %d"
					% [LIMITE, s.aperture(), _quadro.direction()])
				_fine()
			return
		2:
			_verifica("la fase si è chiusa da sola a fine corsa", _finita)
			# IL VINCOLO: si va in sala controllo col pulsante ancora premuto.
			_avvicina(LONTANO)
			_passo = 3
		3:
			Input.action_press(&"dome_open")
			_passo = 4
		4:
			_verifica("da otto metri il quadro si lascia da solo", not _quadro.is_active())
			_verifica("e il comando si stacca", _quadro.direction() == 0)
			Input.action_release(&"dome_open")
			print("[quadro] %s" % ("tutto a posto" if _guasti == 0
				else "%d COSE NON TORNANO" % _guasti))
			_fine()


## CHI C'È INTORNO AL QUADRO, e a che distanza.
##
## Serve perché la prima posa lo aveva messo DENTRO IL VANO DELLA PORTA, e dalla
## foto non si capiva: si vedeva una porta di legno e nessun quadro. Le tuple di
## `geometria.py` dicono dove comincia un vano, non dove finisce, e dedurre l'una
## dall'altra e' esattamente il modo in cui si sbaglia di mezzo metro.
func _chi_c_e_intorno() -> void:
	var qui := _quadro.global_position
	var vicini: Array[String] = []
	_raccogli(get_tree().root, qui, vicini)
	vicini.sort()
	print("[quadro] intorno al quadro, entro 1,2 m:")
	for r in vicini.slice(0, 10):
		print("[quadro]   %s" % r)


func _raccogli(n: Node, qui: Vector3, dentro: Array[String]) -> void:
	var t := n as Node3D
	if t != null and t != _quadro and not _quadro.is_ancestor_of(t):
		var d := t.global_position.distance_to(qui)
		if d < 1.2 and t.global_position != Vector3.ZERO:
			dentro.append("%.2f m  %-24s %s" % [d, t.name, _v(t.global_position)])
	for f in n.get_children():
		_raccogli(f, qui, dentro)


## Mette il giocatore a `quanto` metri dal quadro, dentro la stanza, e glielo fa
## GUARDARE: uno scatto preso senza girare la testa fotografa la parete dietro, e
## non prova che il quadro si veda. La prima stesura faceva cosi', e la foto
## mostrava due interruttori della luce a otto metri di distanza.
func _avvicina(quanto: float) -> void:
	var p := _quadro.global_position
	_player.global_position = Vector3(p.x, 0.0, p.z - quanto)
	# SOLO IMBARDATA, MAI BECCHEGGIO. `look_at` su un bersaglio piu' alto inclina
	# tutto il corpo, e la camera - che sta a un metro e settanta sopra i piedi -
	# finisce a guardare il tetto: la seconda foto era un soffitto. Il bersaglio si
	# mette alla quota del corpo, e il quadro entra in campo da se'.
	_player.look_at(Vector3(p.x, _player.global_position.y, p.z), Vector3.UP)


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
	print("[quadro] %s   <-- ATTESO, e non è così" % cosa)


func _v(p: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]


func _fine() -> void:
	get_tree().quit()
