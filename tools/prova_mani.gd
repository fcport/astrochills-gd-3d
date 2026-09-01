## QUELLO CHE SI HA IN MANO E' ANCORA NEL MONDO?
##
## LA DOMANDA, E PERCHE' NON E' OVVIA. Tenere un oggetto in mano in prima persona
## e' facile in un modo solo e giusto in un altro. Il modo facile lo appende alla
## camera: da quel momento non e' piu' un corpo, e' un pezzo di testa. Ti segue
## perfetto, e attraversa i muri, i tavoli e il telescopio senza che niente
## protesti - nessun errore, nessun avviso, e un oggetto che entra nell'intonaco
## quando ti avvicini troppo a una parete. E' l'errore che questa sonda esiste per
## vedere.
##
## SI MISURA IL CASO PEGGIORE, non quello medio: si prende l'oggetto e si CAMMINA
## DENTRO UN MURO. La mano finisce mezzo metro oltre l'intonaco - il corpo si
## ferma prima, la mano no - quindi ogni tick chiede all'oggetto di stare dove
## l'oggetto non puo' stare. E' l'unico momento in cui le due implementazioni
## danno risultati diversi, ed e' per questo che il banco e' fatto di un muro.
##
## IL DIFETTO SI PUO' RIMETTERE: `MANO_RIGIDA=1` accende `mano_rigida` sul
## `Carryable`, che torna al teletrasporto. Senza quel confronto il referto
## direbbe «l'oggetto non e' entrato nel muro» e nessuno saprebbe se e' merito
## della fisica o se il muro non e' mai stato toccato.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_mani.tscn
##     MANO_RIGIDA=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_mani.tscn
extends Node

## Il banco, in metri. Il muro sta davanti al giocatore e la sua faccia interna e'
## il numero che tutta la prova guarda: nessun pezzo dell'oggetto deve mai
## trovarsi oltre.
const MURO_Z := -1.60
const MURO_SPESSORE := 0.10
const FACCIA := MURO_Z + MURO_SPESSORE * 0.5

## Il tavolino su cui l'oggetto aspetta di essere raccolto, e l'oggetto.
const TAVOLO := Vector3(0.60, 0.40, 0.0)
const TAVOLO_ALTEZZA := 0.80
const LATO := 0.16

var _guasti := 0
var _scena: Node3D
var _p: Player
var _oggetto: Carryable


## DIFFERITO, come in `prova_rete`: dentro `_ready()` la root sta ancora montando
## i propri figli e `add_child` fallisce. Il banco nascerebbe fuori dall'albero, e
## tutto il resto misurerebbe trasformate di nodi che non esistono.
func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[mani] GUASTO: " + msg)


## Un tick di fisica vero. La fisica di questa sonda non si simula a mano come in
## `prova_slew`: qui il punto E' il motore - se lo si scavalca si misura la
## propria aritmetica invece della collisione, cioe' esattamente la cosa in esame.
func _tick() -> void:
	await get_tree().physics_frame


func _muro(nome: String, centro: Vector3, misura: Vector3) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.name = nome
	corpo.collision_layer = Interactable.LAYER_WORLD
	var forma := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = misura
	forma.shape = box
	corpo.add_child(forma)
	corpo.position = centro
	_scena.add_child(corpo)
	return corpo


func _monta() -> void:
	_scena = Node3D.new()
	get_tree().root.add_child(_scena)
	get_tree().current_scene = _scena

	_muro("Pavimento", Vector3(0.0, -0.5, 0.0), Vector3(20.0, 1.0, 20.0))
	_muro("Muro", Vector3(0.0, 1.5, MURO_Z), Vector3(8.0, 3.0, MURO_SPESSORE))
	_muro("Tavolo", TAVOLO, Vector3(0.5, TAVOLO_ALTEZZA, 0.5))

	_p = load("res://world/player/player.tscn").instantiate() as Player
	_scena.add_child(_p)
	_p.global_position = Vector3.ZERO

	_oggetto = Carryable.new()
	_oggetto.name = "Scatola"
	_oggetto.nome = "la scatola"
	_oggetto.mass = 1.0
	_oggetto.mano_rigida = OS.get_environment("MANO_RIGIDA") == "1"
	var forma := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(LATO, LATO, LATO)
	forma.shape = box
	_oggetto.add_child(forma)
	_scena.add_child(_oggetto)
	_oggetto.global_position = TAVOLO + Vector3(0.0, TAVOLO_ALTEZZA * 0.5 + LATO, 0.0)


