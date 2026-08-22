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
func _check_local_to_scene() -> void:
	print("-- .tres delle sorgenti: resource_local_to_scene deve essere true")
	for path in [
		"res://phases/polar/sources/honest_drift.tres",
		"res://phases/polar/sources/wandering_drift.tres",
	]:
		var r := load(path) as Resource
		if r == null:
			print("   %-22s NON CARICABILE" % path.get_file())
			continue
		var ok := r.resource_local_to_scene
		print("   %-22s resource_local_to_scene = %s%s" % [
			path.get_file(), ok, "" if ok else "   <-- ATTESO: true"])


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
