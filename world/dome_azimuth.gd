## LA CUPOLA CHE INSEGUE IL TELESCOPIO, e non copiandogli l'azimut.
##
## COSA FA, IN UNA RIGA: gira la calotta finché la fessura sta dove il raggio del
## telescopio buca la sfera.
##
## PERCHÉ NON BASTA COPIARE L'AZIMUT, che è la cosa che tutti fanno per prima e che
## qui sbaglia di decine di gradi. Il conto giusto non parte dal telescopio: parte
## dall'APERTURA, e chiede dove la retta di vista incontra la sfera della cupola. Le
## due cose coincidono solo se l'apertura sta nel centro della sfera — e su una
## equatoriale tedesca non ci sta mai, perché il tubo lavora **di fianco** al
## pilastro. Qui, misurato sulla geometria vera (sfera di raggio 2,50 col centro a
## 3,38 m, apertura a 1,86 m e fino a un metro fuori dall'asse):
##
##     apertura 1,05 m fuori asse   azimut telescopio   azimut cupola   scarto
##       puntando a 30° di altezza         180°             155°         -25°
##                  60°                    180°             147°         -33°
##                  75°                    180°             130°         -50°
##                  88°                    180°              96°         -84°
##
## Non è una correzione: è un altro numero. Due cause si sommano — il braccio della
## declinazione e il fatto che l'apertura stia un metro e mezzo SOTTO il centro della
## sfera — e nessuna delle due si vede guardando la scena.
##
## DUE CONSEGUENZE CHE ESCONO DAGLI STESSI NUMERI, e sono giocabili:
##   - dopo un ribaltamento al meridiano la cupola deve saltare di cinquanta-ottanta
##     gradi, perché il tubo passa dall'altra parte del pilastro;
##   - sotto i trenta gradi di altezza l'uscita cade sulla linea di gronda, cioè quei
##     bersagli la cupola non li vede. È vero anche nell'edificio reale, e il
##     targeting dovrà saperlo.
##
## ASSERVITA E NON A MANO, ed è una decisione contro il GDD (fase 7, «porti la
## fessura sull'azimut del telescopio»). La ragione è la regola che il progetto ha
## già: se una cosa nessuno la farebbe davvero, si cambia il documento. Con scarti
## che cambiano di continuo mentre il cielo gira, girare la cupola a mano non è un
## rituale, è un metronomo — e nessun osservatorio con un computer che pilota la
## montatura la gira a mano. La pulsantiera resta come comando manuale.
##
## IL MOTORE È LENTO, e si deve vedere. Una cupola da cinque metri pesa, e quando
## parte lo sanno tutti: otto gradi al secondo sono dieci secondi per un quarto di
## giro. È anche il motivo per cui l'inseguimento non insegue di continuo — vedi
## `GIOCO`.
class_name DomeAzimuth
extends Node3D

const GROUP := &"dome_azimuth"

## Gradi al secondo del motore.
const VELOCITA := 8.0

## Di quanto la fessura può stare sbagliata prima che il motore riparta, in gradi.
##
## SERVE, E NON È PIGRIZIA: senza, il motore inseguirebbe la deriva del cielo con
## micro-scatti continui, e una cupola che si muove sempre di un grado è più falsa di
## una che sta ferma. Le cupole vere hanno esattamente questo gioco — si muovono a
## strappi, quando l'errore accumulato supera una soglia — ed è per quello che
## durante una posa le si sente partire ogni tanto invece che sentirle sempre.
const GIOCO := 4.0

## Il nodo della calotta: la sua origine sta sull'asse della cupola, alla quota di
## gronda, e i portelli gli sono appesi. Ruotarlo ruota tutto.
@export var calotta: NodePath

## Il raggio della sfera, in metri. Dal modello, scritto dal generatore.
@export var raggio := 2.50

## Dove guarda la fessura quando la calotta è a rotazione zero, in gradi di azimut.
## Il modello la taglia sul meridiano verso -Z, che in questa convenzione è 180.
@export var fessura_a_riposo := 180.0

var _calotta: Node3D
var _centro := Vector3.ZERO
var _apertura := 0.0
var _azimut := 0.0
var _voluto := 0.0
var _fermo := true


