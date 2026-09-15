## IL FUNGO ROSSO DEL QUADRO: dà corrente a tutto, o la toglie a tutto.
##
## PERCHÉ È UN FUNGO E NON UNA LEVA. Il cappello largo si preme col palmo, al buio
## e con i guanti — è la forma di un arresto d'emergenza, ed è esattamente il gesto
## che serve qui: si esce di notte, si arma il quadro, si rientra. Una leva da
## interruttore vorrebbe due dita e la vista.
##
## SONO DUE, E FANNO LA STESSA COSA (D-256): il fungo sull'anta, che si preme a
## quadro chiuso, e il pulsante rosso che il modello ha già dentro la cassa, che si
## preme a quadro aperto — l'anta aperta gira il primo dall'altra parte.
##
## SI PREME E BASTA, e non si tiene premuto. È la differenza con i pulsanti della
## cupola, ed è la differenza fra i due meccanismi veri: il portello si comanda a
## uomo presente perché è un battente da quintali che si muove, la corrente è uno
## scatto — o c'è o non c'è, e nessuno tiene il dito su un sezionatore.
##
## IL CAPPELLO RIENTRA E TORNA, e non è un vezzo: è l'unico modo che il pulsante ha
## di dire «ti ho sentito» a chi lo sta guardando da mezzo metro. Vale qui come
## valeva per il quadro della cupola — un comando che non si muove quando lo premi
## sembra rotto anche quando funziona.
class_name MainsButton
extends Interactable

## Chi ha bisogno del pulsante lo trova per GRUPPO, mai per nome: nella scena si
## chiama `Fungo` e cosi' si chiama anche la mesh rossa dentro il modello, che e'
## un altro nodo. Una sonda che cercava «il primo Fungo dell'albero» trovava la
## mesh, il cast falliva, e il referto diceva «il pulsante non si trova» con il
## pulsante montato e funzionante.
const GROUP := &"mains_button"

## Di quanto rientra il cappello, in metri. Quattro millimetri, la corsa di un
## pulsante industriale: come quelli della cupola, e per la stessa ragione — a
## dodici il cappuccio spariva dietro la propria ghiera.
const CORSA := 0.004

## Quanto resta premuto prima di tornare su, in secondi.
const SCATTO := 0.14

## Il quadro a cui questo pulsante appartiene. Lo scrive il generatore: cercarlo
## per gruppo funzionerebbe finché non ci saranno due quadri.
@export var rete: NodePath

## Il pezzo che rientra. Vuoto, si cerca un figlio chiamato `Fungo`.
@export var cappello: NodePath

var _rete: Mains
var _cappello: Node3D
var _riposo := Vector3.ZERO
var _premuto := 0.0


## Il primo del gruppo, cioè uno dei due: chi deve distinguerli guarda chi li porta — il
## fungo sta sull'anta (vedi `prova_rete.gd`).
static func find_in(tree: SceneTree) -> MainsButton:
	return tree.get_first_node_in_group(GROUP) as MainsButton


func _ready() -> void:
	add_to_group(GROUP)
	_rete = get_node_or_null(rete) as Mains
	_cappello = get_node_or_null(cappello) as Node3D
	if _cappello != null:
		_riposo = _cappello.position
	interacted.connect(_su_pressione)
	set_process(false)


## Il prompt dice cosa succederà, non cosa si sta guardando — stessa regola della
## placca della luce.
func prompt() -> String:
	if _rete == null:
		return prompt_text
	return "Stacca la corrente" if _rete.acceso() else "Dai corrente"


func _su_pressione(_by: Node3D) -> void:
	if _rete == null:
		push_error("[rete] il pulsante non trova il quadro")
		return
	_rete.commuta()
	if _cappello != null:
		# Rientra lungo la propria normale, che è il +Z locale del quadro: il
		# pulsante sta sull'anta e si muove con lei, quindi il verso va preso in
		# coordinate LOCALI o a quadro aperto il tasto rientrerebbe di traverso.
		_cappello.position = _riposo - Vector3(0.0, 0.0, CORSA)
		_premuto = SCATTO
		set_process(true)


func _process(delta: float) -> void:
	_premuto -= delta
	if _premuto > 0.0:
		return
	if _cappello != null:
		_cappello.position = _riposo
	set_process(false)
