## Il quadro della cupola: due pulsanti a muro, APRE e CHIUDE.
##
## PERCHÉ NON STA PIÙ SUL PC (D-171). Nel 1999 comandare una cupola dal computer
## della sala controllo si poteva fare — si chiamava Digital Dome Works — ma era
## roba da osservatorio ricco. A Monte San Lorenzo il portello si apre da un
## quadro a muro, in cupola, sotto il portello che si muove: e quello è anche il
## posto giusto per aprirlo, perché chi apre una cupola vuole VEDERLA aprirsi.
##
## DUE PULSANTI A UOMO PRESENTE, come sul quadro vero: il motore va solo finché
## tieni il dito. Non è un vezzo: un battente da qualche quintale che si muove da
## solo mentre nessuno guarda è un modo di rompere un telescopio.
##
## SI PRENDE E SI LASCIA, con `E`. Finché il quadro è «in mano», le frecce
## comandano il motore; appena lo lasci — o ti allontani — il comando si stacca da
## sé. Senza questo stato, le frecce comanderebbero la cupola da qualunque punto
## dell'osservatorio, cucina compresa.
##
## PARLA COL BUS E NON CON LA FASE. `world/` non può nominare `phases/`, ed è la
## regola giusta anche a prescindere: quello che questo quadro sa è che qualcuno
## sta tenendo premuto un pulsante, e lo dice a voce alta. Chi in giro per la
## notte se ne fa qualcosa, ascolta.
class_name DomePanel
extends Interactable

## Chi ha bisogno del quadro lo trova per GRUPPO, mai per percorso di nodo.
const GROUP := &"dome_panel"

## Oltre questa distanza il quadro si lascia da solo.
##
## SERVE, e non è una comodità: senza, si prende il quadro, si scende in sala
## controllo e si comanda la cupola da seduti — che è esattamente l'automazione
## che questo file esiste per NON avere.
const REACH := 2.0

var _active := false
var _direction := 0
var _user: Node3D


func _ready() -> void:
	add_to_group(GROUP)
	_aggiorna_prompt()
	interacted.connect(_on_interacted)


## Il quadro della scena, o `null`. Per il banco e per le sonde.
static func find_in(tree: SceneTree) -> DomePanel:
	return tree.get_first_node_in_group(GROUP) as DomePanel


## Se qualcuno ha il quadro in mano.
func is_active() -> bool:
	return _active


## Che cosa si sta tenendo premuto adesso: +1 apre, -1 chiude, 0 niente.
func direction() -> int:
	return _direction


func _process(_delta: float) -> void:
	if not _active:
		return
	# CHI SI ALLONTANA LASCIA IL QUADRO. Si controlla prima dei tasti: un comando
	# dato da otto metri non deve partire nemmeno per un fotogramma.
	if _user == null or not is_instance_valid(_user) \
			or _distanza() > REACH:
		_lascia()
		return
	# `get_axis` E NON DUE `if`: tenendo premuti tutti e due i pulsanti si ottiene
	# esattamente 0, che è l'interblocco dei quadri veri — il motore non decide da
	# solo chi dei due ha ragione, sta fermo.
	_comanda(signi(roundi(Input.get_axis(&"dome_close", &"dome_open"))))


## QUANTO SI E' LONTANI, MISURATO SUL PAVIMENTO e non in linea d'aria.
##
## Il quadro sta a un metro e trentacinque, il giocatore ha l'origine ai piedi: in
## tre dimensioni chi gli sta davanti a un metro e mezzo risulta a 2,02 metri, e il
## quadro gli si staccava di mano mentre lo stava guardando. Il dislivello fra i
## piedi di uno e un oggetto appeso al muro non e' distanza, e' altezza.
func _distanza() -> float:
	var a := global_position
	var b := _user.global_position
	return Vector2(a.x - b.x, a.z - b.z).length()


func _on_interacted(by: Node3D) -> void:
	if _active:
		_lascia()
		return
	_active = true
	_user = by
	_aggiorna_prompt()


func _lascia() -> void:
	_comanda(0)
	_active = false
	_user = null
	_aggiorna_prompt()


## Annuncia il comando SOLO QUANDO CAMBIA.
##
## Un pulsante tenuto premuto per sei secondi emetterebbe trecentosessanta volte
## lo stesso numero, e chiunque si colleghi a questo segnale domani pagherebbe
## quel traffico per sempre. È la stessa regola di `dome_aperture_changed`.
func _comanda(verso: int) -> void:
	if verso == _direction:
		return
	_direction = verso
	Events.dome_button_changed.emit(verso)


func _exit_tree() -> void:
	# Un quadro che sparisce con un pulsante premuto lascerebbe il motore acceso
	# per sempre: nessuno emetterebbe più lo zero.
	if _direction != 0:
		_comanda(0)


func _aggiorna_prompt() -> void:
	prompt_text = "Lascia il quadro" if _active else "Usa il quadro della cupola"
