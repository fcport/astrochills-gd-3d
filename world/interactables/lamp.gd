## La lampada che smette di lampeggiare: il registro SISTEMARE dell'attesa (storia 3.4),
## e il dimostratore completo di FR29 — lire → mondo che cambia. È l'attività «una tantum,
## comprata, permanente».
##
## PERCHÉ SEMPRE PRESENTE, A DIFFERENZA DELLA MOKA. La moka *compare* perché comprata; la
## lampada *c'è già* e va *sistemata*. Sono due registri diversi (FARE vs SISTEMARE) e due
## seam diversi: la moka legge il possesso per la PRESENZA, la lampada lo legge per
## l'INTERATTIVITÀ. Quindi la lampada c'è dalla prima notte — rotta, che lampeggia e ronza
## — e NON ascolta `item_purchased`: `can_interact()` rilegge `Game.profile.owns(&"lampadina")`
## a ogni tick (il raggio del giocatore ripolla il focus di continuo), e comprare la
## lampadina la rende cambiabile alla prossima occhiata, senza sottoscrizioni. Meno
## superficie della moka.
##
## PERCHÉ AUTONOMA, SENZA `main.gd`. Come la moka: la sua presenza e la sua interattività
## dipendono SOLO dal profilo del giocatore (`Game.profile`, autoload → `core/`) e il
## cambio è tutto interno. Vive nella scena e si cabla da sé in `_ready()`. Questo file non
## nomina le cartelle notte/fasi/terminale — dipende solo da `core`, `data` e autoload
## (`Game`, `Events`).
##
## LE TRANSIZIONI SONO PURE, IL RESTO È EFFETTO. Come `Moka.next_on_interact`, la tavola è
## statica e collaudabile senza SceneTree (`next_on_interact`, `is_interactive`,
## `prompt_for`, `starts_activity`). Il nodo mappa i marcatori started/ended sulle chiamate
## `Events.wait_activity_*`, guida timer/luce/suono, e persiste via `Game.mark_lamp_fixed()`;
## la funzione pura non tocca nulla di tutto ciò.
##
## NESSUN BONUS, e da nessuna parte scritto che potrebbe esisterne uno: la lampada
## sistemata non alza né abbassa alcun punteggio, non tocca `Game`/`NightRun`. È il registro
## SISTEMARE, e il suo unico contratto verso la telemetria è emettere onestamente la coppia
## `started`/`ended`.
class_name Lamp
extends Interactable

## L'articolo che rende la lampada CAMBIABILE (non presente: la lampada c'è comunque).
## Comprato al terminale (3.2), persistito nel save come possesso del GIOCATORE. Letto
## LIVE in `can_interact()`, senza sottoscrizione.
const BULB := &"lampadina"

## Il marcatore dell'attività per il condotto di misura (C4). La coppia
## `Events.wait_activity_started/ended(&"lampada")` racchiude il cambio; uno `started`
## senza `ended` (quit a metà) è un abbandono — un dato, non un buco.
const ACTIVITY := &"lampada"

## Chi ha bisogno della lampada la trova per GRUPPO, mai per percorso di nodo: stessa
## regola della moka, del letto e del monitor.
const GROUP := &"lampada"

## Gli stati della lampada. BROKEN → CHANGING lo avvia un'interazione (`E`); CHANGING →
## FIXED lo guida il `Timer` (il cambio reale, dura qualche secondo), non un'interazione.
enum State {
	BROKEN,    ## rotta: lampeggia e ronza. Cambiabile SOLO se si possiede la lampadina.
	CHANGING,  ## si sta cambiando: inerte, si aspetta il `Timer`. Luce/suono si spengono.
	FIXED,     ## cambiata: luce stabile, silenzio, inerte per sempre.
}

## Quanto dura il cambio: qualche secondo, percepibile — non un interruttore. Il `Timer`
## conta col tempo scalato, quindi F1–F4 lo accelerano. Tarabile guardando: verifica
## d'operatore, non un numero da stimare.
const CHANGE_SECONDS := 4.0

## Il ronzio sintetizzato del neon rotto: un tono grave in loop (onda quadra), come il
## borbottio della moka e il beep del terminale 3.2. Nessun asset d'arte (segnaposto,
## coerente con la memoria «asset provvisori»).
const HUM_HZ := 120
const SND_FRAMES := 4410            ## ~200 ms a 22050 Hz, in loop
const SND_MIX_RATE := 22050
const HUM_VOL_DB := -14.0

