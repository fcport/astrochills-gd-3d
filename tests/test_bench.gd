## Banco di collaudo. NESSUN FRAMEWORK (NFR19).
##
## Istanzia a mano le parti a logica pura e ne stampa il comportamento. Nessun
## addon, nessuna dipendenza, nessun setup: si apre la scena e si guarda l'output.
##
## IL LIMITE È DICHIARATO, non nascosto: un banco STAMPA, non asserisce. Nessuna
## regressione viene rilevata da sola, e ogni verifica resta un atto di lettura.
## Se un giorno non dovesse più bastare, GUT coprirebbe queste aree senza toccare
## una riga del codice di produzione — niente qui dentro ha bisogno di uno
## SceneTree. L'aritmetica della notte legge l'autoload `Tuning`, e non per
## comodità: è ciò che l'AC6 della 2.1 impone, ed è anche l'unico modo di
## collaudare i numeri con cui il gioco sta davvero girando, override compreso.
## Ma quel giorno non è oggi, e non si decide da soli.
##
## Aree previste dall'architettura: sorgenti di verità (qui), l'aritmetica della
## notte (qui dalla storia 2.1), aggregazione della qualità delle foto e
## migrazione del save — che non esistono ancora: arrivano più avanti nell'epica 2.
##
## SI COLLAUDANO I .tres, NON I DEFAULT DELLO SCRIPT. Il gioco carica le sorgenti
## dalle risorse, non con `.new()`: un `drift_rate = 0.0` battuto per sbaglio nel
## `.tres` rende la fase incompletabile e un banco che istanzia lo script
## stamperebbe comunque tutto pulito, perché starebbe collaudando numeri che il
## gioco non usa.
extends Node


const HONEST_PATH := "res://phases/polar/sources/honest_drift.tres"
const WANDERING_PATH := "res://phases/polar/sources/wandering_drift.tres"
const CATALOG_PATH := "res://phases/targeting/sources/honest_catalog.tres"
const SEQUENCE_PATH := "res://phases/imaging/sources/honest_sequence.tres"
const ROSTER_PATH := "res://data/clients/roster.tres"
const ITEM_CATALOG_PATH := "res://data/catalog/catalog.tres"
## La costante dell'orologio vero, non una copia: il banco confronta la propria
## aritmetica con quella del gioco, e per farlo deve leggere la stessa costante.
const CLOCK := preload("res://night/night_clock.gd")

## Ripetuta qui apposta, e CONFRONTATA con quella dell'orologio in
## `_check_night_clock()`: un banco che si limitasse a tenerne una copia
## collauderebbe in silenzio un'aritmetica che il gioco non usa più.
const NIGHT_START_HOUR := 21


## Carica la risorsa vera. Se manca lo dice invece di ripiegare in silenzio sui
## default: un banco che collauda un ripiego non collauda niente.
func _load_source(path: String) -> Resource:
	var r := load(path) as Resource
	if r == null:
		print("   %s NON CARICABILE  <-- il gioco userebbe questo file" % path)
	return r


func _ready() -> void:
	print("")
	print("=== BANCO DI COLLAUDO — Astrochill ===")
	print("")
	_check_honest_drift()
	print("")
	_check_wandering_drift()
	print("")
	_check_local_to_scene()
	print("")
	_check_honest_catalog()
	print("")
	_check_imaging_sequence()
	print("")
	_check_imaging_setup()
	print("")
	_check_night_clock()
	print("")
	_check_player_profile()
	print("")
	_check_save_manager()
	print("")
	_check_photo_quality()
	print("")
	_check_photo_schema()
	print("")
	_check_photo_record()
	print("")
	_check_payout()
	print("")
	_check_commission()
	print("")
	_check_sale()
	print("")
	_check_item_catalog()
	print("")
	_check_owned_items()
	print("")
	_check_spend()
	print("")
	_check_can_afford()
	print("")
	_check_moka_ritual()
	print("")
	_check_lamp_repair()
	print("")
	_check_dome_presence()
	print("")
	print("=== fine ===")
	get_tree().quit()


## La sorgente onesta deve essere una funzione pura dell'input: stesso input,
## stesso output, `delta` irrilevante. È ciò che permette alla fase di tenersi il
## proprio orologio, ed è la metà onesta della differenza che `F9` mette in scena.
func _check_honest_drift() -> void:
	print("-- HonestDrift: deve essere DETERMINISTICA")
	var src := _load_source(HONEST_PATH) as HonestDrift
	if src == null:
		return
	print("   dal .tres: drift_rate = %.4f" % src.drift_rate)

	var i := PolarInput.new()
	i.azimuth = 0.5
	i.altitude = -0.2
	i.seconds_since_correction = 3.0

	var a := src.sample(i, 0.016)
	var b := src.sample(i, 0.99)
	print("   sample(i, 0.016) = %s" % a)
	print("   sample(i, 0.99 ) = %s" % b)
	# is_equal_approx e non ==: con `==` un qualunque riordino dell'aritmetica
	# dentro sample() farebbe gridare al non determinismo una sorgente che
	# deterministica lo è, e su un banco che stampa e non asserisce il falso
	# allarme va poi diagnosticato a mano.
	print("   -> %s" % ("DETERMINISTICA" if a.is_equal_approx(b) else "NON deterministica  <-- ATTESO: deterministica"))

	var aligned := PolarInput.new()
	aligned.seconds_since_correction = 60.0
	print("   montatura allineata, dopo 60 s: %s (attesa: (0, 0))" % src.sample(aligned, 0.016))

	# Girando la vite verso lo zero la velocità deve CALARE, in modo monotono e
	# senza cambiare segno prima dello zero: è ciò che il giocatore vede mentre
	# tiene premuto, e se il segno fosse invertito il gioco insegnerebbe la
	# direzione sbagliata.
	#
	# Si guarda la COMPONENTE, non il modulo. `.length()` butta via il segno,
	# quindi una sorgente che restituisse l'opposto — il caso catastrofico che
	# questo commento nomina — stamperebbe esattamente le stesse righe.
	print("   girando la vite verso lo zero la velocità deve calare:")
	var g := PolarInput.new()
	var previous := INF
	for screw in [1.4, 1.0, 0.6, 0.2, 0.0]:
		g.azimuth = screw
		var vx: float = src.sample(g, 0.016).x
		var magnitude := absf(vx)
		var falls := magnitude < previous
		# Con vite positiva la deriva deve essere positiva: stesso segno, sempre.
		var signed_ok := is_zero_approx(screw) or signf(vx) == signf(screw)
		previous = magnitude
		var note := ""
		if not falls:
			note = "   <-- ATTESO: minore del precedente"
		elif not signed_ok:
			note = "   <-- SEGNO INVERTITO: la vite allontana invece di avvicinare"
		print("      vite %+.2f -> %+.4f arcmin/s%s" % [screw, vx, note])


## La sorgente bugiarda deve NON esserlo: si tiene il proprio tempo e ignora
## l'input. È la differenza che si vuole poter vedere.
func _check_wandering_drift() -> void:
	print("-- WanderingDrift: deve essere NON deterministica")
	var src := _load_source(WANDERING_PATH) as WanderingDrift
	if src == null:
		return
	print("   dal .tres: amplitude = %.4f" % src.amplitude)

	# Input identico, e volutamente irrilevante: la bugia non lo guarda.
	var i := PolarInput.new()
	i.azimuth = 0.5
	i.altitude = -0.2
	i.seconds_since_correction = 3.0

	var a := src.sample(i, 0.5)
	var b := src.sample(i, 0.5)
	print("   sample(i, 0.5) 1a volta = %s" % a)
	print("   sample(i, 0.5) 2a volta = %s" % b)
	print("   -> %s" % ("NON deterministica" if not a.is_equal_approx(b) else "deterministica  <-- ATTESO: non deterministica"))

	var zero := PolarInput.new()
	print("   con input a zero deriva lo stesso: %s (una montatura allineata che scivola)" % src.sample(zero, 0.5))


## Le Resource in Godot sono condivise per riferimento: senza questo, due fasi in
## scena riceverebbero la stessa istanza e la seconda erediterebbe la deriva
## accumulata dalla prima. È un bug che costa un pomeriggio e non si manifesta
## finché non ci sono due fasi insieme.
## L'ELENCO E' UNO SOLO, e sta qui. Il targeting era finito in un controllo
## inline dentro `_check_honest_catalog`, e il risultato erano due liste che
## potevano divergere: chi aggiungeva la settima sorgente guardava questa, non ci
## trovava il catalogo, e concludeva che non era la sede giusta. Ogni sorgente
## nuova si aggiunge QUI dentro e in nessun altro posto.
const SOURCE_PATHS := [
	"res://phases/polar/sources/honest_drift.tres",
	"res://phases/polar/sources/wandering_drift.tres",
	"res://phases/targeting/sources/honest_catalog.tres",
	"res://phases/targeting/sources/wandering_catalog.tres",
	"res://phases/imaging/sources/honest_sequence.tres",
]


func _check_local_to_scene() -> void:
	print("-- .tres delle sorgenti: resource_local_to_scene deve essere true")
	for path in SOURCE_PATHS:
		var r := load(path) as Resource
		if r == null:
			print("   %-22s NON CARICABILE" % path.get_file())
			continue
		var ok := r.resource_local_to_scene
		print("   %-22s resource_local_to_scene = %s%s" % [
			path.get_file(), ok, "" if ok else "   <-- ATTESO: true"])


