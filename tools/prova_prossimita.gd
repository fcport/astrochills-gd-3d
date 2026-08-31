## Banco della luce di prossimità: rivela quello che sfiori, NON schiarisce la stanza.
##
## La lampada che il giocatore si porta addosso è una di quelle cose che a occhio
## non si sanno giudicare. Guardando uno scatto si vede «più chiaro» e si è
## contenti; quello che non si vede è che si è alzato anche il fondo della stanza,
## cioè si è buttata via l'unica cosa che il buio doveva dare. E siccome la si tara
## alzando un numero finché non piace, si finisce sempre un pochino oltre.
##
## Qui la si misura invece di guardarla. Si cerca il tratto libero più lungo della
## sala telescopio, si mette il giocatore a quattro distanze da quel muro e si
## fotografa lo stesso identico punto due volte, con la lampada accesa e spenta.
## Quello che conta non è quanto viene chiaro: è **la differenza fra le due**, e
## come muore con la distanza.
##
##   1. da vicino si deve vedere qualcosa (o la lampada non serve a niente);
##   2. in fondo NON si deve vedere niente (o si è schiarita la stanza);
##   3. nemmeno da vicino il muro deve diventare una parete illuminata.
##
## Il terzo controllo è quello che tiene onesta la taratura: senza, basta alzare
## l'energia finché «si vede bene» e la notte è finita.
##
##     Godot --script tools/prova_prossimita.gd
##
## NIENTE `--headless`: senza rendering il viewport torna un'immagine vuota e il
## banco misurerebbe zero dappertutto, dichiarando che va tutto bene.
extends SceneTree

## Quanti fotogrammi si lascia assestare la scena dopo aver mosso il giocatore o
## toccato la lampada.
##
## NON È UN NUMERO SCRITTO QUI: si ricava da quanto la lampada ci mette davvero a
## salire. Prima era otto, quando la salita durava un terzo di secondo — il banco
## fotografava a metà salita e leggeva numeri che nel gioco non esistevano. Poi la
## salita è diventata di tre secondi, per dare l'idea dell'occhio che si abitua, e un
## quaranta scritto a mano avrebbe rifatto lo stesso sbaglio in silenzio: infatti l'ha
## rifatto, e il banco ha accusato «una lampada di là dal muro la smorza» mentre la
## lampada stava soltanto ancora salendo. Chi rallenta la lampada non deve venire a
## ricordarsi di questo file.
## La costante si legge DALLO SCRIPT, non dalla classe: `class_name` vive nella
## cache che scrive l'editor, e un banco lanciato con `--script` su un progetto
## appena clonato quella cache non ce l'ha.
static func assesto() -> int:
	var s: GDScript = load("res://world/player/luce_prossimita.gd")
	var lenta: float = s.get_script_constant_map()["SI_ABITUA"]
	return int(60.0 / lenta * 1.25) + 10

## A che distanze dal muro si misura. La prima è «ci sono quasi addosso», l'ultima
## è «è in fondo alla stanza e deve restare nera».
const DISTANZE := [0.7, 1.5, 2.5, 5.0]

## Quanto si deve alzare il muro più vicino, su 255. Sotto questa soglia la lampada
## c'è ma non fa il suo mestiere.
const ALZATA_MINIMA := 8.0

## Quanto può alzarsi il muro più lontano, su 255. È il controllo dell'atmosfera:
## il fondo della stanza deve restare esattamente com'era.
const ALZATA_MASSIMA_LONTANO := 1.5

## Quanto può alzarsi una parete quando LA PLAFONIERA È ACCESA, su 255. È il
## controllo che è nato da un difetto visto giocando: la lampada lavorava anche a
## luce accesa, e avvicinandosi a una parete illuminata compariva un alone che
## seguiva la testa. In una stanza accesa la lampada non deve esistere.
const ACCESA_MASSIMA := 1.5

## Quanto può alzarsi la parete VISTA DALL'ALTRA STANZA, su 255. La lampada non
## fa ombra — costa zero e a questa energia dovrebbe restare di qua dal muro. Questo
## numero è la verifica che «dovrebbe» sia vero.
const FUGA_MASSIMA := 1.5

