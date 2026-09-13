## L'attività «stare a guardare» della cupola: la MISURA del registro «stare» dell'attesa
## (storia 3.5). Rileva il giocatore nella cupola e, quando c'è una sequenza in corso e
## ci resta più di qualche secondo, emette la coppia `wait_activity_started/ended(&"cupola")`
## verso la telemetria (3.6). È il gemello di misura del `Telescope`, che fa la resa:
## due responsabilità diverse, due nodi (vedi Design Notes dello spec).
##
## GEMELLO DI `IndoorsVolume`. Un `Area3D` che rileva il SOLO giocatore
## (`collision_mask = LAYER_PLAYER`, `collision_layer = 0`), trovabile per gruppo, con il
## ripiego «dalla parte giusta». Ne ricalca la configurazione perché il mestiere è lo
## stesso — sapere se un corpo è dentro un volume — ma qui il volume è la sola cupola,
## non l'edificio.
##
## SA DELLA SEQUENZA TRAMITE `Events`, MAI INTERROGANDO LA FASE. Che una sequenza sia in
## corso passa SOLO da `Events.phase_started`/`phase_finished` filtrati su
## `key == &"imaging"` — la stessa soft-coupling del `Telescope`.
## Questo file NON nomina `phases/`, `night/`, `photo/`: «imaging» compare solo come
## chiave di filtro sul bus.
##
## IL GATE E LA SOGLIA SONO PURI; TIMER ED EMISSIONE SONO EFFETTO. Come `Moka`, la
## logica di decisione è in funzioni statiche collaudabili sul banco (`is_gate_open`,
## `should_emit_started`, `should_emit_ended`): nessuno SceneTree,
## nessun autoload, nessun timer. Il nodo tiene lo stato, guida il `Dwell` Timer, e
## MAPPA le decisioni pure sull'emissione onesta della coppia.
##
## NESSUN FEEDBACK VISIBILE, NESSUN BONUS, NESSUN PROMPT. La cupola non chiede niente:
## nessun contatore, nessun conto alla rovescia, nessun «non letti», nessun fallimento.
## Lo «stare» non tocca `Game`/`NightRun` né alcun punteggio, e da nessuna parte è scritto
## che potrebbe. L'emissione della coppia è l'unico contratto verso la telemetria, e non
## produce nulla che il giocatore veda.
class_name DomeActivity
extends Area3D

## Il marcatore dell'attività per il condotto di misura (C4). La coppia
## `Events.wait_activity_started/ended(&"cupola")` racchiude una permanenza; uno `started`
## senza `ended` (quit in cupola a metà posa) è un abbandono — un dato, non un buco.
const ACTIVITY := &"cupola"

## Chi ha bisogno di questo volume lo trova per GRUPPO, mai per percorso di nodo: stessa
## regola di `IndoorsVolume`, della moka e del monitor.
const GROUP := &"dome_activity"

## La soglia di permanenza: quanti secondi di gioco il giocatore deve restare in cupola
## con una sequenza in corso perché «stare a guardare» conti — POCHI secondi, non decine.
## Separa lo «stare» dal semplice attraversare la cupola. Il `Dwell` Timer conta col
## tempo scalato (come il `BrewTimer` della moka), quindi F1–F4 lo accelerano. Tarabile
## guardando/misurando: è una verifica d'operatore, non un numero da difendere al pixel.
const DWELL_SECONDS := 4.0


@onready var _dwell: Timer = $Dwell

## Le due condizioni del gate, aggiornate dagli eventi. Il giocatore è nella cupola;
## una sequenza è in corso. `_reevaluate()` le combina.
var _in_dome := false
var _seq_running := false

## Vero fra `started` e `ended`: si sta «stando a guardare». Serve a non riemettere
## `started` due volte e a sapere se emettere `ended` quando il gate si chiude.
var _watching := false


# --- Logica pura del gate e della soglia: statica, senza SceneTree, sul banco ---------
#
# Gemella di `Moka.is_interactive`. Il nodo la consulta e ci
# appende gli effetti (timer, emissione); la funzione non tocca né l'uno né l'altro.

## Il gate è aperto quando ENTRAMBE le condizioni valgono: il giocatore è in cupola E una
## sequenza è in corso. È la condizione perché la permanenza abbia senso di essere contata.
static func is_gate_open(in_dome: bool, seq_running: bool) -> bool:
	return in_dome and seq_running


## Se emettere `started`: solo se NON si sta già guardando E il gate è aperto. Valutato al
## timeout del `Dwell` (dopo la soglia di permanenza), non appena il gate si apre.
static func should_emit_started(watching: bool, gate_open: bool) -> bool:
	return not watching and gate_open


## Se emettere `ended`: solo se si STA guardando E il gate si è chiuso. Valutato quando una
## delle due condizioni cade — uscita dalla cupola O fine sequenza, quale prima: entrambe
## chiudono il gate, quindi qui sono lo stesso caso e non c'è doppio `ended`.
static func should_emit_ended(watching: bool, gate_open: bool) -> bool:
	return watching and not gate_open

