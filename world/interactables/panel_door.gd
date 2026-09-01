## L'ANTA DI UN QUADRO: si apre, si chiude, e ci mette il suo tempo.
##
## PERCHÉ NON RIUSA `Door`. Quella è la porta di una stanza: sa di stipiti, di
## versi di apertura dichiarati in `geometria.py`, di quale locale illumina la
## placca accanto. Un'anta di lamiera da quaranta centimetri non ha niente di
## tutto questo — ha un cardine e due posizioni — e farle attraversare quel
## contratto vorrebbe dire dichiararle un locale, un verso e una maniglia che non
## ha. Sono due oggetti che si somigliano e non sono la stessa cosa.
##
## SI APRE PIANO, e novanta gradi non bastano: un'anta a filo di novanta copre
## ancora mezzo quadro se la si guarda di sbieco, e chi apre un quadro lo apre per
## vederci dentro. Centodieci gradi la portano fuori dal campo.
##
## E DIETRO NON C'È NIENTE DA FARE, ancora. Il quadro si apre e mostra il proprio
## cablaggio: interruttori, morsetti, cavi. Non c'è nessun gesto lì dentro — quello
## che c'è di premibile sta FUORI, il fungo rosso, com'è giusto per un comando che
## si deve poter dare senza aprire niente. Aprire serve a guardare, e un giorno a
## qualcosa che oggi non c'è.
class_name PanelDoor
extends Interactable

## Per GRUPPO, mai per nome, e la ragione e' la stessa del fungo: nella scena
## questo nodo si chiama `Anta` e cosi' si chiama anche la lamiera dentro il
## modello. Cercare «la prima Anta dell'albero» trova la mesh, il cast fallisce, e
## il referto dice che l'anta non esiste mentre e' li' e funziona.
const GROUP := &"panel_door"

## Quanto si apre, in gradi.
const APERTURA := 110.0

## Gradi al secondo. Lenta: è lamiera con due cerniere, non una porta a molla.
const VELOCITA := 220.0

## Il nodo che ruota — quello con l'origine sul cardine, scritto dal modellatore.
@export var anta: NodePath

## Il verso in cui gira: +1 o -1. Dipende da quale spigolo il modello ha come
## cardine, e lo scrive il generatore invece di lasciarlo indovinare qui.
@export var verso: int = 1

var _anta: Node3D
var _riposo := 0.0
var _voluto := 0.0
var _ora := 0.0


static func find_in(tree: SceneTree) -> PanelDoor:
	return tree.get_first_node_in_group(GROUP) as PanelDoor


func _ready() -> void:
	add_to_group(GROUP)
	_anta = get_node_or_null(anta) as Node3D
	if _anta == null:
		push_error("[quadro] l'anta non si trova")
		return
	_riposo = _anta.rotation.y
	interacted.connect(_su_pressione)
	set_process(false)


func prompt() -> String:
	return "Chiudi il quadro" if aperta() else "Apri il quadro"


## Vera quando l'anta è oltre metà corsa. Per il prompt e per le sonde.
func aperta() -> bool:
	return absf(_voluto) > APERTURA * 0.5


func _su_pressione(_by: Node3D) -> void:
	_voluto = 0.0 if aperta() else APERTURA * signf(float(verso))
	set_process(true)


func _process(delta: float) -> void:
	if _anta == null:
		set_process(false)
		return
	_ora = move_toward(_ora, _voluto, VELOCITA * delta)
	_anta.rotation.y = _riposo + deg_to_rad(_ora)
	# ANCHE IL PROPRIO CORPO, che ha l'origine sullo stesso cardine: la lamiera che
	# si vede e il bersaglio che si mira devono essere nello stesso posto, o si
	# preme un quadro che non c'e' piu'.
	rotation.y = deg_to_rad(_ora)
	if is_equal_approx(_ora, _voluto):
		set_process(false)