## Il catalogo onesto del targeting: disponibilità corretta all'ora corrente,
## determinismo, e `resource_local_to_scene`. Si collauda il `.tres` che il gioco
## carica davvero, non i default dello script.
##
## LE ORE SI DANNO IN MINUTI NOTTE-RELATIVI, come `run.elapsed_min`: le 21:30
## sono 30, le 05:00 sono 480. È lo stesso conto che la sorgente fa sulle finestre
## dei target, e collaudarlo qui è collaudare che il wrap di mezzanotte regga.
func _check_honest_catalog() -> void:
	print("-- HonestCatalog: disponibilità all'ora corrente, DETERMINISTICA")

	# Prima di collaudare la disponibilità, si collauda che l'inizio notte sia LO
	# STESSO dell'orologio: una copia divergente calcolerebbe finestre che il gioco
	# non usa. Stessa disciplina della 2.1 per l'aritmetica della notte.
	if NIGHT_START_HOUR != HonestCatalog.NIGHT_START_HOUR:
		print("   NIGHT_START_HOUR: banco %d, sorgente %d  <-- ATTESO: uguali" % [
			NIGHT_START_HOUR, HonestCatalog.NIGHT_START_HOUR])
	if HonestCatalog.NIGHT_START_HOUR != CLOCK.NIGHT_START_HOUR:
		print("   NIGHT_START_HOUR: sorgente %d, orologio %d  <-- ATTESO: uguali" % [
			HonestCatalog.NIGHT_START_HOUR, CLOCK.NIGHT_START_HOUR])

	var src := _load_source(CATALOG_PATH) as HonestCatalog
	if src == null:
		return
	# `resource_local_to_scene` NON si verifica qui: la verifica una sola funzione,
	# su un solo elenco (`SOURCE_PATHS`). Vedi `_check_local_to_scene`.
	print("   dal .tres: %d target" % src.targets.size())
	if src.targets.size() != 6:
		print("   <-- ATTESO: 6 target di base")

	# I set attesi sono PINNATI: il banco non si limita a stampare la
	# disponibilità, la confronta con ciò che deve essere. Senza il confronto una
	# regressione sul wrap di mezzanotte o sul confine `<=` scorrerebbe via anche
	# sotto gli occhi di chi legge.
	#
	# 21:30 = 30 min: disponibili esattamente {M42, M45, M31, M8}.
	_assert_availability(src, 30.0, "21:30", PackedStringArray(["M42", "M45", "M31", "M8"]))
	# 05:00 = 480 min: disponibili esattamente {M13, M57, M31}. M31 ha finestra
	# fino alle 05:00 = 480, ed è il confine `480<=480` inclusivo — il punto più
	# facile da rompere.
	_assert_availability(src, 480.0, "05:00", PackedStringArray(["M13", "M57", "M31"]))
	# Il confine del wrap di mezzanotte per M8 (`vis_to = "00:00"` -> 180 min): a
	# 180 deve essere disponibile (confine inclusivo), a 181 no. È la coppia che
	# distingue `<=` da `<` proprio sul minuto che attraversa le 00:00.
	_assert_available_contains(src, 180.0, "00:00", &"M8", true)
	_assert_available_contains(src, 181.0, "00:01", &"M8", false)

	# Determinismo: stesso `now_min`, due chiamate, stessa lista/disponibilità.
	var i := TargetingInput.new()
	i.now_min = 30.0
	var a := src.sample(i)
	var b := src.sample(i)
	print("   determinismo a 21:30: %s" % (
		"DETERMINISTICA" if _same_availability(a, b) else "NON deterministica  <-- ATTESO: deterministica"))


## Stampa la disponibilità a `now_min` e la confronta con il set atteso di sigle
## disponibili. Un `<-- ATTESO {...}` compare solo quando il set effettivo diverge
## da quello pinnato — coerente con gli altri check del banco: si stampa sempre,
## si segnala solo lo scostamento.
func _assert_availability(
	src: HonestCatalog, now_min: float, label: String, expected: PackedStringArray
) -> void:
	var i := TargetingInput.new()
	i.now_min = now_min
	var rows := PackedStringArray()
	var actual := PackedStringArray()
	for entry in src.sample(i):
		var short: String = entry.get(&"short", "?")
		var avail: bool = entry.get(&"available", false)
		rows.append("%s=%s" % [short, "sì" if avail else "no"])
		if avail:
			actual.append(short)
	var note := ""
	if not _same_set(actual, expected):
		note = "   <-- ATTESO disponibili: {%s}" % ", ".join(expected)
	print("   alle %s (now_min %.0f): %s%s" % [label, now_min, ", ".join(rows), note])


## Confine puntuale: una sola sigla, disponibile o no a un preciso `now_min`.
## Serve per i minuti di frontiera (il wrap di mezzanotte), dove conta il singolo
## target e non l'intero set.
func _assert_available_contains(
	src: HonestCatalog, now_min: float, label: String, short: StringName, expected: bool
) -> void:
	var i := TargetingInput.new()
	i.now_min = now_min
	var found := false
	for entry in src.sample(i):
		if StringName(entry.get(&"short", "")) == short:
			found = entry.get(&"available", false)
			break
	var note := ""
	if found != expected:
		note = "   <-- ATTESO: %s = %s" % [short, "disponibile" if expected else "non disponibile"]
	print("   confine %s (now_min %.0f): %s = %s%s" % [
		label, now_min, short, "disponibile" if found else "non disponibile", note])


## Uguaglianza fra set di sigle, ordine irrilevante.
func _same_set(a: PackedStringArray, b: PackedStringArray) -> bool:
	if a.size() != b.size():
		return false
	for s in a:
		if not b.has(s):
			return false
	return true


func _same_availability(a: Array[Dictionary], b: Array[Dictionary]) -> bool:
	if a.size() != b.size():
		return false
	for k in a.size():
		if a[k].get(&"id") != b[k].get(&"id"):
			return false
		if a[k].get(&"available") != b[k].get(&"available"):
			return false
	return true


## La sorgente onesta dell'imaging: determinismo, monotonìa del conteggio frame,
## clamp a `frames_total`, e la guardia `min_per_frame <= 0`. Si collauda il `.tres`
## che il gioco carica davvero, non i default dello script.
##
## LOGICA PURA. Non c'è fase né SceneTree: si costruisce l'input a mano e si legge
## ciò che `sample()` restituisce. È esattamente ciò che la fase fa a ogni frame,
## meno l'orologio della notte — che qui si simula passando il tempo trascorso.
func _check_imaging_sequence() -> void:
	print("-- HonestSequence: conteggio frame dal tempo, DETERMINISTICO e monotono")
	var src := _load_source(SEQUENCE_PATH) as HonestSequence
	if src == null:
		return

	var mpf := 5.0
	var total := 20

	# Determinismo: stesso input, due chiamate, stesso stato.
	var i := ImagingInput.new()
	i.elapsed_since_start_min = 2.5 * mpf
	i.frames_total = total
	i.min_per_frame = mpf
	var a := src.sample(i)
	var b := src.sample(i)
	print("   a 2.5*min_per_frame: %s" % a)
	print("   -> %s" % (
		"DETERMINISTICA" if a == b else "NON deterministica  <-- ATTESO: deterministica"))
	# Frame in corso: 2.5 frame di tempo -> 2 acquisiti (floor), ancora in corso.
	if int(a.get(&"frames_done", -1)) != 2 or bool(a.get(&"done", true)):
		print("   <-- ATTESO: frames_done = 2, done = false")

	# Appena avviata: zero tempo -> zero frame, ma running.
	var start := _sample_at(src, 0.0, total, mpf)
	if int(start.get(&"frames_done", -1)) != 0 or not bool(start.get(&"running", false)):
		print("   a elapsed 0: %s  <-- ATTESO: frames_done = 0, running = true" % start)
	else:
		print("   a elapsed 0: frames_done = 0, running = true")

	# Monotonìa: il conteggio non scende mai col crescere del tempo, e clampa al
	# totale senza mai superarlo. Si campiona ben oltre la fine per provare il clamp.
	print("   monotonìa e clamp (min_per_frame = %.0f, frames_total = %d):" % [mpf, total])
	var previous := -1
	var monotonic := true
	var clamped := true
	for step in range(0, 26):
		var elapsed := float(step) * mpf
		var done := int(_sample_at(src, elapsed, total, mpf).get(&"frames_done", -1))
		if done < previous:
			monotonic = false
		if done > total:
			clamped = false
		previous = done
	# Alla fine esatta e oltre: sempre `total`, mai di più, e `done` vero.
	var at_end := _sample_at(src, float(total) * mpf, total, mpf)
	var past_end := _sample_at(src, float(total + 5) * mpf, total, mpf)
	print("      alla fine (elapsed = %d*mpf): %s" % [total, at_end])
	print("      oltre la fine (elapsed = %d*mpf): %s" % [total + 5, past_end])
	if not monotonic:
		print("      <-- ATTESO: il conteggio non deve mai calare")
	if not clamped or int(at_end.get(&"frames_done", -1)) != total or int(past_end.get(&"frames_done", -1)) != total:
		print("      <-- ATTESO: clamp a %d, mai oltre" % total)
	if not bool(at_end.get(&"done", false)) or not bool(past_end.get(&"done", false)):
		print("      <-- ATTESO: done = true a fine sequenza")

	# NOTA: la guardia `min_per_frame <= 0` (Tuning corrotto) NON si collauda qui.
	# È un canale 1 — un `push_error` — e questo banco lo legge il cancello
	# `.bmad-loop/verify.ps1`, che tratta OGNI riga d'errore come un guasto (è la sua
	# ragione d'essere). Pilotare il ramo corrotto stamperebbe un `USER ERROR` vero e
	# tingerebbe di rosso il cancello su codice giusto. I canali d'errore li provano
	# il cancello (sull'avvio del gioco) e l'occhio, non il banco — come per il
	# catalogo vuoto del targeting, che infatti nessun check qui esercita.


