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

## Quanto è alta la camera dal piano di appoggio all'imboccatura del naso, in
## metri: 7,5 cm di testa, più la ruota filtri e il suo naso. È il numero con cui
## la si infila nel focheggiatore, e viene da `tools/ccd_blender.py` — dove a sua
## volta viene dalle quote SBIG.
const ALTA := 0.111

## Emesso quando la camera viene montata o smontata. È un FATTO del mondo, non un
## comando: chi vuole saperlo — un domani la fase che pretende la camera al suo
## posto — lo ascolta.
signal montaggio_cambiato(montata: bool)

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
		global_transform = _fuoco.global_transform * Transform3D(
			Basis(Vector3.RIGHT, deg_to_rad(-90.0)), Vector3(0.0, 0.0, ALTA))
		montaggio_cambiato.emit(true)
		return
	reparent(_fuoco, false)
	# IL NASO DENTRO IL FOCHEGGIATORE. Il modello ha l'asse ottico sul proprio +Y
	# con l'origine sotto; il nodo `Fuoco` guarda fuori dal tubo lungo il proprio
	# -Z, che è la convenzione di Godot per «dove guarda un nodo». La camera va
	# quindi girata di novanta gradi e infilata all'indietro della propria altezza,
	# così il naso entra nella bocca invece di restare a mezz'aria davanti.
	transform = Transform3D(
		Basis(Vector3.RIGHT, deg_to_rad(-90.0)),
		Vector3(0.0, 0.0, ALTA))
	montaggio_cambiato.emit(true)


func _smonta() -> void:
	if not _montata:
		return
	_montata = false
	var dove := global_transform
	reparent(_casa, false)
	global_transform = dove
	freeze = false
	montaggio_cambiato.emit(false)

