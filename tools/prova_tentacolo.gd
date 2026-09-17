## L'ONDA VIAGGIA DAVVERO VERSO IL BASSO?
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_tentacolo.tscn
##
## PERCHE' UNA SONDA PER UNA COSA CHE SI GUARDA. Il movimento si giudica a occhio,
## e questa sonda non ci prova nemmeno: non dice se è bello. Dice se le quattro
## cose che POSSONO essere sbagliate in silenzio sono a posto, e sono tutte cose
## che a occhio si vedono solo quando sono sbagliate di molto.
##
##   1. LE OSSA STANNO DOVE IL CONTO DICE. `world/tentacolo.gd` calcola una spina
##      e poi orienta cento ossa perché ci stiano sopra. Quel conto passa da una
##      posa globale a una locale dividendo per il padre, e se la divisione è
##      dalla parte sbagliata il tentacolo si piega lo stesso — solo altrove. Qui
##      si confronta ogni osso VERO, letto dallo scheletro, con quello che il conto
##      crede: la direzione E LA POSIZIONE. Per un po' si è confrontata solo la
##      direzione, e le direzioni erano giuste mentre la punta stava quattro metri
##      più su del previsto — ossa lunghe due metri che seguono una curva più lunga
##      di due si accorciano, e un angolo non lo dice.
##   2. L'ONDA VIAGGIA, e viaggia in giù. E' tutta la differenza fra una cosa viva
##      e una bandiera: si misura correlando il movimento di un punto alto con
##      quello di un punto basso e guardando di quanto il secondo è in ritardo. Se
##      il ritardo fosse zero il braccio si piegherebbe tutto insieme; se fosse
##      negativo l'onda salirebbe dalla punta, che è il verso sbagliato.
##   3. NON SI SPEZZA. Fra un osso e il successivo ci sono due metri: se l'onda
##      chiede una curva più stretta di quello che cento segmenti da due metri possono
##      fare, la pelle prende una piega netta e si vede la faccia. Si misura
##      l'angolo massimo fra due segmenti consecutivi.
##   4. ARRIVA DOVE DEVE. La punta deve restare davanti alla facciata e sopra
##      l'erba — non dentro il muro, non sottoterra. L'edificio è il rettangolo
##      x∈[0, 19], z∈[0, 9,5] di `tools/geometria.py`.
##
## IL TEMPO SI MUOVE A MANO, e senza non si misurerebbe niente: in headless un
## fotogramma dura un millesimo di secondo, e aspettando i fotogrammi veri si
## guarderebbero trenta secondi di onda in tre. `Tentacolo.passo()` esiste per
## questo — la sonda spegne `_process` e chiama i passi lei, da un sessantesimo.
extends Node

## Quanto tempo di onda si guarda, e con che passo. Trenta secondi sono quasi due
## periodi del modo lento: meno, e la correlazione non avrebbe abbastanza segnale
## per trovare un ritardo di quattro secondi e mezzo.
const PASSO := 1.0 / 60.0
const DURATA := 84.0

## Da quando si registra il segnale da correlare: prima di allora sta ancora
## scendendo — quarantadue secondi — e scendendo si agita di più
## (`FOGA_IN_DISCESA`). Un'ampiezza che cambia mentre si misura sposta la
## correlazione.
const DA_QUANDO := 48.0

## I due punti che si correlano, in METRI SOPRA LA PUNTA: cinquanta e venti.
## STANNO TUTTI E DUE NEL PEZZO CHE SI VEDE, ed è l'unico modo di misurare: su un
## braccio di millecinquecento metri l'onda ci mette minuti a percorrerlo tutto, e
## fra la cima e la punta il ritardo supererebbe di parecchio il mezzo periodo
## dentro cui la correlazione sa distinguere avanti da indietro. In metri e non in
## frazione, perché le ossa sono lunghe diverse e la frazione non dice più dove.
const PROSSIMALE := 50.0
const DISTALE := 20.0

## Dove si cala, come in `debug/tentacolo.gd` — ricopiato apposta: la sonda deve
## misurare un posto, e se domani quel posto cambia là, qui deve fallire e non
## seguire in silenzio.
const DOVE := Vector2(10.6, 17.0)
const FRANCO := 1.5

