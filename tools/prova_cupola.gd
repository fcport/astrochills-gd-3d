## La cupola si apre davvero? Si misura, e si fotografa.
##
## SERVONO TUTTE E DUE. I numeri dicono se i battenti si sono spostati di quanto
## dovevano — ed è l'unica cosa che un banco può sapere — ma non dicono se dal
## pavimento della cupola si vede il cielo, che è precisamente ciò per cui la fase
## 1 esiste. Due lastre che si scostano perfettamente e lasciano vedere il tetto di
## sopra sarebbero corrette in ogni loro numero.
##
## È UNA SCENA E NON UNO `--script`, ed è obbligatorio: `--script` non monta gli
## autoload, e senza `Events` nessuno annuncia niente — i battenti resterebbero
## chiusi e la sonda direbbe che il meccanismo è rotto.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/prova_cupola.tscn
##
## MONDO=res://world/blockout.tscn prova la cupola MODELLATA invece di quella
## segnaposto del vecchio osservatorio. Sono due meccanismi diversi — due lastre che
## scorrono contro due gusci che ruotano — e lo stesso nodo li muove entrambi:
## provarne uno solo vorrebbe dire provarne mezzo.
## DA=x,y,z A=x,y,z guarda la cupola DA FUORI invece che dal pavimento. Serve a
## giudicare il MOVIMENTO: da sotto, di notte, due gusci scuri su un guscio scuro
## non si distinguono, e una foto nera non prova niente in nessuna delle due
## direzioni. SOLE=<energia> alza la luna finche' la forma si vede.
## PARTITA=1 carica IL GIOCO — `main.tscn`, con la notte e l'orchestratore — si
## siede al monitor come farebbe il giocatore e tiene premuto il comando. È la
## prova che conta davvero: monta le fasi il piano della notte, non la sonda, e se
## la cupola non fosse la prima non si aprirebbe niente.
## FASE=1 non annuncia niente da sé: monta la FASE VERA, le tiene premuto il
## comando, e guarda se la cupola si apre. È l'unica prova che copre la catena
## intera — pannello, bus, battenti — invece delle sue due metà separate.
## APERTURA=<0..1> prova una corsa parziale invece della fine corsa.
## CHIUSA=1 fotografa senza aprire niente: è il confronto, e senza confronto una
## foto del cielo non prova che prima non si vedesse.
##
## Scrive user://cupola.png, cioè
## %APPDATA%/Godot/app_userdata/<progetto>/cupola.png
extends Node

const FUORI := "user://cupola.png"

## Quanto si aspetta al massimo che i battenti arrivino, in SECONDI.
##
## SI ASPETTA IL FATTO, NON UN CONTEGGIO DI FOTOGRAMMI. Questa finestra non ha il
## vsync e ne macina cinquecento al secondo: contare i fotogrammi vuol dire
## misurare la macchina, non il meccanismo. È lo stesso errore già pagato dalla
## sonda della postazione, e la correzione è la stessa.
const LIMITE := 12.0

## `Node` e non `Node3D`: in partita la scena caricata è `main.tscn`, la cui radice
## è un `Node` semplice — il mondo 3D vive dentro il suo SubViewport. Tipizzarla
## come `Node3D` faceva morire la sonda all'assegnazione, prima di misurare.
var _scena: Node
var _fase := 0
var _conto := 0
var _tempo := 0.0
var _partenza: Array[Vector3] = []
var _bersaglio := 1.0
var _fase_vera: Phase
var _partita := false
var _premuto := false
var _ultimo_secondo := 0


func _ready() -> void:
	# Differito: dentro `_ready()` la radice sta ancora montando i propri figli e
	# `add_child()` viene rifiutato.
	_monta.call_deferred()


func _monta() -> void:
	var quale := OS.get_environment("MONDO")
	if quale.is_empty():
		quale = "res://world/observatory.tscn"
	print("[cupola] mondo: %s" % quale)
	var scena: Node = load(quale).instantiate()
	# PRIMA in albero, POI scena corrente: `set_current_scene()` rifiuta un nodo che
	# non sia già figlio della radice. E non `change_scene_to_file()`, che libererebbe
	# la scena corrente — cioè questa sonda, che sparirebbe prima di misurare.
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	_scena = scena