## Quanto può venire chiaro, su 255, il punto PIÙ CHIARO dell'inquadratura da
## settanta centimetri. Non il centro: il centro è dove capita, e al primo giro
## capitava su una porta di noce che con l'albedo che ha resta scura qualunque luce
## le arrivi. Il controllo passava mentre l'intonaco lì accanto, nella stessa foto,
## era a duecento su duecentocinquantacinque — cioè un lampione. Il caso peggiore è
## la superficie più chiara che la lampada illumina, e si legge col 98º percentile
## dell'immagine: il massimo secco lo deciderebbe un riflesso da un pixel solo.
const CHIARO_MASSIMO := 110.0

var _scena: Node3D = null
var _corpo: CharacterBody3D = null
var _luce: OmniLight3D = null
var _muro := Vector3.ZERO
var _fuori := Vector3.ZERO

## La camera che guarda dall'ALTRA parte del muro. Non è un vezzo: la fuga di luce
## attraverso una parete è, per definizione, una cosa che dal lato illuminato non si
## vede. Serve stare dall'altra parte.
## La plafoniera del locale in cui si misura, per la prova a luce accesa.
var _plafoniera: Light3D = null

## Una plafoniera che dal punto di misura non si vede: sta in un altro locale.
var _altrove: Light3D = null

var _spia: Camera3D = null
var _oltre := Vector3.ZERO
var _mira := Vector3.ZERO

var _prese: Array = []
var _i := -1
var _attesa := 0
var _letture := {}
var _guasti: Array[String] = []


func _process(_d: float) -> bool:
	if _i < 0:
		_prepara()
		return false
	if _attesa > 0:
		_attesa -= 1
		return false
	_leggi()
	_i += 1
	if _i >= _prese.size():
		return _conclusione()
	_sistema()
	return false


## Trova il muro su cui misurare e apparecchia l'elenco delle prese.
func _prepara() -> void:
	_scena = load("res://world/blockout.tscn").instantiate()
	get_root().add_child(_scena)
	_corpo = _scena.get_node_or_null("Player") as CharacterBody3D
	if _corpo == null:
		push_error("nel blockout non c'e' nessun Player")
		quit(1)
		return
	# da spento non simula fisica: resta dove lo si mette invece di cadere
	if _corpo.has_method("set_enabled"):
		_corpo.call("set_enabled", false)
	# E SI SPEGNE TUTTO IL RESTO. Nel primo giro il banco ha misurato un muro sotto
	# una plafoniera accesa: la lampada di prossimita' aggiungeva pochi livelli su una
	# parete che ne aveva gia' centoventi, e il conto non voleva dire niente. La
	# domanda e' cosa fa questa lampada IN UNA STANZA AL BUIO, quindi il buio glielo
	# si fa intorno.
	_spegni(_scena)
	var cam := _corpo.get_node_or_null("Camera") as Camera3D
	if cam != null:
		cam.current = true          # senza, si fotografa un viewport senza camera
	print("camera: %s" % ("assente" if cam == null else "attiva=%s" % cam.current))
	_luce = _corpo.get_node_or_null("Camera/Prossimita") as OmniLight3D
	if _luce == null:
		push_error("il giocatore non ha nessuna luce di prossimita'")
		quit(1)
		return
	_cerca_muro()
	for d in DISTANZE:
		_prese.append({"d": d, "accesa": false})
		_prese.append({"d": d, "accesa": true})
	# e la stessa parete con la plafoniera accesa: li' la lampada deve sparire
	_plafoniera = _piu_vicina(_muro + _fuori * DISTANZE[0])
	if _plafoniera != null:
		_prese.append({"d": DISTANZE[0], "accesa": false, "illuminato": true})
		_prese.append({"d": DISTANZE[0], "accesa": true, "illuminato": true})
	# E IL RISCHIO OPPOSTO. Una lampada che si spegne dove c'e' luce si spegne anche
	# dove la luce sta di la' dal muro, se nessuno controlla: il corridoio acceso
	# lascerebbe al buio pesto chi e' chiuso nel magazzino. Si accende una plafoniera
	# che da qui NON si vede e si pretende che qui non cambi niente.
	_altrove = _dietro_un_muro(_muro + _fuori * DISTANZE[0])
	if _altrove != null:
		_prese.append({"d": DISTANZE[0], "accesa": false, "altrove": true})
		_prese.append({"d": DISTANZE[0], "accesa": true, "altrove": true})
	if _cerca_oltre():
		_spia = Camera3D.new()
		_spia.fov = 55.0
		_scena.add_child(_spia)
		_prese.append({"d": 0.5, "accesa": false, "oltre": true})
		_prese.append({"d": 0.5, "accesa": true, "oltre": true})
	print("muro di prova a (%.2f, %.2f, %.2f)" % [_muro.x, _muro.y, _muro.z])
	_i = 0
	_sistema()