## L'edificio in pianta (`geometria.py`: 38 x 19 unità, K = 0,5).
const EDIFICIO := Rect2(0.0, 0.0, 19.0, 9.5)

## Quante ne ha `tools/tentacolo_blender.py`. Ricopiato: se là cambia, qui deve
## fallire invece di seguire in silenzio — la risoluzione della catena è metà
## dell'animazione.
const OSSA_ATTESE := 90

## Quanto può piegare un giunto prima che la pelle faccia la grinza, in gradi.
const PIEGA_MASSIMA := 12.0

## Quanto deve restare fra il tentacolo e l'edificio, in metri, misurato sui giunti
## bassi — quelli che potrebbero entrarci dentro.
const DISTANZA_MINIMA := 2.5

## Sotto questa ampiezza di movimento la correlazione non misura niente: la sonda
## sarebbe cieca e passerebbe anche con l'onda spenta.
const AMPIEZZA_CIECA := 0.10

var _guasti := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[tentacolo] GUASTO: " + msg)


## Preme un tasto per davvero: l'evento entra dal motore e scende per l'albero come
## quello di una tastiera.
##
## `flush_buffered_events()` DOPO OGNI EVENTO, e senza non succede niente. Godot
## accumula gli input e li consegna quando gli pare; `parse_input_event` li mette
## in coda, non li recapita. La prima stesura premeva e guardava al fotogramma
## dopo: il tentacolo non compariva, e la sonda ha accusato lo strumento di non
## rispondere al tasto mentre in partita rispondeva benissimo. Un attrezzo che
## incolpa il codice giusto è peggio di uno rotto.
func _premi(tasto: Key) -> void:
	var giu := InputEventKey.new()
	giu.keycode = tasto
	giu.pressed = true
	Input.parse_input_event(giu)
	Input.flush_buffered_events()
	var su := InputEventKey.new()
	su.keycode = tasto
	su.pressed = false
	Input.parse_input_event(su)
	Input.flush_buffered_events()


func _tentacolo_in(n: Node) -> Tentacolo:
	if n == null:
		return null
	for f in n.get_children():
		if f is Tentacolo:
			return f as Tentacolo
	return null