func _process(d: float) -> void:
	if _scena == null:
		return
	_conto += 1

	if _fase == 0 and _conto > 4:
		_fase = 1
		_conto = 0
		var s := DomeShutter.find_in(get_tree())
		if s == null:
			print("[cupola] NESSUN BATTENTE: il gruppo '%s' è vuoto" % DomeShutter.GROUP)
			_fine()
			return
		var lastre := _lastre(s)
		if lastre.is_empty():
			print("[cupola] il battente non ha lastre risolte: NodePath sbagliato?")
			_fine()
			return
		for n in lastre:
			_partenza.append(_ingombro(n).get_center())
			print("[cupola] %-14s chiusa, baricentro a %s" % [n.name, _v(_ingombro(n).get_center())])
		_fessura(lastre, "da chiusa")

		_inquadra(lastre)
		if not OS.get_environment("CHIUSA").is_empty():
			_fase = 3
			return
		var a := OS.get_environment("APERTURA")
		_bersaglio = clampf(float(a), 0.0, 1.0) if not a.is_empty() else 1.0
		if not OS.get_environment("PARTITA").is_empty():
			_siediti()
			return
		if not OS.get_environment("FASE").is_empty():
			_monta_la_fase()
			return
		# Si annuncia il FATTO, esattamente come lo annuncia la fase: la sonda non
		# tocca il battente, gli parla nella sola lingua che conosce.
		Events.dome_aperture_changed.emit(_bersaglio)
		return

	if _fase == 1:
		# UN SOLO POSTO DOVE SCORRE IL TEMPO. La prima stesura ne aveva due — il
		# ramo «partita» e questo — e dopo la pressione ci passava tutti e due nello
		# stesso fotogramma: l'orologio della sonda correva al doppio, e la cupola
		# sembrava aprirsi a meta' velocita'. Il meccanismo era giusto, la misura no,
		# e per tre giri ho cercato il guasto dalla parte sbagliata.
		_tempo += d
		if _partita and not _premuto:
			var banco := _trova_banco(get_tree().root)
			if banco != null and banco.is_seated:
				print("[cupola] seduti dopo %.2f s: tengo premuto il comando" % _tempo)
				Input.action_press(&"dome_open")
				_premuto = true
			elif _tempo > LIMITE:
				print("[cupola] NON CI SI SIEDE dopo %.1f s" % LIMITE)
				_fine()
			return
		var s := DomeShutter.find_in(get_tree())
		# UN RIGO AL SECONDO MENTRE SI APRE. Una sonda che stampa solo l'esito dice
		# «non ci e' arrivata» e non dice se e' andata piano, se si e' fermata, o se
		# non e' mai partita: tre guasti diversi con lo stesso referto.
		if int(_tempo) > _ultimo_secondo:
			_ultimo_secondo = int(_tempo)
			var f := _trova_fase(get_tree().root)
			print("[cupola]   %2d s: battente %.3f  pannello %s  scala %.2f  comando %s"
				% [_ultimo_secondo, s.aperture(),
					("%.3f" % f.aperture()) if f != null else "-",
					Engine.time_scale, Input.is_action_pressed(&"dome_open")])
		if absf(s.aperture() - _bersaglio) > 0.001 and _tempo < LIMITE:
			return
		if absf(s.aperture() - _bersaglio) > 0.001:
			print("[cupola] NON ARRIVATO dopo %.1f s: apertura %.3f invece di %.3f"
				% [LIMITE, s.aperture(), _bersaglio])
			_fine()
			return
		_fase = 2
		_conto = 0
		var lastre := _lastre(s)
		print("[cupola] apertura %.2f raggiunta in %.2f s" % [_bersaglio, _tempo])
		if _fase_vera != null or _partita:
			# Il comando si lascia e si preme INVIO, come farebbe il giocatore: è
			# l'ultimo anello, e senza di lui «la fase finisce» resterebbe una cosa
			# scritta nel codice e mai vista succedere.
			#
			# DUE MECCANISMI DIVERSI PER DUE LETTURE DIVERSE, e confonderli costa un
			# pomeriggio. `Input.action_press` cambia lo STATO dell'input e non
			# genera nessun evento: va benissimo per il comando del motore, che la
			# fase legge con `is_action_pressed`. Ma INVIO la fase lo legge in
			# `_unhandled_input`, cioè dagli EVENTI, e lì `action_press` non arriva
			# mai — la sonda restava a guardare una fase che non si chiudeva.
			Input.action_release(&"dome_open")
			var invio := InputEventAction.new()
			invio.action = &"dome_confirm"
			invio.pressed = true
			Input.parse_input_event(invio)
		var fermo := 0
		for i in lastre.size():
			var ora := _ingombro(lastre[i]).get_center()
			var spostata := ora - _partenza[i]
			if spostata.length() < 0.001:
				fermo += 1
			print("[cupola] %-14s aperta,  baricentro a %s   spostato di %.3f m, ruotato di %.1f gradi"
				% [lastre[i].name, _v(ora), spostata.length(),
					rad_to_deg(lastre[i].basis.get_euler().x)])
		_fessura(lastre, "da aperta")
		if fermo > 0:
			print("[cupola] %d LASTRE FERME: il battente non le ha mosse" % fermo)
		return

	if _fase == 2 and _conto > 6:
		_fase = 3
		_conto = 0
		return

	if _fase == 3 and _conto > 6:
		# IN HEADLESS NON C'E' NIENTE DA FOTOGRAFARE, e chiederlo lo stesso non
		# restituisce un'immagine vuota: restituisce `null`, e il `save_png` che
		# segue muore prima del `quit()`. La sonda restava aperta a stampare lo
		# stesso errore per sempre.
		if DisplayServer.get_name() == "headless":
			print("[cupola] headless: nessuno scatto")
		else:
			var img: Image = get_viewport().get_texture().get_image()
			img.save_png(FUORI)
			print("[cupola] scatto in %s" % ProjectSettings.globalize_path(FUORI))
		_fine()
		return


