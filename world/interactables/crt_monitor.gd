## Il monitor CRT sulla scrivania: un oggetto del mondo, e l'unico interagibile
## che questa storia costruisce.
##
## Non è un mobile. È l'oggetto per cui la stanza esiste: le interfacce
## diegetiche sono il grosso del gameplay, e questo è lo schermo su cui
## appariranno. La scocca è arredo; il vetro è un `CrtScreen`, che vive in
## `crt/` ed è un sistema generico.
##
## NON EMETTE `Events.screen_registered`, ed è una decisione, non una
## dimenticanza.
##
## `crt/crt_screen.gd::_ready()` lo emette già da sé, con `self`. Lo snippet di
## `game-architecture.md § Architectural Boundaries` fa invece emettere
## `$CrtScreen` a questo file: applicando entrambi, il segnale partirebbe DUE
## volte per ogni schermo e alla storia 1.3 `night_session` collegherebbe `_crt`
## due volte. È il rilievo M5 del readiness report, assegnato a questa storia.
##
## Emette `CrtScreen` perché è lui a sapere di essere pronto — il suo `_ready()`
## è anche il punto in cui la texture del viewport viene agganciata al materiale
## dello schermo — e perché così `world/` non ha bisogno di conoscere il tipo
## `CrtScreen` per annunciarlo. L'AC3 resta soddisfatto: il monitor entra in
## scena, e la registrazione parte.
class_name CrtMonitor
extends Interactable

## Chi ha bisogno del monitor lo trova per GRUPPO, mai per percorso di nodo.
##
## Un percorso si rompe al primo spostamento — ed è precisamente ciò che l'AC3
## vieta. Un gruppo no: il nodo può essere spostato, rinominato o annidato
## diversamente e continua a farsi trovare.
const GROUP := &"crt_monitor"

@onready var _screen: CrtScreen = %CrtScreen


func _ready() -> void:
	super()
	add_to_group(GROUP)


## Lo schermo di questo monitor, per chi lo ha trovato tramite il gruppo.
func screen() -> CrtScreen:
	return _screen
