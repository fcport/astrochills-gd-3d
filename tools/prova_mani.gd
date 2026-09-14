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
##     PROP_OSTACOLO=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_mani.tscn
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
	# SU TUTTI E DUE I LAYER, e nel gioco non e' cosi': li' il mondo ha una
	# collisione grezza per il corpo del giocatore (`LAYER_WORLD`) e una a
	# triangoli per le cose che ci si posano (`Corazza.LAYER_APPOGGI`). Qui il
	# banco e' fatto di scatole, che sono la stessa cosa vista in due modi: darle
	# a tutti e due i layer prova il giocatore E gli oggetti con una geometria
	# sola.
	corpo.collision_layer = Interactable.LAYER_WORLD | Corazza.LAYER_APPOGGI
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
	_oggetto.ostacolo_per_il_giocatore = OS.get_environment("PROP_OSTACOLO") == "1"
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
##
## SI CHIEDE AL GIOCATORE invece di rifare il conto: la posizione della mano e'
## una cosa che si tara guardando, e una copia della formula qui dentro sarebbe
## una seconda verita' destinata a divergere alla prima taratura. Quello che
## questa sonda deve provare non e' DOVE sta la mano - e' che l'oggetto ci arrivi
## e che per arrivarci non attraversi niente.
func _scarto_dalla_mano() -> float:
	return _p._trasformata_mano().origin.distance_to(_oggetto.global_position)


