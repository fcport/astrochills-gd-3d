## Un pulsante del quadro della cupola: lo miri, lo tieni premuto, il motore va.
##
## PERCHÉ NON È PIÙ UN QUADRO SOLO CON DUE FRECCE (D-174). La prima stesura era un
## oggetto solo: lo prendevi con `E` e poi comandavi il motore con le frecce della
## tastiera. Non funzionava e non si capiva, e i due difetti erano lo stesso
## difetto — un comando che sta nel mondo si preme dove sta, non da tastiera.
## Adesso i pulsanti sono due oggetti distinti, si mirano uno per uno, e quello che
## premi è quello che si muove.
##
## SI TIENE PREMUTO `E`, e il motore va finché lo tieni. È il gesto dei quadri
## veri — a uomo presente, perché un battente da qualche quintale che si muove da
## solo mentre nessuno guarda è un modo di rompere un telescopio — ed è anche
## l'unico gesto che il giocatore ha già imparato altrove nel gioco.
##
## IL PULSANTE RIENTRA MENTRE LO PREMI, e non è un vezzo: è l'unico modo che ha
## di dire «ti ho sentito» a chi lo sta guardando da mezzo metro. Un comando che
## non si muove quando lo premi sembra rotto anche quando funziona.
##
## PARLA COL BUS E NON CON LA FASE: `world/` non può nominare `phases/`. Quello
## che questo pulsante sa è che un dito lo sta schiacciando, e lo dice a voce alta.
class_name DomeButton
extends Interactable

## Chi ha bisogno dei pulsanti li trova per GRUPPO, mai per percorso di nodo.
const GROUP := &"dome_button"

## Di quanto rientra il cappello quando lo premi, in metri.
const TRAVEL := 0.012

## Oltre questa distanza il dito si stacca da solo. Poco più della portata del
## raggio del giocatore (1,20 m): chi indietreggia di un passo lascia il pulsante.
const REACH := 1.5

## +1 apre, -1 chiude. Lo dichiara la scena, così questo file non sa quale dei due
## pulsanti sia — e i due pulsanti sono lo stesso pulsante montato al contrario.
@export var direction: int = 1

## Che cosa c'è scritto sulla targhetta, e quindi nel prompt.
@export var action_name: String = "Apri la cupola"

@onready var _cap: Node3D = get_node_or_null("Cappello")

var _held := false
var _user: Node3D
var _rest := Vector3.ZERO


func _ready() -> void:
	add_to_group(GROUP)
	prompt_text = action_name
	if _cap != null:
		_rest = _cap.position
	interacted.connect(_on_interacted)


## Tutti i pulsanti della scena. Per il banco e per le sonde.
static func all_in(tree: SceneTree) -> Array[Node]:
	return tree.get_nodes_in_group(GROUP)


## Se questo pulsante è schiacciato adesso.
func is_held() -> bool:
	return _held


func _process(_delta: float) -> void:
	if not _held:
		return
	# SI LASCIA DA SÉ in tre casi: il dito si è alzato, il giocatore se n'è andato,
	# o il giocatore è sparito. Il primo è il gesto; gli altri due sono le
	# scorciatoie che senza questo controllo permetterebbero di comandare la cupola
	# dalla sala di controllo.
	if not Input.is_action_pressed(&"interact"):
		_lascia()
		return
	if _user == null or not is_instance_valid(_user) or _distanza() > REACH:
		_lascia()


func _on_interacted(by: Node3D) -> void:
	if _held:
		return
	_held = true
	_user = by
	if _cap != null:
		# Rientra lungo la propria normale: il cappello guarda in avanti come tutto
		# il pulsante, e «dentro» è meno Z locale.
		_cap.position = _rest + Vector3(0.0, 0.0, -TRAVEL)
	Events.dome_button_changed.emit(signi(direction))


func _lascia() -> void:
	_held = false
	_user = null
	if _cap != null:
		_cap.position = _rest
	Events.dome_button_changed.emit(0)


## Quanto si è lontani, MISURATO SUL PAVIMENTO e non in linea d'aria: il pulsante
## sta a un metro e mezzo, il giocatore ha l'origine ai piedi, e il dislivello fra
## i due non è distanza — è altezza. (Il difetto è già stato pagato una volta.)
func _distanza() -> float:
	var a := global_position
	var b := _user.global_position
	return Vector2(a.x - b.x, a.z - b.z).length()


func _exit_tree() -> void:
	# Un pulsante che sparisce schiacciato lascerebbe il motore acceso per sempre.
	if _held:
		_held = false
		Events.dome_button_changed.emit(0)