## Il target arriva dal `ctx` e sopravvive fino al readout (FR12/ADR-002).
##
## Si collauda il caso VALIDO: un target presente attraversa `setup()` ed emerge nel
## `_config_readout()` — la stessa strada che porta al payload verso 2.4/2.5. Senza
## SceneTree: `setup()` e `_config_readout()` non toccano né `_screen` né `truth`,
## bastano un'istanza nuda e una `NightRun`.
##
## Il ramo «ctx senza target_id» NON si prova qui: emette un `push_error` (canale 1),
## e vale la stessa ragione scritta sopra per `min_per_frame <= 0` — lo sorveglia il
## cancello, non il banco.
func _check_imaging_setup() -> void:
	print("-- PhaseImaging.setup(): il target del ctx arriva fino al readout")
	var run := NightRun.new()

	var with_target := PhaseImaging.new()
	with_target.setup(run, {&"target_id": &"m42"})
	var ro_ok := with_target._config_readout()
	print("   ctx con target_id = m42: readout.target = \"%s\"" % String(ro_ok.get(&"target", "")))
	if String(ro_ok.get(&"target", "")) != "m42":
		print("      <-- ATTESO: target = m42")
	with_target.free()

	# 2.6 — «scatta ancora → stessa configurazione»: `setup()` reidrata esposizione e
	# frame dal ctx quando ci sono, con `clampi` ai limiti dell'interfaccia; assenti,
	# restano i default. È logica pura e deterministica: si collauda qui, senza
	# SceneTree, sullo stesso modello del target sopra — istanzia, `setup`, legge
	# `_config_readout()`, libera.

	# 1) In range: i valori del ctx passano intatti fino al readout.
	var cfg := PhaseImaging.new()
	cfg.setup(run, {&"target_id": &"m42", &"exposure_sec": 300, &"frame_count": 40})
	var ro_cfg := cfg._config_readout()
	print("   ctx con esposizione 300 + frame 40: readout %d / %d" % [
		int(ro_cfg.get(&"exposure_sec", -1)), int(ro_cfg.get(&"frame_count", -1))])
	if int(ro_cfg.get(&"exposure_sec", -1)) != 300:
		print("      <-- ATTESO: exposure_sec = 300")
	if int(ro_cfg.get(&"frame_count", -1)) != 40:
		print("      <-- ATTESO: frame_count = 40")
	cfg.free()

	# 2) Fuori scala: `clampi` riporta ai massimi dell'interfaccia (EXPOSURE_MAX 600,
	# FRAMES_MAX 60), così un ctx malformato non li viola.
	var clamped := PhaseImaging.new()
	clamped.setup(run, {&"target_id": &"m42", &"exposure_sec": 9000, &"frame_count": 999})
	var ro_clamp := clamped._config_readout()
	print("   ctx fuori scala (9000 / 999): readout %d / %d  (max %d / %d)" % [
		int(ro_clamp.get(&"exposure_sec", -1)), int(ro_clamp.get(&"frame_count", -1)),
		PhaseImaging.EXPOSURE_MAX, PhaseImaging.FRAMES_MAX])
	if int(ro_clamp.get(&"exposure_sec", -1)) != PhaseImaging.EXPOSURE_MAX:
		print("      <-- ATTESO: exposure_sec = %d" % PhaseImaging.EXPOSURE_MAX)
	if int(ro_clamp.get(&"frame_count", -1)) != PhaseImaging.FRAMES_MAX:
		print("      <-- ATTESO: frame_count = %d" % PhaseImaging.FRAMES_MAX)
	clamped.free()

	# 3) Senza chiavi di config: i default restano (primo scatto). EXPOSURE_DEFAULT 120,
	# FRAMES_DEFAULT 20.
	var defaults := PhaseImaging.new()
	defaults.setup(run, {&"target_id": &"m42"})
	var ro_def := defaults._config_readout()
	print("   ctx senza config: readout %d / %d  (default %d / %d)" % [
		int(ro_def.get(&"exposure_sec", -1)), int(ro_def.get(&"frame_count", -1)),
		PhaseImaging.EXPOSURE_DEFAULT, PhaseImaging.FRAMES_DEFAULT])
	if int(ro_def.get(&"exposure_sec", -1)) != PhaseImaging.EXPOSURE_DEFAULT:
		print("      <-- ATTESO: exposure_sec = %d" % PhaseImaging.EXPOSURE_DEFAULT)
	if int(ro_def.get(&"frame_count", -1)) != PhaseImaging.FRAMES_DEFAULT:
		print("      <-- ATTESO: frame_count = %d" % PhaseImaging.FRAMES_DEFAULT)
	defaults.free()


## L'aggregazione della qualità della foto: media intera dei punteggi di fase, `0`
## sul dizionario vuoto. LOGICA PURA — `PhotoQuality.new()` senza SceneTree, come le
## sorgenti di verità.
##
## IL CASO CHE CONTA È QUELLO EREDITATO. `phase_scores` persiste fra gli scatti: se
## la 2.6 rifà solo l'imaging, polar e targeting restano col loro punteggio vecchio,
## e `aggregate` li conta. Non c'è un ramo dell'ereditarietà da collaudare — è la
## persistenza del dizionario — ma il banco stampa il comportamento su un dizionario
## «ereditato» perché è l'AC2 a chiederlo esplicitamente.
func _check_photo_quality() -> void:
	print("-- PhotoQuality.aggregate(): media intera dei punteggi, 0 su vuoto")
	var q := PhotoQuality.new()

	# Aggregazione tipica: (80+60+100)/3 = 80.
	_report_quality(q, {&"polar": 80, &"targeting": 60, &"imaging": 100}, 80,
		"tipico")
	# Ereditato: solo l'imaging rifatto (40); polar/targeting sono i punteggi VECCHI,
	# ancora nel dizionario perché persiste. (80+60+40)/3 = 60.
	_report_quality(q, {&"polar": 80, &"targeting": 60, &"imaging": 40}, 60,
		"ereditato — polar/targeting contano col punteggio precedente")
	# Fase sola: 80/1 = 80.
	_report_quality(q, {&"polar": 80}, 80, "una fase sola")
	# Vuoto: 0, nessuna divisione per zero.
	_report_quality(q, {}, 0, "nessun punteggio")


## Stampa `aggregate` sul caso e segnala lo scostamento con `<-- ATTESO`, come gli
## altri check del banco: si stampa sempre, si segnala solo la differenza.
func _report_quality(q: PhotoQuality, scores: Dictionary, expected: int, label: String) -> void:
	var got := q.aggregate(scores)
	var note := "" if got == expected else "   <-- ATTESO: %d" % expected
	print("   %-58s aggregate = %d%s" % [label, got, note])


## `Photo.is_photo()`: è il DATO nel ctx a dire se c'è una foto, non il nome di una
## fase. Servono esposizione E conteggio frame (li lascia l'imaging); il solo
## `target_id` — che lo lascia anche il targeting — non basta. Logica pura,
## statica: nessun nodo, nessun ctx reale, solo dizionari costruiti a mano.
func _check_photo_schema() -> void:
	print("-- Photo.is_photo(): esposizione + frame = foto; solo target = no")
	# Foto presente: il payload dell'imaging (I/O matrix, riga «foto presente»).
	_report_is_photo({&"target_id": &"m42", &"exposure_sec": 120, &"frame_count": 20}, true,
		"ctx con esposizione e frame")
	# Solo il target: il payload del targeting, nessuno scatto ancora.
	_report_is_photo({&"target_id": &"m42"}, false, "solo target_id (nessuno scatto)")
	# Ciclo vuoto: nessuna chiave (I/O matrix, riga «ciclo senza foto»).
	_report_is_photo({}, false, "ctx vuoto")


func _report_is_photo(ctx: Dictionary, expected: bool, label: String) -> void:
	var got := Photo.is_photo(ctx)
	var note := "" if got == expected else "   <-- ATTESO: %s" % expected
	print("   %-40s is_photo = %s%s" % [label, got, note])


## `Photo.from_ctx()`: costruisce il record foto — il contratto-dati verso la 2.5.
## Logica pura e statica: si passa un ctx, una qualità già aggregata e un indice, e
## si legge il `Dictionary` che ne esce. Le chiavi attese si leggono dalle costanti
## `Photo.KEY_*`, non da stringhe: se un giorno una chiave cambia, il banco cambia
## con essa invece di collaudare una vecchia forma.
func _check_photo_record() -> void:
	print("-- Photo.from_ctx(): il record verso la 2.5, target/esposizione/frame/qualità")

	# Ctx pieno: il payload dell'imaging con un bersaglio scelto. Ogni campo mappato.
	var full := Photo.from_ctx(
		{&"target_id": &"m42", &"exposure_sec": 120, &"frame_count": 20}, 80, 0)
	_report_record_field(full, Photo.KEY_TARGET, "m42", "ctx pieno: target")
	_report_record_field(full, Photo.KEY_EXPOSURE, 120, "ctx pieno: esposizione")
	_report_record_field(full, Photo.KEY_FRAMES, 20, "ctx pieno: frame")
	_report_record_field(full, Photo.KEY_QUALITY, 80, "ctx pieno: qualità")
	_report_record_field(full, Photo.KEY_ID, 0, "ctx pieno: id dall'indice")

	# DW-3: scatto senza bersaglio scelto. `target_id` NON è nel ctx; il record lo
	# registra come stringa VUOTA (non null, non assente) — un record ben formato.
	var no_target := Photo.from_ctx({&"exposure_sec": 60, &"frame_count": 5}, 50, 1)
	_report_record_field(no_target, Photo.KEY_TARGET, "", "DW-3 senza target: stringa vuota")
	_report_record_field(no_target, Photo.KEY_EXPOSURE, 60, "DW-3 senza target: esposizione")
	_report_record_field(no_target, Photo.KEY_FRAMES, 5, "DW-3 senza target: frame")
	_report_record_field(no_target, Photo.KEY_QUALITY, 50, "DW-3 senza target: qualità")
	_report_record_field(no_target, Photo.KEY_ID, 1, "DW-3 senza target: id dall'indice")


## Legge un campo del record e lo confronta con l'atteso. Come gli altri report del
## banco: si stampa sempre, si segnala solo lo scostamento con `<-- ATTESO`.
## `Variant` in ingresso: il record mescola stringhe e interi, e il confronto `==`
## regge entrambi.
func _report_record_field(record: Dictionary, key: StringName, expected: Variant, label: String) -> void:
	var got: Variant = record.get(key)
	var note := "" if got == expected else "   <-- ATTESO: %s" % str(expected)
	print("   %-40s %s = %s%s" % [label, key, str(got), note])


