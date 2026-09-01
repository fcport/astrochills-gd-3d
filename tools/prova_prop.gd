## LA ROBA POSATA STA DOVE E' STATA POSATA?
##
## LA DOMANDA, E PERCHE' NON E' OVVIA. Un oggetto raccoglibile e' un corpo rigido
## con la gravita' accesa: appena la scena parte, cade. Se sotto c'e' il piano su
## cui lo si e' messo si assesta di qualche millimetro e resta li'; se quel piano
## non ha collisione - e nel blockout la collisione degli arredi la genera un altro
## pezzo di codice - attraversa la consolle, il pavimento e finisce nella cantina
## senza che niente protesti. In partita si vede solo entrando in quella stanza e
## non trovandoci niente: il difetto piu' silenzioso che questi oggetti possano
## avere.
##
## NON SI CONTROLLA UN ELENCO, SI CONTROLLA LA SCENA: la sonda cerca da sola OGNI
## `Carryable` dell'albero. E' la stessa regola di `prova_rete.gd` - chiedere al
## generatore se ha posato bene quello che ha posato lui e' ricopiare la sua lista
## in due posti.
##
## IL DIFETTO SI RIMETTE: `PROP_IN_ARIA=1` alza tutto di un metro prima di far
## girare la fisica. Senza quel confronto un referto che dice «sono tutti fermi»
## non direbbe se la sonda saprebbe accorgersi di uno che se n'e' andato.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_prop.tscn
##     PROP_IN_ARIA=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_prop.tscn
extends Node

## Quanto puo' scendere assestandosi, in metri. Un corpo rigido appoggiato affonda
## di qualche millimetro nel margine del solutore; cinque centimetri sono gia'
## tanti, e mezzo metro vuol dire che il piano non c'era.
const ASSESTAMENTO := 0.05

var _guasti := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[prop] GUASTO: " + msg)


func _tutti(n: Node, fuori: Array[Carryable]) -> void:
	if n is Carryable:
		fuori.append(n as Carryable)
	for f in n.get_children():
		_tutti(f, fuori)


func _prova() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	await get_tree().physics_frame
	await get_tree().physics_frame

	var roba: Array[Carryable] = []
	_tutti(get_tree().root, roba)
	# La camera CCD nasce avvitata al telescopio e non cade: e' un caso suo, e lo
	# prova `prova_ccd.gd`. Qui interessa la roba appoggiata.
	roba = roba.filter(func(c): return not (c is CcdCamera))
	print("[prop] nella scena ci sono %d oggetti da raccogliere" % roba.size())
	if roba.size() < 2:
		print("[prop] SONDA CIECA: con meno di due oggetti non c'e' niente da "
			+ "guardare, e questa prova passerebbe comunque")
		_guasti += 1

	if OS.get_environment("PROP_IN_ARIA") == "1":
		for c in roba:
			c.global_position += Vector3.UP

	var partenza := {}
	for c in roba:
		partenza[c] = c.global_position

	# Otto secondi: un oggetto che deve solo assestarsi ci mette qualche
	# fotogramma, uno che sta cadendo in cantina ci arriva comodamente, e a un
	# corpo rigido che oscilla su un piano si lascia il tempo di addormentarsi.
	for _i in 480:
		await get_tree().physics_frame

	for c in roba:
		var da: Vector3 = partenza[c]
		var sceso := da.y - c.global_position.y
		var ferma := c.linear_velocity.length()
		# LO SPOSTAMENTO IN PIANTA E' L'ALTRA META', e senza non si vedrebbe il
		# difetto peggiore: un oggetto che non si addormenta mai non cade, ma
		# STRISCIA - e in una notte di gioco se ne va dal piano da solo.
		var scivolato := Vector2(c.global_position.x - da.x,
			c.global_position.z - da.z).length()
		print("[prop] %-12s da y=%.3f a y=%.3f (sceso %.3f, scivolato %.3f), "
			% [c.name, da.y, c.global_position.y, sceso, scivolato]
			+ "velocita' %.3f m/s, giro %.3f, dorme=%s"
			% [ferma, c.angular_velocity.length(), c.sleeping])
		# SU CHE COSA E' APPOGGIATO, e non e' curiosita': un oggetto che non si
		# ferma quasi sempre sta a cavallo di due corpi o non tocca niente, e
		# saperlo e' meta' della diagnosi.
		var sotto := c.get_colliding_bodies().map(func(b): return b.name)
		print("           tocca: %s" % (", ".join(sotto) if sotto.size() > 0 else "niente"))
		if scivolato > ASSESTAMENTO:
			_guasto("%s e' scivolato di %.3f m in tre secondi: da fermo non sta fermo"
				% [c.name, scivolato])
		if sceso > ASSESTAMENTO:
			_guasto("%s e' sceso di %.3f m: sotto non c'era niente che lo reggesse"
				% [c.name, sceso])
		if ferma > 0.05:
			_guasto("%s non si e' fermato: va ancora a %.3f m/s" % [c.name, ferma])
		# E CHE SIA MIRABILE: un oggetto raccoglibile che il raggio non incontra
		# non si puo' prendere, e non lo dice nessun errore.
		if (c.collision_layer & Interactable.LAYER_INTERACTABLE) == 0:
			_guasto("%s non sta sul layer degli interagibili: il raggio del "
				% c.name + "giocatore non lo troverebbe mai")

	if _guasti == 0:
		print("[prop] ok: tutto quello che e' posato sta dove e' stato posato")
	else:
		print("[prop] GUASTO: %d controlli falliti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)