## L'illuminazione della cucina che la lampada fa: fioca e intermittente da rotta, piena e
## stabile da riparata. L'energia varia in `_process` (irregolare, tipo neon) attorno a
## questi estremi mentre lampeggia; a FIXED resta ferma su `ENERGY_STABLE`.
##
## I NUMERI SONO SCESI DI DUE VOLTE E MEZZO, e non è una regolazione a gusto: a 2,2
## questa lampadina su un bancone era più forte della plafoniera che le sta sopra
## (2,1), e con sei metri di portata e nessuna ombra illuminava la stanza accanto
## attraverso il muro. Portata e ombra le sistema `lamp.tscn`; qui si sistema
## l'energia, che il codice riscrive a ogni cambio di stato — cambiarla solo nella
## scena non avrebbe fatto niente, perché `_enter_fixed()` la sovrascrive.
const ENERGY_STABLE := 0.9
const ENERGY_FLICKER_MIN := 0.06
const ENERGY_FLICKER_MAX := 1.1

## Il neon rotto non lampeggia a ritmo fisso: sta acceso a scatti di durata variabile,
## poi crolla per un attimo. Questi sono gli estremi degli intervalli fra un cambio di
## livello e il successivo (in secondi di gioco, scalati da `Engine.time_scale`).
const FLICKER_HOLD_MIN := 0.04
const FLICKER_HOLD_MAX := 0.5

@onready var _light: OmniLight3D = $Light
@onready var _sound: AudioStreamPlayer3D = $Sound
@onready var _change_timer: Timer = $ChangeTimer

var _state: State = State.BROKEN

## Il conto alla rovescia del prossimo scatto del lampeggio (secondi di gioco). Quando
## arriva a zero si sceglie una nuova energia e un nuovo intervallo. NON è un conto alla
## rovescia mostrato al giocatore: è la meccanica interna del neon che sfarfalla.
var _flicker_left := 0.0


func _ready() -> void:
	add_to_group(GROUP)
	_install_hum_sound()

	# Il timer del cambio: one-shot, avviato all'ingresso in CHANGING. Il nodo `Timer`
	# conta col tempo scalato, così F1–F4 lo accelerano come il `_process` del lampeggio.
	# La durata la fissa il codice (non la scena) perché è un valore di rituale, non di
	# layout — stessa scelta del `BrewTimer` della moka.
	_change_timer.one_shot = true
	_change_timer.wait_time = CHANGE_SECONDS
	_change_timer.timeout.connect(_on_change_finished)

	# La propria `interacted`: ci si collega, non si sovrascrive `interact()` — così la
	# base resta l'unico punto che emette, e un domani un secondo ascoltatore si aggiunge
	# senza ricordarsi di `super()`. Stessa disciplina della moka.
	interacted.connect(_on_interacted)

	# NESSUNA sottoscrizione a `item_purchased`: l'interattività si rilegge live in
	# `can_interact()`. La lampada legge SOLO il flag di riparazione all'avvio, per nascere
	# già sistemata dopo il sonno/riavvio.
	if Game.profile.lamp_fixed:
		_enter_fixed()
	else:
		_enter_broken()


## Se adesso ci si può interagire. STRINGE la condizione della base (mai la allenta):
## oltre a `enabled`, la lampada è cambiabile SOLO da rotta E possedendo la lampadina —
## letta LIVE, senza sottoscrizione. Durante il cambio (CHANGING) e da sistemata (FIXED) è
## inerte.
func can_interact() -> bool:
	return super() and is_interactive(_state, Game.profile.owns(BULB))


# --- Logica pura del cambio: statica, senza SceneTree, collaudabile sul banco ---------
#
# È la tavola delle transizioni, gemella di `Moka.next_on_interact`. Il nodo la consulta e
# ci appende gli effetti (timer, luce, suono, telemetria, persistenza); la funzione non
# tocca nulla di tutto ciò.