## `PhotoPayout`: la curva a scaglioni ai bordi, e l'arrotondamento del moltiplicatore.
## LOGICA PURA — `PhotoPayout.new()` senza SceneTree, come `PhotoQuality`.
##
## SI COLLAUDA LA CURVA DEL .tres, non i default dello script: `Tuning.payout_tiers`
## è ciò con cui il gioco vende davvero, override compreso. I bordi degli scaglioni
## (0/29/30/49/50/74/75/89/90/100) sono l'AC — l'ultimo scaglione superato vince — e
## l'arrotondamento (base 3500, ×0.6 → 2100, ×1.4 → 4900) è l'aritmetica dell'I/O matrix.
func _check_payout() -> void:
	print("-- PhotoPayout.tier_payout(): scaglione più alto raggiunto; 0 su curva vuota")
	var p := PhotoPayout.new()
	var tiers: Array = Tuning.payout_tiers
	print("   dal .tres: payout_tiers = %s" % str(tiers))

	# Bordi degli scaglioni con i valori segnaposto (500/1500/3500/7000/15000).
	_report_tier(p, tiers, 0, 500, "quality 0 → primo scaglione")
	_report_tier(p, tiers, 29, 500, "quality 29 → ancora il primo")
	_report_tier(p, tiers, 30, 1500, "quality 30 → secondo")
	_report_tier(p, tiers, 49, 1500, "quality 49 → ancora il secondo")
	_report_tier(p, tiers, 50, 3500, "quality 50 → terzo")
	_report_tier(p, tiers, 74, 3500, "quality 74 → ancora il terzo")
	_report_tier(p, tiers, 75, 7000, "quality 75 → quarto")
	_report_tier(p, tiers, 89, 7000, "quality 89 → ancora il quarto")
	_report_tier(p, tiers, 90, 15000, "quality 90 → quinto")
	_report_tier(p, tiers, 100, 15000, "quality 100 → ancora il quinto")
	# Curva vuota: 0, come `quality` su vuoto — non si inventa un numero.
	_report_tier(p, [], 80, 0, "curva vuota → 0")

	# L'arrotondamento del moltiplicatore (I/O matrix): base 3500.
	print("   -- apply_multiplier(): round(base * mult)")
	_report_mult(p, 3500, 0.6, 2100, "base 3500 × 0.6")
	_report_mult(p, 3500, 1.4, 4900, "base 3500 × 1.4")
	_report_mult(p, 3500, 1.0, 3500, "base 3500 × 1.0")


func _report_tier(p: PhotoPayout, tiers: Array, quality: int, expected: int, label: String) -> void:
	var got := p.tier_payout(quality, tiers)
	var note := "" if got == expected else "   <-- ATTESO: %d" % expected
	print("   %-40s lire = %d%s" % [label, got, note])


func _report_mult(p: PhotoPayout, base: int, mult: float, expected: int, label: String) -> void:
	var got := p.apply_multiplier(base, mult)
	var note := "" if got == expected else "   <-- ATTESO: %d" % expected
	print("   %-40s lire = %d%s" % [label, got, note])


## `Commission.choose()`: scelta DETERMINISTICA da `night_index`, esclusione di
## `privato_g`, roster vuoto → `{}`. LOGICA PURA e statica.
##
## SI CARICA IL ROSTER VERO (`_load_source`), non un array a mano: è il `.tres` con
## cui il gioco sceglie davvero, e `privato_g` è nel file ma disabilitato — la prova
## che non venga mai scelto vale solo sul dato reale.
func _check_commission() -> void:
	print("-- Commission.choose(): scelta deterministica su night_index, privato_g escluso")
	var roster := _load_source(ROSTER_PATH) as ClientRoster
	if roster == null:
		return
	var clients: Array = roster.clients
	print("   dal .tres: %d committenti (di cui abilitati: %s)" % [
		clients.size(), _enabled_names(clients)])

	# Tre abilitati (Coelum, Astrofili Marche, BBS Cygnus) in ordine; `privato_g`
	# disabilitato. La rotazione su `night_index`: 1→primo, 2→secondo, 3→terzo, 4→primo.
	_report_commission(clients, 1, "Coelum", "notte 1 → primo abilitato")
	_report_commission(clients, 2, "Astrofili Marche", "notte 2 → secondo")
	_report_commission(clients, 3, "BBS Cygnus", "notte 3 → terzo")
	_report_commission(clients, 4, "Coelum", "notte 4 → rotazione al primo")

	# `privato_g` non compare mai: lo si prova scorrendo abbastanza notti.
	var saw_privato := false
	for n in range(1, 9):
		var c := Commission.choose(clients, n)
		if String(c.get(Commission.CLIENT_NAME, "")) == "Privato G.":
			saw_privato = true
	var privato_note := "   <-- ATTESO: mai scelto" if saw_privato else ""
	print("   %-40s privato_g scelto = %s%s" % ["disabilitato escluso", saw_privato, privato_note])

	# Roster vuoto → `{}`: nessuna commessa applicabile, ogni vendita a base.
	var empty := Commission.choose([], 1)
	var empty_note := "" if empty.is_empty() else "   <-- ATTESO: {}"
	print("   %-40s choose([], 1) = %s%s" % ["roster vuoto → nessuna commessa", empty, empty_note])

	# Roster NON vuoto ma tutti disabilitati → `{}`. È un PERCORSO DIVERSO dal roster
	# vuoto: il filtro `enabled` produce una lista vuota, poi `is_empty()` scatta. La
	# riga «Roster assente/vuoto» dell'I/O matrix copre esplicitamente entrambi i casi.
	var d := ClientData.new()
	d.enabled = false
	d.name = "Disabled"
	var all_off := Commission.choose([d], 1)
	var all_off_note := "" if all_off.is_empty() else "   <-- ATTESO: {}"
	print("   %-40s choose([disabled], 1) = %s%s" % [
		"roster tutto disabilitato → nessuna commessa", all_off, all_off_note])


func _report_commission(clients: Array, night_index: int, expected_name: String, label: String) -> void:
	var c := Commission.choose(clients, night_index)
	var got := String(c.get(Commission.CLIENT_NAME, ""))
	var note := "" if got == expected_name else "   <-- ATTESO: %s" % expected_name
	print("   %-40s client = %s%s" % [label, got, note])


func _enabled_names(clients: Array) -> String:
	var names := PackedStringArray()
	for c in clients:
		if c != null and c.enabled:
			names.append(c.name)
	return ", ".join(names)


## Le QUATTRO righe di flusso della I/O matrix, provate sulla logica VERA — le stesse
## funzioni pure che l'orchestratore e la schermata di vendita chiamano, non una copia:
##
##   1. «Vendita senza commessa applicabile» → target foto ≠ commission.target → base
##   2. «Vendita con commessa, accettata» (FULFILL) → round(base*mult)
##   3. «Vendita con commessa, rifiutata» (SELL OPEN) → base
##   4. «Foto senza nome (DW-3)» → target_id vuoto → nessuna commessa applicabile → base
##
## `Commission.applies_to` decide se la commessa vale per QUESTA foto; `PhotoPayout.sale_lire`
## compone il payout dalla scelta FULFILL/SELL. Le chiavi dei dict vengono da
## `Commission.TARGET_ID`, non da stringhe sparse.
func _check_sale() -> void:
	print("-- Vendita (I/O matrix): applies_to + sale_lire, le 4 righe di flusso")
	var p := PhotoPayout.new()
	var comm := {Commission.TARGET_ID: &"m42", Commission.MULTIPLIER: 0.6}

	# Riga 1: la foto è m42, la commessa vuole m13 → non applicabile → base.
	var off_target := {Commission.TARGET_ID: &"m13", Commission.MULTIPLIER: 0.6}
	_report_applies(&"m42", off_target, false, "riga 1: target foto ≠ commessa")
	_report_sale(p, 3500, 0.6, false, 3500, "riga 1: non applicabile → base")

	# Riga 2: la foto è m42, la commessa vuole m42, FULFILL → round(base*mult).
	_report_applies(&"m42", comm, true, "riga 2/3: target foto = commessa")
	_report_sale(p, 3500, 0.6, true, 2100, "riga 2: FULFILL → round(3500*0.6)")

	# Riga 3: stessa commessa applicabile, ma SELL OPEN (rifiuto) → base ×1.0.
	_report_sale(p, 3500, 0.6, false, 3500, "riga 3: SELL OPEN → base")

	# Riga 4: foto senza nome (DW-3), target vuoto → mai applicabile → base.
	_report_applies(&"", comm, false, "riga 4: DW-3 target vuoto → non applicabile")
	_report_sale(p, 3500, 0.6, false, 3500, "riga 4: DW-3 → base")


func _report_applies(target_id: StringName, commission: Dictionary, expected: bool, label: String) -> void:
	var got := Commission.applies_to(target_id, commission)
	var note := "" if got == expected else "   <-- ATTESO: %s" % expected
	print("   %-42s applies_to = %s%s" % [label, got, note])


func _report_sale(p: PhotoPayout, base: int, mult: float, fulfill: bool, expected: int, label: String) -> void:
	var got := p.sale_lire(base, mult, fulfill)
	var note := "" if got == expected else "   <-- ATTESO: %d" % expected
	print("   %-42s lire = %d%s" % [label, got, note])