## Si siede al monitor come farebbe il giocatore: `E` sul monitor, e basta. Chi
## monta la fase è il piano della notte, che qui non si tocca.
func _siediti() -> void:
	_partita = true
	# CHE LA NOTTE VADA AVANTI E' META' DELLA PROVA. Una fase che si apre e non si
	# chiude lascia la notte ferma su di se' fino all'alba, e da fuori si vedrebbe
	# solo una cupola aperta e un monitor che non cambia mai schermata.
	Events.phase_finished.connect(func(chiave: StringName, punteggio: int) -> void:
		print("[cupola] fase '%s' chiusa con %d" % [chiave, punteggio]))
	Events.phase_started.connect(func(chiave: StringName) -> void:
		print("[cupola] fase '%s' montata" % chiave))
	var monitor := CrtMonitor.find_in(get_tree())
	if monitor == null:
		print("[cupola] NESSUN MONITOR nel gioco")
		_fine()
		return
	monitor.interact(Player.find_in(get_tree()))


## La fase della cupola, ovunque l'orchestratore l'abbia montata.
func _trova_fase(n: Node) -> PhaseDome:
	var d := n as PhaseDome
	if d != null:
		return d
	for f in n.get_children():
		var t := _trova_fase(f)
		if t != null:
			return t
	return null


## Il banco della postazione, ovunque `main.gd` l'abbia appeso.
func _trova_banco(n: Node) -> DeskCamera:
	var d := n as DeskCamera
	if d != null:
		return d
	for f in n.get_children():
		var t := _trova_banco(f)
		if t != null:
			return t
	return null


## Monta la fase vera e le tiene premuto il comando.
##
## `Input.action_press` E NON UN EVENTO FINTO: la fase legge `is_action_pressed`,
## cioè lo stato dell'input, non gli eventi che passano. Un `InputEventAction`
## spedito a mano attraverserebbe l'albero senza cambiare quello stato, e la sonda
## misurerebbe una cupola comandata da nessuno.
func _monta_la_fase() -> void:
	var fase: Phase = load("res://phases/dome/phase_dome.tscn").instantiate()
	_scena.add_child(fase)
	fase.finished.connect(_su_fine_fase)
	_fase_vera = fase
	print("[cupola] fase montata: chiave '%s', schermo %s, sorgente %s"
		% [fase.key(), "sì" if fase.screen() != null else "NO",
			"sì" if fase.get(&"truth") != null else "NO"])
	Input.action_press(&"dome_open")


func _su_fine_fase(esito: PhaseResult) -> void:
	print("[cupola] la fase si è chiusa: ok %s, punteggio %d" % [esito.ok, esito.score])


## Una camera sul pavimento della cupola, che guarda in su.
##
## `look_at` NON SI PUÒ USARE per guardare lo zenit: la direzione coinciderebbe con
## l'asse verticale e la base sarebbe degenere. Si ruota di 90 gradi attorno a X,
## che porta il -Z della camera esattamente su +Y.
func _inquadra(lastre: Array[Node3D]) -> void:
	# SOTTO I BATTENTI, e non sotto il nodo che li comanda: quel nodo puo' stare
	# all'origine del mondo — nel blockout ci sta — e la camera finirebbe in mezzo
	# al prato a fotografare il buio, con la sonda che dice «nessun cielo».
	var mezzo := Vector3.ZERO
	for n in lastre:
		mezzo += n.global_position
	mezzo /= float(lastre.size())
	var cam := Camera3D.new()
	_scena.add_child(cam)
	if not OS.get_environment("DA").is_empty():
		cam.global_position = _punto("DA", mezzo + Vector3(0.0, 3.0, -8.0))
		cam.look_at(_punto("A", mezzo), Vector3.UP)
		cam.fov = 45.0
	else:
		cam.global_position = Vector3(mezzo.x, 1.2, mezzo.z)
		cam.rotation = Vector3(PI / 2.0, 0.0, 0.0)
		cam.fov = 75.0
	cam.current = true
	var sole := OS.get_environment("SOLE")
	if not sole.is_empty():
		_alza_la_luna(_scena, float(sole))


