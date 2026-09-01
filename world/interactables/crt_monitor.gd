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
##
## MA IL SIGNAL DA SOLO NON BASTA, e chi arriva dopo deve saperlo. `CrtScreen`
## emette nel proprio `_ready()`, e l'ordine di costruzione dell'albero è
## profondità-prima: quando il mondo è istanziato dentro `main.tscn`,
## l'emissione avviene PRIMA di `Main._ready()`. Chiunque nasca lì dentro — la
## `night_session` dell'epica 2 — si collegherebbe a segnale già passato e non
## riceverebbe mai niente. Il ripiego è `find_in()`: chi arriva tardi non aspetta
## un annuncio, va a cercare. Il gruppo è la via, mai un percorso di nodo.
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
	add_to_group(GROUP)
	# IL MONITOR STA ATTACCATO ALLA RETE come tutto il resto, e staccando la
	# corrente si deve spegnere: e' la prima cosa che il GDD affida al contatore
	# («governa PC, monitor, montatura e luci»), e un CRT che continua a brillare
	# con il quadro staccato smaschera tutto l'impianto in un colpo solo.
	#
	# SI SPEGNE IL VETRO E NON LA FASE: quello che gira dentro il computer resta
	# dov'e', e riaccendendo si ritrova la stessa schermata. Un monitor spento non
	# e' un programma chiuso, ed e' la differenza fra togliere la corrente al
	# tubo catodico e riavviare la notte.
	Events.mains_changed.connect(_su_rete)


func _su_rete(acceso: bool) -> void:
	if _screen != null:
		_screen.visible = acceso


## Il monitor della scena, o `null` se non ce n'è. È il ripiego per chi si è
## perso `Events.screen_registered` perché è nato dopo l'emissione.
##
## Se un giorno l'osservatorio avrà più di un CRT questa funzione non basterà
## più, e sarà giusto che smetta di bastare: il chiamante dovrà dire QUALE
## monitor vuole, invece di prendere il primo che passa.
static func find_in(tree: SceneTree) -> CrtMonitor:
	return tree.get_first_node_in_group(GROUP) as CrtMonitor


## Lo schermo di questo monitor, per chi lo ha trovato tramite il gruppo.
func screen() -> CrtScreen:
	return _screen