## `affects_sequence(key)` VIVEVA QUI, e la review dell'epica 3 l'ha tolta: filtrava le
## chiavi di `phase_started` per decidere se il gate riguardasse questa cupola. Adesso il
## gate si apre su `Events.sequence_started`, che porta il fatto senza la chiave — non
## c'è più niente da filtrare, e `&"imaging"` non compare più in questo file.


# --- Il nodo: mappa le decisioni pure sugli effetti ----------------------------------

func _ready() -> void:
	add_to_group(GROUP)
	# SOLO IL GIOCATORE, e l'area non deve essere TROVATA da nessuno: stessa maschera di
	# `IndoorsVolume`. Senza la maschera l'area si sveglierebbe per ogni parete e ogni
	# mobile (`StaticBody3D` sul layer del mondo) che la attraversano.
	collision_mask = Interactable.LAYER_PLAYER
	collision_layer = 0
	monitoring = true

	# Il rilevamento del giocatore, con la guardia `body is Player`: solo il suo corpo
	# apre/chiude `_in_dome`, mai un altro corpo che per errore finisse sul layer.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# LA SEQUENZA dal bus, e non lo schermo della sequenza. Fino alla review dell'epica 3
	# il gate si apriva su `phase_started(&"imaging")`, cioè al MONTAGGIO della fase:
	# chi fosse salito in cupola mentre il pannello di configurazione era a schermo
	# avrebbe visto contare «sto a guardare la posa» senza nessuna posa in corso — e la
	# telemetria della 3.6 avrebbe misurato quel tempo come attesa vissuta.
	Events.sequence_started.connect(_on_sequence_started)
	Events.sequence_ended.connect(_on_sequence_ended)

	# Il Dwell Timer della soglia: one-shot, avviato quando il gate si apre. Il nodo
	# `Timer` conta col tempo scalato, così F1–F4 lo accelerano come il `BrewTimer` della
	# moka. La durata la fissa il codice (valore di rituale, non di layout).
	_dwell.one_shot = true
	_dwell.wait_time = DWELL_SECONDS
	_dwell.timeout.connect(_on_dwell_timeout)


## Il giocatore è entrato nella cupola. Solo il suo corpo conta (guardia `body is Player`):
## un altro corpo sul layer non aprirebbe il gate.
func _on_body_entered(body: Node3D) -> void:
	if not (body is Player):
		return
	_in_dome = true
	_reevaluate()


## Il giocatore è uscito dalla cupola.
func _on_body_exited(body: Node3D) -> void:
	if not (body is Player):
		return
	_in_dome = false
	_reevaluate()


## La sequenza è partita davvero (START premuto). Nessun filtro per chiave: il segnale
## porta già il fatto, e `&"imaging"` non compare più in questo file.
func _on_sequence_started() -> void:
	_seq_running = true
	_reevaluate()


## La sequenza è finita — conclusa, oppure smontata a metà (alba, *rifai setup*). Se si
## stava guardando, è uno dei due modi di smettere di «stare»: `_reevaluate()` emette
## `ended`. Il caso «smontata a metà» prima non arrivava affatto — `phase_finished` non
## viene emesso — e lasciava uno `started` senza il suo `ended` nella telemetria.
func _on_sequence_ended() -> void:
	_seq_running = false
	_reevaluate()


## Il cuore della coppia: chiamato a ogni cambio di `_in_dome`/`_seq_running`. Se il gate si
## apre e non si sta già guardando, (ri)avvia il `Dwell` — la permanenza riparte da zero a
## ogni riapertura (va e torna → nuovo `started` solo dopo la soglia). Se il gate si chiude,
## annulla il `Dwell` (una permanenza troppo breve, o una posa finita prima della soglia,
## non emette niente) ED emette `ended` se si stava guardando — uscita O fine sequenza,
## quale prima, sono qui lo stesso caso: un solo punto d'emissione, nessun doppio `ended`.
func _reevaluate() -> void:
	var gate_open := is_gate_open(_in_dome, _seq_running)
	if gate_open:
		if not _watching:
			# Riparte da zero a ogni apertura del gate: se il Dwell già girava (non
			# dovrebbe, il gate era chiuso) `start()` lo riavvia comunque.
			_dwell.start()
	else:
		_dwell.stop()
		if should_emit_ended(_watching, gate_open):
			Events.wait_activity_ended.emit(ACTIVITY)
			_watching = false


## La soglia di permanenza è scattata. Se il gate è ANCORA aperto (non si è usciti né la
## sequenza è finita nel frattempo) e non si sta già guardando, «stare a guardare» è
## diventato reale: emette `started` una sola volta. Se il gate si fosse chiuso prima, il
## `Dwell` è già stato fermato da `_reevaluate` e questo timeout non arriva.
func _on_dwell_timeout() -> void:
	var gate_open := is_gate_open(_in_dome, _seq_running)
	if should_emit_started(_watching, gate_open):
		Events.wait_activity_started.emit(ACTIVITY)
		_watching = true


## Il volume della cupola della scena, o `null` se non ce n'è. Stessa firma di
## `IndoorsVolume.find_in`.
static func find_in(tree: SceneTree) -> DomeActivity:
	return tree.get_first_node_in_group(GROUP) as DomeActivity
