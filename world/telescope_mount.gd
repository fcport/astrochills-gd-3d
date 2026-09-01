## LA MONTATURA CHE SI MUOVE: due angoli in ingresso, un tubo che gira.
##
## COSA FA, IN UNA RIGA: le si dice dove guardare — angolo orario e declinazione — e
## lei ci porta gli assi, non di scatto ma alla velocità di un motore.
##
## È UNA EQUATORIALE TEDESCA, e il modello lo è davvero: `telescopio_blender.py`
## ricostruisce la gerarchia `Polo → AssePolare → Declinazione → AsseDec → Tubo`
## misurando gli assi sui vertici invece di fidarsi dei nomi, e li trova ortogonali a
## meno di 1e-4. Qui non si costruisce niente: si ruotano due nodi.
##
## ZERO È IL RIPOSO, E IL RIPOSO È IL POLO. Con i due perni a rotazione nulla il tubo
## è parallelo all'asse polare e il contrappeso sta in basso: in cielo vuol dire che
## si sta guardando la stella polare. Da lì la declinazione bascula di `90 - dec` e
## l'ascensione retta gira dell'angolo orario. È il contratto scritto in
## `geometria.py`, ed è quello che rende il puntamento due rotazioni e non un
## problema di convenzioni.
##
## LA POSA MODELLATA VA TOLTA PRIMA. Il `.glb` non nasce a zero: porta addosso la posa
## in cui il telescopio si vede nei render di controllo (-60° e -20°), perché un
## telescopio fotografato nella posizione di riposo sembra rotto. Quindi all'avvio si
## sottrae quella posa e si tiene da parte la base VERA dello zero — se non la si
## togliesse, ogni puntamento sarebbe sbagliato di sessanta gradi e sembrerebbe
## comunque plausibile, che è il modo peggiore di sbagliare.
##
## DOVE GUARDA LO DICE IL MODELLO, non questo file. `Mira` è un `Node3D` vuoto che
## `telescopio_blender.py` appende ad AsseDec sull'asse ottico, all'altezza
## dell'apertura: il suo **Y locale** è la direzione di vista (in Blender era Z, la
## conversione a Y-alto del glTF li scambia) e la sua origine è il punto da cui parte
## il raggio. Indovinare l'asse ottico dalla mesh del tubo è già stato provato: la
## retta di regressione della nuvola di vertici dava 62 gradi dove il tubo ne faceva
## 43, perché in quella nuvola ci sono anche cercatore, anelli e bulloni.
##
## E L'APERTURA SERVE PIÙ DELLA DIREZIONE, per via della cupola: su una equatoriale
## tedesca il tubo sta di fianco al pilastro, quindi il raggio non parte dal centro
## della cupola e l'azimut da dare alla fessura non è quello del telescopio. Vedi
## `world/dome_azimuth.gd`, dove il conto è fatto e i numeri sono grossi.
class_name TelescopeMount
extends Node3D

## Chi ha bisogno della montatura la trova per GRUPPO, mai per percorso: stessa
## regola di `IndoorsVolume`, del monitor e della cupola.
const GROUP := &"telescope_mount"

## Quanto in fretta si muovono gli assi, in gradi al secondo.
##
## DODICI, che è lento e va bene: un GOTO su una montatura di quegli anni è una cosa
## che si sente e si guarda, non un taglio di montaggio. Da un capo all'altro del
## cielo sono una quindicina di secondi — abbastanza per accorgersi che la macchina
## sta lavorando, poco abbastanza da non essere un'attesa.
const VELOCITA := 12.0

## Quanto vicino all'angolo chiesto si considera arrivati, in gradi.
const ARRIVATO := 0.05