## La lampada della scena più vicina a un punto: è la plafoniera di quel locale.
func _piu_vicina(punto: Vector3) -> Light3D:
	var trovate: Array = []
	_raccogli(_scena, trovate)
	var meglio: Light3D = null
	var quanto := 1e9
	for L in trovate:
		var d: float = punto.distance_to((L as Light3D).global_position)
		if d < quanto:
			quanto = d
			meglio = L
	return meglio


func _raccogli(n: Node, dentro: Array) -> void:
	if n is Light3D and not _corpo.is_ancestor_of(n):
		dentro.append(n)
	for f in n.get_children():
		_raccogli(f, dentro)


## Una lampada che da `punto` non si vede, perche' in mezzo c'e' un muro.
func _dietro_un_muro(punto: Vector3) -> Light3D:
	var spazio := _scena.get_world_3d().direct_space_state
	var trovate: Array = []
	_raccogli(_scena, trovate)
	for L in trovate:
		var q := PhysicsRayQueryParameters3D.create(punto, (L as Light3D).global_position)
		q.exclude = [_corpo.get_rid()]
		if not spazio.intersect_ray(q).is_empty():
			return L
	return null


## Spegne ogni lampada della scena, comunque sia stata accesa.
func _spegni(n: Node) -> void:
	if n is Light3D:
		(n as Light3D).visible = false
	if n.name == "Accesa" and n is Node3D:
		(n as Node3D).visible = false
	for f in n.get_children():
		_spegni(f)


## Da dove si prova a guardare. LE PLAFONIERE FANNO DA SEGNAPOSTO: stanno per
## costruzione al centro dei locali, sono già nel file e nessuno le sposta senza
## spostare la stanza. Un punto di partenza scritto a mano qui dentro era finito in
## un vano di porta, e da lì non c'era un tratto di parete libera abbastanza lungo
## per misurare niente.
func _da_dove() -> Array:
	var punti: Array = []
	_raduna(_scena, punti)
	if punti.is_empty():
		punti.append(Vector3(2.60, 1.65, 5.90))
	return punti


func _raduna(n: Node, punti: Array) -> void:
	if n is Light3D and not _corpo.is_ancestor_of(n):
		var p: Vector3 = (n as Light3D).global_position
		punti.append(Vector3(p.x, 1.65, p.z))
	for f in n.get_children():
		_raduna(f, punti)


