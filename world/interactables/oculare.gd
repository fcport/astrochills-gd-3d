## GUARDARE DENTRO IL TELESCOPIO, che è la cosa che nessuno aveva ancora potuto fare.
##
## LA RICHIESTA, DA FEDERICO: «se uno toglie la camera sarebbe bello poter guardare
## nel telescopio e vedere cosa sta puntando». È il gesto che chiude il cerchio del
## focheggiatore: la CCD si smonta già (vedi `ccd_camera.gd`), e finora smontarla
## lasciava un buco che non serviva a niente.
##
## COSA SI VEDE, DETTO SUBITO. Non una nebulosa disegnata: il CIELO, da dove il tubo
## sta guardando adesso. Se la fessura è chiusa, o la cupola non è girata dov'è
## girato il telescopio, si vede il buio della calotta — ed è la risposta giusta,
## perché è quello che si vedrebbe davvero. Questa vista non aggiunge nessun oggetto
## al mondo: mette l'occhio in un punto che c'è già.
##
## L'OCULARE È UNA CAMERA SU `Mira`, e non su `Fuoco`. `Fuoco` è la bocca del
## portaoculare — dove si avvita la CCD, cioè dove sta l'OCCHIO; `Mira` è l'empty che
## `telescopio_blender.py` appende sull'ASSE OTTICO all'altezza dell'apertura, con il
## proprio +Y nella direzione di vista. Chi guarda dentro un telescopio vede quello
## che entra dall'apertura, non quello che sta di fianco all'oculare: la camera va
## dove entra la luce. E siccome è appesa lì dentro, insegue il tubo da sola — quando
## la montatura si muove, il campo scorre, che è metà di quello che c'era da vedere.
##
## IL CAMPO È LARGO PIÙ DEL VERO, ed è una scelta dichiarata. Un oculare su questo
## Newton dà mezzo grado; a mezzo grado le stelle di `world/shaders/cielo.gdshader`
## — che hanno una dimensione ANGOLARE fissa, essendo dischetti dentro celle di
## direzione — diventerebbero palle grosse come una moneta, e il cielo si leggerebbe
## come un difetto. A dodici gradi restano puntini e si vede il campo muoversi: è il
## campo di un CERCATORE, non di un oculare, ed è il compromesso fra la fisica e ciò
## che questo cielo sa disegnare. Il numero si tara guardando, come `TRACK_RATE`.
class_name Oculare
extends Interactable

## Chi ha bisogno dell'oculare lo trova per GRUPPO, mai per percorso: stessa regola
## della montatura, della cupola e del monitor.
const GROUP := &"oculare"

## L'ampiezza del campo, in gradi. Vedi l'intestazione: è larga apposta.
const CAMPO_GRADI := 12.0

## Quanto del quadro resta scoperto dal velo, in frazione della metà dell'altezza.
## Il cerchio dell'oculare tocca il bordo alto e basso e lascia neri i due fianchi:
## è come si vede mettendo l'occhio a un tubo, ed è anche il motivo per cui non
## serve nessun testo che spieghi dove si sta guardando.
const RAGGIO_VELO := 0.92

## L'asse ottico: il nodo `Mira` del telescopio, con il proprio +Y verso il cielo.
## Lo scrive il generatore della scena.
@export var mira: NodePath

## Emesso entrando e uscendo. È un FATTO del mondo — «adesso qualcuno ha l'occhio
## al telescopio» — e chi vorrà saperlo (una fase, un punteggio) lo ascolta invece
## di chiedere.
signal guardato(dentro: bool)

var _mira: Node3D
var _cam: Camera3D
var _velo: CanvasLayer
var _dentro := false
var _chi: Player = null


static func find_in(tree: SceneTree) -> Oculare:
	return tree.get_first_node_in_group(GROUP) as Oculare