## Il filtro del catalogo (3.2): per categoria, SOLO gli implementati.
##
## SI CARICA IL CATALOGO VERO (`_load_source`), non un array a mano: è il `.tres` che il
## terminale legge davvero. moka e lampadina sono implementate; stufetta e
## lubrificare_cupola no — sono nel file apposta per provare che il filtro fa qualcosa.
## Se il filtro fosse rotto e mostrasse tutto, questo check lo stamperebbe.
func _check_item_catalog() -> void:
	print("-- ItemCatalog.for_category(): solo gli implementati per categoria (3.2)")
	var catalog := _load_source(ITEM_CATALOG_PATH) as ItemCatalog
	if catalog == null:
		return
	print("   dal .tres: %d articoli totali" % catalog.items.size())

	# PERSONAL: implementati = solo moka. stufetta è personal ma non implementata.
	_report_category(catalog, &"personal", PackedStringArray(["moka"]),
		"personal implementati")
	# FACILITIES: implementati = solo lampadina. lubrificare_cupola è facilities, no.
	_report_category(catalog, &"facilities", PackedStringArray(["lampadina"]),
		"facilities implementati")

	# Il filtro spento (only_implemented = false) DEVE dare di più: è la prova che il
	# filtro non è un no-op. personal senza filtro = moka + stufetta.
	var all_personal := catalog.for_category(&"personal", false)
	var impl_personal := catalog.for_category(&"personal", true)
	var filters := all_personal.size() > impl_personal.size()
	var fnote := "" if filters else "   <-- ATTESO: il filtro deve escludere i non implementati"
	print("   %-40s personal: tutti %d, implementati %d%s" % [
		"il filtro esclude davvero", all_personal.size(), impl_personal.size(), fnote])

	# Il prezzo della lampadina è 2000 lire (economia §6): dato nel .tres, non nel codice.
	var bulb := _first_with_id(catalog.for_category(&"facilities", true), &"lampadina")
	if bulb != null:
		var pnote := "" if bulb.price == 2000 else "   <-- ATTESO: 2000 (economia §6)"
		print("   %-40s lampadina price = %d%s" % ["prezzo lampadina dal .tres", bulb.price, pnote])
		# label EN, blurb IT (NFR10): la label è tutta maiuscole ASCII di software; il
		# blurb contiene testo — non si asserisce la lingua, si stampa perché si veda.
		print("   lampadina label EN = \"%s\", blurb IT (primi 40) = \"%s...\"" % [
			bulb.label, bulb.blurb.substr(0, 40)])


func _report_category(
	catalog: ItemCatalog, cat: StringName, expected_ids: PackedStringArray, label: String
) -> void:
	var got := PackedStringArray()
	for item in catalog.for_category(cat):
		got.append(String(item.id))
	var note := "" if _same_set(got, expected_ids) else "   <-- ATTESO: {%s}" % ", ".join(expected_ids)
	print("   %-40s ids = {%s}%s" % [label, ", ".join(got), note])


func _first_with_id(items: Array[ItemData], id: StringName) -> ItemData:
	for item in items:
		if item.id == id:
			return item
	return null


## `PlayerProfile.owns/mark_owned` e il round-trip del possesso sul save (3.2).
##
## Il possesso è del GIOCATORE (C1) come il portafoglio: attraversa le notti e il
## riavvio. Si collauda la logica pura (`owns`/`mark_owned`, idempotenza) e che
## `owned_items` sopravviva al giro su disco con `SaveManager` — senza SceneTree, come
## `_check_save_manager`. Il default `[]` non bumpa la versione: un profilo senza il
## campo torna «niente posseduto».
func _check_owned_items() -> void:
	print("-- PlayerProfile.owns/mark_owned + round-trip del possesso (3.2, C1)")

	var p := PlayerProfile.new()
	print("   il giocatore nasce senza niente: owns(moka) = %s" % p.owns(&"moka"))
	if p.owns(&"moka"):
		print("   <-- ATTESO: un profilo nuovo non possiede niente")

	p.mark_owned(&"moka")
	print("   dopo mark_owned(moka): owns(moka) = %s, owns(lampadina) = %s" % [
		p.owns(&"moka"), p.owns(&"lampadina")])
	if not p.owns(&"moka") or p.owns(&"lampadina"):
		print("   <-- ATTESO: possiede la moka, non la lampadina")

	# Idempotenza: comprare due volte non duplica.
	p.mark_owned(&"moka")
	var dup_note := "" if p.owned_items.size() == 1 else "   <-- ATTESO: mark_owned è idempotente"
	print("   mark_owned(moka) due volte: owned_items = %s%s" % [p.owned_items, dup_note])

	# Round-trip su disco: il possesso sopravvive al save/load, come il portafoglio. E con
	# lui `lamp_fixed` (3.4), per parita' col possesso: la riparazione della lampada e' del
	# GIOCATORE e attraversa il riavvio, esattamente come `owned_items`.
	var bench_dir := "user://saves/_bench_items"
	var path := "%s/profile.tres" % bench_dir
	DirAccess.make_dir_recursive_absolute(bench_dir)
	var saves := SaveManager.new()
	p.mark_owned(&"lampadina")
	p.wallet_lire = 3000
	p.lamp_fixed = true
	saves.save_profile(p, path)
	var back := saves.load_profile(path)
	var round_ok := back.owns(&"moka") and back.owns(&"lampadina") and back.wallet_lire == 3000 and back.lamp_fixed
	print("   round-trip: owns(moka)=%s owns(lampadina)=%s wallet=%d lamp_fixed=%s" % [
		back.owns(&"moka"), back.owns(&"lampadina"), back.wallet_lire, back.lamp_fixed])
	if not round_ok:
		print("   <-- ATTESO: possesso, portafoglio e lamp_fixed sopravvivono al .tres")

	# Un profilo SENZA i campi (default [] / false) è «niente posseduto, lampada non
	# riparata», non un errore.
	var fresh := PlayerProfile.new()
	print("   default: owned_items vuoto = %s, lamp_fixed = %s (assente = stato iniziale)" % [
		fresh.owned_items.is_empty(), fresh.lamp_fixed])
	if not fresh.owned_items.is_empty() or fresh.lamp_fixed:
		print("   <-- ATTESO: default [] / false — nessun bump di versione")

	# Ripulire.
	var d := DirAccess.open(bench_dir)
	if d != null:
		d.list_dir_begin()
		var name := d.get_next()
		while not name.is_empty():
			if not d.current_is_dir():
				DirAccess.remove_absolute(bench_dir.path_join(name))
			name = d.get_next()
		d.list_dir_end()
	DirAccess.remove_absolute(bench_dir)


## L'aritmetica della spesa (3.2): earnings-prima-poi-wallet, e `wallet_now` cala esatto.
##
## `Game.split_spend` è PURA e STATICA — si collauda senza toccare l'autoload `Game`,
## come le sorgenti di verità. Il modello: `wallet_now = wallet_lire + night_earnings`;
## la spesa deduce prima da `night_earnings` (fino a 0), il resto da `wallet_lire`, così
## entrambi restano ≥ 0 e la somma cala esatto. Qui si simula il travaso a mano sui due
## contatori e si verifica che rispecchi lo split.
func _check_spend() -> void:
	print("-- Game.split_spend(): earnings-prima-poi-wallet, wallet_now cala esatto (3.2)")

	# (1) Tutto dalla presa della notte: amount <= night_earnings → niente dal wallet.
	_report_split(500, 2000, 500, 0, "500 su presa 2000: tutto dalla presa")
	# (2) Presa a zero: la presa cala a 0, il resto dal wallet.
	_report_split(3000, 2000, 2000, 1000, "3000 su presa 2000: 2000 presa + 1000 wallet")
	# (3) Nessuna presa (notte non versante): tutto dal wallet.
	_report_split(1500, 0, 0, 1500, "1500 su presa 0: tutto dal wallet")
	# (4) Esatto: amount == night_earnings → presa svuotata, wallet intatto.
	_report_split(2000, 2000, 2000, 0, "2000 su presa 2000: presa svuotata")

	# La somma cala ESATTO: simulando il travaso, wallet_now = wallet_lire + earnings
	# scende di `amount`. Si prende il caso (2), che tocca entrambi i contatori.
	var wallet_lire := 5000
	var night_earnings := 2000
	var before := wallet_lire + night_earnings
	var amount := 3000
	var split := Game.split_spend(amount, night_earnings)
	night_earnings -= split[0]
	wallet_lire -= split[1]
	var after := wallet_lire + night_earnings
	var exact := (before - after) == amount and night_earnings >= 0 and wallet_lire >= 0
	print("   wallet_now: prima %d, speso %d, dopo %d (presa %d, wallet %d)" % [
		before, amount, after, night_earnings, wallet_lire])
	if not exact:
		print("   <-- ATTESO: wallet_now cala esatto di %d, entrambi ≥ 0" % amount)


func _report_split(amount: int, earnings: int, exp_e: int, exp_w: int, label: String) -> void:
	var split := Game.split_spend(amount, earnings)
	var ok := split[0] == exp_e and split[1] == exp_w
	var note := "" if ok else "   <-- ATTESO: presa %d, wallet %d" % [exp_e, exp_w]
	print("   %-42s presa %d, wallet %d%s" % [label, split[0], split[1], note])


## `Game.can_afford()`: la soglia di spesa È `wallet_now()`, né più né meno (3.2).
##
## Si collauda sull'autoload VERO, montando uno stato temporaneo su `Game.run`/
## `Game.profile` e ripristinandolo subito. NESSUN EFFETTO SU DISCO: `can_afford` è una
## lettura pura (`wallet_now() >= amount`), non salva niente — a differenza di
## `spend_lire`, che scrive sui path di save reali e per questo non si esercita qui.
func _check_can_afford() -> void:
	print("-- Game.can_afford(): la soglia di spesa = wallet_now (3.2)")
	var saved_run := Game.run
	var saved_profile := Game.profile
	var r := NightRun.new()
	r.night_earnings = 2000
	var p := PlayerProfile.new()
	p.wallet_lire = 500
	Game.run = r
	Game.profile = p
	# wallet_now = wallet_lire 500 + night_earnings 2000 = 2500.
	_report_afford(2500, true, "esatto: 2500 su 2500")
	_report_afford(2501, false, "uno in piu': 2501 su 2500")
	_report_afford(0, true, "zero e' sempre affordabile")
	Game.run = saved_run
	Game.profile = saved_profile


func _report_afford(amount: int, expected: bool, label: String) -> void:
	var got := Game.can_afford(amount)
	var note := "" if got == expected else "   <-- ATTESO: %s" % expected
	print("   %-42s can_afford(%d) = %s%s" % [label, amount, got, note])