func _ready() -> void:
	add_to_group(GROUP)
	_calotta = get_node_or_null(calotta) as Node3D
	if _calotta == null:
		push_error("[system] cupola: la calotta non si trova")
		set_process(false)
		return
	# IL CENTRO SI MISURA, non si scrive: è l'origine del nodo della calotta, che il
	# modellatore mette sull'asse alla quota di gronda. Un numero copiato qui sarebbe
	# la seconda verità sulla stessa cosa, e il giorno che la cupola si alza di dieci
	# centimetri l'inseguimento sbaglierebbe senza dirlo.
	_centro = _calotta.global_position
	# LA FESSURA COMINCIA DOVE IL MODELLO L'HA MESSA, e il motore non parte finché
	# non c'è niente da inseguire.
	_azimut = fessura_a_riposo
	_voluto = fessura_a_riposo
	Events.dome_aperture_changed.connect(func(f: float) -> void: _apertura = f)


## L'azimut in cui va portata la fessura perché il raggio esca, in gradi.
## `NAN` se quel raggio non incontra la cupola affatto — cioè se si sta puntando
## sotto la linea di gronda, dove c'è il tetto e non la calotta.
static func azimut_di_uscita(apertura: Vector3, direzione: Vector3,
		centro: Vector3, raggio: float) -> float:
	var d := apertura - centro
	var dp := d.dot(direzione)
	var disc := dp * dp - (d.length_squared() - raggio * raggio)
	if disc < 0.0:
		return NAN
	# La radice PIÙ GRANDE, cioè l'uscita davanti a sé. Quella piccola è dietro le
	# spalle, e con l'apertura dentro la sfera è negativa: prenderla vorrebbe dire
	# mandare la fessura dalla parte opposta, che è un difetto che sembra un bug di
	# segno e invece è un errore di geometria.
	var u := d + direzione * (-dp + sqrt(disc))
	if u.y < 0.0:
		return NAN          # sotto la gronda: lì la cupola non c'è
	return rad_to_deg(atan2(u.x, u.z))


## Dove guarda la fessura adesso, in gradi di azimut. Per le sonde.
func azimut() -> float:
	return _azimut


## Quanto la fessura è lontana da dove dovrebbe stare, in gradi. Per le sonde.
func errore() -> float:
	return absf(wrapf(_voluto - _azimut, -180.0, 180.0))


## Vero mentre il motore gira.
func in_moto() -> bool:
	return not _fermo


static func find_in(tree: SceneTree) -> DomeAzimuth:
	return tree.get_first_node_in_group(GROUP) as DomeAzimuth


func _process(delta: float) -> void:
	# A CUPOLA CHIUSA NON SI INSEGUE NIENTE, e non è una finezza: senza questa riga
	# il motore parte al primo fotogramma della notte e porta la fessura sull'azimut
	# del telescopio a riposo — che sono quasi centottanta gradi. Il giocatore vede
	# la calotta girare mezzo giro sotto i piedi appena entra, per inseguire una
	# fessura che è ancora chiusa. Federico l'ha visto e l'ha detto in tre parole:
	# «è tutto spostato».
	#
	# E NON È SOLO ESTETICA: una cupola vera non si slega mentre è chiusa, perché
	# non c'è niente da allineare e perché il motore lo si accende quando serve.
	if _apertura < 0.05:
		_fermo = true
		return
	var m := TelescopeMount.find_in(get_tree())
	if m == null:
		return
	var chiesto := azimut_di_uscita(m.apertura(), m.direzione(), _centro, raggio)
	if not is_nan(chiesto):
		_voluto = chiesto
	var scarto := wrapf(_voluto - _azimut, -180.0, 180.0)
	# Parte quando lo scarto supera il gioco, e poi va fino in fondo: una cupola che
	# si ferma appena rientra nella tolleranza riparte due secondi dopo, e il rumore
	# del motore diventa un singhiozzo.
	if _fermo and absf(scarto) < GIOCO:
		return
	_fermo = false
	_azimut = move_toward(_azimut, _azimut + scarto, VELOCITA * delta)
	_calotta.rotation.y = deg_to_rad(_azimut - fessura_a_riposo)
	if absf(wrapf(_voluto - _azimut, -180.0, 180.0)) <= 0.05:
		_fermo = true
