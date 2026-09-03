## LA CAMERA E' AVVITATA AL TELESCOPIO, O SOLO APPOGGIATA LI'?
##
## LA DOMANDA, E PERCHE' NON E' OVVIA. Una camera CCD montata al fuoco e' un pezzo
## dello strumento: quando il tubo insegue il cielo, lei ci va insieme. Metterla
## nel posto giusto e' facile e sbagliato - per un fotogramma le due cose sono
## identiche, e nessun controllo statico le distingue. La differenza si vede solo
## MUOVENDO IL TELESCOPIO, ed e' esattamente quello che questa sonda fa: manda il
## tubo dall'altra parte del cielo e guarda se la camera c'e' ancora.
##
## E SI CONTROLLA ANCHE IL RITORNO, che e' la meta' che si dimentica: smontata
## deve tornare un corpo che cade, e riportata al fuoco deve riavvitarsi.
##
## E SI CONTROLLA CHE NON SI POSSA PERDERE, che e' la domanda arrivata per ultima e
## pesa piu' di tutte. Federico: «se a uno cade la camera che toglie dal telescopio,
## gli cade dentro il cerchio del telescopio, rischia che non si possa mai piu'
## utilizzare. E' una situazione terrificante». Ed e' vero: il fuoco sta sopra il
## pozzo del pilastro, dentro l'anello della passerella, e una camera lasciata li'
## finiva sul pavimento della sala - sessanta centimetri piu' giu', dentro un pozzo
## in cui il giocatore non entra, dove nessuno la poteva piu' raccogliere. Senza
## camera non si fotografa piu' niente: non e' un oggetto smarrito, e' una partita
## finita.
##
## LA CURA NON E' PIU' UN DIVIETO, ED E' PER QUESTO CHE QUESTA SONDA E' CAMBIATA.
## Prima la mano non lasciava andare la camera sul vuoto, e la sonda controllava
## che il rifiuto ci fosse; Federico l'ha bocciato giocandoci - «adesso sono
## bloccato con la camera in mano» - e adesso il buco e' TAPPATO: sotto la
## passerella c'e' un fondo invisibile sul layer degli appoggi. Quindi la domanda
## si e' rovesciata: non «la mano si rifiuta?» ma «posandola dove capita attorno al
## telescopio, la si ritrova sempre?». Si prova un giro di pose intorno al fuoco -
## quelle in cui uno smonta la camera davvero - e per ognuna si guarda dove si
## ferma e se da qualche parte ci si arriva.
##
## I DIFETTI SI RIMETTONO, uno per domanda: `CAMERA_APPOGGIATA=1` accende
## `appoggiata_e_basta`, che posa la camera sul fuoco senza appenderla - senza quel
## confronto un referto che dice «la camera sta al fuoco» non direbbe se ci sta
## attaccata. `CAMERA_SI_PERDE=1` toglie il fondo invisibile E la rete, e rimette
## la partita che si rompe.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_ccd.tscn
##     CAMERA_APPOGGIATA=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_ccd.tscn
##     CAMERA_SI_PERDE=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_ccd.tscn
extends Node

## Il giro di pose attorno al fuoco: a che distanza e in quante direzioni.
##
## SESSANTA E NOVANTA CENTIMETRI, non di piu': e' quanto un braccio sposta la camera
## dal focheggiatore mentre la si smonta, e sono tutte fuori da `PORTATA_ATTACCO`,
## cioe' distanze a cui posarla vuol dire posarla e non riavvitarla.
const POSE_RAGGI := [0.6, 0.9]
const POSE_VERSI := 8

var _guasti := 0
var _scena: Node
var _ccd: CcdCamera
var _fuoco: Node3D


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[ccd] GUASTO: " + msg)


func _tick() -> void:
	await get_tree().physics_frame


## Quanto la camera e' lontana da dove il focheggiatore la vuole. Non si guarda la
## posizione assoluta - il telescopio si muove, e un numero assoluto non direbbe
## niente - ma lo SCARTO dal fuoco, che deve restare quello che era.
func _scarto() -> float:
	return _ccd.global_position.distance_to(_fuoco.global_position)