## IL PUNTO DI MISURA NON SI SCRIVE A MANO. Un paio di coordinate copiate qui
## dentro sopravvivono a chi sposta un muro e da quel giorno il banco misura una
## parete che non c'è più. Si spara invece un ventaglio di raggi orizzontali dal
## centro della sala e si tiene il più lungo che ci stia: è, per costruzione, il
## tratto dove le quattro distanze ci stanno tutte.
func _cerca_muro() -> void:
	var spazio := _scena.get_world_3d().direct_space_state
	var meglio := 0.0
	for da in _da_dove():
		for k in range(48):
			var a := TAU * k / 48.0
			var dir := Vector3(sin(a), 0.0, cos(a))
			var par := PhysicsRayQueryParameters3D.create(da, da + dir * 14.0)
			par.exclude = [_corpo.get_rid()]
			var urto := spazio.intersect_ray(par)
			if urto.is_empty():
				continue
			var quanto: float = da.distance_to(urto["position"])
			# oltre le distanze di prova non serve, e piu' lontano si finisce fuori
			# dalla sala passando da una porta aperta
			if quanto <= meglio or quanto >= 12.0:
				continue
			# DEV'ESSERE UNA PARETE, NON UN VANO. Al primo giro il raggio piu' lungo
			# usciva da una porta aperta e finiva su una lastra scura che alla luce non
			# rispondeva: il banco misurava lo stesso 6,6 a ogni distanza e accusava la
			# lampada di non funzionare. Si sparano quattro raggi paralleli scostati di
			# venticinque centimetri: se non arrivano tutti alla stessa distanza, li' non
			# c'e' una parete piana ma uno spigolo, uno stipite o un'apertura.
			var lato := Vector3(dir.z, 0.0, -dir.x)
			var piana := true
			for s in [-0.25, 0.25, -0.5, 0.5]:
				var q := PhysicsRayQueryParameters3D.create(da + lato * s,
					da + lato * s + dir * 14.0)
				q.exclude = [_corpo.get_rid()]
				var u2 := spazio.intersect_ray(q)
				if u2.is_empty() or absf((da + lato * s).distance_to(u2["position"]) - quanto) > 0.30:
					piana = false
					break
			# e verticale: un banco che finisce a misurare il soffitto misura una cosa
			# che il giocatore non guarda mai
			if not piana or absf((urto["normal"] as Vector3).y) > 0.2:
				continue
			# E DAVANTI DEV'ESSERCI CAMPO APERTO. La prima parete che passava tutti i
			# controlli era il battente di una porta, con lo stipite a venti centimetri
			# di lato: quel pezzo di muro si prendeva quasi tutta la luce e il banco
			# leggeva duecentoquaranta su duecentocinquantacinque, dando la colpa a una
			# lampada che sul bersaglio vero ne alzava trenta. Da dove si misura ci
			# devono essere un metro e mezzo liberi per parte, o non si sta misurando
			# una parete: si sta misurando un angolo.
			var posto: Vector3 = urto["position"] - dir * DISTANZE[0]
			var largo := true
			for s in [-1.0, 1.0]:
				var q := PhysicsRayQueryParameters3D.create(posto, posto + lato * (s * 1.5))
				q.exclude = [_corpo.get_rid()]
				if not spazio.intersect_ray(q).is_empty():
					largo = false
					break
			if not largo:
				continue
			meglio = quanto
			_muro = urto["position"]
			_fuori = -dir
	if meglio < DISTANZE[DISTANZE.size() - 1] + 0.5:
		push_error("non c'e' un tratto libero lungo abbastanza: %.1f m" % meglio)
		quit(1)


## Cerca un punto d'osservazione dall'altra parte della parete di prova.
##
## Dev'essere AL CHIUSO: se di là c'è il prato, la lettura la fa il cielo notturno e
## non dice niente sulla lampada. Il criterio è avere un soffitto sopra la testa.
##
## E SI GUARDA LA PARETE DI FRONTE, NON IL RETRO DEL MURO. Al primo tentativo la
## spia inquadrava il retro della parete di prova e riportava zero fuga anche con la
## lampada a quaranta di energia — sembrava una bella notizia, ed era un errore di
## fisica elementare: quella faccia dà le spalle alla lampada, e una superficie
## girata dall'altra parte resta nera che la luce le arrivi o no. La luce che passa
## il muro si posa su ciò che nella stanza accanto è rivolto VERSO di lei, cioè la
## parete opposta. È lì che si misura.
##
## E SI MISURA IL PAVIMENTO, non la parete di fronte. La parete di fronte è dove
## capita: dietro il muro di prova la stanza è profonda quattro metri e mezzo, cioè
## più della portata della lampada, e la fuga usciva zero per un motivo che non
## dipende dalla lampada — bastava una stanza più stretta per cambiare risposta. Il
## pavimento invece sta SEMPRE a un metro e mezzo dalla lampada, in qualunque
## stanza, ed è sempre rivolto verso l'alto cioè verso di lei. È il caso peggiore, e
## non dipende da quale parete il banco ha pescato.
func _cerca_oltre() -> bool:
	var spazio := _scena.get_world_3d().direct_space_state
	# si entra nel muro e si esce dall'altra parte, cercando il primo spazio libero
	for dentro in [0.35, 0.5, 0.7, 0.9, 1.2, 1.6]:
		var p: Vector3 = _muro - _fuori * dentro
		# PRIMA DI TUTTO: DEV'ESSERE ARIA. Il criterio del pavimento sotto e del
		# soffitto sopra e' vero anche DENTRO il muro, ed e' li' che la spia e'
		# finita al primo giro: inquadrava il nero interno di una parete e riportava
		# nessuna fuga anche con la lampada a quaranta di energia. Un controllo che
		# non puo' fallire non e' un controllo.
		var punto := PhysicsPointQueryParameters3D.new()
		punto.position = p
		if not spazio.intersect_point(punto, 1).is_empty():
			continue
		var giu := PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * 3.0)
		var su := PhysicsRayQueryParameters3D.create(p, p + Vector3.UP * 4.0)
		if spazio.intersect_ray(giu).is_empty() or spazio.intersect_ray(su).is_empty():
			continue                       # niente pavimento o niente soffitto: e' fuori
		# il pezzo di pavimento subito oltre il muro: quello che la luce filtrata
		# colpisce per primo, e che c'e' in qualunque stanza
		var sotto := PhysicsRayQueryParameters3D.create(p - _fuori * 0.35,
			p - _fuori * 0.35 + Vector3.DOWN * 3.0)
		var visto := spazio.intersect_ray(sotto)
		if visto.is_empty():
			continue
		_oltre = p
		_mira = visto["position"]
		print("spia %.2f m dietro il muro, guarda il pavimento a %.2f m dalla lampada"
			% [dentro, _mira.distance_to(_muro + _fuori * 0.5 - Vector3(0, 0.4, 0))])
		return true
	print("dietro la parete di prova non c'e' una stanza: fuga non misurata")
	return false


