## L'OCCHIO CHE SI FA IL BUIO: in cupola, a luci spente e cupola aperta, si comincia
## a vedere di più — non a vedere più chiaro.
##
## L'IDEA È DI FEDERICO, e anche la correzione che l'ha rimessa in riga. È arrivata
## così: «con la cupola aperta e le luci spente, per lo stesso principio per cui si
## attiva l'abituamento degli occhi, alziamo leggermente il punto di nero». E dopo
## averla provata: «a me sembra di vedere uguale, solo leggermente più chiaro, i neri
## sono leggermente meno neri. In realtà vorrei vedere leggermente di più. Piuttosto
## fai tornare i neri come erano prima, però che veda un po' più di forme, di cose».
##
## E LA SECONDA VERSIONE È GIUSTA, IN UN MODO CHE VALE OLTRE QUESTO CASO. Alzare il
## punto di nero e alzare la sensibilità sembrano la stessa cosa e sono opposte:
##
##   - IL PUNTO DI NERO alza il fondo e lascia tutto il resto dov'è. Quello che era
##     nero diventa grigio, e quello che era appena visibile resta appena visibile.
##     Si vede più CHIARO e non si vede più NIENTE: il contrasto locale, che è quello
##     che fa emergere una forma, non si muove di un livello. È esattamente quello
##     che Federico ha visto.
##   - L'ESPOSIZIONE moltiplica. Il nero (che è zero) resta nero, e tutto quello che
##     stava fra l'invisibile e il visibile sale sopra la soglia: il corrimano, il
##     bordo della passerella, la curva del tubo. Si vedono più COSE, e i neri
##     restano neri — che è la richiesta, parola per parola.
##
## Ed è anche quello che fa la retina: al buio non aggiunge un fondo, cambia il
## GUADAGNO. Non arriva più luce — cambia la risposta a quella che c'è.
##
## PERCHÉ È UN AGGIUSTAMENTO DI CAMERA E NON UNA LAMPADA. L'adattamento non è una
## cosa della stanza: è una cosa dell'occhio. Metterlo come luce vorrebbe dire una
## sorgente che illumina secondo la normale e la distanza — cioè con un centro e un
## fuori — e che per non entrare nelle stanze accanto avrebbe bisogno di ombre, cioè
## sarebbe la seconda copia dell'attrezzo che `sky_light.gd` ha già messo lì per il
## cielo. L'esposizione non ha una posizione, e va bene così: nemmeno l'occhio ce
## l'ha.
##
## SALE PIANO E SCENDE DI COLPO. Farsi l'occhio costa, perderlo no, e l'asimmetria è
## la sola parte di questo effetto che abbia un insegnamento dentro: accendere la
## luce in cupola non è gratis.
class_name DarkAdaptation
extends Area3D

## Chi ha bisogno di questo volume lo trova per GRUPPO, mai per percorso di nodo:
## stessa regola di `IndoorsVolume` e di `DomeActivity`.
const GROUP := &"dark_adaptation"

## Di quanto si moltiplica l'esposizione ad adattamento pieno. 2,4 è poco più di un
## diaframma e un quarto.
##
## SEMBRA TANTO E NON LO È, perché la curva ACES comprime gli alti: quello che era
## già chiaro sale pochissimo (si avvicina al bianco e la curva lo trattiene), mentre
## quello che stava sul fondo — dove la curva è ancora dritta — sale di tutto il
## fattore. È il moltiplicatore giusto per un effetto che deve far emergere il debole
## senza bruciare il forte, e non è un caso: è per quel comportamento che ACES sta
## sulla scena fin dall'inizio.
##
## IL NERO RESTA NERO, e questa è la differenza con la versione di prima: zero per
## qualunque numero fa zero. Il fondo della cupola non si schiarisce, si popola.
const GUADAGNO := 2.4

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
var _riposo := 1.0
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


## Il puntatore all'ambiente e l'esposizione di partenza. Il `WorldEnvironment` si
## cerca per TIPO e non per nome: un nodo rinominato non deve spegnere un effetto in
## silenzio.
##
## L'ESPOSIZIONE DI RIPOSO SI LEGGE, NON SI SCRIVE. Sta in `gen_blockout.py` insieme
## al tonemapping, ed è lì che va decisa; questo nodo la moltiplica e basta. Un
## secondo numero scritto qui sarebbe una seconda verità sulla stessa cosa, e il
## giorno che l'ambiente cambia esposizione la cupola resterebbe all'antica.
func _prepara() -> void:
	var we := _cerca_ambiente(get_tree().root)
	if we != null:
		_ambiente = we.environment
		_riposo = _ambiente.tonemap_exposure


## SI RIMETTE A POSTO USCENDO, e non è pedanteria da manuale: `Environment` è una
## RISORSA, e le risorse in Godot possono sopravvivere alla scena che le ha caricate.
## Sparendo con l'esposizione moltiplicata, la notte dopo questo stesso nodo
## leggerebbe 2,4 come valore di riposo e ci moltiplicherebbe sopra un altro 2,4 —
## un difetto che si vede solo alla seconda notte, cioè mai mentre lo si sviluppa.
func _exit_tree() -> void:
	if _ambiente != null:
		_ambiente.tonemap_exposure = _riposo


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


## Il guadagno cresce con l'adattamento. Interpolazione lineare e non geometrica: a
## metà strada si vuole metà dell'effetto percepito, e con ACES di mezzo la
## differenza fra le due è sotto la soglia in cui varrebbe la pena discuterne.
func _applica() -> void:
	_ambiente.tonemap_exposure = _riposo * lerpf(1.0, GUADAGNO, _q)


## Quanto l'occhio è fatto. Per le sonde: leggere il segnale non prova che il nodo
## l'abbia ricevuto, e leggere lo schermo non dice di chi è la colpa.
func adaptation() -> float:
	return _q