## LA CAMERA SI PUO' PERDERE? La si posa tutto intorno al telescopio e la si va a
## ricercare.
##
## LE POSE NON SONO SCELTE A MANO: sono un giro attorno al FUOCO, che e' il posto
## da cui la camera parte quando la si smonta - e sta sopra il pozzo del pilastro,
## quindi «mollarla dov'e' adesso» e' insieme il gesto piu' naturale e quello che
## fino a ieri la buttava giu'. Scrivere i punti a mano vorrebbe dire riscriverli a
## ogni posa del telescopio, e il telescopio cambia posa apposta poche righe piu' su.
##
## DUE DOMANDE PER OGNI POSA, e sono diverse: **posarla si puo'?** (il divieto e'
## stato tolto, e se un domani tornasse la camera resterebbe incollata in mano) e
## **da qualche parte ci si arriva?**, cioe' esiste un punto in cui un giocatore ci
## sta in piedi, la vede e la raggiunge. La seconda e' l'unica che conti davvero:
## non importa dove finisce, importa che la si riprenda.
##
## E POI L'INCIDENTE, che il fondo invisibile da solo non copre: la camera puo'
## essere strappata dalla mano contro uno stipite (vedi `Carryable.STRAPPO`). La si
## lascia cadere dal fuoco e si guarda dove sta dieci secondi dopo - o l'ha ripresa
## la rete, o si riesce a prenderla.
func _non_si_perde(giocatore: Player) -> void:
	var si_perde := OS.get_environment("CAMERA_SI_PERDE") == "1"
	_ccd.si_puo_perdere = si_perde
	if si_perde:
		_togli_il_fondo()
	# --- IL GIRO DELLE POSE
	var provate := 0
	var perse := 0
	for d in POSE_RAGGI:
		for k in POSE_VERSI:
			var ang := TAU * float(k) / float(POSE_VERSI)
			var p: Vector3 = _fuoco.global_position \
				+ Vector3(cos(ang) * (d as float), 0.10, sin(ang) * (d as float))
			if _e_occupato(p):
				continue          # dentro il tubo o dentro un muro: non e' una posa
			_ccd.prendi(giocatore)
			_ccd.global_position = p
			await _tick()
			_ccd.posa()
			await _tick()
			if _ccd.in_mano():
				_guasto("a %s posare la camera e' stato RIFIUTATO: resta in mano, "
					% _v(p) + "e chi la tiene non sa piu' come liberarsene")
				continue
			if _ccd.montata():
				continue          # troppo vicina al fuoco: si e' riavvitata, giusto cosi'
			provate += 1
			# CINQUE SECONDI, non tre: la camera cade da due metri e rotola, la
			# rete guarda dove e' finita solo quando si e' fermata, e se la sposta
			# ricomincia il conto - nelle fessure peggiori ci vogliono due o tre
			# giri. Con l'attesa corta si leggeva «persa» una camera che stava
			# ancora venendo ripescata.
			for _i in 300:
				await _tick()
			if not _ccd.si_riesce_a_prendere() and not _ccd.montata():
				perse += 1
				_guasto("posata a %s la camera finisce a %s, e da li' nessun "
					% [_v(p), _v(_ccd.global_position)]
					+ "giocatore la puo' piu' raccogliere")
	print("[ccd] posata in %d punti attorno al fuoco: %d perse" % [provate, perse])
	if provate < 6:
		_guasto("SONDA CIECA: solo %d pose valide attorno al fuoco, troppo poche "
			% provate + "per dire che la camera non si perde")
	elif perse == 0:
		print("[ccd] ok: dovunque la si posi attorno al telescopio, la si ritrova")
	# --- L'INCIDENTE: la si butta come se uno stipite l'avesse strappata.
	_ccd.prendi(giocatore)
	_ccd.lascia()
	_ccd.global_position = _fuoco.global_position
	_ccd.linear_velocity = Vector3.ZERO
	for _i in 240:
		await _tick()
	var dove := _ccd.global_position
	print("[ccd] strappata di mano al fuoco, dieci secondi dopo: montata=%s, a %s"
		% [_ccd.montata(), _v(dove)])
	if _ccd.montata():
		print("[ccd] ok: la rete l'ha rimessa al fuoco")
	elif _ccd.si_riesce_a_prendere():
		print("[ccd] ok: e' caduta in un posto da cui si riesce a prenderla")
	else:
		_guasto("la camera e' ferma a %s e non c'e' nessun posto da cui un "
			% _v(dove) + "giocatore la potrebbe raccogliere: e' persa per sempre")


