## La fase dell'accensione si può SBAGLIARE, e si può rimediare? Si gioca.
##
## DUE DOMANDE, E LA SECONDA È QUELLA CHE CONTA. Che collegando le cose nell'ordine
## giusto rispondano tutte è il caso facile, e lo prova anche il banco. Il caso che
## fa esistere questa fase è l'altro: aprire la porta alla ruota portafiltri con la
## camera spenta, accendere la camera dopo, e trovare la porta ancora muta. Se
## quella porta guarisse da sola, la fase non avrebbe niente da insegnare; se non
## guarisse nemmeno col RESET, sarebbe un vicolo cieco in cui il giocatore resta
## chiuso.
##
## È UNA SCENA E NON UNO `--script`: la fase vive dentro l'albero e legge autoload.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/prova_accensione.tscn
##
## Scrive user://accensione.png — il pannello ingrandito tre volte, fotografato nel
## momento in cui una porta è muta, che è il momento che vale la pena guardare.
extends Node

const FUORI := "user://accensione.png"

## IL SECONDO SCATTO È QUELLO CHE SERVE. Il pannello a fine fase è tre OK in
## colonna e non dice niente su come ci si è arrivati: la schermata da giudicare è
## quella in cui una porta è muta e il registro racconta perché.
const FUORI_MUTA := "user://accensione_muta.png"

## I bit degli apparecchi, nell'ordine in cui `PhaseStartup` li elenca.
const MOUNT := 1
const CAMERA := 2
const FILTER := 4

var _fase: PhaseStartup
var _guasti := 0
var _chiusa := false


func _ready() -> void:
	_monta.call_deferred()


func _monta() -> void:
	var scena: Node = load("res://phases/startup/phase_startup.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	_fase = scena as PhaseStartup
	_fase.finished.connect(func(r: PhaseResult) -> void:
		_chiusa = true
		print("[accensione] fase chiusa: ok=%s punteggio=%d" % [r.ok, r.score]))
	# Il pannello a schermo, ingrandito: a grandezza naturale è un francobollo.
	var strato := CanvasLayer.new()
	strato.scale = Vector2(3, 3)
	add_child(strato)
	var vista := _fase.screen()
	vista.get_parent().remove_child(vista)
	strato.add_child(vista)
	_gioca()


func _gioca() -> void:
	await _la_strada_storta()
	await _il_rimedio()
	await _il_resto()
	await _uscita()
	await _scatta()
	print("[accensione] %s" % ("tutto a posto" if _guasti == 0
		else "%d COSE NON TORNANO" % _guasti))
	get_tree().quit()


## Si collega la ruota portafiltri per prima, che è lo sbaglio naturale: è
## l'ultima riga, non ha interruttore, e sembra la più facile.
func _la_strada_storta() -> void:
	await _premi(&"startup_down")
	await _premi(&"startup_down")
	await _premi(&"startup_act")
	await _aspetta(1.5)
	_verifica("la ruota collegata a camera spenta non risponde",
		_fase.answering() & FILTER == 0)


## Si accende la camera, e la porta della ruota resta muta lo stesso: è il fatto
## che questa fase esiste per insegnare. Poi il RESET la rimette in gioco.
func _il_rimedio() -> void:
	await _premi(&"startup_up")
	await _premi(&"startup_act")            # interruttore della camera
	await _aspetta(0.3)
	_verifica("accendere la camera DOPO non fa rispondere la ruota",
		_fase.answering() & FILTER == 0)
	await _scatta_in(FUORI_MUTA)

	await _premi(&"startup_down")
	await _premi(&"startup_reset")
	await _aspetta(1.1)
	await _premi(&"startup_act")
	await _aspetta(1.5)
	_verifica("dopo il reset la ruota risponde", _fase.answering() & FILTER != 0)


func _il_resto() -> void:
	await _premi(&"startup_up")             # camera: e' gia' accesa, quindi collega
	await _premi(&"startup_act")
	await _aspetta(1.5)
	_verifica("la camera risponde", _fase.answering() & CAMERA != 0)

	await _premi(&"startup_up")             # montatura: accendi, poi collega
	await _premi(&"startup_act")
	await _aspetta(0.3)
	await _premi(&"startup_act")
	await _aspetta(1.5)
	_verifica("la montatura risponde", _fase.answering() & MOUNT != 0)
	_verifica("rispondono tutti", _fase.is_ready())


## L'ultima pressione dello stesso tasto chiude la fase. Che questo funzioni non è
## scontato: `startup_act` fa due mestieri, e uno dei due potrebbe mangiarsi
## l'altro.
func _uscita() -> void:
	await _premi(&"startup_act")
	await _aspetta(0.2)
	_verifica("INVIO a tutto collegato chiude la fase", _chiusa)


func _scatta() -> void:
	await _scatta_in(FUORI)


func _scatta_in(dove: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("[accensione] headless: nessuno scatto")
		return
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(dove)
		print("[accensione] scatto in %s" % ProjectSettings.globalize_path(dove))


## Preme e rilascia un'azione.
##
## `Input.action_press` mette lo STATO e non genera nessun evento, e questa fase
## legge tutto in `_unhandled_input`: senza un evento vero non le arriverebbe
## niente, e la sonda direbbe che la fase non risponde ai tasti.
func _premi(azione: StringName) -> void:
	var e := InputEventAction.new()
	e.action = azione
	e.pressed = true
	Input.parse_input_event(e)
	await _aspetta(0.08)


func _aspetta(secondi: float) -> void:
	await get_tree().create_timer(secondi).timeout


func _verifica(cosa: String, vero: bool) -> void:
	if vero:
		print("[accensione] ok: %s" % cosa)
		return
	_guasti += 1
	print("[accensione] %s   <-- ATTESO, e non e' cosi'" % cosa)