func _ready() -> void:
	add_to_group(GROUP)
	# NON È UN OSTACOLO, ed è l'unico Interactable che si toglie dal layer del
	# mondo. Questo corpo sta nella bocca del focheggiatore, cioè esattamente dove
	# la camera CCD si avvita e dove il tubo ha già la propria collisione: un
	# secondo volume solido lì dentro non fermerebbe niente che non sia già
	# fermato, e sarebbe un ostacolo in più contro cui la CCD sbatte montandosi.
	# Il raggio del giocatore lo trova lo stesso, perché cerca mondo E
	# interagibili.
	collision_layer &= ~LAYER_WORLD
	_mira = get_node_or_null(mira) as Node3D
	if _mira == null:
		push_error("[oculare] l'asse ottico del telescopio non si trova")
		return
	_cam = Camera3D.new()
	_cam.name = "Oculare"
	_cam.fov = CAMPO_GRADI
	_cam.current = false
	_mira.add_child(_cam)
	# IL +Y DI `Mira` DIVENTA IL -Z DELLA CAMERA, che è dove una camera guarda in
	# Godot. Il quarto di giro attorno a X è tutta la conversione, ed è lo stesso
	# scarto di convenzione che `ccd_camera.gd` documenta: quel nodo lo esporta
	# Blender, dove la direzione è +Z, e il glTF la porta su +Y.
	_cam.transform = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO)
	interacted.connect(_su_interazione)
	set_process_unhandled_input(false)


## Ci si guarda dentro solo se la camera CCD NON è avvitata, e non è una regola
## inventata: al fuoco ci sta una cosa sola. È anche l'unico modo in cui il
## giocatore scopre che smontare la camera serve a qualcosa.
func can_interact() -> bool:
	return super() and not _ccd_montata()


func prompt() -> String:
	return "Guarda nell'oculare"


## Se in questo momento qualcuno ha l'occhio al telescopio.
func dentro() -> bool:
	return _dentro


func _ccd_montata() -> bool:
	var ccd := CcdCamera.find_in(get_tree())
	return ccd != null and ccd.montata()


func _su_interazione(chi: Node3D) -> void:
	if _dentro:
		_esci()
	else:
		_entra(chi as Player)


func _entra(chi: Player) -> void:
	if _cam == null or _dentro:
		return
	_dentro = true
	_chi = chi
	# IL CONTROLLO SI TOGLIE PRIMA DI CAMBIARE CAMERA, come nella postazione al
	# monitor (ADR-003): con il controller acceso il mouse continuerebbe a girare
	# una testa che nessuno vede, e uscendo ci si ritroverebbe voltati.
	if _chi != null:
		_chi.set_enabled(false)
		# E IL MIRINO SPARISCE. Il punto al centro dello schermo resta acceso anche
		# a controllo spento (vedi `crosshair.gd`), e dentro il campo dell'oculare
		# diventa una stella che non c'è, ferma al centro esatto: la prima cosa che
		# uno crede di aver trovato.
		_chi.mostra_mirino(false)
	_cam.current = true
	_mostra_velo(true)
	set_process_unhandled_input(true)
	guardato.emit(true)


func _esci() -> void:
	if not _dentro:
		return
	_dentro = false
	set_process_unhandled_input(false)
	_mostra_velo(false)
	if _chi != null:
		# LA CAMERA DEL GIOCATORE SI RIPRENDE IL POSTO DA SOLA: `current = true`
		# su una camera ne spegne ogni altra dello stesso viewport, ed è meglio
		# che spegnere questa e sperare che qualcuno si faccia avanti — senza
		# nessuna camera corrente il viewport resta nero.
		var cam := _chi.camera()
		if cam != null:
			cam.current = true
		_chi.mostra_mirino(true)
		_chi.set_enabled(true)
	_chi = null
	guardato.emit(false)


## Si esce con lo stesso tasto con cui si è entrati, o con Esc. Non c'è una riga a
## schermo che lo dica: chi è entrato premendo `E` ha in mano l'unica informazione
## che serve, e il velo nero dice già che si è dentro qualcosa.
func _unhandled_input(event: InputEvent) -> void:
	if not _dentro:
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_esci()


## IL VELO È UN CERCHIO NERO, e serve a due cose insieme: dice che si sta guardando
## dentro un tubo, e nasconde che il campo è largo dodici gradi invece di mezzo.
## Vive in un `CanvasLayer` figlio di questo nodo, quindi disegna dentro il
## `SubViewport` del mondo insieme al mirino e al prompt — cioè passa dal filtro
## CRT come tutto il resto, invece di stargli sopra a piena risoluzione.
func _mostra_velo(acceso: bool) -> void:
	if not acceso:
		if _velo != null:
			_velo.visible = false
		return
	if _velo == null:
		_velo = CanvasLayer.new()
		_velo.name = "VeloOculare"
		var rect := ColorRect.new()
		rect.name = "Velo"
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = load("res://world/shaders/oculare.gdshader")
		mat.set_shader_parameter("raggio", RAGGIO_VELO)
		rect.material = mat
		_velo.add_child(rect)
		add_child(_velo)
	_velo.visible = true