## Di quanto la rotazione zero dell'asse polare è lontana dal meridiano, in gradi.
##
## MISURATO, NON DEDOTTO, e il modo in cui lo si è misurato conta quanto il numero.
## Portando gli assi a valori noti e leggendo dove finiva la mira:
##
##     asse ar   dec        altezza   azimut     che vuol dire
##        0       90         +43,1      -1       il POLO (l'altezza vale la latitudine)
##       90        0         +46,6     178       il meridiano a sud: angolo orario ZERO
##        0        0          -0,6      89       l'orizzonte a est: angolo orario -90
##      180        0          +1,3     -90       l'orizzonte a ovest: angolo orario +90
##
## Tre righe indipendenti che danno lo stesso scarto: novanta gradi. Non è un numero
## con un significato fisico — è dove il modello aveva il tubo quando è stato
## montato — ed è esattamente per questo che va misurato invece che ragionato.
##
## E il polo esce a 43,1 dove la latitudine di Montegrimano è 43,9: otto decimi di
## grado di disallineamento polare, che il modellatore crede di aver raddrizzato e
## non ha raddrizzato. È poco per vedersi e troppo per un gioco che ha una fase
## sull'allineamento polare; sta scritto qui perché qualcuno ci torni.
const AR_ZERO := 90.0

## I due perni del modello, e la posa che portano addosso. Li scrive il generatore:
## quali nodi siano e quanto valga la posa lo sa `geometria.py`, non questo file.
@export var asse_ar: NodePath
@export var asse_de: NodePath
@export var mira: NodePath
@export var ar_riposo_gradi := 0.0
@export var dec_riposo_gradi := 0.0

var _ar: Node3D
var _de: Node3D
var _mira: Node3D

## Le basi dei due perni con rotazione ZERO, cioè senza la posa modellata.
var _ar0 := Basis.IDENTITY
var _de0 := Basis.IDENTITY

## Dove si sta guardando adesso, in gradi. Il riposo è il polo.
var _ha := 0.0
var _dec := 90.0

## Dove si vuole arrivare.
var _ha_v := 0.0
var _dec_v := 90.0


func _ready() -> void:
	add_to_group(GROUP)
	_ar = get_node_or_null(asse_ar) as Node3D
	_de = get_node_or_null(asse_de) as Node3D
	_mira = get_node_or_null(mira) as Node3D
	if _ar == null or _de == null or _mira == null:
		push_error("[system] montatura: manca un perno del telescopio")
		set_process(false)
		return
	# Via la posa modellata: quello che resta è la base dello zero.
	_ar0 = _ar.transform.basis * Basis(Vector3.UP, -deg_to_rad(ar_riposo_gradi))
	_de0 = _de.transform.basis * Basis(Vector3.UP, -deg_to_rad(dec_riposo_gradi))
	# Si parte da dove il modello è posato, non dal polo: il giocatore trova lo
	# strumento com'è nella scena, e la prima mossa lo muove da lì.
	_dec = 90.0 - dec_riposo_gradi
	_ha = ar_riposo_gradi - AR_ZERO
	_dec_v = _dec
	_ha_v = _ha
	_scrivi()


## Dove si vuole guardare: angolo orario e declinazione, in gradi. Non ci si arriva
## subito — ci si arriva alla velocità del motore.
func punta(ha_gradi: float, dec_gradi: float) -> void:
	_ha_v = wrapf(ha_gradi, -180.0, 180.0)
	_dec_v = clampf(dec_gradi, -90.0, 90.0)


## Vero mentre gli assi si stanno ancora muovendo.
func in_moto() -> bool:
	return absf(_ha - _ha_v) > ARRIVATO or absf(_dec - _dec_v) > ARRIVATO


## Da dove parte il raggio: il centro dell'apertura, in coordinate del mondo.
func apertura() -> Vector3:
	return _mira.global_position


## Dove guarda: versore, in coordinate del mondo. È l'Y locale della mira.
func direzione() -> Vector3:
	return _mira.global_transform.basis.y.normalized()


## L'angolo orario e la declinazione di adesso, in gradi.
func dove() -> Vector2:
	return Vector2(_ha, _dec)


static func find_in(tree: SceneTree) -> TelescopeMount:
	return tree.get_first_node_in_group(GROUP) as TelescopeMount


func _process(delta: float) -> void:
	if not in_moto():
		return
	var passo := VELOCITA * delta
	_ha = move_toward(_ha, _ha_v, passo)
	_dec = move_toward(_dec, _dec_v, passo)
	_scrivi()


## I due angoli diventano le due rotazioni. È tutto qui il puntamento.
func _scrivi() -> void:
	_ar.transform.basis = _ar0 * Basis(Vector3.UP, deg_to_rad(_ha + AR_ZERO))
	_de.transform.basis = _de0 * Basis(Vector3.UP, deg_to_rad(90.0 - _dec))