## Il rituale della moka (3.3): la logica PURA e STATICA — transizioni, interattivita' per
## tempo, prompt, e i punti d'emissione della coppia started/ended. Gemella di
## `Game.split_spend`: nessuno SceneTree, nessun autoload, nessun timer/suono.
##
## Il timer d'attesa, il suono che sale/borbotta e la raggiungibilita' del volume di
## collisione NON si collaudano qui: sono effetti e percezione — verifiche d'operatore,
## che si camminano nel gioco (come dice lo spec). Il banco legge la tavola.
func _check_moka_ritual() -> void:
	print("-- Moka: rituale a piu' tempi, transizioni pure + punti d'emissione (3.3)")

	# La tavola delle transizioni `E`. BREWING → READY NON e' qui: lo guida il Timer,
	# non un'interazione — e BREWING → BREWING e' inerte (li' `is_interactive` e' falso).
	_report_moka_next(Moka.Step.IDLE, Moka.Step.FILLED, "IDLE + E -> FILLED (riempi)")
	_report_moka_next(Moka.Step.FILLED, Moka.Step.BREWING, "FILLED + E -> BREWING (sul fuoco)")
	_report_moka_next(Moka.Step.BREWING, Moka.Step.BREWING, "BREWING + E -> BREWING (inerte)")
	_report_moka_next(Moka.Step.READY, Moka.Step.POURED, "READY + E -> POURED (versa)")
	_report_moka_next(Moka.Step.POURED, Moka.Step.IDLE, "POURED + E -> IDLE (bevi, ripetibile)")

	# Interattivita' per tempo: falso SOLO in BREWING (si aspetta e si ascolta), vero
	# altrove. E' la condizione che `can_interact()` STRINGE sopra la base.
	print("   -- is_interactive: falso solo in BREWING")
	_report_moka_interactive(Moka.Step.IDLE, true, "IDLE interagibile")
	_report_moka_interactive(Moka.Step.FILLED, true, "FILLED interagibile")
	_report_moka_interactive(Moka.Step.BREWING, false, "BREWING inerte")
	_report_moka_interactive(Moka.Step.READY, true, "READY interagibile")
	_report_moka_interactive(Moka.Step.POURED, true, "POURED interagibile")

	# Prompt per tempo (IT, lo legge il giocatore — NFR10). BREWING non ha prompt:
	# durante l'attesa non c'e' niente da sollecitare (nessun conto alla rovescia).
	print("   -- prompt per tempo")
	_report_moka_prompt(Moka.Step.IDLE, "Riempi la moka")
	_report_moka_prompt(Moka.Step.FILLED, "Metti la moka sul fuoco")
	_report_moka_prompt(Moka.Step.BREWING, "")
	_report_moka_prompt(Moka.Step.READY, "Versa il caffè")
	_report_moka_prompt(Moka.Step.POURED, "Bevi il caffè")

	# I punti d'emissione della coppia (C4): started al PRIMO tempo (riempire, cioe' da
	# IDLE), ended all'ULTIMO (bere, cioe' da POURED). Nessun altro tempo emette.
	print("   -- punti d'emissione: started al 1o tempo (IDLE), ended all'ultimo (POURED)")
	var all_steps: Array[Moka.Step] = [
		Moka.Step.IDLE, Moka.Step.FILLED, Moka.Step.BREWING, Moka.Step.READY, Moka.Step.POURED]
	for step in all_steps:
		var starts := Moka.starts_activity(step)
		var ends := Moka.ends_activity(step)
		var exp_start: bool = step == Moka.Step.IDLE
		var exp_end: bool = step == Moka.Step.POURED
		var note := ""
		if starts != exp_start:
			note = "   <-- ATTESO started = %s" % exp_start
		elif ends != exp_end:
			note = "   <-- ATTESO ended = %s" % exp_end
		print("      %-10s started=%s ended=%s%s" % [_moka_step_name(step), starts, ends, note])

	# Il giro completo, e la sua ripetibilita': IDLE →(E)→ FILLED →(E)→ BREWING →(Timer)→
	# READY →(E)→ POURED →(E)→ IDLE. Si simula la mano (le `E`) e il Timer (BREWING→READY)
	# a mano, e si verifica che si torni a IDLE — pronta per rifarlo.
	var s := Moka.Step.IDLE
	s = Moka.next_on_interact(s)          # riempi
	s = Moka.next_on_interact(s)          # sul fuoco
	if s == Moka.Step.BREWING:
		s = Moka.Step.READY               # il Timer, non un'interazione
	s = Moka.next_on_interact(s)          # versa
	s = Moka.next_on_interact(s)          # bevi
	var loop_note := "" if s == Moka.Step.IDLE else "   <-- ATTESO: torna a IDLE (ripetibile)"
	print("   giro completo torna a IDLE: %s%s" % [_moka_step_name(s), loop_note])


func _report_moka_next(step: Moka.Step, expected: Moka.Step, label: String) -> void:
	var got := Moka.next_on_interact(step)
	var note := "" if got == expected else "   <-- ATTESO: %s" % _moka_step_name(expected)
	print("   %-42s -> %s%s" % [label, _moka_step_name(got), note])


func _report_moka_interactive(step: Moka.Step, expected: bool, label: String) -> void:
	var got := Moka.is_interactive(step)
	var note := "" if got == expected else "   <-- ATTESO: %s" % expected
	print("      %-38s is_interactive = %s%s" % [label, got, note])


func _report_moka_prompt(step: Moka.Step, expected: String) -> void:
	var got := Moka.prompt_for(step)
	var note := "" if got == expected else "   <-- ATTESO: \"%s\"" % expected
	print("      %-10s prompt = \"%s\"%s" % [_moka_step_name(step), got, note])


func _moka_step_name(step: Moka.Step) -> String:
	match step:
		Moka.Step.IDLE: return "IDLE"
		Moka.Step.FILLED: return "FILLED"
		Moka.Step.BREWING: return "BREWING"
		Moka.Step.READY: return "READY"
		Moka.Step.POURED: return "POURED"
		_: return "?"


## La riparazione della lampada (3.4): la logica PURA e STATICA — transizioni,
## interattivita' gated sul possesso della lampadina, prompt, e il punto d'emissione di
## `started`. Gemella di `_check_moka_ritual`: nessuno SceneTree, nessun autoload, nessun
## timer/luce/suono.
##
## Il timer del cambio, il lampeggio+ronzio, la persistenza runtime di `lamp_fixed` e la
## raggiungibilita' del volume di collisione NON si collaudano qui: sono effetti e
## percezione — verifiche d'operatore, che si camminano nel gioco (come dice lo spec). Il
## round-trip di `lamp_fixed` sul .tres sta in `_check_owned_items`, per parita' col
## possesso. Il banco legge la tavola.
func _check_lamp_repair() -> void:
	print("-- Lampada: cambio a stati, transizioni pure + gating sul possesso (3.4)")

	# La tavola delle transizioni `E`. Solo BROKEN → CHANGING e' una transizione da
	# interazione; CHANGING/FIXED restano fermi (inerti: la' `is_interactive` e' falso e
	# l'interazione non arriva nemmeno). CHANGING → FIXED NON e' qui: lo guida il Timer.
	_report_lamp_next(Lamp.State.BROKEN, Lamp.State.CHANGING, "BROKEN + E -> CHANGING (cambia)")
	_report_lamp_next(Lamp.State.CHANGING, Lamp.State.CHANGING, "CHANGING + E -> CHANGING (inerte)")
	_report_lamp_next(Lamp.State.FIXED, Lamp.State.FIXED, "FIXED + E -> FIXED (inerte)")

	# Interattivita' per stato E possesso: la gating con/senza lampadina e' l'AC centrale
	# della 3.4, e qui e' una riga di tabella perche' `is_interactive` prende `owns_bulb`
	# come parametro (resta pura). Vero SOLO da BROKEN E possedendo la lampadina.
	print("   -- is_interactive(state, owns_bulb): vero solo BROKEN + lampadina")
	_report_lamp_interactive(Lamp.State.BROKEN, false, false, "BROKEN senza lampadina: inerte (nessun invito a comprarla)")
	_report_lamp_interactive(Lamp.State.BROKEN, true, true, "BROKEN con lampadina: cambiabile")
	_report_lamp_interactive(Lamp.State.CHANGING, true, false, "CHANGING con lampadina: inerte (si aspetta il Timer)")
	_report_lamp_interactive(Lamp.State.FIXED, true, false, "FIXED con lampadina: inerte per sempre")

	# Prompt per stato (IT, lo legge il giocatore — NFR10). Solo BROKEN ha un prompt;
	# CHANGING/FIXED no. Il prompt compare comunque solo quando `can_interact()` e' vero.
	print("   -- prompt per stato")
	_report_lamp_prompt(Lamp.State.BROKEN, "Cambia la lampadina")
	_report_lamp_prompt(Lamp.State.CHANGING, "")
	_report_lamp_prompt(Lamp.State.FIXED, "")

	# Il punto d'emissione di `started` (C4): SOLO da BROKEN, cioe' all'inizio del cambio.
	# La fine (`ended`) la emette il Timer, non un'interazione — la sua sede e'
	# `_on_change_finished`, non una funzione pura, quindi qui si collauda solo `started`.
	print("   -- punto d'emissione: started SOLO da BROKEN (inizio cambio)")
	var all_states: Array[Lamp.State] = [Lamp.State.BROKEN, Lamp.State.CHANGING, Lamp.State.FIXED]
	for state in all_states:
		var starts := Lamp.starts_activity(state)
		var exp_start: bool = state == Lamp.State.BROKEN
		var note := "" if starts == exp_start else "   <-- ATTESO started = %s" % exp_start
		print("      %-10s started=%s%s" % [_lamp_state_name(state), starts, note])


