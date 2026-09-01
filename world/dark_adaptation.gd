## L'OCCHIO CHE SI FA IL BUIO: in cupola, a luci spente e cupola aperta, il nero
## smette di essere nero assoluto e si comincia a intravedere.
##
## L'IDEA È DI FEDERICO, e vale la pena scriverla com'è arrivata: «con la cupola
## aperta e le luci spente, per lo stesso principio per cui si attiva l'abituamento
## degli occhi, alziamo leggermente il punto di nero — sembra che vedi un po'
## meglio, una leggera diffusione, solo nella sala telescopio».
##
## PERCHÉ È UN AGGIUSTAMENTO DI CAMERA E NON UNA LAMPADA. L'adattamento al buio non
## è una cosa della stanza: è una cosa dell'OCCHIO. Metterlo come luce vorrebbe dire
## una sorgente che illumina uniformemente ogni superficie della cupola e nessuna di
## quelle accanto — cioè una lampada che i muri devono fermare, che è quello che ha
## già fatto `sky_light.gd` per il cielo e che qui sarebbe la seconda copia dello
## stesso attrezzo per un fenomeno diverso. Alzare il punto di nero della SCENA
## INQUADRATA è letteralmente quello che fa la retina: non arriva più luce, cambia
## la risposta a quella che c'è.
##
## COME: `Environment.adjustment_color_correction` con una rampa che parte da un
## grigio-blu invece che dal nero. Il LUT a una dimensione mappa ogni canale
## attraverso la rampa, quindi `fuori = alzata + dentro * (1 - alzata)`: i neri
## salgono, i bianchi restano dove sono, e in mezzo la curva resta dritta. Non è un
## contrasto abbassato — è esattamente e solo il fondo che si stacca dal nero.
##
## IL COLORE DELL'ALZATA NON È GRIGIO: è freddo, e viene dalla stessa famiglia della
## luce del cielo. Un'alzata neutra fa cenere; quella azzurrina fa notte, ed è anche
## quello che l'occhio fa davvero — al buio la visione passa ai bastoncelli, che sono
## ciechi al rosso e spostano tutto verso il blu (l'effetto Purkinje). Non è un
## vezzo: è il motivo per cui le sale di controllo hanno la luce rossa, cioè la
## stessa ragione che sta scritta in D-011.
##
## SALE PIANO E SCENDE DI COLPO, come l'originale. Farsi l'occhio costa venti minuti
## veri e perderlo costa un lampo: qui i venti minuti sono compressi in nove secondi
## — un gioco non può chiedere venti minuti di attesa a occhi aperti — ma
## l'ASIMMETRIA resta intera, perché è lei a dare il senso. Accendere la luce in
## cupola non è gratis, e lo si impara accendendola.
class_name DarkAdaptation
extends Area3D

## Chi ha bisogno di questo volume lo trova per GRUPPO, mai per percorso di nodo:
## stessa regola di `IndoorsVolume` e di `DomeActivity`.
const GROUP := &"dark_adaptation"

## Quanto si alza il punto di nero, ad adattamento pieno. Sono i valori del LUT nel
## punto zero della rampa, cioè: un pixel nero esce così.
##
## PICCOLO, E LA MISURA DEL «PICCOLO» È CHE IL BIANCO NON SI MUOVE. La rampa alza i
## neri e lascia i bianchi: se l'alzata fosse grossa, la scena non sembrerebbe più
## illuminata — sembrerebbe SBIADITA, che è il difetto che si ottiene sempre quando
## si cerca di far vedere di più togliendo contrasto.
const ALZATA := Color(0.036, 0.042, 0.058)

## Quanti secondi per farsi l'occhio, da zero a pieno.
##
## CINQUANTA, E LI HA CHIESTI FEDERICO CONTRO I MIEI NOVE: «non è che appena apre la
## cupola, proprio nel primo secondo — dai almeno cinquanta secondi, miglioriamo la
## luminosità in maniera graduale; niente di estremizzante, altrimenti diventa tutto
## uno scattone». Ha ragione, e la ragione è più generale del caso: un effetto che
## arriva in nove secondi lo si VEDE ARRIVARE, e a quel punto non è più l'occhio che
## si abitua — è il gioco che accende qualcosa. A cinquanta non c'è nessun istante in
## cui succede: ci si accorge solo, dopo un po', di stare vedendo cose che prima non
## c'erano. Che è esattamente com'è la cosa vera.
##
## E non è nemmeno una compressione violenta: l'adattamento completo costa venti
## minuti, ma la parte ripida — quella che si nota — si esaurisce nei primi minuti.
## Cinquanta secondi sono quella.
const SALITA := 50.0