## Alza tutte le direzionali della scena. Solo per la fotografia: una cupola di
## notte e' nera, e il nero non dice se una cosa si e' mossa.
func _alza_la_luna(n: Node, energia: float) -> void:
	var l := n as DirectionalLight3D
	if l != null:
		l.light_energy = energia
	for f in n.get_children():
		_alza_la_luna(f, energia)


## Un punto da variabile d'ambiente, o il ripiego.
##
## TIPIZZATA, e non «Vector3 oppure null»: un `var x := f()` su una funzione senza
## tipo di ritorno non compila, la sonda parte senza copione e non chiude mai la
## finestra. È già successo due volte in questo file.
func _punto(chiave: String, difetto: Vector3) -> Vector3:
	var t := OS.get_environment(chiave)
	if t.is_empty():
		return difetto
	var n := t.split(",")
	if n.size() != 3:
		return difetto
	return Vector3(float(n[0]), float(n[1]), float(n[2]))


## La LUCE NETTA fra le due lastre: quanto cielo passa davvero.
##
## FRA I BORDI E NON FRA I CENTRI, ed è tutta la differenza: due lastre profonde
## 2,1 m con i centri a 2,1 m di distanza si toccano, e una misura da centro a
## centro le direbbe «distanti due metri» — cioè direbbe che la cupola è aperta
## mentre è chiusa. Si misura sull'asse su cui si scostano, prendendo i bordi
## dagli ingombri veri delle mesh.
##
## VALE SOLO PER I BATTENTI CHE SCORRONO. Due gusci che RUOTANO sullo stesso
## sferoide hanno gli ingombri sovrapposti sempre, prima e dopo: la loro distanza
## sarebbe un numero negativo qualunque cosa succeda, e stamparlo vorrebbe dire
## mettere in tabella una misura che non misura niente. Quando non ha senso, si
## dice che non ce l'ha.
func _fessura(lastre: Array[Node3D], quando: String) -> void:
	var luce := _luce_netta(lastre)
	if luce < 0.0:
		print("[cupola] battenti accavallati sullo stesso guscio: la luce netta %s non si misura cosi'"
			% quando)
		return
	print("[cupola] luce netta %s: %.3f m" % [quando, luce])


func _luce_netta(lastre: Array[Node3D]) -> float:
	if lastre.size() != 2:
		return -1.0
	var a := _ingombro(lastre[0])
	var b := _ingombro(lastre[1])
	if a.size == Vector3.ZERO or b.size == Vector3.ZERO:
		return -1.0
	# L'asse di corsa: quello su cui i due centri sono più lontani.
	var d := (a.get_center() - b.get_center()).abs()
	var asse := 0
	if d.y > d[asse]:
		asse = 1
	if d.z > d[asse]:
		asse = 2
	var vicina := a if a.get_center()[asse] < b.get_center()[asse] else b
	var lontana := b if vicina == a else a
	return lontana.position[asse] - (vicina.position[asse] + vicina.size[asse])


## L'ingombro globale di una lastra, dalle mesh che ha addosso. Dalle MESH e non
## dalle collisioni: quello che il giocatore vede è la mesh, e se le due
## divergessero è la mesh a dire la verità su cosa si vede.
func _ingombro(n: Node3D) -> AABB:
	var fuori := AABB()
	var primo := true
	# IL NODO STESSO CONTA. Le lastre segnaposto sono `StaticBody3D` con la mesh
	# appesa sotto; i portelli modellati SONO la mesh. Guardando solo i figli, i
	# secondi tornavano con un ingombro vuoto — baricentro all'origine del mondo,
	# spostamento zero — e la sonda gridava «battenti fermi» su due gusci che si
	# erano appena girati di novanta gradi.
	var candidati: Array[Node] = [n]
	candidati.append_array(n.get_children())
	for f in candidati:
		var m := f as MeshInstance3D
		if m == null or m.mesh == null:
			continue
		var locale := m.get_aabb()
		var g := m.global_transform
		var punti: Array[Vector3] = []
		for i in 8:
			punti.append(g * locale.get_endpoint(i))
		var box := AABB(punti[0], Vector3.ZERO)
		for p in punti:
			box = box.expand(p)
		fuori = box if primo else fuori.merge(box)
		primo = false
	return fuori


## Le lastre risolte dal battente. Si rilegge il `NodePath` invece di frugare nei
## campi privati: è la stessa strada che percorre il nodo, quindi un percorso
## sbagliato si vede qui come si vedrebbe in gioco.
func _lastre(s: DomeShutter) -> Array[Node3D]:
	var fuori: Array[Node3D] = []
	for p in s.leaves:
		var n := s.get_node_or_null(p) as Node3D
		if n != null:
			fuori.append(n)
	return fuori


func _fine() -> void:
	get_tree().quit()


func _v(p: Vector3) -> String:
	return "%.3f, %.3f, %.3f" % [p.x, p.y, p.z]
