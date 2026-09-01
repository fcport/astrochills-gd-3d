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
##
## QUATTRO MILLIMETRI E NON DODICI, ed e' la corsa vera di un pulsante industriale:
## a dodici il cappuccio della pulsantiera - che ne sporge dieci - rientrava DIETRO
## la propria targhetta e spariva. Nello scatto il tasto premuto non c'era, e il
## sintomo sembrava un problema di colore.
const TRAVEL := 0.004

## Oltre questa distanza il dito si stacca da solo. Poco più della portata del
## raggio del giocatore (1,20 m): chi indietreggia di un passo lascia il pulsante.
const REACH := 1.5

## +1 apre, -1 chiude. Lo dichiara la scena, così questo file non sa quale dei due
## pulsanti sia — e i due pulsanti sono lo stesso pulsante montato al contrario.
@export var direction: int = 1

## Che cosa c'è scritto sulla targhetta, e quindi nel prompt.
@export var action_name: String = "Apri la cupola"

## I PEZZI CHE RIENTRANO QUANDO SI PREME, e sono PIU' DI UNO: il cappuccio e la
## freccia serigrafata sopra. Nascono da due materiali diversi, e l'esportatore
## glTF fa una mesh per materiale - non c'e' modo di darli come un pezzo solo senza
## dipingere la freccia sul cappuccio, che a questa scala sarebbe tre pixel. Con un
## nodo solo la freccia restava sospesa a mezz'aria mentre il tasto scendeva.
##
## Vuoto, si ricade su un figlio chiamato `Cappello`: e' com'era prima, e vale per
## i pulsanti costruiti da primitive invece che importati.
@export var cap_paths: Array[NodePath] = []

var _held := false
var _user: Node3D
var _caps: Array[Node3D] = []
var _rest: Array[Vector3] = []


func _ready() -> void:
	add_to_group(GROUP)
	prompt_text = action_name
	for p in cap_paths:
		var n := get_node_or_null(p)
		if n is Node3D:
			_caps.append(n)
	if _caps.is_empty():
		var solo := get_node_or_null("Cappello")
		if solo is Node3D:
			_caps.append(solo)
	for c in _caps:
		_rest.append(c.position)
	interacted.connect(_on_interacted)


## Tutti i pulsanti della scena. Per il banco e per le sonde.
static func all_in(tree: SceneTree) -> Array[Node]:
	return tree.get_nodes_in_group(GROUP)


## Se questo pulsante è schiacciato adesso.
func is_held() -> bool:
	return _held


## MENTRE LO TIENI, IL PULSANTE NON È PIÙ UN INTERAGIBILE — e quindi il prompt
## sparisce, insieme al mirino.
##
## Non è un dettaglio di stile: «[E] Apri la cupola» che resta scritto mentre stai
## già aprendo è una riga che chiede di fare quello che stai facendo. Il giocatore
## la legge come «non ha funzionato, ripremi», e la cupola nel frattempo si apre
## davvero — cioè l'interfaccia contraddice il mondo. Sparendo, la riga dice
## l'unica cosa vera: adesso tocca a te tenere e guardare.
##
## Mollato il tasto, `_lascia()` rimette tutto e la riga ricompare da sé, perché il
## giocatore rifà il raggio ogni tick e la riga è funzione di quello che trova.
##
## Stringe la condizione e non la allenta, che è quello che `Interactable` chiede
## alle sottoclassi. `interact()` la consulta, ma quando questo diventa vero
## l'interazione è già avvenuta.
func can_interact() -> bool:
	return super() and not _held


func _process(_delta: float) -> void:
	if not _held:
		return
	# SI LASCIA DA SÉ in tre casi: il dito si è alzato, il giocatore se n'è andato,
	# o il giocatore è sparito. Il primo è il gesto; gli altri due sono le
	# scorciatoie che senza questo controllo permetterebbero di comandare la cupola
	# dalla sala di controllo.
	if not _tenuto():
		_lascia()
		return
	if _user == null or not is_instance_valid(_user) or _distanza() > REACH:
		_lascia()


## SI TIENE CON `E` OPPURE COL CLICK SINISTRO, e il secondo non è un doppione.
##
## `E` è il tasto con cui si preme; il click sinistro è quello che si tiene mentre
## si guarda altrove — e guardare altrove, qui, vuol dire guardare la cupola che si
## apre sopra la propria testa. Con il solo `E` bisognerebbe tenere il mignolo su
## un tasto mentre si gira il mouse, che è la posizione della mano che nessuno
## tiene per sei secondi.
func _tenuto() -> bool:
	return Input.is_action_pressed(&"interact") or Input.is_action_pressed(&"dome_hold")


func _on_interacted(by: Node3D) -> void:
	if _held:
		return
	_held = true
	_user = by
	# IL CORPO SI FERMA, LA TESTA NO: si tiene premuto e ci si guarda intorno. È il
	# motivo per cui questo comando sta in cupola e non sul PC — mentre la fessura
	# si apre, la si guarda.
	if by.has_method("set_movement_locked"):
		by.set_movement_locked(true)
	# Rientra lungo la propria normale: il cappello guarda in avanti come tutto
	# il pulsante, e «dentro» è meno Z locale.
	_muovi(-TRAVEL)
	Events.dome_button_changed.emit(signi(direction))


func _lascia() -> void:
	_held = false
	if _user != null and is_instance_valid(_user) and _user.has_method("set_movement_locked"):
		_user.set_movement_locked(false)
	_user = null
	_muovi(0.0)
	Events.dome_button_changed.emit(0)


func _muovi(dentro: float) -> void:
	for i in _caps.size():
		_caps[i].position = _rest[i] + Vector3(0.0, 0.0, dentro)


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
		_lascia()