func _report_lamp_next(state: Lamp.State, expected: Lamp.State, label: String) -> void:
	var got := Lamp.next_on_interact(state)
	var note := "" if got == expected else "   <-- ATTESO: %s" % _lamp_state_name(expected)
	print("   %-42s -> %s%s" % [label, _lamp_state_name(got), note])


func _report_lamp_interactive(state: Lamp.State, owns_bulb: bool, expected: bool, label: String) -> void:
	var got := Lamp.is_interactive(state, owns_bulb)
	var note := "" if got == expected else "   <-- ATTESO: %s" % expected
	print("      %-54s is_interactive = %s%s" % [label, got, note])


func _report_lamp_prompt(state: Lamp.State, expected: String) -> void:
	var got := Lamp.prompt_for(state)
	var note := "" if got == expected else "   <-- ATTESO: \"%s\"" % expected
	print("      %-10s prompt = \"%s\"%s" % [_lamp_state_name(state), got, note])


func _lamp_state_name(state: Lamp.State) -> String:
	match state:
		Lamp.State.BROKEN: return "BROKEN"
		Lamp.State.CHANGING: return "CHANGING"
		Lamp.State.FIXED: return "FIXED"
		_: return "?"


## Lo «stare a guardare» della cupola (3.5): la logica PURA e STATICA di `DomeActivity` —
## il gate (in cupola E posa in corso), i punti d'emissione della coppia started/ended, e
## il filtro sulla sequenza. Gemella di `_check_moka_ritual`/`_check_lamp_repair`: nessuno
## SceneTree, nessun autoload, nessun timer.
##
## Il moto del telescopio, i suoni (ronzio, cigolio), il dwell timer runtime e la
## raggiungibilita'/collisione NON si collaudano qui: sono resa, effetto e percezione —
## verifiche d'operatore, che si camminano nel gioco (come dice lo spec). Il banco legge
## la tavola delle decisioni.
func _check_dome_presence() -> void:
	print("-- Cupola: gate del «stare a guardare», coppia started/ended, filtro sequenza (3.5)")

	# is_gate_open: vero SOLO con ENTRAMBE le condizioni (in cupola E posa in corso). E'
	# la condizione perche' la permanenza abbia senso di essere contata.
	print("   -- is_gate_open(in_dome, seq_running): vero solo con entrambe")
	_report_gate(false, false, false, "fuori, nessuna posa")
	_report_gate(true, false, false, "in cupola, nessuna posa (solo passare di li')")
	_report_gate(false, true, false, "posa in corso ma fuori dalla cupola")
	_report_gate(true, true, true, "in cupola CON posa in corso: gate aperto")

	# should_emit_started (valutato al timeout del Dwell): only se NON si sta gia'
	# guardando E il gate e' aperto. Una permanenza troppo breve, o una posa finita prima
	# della soglia, chiude il gate prima del timeout e non arriva qui.
	print("   -- should_emit_started(watching, gate_open): not watching AND gate")
	_report_started(false, true, true, "non attivo + gate aperto: emette started")
	_report_started(true, true, false, "gia' attivo + gate aperto: niente (una sola volta)")
	_report_started(false, false, false, "non attivo + gate chiuso: niente (soglia caduta)")
	_report_started(true, false, false, "gia' attivo + gate chiuso: niente (lo chiude ended)")

	# should_emit_ended (valutato quando una condizione cade): solo se si STA guardando E
	# il gate si e' chiuso. Uscita dalla cupola O fine sequenza — entrambe chiudono il
	# gate, quindi sono lo stesso caso: un solo `ended`, nessun doppio.
	print("   -- should_emit_ended(watching, gate_open): watching AND not gate")
	_report_ended(true, false, true, "attivo + gate chiuso (uscito O posa finita): emette ended")
	_report_ended(true, true, false, "attivo + gate ancora aperto: niente")
	_report_ended(false, false, false, "non attivo + gate chiuso: niente (mai partito)")
	_report_ended(false, true, false, "non attivo + gate aperto: niente")

	# affects_sequence: SOLO l'imaging apre/chiude questo gate. La polare e il targeting
	# emettono lo stesso segnale con la propria chiave e passano senza toccarlo — stessa
	# soft-coupling via StringName di sequence_chime.gd e del telescopio.
	print("   -- affects_sequence(key): vero solo su &\"imaging\"")
	_report_affects(&"imaging", true, "imaging: riguarda la cupola")
	_report_affects(&"polar", false, "polar: passa senza aprire il gate")
	_report_affects(&"targeting", false, "targeting: passa senza aprire il gate")


func _report_gate(in_dome: bool, seq_running: bool, expected: bool, label: String) -> void:
	var got := DomeActivity.is_gate_open(in_dome, seq_running)
	var note := "" if got == expected else "   <-- ATTESO: %s" % expected
	print("      %-46s gate = %s%s" % [label, got, note])


func _report_started(watching: bool, gate_open: bool, expected: bool, label: String) -> void:
	var got := DomeActivity.should_emit_started(watching, gate_open)
	var note := "" if got == expected else "   <-- ATTESO: %s" % expected
	print("      %-46s started = %s%s" % [label, got, note])


func _report_ended(watching: bool, gate_open: bool, expected: bool, label: String) -> void:
	var got := DomeActivity.should_emit_ended(watching, gate_open)
	var note := "" if got == expected else "   <-- ATTESO: %s" % expected
	print("      %-46s ended = %s%s" % [label, got, note])


func _report_affects(key: StringName, expected: bool, label: String) -> void:
	var got := DomeActivity.affects_sequence(key)
	var note := "" if got == expected else "   <-- ATTESO: %s" % expected
	print("      %-46s affects = %s%s" % [label, got, note])


## Piccola comodità: costruisce l'input e campiona in una riga.
func _sample_at(src: HonestSequence, elapsed: float, total: int, mpf: float) -> Dictionary:
	var i := ImagingInput.new()
	i.elapsed_since_start_min = elapsed
	i.frames_total = total
	i.min_per_frame = mpf
	return src.sample(i)


## L'aritmetica della notte, senza aprire una finestra.
##
## Qui non c'è un `NightClock` istanziato: quello ha bisogno di uno SceneTree, di
## un `_process` e dell'autoload `Tuning`. Ciò che si collauda è la MATEMATICA che
## ci sta dentro — la stessa formula, scritta una seconda volta e confrontata con
## i valori del `.tres` che il gioco carica davvero. Se un giorno le due
## divergono, è perché qualcuno ha cambiato la formula senza cambiare la storia.
##
## SI PASSA DALL'AUTOLOAD `Tuning`, non da un `load()` del `.tres`. È l'AC6 della
## storia 2.1 alla lettera — «nessun punto del codice legge il `.tres` del tuning
## con `load()`» — ed è anche l'unico modo di collaudare i numeri VERI: `Tuning`
## applica `user://tuning_override.cfg`, che è precisamente lo strumento con cui
## si tara l'MVP. Un banco che leggesse il `.tres` grezzo stamperebbe «l'alba cade
## alle 06:00» mentre il gioco ne sta giocando un'altra, ed è lo strumento che
## dovrebbe accorgersene per primo.
func _check_night_clock() -> void:
	print("-- La notte: durata, ritmo, e l\'ora che ne esce")

	# Prima di collaudare l'aritmetica, si collauda che sia LA STESSA. La copia
	# qui sopra esiste per non dipendere da uno SceneTree; se diverge da quella
	# dell'orologio, tutto ciò che segue misura un gioco che non esiste.
	if NIGHT_START_HOUR != CLOCK.NIGHT_START_HOUR:
		print("   NIGHT_START_HOUR: banco %d, orologio %d  <-- ATTESO: uguali" % [
			NIGHT_START_HOUR, CLOCK.NIGHT_START_HOUR])
		return

	var length := Tuning.night_length_min
	var rate := Tuning.game_min_per_sec
	print("   da Tuning (profilo %s): night_length_min = %.0f min di gioco, game_min_per_sec = %.2f" % [
		Tuning.profile_hash, length, rate])

	if length <= 0.0 or rate <= 0.0:
		print("   <-- ATTESO: entrambi > 0, altrimenti la notte non finisce o non comincia")
		return

	# L'ora si ricava per somma diretta: elapsed_min E' l'ora. Nessuna compressione.
	var dawn_hour := int(NIGHT_START_HOUR + length / 60.0) % 24
	var dawn_minute := int(length) % 60
	print("   l\'alba cade alle %02d:%02d  (21:00 + %.0f minuti)" % [
		dawn_hour, dawn_minute, length])
	if dawn_hour != 6 or dawn_minute != 0:
		print("   <-- nota: il commento di tuning_profile.gd dice 21:00 -> 06:00 = 540")

	print("   durata reale della sessione: %.1f minuti  (%.0f / %.2f secondi)" % [
		length / rate / 60.0, length, rate])
	print("   la stessa notte a time_scale x10: %.1f minuti" % (length / rate / 10.0 / 60.0))

	# Il conto che l'orologio fa a ogni frame, rifatto qui.
	print("   accumulo: a 60 fps un frame vale %.4f minuti di gioco" % (rate / 60.0))
	var frames := int(ceil(length / (rate / 60.0)))
	print("   servono %d frame a 60 fps perche' elapsed_min raggiunga la soglia" % frames)

	# Le ore varcate lungo la notte, che sono i `hour_passed` che verranno emessi.
	var hours := PackedStringArray()
	var h := NIGHT_START_HOUR
	var m := 0.0
	while m < length:
		m += 60.0
		h = (h + 1) % 24
		if m <= length:
			hours.append("%02d" % h)
	print("   ore varcate: %s  (%d segnali hour_passed)" % [
		", ".join(hours), hours.size()])