## Il fondo invisibile della passerella si toglie di scena spegnendogli il layer:
## e' la meta' del difetto che si rimette, e senza di questo il pozzo resterebbe
## tappato anche con `CAMERA_SI_PERDE=1` - cioe' la sonda direbbe «ok» misurando la
## cura invece del difetto.
func _togli_il_fondo() -> void:
	var fondo := _scena.find_child("FondoPasserella", true, false) as CollisionObject3D
	if fondo == null:
		_guasto("SONDA CIECA: il FondoPasserella non si trova, quindi togliendolo "
			+ "non si rimette niente")
		return
	fondo.collision_layer = 0
	print("[ccd] difetto rimesso: il fondo della passerella e' stato tolto")


## C'e' gia' qualcosa in quel punto? Una posa dentro il tubo o dentro un muro non e'
## una posa: la fisica ne sparerebbe fuori la camera, e il referto racconterebbe di
## un volo che nessun giocatore fara' mai.
func _e_occupato(p: Vector3) -> bool:
	var spazio := _ccd.get_world_3d().direct_space_state
	var palla := SphereShape3D.new()
	palla.radius = 0.10
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = palla
	q.transform = Transform3D(Basis.IDENTITY, p)
	q.collision_mask = Corazza.LAYER_APPOGGI
	q.exclude = [_ccd.get_rid()]
	return not spazio.intersect_shape(q, 1).is_empty()


func _v(p: Vector3) -> String:
	return "%.2f, %.2f, %.2f" % [p.x, p.y, p.z]


