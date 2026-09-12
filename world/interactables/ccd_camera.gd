## LA CAMERA CCD: la si prende in mano, la si porta al telescopio, la si avvita.
##
## PERCHÉ È UN `Carryable` E NON UN `Interactable`. Perché è l'unico oggetto del
## gioco che è tutte e due le cose a seconda di dove sta: avvitata al
## focheggiatore è un pezzo dello strumento e non si muove; staccata è una scatola
## da un chilo e mezzo che cade se la molli. Ereditare dal trasportabile e
## aggiungere il caso «montata» tiene la fisica dove serve e la toglie dove non
## serve — il contrario avrebbe voluto due nodi che si scambiano il posto.
##
## MONTATA NON SIMULA, ED È GIUSTO COSÌ. Una camera avvitata al fuoco è
## SOLIDALE al tubo: deve seguirlo mentre insegue il cielo, e un corpo rigido che
## insegue un bersaglio in movimento a mezzo metro d'altezza oscillerebbe,
## sbatterebbe contro gli anelli e finirebbe per cadere. Avvitata è avvitata:
## `freeze` e si appende al nodo del fuoco. È l'unica riparentatura del progetto,
## e ha una ragione fisica — la vite — invece che di comodo.
##
## DOVE VA, LO DICE IL MODELLO. Il punto di attacco non è una quota scritta qui:
## è il nodo `Fuoco` che `telescopio_blender.py` DEDUCE dal focheggiatore del
## modello — la bocca del portaoculare, e il verso in cui esce dal tubo. Se un
## domani il telescopio cambia, la camera si monta dove sta il nuovo
## focheggiatore senza che nessuno tocchi questo file.
class_name CcdCamera
extends Carryable

## Chi ha bisogno della camera la trova per GRUPPO. Stessa regola del fungo e
## dell'anta (D-196), e qui a maggior ragione: nella scena questo nodo si chiama
## `Ccd` e dentro il modello ci sono le sue mesh.
##
## NON SI CHIAMA `GROUP` come tutti gli altri, e non e' una svista: `Carryable`
## ha gia' una costante con quel nome, e in GDScript una sottoclasse non puo'
## ridichiararla. Sono due gruppi diversi e giusti tutti e due - la camera E' un
## trasportabile ED E' la camera - quindi ci sta in tutti e due.
const GRUPPO := &"ccd_camera"

## Da quanto vicino si riesce ad avvitarla, in metri. Mezzo metro: è la distanza a
## cui un braccio arriva al focheggiatore, e sopra il metro si monterebbe la
## camera stando dall'altra parte della passerella.
const PORTATA_ATTACCO := 0.55

## Di quanto si arretra la camera perché il naso entri nel focheggiatore, in
## metri: 7,5 cm di testa più 2,2 di ruota filtri. Il naso, tre centimetri, sta
## tutto DENTRO il portaoculare.
##
## NON È L'ALTEZZA DELL'OGGETTO, e prima lo era. Il modello è alto 12,7 cm — il
## naso della CFW-8 sporge di tre centimetri, come nel vero — ma arretrarla di
## tutti e 12,7 le lascerebbe il naso appoggiato sulla bocca del focheggiatore,
## e un naso appoggiato non è un naso montato.
##
## ED È SCESA DI UN CENTIMETRO E MEZZO, da 0,111 a 0,097, guardandola in partita:
## Federico, davanti al telescopio, «forse va abbassata leggermente la camera».
## Con 0,111 dentro il portaoculare ci stava metà naso e l'altra metà restava a
## vista, cioè un dito di vuoto fra il collare del focheggiatore e la ruota
## filtri — la camera sembrava appesa davanti al tubo invece che avvitata. Adesso
## il naso entra fino alla battuta della ruota filtri, che è dove si ferma
## infilando un 31,75 vero.
## Le quote stanno in `tools/ccd_blender.py`, che a sua volta le prende da SBIG.
const ALTA := 0.097

## Come sta la camera rispetto al nodo `Fuoco`: arretrata di `ALTA` lungo il suo
## +Y, e girata di mezzo giro perché il naso guardi dentro il focheggiatore.
##
## IL +Y, E NON IL -Z. Questa riga è stata sbagliata per due settimane e nessun
## controllo se n'è accorto: `-Z` è la convenzione di Godot per «dove guarda un
## nodo», ma il nodo `Fuoco` non lo scrive Godot — lo esporta Blender, dove
## `perno()` allinea al verso del focheggiatore il proprio **+Z**, che passando
## per il glTF diventa il **+Y** di qui. Montata sul -Z la camera finiva di
## traverso, appiccicata al fianco del tubo: in partita si vedeva, e
## `prova_ccd.gd` diceva ok perché misurava solo la DISTANZA dalla bocca — che
## di traverso è identica. Adesso quella prova misura anche da che parte.
const POSA := Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0.0, ALTA, 0.0))

