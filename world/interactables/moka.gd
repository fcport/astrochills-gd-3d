## La moka: il registro FARE dell'attesa, e la battuta tematica del gioco messa in
## meccanica — un'attesa piccola dentro l'attesa grande.
##
## PERCHÉ AUTONOMA, SENZA `main.gd`. Letto e monitor passano da `main.gd` perché il
## loro `enabled` dipende dallo stato della notte/fase, che solo `main.gd` vede. La
## moka no: la sua comparsa dipende SOLO dal possesso (`Game.profile`, autoload →
## `core/`) e il rituale è tutto interno. Quindi vive nella scena e si cabla da sé in
## `_ready()` — è la lettura letterale del seam scritto in `events.gd` («la moka
## nascerà ascoltando `item_purchased` e leggendo `Game.profile.owns(id)`»). Meno
## superficie, isolamento pulito: questo file non nomina le cartelle notte, fasi o
## terminale — dipende solo da `core`, `data` e autoload (`Game`, `Events`).
##
## LE TRANSIZIONI SONO PURE, IL RESTO È EFFETTO. Come `split_spend` in 3.2, la tavola
## del rituale è statica e collaudabile senza SceneTree (`next_on_interact`,
## `is_interactive`, `prompt_for`). Il nodo mappa i marcatori started/ended sulle
## chiamate `Events.wait_activity_*` e gestisce timer/suono; la funzione pura non tocca
## né l'uno né l'altro.
##
## NESSUN BONUS, e da nessuna parte scritto che potrebbe esisterne uno: un caffè fatto
## non alza né abbassa alcun punteggio, non tocca `Game`/`NightRun`. È l'attività del
## registro FARE, e il suo unico contratto verso la telemetria è emettere onestamente
## la coppia `started`/`ended`.
class_name Moka
extends Interactable

## L'articolo che fa comparire questa moka. Comprato al terminale (3.2), persistito nel
## save come possesso del GIOCATORE — la moka lo legge in sicurezza, `Game.profile`
## esiste prima della prima notte.
const ITEM := &"moka"

## Il marcatore dell'attività per il condotto di misura (C4). La coppia
## `Events.wait_activity_started/ended(&"caffe")` racchiude un rituale; un `started`
## senza `ended` è un abbandono, che è un dato, non un buco.
const ACTIVITY := &"caffe"

## Chi ha bisogno della moka la trova per GRUPPO, mai per percorso di nodo: stessa
## regola del letto e del monitor, e per la stessa ragione — un percorso si rompe al
## primo spostamento.
const GROUP := &"moka"

## I tempi del rituale. Ogni tempo è un'azione separata (`E`), tranne il passaggio
## BREWING → READY, che lo guida il `Timer` (l'attesa reale), non un'interazione.
enum Step {
	IDLE,     ## vuota sul piano: pronta da riempire
	FILLED,   ## riempita: pronta da mettere sul fuoco
	BREWING,  ## sul fuoco: si aspetta e si ascolta (inerte all'interazione)
	READY,    ## borbottata: pronta da versare
	POURED,   ## versata: pronta da bere
}

## Quanto dura l'attesa fra fuoco e pronto: decine di secondi, percepibili. Il `Timer`
## conta col tempo scalato, quindi gli strumenti F1–F4 la accelerano (fino a ×5 utile).
## Tarabile guardando/ascoltando: è una verifica d'operatore, non un numero da stimare.
const BREW_SECONDS := 40.0

## Il timbro del borbottio sintetizzato: un tono grave in loop, che sale durante
## l'attesa e alla fine dà un picco più forte. Nessun asset d'arte (segnaposto,
## coerente con la memoria «asset provvisori» e col beep del terminale 3.2).
const BREW_HZ := 90
const SND_FRAMES := 4410            ## ~200 ms a 22050 Hz, in loop
const SND_MIX_RATE := 22050

## Volume/pitch agli estremi dell'attesa: parte fioco e grave, arriva pieno e un filo
## più acuto. Il picco del borbottio finale è più forte ancora.
const VOL_START_DB := -30.0
const VOL_PEAK_DB := -6.0
const VOL_BURST_DB := 0.0
const PITCH_START := 0.85
const PITCH_PEAK := 1.15

@onready var _sound: AudioStreamPlayer3D = $Sound
@onready var _brew_timer: Timer = $BrewTimer

var _step: Step = Step.IDLE
var _rise: Tween


