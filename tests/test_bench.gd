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
