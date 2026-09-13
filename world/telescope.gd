## Il telescopio della cupola: la RESA del registro «stare» dell'attesa (storia 3.5).
## Mentre l'imaging espone, il tubo insegue lento; a sequenza ferma sta immobile. È il
## visivo del «telescopio che lavora da solo»
## mentre il giocatore alza gli occhi alla fessura — non la misura, che è del gemello
## `DomeActivity`. Due responsabilità diverse, due nodi (vedi Design Notes dello spec).
##
## SA TRAMITE `Events`, MAI INTERROGANDO LA FASE. Che una sequenza sia in corso passa
## SOLO da `Events.phase_started`/`phase_finished` filtrati su `key == &"imaging"` — la
## stessa soft-coupling via `StringName` di `world/dome_activity.gd`. Questo
## file NON nomina `phases/`, `night/`, `photo/`: «imaging» compare solo come chiave di
## filtro sul bus, e il mondo continua a non conoscere la cartella delle fasi.
##
## NESSUN BONUS, NESSUN INPUT, NESSUN ACCESSO A VIEWPORT/CAMERA. Il telescopio in questa
## storia NON è un interagibile: nessun prompt, nessuna azione `E`. Non tocca
## `Game`/`NightRun` né alcun punteggio, e da nessuna parte è scritto che potrebbe. Non
## assume di essere visibile: un nodo di sfondo non chiede `get_viewport()` né la camera.
##
## LA FISICITÀ È NELLA SCENA. Il volume di collisione che ferma il giocatore (DW-12,
## lasciato in eredità dalla 3.1: «la fisicità appartiene alla 3.5») è il figlio `Body`
## `StaticBody3D` su `LAYER_WORLD`, montato in `dome.tscn`. È fisicità, non un volume
## d'interazione: ci si sbatte contro, non lo si «usa».
class_name Telescope
extends Node3D

## Chi ha bisogno del telescopio lo trova per GRUPPO, mai per percorso di nodo: stessa
## regola della moka e del monitor.
const GROUP := &"telescope"

## Quanto insegue: radianti al secondo di gioco. Un inseguimento LENTO e continuo,
## percepibile guardandolo per qualche secondo — non un'oscillazione. `_process` lo
## moltiplica per `delta`, già scalato da `Engine.time_scale`, quindi F1–F4 lo
## accelerano come tutto il resto. La velocità esatta la tara l'operatore guardando:
## «percepibile in qualche secondo» è un giudizio d'occhio, non un numero da stimare.
##
## 0.08 ERA TROPPO: 4,6 gradi al secondo, ventitré in cinque secondi — si legge come un
## motore che gira, non come una montatura che insegue. Il numero non era mai stato
## guardato da nessuno perché fino alla review del 2026-08-24 il moto partiva al MONTAGGIO
## della fase, cioè in un momento in cui il giocatore sta al monitor e non lo vede.
## Portato a 0.02 (1,15 gradi al secondo) da Federico il 2026-08-24, sempre a occhio: se
## rivedendolo giocare risultasse ancora sbagliato, è questa riga e nient'altro.
const TRACK_RATE := 0.02


@onready var _tube: Node3D = $Tube

## Vero mentre una sequenza di imaging è in corso: SOLO allora il tubo si muove. Lo dice
## il bus, non la fase.
var _tracking := false


func _ready() -> void:
	add_to_group(GROUP)

	# Non `connect` in scena: il collegamento sta nel codice del nodo, così chi istanzia
	# `dome.tscn` in `world/` non deve ricablare nulla.
	# LA SEQUENZA, non lo schermo della sequenza. `phase_started(&"imaging")` diceva
	# «il pannello di configurazione è comparso»: il tubo si metteva a inseguire mentre
	# il giocatore stava ancora scegliendo i frame. `sequence_started` arriva su START.
	Events.sequence_started.connect(_on_sequence_started)
	Events.sequence_ended.connect(_on_sequence_ended)

	# Fermo finché una sequenza non parte: `_process` gira SOLO in
	# tracking (lo accende `_on_phase_started`), così a riposo non c'è lavoro per frame.
	set_process(false)


## La sequenza è partita DAVVERO (il giocatore ha premuto START). Nessun filtro per
## chiave: il segnale porta già il fatto, e la stringa `&"imaging"` non compare più in
## questo file — il mondo non ha mai avuto bisogno di sapere come si chiama la fase.
func _on_sequence_started() -> void:
	_tracking = true
	set_process(true)


## La sequenza è finita — conclusa, oppure smontata a metà dall'alba o da *rifai
## setup*. Prima della review dell'epica 3 questo nodo ascoltava `phase_finished`, che
## nel secondo caso non arriva MAI: una posa interrotta lasciava il tubo a ruotare per il
## resto della partita. Il tubo si ferma dov'è (nessun
## ritorno a casa: è un segnaposto, non una montatura vera che fa il parking).
func _on_sequence_ended() -> void:
	_tracking = false
	set_process(false)


## L'inseguimento: il tubo ruota lentamente in azimut attorno al mount. Solo il tubo si
## muove, non il treppiede (che è statico nella scena). `delta` è già scalato da
## `Engine.time_scale`, quindi F1–F4 accelerano l'inseguimento come il resto.
func _process(delta: float) -> void:
	# Guardia difensiva: se per qualche via `_process` girasse fuori dal tracking, non
	# tocca il tubo. In pratica non ci si arriva mai (chi lo spegne lo ferma anche qui).
	if not _tracking:
		return
	_tube.global_rotate(Vector3.UP, TRACK_RATE * delta)


## Il telescopio della scena, o `null` se non ce n'è. Stessa firma di `Moka.find_in`.
static func find_in(tree: SceneTree) -> Telescope:
	return tree.get_first_node_in_group(GROUP) as Telescope