func _scheletro_di(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n as Skeleton3D
	for f in n.get_children():
		var s := _scheletro_di(f)
		if s != null:
			return s
	return null


func _mesh_di(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n as MeshInstance3D
	for f in n.get_children():
		var m := _mesh_di(f)
		if m != null:
			return m
	return null


func _prato_di(n: Node) -> Prato:
	if n is Prato:
		return n as Prato
	for f in n.get_children():
		var p := _prato_di(f)
		if p != null:
			return p
	return null


## Quanto dista, in orizzontale, un punto dal rettangolo dell'edificio. Zero se ci
## sta dentro.
func _distanza_edificio(p: Vector3) -> float:
	var dx := maxf(maxf(EDIFICIO.position.x - p.x, 0.0),
		p.x - (EDIFICIO.position.x + EDIFICIO.size.x))
	var dz := maxf(maxf(EDIFICIO.position.y - p.z, 0.0),
		p.z - (EDIFICIO.position.y + EDIFICIO.size.y))
	return Vector2(dx, dz).length()


## Fin dove si cerca il ritardo, in secondi. OTTO E NON QUATTORDICI, ed è un limite
## del metodo, non una scelta: il modo lento ha periodo 17 s, e su un segnale
## periodico un ritardo di +4,6 s e uno di -12,4 s sono LA STESSA COSA. Cercando
## fino a 14 la correlazione ha risposto -12,07 — cioè la risposta giusta, letta al
## contrario, che è il modo peggiore di sbagliare. Dentro mezzo periodo l'ambiguità
## non esiste.
const RITARDO_CERCABILE := 8.0


## Di quanto il secondo segnale è in ritardo sul primo, in secondi.
##
## SI NORMALIZZANO PRIMA, e non è pignoleria: il punto basso si muove dieci volte
## più del punto alto, e senza togliere media e scala la correlazione seguirebbe
## l'ampiezza invece del tempo.
func _ritardo_fra(a: PackedFloat32Array, b: PackedFloat32Array, max_s: float) -> float:
	var na := _normalizza(a)
	var nb := _normalizza(b)
	var passi := int(max_s / PASSO)
	var migliore := 0
	var punteggio := -1e30
	for k in range(-passi, passi + 1):
		var somma := 0.0
		var conta := 0
		for i in na.size():
			var j := i + k
			if j < 0 or j >= nb.size():
				continue
			somma += na[i] * nb[j]
			conta += 1
		if conta < na.size() / 2:
			continue
		var media := somma / float(conta)
		if media > punteggio:
			punteggio = media
			migliore = k
	return float(migliore) * PASSO


func _normalizza(v: PackedFloat32Array) -> PackedFloat32Array:
	var media := 0.0
	for x in v:
		media += x
	media /= float(v.size())
	var scarto := 0.0
	for x in v:
		scarto += (x - media) * (x - media)
	scarto = sqrt(scarto / float(v.size()))
	if scarto < 1e-6:
		scarto = 1.0
	var fuori := PackedFloat32Array()
	fuori.resize(v.size())
	for i in v.size():
		fuori[i] = (v[i] - media) / scarto
	return fuori


func _prova() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 6:
		await get_tree().physics_frame

	# IL TASTO. Il resto della sonda cala il tentacolo chiamando i metodi, che è il
	# modo di misurarlo; ma quello che Federico farà è PREMERE F5, e fra le due cose
	# ci sono tre punti che possono rompersi in silenzio — `main.gd` che non
	# installa lo strumento, l'evento che non arriva fino a lui, il nodo che non
	# entra nel mondo. Qui si preme il tasto davvero e si guarda se compare.
	if scena.get_node_or_null("Tentacolo") == null:
		_guasto("main.gd non installa debug/tentacolo.gd: F5 non risponde")
	var mondo := scena.get_node_or_null("%SubViewport")
	_premi(KEY_F5)
	for _f in 3:
		await get_tree().process_frame
	var comparso := _tentacolo_in(mondo)
	if comparso == null:
		_guasto("premuto F5, nel mondo non è comparso nessun tentacolo")
	else:
		print("[tentacolo] F5: compare «%s» a (%.1f, %.1f)" % [
			comparso.name, comparso.global_position.x, comparso.global_position.z])
		_premi(KEY_F5)
		await get_tree().process_frame
		comparso.free()

	var prato := _prato_di(get_tree().root)
	if prato == null:
		_guasto("niente prato: la quota della punta non è misurabile")
		get_tree().quit(1)
		return

	var scena_t := load("res://world/tentacolo.tscn") as PackedScene
	var t := scena_t.instantiate() as Tentacolo
	prato.get_parent().add_child(t)
	t.set_process(false)
	t.posa_sul_prato(DOVE.x, DOVE.y, FRANCO)
	t.scendi()

	var scheletro := _scheletro_di(t)
	if scheletro == null:
		_guasto("nessuno Skeleton3D nel .glb: il tentacolo resterebbe un palo")
		get_tree().quit(1)
		return
	print("[tentacolo] %d ossa, ancoraggio a y=%.2f" % [
		scheletro.get_bone_count(), t.global_position.y])

	# LA PELLE E' LUNGA QUANTO LE OSSA? `Tentacolo.LUNGHEZZA` è ricopiata a mano da
	# `tentacolo_blender.py`, e la testata di quel file lo dice: se le due divergono
	# non si rompe niente di vistoso — l'onda si distribuisce su una lunghezza che
	# non è quella del modello, e la piega esce più stretta o più larga di quanto la
	# pelle pretenda. Si misura l'ingombro vero della mesh, che è l'unico posto in
	# cui la lunghezza del modello è un fatto e non una costante.
	var pelle := _mesh_di(t)
	if pelle == null:
		_guasto("nel .glb non c'è nessuna mesh: c'è lo scheletro e basta")
	else:
		var misura: float = pelle.get_aabb().size[pelle.get_aabb().size.max_axis_index()]
		print("[tentacolo] la pelle misura %.1f m sul lato lungo (LUNGHEZZA = %.1f)" % [
			misura, Tentacolo.LUNGHEZZA])
		if absf(misura - Tentacolo.LUNGHEZZA) > 1.5:
			_guasto("la pelle è lunga %.1f m ma lo script ne conta %.1f: l'onda "
				% [misura, Tentacolo.LUNGHEZZA] + "sta su un braccio che non esiste")
	if scheletro.get_bone_count() != OSSA_ATTESE:
		_guasto("%d ossa invece di %d: il modello non è quello che lo script si aspetta"
			% [scheletro.get_bone_count(), OSSA_ATTESE])

	# --- la discesa ----------------------------------------------------------
	var alta := t.punta().y
	var passi := int(DURATA / PASSO)
	var prossimale := PackedFloat32Array()
	var distale := PackedFloat32Array()
	var piega_massima := 0.0
	# DOVE e QUANDO: un numero solo non dice cosa correggere, e le cause possibili
	# stanno in posti diversi — la punta, la tenuta, le ossa lunghe di metà colonna
	var piega_dove := 0.0
	var piega_quando := 0.0
	var scarto_ossa := 0.0
	var scarto_posizioni := 0.0
	var distanza_minima := 1e9
	var punta_minima := 1e9
	var punta_massima := -1e9
	var ampiezza_punta := 0.0
	var centro_punta := Vector2(t.global_position.x, t.global_position.z)

	for n in passi:
		t.passo(PASSO)
		var g := t.giunti()
		var quanti := g.size()
		var s_pros := t.giunto_a(PROSSIMALE)
		var s_dist := t.giunto_a(DISTALE)
		if float(n) * PASSO >= DA_QUANDO:
			prossimale.append(g[s_pros].x - t.global_position.x)
			distale.append(g[s_dist].x - t.global_position.x)

		# la piega fra segmenti consecutivi
		for k in range(quanti - 2):
			var a := (g[k + 1] - g[k]).normalized()
			var b := (g[k + 2] - g[k + 1]).normalized()
			var piega := rad_to_deg(a.angle_to(b))
			if piega > piega_massima:
				piega_massima = piega
				piega_dove = t.metri_dalla_punta(k + 1)
				piega_quando = float(n) * PASSO

		# le ossa vere contro la curva voluta: una volta ogni mezzo secondo basta
		if n % 30 == 0:
			for k in range(scheletro.get_bone_count() - 1):
				var testa: Vector3 = scheletro.global_transform * scheletro.get_bone_global_pose(k).origin
				var testa2: Vector3 = scheletro.global_transform * scheletro.get_bone_global_pose(k + 1).origin
				var vera := (testa2 - testa).normalized()
				var voluta := (g[k + 1] - g[k]).normalized()
				scarto_ossa = maxf(scarto_ossa, rad_to_deg(vera.angle_to(voluta)))
				scarto_posizioni = maxf(scarto_posizioni, testa.distance_to(g[k]))

		var punta := t.punta()
		# quando è arrivata: quota sull'erba, distanza dall'edificio, giro della punta
		if float(n) * PASSO > DA_QUANDO:
			var suolo: float = prato.position.y + FormaPrato.altezza(
				Vector2(punta.x, punta.z), prato.sito())
			punta_minima = minf(punta_minima, punta.y - suolo)
			punta_massima = maxf(punta_massima, punta.y - suolo)
			ampiezza_punta = maxf(ampiezza_punta,
				Vector2(punta.x, punta.z).distance_to(centro_punta))
			for k in quanti:
				if g[k].y < 8.0:
					distanza_minima = minf(distanza_minima, _distanza_edificio(g[k]))

	print("[tentacolo] discesa: la punta passa da y=%.1f a %.1f" % [alta, t.punta().y])
	print("[tentacolo] piega massima fra segmenti  %.1f gradi  (limite %.0f), a %.0f m dalla punta, al secondo %.1f" % [
		piega_massima, PIEGA_MASSIMA, piega_dove, piega_quando])
	print("[tentacolo] le ossa seguono la curva a  %.3f gradi e %.3f m" % [
		scarto_ossa, scarto_posizioni])
	print("[tentacolo] punta sull'erba  da %.2f a %.2f m,  gira entro %.2f m dall'asse" % [
		punta_minima, punta_massima, ampiezza_punta])
	print("[tentacolo] dall'edificio, sotto gli 8 m:  %.2f m" % distanza_minima)

	var ampiezza_alta := _ampiezza(prossimale)
	var ampiezza_bassa := _ampiezza(distale)
	if ampiezza_bassa < AMPIEZZA_CIECA:
		_guasto("SONDA CIECA: la punta si muove di %.3f m, non c'è onda da misurare"
			% ampiezza_bassa)
	else:
		var ritardo := _ritardo_fra(prossimale, distale, RITARDO_CERCABILE)
		print("[tentacolo] ampiezza a %.0f m: %.2f m   a %.0f m: %.2f m" % [
			PROSSIMALE, ampiezza_alta, DISTALE, ampiezza_bassa])
		print("[tentacolo] l'onda scende fra i due punti in %.2f s (attesi ~3,2)"
			% ritardo)
		if ritardo <= 0.05:
			_guasto("l'onda NON scende: ritardo %.2f s fra %.0f e %.0f m"
				% [ritardo, PROSSIMALE, DISTALE])
		elif ritardo > 12.0:
			_guasto("ritardo di %.2f s: l'onda non arriva mai in fondo" % ritardo)
		# IL CORPO SI MUOVE, LA PUNTA NO: è l'inviluppo, ed è la cosa che fa leggere
		# il tentacolo come una cosa che è ARRIVATA da qualche parte invece che come
		# un nastro al vento. Si confronta il giro della punta con l'ampiezza del
		# corpo venti metri più su. (Confrontare i due punti fra loro non direbbe
		# niente: distano trenta metri su duecento, e lì l'inviluppo è quasi piatto.)
		if ampiezza_bassa < 2.6 * ampiezza_punta:
			_guasto("il corpo si muove come la punta (%.2f contro %.2f m): l'inviluppo non tiene"
				% [ampiezza_bassa, 2.0 * ampiezza_punta])

	if piega_massima > PIEGA_MASSIMA:
		_guasto("piega di %.1f gradi fra due segmenti: la pelle fa la grinza"
			% piega_massima)
	if scarto_ossa > 0.5:
		_guasto("le ossa si piegano a %.2f gradi dalla curva voluta" % scarto_ossa)
	if scarto_posizioni > 0.05:
		_guasto("le ossa stanno a %.2f m da dove il conto le mette: la punta vera non è "
			% scarto_posizioni + "quella che la sonda misura")
	if punta_minima < 0.3:
		_guasto("la punta scende a %.2f m dall'erba: ci entra dentro" % punta_minima)
	if distanza_minima < DISTANZA_MINIMA:
		_guasto("passa a %.2f m dall'edificio" % distanza_minima)

	# --- la risalita ---------------------------------------------------------
	var risalito := [false]
	t.risalito.connect(func() -> void: risalito[0] = true)
	t.risali()
	for _n in int(32.0 / PASSO):
		t.passo(PASSO)
	print("[tentacolo] risalita: la punta torna a y=%.1f" % t.punta().y)
	if not risalito[0]:
		_guasto("la risalita non segnala di essere finita: il nodo non verrebbe liberato")
	if t.punta().y < Tentacolo.SPARISCE:
		_guasto("dopo la risalita la punta sta a y=%.1f: si vedrebbe ancora" % t.punta().y)

	print("")
	print("[tentacolo] %s" % ("TUTTO A POSTO" if _guasti == 0 else "%d GUASTI" % _guasti))
	get_tree().quit(1 if _guasti > 0 else 0)


## Di quanto si muove un segnale, da picco a picco.
func _ampiezza(v: PackedFloat32Array) -> float:
	var basso := 1e30
	var alto := -1e30
	for x in v:
		basso = minf(basso, x)
		alto = maxf(alto, x)
	return alto - basso