## Punta la testa verso un punto del mondo. La imbardata va sul corpo e il
## beccheggio sulla camera, come nel gioco: farlo diversamente qui vorrebbe dire
## provare un giocatore che non esiste.
func _guarda(punto: Vector3) -> void:
	var occhio := _p.camera().global_position
	var d := punto - occhio
	_p.rotation.y = atan2(-d.x, -d.z)
	_p.camera().rotation.x = atan2(d.y, Vector2(d.x, d.z).length())


## Quanto e' lontano l'oggetto da dove la mano lo vorrebbe.
func _scarto_dalla_mano() -> float:
	var testa := _p.camera().global_transform
	var voluta := testa.origin \
		- testa.basis.z * Player.DISTANZA_MANO \
		+ testa.basis.y * Player.ALTEZZA_MANO
	return voluta.distance_to(_oggetto.global_position)


func _prova() -> void:
	_monta()
	await _tick()
	await _tick()

	# --- LO TROVA IL RAGGIO? Un oggetto che il raggio non incontra non si puo'
	# raccogliere, e non lo dice nessun errore: davanti non compare il prompt.
	_guarda(_oggetto.global_position)
	await _tick()
	if _p._mirato != _oggetto:
		_guasto("guardando la scatola il raggio non la trova")
	else:
		print("[mani] mirando la scatola il prompt dice: %s" % _oggetto.prompt())

	# --- SI PRENDE, E CI ARRIVA. Mezzo secondo: la mano fa 6 m/s e deve coprirne
	# meno di uno.
	_p._prendi(_oggetto)
	for _i in 30:
		await _tick()
	var scarto := _scarto_dalla_mano()
	print("[mani] presa: la scatola sta a %.3f m da dove la mano la vuole" % scarto)
	if not _oggetto.in_mano():
		_guasto("la scatola non risulta in mano")
	if scarto > 0.05:
		_guasto("la scatola non arriva in mano: %.3f m di scarto" % scarto)

	# --- IL CUORE: SI CAMMINA DENTRO IL MURO. Il corpo si ferma, la mano no.
	_guarda(Vector3(0.0, _p.camera().global_position.y, MURO_Z))
	Input.action_press(&"move_forward")
	var dentro := 0.0
	for _i in 120:
		await _tick()
		# Lo spigolo davanti, non il centro: e' quello che tocca l'intonaco.
		dentro = maxf(dentro, FACCIA - (_oggetto.global_position.z - LATO * 0.5))
	Input.action_release(&"move_forward")
	print("[mani] camminando nel muro: corpo a z=%.3f, scatola a z=%.3f, "
		% [_p.global_position.z, _oggetto.global_position.z]
		+ "dentro l'intonaco al massimo %.3f m (il muro e' spesso %.2f)"
		% [dentro, MURO_SPESSORE])
	# DUE CONTROLLI E NON UNO, perche' sono due difetti diversi. Uscire
	# DALL'ALTRA PARTE e' il difetto grosso: l'oggetto non e' piu' nel mondo, e' in
	# un'altra stanza. Entrare di qualche millimetro e' quello che fa qualunque
	# corpo rigido spinto contro un muro - il motore risolve la compenetrazione
	# dopo averla vista - e diventa un difetto solo quando si vede.
	if dentro >= MURO_SPESSORE:
		_guasto("la scatola PASSA il muro: %.3f m su %.2f di spessore"
			% [dentro, MURO_SPESSORE])
	elif dentro > 0.02:
		_guasto("la scatola affonda nell'intonaco di %.3f m: si vede" % dentro)
	else:
		print("[mani] ok: la scatola si ferma sulla superficie del muro")
	# SONDA CIECA: se il giocatore non e' arrivato al muro non ha spinto niente, e
	# questo controllo passerebbe anche appendendo l'oggetto alla camera.
	if _p.global_position.z > FACCIA + 0.45:
		_guasto("SONDA CIECA: il giocatore si e' fermato a %.3f m dal muro, la mano "
			% (_p.global_position.z - FACCIA) + "non ci e' mai arrivata dentro")

	# --- SI POSA E CADE. L'oggetto lasciato in aria deve arrivare a terra e
	# fermarcisi: e' l'altra meta' di «c'e' la fisica».
	_oggetto.lascia()
	if _p._in_mano != null:
		_guasto("posata la scatola, il giocatore crede di averla ancora in mano")
	for _i in 150:
		await _tick()
	var quota := _oggetto.global_position.y
	print("[mani] posata: si ferma a y=%.3f (il pavimento la vuole a %.3f)"
		% [quota, LATO * 0.5])
	if absf(quota - LATO * 0.5) > 0.03:
		_guasto("posata, la scatola non si ferma sul pavimento: y=%.3f" % quota)

	# --- LO STRAPPO. Chi si allontana con qualcosa incastrato la perde, e non se
	# la porta dietro attraverso il muro.
	#
	# SI RIPARTE DA UNA ZONA LIBERA, e la prima stesura non lo faceva: riprendendo
	# la scatola col giocatore ancora schiacciato contro il muro, la mano stava
	# DENTRO l'intonaco e la scatola non poteva arrivarci. Lo strappo scattava in
	# un fotogramma, ed era giusto - ma misurava il muro, non l'allontanamento.
	_p.global_position = Vector3(3.0, 0.0, 0.0)
	_p.rotation.y = 0.0
	_p.camera().rotation.x = 0.0
	_oggetto.global_position = Vector3(3.0, 1.20, -0.55)
	_oggetto.linear_velocity = Vector3.ZERO
	await _tick()
	_p._prendi(_oggetto)
	for _i in 30:
		await _tick()
	if not _oggetto.in_mano():
		_guasto("in campo libero la scatola non arriva nemmeno in mano: la prova "
			+ "dello strappo non vale")
	_p.global_position = Vector3(3.0, 0.0, 6.0)
	var fotogrammi := 0
	for _i in 90:
		await _tick()
		fotogrammi += 1
		if not _oggetto.in_mano():
			break
	print("[mani] strappo: la mano molla dopo %.2f s" % (fotogrammi / 60.0))
	if _oggetto.in_mano():
		_guasto("allontanandosi di 4 m la scatola resta in mano")
	if _p._in_mano != null:
		_guasto("strappata la scatola, il giocatore crede di averla ancora in mano")

	# --- E CI SI CAMMINA CONTRO. Una scatola per terra che non si sposta quando
	# ci vai dentro e' un sasso dipinto.
	for _i in 90:
		await _tick()
	_oggetto.global_position = Vector3(3.0, LATO, 4.0)
	_oggetto.linear_velocity = Vector3.ZERO
	for _i in 30:
		await _tick()
	var prima := _oggetto.global_position
	_guarda(Vector3(3.0, _p.camera().global_position.y, 2.0))
	Input.action_press(&"move_forward")
	for _i in 60:
		await _tick()
	Input.action_release(&"move_forward")
	var corsa := prima.distance_to(_oggetto.global_position)
	print("[mani] calciata: la scatola si sposta di %.3f m" % corsa)
	if corsa < 0.15:
		_guasto("camminando contro la scatola non si sposta: e' un sasso dipinto")

	if _guasti == 0:
		print("[mani] ok: quello che si ha in mano resta dentro il mondo")
	else:
		print("[mani] GUASTO: %d controlli falliti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)