## E quanti per perderlo. Un trentatreesimo della salita: è l'ASIMMETRIA a raccontare
## la cosa, ed è la sola parte di questo effetto che abbia un insegnamento dentro.
## Farsi l'occhio costa, perderlo no — accendere la luce in cupola non è gratis, e lo
## si impara accendendola una volta.
##
## UN SECONDO E MEZZO E NON UN FOTOGRAMMA, però. Anche il crollo, se è istantaneo, è
## «uno scattone», e per giunta sarebbe indistinguibile da un difetto di rendering.
## Un secondo e mezzo si legge come una reazione, non come un interruttore.
const DISCESA := 1.5

## Sotto questa apertura della cupola l'adattamento non parte. Non è una soglia
## fisiologica — l'occhio si adatta anche in una stanza chiusa — è una scelta di
## regia: questo effetto racconta «la cupola è aperta e sto guardando il cielo», e
## regalarlo anche a cupola chiusa vorrebbe dire spendere l'unico momento in cui il
## gioco cambia da solo per non dire niente.
const APERTA := 0.30

## Le `Accesa` delle lampade della sala: se una qualsiasi è visibile, niente
## adattamento. Arrivano per `NodePath` dal generatore, che è l'unico a sapere quali
## lampade stanno in cupola — questo file non deve conoscere la pianta.
@export var luci: Array[NodePath] = []

## Quanto l'occhio è fatto, da 0 a 1.
var _q := 0.0

var _dentro := false
var _apertura := 0.0
var _giocatore: Node3D
var _ambiente: Environment
var _rampa: Gradient
var _lut: GradientTexture1D
var _nodi_luce: Array[Node] = []


func _ready() -> void:
	add_to_group(GROUP)
	# SOLO IL GIOCATORE, e l'area non dev'essere trovata da nessuno: stessa maschera
	# di `IndoorsVolume` e `DomeActivity`. Senza, l'area si sveglierebbe per ogni
	# parete e ogni mobile — sono tutti `StaticBody3D` sul layer del mondo.
	collision_mask = Interactable.LAYER_PLAYER
	collision_layer = 0
	monitoring = true
	Events.dome_aperture_changed.connect(_su_apertura)
	for p in luci:
		var n := get_node_or_null(p)
		if n != null:
			_nodi_luce.append(n)
	_prepara()


## Il LUT e il puntatore all'ambiente. Il `WorldEnvironment` si cerca per TIPO e non
## per nome: un nodo rinominato non deve spegnere un effetto in silenzio.
func _prepara() -> void:
	_rampa = Gradient.new()
	_rampa.set_offset(0, 0.0)
	_rampa.set_offset(1, 1.0)
	_rampa.set_color(0, Color.BLACK)
	_rampa.set_color(1, Color.WHITE)
	_lut = GradientTexture1D.new()
	_lut.gradient = _rampa
	# 64 campioni: la rampa è una retta, e una retta non ha bisogno di più.
	_lut.width = 64
	var we := _cerca_ambiente(get_tree().root)
	if we != null:
		_ambiente = we.environment


func _cerca_ambiente(n: Node) -> WorldEnvironment:
	if n is WorldEnvironment:
		return n
	for f in n.get_children():
		var t := _cerca_ambiente(f)
		if t != null:
			return t
	return null


func _su_apertura(fraction: float) -> void:
	_apertura = fraction


## Se una qualunque lampada della sala è accesa, l'occhio non si fa. È il patto che
## rende l'effetto una conseguenza delle scelte del giocatore invece che un regalo.
func _al_buio() -> bool:
	for n in _nodi_luce:
		if n is Node3D and (n as Node3D).visible:
			return false
	return true


func _process(delta: float) -> void:
	if _ambiente == null:
		return
	# SI CHIEDE INVECE DI ASCOLTARE, come fa `IndoorsVolume`: `body_entered` non
	# scatta per chi è già dentro quando l'area nasce, e un effetto che non parte
	# perché il giocatore stava di là al momento sbagliato è il tipo di guasto che
	# non si riproduce mai su richiesta.
	if _giocatore == null or not is_instance_valid(_giocatore):
		_giocatore = Player.find_in(get_tree())
	_dentro = _giocatore != null and overlaps_body(_giocatore)
	var bersaglio := 1.0 if (_dentro and _apertura >= APERTA and _al_buio()) else 0.0
	if bersaglio > _q:
		_q = minf(bersaglio, _q + delta / SALITA)
	else:
		_q = maxf(bersaglio, _q - delta / DISCESA)
	_applica()


func _applica() -> void:
	if _q <= 0.001:
		_ambiente.adjustment_enabled = false
		return
	_rampa.set_color(0, ALZATA * _q)
	_ambiente.adjustment_color_correction = _lut
	_ambiente.adjustment_enabled = true


## Quanto l'occhio è fatto. Per le sonde: leggere il segnale non prova che il nodo
## l'abbia ricevuto, e leggere lo schermo non dice di chi è la colpa.
func adaptation() -> float:
	return _q