## Lo stato successivo a un'interazione `E`. Solo BROKEN → CHANGING è una transizione da
## interazione (e solo se si possiede la lampadina, filtro che sta in `is_interactive`).
## CHANGING → FIXED NON è qui: lo guida il `Timer`, non un'interazione. CHANGING e FIXED
## restano fermi (inerti: là `is_interactive` è falso e l'interazione non arriva nemmeno).
static func next_on_interact(state: State) -> State:
	match state:
		State.BROKEN:
			return State.CHANGING   # + wait_activity_started(&"lampada"); il nodo avvia il Timer
		_:
			return state            # CHANGING/FIXED: inerte


## Se lo stato `state` risponde a un'interazione. Vero SOLO da BROKEN E possedendo la
## lampadina: senza la lampadina la lampada c'è ma non è cambiabile (nessun prompt, nessun
## invito a comprarla). `owns_bulb` è un PARAMETRO → la funzione resta pura e la gating
## con/senza lampadina è una riga di tabella sul banco, non uno SceneTree.
static func is_interactive(state: State, owns_bulb: bool) -> bool:
	return state == State.BROKEN and owns_bulb


## La riga che il giocatore legge guardando la lampada. In italiano, breve (lo legge il
## giocatore, non una macchina — NFR10). Solo BROKEN ha un prompt; CHANGING e FIXED no:
## durante il cambio non c'è niente da sollecitare, e da riparata non c'è più niente da
## fare. Il prompt compare comunque solo quando `can_interact()` è vero (lampadina
## posseduta): la stringa è la stessa, la visibilità la decide `can_interact`.
static func prompt_for(state: State) -> String:
	match state:
		State.BROKEN:
			return "Cambia la lampadina"
		_:
			return ""


## Se lo stato `state` è quello che AVVIA l'attività (l'inizio del cambio): è da qui che
## parte `wait_activity_started`. La fine (`ended`) la emette il `Timer`, non un'interazione,
## quindi non c'è un `ends_activity` puro — il punto d'emissione della fine è `_on_change_finished`.
static func starts_activity(state: State) -> bool:
	return state == State.BROKEN


# --- Il nodo: mappa i marcatori puri sugli effetti -----------------------------------

func prompt() -> String:
	return prompt_for(_state)


## Un'interazione è avvenuta (la base ha già filtrato su `can_interact()`, quindi qui siamo
## certi di essere in BROKEN e di possedere la lampadina). Si emette `started` PRIMA di
## cambiare stato — è definito sullo stato che si sta lasciando — poi si avanza e si accende
## il cambio.
func _on_interacted(_by: Node3D) -> void:
	if starts_activity(_state):
		Events.wait_activity_started.emit(ACTIVITY)

	var was_broken := _state == State.BROKEN
	_state = next_on_interact(_state)

	# BROKEN → CHANGING: parte il cambio reale. Il resto (CHANGING/FIXED) è inerte e non
	# arriva mai qui, perché `can_interact()` è già falso.
	if was_broken and _state == State.CHANGING:
		_start_changing()


## Inizio del cambio: la lampada diventa inerte. Il `Timer` conta il tempo del cambio;
## durante l'attesa la luce si spegne (si sta smontando la lampadina) e il ronzio tace.
## `can_interact()` è già falso (CHANGING), quindi il prompt sparisce da sé al prossimo
## tick del giocatore. `_process` si spegne qui: in CHANGING non c'è nulla da animare (la
## luce resta a 0 fino a `_on_change_finished` → `_enter_fixed`), e riaccenderlo per
## riscrivere 0 a ogni frame sarebbe lavoro morto.
func _start_changing() -> void:
	_change_timer.start()
	_sound.stop()
	set_process(false)
	_light.light_energy = 0.0


## Il cambio è concluso: la lampada passa a FIXED. È guidato da QUI (il `Timer`), non da
## un'interazione. Si emette `ended`, si stabilizza la luce, si tace il ronzio, e si
## PERSISTE la riparazione via `Game.mark_lamp_fixed()` (che salva). Se il save fallisce,
## `SaveManager` lo registra su canale 1 e lo stato in memoria resta FIXED — la stessa
## scelta di `spend_lire`.
func _on_change_finished() -> void:
	Events.wait_activity_ended.emit(ACTIVITY)
	_enter_fixed()
	Game.mark_lamp_fixed()