## Il sinistro, come lo consegnerebbe il mouse. Dato al giocatore direttamente: in
## headless non c'è una finestra da cui farlo passare.
func _clic(premuto: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = premuto
	_p._unhandled_input(ev)


## La bottiglia del blockout rifatta con le sue misure (`s_bottiglia` in
## `world/blockout.tscn`), con l'origine sul fondo come lì.
func _bottiglia() -> Carryable:
	var b := Carryable.new()
	b.name = "Bottiglia"
	b.nome = "la bottiglia"
	b.mass = 0.5
	b.lancio_senza_giro = OS.get_environment("LANCIO_SENZA_GIRO") == "1"
	var forma := CollisionShape3D.new()
	var cilindro := CylinderShape3D.new()
	cilindro.height = 0.299
	cilindro.radius = 0.037
	forma.shape = cilindro
	forma.position.y = 0.150
	b.add_child(forma)
	_scena.add_child(b)
	return b


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

	# --- SI PRENDE GUARDANDO IN BASSO, E RESTA DRITTA.
	#
	# E' il secondo difetto che Federico ha trovato: presa la mano conservava
	# l'orientamento rispetto a TUTTA la testa, beccheggio compreso, quindi un
	# oggetto raccolto guardando in giu' restava inclinato di quell'angolo per
	# sempre - si rialzava lo sguardo e il termos si presentava coricato in avanti.
	# Una cosa in mano sta dritta: c'e' la gravita', e il polso la raddrizza senza
	# pensarci.
	#
	# La presa avviene DA SOPRA di proposito (il tavolino sta a 80 cm e l'occhio a
	# 165): e' il caso in cui il difetto c'e', e prendere una cosa all'altezza degli
	# occhi non lo mostrerebbe mai.
	# E CORICATA, che e' l'altra meta' della stessa cosa. Federico l'ha vista dopo
	# la prima cura: «l'ho raccolto di nuovo nella stessa posizione in cui l'ho
	# raccolto e non si era drizzato». Un oggetto caduto di traverso resta di
	# traverso in mano, e per rimetterlo in piedi bisogna sperare che cada bene.
	# Chi raccoglie una bottiglia coricata la mette dritta: e' il polso, e non
	# farlo e' la cosa che si nota.
	_oggetto.global_basis = Basis(Vector3.RIGHT, deg_to_rad(90.0))
	await _tick()
	print("[mani] la si prende guardando in giu' di %.0f gradi, e da coricata "
		% rad_to_deg(-_p.camera().rotation.x)
		+ "(%.0f gradi fuori squadra)"
		% rad_to_deg(_oggetto.global_basis.y.angle_to(Vector3.UP)))
	_p._prendi(_oggetto)
	for _i in 30:
		await _tick()
	# Si rimette lo sguardo all'orizzonte: e' li' che l'inclinazione si vede.
	_guarda(Vector3(0.0, _p.camera().global_position.y, -10.0))
	for _i in 30:
		await _tick()
	var scarto := _scarto_dalla_mano()
	# QUANTO E' STORTA: l'angolo fra il suo «su» e il su del mondo. Zero vuol dire
	# in piedi; novanta, coricata.
	var storta := rad_to_deg(_oggetto.global_basis.y.angle_to(Vector3.UP))
	print("[mani] presa: la scatola sta a %.3f m da dove la mano la vuole, "
		% scarto + "e pende di %.1f gradi rispetto alla verticale" % storta)
	if storta > 5.0:
		_guasto("in mano la scatola pende di %.1f gradi: non si e' raddrizzata "
			% storta + "- e' rimasta come stava, o come stava lo sguardo")
	if not _oggetto.in_mano():
		_guasto("la scatola non risulta in mano")
	if scarto > 0.05:
		_guasto("la scatola non arriva in mano: %.3f m di scarto" % scarto)

	# --- LA RIGA A SCHERMO DICE QUELLO CHE SI PUO' FARE, SEMPRE.
	#
	# E' il difetto che Federico ha trovato per primo: posato il termos, restava
	# scritto «Posa il termos» su un termos gia' per terra, e tornava a posto solo
	# guardando un'altra cosa e poi di nuovo lui. Un prompt che mente non da'
	# nessun errore - si preme un tasto che non fa niente, e sembra rotto il gioco.
	#
	# SI GUARDA CIO' CHE C'E' A SCHERMO, non chi ha chiamato `show_prompt`:
	# controllare le chiamate vorrebbe dire fidarsi che l'ultima abbia vinto, che
	# e' esattamente cio' che non era vero.
	var schermo: InteractionPrompt = _p.get_node("%InteractionPrompt")
	_p._aggiorna_mira()
	print("[mani] con la scatola in mano lo schermo dice: %s" % schermo.riga())
	if not schermo.riga().contains("Posa"):
		_guasto("tenendo la scatola in mano non compare la riga per posarla")
	_oggetto.posa()
	await _tick()
	_p._aggiorna_mira()
	print("[mani] appena posata lo schermo dice: %s"
		% (schermo.riga() if not schermo.riga().is_empty() else "(niente)"))
	if schermo.riga().contains("Posa"):
		_guasto("posata la scatola resta scritto «%s»: il prompt mente"
			% schermo.riga())
	# E si riprende, che il resto della prova la vuole in mano.
	_p._prendi(_oggetto)
	for _i in 20:
		await _tick()

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

	# --- IL LANCIO: SINISTRO TENUTO, E PARTE AL RILASCIO SOLO A BARRA PIENA.
	#
	# Federico: «tenendo premuto il pulsante sinistro si possa lanciare, una piccola
	# barra che fa vedere che stai caricando e solo se arrivi al massimo lanci». La
	# meta' che si rompe senza che nessuno se ne accorga e' la seconda: mollato a
	# meta' carica, la scatola deve restare in mano.
	#
	# SI LANCIA VERSO +Z, lontano dal muro: a z=-1.6 la scatola ci sbatterebbe dopo
	# un metro, e la distanza percorsa misurerebbe il muro invece del lancio.
	for _i in 90:
		await _tick()
	_p.global_position = Vector3(3.0, 0.0, 0.0)
	_p.rotation.y = PI
	_p.camera().rotation.x = 0.0
	_oggetto.global_position = _p._trasformata_mano().origin
	_oggetto.linear_velocity = Vector3.ZERO
	await _tick()
	_p._prendi(_oggetto)
	for _i in 30:
		await _tick()
	var mirino: Crosshair = _p._mirino
	_clic(true)
	for _i in int(Player.TEMPO_CARICA * 30.0):
		await _tick()
	print("[mani] lancio mollato a meta': la barra era a %.2f" % mirino._carica)
	if mirino._carica <= 0.0:
		_guasto("tenendo premuto il sinistro la barra non si riempie")
	_clic(false)
	await _tick()
	if not _oggetto.in_mano():
		_guasto("mollato il sinistro a meta' carica, la scatola e' partita lo stesso")
	if mirino._carica > 0.0:
		_guasto("mollato il sinistro la barra resta a %.2f" % mirino._carica)
	# TENUTO OLTRE LA BARRA PIENA NON PARTE: parte quando si molla (D-241). Mezzo
	# secondo in più basta a vedere un lancio che scattasse da solo.
	_clic(true)
	var tick_pieno := -1
	for i in int(Player.TEMPO_CARICA * 60.0) + 30:
		await _tick()
		if tick_pieno < 0 and mirino._carica >= 1.0:
			tick_pieno = i + 1
	print("[mani] tenuto oltre: barra piena dopo %.2f s, e mezzo secondo dopo la scatola %s"
		% [tick_pieno / 60.0, "e' ancora in mano" if _oggetto.in_mano() else "e' partita"])
	if not _oggetto.in_mano():
		_guasto("a barra piena la scatola parte da sola, senza aspettare il rilascio")
	if tick_pieno < 0:
		_guasto("tenendo il sinistro la barra non arriva mai in fondo")
	elif absf(tick_pieno / 60.0 - Player.TEMPO_CARICA) > 0.05:
		_guasto("la barra si riempie in %.2f s, la carica ne dura %.2f"
			% [tick_pieno / 60.0, Player.TEMPO_CARICA])
	_clic(false)
	await _tick()
	var partenza := _oggetto.global_position
	var spinta := _oggetto.linear_velocity
	print("[mani] mollato a barra piena: parte a %.1f m/s (%.1f in avanti)"
		% [spinta.length(), spinta.z])
	if _oggetto.in_mano():
		_guasto("mollato il sinistro a barra piena la scatola non parte")
	else:
		if spinta.z < 4.0:
			_guasto("la scatola non parte in avanti: %.1f m/s lungo lo sguardo" % spinta.z)
		if _p._in_mano != null:
			_guasto("lanciata la scatola, il giocatore crede di averla ancora in mano")
		if mirino._carica > 0.0:
			_guasto("lanciata la scatola, la barra resta a %.2f" % mirino._carica)
	for _i in 60:
		await _tick()
	var volo := Vector2(_oggetto.global_position.x - partenza.x,
		_oggetto.global_position.z - partenza.z).length()
	print("[mani] lanciata, dopo un secondo sta a %.2f m da dove e' partita" % volo)
	if volo < 1.5:
		_guasto("lanciata, la scatola si e' fermata a %.2f m: non e' un lancio" % volo)

	# --- E UNA BOTTIGLIA LANCIATA NON ATTERRA SEMPRE IN PIEDI.
	#
	# Federico: «ho provato a tirare la bottiglia e cade perfettamente in piedi». In
	# mano sta dritta, e senza un giro volava dritta e toccava terra sul fondo. Si
	# lancia la forma vera della bottiglia OTTO volte, con lo sguardo che cambia, e si
	# conta come si ferma. `LANCIO_SENZA_GIRO=1` rimette il difetto.
	#
	# IL SEME E' FISSO perche' il giro ha un caso dentro: senza, un referto rosso non
	# si potrebbe rifare.
	seed(241)
	var lanci := 8
	var in_piedi := 0
	for k in lanci:
		var bottiglia := _bottiglia()
		_p.global_position = Vector3(-5.0, 0.0, -0.5)
		_p.rotation.y = PI + deg_to_rad(-30.0 + 60.0 * k / float(lanci - 1))
		_p.camera().rotation.x = deg_to_rad(-10.0 + 5.0 * (k % 3))
		bottiglia.global_position = _p._trasformata_mano().origin
		await _tick()
		_p._prendi(bottiglia)
		for _i in 30:
			await _tick()
		_clic(true)
		for _i in int(Player.TEMPO_CARICA * 60.0) + 5:
			await _tick()
		_clic(false)
		await _tick()
		var lanciata := not bottiglia.in_mano()
		for _i in 240:
			await _tick()
		var pende := rad_to_deg(bottiglia.global_basis.y.angle_to(Vector3.UP))
		var lontana := Vector2(bottiglia.global_position.x - _p.global_position.x,
			bottiglia.global_position.z - _p.global_position.z).length()
		print("[mani] bottiglia %d: ferma a %.1f m, pende di %.0f gradi"
			% [k + 1, lontana, pende])
		# SONDA CIECA: una bottiglia rimasta in mano, o caduta ai piedi, sta dritta
		# per ragioni che col lancio non c'entrano.
		if not lanciata or lontana < 1.5:
			_guasto("SONDA CIECA: la bottiglia %d non e' stata lanciata (a %.1f m)"
				% [k + 1, lontana])
		elif pende < 15.0:
			in_piedi += 1
		bottiglia.queue_free()
	print("[mani] bottiglie lanciate: %d su %d si fermano in piedi" % [in_piedi, lanci])
	if in_piedi * 2 > lanci:
		_guasto("%d bottiglie lanciate su %d si fermano in piedi: volano dritte"
			% [in_piedi, lanci])

	# --- E CI SI CAMMINA SOPRA SENZA DECOLLARE.
	#
	# UN TERMOS NON E' UN GRADINO. Se un oggetto da mano sta sul layer del mondo, la
	# capsula del giocatore ci sale sopra, il solutore trova una compenetrazione
	# verticale e la risolve sparando in aria chi cammina. Federico l'ha visto in
	# partita - «se ci cammino sopra faccio dei salti pazzeschi» - e non e' un
	# numero da tarare: e' una scelta di layer.
	for _i in 90:
		await _tick()
	_p.global_position = Vector3(3.0, 0.0, 5.4)
	_oggetto.global_position = Vector3(3.0, LATO, 4.0)
	_oggetto.linear_velocity = Vector3.ZERO
	for _i in 30:
		await _tick()
	_guarda(Vector3(3.0, _p.camera().global_position.y, 2.0))
	var quota_a_terra := _p.global_position.y
	var salito := 0.0
	# QUANTO SI E' AVVICINATO, non dove e' finito: col difetto acceso il giocatore
	# viene sparato DALL'ALTRA PARTE della stanza, e guardando la posizione finale
	# la guardia gridava «non ci sei mai salito sopra» proprio mentre volava per
	# esserci salito. E' lo stesso errore della guardia di `prova_ccd.gd`, e la
	# stessa cura: si guarda il percorso, non il punto d'arrivo.
	var piu_vicino := _p.global_position.z
	Input.action_press(&"move_forward")
	for _i in 90:
		await _tick()
		salito = maxf(salito, _p.global_position.y - quota_a_terra)
		piu_vicino = minf(piu_vicino, _p.global_position.z)
	Input.action_release(&"move_forward")
	print("[mani] camminando sopra la scatola il giocatore si alza di %.3f m "
		% salito + "(e' arrivato fino a z=%.2f, la scatola sta a 4.00)" % piu_vicino)
	# SONDA CIECA: se il giocatore non e' arrivato fin sopra la scatola non ha
	# scavalcato niente, e questo controllo passerebbe comunque.
	# E LA GUARDIA VALE SOLO SE NON SI E' VISTO NIENTE: col difetto acceso il
	# giocatore viene respinto prima ancora di arrivarci, quindi non «arriva sulla
	# scatola» - ma il salto lo ha gia' fatto, e gridare «non ho visto niente»
	# mentre lo si sta misurando e' peggio che tacere.
	if piu_vicino > 4.0 and salito <= 0.05:
		_guasto("SONDA CIECA: il giocatore non e' andato oltre z=%.2f e non e' "
			% piu_vicino + "successo niente: non ci e' mai arrivato sopra")
	if salito > 0.05:
		_guasto("camminando sulla scatola il giocatore si alza di %.3f m: e' un "
			% salito + "gradino, non un oggetto da mano")
	else:
		print("[mani] ok: la scatola non fa da gradino")

	if _guasti == 0:
		print("[mani] ok: quello che si ha in mano resta dentro il mondo")
	else:
		print("[mani] GUASTO: %d controlli falliti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)