## Mette il giocatore alla distanza della presa corrente, guardando il muro.
func _sistema() -> void:
	var presa: Dictionary = _prese[_i]
	var occhio: Vector3 = _muro + _fuori * float(presa["d"])
	_corpo.global_position = Vector3(occhio.x, occhio.y - Player.EYE_HEIGHT, occhio.z)
	# la camera guarda lungo -Z locale: questa imbardata la punta contro il muro
	_corpo.rotation.y = atan2(_fuori.x, _fuori.z)
	_luce.visible = bool(presa["accesa"])
	# la plafoniera si accende solo per le prese che la vogliono, e si spegne per
	# tutte le altre: accesa una volta resterebbe accesa e falserebbe il resto
	for coppia in [[_plafoniera, "illuminato"], [_altrove, "altrove"]]:
		if coppia[0] == null:
			continue
		var acceso: bool = presa.get(coppia[1], false)
		var n: Node = coppia[0]
		while n != null and n != _scena:
			if n is Node3D:
				(n as Node3D).visible = acceso
			n = n.get_parent()
	if presa.get("oltre", false):
		_spia.global_position = _oltre
		_spia.look_at(_mira, Vector3.UP)
		_spia.current = true
	elif _spia != null:
		_spia.current = false
		(_corpo.get_node("Camera") as Camera3D).current = true
	_attesa = assesto()


## Legge il centro dell'inquadratura. Non un pixel solo: undici per undici, mediati.
## Un pixel singolo su una parete con texture è rumore, e il rumore su una misura da
## pochi livelli su 255 è tutta la misura.
func _leggi() -> void:
	var img := get_root().get_texture().get_image()
	var cx := img.get_width() / 2
	var cy := img.get_height() / 2
	var somma := 0.0
	var n := 0
	for y in range(cy - 5, cy + 6):
		for x in range(cx - 5, cx + 6):
			var c := img.get_pixel(x, y)
			somma += (c.r + c.g + c.b) / 3.0 * 255.0
			n += 1
	# e il punto piu' chiaro di tutta l'inquadratura, campionando un pixel ogni
	# quattro: e' il caso peggiore, quello che dice se la stanza sta diventando chiara
	var tutti: Array[float] = []
	for y in range(0, img.get_height(), 4):
		for x in range(0, img.get_width(), 4):
			var c := img.get_pixel(x, y)
			tutti.append((c.r + c.g + c.b) / 3.0 * 255.0)
	tutti.sort()
	var presa: Dictionary = _prese[_i]
	var chiave = presa["d"]
	if presa.get("oltre", false):
		chiave = "oltre"
	elif presa.get("illuminato", false):
		chiave = "accesa"
	elif presa.get("altrove", false):
		chiave = "altrove"
	# UNA FOTO LA LASCIA COMUNQUE. I numeri dicono di quanto si e' alzato il muro, non
	# se l'ombra si stacca dai battiscopa o se l'intonaco granisce: quelle si vedono.
	if presa.get("oltre", false):
		img.save_png("user://spia_%s.png" % ("accesa" if presa["accesa"] else "spenta"))
	elif presa["accesa"] and is_equal_approx(presa["d"], DISTANZE[0]):
		img.save_png("user://prossimita.png")
	if not _letture.has(chiave):
		_letture[chiave] = {}
	var stato := "accesa" if presa["accesa"] else "spenta"
	_letture[chiave][stato] = somma / n
	_letture[chiave]["chiaro_" + stato] = tutti[int(tutti.size() * 0.98)]