## LE MISURE DELLA RETE — quanto ferma, quanto lontano si cerca, quanti piani si
## scendono — non stanno più qui: stanno in `Carryable`, perché la promessa che
## una cosa caduta si ritrova vale per tutto quello che si prende in mano e non
## per la sola camera. Qui resta la sola cosa che di questa camera è speciale:
## dove va a finire quando un posto buono non c'è (vedi `_perduta()`).

## IL MONTAGGIO SI ANNUNCIA SUL BUS, e qui c'era invece un `montaggio_cambiato`
## dichiarato su questo nodo.
##
## Non l'ha mai potuto ascoltare nessuno, e non era una dimenticanza: era
## impossibile. L'unico interessato è il software di ripresa — la posa, che deve
## morire se la camera se ne va — e vive in `phases/`, che non conosce `world/` e
## non ha modo di arrivare a questo nodo. Un signal diretto vuole un ascoltatore
## capace di trovare l'emettitore; questo fatto non ne ha nessuno.
##
## Adesso esce da `Events.camera_mounted_changed`, dove chiunque lo sente senza
## sapere chi sia questo nodo.

## Il nodo `Fuoco` del telescopio: la bocca del focheggiatore, con il proprio -Z
## rivolto fuori dal tubo. Lo scrive il generatore della scena.
@export var fuoco: NodePath

## Se all'avvio la camera è già avvitata al telescopio.
##
## VERA, ED È COME STA IN UN OSSERVATORIO: la camera si monta una volta e ci
## resta; nessuno la smonta a fine notte per rimontarla la sera dopo. Nasce
## quindi al suo posto, e chi vuole prenderla in mano la va a smontare — che è il
## gesto vero, e anche l'unico modo di scoprire che si può fare.
##
## E RISOLVE UN PROBLEMA PRATICO: nascendo posata da qualche parte servirebbe un
## piano che la regga, in una cupola dove il pavimento è il modello dell'edificio.
## Nascendo montata sta dove il modello dice, e non c'è nessuna quota da azzeccare.
@export var montata_all_avvio := true

## IL MODO SBAGLIATO, tenuto a portata di mano perche' lo si possa misurare.
##
## A `true` la camera viene posata sul fuoco e lasciata li' invece di essere
## appesa: e' quello che verrebbe naturale scrivere, e per un fotogramma e'
## indistinguibile dal giusto. Poi il telescopio comincia a inseguire il cielo e
## la camera resta dov'era - a mezz'aria, davanti a un tubo che se n'e' andato.
##
## Esiste solo perche' la sonda possa rimettere il difetto: senza il confronto,
## «la camera sta al fuoco» non distingue l'avvitata dall'appoggiata. Vedi
## `tools/prova_ccd.gd`, che lo accende con `CAMERA_APPOGGIATA=1`.
@export var appoggiata_e_basta := false

var _fuoco: Node3D
var _montata := false
## Dove stava prima di essere appesa al fuoco. Serve a rimetterla nell'albero da
## cui viene invece che lasciarla figlia del telescopio per sempre.
var _casa: Node


static func find_in(tree: SceneTree) -> CcdCamera:
	return tree.get_first_node_in_group(GRUPPO) as CcdCamera


func _ready() -> void:
	super()
	add_to_group(GRUPPO)
	_casa = get_parent()
	_fuoco = get_node_or_null(fuoco) as Node3D
	if _fuoco == null:
		push_error("[ccd] il fuoco del telescopio non si trova")
		return
	if montata_all_avvio:
		# DIFFERITO: `reparent` dentro `_ready()` sposta un nodo mentre l'albero
		# lo sta ancora montando, e Godot lo rifiuta.
		_monta.call_deferred()


## AVVITATA AL FUOCO È FERMA, e la rete non deve nemmeno guardarla: è appesa a un
## tubo che si muove, non è caduta da nessuna parte. Il resto — quanto ferma,
## quando guardare — lo fa `Carryable`.
func _fuori_dalla_rete() -> bool:
	return _montata or super()