func _prova() -> void:
	_scena = load("res://main.tscn").instantiate()
	get_tree().root.add_child(_scena)
	get_tree().current_scene = _scena
	for _i in 20:
		await _tick()

	_ccd = CcdCamera.find_in(get_tree())
	if _ccd == null:
		print("[ccd] la camera non si trova: la prova non vale")
		get_tree().quit(1)
		return
	if OS.get_environment("CAMERA_APPOGGIATA") == "1":
		# Si rimette il difetto e si rimonta da capo: la camera e' gia' nata
		# avvitata, e cambiare la bandiera dopo non la stacca.
		_ccd.appoggiata_e_basta = true
		_ccd.prendi(Player.find_in(get_tree()))
		_ccd.posa()
		await _tick()
	_fuoco = _ccd.get_node_or_null(_ccd.fuoco) as Node3D
	if _fuoco == null:
		_fuoco = _scena.find_child("Fuoco", true, false) as Node3D
	if _fuoco == null:
		print("[ccd] il fuoco del telescopio non si trova: la prova non vale")
		get_tree().quit(1)
		return

	# --- NASCE MONTATA. In un osservatorio la camera sta al suo posto: chi la
	# vuole in mano la va a smontare, e questo e' anche l'unico modo di scoprire
	# che si puo' fare.
	var partenza := _scarto()
	print("[ccd] all'avvio: montata=%s, a %.3f m dalla bocca del focheggiatore"
		% [_ccd.montata(), partenza])
	if not _ccd.montata():
		_guasto("la camera non nasce montata")
	if partenza > 0.20:
		_guasto("montata, la camera sta a %.3f m dal fuoco: non e' avvitata li'"
			% partenza)

	# --- MA DA CHE PARTE? E' il buco che questa prova aveva. Lo scarto dice
	# quanto la camera e' LONTANA dalla bocca, non dove sta: una camera avvitata
	# davanti al focheggiatore e una infilata dentro il tubo distano identico, e
	# passano identiche. In partita si vedeva il corpo dentro il telescopio,
	# mentre qui tutto diceva ok.
	#
	# «FUORI» NON SI DICHIARA, SI MISURA. La Mira sta sull'asse ottico del tubo e
	# il Fuoco sulla bocca del focheggiatore, che da quell'asse esce
	# perpendicolare: la componente della bocca perpendicolare all'asse E' la
	# direzione in cui si monta. Cosi' il controllo non poggia su nessuna
	# convenzione di assi - ed e' proprio una convenzione data per buona (il -Z
	# «avanti» di Godot, dove il modello del telescopio mette invece il +Y) ad
	# aver montato la camera di traverso.
	var mira := _scena.find_child("Mira", true, false) as Node3D
	if mira == null:
		print("[ccd] la mira non si trova: il verso non si puo' misurare")
		get_tree().quit(1)
		return
	var asse_tubo := mira.global_transform.basis.y.normalized()
	var dall_asse := _fuoco.global_position - mira.global_position
	var fuori := (dall_asse - asse_tubo * dall_asse.dot(asse_tubo)).normalized()
	var sporgenza := (_ccd.global_position - _fuoco.global_position).dot(fuori)
	var guarda := _ccd.global_transform.basis.y.dot(fuori)
	print("[ccd] il retro della camera sta %.3f m fuori dalla bocca, e il naso "
		% sporgenza + "guarda dentro per %.2f (1 = dritto dentro)" % -guarda)
	if sporgenza < 0.05:
		_guasto("il corpo della camera sta %.3f m fuori dalla bocca: e' dentro "
			% sporgenza + "il tubo o di traverso, non avvitata davanti")
	if -guarda < 0.9:
		_guasto("l'asse ottico della camera guarda dentro il focheggiatore solo "
			+ "per %.2f: e' montata storta" % -guarda)

	# --- IL CUORE: IL TELESCOPIO SI MUOVE E LEI CI VA INSIEME.
	var montatura := TelescopeMount.find_in(get_tree())
	if montatura == null:
		print("[ccd] la montatura non si trova: la prova non vale")
		get_tree().quit(1)
		return
	var dov_era := _ccd.global_position
	var fuoco_era := _fuoco.global_position
	montatura.punta(75.0, 55.0)
	for _i in 240:
		await _tick()
	var corsa_fuoco := fuoco_era.distance_to(_fuoco.global_position)
	var corsa := dov_era.distance_to(_ccd.global_position)
	var resta := _scarto()
	print("[ccd] dopo un GOTO: il focheggiatore si e' spostato di %.3f m, la "
		% corsa_fuoco + "camera di %.3f, e resta a %.3f dal fuoco"
		% [corsa, resta])
	# SONDA CIECA: si guarda quanto si e' mosso IL FOCHEGGIATORE, non la camera.
	# La prima stesura misurava la camera, ed era il controllo sbagliato nel modo
	# piu' insidioso: col difetto acceso la camera non si muove affatto, quindi la
	# guardia gridava «sonda cieca» proprio quando la sonda stava vedendo il
	# difetto. Chi non e' autorizzato a stare fermo e' il telescopio.
	if corsa_fuoco < 0.20:
		_guasto("SONDA CIECA: il focheggiatore si e' spostato di %.3f m, troppo "
			% corsa_fuoco + "poco per distinguere una camera avvitata da una appoggiata")
	if absf(resta - partenza) > 0.02:
		_guasto("inseguendo, la camera si allontana dal fuoco: %.3f m contro i "
			% resta + "%.3f di partenza - non e' avvitata, e' appoggiata" % partenza)

	# --- SI SMONTA, E TORNA UN OGGETTO. Presa in mano deve staccarsi da sola;
	# lasciata deve cadere, cioe' tornare un corpo del mondo.
	var giocatore := Player.find_in(get_tree())
	_ccd.prendi(giocatore)
	if _ccd.montata():
		_guasto("presa in mano, la camera risulta ancora montata")
	if _ccd.freeze:
		_guasto("smontata, la camera e' ancora congelata: non cadrebbe mai")
	_ccd.lascia()
	var alta := _ccd.global_position.y
	for _i in 180:
		await _tick()
	var scesa := alta - _ccd.global_position.y
	print("[ccd] smontata e lasciata: scende di %.3f m e si ferma" % scesa)
	if scesa < 0.10:
		_guasto("lasciata cadere da %.2f m la camera scende di %.3f m: resta "
			% [alta, scesa] + "appesa a mezz'aria")

	# --- E SI RIMONTA. Riportarla alla bocca deve bastare: e' il gesto vero, e il
	# prompt lo dice da solo quando ci si arriva.
	_ccd.prendi(giocatore)
	_ccd.global_position = _fuoco.global_position
	await _tick()
	var riga := _ccd.prompt_posa()
	print("[ccd] tenendola alla bocca il prompt dice: %s" % riga)
	if not riga.contains("Avvita"):
		_guasto("arrivati al focheggiatore il prompt non propone di avvitarla")
	_ccd.posa()
	await _tick()
	if not _ccd.montata():
		_guasto("riportata alla bocca, la camera non si rimonta")

	# --- E NON SI PUO' PERDERE ---------------------------------------------
	await _non_si_perde(giocatore)

	if _guasti == 0:
		print("[ccd] ok: la camera e' avvitata al fuoco e ci resta anche inseguendo")
		print("[ccd] ok: e non si riesce a perderla nel pozzo del pilastro")
	else:
		print("[ccd] GUASTO: %d controlli falliti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)