func _ready() -> void:
	add_to_group(GROUP)
	_install_brew_sound()

	# Il timer d'attesa: one-shot, avviato all'ingresso in BREWING. Il nodo `Timer`
	# conta col tempo scalato, così F1–F4 lo accelerano assieme al `Tween` del suono
	# e restano sincroni. La durata la fissa il codice (non la scena) perché è un
	# valore di rituale, non di layout.
	_brew_timer.one_shot = true
	_brew_timer.wait_time = BREW_SECONDS
	_brew_timer.timeout.connect(_on_brew_finished)

	# Il seam: la moka compare perché comprata. All'avvio legge il possesso; a runtime
	# ascolta l'annuncio del terminale (3.2). `dawn_reached` è connesso solo come gancio
	# previsto per 3.6/telemetria — NON resetta il rituale: «non scade niente» è un AC.
	Events.item_purchased.connect(_on_item_purchased)
	Events.dawn_reached.connect(_on_dawn_reached)

	# La propria `interacted`: ci si collega, non si sovrascrive `interact()` — così la
	# base resta l'unico punto che emette, e un domani un secondo ascoltatore (la
	# telemetria degli usi) si aggiunge senza ricordarsi di `super()`.
	interacted.connect(_on_interacted)

	_apply_presence(Game.profile.owns(ITEM))


## Se adesso ci si può interagire. STRINGE la condizione della base (mai la allenta):
## oltre a `enabled`, tace durante l'attesa (BREWING) — si aspetta e si ascolta, non si
## clicca. Da non-posseduta `enabled` è già falso (la moka nasce spenta e invisibile).
func can_interact() -> bool:
	return super() and is_interactive(_step)


# --- Logica pura del rituale: statica, senza SceneTree, collaudabile sul banco -------
#
# È la tavola delle transizioni, gemella di `Game.split_spend` in 3.2. Il nodo la
# consulta e ci appende gli effetti (timer, suono, telemetria); la funzione non tocca
# nulla di tutto ciò.

## Lo stato successivo a un'interazione `E`. BREWING resta BREWING (inerte: là
## `is_interactive` è falso e l'interazione non arriva nemmeno). BREWING → READY NON è
## qui: lo guida il `Timer`, non un'interazione.
static func next_on_interact(step: Step) -> Step:
	match step:
		Step.IDLE:
			return Step.FILLED   # + wait_activity_started(&"caffe")
		Step.FILLED:
			return Step.BREWING  # il nodo avvia timer + suono
		Step.READY:
			return Step.POURED
		Step.POURED:
			return Step.IDLE     # + wait_activity_ended(&"caffe")
		_:
			return Step.BREWING  # inerte


## Se il tempo `step` risponde a un'interazione. Falso SOLO in BREWING (si aspetta);
## vero in tutti gli altri.
static func is_interactive(step: Step) -> bool:
	return step != Step.BREWING


## La riga che il giocatore legge guardando la moka in un dato tempo. In italiano, breve
## (lo legge il giocatore, non una macchina — NFR10). BREWING non ha prompt: durante
## l'attesa non c'è niente da sollecitare.
static func prompt_for(step: Step) -> String:
	match step:
		Step.IDLE:
			return "Riempi la moka"
		Step.FILLED:
			return "Metti la moka sul fuoco"
		Step.READY:
			return "Versa il caffè"
		Step.POURED:
			return "Bevi il caffè"
		_:
			return ""


## Se il tempo `step` è il PRIMO (riempire): è qui che parte `wait_activity_started`.
static func starts_activity(step: Step) -> bool:
	return step == Step.IDLE


## Se il tempo `step` è l'ULTIMO (bere): è qui che parte `wait_activity_ended`.
static func ends_activity(step: Step) -> bool:
	return step == Step.POURED


# --- Il nodo: mappa i marcatori puri sugli effetti ----------------------------------

func prompt() -> String:
	return prompt_for(_step)


## Un'interazione è avvenuta (la base ha già filtrato su `can_interact()`). Si applicano
## i marcatori started/ended PRIMA di cambiare stato — sono definiti sul tempo che si
## sta lasciando — poi si avanza e si accendono gli effetti del tempo nuovo.
func _on_interacted(_by: Node3D) -> void:
	if starts_activity(_step):
		Events.wait_activity_started.emit(ACTIVITY)
	if ends_activity(_step):
		Events.wait_activity_ended.emit(ACTIVITY)

	var was_filled := _step == Step.FILLED
	_step = next_on_interact(_step)

	# FILLED → BREWING: parte l'attesa reale e il suono che sale. Il resto delle
	# transizioni è solo un cambio di prompt, che `prompt()` riflette da sé.
	if was_filled and _step == Step.BREWING:
		_start_brewing()