## Il travaso fra la notte e il giocatore — il rilievo C1, chiuso il 2026-08-23.
##
## Non serve nessuno SceneTree: `NightRun` e `PlayerProfile` sono due Resource di soli
## dati, e la regola che le lega e' aritmetica pura. Si collauda QUI perche' e'
## esattamente il punto in cui e' facile sbagliare: una riga dimenticata nel travaso
## non produce nessun errore, produce un portafoglio che si azzera ogni tanto.
func _check_player_profile() -> void:
	print("-- Il portafoglio attraversa la notte (C1)")

	var profile := PlayerProfile.new()
	print("   il giocatore nasce con %d lire e %d notti fatte" % [
		profile.wallet_lire, profile.nights_completed])
	if profile.wallet_lire != 0 or profile.nights_completed != 0:
		print("   <-- ATTESO: si comincia da zero")

	# Notte 1: si guadagna, si chiude, si versa.
	var n1 := NightRun.new()
	n1.night_index = profile.nights_completed + 1
	n1.night_earnings = 4900
	n1.phase_scores = {&"polar": 80, &"imaging": 100}
	profile.wallet_lire += n1.night_earnings
	profile.nights_completed += 1
	print("   notte %d: guadagnate %d -> in cassa %d" % [
		n1.night_index, n1.night_earnings, profile.wallet_lire])

	# Notte 2: la nuova notte NON eredita i guadagni, ma il giocatore tiene le lire.
	var n2 := NightRun.new()
	n2.night_index = profile.nights_completed + 1
	print("   notte %d: guadagni della notte %d, in cassa %d" % [
		n2.night_index, n2.night_earnings, profile.wallet_lire])
	if n2.night_earnings != 0:
		print("   <-- ATTESO: i guadagni sono DELLA NOTTE e ripartono da zero")
	if profile.wallet_lire != 4900:
		print("   <-- ATTESO: il portafoglio e' del GIOCATORE e resta a 4900")
	if not n2.phase_scores.is_empty():
		print("   <-- ATTESO: i punteggi appartengono alla notte, non al giocatore")
	if n2.night_index != 2:
		print("   <-- ATTESO: l'indice avanza da nights_completed, non da un numero scritto a mano")

	# L'indice che avanza e' cio' che fa ruotare i committenti: senza, la commessa
	# resta per sempre la prima del roster e FULFILL paga quanto SELL.
	print("   la rotazione dei committenti segue l'indice: notte 1 -> primo, notte 2 -> secondo")

	# Il campo `version` esiste dal primo giorno, come per NightRun.
	print("   PlayerProfile v%d, NightRun v%d" % [
		PlayerProfile.CURRENT_VERSION, NightRun.CURRENT_VERSION])


## La persistenza porta il lavoro di una notte alla successiva (2.7).
##
## Si collauda `SaveManager` puro, senza SceneTree: round-trip, `migrate()` SEMPRE, e
## il ramo gentile su un file illeggibile. I percorsi di banco stanno in
## `user://saves/_bench/` — distinti da `profile.tres`/`night.tres` reali, così il
## banco non pesta il save del gioco — e si ripuliscono a fine check.
##
## NON esercita canali d'errore engine: il caso illeggibile passa dallo SNIFF
## dell'header (`FileAccess`) PRIMA di `ResourceLoader`, quindi Godot non emette alcun
## `ERROR` di caricamento e il cancello resta verde.
func _check_save_manager() -> void:
	print("-- SaveManager: il portafoglio è ancora lì la notte dopo (2.7)")

	var bench_dir := "user://saves/_bench"
	var profile_path := "%s/profile.tres" % bench_dir
	var run_path := "%s/night.tres" % bench_dir
	var junk_path := "%s/junk.tres" % bench_dir
	DirAccess.make_dir_recursive_absolute(bench_dir)

	var saves := SaveManager.new()

	# (0) Nessun save: primo avvio. Un percorso che non esiste → profilo pulito e
	# NESSUNA frase gentile: l'assenza di un save non è un errore, è un gioco nuovo.
	var missing := saves.load_profile("%s/non-esiste.tres" % bench_dir)
	print("   nessun save: wallet %d, notti %d, messaggio = \"%s\"" % [
		missing.wallet_lire, missing.nights_completed, saves.last_load_message])
	if missing.wallet_lire != 0 or missing.nights_completed != 0:
		print("   <-- ATTESO: un primo avvio parte da un profilo pulito")
	if not saves.last_load_message.is_empty():
		print("   <-- ATTESO: un save assente è silenzioso, nessuna frase gentile")

	# (a) Round-trip del profilo: wallet e notti sopravvivono al giro su disco.
	var p := PlayerProfile.new()
	p.wallet_lire = 4900
	p.nights_completed = 3
	var saved := saves.save_profile(p, profile_path)
	var back := saves.load_profile(profile_path)
	print("   round-trip profilo: salvato=%s, wallet %d, notti %d" % [
		saved, back.wallet_lire, back.nights_completed])
	if not saved or back.wallet_lire != 4900 or back.nights_completed != 3:
		print("   <-- ATTESO: wallet 4900 e 3 notti sopravvivono al .tres")
	if not saves.last_load_message.is_empty():
		print("   <-- ATTESO: un load valido non lascia messaggio gentile")

	# (b) `migrate()` SEMPRE: un profilo salvato con version = 0 torna a CURRENT_VERSION.
	var old := PlayerProfile.new()
	old.version = 0
	saves.save_profile(old, profile_path)
	var migrated := saves.load_profile(profile_path)
	print("   migrate() al load: version %d -> %d" % [0, migrated.version])
	if migrated.version != PlayerProfile.CURRENT_VERSION:
		print("   <-- ATTESO: migrate() porta a v%d a ogni load" % PlayerProfile.CURRENT_VERSION)

	# (c) Save illeggibile → frase gentile + profilo pulito, senza rumore engine. Si
	# scrive spazzatura con FileAccess (header NON `[gd_resource`): lo sniff la
	# intercetta prima di ResourceLoader, quindi nessun ERROR di caricamento.
	var junk := FileAccess.open(junk_path, FileAccess.WRITE)
	junk.store_string("questo non è un .tres — logbook rovinato\n")
	junk.close()
	var clean := saves.load_profile(junk_path)
	print("   illeggibile: messaggio = \"%s\"" % saves.last_load_message)
	print("   illeggibile: profilo pulito, wallet %d, notti %d" % [
		clean.wallet_lire, clean.nights_completed])
	if saves.last_load_message.is_empty():
		print("   <-- ATTESO: un save illeggibile mette una frase gentile su last_load_message")
	if clean.wallet_lire != 0 or clean.nights_completed != 0:
		print("   <-- ATTESO: un save illeggibile riparte da un profilo pulito")

	# (d) Round-trip NightRun: la chiave StringName di phase_scores sopravvive al .tres.
	# Ritira per il percorso .tres la voce di deferred-work sul round-trip JSON: è JSON
	# che perde `&"..."`, non ResourceSaver.
	var r := NightRun.new()
	r.phase_scores = {&"polar": 80}
	saves.save_run(r, run_path)
	var r_back := saves.load_run(run_path)
	var key_ok: bool = r_back.phase_scores.has(&"polar") and r_back.phase_scores[&"polar"] == 80
	print("   round-trip NightRun: phase_scores[&\"polar\"] = %s (chiave StringName intatta: %s)" % [
		r_back.phase_scores.get(&"polar", "assente"), key_ok])
	if not key_ok:
		print("   <-- ATTESO: il .tres preserva la chiave StringName")

	# (e) Il portafoglio attraversa un RIAVVIO, non solo la notte (AC2/AC3). È il caso
	# che la storia esiste per rendere vero: si mette un disco IN MEZZO al travaso di
	# `_check_player_profile`, dove là c'era solo memoria. La glue vera (`Game._ready`
	# carica, `end_night` versa+salva, `start_night` fa `NightRun.new()`) resta
	# scoperta dal banco perché è stateful e serve uno SceneTree — vedi il deferred del
	# 2.7, sorella di DW-7/DW-9. Qui si prova la LOGICA: ciò che sopravvive al disco e
	# ciò che no.
	var earned := PlayerProfile.new()
	earned.wallet_lire += 4900          # notte 1: guadagnato e versato
	earned.nights_completed += 1
	saves.save_profile(earned, profile_path)

	var rebooted := saves.load_profile(profile_path)   # spegni e riaccendi
	print("   riavvio: wallet %d, notti %d (prima 4900 / 1)" % [
		rebooted.wallet_lire, rebooted.nights_completed])
	if rebooted.wallet_lire != 4900 or rebooted.nights_completed != 1:
		print("   <-- ATTESO: il portafoglio e le notti sopravvivono al riavvio")

	# La notte nuova dopo il riavvio: `NightRun.new()`, come fa `start_night`. I
	# punteggi della notte precedente NON ci sono (appartengono alla notte), e l'indice
	# avanza da `nights_completed` del profilo ricaricato.
	var next_night := NightRun.new()
	var next_index := rebooted.nights_completed + 1
	print("   notte dopo il riavvio: phase_scores vuoti = %s, night_index = %d (atteso 2)" % [
		next_night.phase_scores.is_empty(), next_index])
	if not next_night.phase_scores.is_empty():
		print("   <-- ATTESO: i punteggi appartengono alla notte, non sopravvivono al riavvio")
	if next_index != 2:
		print("   <-- ATTESO: l'indice avanza dal profilo ricaricato (nights_completed + 1)")

	# Ripulire i file di banco: non devono restare a sporcare user://.
	# SI SVUOTA LA CARTELLA, non si cancellano tre nomi noti. Da quando un save
	# illeggibile viene messo in quarantena, il file spazzatura del banco non si chiama
	# piu' come quando e' stato creato — e' diventato `junk.tres.corrupt-<ts>` — quindi
	# `remove_absolute(junk_path)` falliva in silenzio, `remove_absolute(bench_dir)`
	# falliva a sua volta perche' la cartella non era vuota, e il banco lasciava
	# residui dentro la stessa directory dove il gioco tiene i salvataggi veri.
	var d := DirAccess.open(bench_dir)
	if d != null:
		d.list_dir_begin()
		var name := d.get_next()
		while not name.is_empty():
			if not d.current_is_dir():
				DirAccess.remove_absolute(bench_dir.path_join(name))
			name = d.get_next()
		d.list_dir_end()
	DirAccess.remove_absolute(bench_dir)