func _conclusione() -> bool:
	print("\n  distanza    spenta   accesa    alzata")
	for d in DISTANZE:
		var spenta: float = _letture[d]["spenta"]
		var accesa: float = _letture[d]["accesa"]
		print("  %5.1f m     %5.1f    %5.1f    %+6.1f" % [d, spenta, accesa, accesa - spenta])

	var vicino: float = DISTANZE[0]
	var lontano: float = DISTANZE[DISTANZE.size() - 1]
	var alzata_vicino: float = _letture[vicino]["accesa"] - _letture[vicino]["spenta"]
	var alzata_lontano: float = _letture[lontano]["accesa"] - _letture[lontano]["spenta"]

	if alzata_vicino < ALZATA_MINIMA:
		_guasti.append("a %.1f m alza di soli %.1f livelli: non si vede niente di piu'"
			% [vicino, alzata_vicino])
	if alzata_lontano > ALZATA_MASSIMA_LONTANO:
		_guasti.append("a %.1f m alza di %.1f livelli: sta schiarendo la stanza, non "
			% [lontano, alzata_lontano] + "quello che hai vicino")
	if _letture.has("accesa"):
		var con: float = _letture["accesa"]["accesa"] - _letture["accesa"]["spenta"]
		print("  a luce accesa    %5.1f    %5.1f    %+6.1f"
			% [_letture["accesa"]["spenta"], _letture["accesa"]["accesa"], con])
		if con > ACCESA_MASSIMA:
			_guasti.append("con la plafoniera accesa la lampada alza ancora di %.1f "
				% con + "livelli: si vede il proprio alone su una parete illuminata")

	if _letture.has("altrove"):
		var la: float = _letture["altrove"]["accesa"] - _letture["altrove"]["spenta"]
		print("  luce di la'      %5.1f    %5.1f    %+6.1f"
			% [_letture["altrove"]["spenta"], _letture["altrove"]["accesa"], la])
		# NON basta che sia accesa: dev'essere PIENA. Al primo giro il confronto era
		# con ALZATA_MINIMA, e togliendo il controllo dell'occlusione la lampada
		# scendeva a meta' senza che il banco fiatasse - una stanza buia illuminata a
		# meta' perche' il corridoio di la' e' acceso e' lo stesso difetto, solo piu'
		# educato. Si confronta con quanto alzava al buio, alla stessa distanza.
		var al_buio: float = _letture[DISTANZE[0]]["accesa"] - _letture[DISTANZE[0]]["spenta"]
		if la < al_buio - 3.0:
			_guasti.append("una lampada accesa DI LA' DAL MURO la smorza: qui alza di "
				+ "%.1f livelli invece dei %.1f che fa al buio" % [la, al_buio])

	if _letture.has("oltre"):
		var fuga: float = _letture["oltre"]["accesa"] - _letture["oltre"]["spenta"]
		print("  di la' dal muro   %5.1f    %5.1f    %+6.1f"
			% [_letture["oltre"]["spenta"], _letture["oltre"]["accesa"], fuga])
		if fuga > FUGA_MASSIMA:
			_guasti.append("la lampada si vede dalla stanza accanto: alza il muro di "
				+ "%.1f livelli attraverso l'intonaco" % fuga)

	print("
  a %.1f m il punto piu' chiaro passa da %.0f a %.0f su 255"
		% [vicino, _letture[vicino]["chiaro_spenta"], _letture[vicino]["chiaro_accesa"]])
	if _letture[vicino]["chiaro_accesa"] > CHIARO_MASSIMO:
		_guasti.append("a %.1f m si arriva a %.0f su 255: e' una stanza illuminata, "
			% [vicino, _letture[vicino]["chiaro_accesa"]] + "non una cosa svelata")

	print("\ndistanze provate: %d, guasti: %d" % [DISTANZE.size(), _guasti.size()])
	for g in _guasti:
		print("  " + g)
	quit(1 if _guasti.size() > 0 else 0)
	return true