## Sul fuoco: avvia il timer d'attesa e il suono che sale. `can_interact()` è già falso
## (BREWING), quindi il prompt sparisce da sé al prossimo tick del giocatore.
func _start_brewing() -> void:
	# Sempre dal baseline fioco/grave PRIMA della salita: un rituale precedente puo'
	# aver lasciato volume/pitch a meta' se il burst finale e' stato interrotto.
	# Azzerare qui rende la salita del Tween deterministica — parte sempre dallo stesso
	# punto, invece di ereditare i livelli lasciati indietro.
	_reset_sound_levels()
	_brew_timer.start()
	_sound.play()
	if _rise != null and _rise.is_valid():
		_rise.kill()
	# Il `Tween` sale per la durata dell'attesa: «il suono sale». Segue `Engine.time_scale`
	# come il `Timer`, così restano sincroni fra loro e con F1–F4.
	_rise = create_tween()
	_rise.tween_property(_sound, "volume_db", VOL_PEAK_DB, BREW_SECONDS)
	_rise.parallel().tween_property(_sound, "pitch_scale", PITCH_PEAK, BREW_SECONDS)


## L'attesa è conclusa: borbotta (un picco più forte, breve) e passa a READY. BREWING →
## READY è guidato da QUI, non da un'interazione.
func _on_brew_finished() -> void:
	_step = Step.READY
	if _rise != null and _rise.is_valid():
		_rise.kill()
	# Il borbottio: un breve picco più forte, poi tace. Il suono torna al suo stato di
	# partenza per il prossimo rituale.
	var burst := create_tween()
	burst.tween_property(_sound, "volume_db", VOL_BURST_DB, 0.15)
	burst.tween_interval(0.35)
	burst.tween_callback(_sound.stop)
	burst.tween_callback(_reset_sound_levels)


## La moka compare perché comprata: a runtime, sull'annuncio del terminale. Un id
## diverso da `&"moka"` è ignorato.
func _on_item_purchased(id: StringName) -> void:
	if id != ITEM:
		return
	_apply_presence(true)


## Gancio previsto per 3.6/telemetria all'alba. NON resetta il rituale di proposito: un
## rituale lasciato a metà resta a metà (AC3), e uno portato oltre un sonno emette la
## coppia a cavallo del confine — sarà la finestra per-notte di 3.6 a ritagliarla.
func _on_dawn_reached() -> void:
	pass


## Accende o spegne la presenza della moka nel mondo. Spenta: invisibile, collisione
## disattivata, `enabled` falso → `can_interact()` falso, nessun prompt. Accesa: visibile,
## collisione attiva, stato IDLE, `enabled` vero. Idempotente: comprare due volte non
## interrompe un rituale in corso (si accende solo se non è già accesa).
func _apply_presence(present: bool) -> void:
	if present and enabled:
		return
	enabled = present
	visible = present
	# La collisione va spenta col nodo, non solo con `enabled`: da assente la moka non
	# deve nemmeno fermare il giocatore che passa dove non c'è ancora niente.
	$Collision.disabled = not present
	if present:
		_step = Step.IDLE


## Costruisce lo stream del borbottio in codice: nessun asset esterno (provvisorio,
## coerente con la memoria sugli asset e col beep del terminale). Un'onda quadra grave
## in loop — il gorgoglìo di una moka, non una nota.
func _install_brew_sound() -> void:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = SND_MIX_RATE
	wav.stereo = false
	# In loop: l'attesa dura decine di secondi, il campione ne dura una frazione. Il
	# `Tween` fa salire volume/pitch sopra il loop.
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = SND_FRAMES
	var data := PackedByteArray()
	data.resize(SND_FRAMES)
	var period := SND_MIX_RATE / BREW_HZ       # onda quadra grave
	for i in SND_FRAMES:
		var high := (i % period) < (period / 2)
		var amp := 70.0
		var v := int(amp) if high else int(-amp)
		data[i] = (v + 256) % 256              # 8-bit signed → byte
	wav.data = data
	_sound.stream = wav
	_reset_sound_levels()


## Riporta il suono al suo stato di partenza (fioco e grave), per il rituale successivo.
func _reset_sound_levels() -> void:
	_sound.volume_db = VOL_START_DB
	_sound.pitch_scale = PITCH_START


## La moka della scena, o `null` se non ce n'è.
static func find_in(tree: SceneTree) -> Moka:
	return tree.get_first_node_in_group(GROUP) as Moka