## Entra (o nasce) nello stato ROTTO: lampeggia e ronza. `_process` acceso per pilotare il
## lampeggio; il ronzio parte in loop. `enabled` resta vero — la cambiabilità la decide
## `can_interact()` sul possesso della lampadina.
func _enter_broken() -> void:
	_state = State.BROKEN
	set_process(true)
	# Un intervallo di tenuta iniziale POSITIVO: senza, col contatore a 0 il primo frame di
	# `_process` sceglierebbe subito una nuova energia casuale e l'energia MAX qui sotto non
	# si vedrebbe mai. Con la tenuta, l'accensione a piena luce ha il suo momento visibile
	# prima del primo scatto del neon.
	_flicker_left = randf_range(FLICKER_HOLD_MIN, FLICKER_HOLD_MAX)
	_light.light_energy = ENERGY_FLICKER_MAX
	if _sound.stream != null and ToniSegnaposto.continui():
		_sound.play()


## Entra (o nasce) nello stato SISTEMATO: luce stabile, `_process` spento, suono fermo,
## inerte per sempre. Ci si arriva da due strade — il cambio appena concluso
## (`_on_change_finished`), oppure la nascita da un profilo già `lamp_fixed` all'avvio, dopo
## il sonno/riavvio (`_ready`) — ma l'effetto sul nodo è identico, quindi non serve
## distinguerle qui. L'emissione di `ended` e la persistenza NON stanno qui: le fa
## `_on_change_finished`, così la nascita da riparata non riemette né risalva.
func _enter_fixed() -> void:
	_state = State.FIXED
	set_process(false)
	_sound.stop()
	_light.light_energy = ENERGY_STABLE


## Il lampeggio del neon rotto. Gira SOLO in BROKEN: `_start_changing` e `_enter_fixed`
## spengono `_process`, quindi CHANGING e FIXED non arrivano qui. `delta` è già scalato da
## `Engine.time_scale`, quindi F1–F4 accelerano il lampeggio come il `Timer` del cambio. In
## BROKEN sfarfalla a scatti di durata variabile, con energia irregolare — un neon guasto,
## non un seno pulito. Il ronzio pulsa col livello: più forte quando la luce è alta.
func _process(delta: float) -> void:
	# Guardia difensiva: se per qualche via `_process` girasse fuori da BROKEN, non tocca la
	# luce (che gli altri stati fissano da sé). In pratica non ci si arriva mai.
	if _state != State.BROKEN:
		return

	_flicker_left -= delta
	if _flicker_left > 0.0:
		return

	# Nuovo scatto: energia irregolare e un nuovo intervallo di tenuta. `randf_range` dà il
	# carattere «guasto» — livelli e tempi che non si ripetono uguali.
	var energy := randf_range(ENERGY_FLICKER_MIN, ENERGY_FLICKER_MAX)
	_light.light_energy = energy
	_flicker_left = randf_range(FLICKER_HOLD_MIN, FLICKER_HOLD_MAX)

	# Il ronzio pulsa col lampeggio: volume legato al livello di luce del momento. Resta
	# grave e non troppo forte — un fastidio ambientale, non un allarme.
	var t := inverse_lerp(ENERGY_FLICKER_MIN, ENERGY_FLICKER_MAX, energy)
	_sound.volume_db = lerpf(HUM_VOL_DB - 8.0, HUM_VOL_DB, t)


## Costruisce lo stream del ronzio in codice: nessun asset esterno (provvisorio, coerente
## con la memoria sugli asset e col beep del terminale). Un'onda quadra grave in loop — il
## ronzio di un neon, non una nota. Gemello di `Moka._install_brew_sound`.
func _install_hum_sound() -> void:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = SND_MIX_RATE
	wav.stereo = false
	# In loop: il ronzio dura finché la lampada è rotta, il campione ne dura una frazione.
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = SND_FRAMES
	var data := PackedByteArray()
	data.resize(SND_FRAMES)
	var period := SND_MIX_RATE / HUM_HZ        # onda quadra grave
	for i in SND_FRAMES:
		var high := (i % period) < (period / 2)
		var amp := 60.0
		var v := int(amp) if high else int(-amp)
		data[i] = (v + 256) % 256              # 8-bit signed → byte
	wav.data = data
	_sound.stream = wav
	_sound.volume_db = HUM_VOL_DB


## La lampada della scena, o `null` se non ce n'è. Stessa firma di `Moka.find_in`.
static func find_in(tree: SceneTree) -> Lamp:
	return tree.get_first_node_in_group(GROUP) as Lamp