func montata() -> bool:
	return _montata


## Il prompt guardandola. Montata dice come si toglie, staccata come si prende.
func prompt() -> String:
	if _montata:
		return "Smonta la camera dal telescopio"
	return super()


## Il prompt tenendola in mano: cambia SE SI È ARRIVATI AL TELESCOPIO, e quel
## cambio è tutto l'insegnamento che serve. Nessun tutorial dice che la camera va
## avvitata: lo dice la riga che cambia da sola quando ci si avvicina.
func prompt_posa() -> String:
	if _si_arriva_al_fuoco():
		return "Avvita la camera al fuoco"
	return super()


## Cosa succede premendo il tasto con la camera in mano: al focheggiatore si
## avvita, altrove si posa come qualunque altra cosa.
##
## E SI POSA SEMPRE, ANCHE SUL POZZO. Per una settimana qui c'è stato un DIVIETO —
## sul vuoto la mano non la lasciava andare, e il prompt lo diceva — messo per non
## perdere la camera nel pozzo del pilastro. Federico l'ha bocciato giocandoci:
## «adesso sono bloccato con la camera in mano... ma che discorso è fare un prompt
## che dice qui sotto non c'è dove posare la camera, uno impazzisce». Aveva ragione:
## un divieto che non dice dove SI può è una punizione, e questo per giunta lasciava
## in mano l'oggetto che si stava cercando di mettere giù.
##
## IL BUCO ADESSO È TAPPATO, e non è più affare di questo file: sotto la passerella
## c'è un fondo invisibile sul layer degli appoggi (vedi `tools/gen_blockout.py`,
## nodo `FondoPasserella`) che ferma a filo del calpestio tutto quello che ci cade
## dentro — la camera, il termos, una tazza. Il posto dove non si poteva più
## raccogliere niente non esiste più, quindi non c'è più niente da vietare.
func posa() -> void:
	if _si_arriva_al_fuoco():
		_monta()
		return
	super()


## Raccoglierla la smonta, senza doverlo dire: chi la prende in mano da montata
## la sta togliendo.
func prendi(chi: PhysicsBody3D) -> void:
	if _montata:
		_smonta()
	super(chi)


## L'ULTIMA SPIAGGIA, e sta sotto al fondo invisibile per la stessa ragione per
## cui una rete sta sotto un trapezio: il fondo chiude il buco che CONOSCIAMO. La
## camera può ancora essere strappata dalla mano contro uno stipite (vedi
## `Carryable.STRAPPO`) e finire chissà dove.
##
## `Carryable` la ripesca da solo finché entro un metro c'è un posto da cui
## prenderla, e nella casa vera ce n'è sempre uno: la fessura più profonda si
## risolve spostandola di un palmo. Questa funzione è per il caso che resta —
## nessun posto buono da nessuna parte — e la camera, che è l'unico oggetto senza
## il quale la partita non può più finire, torna al fuoco. Non è un teletrasporto
## di comodo: è la sola cosa che distingue «l'ho persa» da «la partita è rotta».
func _perduta() -> void:
	if _fuoco == null:
		return
	Log.info("ccd", "la camera era finita dove non ci si arriva (%.2f, %.2f, %.2f) e "
		% [global_position.x, global_position.y, global_position.z]
		+ "non c'era un posto migliore: rimessa al fuoco")
	_monta()


func _si_arriva_al_fuoco() -> bool:
	if _fuoco == null or _montata:
		return false
	return global_position.distance_to(_fuoco.global_position) <= PORTATA_ATTACCO


func _monta() -> void:
	if _fuoco == null or _montata:
		return
	lascia()
	_montata = true
	# CONGELATA E SENZA COLLISIONE COL MONDO. Il tubo si muove e la porta con sé:
	# un corpo rigido attivo appeso lì dentro passerebbe la notte a sbattere
	# contro gli anelli del telescopio, e la fisica che serviva a NON attraversare
	# i muri diventerebbe il motivo per cui la camera si stacca da sola.
	freeze = true
	if appoggiata_e_basta:
		global_transform = _fuoco.global_transform * POSA
		Events.camera_mounted_changed.emit(true)
		return
	reparent(_fuoco, false)
	transform = POSA
	Events.camera_mounted_changed.emit(true)


func _smonta() -> void:
	if not _montata:
		return
	_montata = false
	var dove := global_transform
	reparent(_casa, false)
	global_transform = dove
	freeze = false
	Events.camera_mounted_changed.emit(false)

