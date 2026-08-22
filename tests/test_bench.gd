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
	_check_night_clock()
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
