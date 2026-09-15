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


const SHUTTER_PATH := "res://phases/dome/sources/honest_shutter.tres"
const VCURVE_PATH := "res://phases/focus/sources/honest_vcurve.tres"
const HONEST_PATH := "res://phases/polar/sources/honest_drift.tres"
const WANDERING_PATH := "res://phases/polar/sources/wandering_drift.tres"
const CATALOG_PATH := "res://phases/targeting/sources/honest_catalog.tres"
const SEQUENCE_PATH := "res://phases/imaging/sources/honest_sequence.tres"
const ROSTER_PATH := "res://data/clients/roster.tres"
const ITEM_CATALOG_PATH := "res://data/catalog/catalog.tres"
const FORUM_PATH := "res://data/forum/forum.tres"
const QUADERNO_PATH := "res://data/quaderno/quaderno.tres"
## La telemetria (3.6): le sue funzioni pure sono STATICHE sullo script. Si preloada lo
## script — non l'autoload `Telemetry`, che ha stato per-notte e un `_ready()` che tocca
## il disco — per collaudare `merge_intervals`/`idle_segments`/`build_report` senza
## SceneTree né I/O, come `Game.split_spend`.
const TELEMETRY := preload("res://autoloads/telemetry.gd")
## La stessa larghezza di a-capo che la BBS usa per il corpo dei messaggi. Ripetuta qui
## apposta: se un giorno diverge dalla BBS, il conteggio righe collauderebbe una misura
## che il gioco non usa — ma la BBS non espone la costante (è privata al suo Control), e
## importarla vorrebbe dire montare quel Control. Si tiene il numero e lo si dichiara.
const BBS_WRAP_WIDTH := 42
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
	_check_honest_shutter()
	print("")
	_check_honest_bus()
	print("")
	_check_honest_peltier()
	print("")
	_check_honest_vcurve()
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

	_check_partite()
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
	_check_dome_presence()
	print("")
	_check_telemetry()
	print("")
	_check_forum()
	print("")
	_check_quaderno()
	print("")
	_check_prato()
	print("")
	_check_macchie()
	print("")
	_check_luna()
	print("")
	_check_pianeti()
	print("")
	_check_work_tabs()
	print("")
	_check_desktop_window()
	print("")
	_check_prints()
	print("")
	print("=== fine ===")
	get_tree().quit()


## La sorgente onesta deve essere una funzione pura dell'input: stesso input,
## stesso output, `delta` irrilevante. È ciò che permette alla fase di tenersi il
## proprio orologio, ed è la metà onesta della differenza che `F9` mette in scena.
## Il battente onesto della cupola (fase 1): deterministico, obbediente al comando,
## e con una corsa intera che si MISURA invece di darla per buona.
##
## LA DURATA DELLA CORSA È IL CONTENUTO DI QUESTA FASE. `motor_speed` è un numero
## nel .tres, e quanti secondi valga non si legge guardandolo: si integra come fa
## la fase, con lo stesso morsetto e la stessa soglia di fine corsa. Un dito che
## sbagliasse uno zero renderebbe la cupola apribile in mezzo secondo o in un
## minuto, e il .tres continuerebbe a sembrare a posto.
func _check_honest_shutter() -> void:
	print("-- HonestShutter: il battente fa quello che il comando dice")
	var src := _load_source(SHUTTER_PATH) as HonestShutter
	if src == null:
		return
	print("   dal .tres: motor_speed = %.4f corsa/s" % src.motor_speed)

	var fermo := DomeInput.new()
	fermo.command = 0
	fermo.aperture = 0.5
	fermo.seconds_running = 0.0
	var v_fermo := src.sample(fermo, 0.016)
	print("   comando lasciato, a metà corsa: %+.4f%s"
		% [v_fermo, "" if is_zero_approx(v_fermo) else "   <-- ATTESO: 0, il battente sta fermo"])

	var acceso := DomeInput.new()
	acceso.command = 1
	acceso.aperture = 0.5
	acceso.seconds_running = 12.0
	var a := src.sample(acceso, 0.016)
	var b := src.sample(acceso, 0.99)
	print("   sample(i, 0.016) = %+.4f" % a)
	print("   sample(i, 0.99 ) = %+.4f" % b)
	print("   -> %s" % ("DETERMINISTICA" if is_equal_approx(a, b)
		else "NON deterministica  <-- ATTESO: deterministica"))
	if a <= 0.0:
		print("   il comando premuto non apre  <-- ATTESO: velocità positiva")

	# La corsa intera, integrata come la integra la fase: stesso morsetto, stessa
	# soglia di fine corsa. Il passo è fisso perché una misura che dipende dal
	# frame rate non è una misura.
	var passo := 1.0 / 60.0
	var apertura := 0.0
	var secondi := 0.0
	while apertura < PhaseDome.FULLY_OPEN and secondi < 120.0:
		acceso.aperture = apertura
		apertura = clampf(apertura + src.sample(acceso, passo) * passo, 0.0, 1.0)
		secondi += passo
	var fuori_mano := secondi < 3.0 or secondi > 15.0
	print("   corsa intera tenendo premuto: %.2f s%s"
		% [secondi, "   <-- nota: fuori dai 3-15 s di rituale" if fuori_mano else ""])

	# E lasciando il comando a metà corsa il battente non deve più muoversi: è
	# la metà del comando a uomo presente che il pannello promette.
	var resta := 0.5
	for _i in 60:
		fermo.aperture = resta
		resta = clampf(resta + src.sample(fermo, passo) * passo, 0.0, 1.0)
	print("   un secondo a comando lasciato: %.4f (partiva da 0,5)%s"
		% [resta, "" if is_equal_approx(resta, 0.5) else "   <-- ATTESO: fermo dov'era"])

	# LA CHIUSURA, che è l'altra metà del quadro. Va provata a parte e non dedotta
	# dal segno: una sorgente che restituisse la stessa velocità POSITIVA con il
	# comando a -1 aprirebbe premendo «chiudi», e nessuna delle righe qui sopra se
	# ne accorgerebbe.
	var giu := DomeInput.new()
	giu.command = -1
	giu.aperture = 1.0
	var v_giu := src.sample(giu, passo)
	print("   comando di chiusura: %+.4f%s"
		% [v_giu, "" if v_giu < 0.0 else "   <-- ATTESO: negativa, il battente torna"])
	var chiude := 1.0
	var t_chiusura := 0.0
	while chiude > 0.0 and t_chiusura < 120.0:
		giu.aperture = chiude
		chiude = clampf(chiude + src.sample(giu, passo) * passo, 0.0, 1.0)
		t_chiusura += passo
	print("   corsa intera di ritorno: %.2f s%s"
		% [t_chiusura, "" if absf(t_chiusura - secondi) < 0.2
			else "   <-- nota: diversa dall'andata"])

	# I DUE PULSANTI INSIEME NON MUOVONO NIENTE. È l'interblocco dei quadri veri, e
	# il posto in cui si decide è la FASE (`get_axis` restituisce 0), non qui: la
	# sorgente riceve già il verso. Si collauda che uno zero resti uno zero.
	var interblocco := DomeInput.new()
	interblocco.command = 0
	interblocco.aperture = 0.5
	var v_inter := src.sample(interblocco, passo)
	print("   verso 0 (due pulsanti insieme): %+.4f%s"
		% [v_inter, "" if is_zero_approx(v_inter) else "   <-- ATTESO: 0"])


## La curva a V del fuoco (fase 8): deterministica, con un minimo dove dice di
## averlo, simmetrica, e — la cosa che conta davvero — con una zona di punteggio
## pieno LARGA ABBASTANZA DA CENTRARE.
##
## QUELLA LARGHEZZA NON SI LEGGE IN NESSUN FILE: nasce da tre numeri che stanno in
## due posti diversi — `min_hfd` e `slope` nel .tres della sorgente, `focus_best_hfd`
## in `Tuning` — e dice quanti passi di focheggiatore separano il pieno dal non
## pieno. Se qualcuno cambia uno dei tre, la fase diventa una lotteria o un regalo
## senza che una riga di codice cambi. Qui si misura, in passi e in decimi di
## secondo di dito.
func _check_honest_vcurve() -> void:
	print("-- HonestVCurve: il fuoco sta dove la curva dice")
	var src := _load_source(VCURVE_PATH) as HonestVCurve
	if src == null:
		return
	print("   dal .tres: fuoco a %.0f passi, minimo %.2f, pendenza %.4f"
		% [src.best_position, src.min_hfd, src.slope])

	var i := FocusInput.new()
	i.position = src.best_position + 300.0
	i.seconds_since_move = 3.0
	var a := src.sample(i, 0.016)
	var b := src.sample(i, 0.99)
	print("   sample(i, 0.016) = %.4f" % a)
	print("   sample(i, 0.99 ) = %.4f" % b)
	print("   -> %s" % ("DETERMINISTICA" if is_equal_approx(a, b)
		else "NON deterministica  <-- ATTESO: deterministica"))

	# Al fuoco il diametro e' il minimo dichiarato, e non zero: l'atmosfera non lo
	# permette, e una sorgente che desse zero starebbe raccontando un'ottica che
	# non esiste.
	i.position = src.best_position
	var al_fuoco := src.sample(i, 0.016)
	print("   al fuoco: %.4f (atteso %.4f)%s"
		% [al_fuoco, src.min_hfd,
			"" if is_equal_approx(al_fuoco, src.min_hfd) else "   <-- ATTESO: il minimo"])

	# Avvicinandosi il diametro deve CALARE, in modo monotono, e da tutte e due le
	# parti allo stesso modo: una curva sbilanciata insegnerebbe a cercare il fuoco
	# sempre dalla stessa parte.
	print("   avvicinandosi il diametro deve calare, e i due rami coincidere:")
	var precedente := INF
	for d in [800.0, 400.0, 200.0, 100.0, 0.0]:
		i.position = src.best_position + d
		var destra := src.sample(i, 0.016)
		i.position = src.best_position - d
		var sinistra := src.sample(i, 0.016)
		var cala := destra < precedente
		var pari := is_equal_approx(destra, sinistra)
		precedente = destra
		var nota := ""
		if not cala:
			nota = "   <-- ATTESO: minore del precedente"
		elif not pari:
			nota = "   <-- ATTESO: i due rami uguali"
		print("      %+5.0f passi -> %.3f   %+5.0f passi -> %.3f%s"
			% [d, destra, -d, sinistra, nota])

	# La zona del pieno, misurata: fin dove il diametro resta sotto la soglia di
	# `Tuning`. Si cerca camminando, un passo per volta, invece di invertire la
	# formula: cosi' la misura resta vera anche il giorno in cui la curva non sara'
	# piu' un'iperbole.
	var largo := 0.0
	while largo < PhaseFocus.TRAVEL:
		i.position = src.best_position + largo
		if src.sample(i, 0.016) > Tuning.focus_best_hfd:
			break
		largo += 1.0
	print("   punteggio pieno entro %.0f passi dal fuoco (%.2f s di dito a %.0f passi/s)"
		% [largo, largo / PhaseFocus.STEP_RATE, PhaseFocus.STEP_RATE])
	if largo < 30.0 or largo > 400.0:
		print("      <-- nota: fuori dai 30-400 passi che rendono la fase giocabile")

	# E al fermo meccanico il punteggio deve essere zero: se anche il peggio
	# possibile prendesse punti, la fase non misurerebbe niente.
	i.position = src.best_position + PhaseFocus.TRAVEL
	var al_fermo := src.sample(i, 0.016)
	print("   al fermo (%.0f passi): %.2f, soglia dello zero %.2f%s"
		% [PhaseFocus.TRAVEL, al_fermo, Tuning.focus_max_hfd,
			"" if al_fermo >= Tuning.focus_max_hfd else "   <-- nota: il peggio prende punti"])


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
	"res://phases/dome/sources/honest_shutter.tres",
	"res://phases/focus/sources/honest_vcurve.tres",
	"res://phases/startup/sources/honest_bus.tres",
	"res://phases/cooling/sources/honest_peltier.tres",
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
	# 04:45 = 465 min: disponibili esattamente {M13, M57, M31}. M31 ha finestra
	# fino alle 04:45 = 465 (stretta di un quarto d'ora per parte da D-237, perché
	# alle 05:00 era sotto l'orizzonte della cupola), ed è il confine `465<=465`
	# inclusivo — il punto più facile da rompere. Alle 05:00 M31 non c'è più.
	_assert_availability(src, 465.0, "04:45", PackedStringArray(["M13", "M57", "M31"]))
	_assert_availability(src, 480.0, "05:00", PackedStringArray(["M13", "M57"]))
	# Il confine del wrap di mezzanotte per M8 (`vis_to = "00:00"` -> 180 min): a
	# 180 deve essere disponibile (confine inclusivo), a 181 no. È la coppia che
	# distingue `<=` da `<` proprio sul minuto che attraversa le 00:00.
	_assert_available_contains(src, 180.0, "00:00", &"M8", true)
	_assert_available_contains(src, 181.0, "00:01", &"M8", false)

	# LA MASCHERA DELL'ORIZZONTE, che e' l'altra meta' di `available` (D-191).
	# Non si pinnano le sigle: si pretende la COERENZA fra i tre campi, cosi'
	# questo controllo resta vero anche il giorno in cui lo strumento verra'
	# alzato dentro la cupola e l'orizzonte scendera'.
	_assert_horizon_mask(src, 30.0, "21:30")
	_assert_horizon_mask(src, 300.0, "02:00")

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
		# SI PINNA LA FINESTRA, NON LA DISPONIBILITA', e la differenza e' nata da
		# una regressione vera: da quando il planetario tiene conto anche
		# dell'orizzonte della cupola, `available` mescola due fatti — «e' nella
		# sua finestra» e «questa cupola lo raggiunge». Confrontando il misto,
		# questi controlli avrebbero smesso di collaudare il wrap di mezzanotte e
		# il confine inclusivo, che sono la ragione per cui esistono.
		var avail: bool = entry.get(&"in_window", false)
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
			# `in_window` e non `available`, per la ragione scritta poco sopra:
			# questo controllo esiste per il confine del wrap di mezzanotte, e
			# l'orizzonte della cupola non c'entra niente con quel confine.
			found = entry.get(&"in_window", false)
			break
	var note := ""
	if found != expected:
		note = "   <-- ATTESO: %s = %s" % [short, "disponibile" if expected else "non disponibile"]
	print("   confine %s (now_min %.0f): %s = %s%s" % [
		label, now_min, short, "disponibile" if found else "non disponibile", note])


## `available` deve essere ESATTAMENTE «nella finestra E sopra l'orizzonte della
## cupola», per ogni target. E l'altezza dichiarata dev'essere quella che
## `SkyGeometry` calcola: la sorgente ha una copia del conto dell'angolo orario
## (la gemella sta in `HonestPointing`), e due copie che divergono farebbero
## offrire dal planetario un soggetto che il GOTO non raggiunge.
func _assert_horizon_mask(src: HonestCatalog, now_min: float, label: String) -> void:
	var i := TargetingInput.new()
	i.now_min = now_min
	var storti := PackedStringArray()
	var sotto := PackedStringArray()
	for entry in src.sample(i):
		var short: String = entry.get(&"short", "?")
		var alt: float = entry.get(&"alt", 0.0)
		var dentro: bool = entry.get(&"in_window", false)
		var disp: bool = entry.get(&"available", false)
		if disp != (dentro and alt >= SkyGeometry.ORIZZONTE_CUPOLA):
			storti.append(short)
		if dentro and alt < SkyGeometry.ORIZZONTE_CUPOLA:
			sotto.append(short)
	var note := ""
	if storti.size() > 0:
		note = "   <-- ATTESO: available == in_window AND alt >= orizzonte; storti: {%s}" % ", ".join(storti)
	print("   orizzonte %.1f alle %s: in finestra ma troppo bassi {%s}%s" % [
		SkyGeometry.ORIZZONTE_CUPOLA, label, ", ".join(sotto), note])


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
## terminale legge davvero. Oggi solo la moka è implementata; stufetta e
## lubrificare_cupola no — e stanno nel file apposta, perché un filtro senza niente da
## escludere non prova di essere un filtro. Se fosse rotto e mostrasse tutto, questo
## check lo stamperebbe.
func _check_item_catalog() -> void:
	print("-- ItemCatalog.for_category(): solo gli implementati per categoria (3.2)")
	var catalog := _load_source(ITEM_CATALOG_PATH) as ItemCatalog
	if catalog == null:
		return
	print("   dal .tres: %d articoli totali" % catalog.items.size())

	# `implemented` significa «esiste davvero là fuori», non «il codice c'è». Oggi lo è
	# solo la moka, che ha un corpo vero (`assets/models/moka.glb`); la lampadina è
	# uscita dal gioco insieme alla lampada (D-236).
	_report_category(catalog, &"personal", PackedStringArray(["moka"]),
		"personal implementati")
	_report_category(catalog, &"facilities", PackedStringArray([]),
		"facilities implementati")

	# Il filtro spento (only_implemented = false) DEVE dare di più: è la prova che il
	# filtro non è un no-op. personal senza filtro = moka + stufetta.
	var all_personal := catalog.for_category(&"personal", false)
	var impl_personal := catalog.for_category(&"personal", true)
	var filters := all_personal.size() > impl_personal.size()
	var fnote := "" if filters else "   <-- ATTESO: il filtro deve escludere i non implementati"
	print("   %-40s personal: tutti %d, implementati %d%s" % [
		"il filtro esclude davvero", all_personal.size(), impl_personal.size(), fnote])


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
	print("   dopo mark_owned(moka): owns(moka) = %s, owns(stufetta) = %s" % [
		p.owns(&"moka"), p.owns(&"stufetta")])
	if not p.owns(&"moka") or p.owns(&"stufetta"):
		print("   <-- ATTESO: possiede la moka, non la stufetta")

	# Idempotenza: comprare due volte non duplica.
	p.mark_owned(&"moka")
	var dup_note := "" if p.owned_items.size() == 1 else "   <-- ATTESO: mark_owned è idempotente"
	print("   mark_owned(moka) due volte: owned_items = %s%s" % [p.owned_items, dup_note])

	# Round-trip su disco: il possesso sopravvive al save/load, come il portafoglio.
	var bench_dir := "user://saves/_bench_items"
	var path := "%s/profile.tres" % bench_dir
	DirAccess.make_dir_recursive_absolute(bench_dir)
	var saves := SaveManager.new()
	p.mark_owned(&"stufetta")
	p.wallet_lire = 3000
	saves.save_profile(p, path)
	var back := saves.load_profile(path)
	var round_ok := back.owns(&"moka") and back.owns(&"stufetta") and back.wallet_lire == 3000
	print("   round-trip: owns(moka)=%s owns(stufetta)=%s wallet=%d" % [
		back.owns(&"moka"), back.owns(&"stufetta"), back.wallet_lire])
	if not round_ok:
		print("   <-- ATTESO: possesso e portafoglio sopravvivono al .tres")

	# Un profilo SENZA il campo (default []) è «niente posseduto», non un errore.
	var fresh := PlayerProfile.new()
	print("   default: owned_items vuoto = %s (assente = stato iniziale)" % fresh.owned_items.is_empty())
	if not fresh.owned_items.is_empty():
		print("   <-- ATTESO: default [] — nessun bump di versione")

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


## La moka, i fuochi e le tazze (D-244): la logica PURA e STATICA. Il gesto, la mira e il
## fuoco vero si camminano con `tools/prova_moka.gd`; qui si legge la tavola.
##
## PRIMA QUI C'ERA LA TAVOLA DEI TEMPI della moka di 3.3 — riempi, sul fuoco, versa, bevi —
## che si avanzava a colpi di E guardandola. Non c'è più perché non ci sono più i tempi: il
## caffè lo fanno le cose, e quello che resta da collaudare senza SceneTree sono le regole
## che le cose seguono.
func _check_moka_ritual() -> void:
	print("-- Moka: cuoce solo su un fuoco acceso, versa solo in una tazza vuota (D-244)")
	var quarto := 10.0 / Moka.BREW_SECONDS
	_report_cottura(0.0, 0, true, 10.0, quarto, "vuota, sul fuoco acceso, 10 s")
	_report_cottura(0.0, 0, false, 10.0, 0.0, "vuota, fuoco spento: ferma")
	_report_cottura(0.5, 0, false, 10.0, 0.5, "tolta a meta': resta a meta'")
	_report_cottura(0.0, Moka.TAZZINE, true, 10.0, 0.0, "col caffe' dentro non ne fa altro")
	_report_cottura(0.95, 0, true, 10.0, 1.0, "oltre la fine si ferma a 1")

	print("   -- versare")
	_report_moka_si(Moka.puo_versare(Moka.TAZZINE, true), true, "caffe' nella moka, tazza vuota")
	_report_moka_si(Moka.puo_versare(0, true), false, "moka vuota")
	_report_moka_si(Moka.puo_versare(2, false), false, "tazza gia' piena")
	_report_moka_num(Moka.inclinazione_a(0.0), 0.0, "inclinazione all'inizio del gesto")
	_report_moka_num(Moka.inclinazione_a((Moka.VERSA_DA + Moka.VERSA_A) / 2.0), 1.0,
		"inclinazione mentre il caffe' scende")
	_report_moka_num(Moka.inclinazione_a(Moka.VERSA_SECONDI), 0.0, "inclinazione alla fine")

	print("   -- il fuoco: cuoce cio' che gli sta sopra, non cio' che gli sta accanto")
	var c := Vector3(10.94, 0.94, 2.01)
	_report_moka_si(Fornello.sta_sopra(c, c + Vector3(0.0, 0.003, 0.0)), true, "appoggiata al centro")
	_report_moka_si(Fornello.sta_sopra(c, c + Vector3(0.03, 0.0, 0.0)), true, "tre centimetri fuori centro")
	_report_moka_si(Fornello.sta_sopra(c, c + Vector3(0.0, 0.0, -0.22)), false, "sul fuoco dietro")
	_report_moka_si(Fornello.sta_sopra(c, c + Vector3(0.0, 0.25, 0.0)), false, "tenuta in mano sopra")

	print("   -- la tazza: il caffe' e' largo quanto la tazza alla sua quota")
	_report_moka_num(Tazza.raggio_a(0.035), 0.0269, "raggio interno a 35 mm (misurato)")
	_report_moka_num(Tazza.raggio_a(0.0275), (0.0173 + 0.0269) / 2.0, "a meta' fra due misure")
	_report_moka_num(Tazza.raggio_a(0.2), 0.0353, "sopra l'ultima misura: l'ultima")
	_report_moka_num(Tazza.quota_per(0.0), Tazza.FONDO, "vuota: il fondo")
	_report_moka_num(Tazza.quota_per(1.0), Tazza.PIENA, "piena")
	_report_moka_num(Tazza.verso_la_bocca((Tazza.BEVI_DA + Tazza.BEVI_A) / 2.0), 1.0,
		"bevendo, a meta' gesto e' alla bocca")
	_report_moka_num(Tazza.verso_la_bocca(Tazza.BEVI_SECONDI), 0.0, "finito di bere, torna giu'")


func _report_cottura(prima: float, dosi: int, acceso: bool, delta: float, expected: float,
		label: String) -> void:
	var got := Moka.avanza_cottura(prima, dosi, acceso, delta)
	var note := "" if absf(got - expected) < 0.0001 else "   <-- ATTESO: %.3f" % expected
	print("   %-44s cottura %.3f -> %.3f%s" % [label, prima, got, note])


func _report_moka_si(got: bool, expected: bool, label: String) -> void:
	var note := "" if got == expected else "   <-- ATTESO: %s" % expected
	print("      %-44s %s%s" % [label, got, note])


func _report_moka_num(got: float, expected: float, label: String) -> void:
	var note := "" if absf(got - expected) < 0.0001 else "   <-- ATTESO: %.4f" % expected
	print("      %-44s %.4f%s" % [label, got, note])


## Le partite e la memoria della casa (D-243): quale partita apre un avvio, quali nomi sono
## cartelle ammesse, e il giro su disco di com'è il mondo. Senza SceneTree; la memoria vera
## — una tazza spostata che finisce nel file e torna al riavvio — la cammina
## `tools/prova_memoria.gd`.
func _check_partite() -> void:
	print("-- Partite: quale si apre, e il mondo che si ricorda (D-243)")
	var vera := SaveManager.PARTITA_VERA
	var sonde := SaveManager.PARTITA_SONDE
	var gioco := PackedStringArray(["--path", "."])
	var sonda := PackedStringArray(["--headless", "tools/prova_moka.tscn"])
	var principale := PackedStringArray(["res://main.tscn"])
	_report_partita(Game.partita_dell_avvio(gioco, "", "", false), vera, "gioco finito")
	_report_partita(Game.partita_dell_avvio(gioco, "", "prova-2", false), vera,
		"gioco finito, con una scelta di sviluppo rimasta")
	_report_partita(Game.partita_dell_avvio(gioco, "", "prova-2", true), "prova-2",
		"sviluppo: l'ultima scelta col pannello")
	_report_partita(Game.partita_dell_avvio(principale, "", "", true), vera,
		"main.tscn lanciata a mano")
	_report_partita(Game.partita_dell_avvio(sonda, "", "prova-2", true), sonde, "una sonda")
	_report_partita(Game.partita_dell_avvio(sonda, vera, "", true), vera,
		"una sonda con PARTITA=partita")
	_report_partita(Game.partita_dell_avvio(gioco, "../profilo", "", true), vera,
		"PARTITA con un percorso dentro: ignorata")

	for coppia in [["prova-1", true], ["partita", true], ["", false], ["../x", false],
			["Prova", false], ["_bench", false], ["con spazio", false]]:
		var got := SaveManager.nome_valido(coppia[0])
		print("      nome «%s» valido: %s%s" % [coppia[0], got,
			"" if got == coppia[1] else "   <-- ATTESO: %s" % coppia[1]])
	var libero := SaveManager.nome_libero(PackedStringArray(["partita", "prova-1", "prova-3"]))
	print("      primo nome libero dopo prova-1 e prova-3: %s%s" % [libero,
		"" if libero == "prova-2" else "   <-- ATTESO: prova-2"])

	# IL GIRO SU DISCO, con una trasformata e un numero dentro il dizionario: sono i tipi
	# che le cose mettono nel loro ricordo, e `ResourceSaver` deve riportarli uguali.
	var dir := "user://saves/_bench_mondo"
	var path := dir.path_join(SaveManager.WORLD_FILE)
	var saves := SaveManager.new()
	var w := WorldState.new()
	var xf := Transform3D(Basis(Vector3.UP, 0.7), Vector3(11.9, 0.78, 3.65))
	w.oggetti = {"TazzaCucina": {&"xf": xf, &"livello": 0.5}, "Fornello2": {&"acceso": true}}
	saves.save_world(w, path)
	var letto := saves.load_world(path)
	var tazza: Dictionary = letto.oggetti.get("TazzaCucina", {})
	var fuoco: Dictionary = letto.oggetti.get("Fornello2", {})
	var giro_ok: bool = letto.version == WorldState.CURRENT_VERSION \
		and tazza.has(&"xf") and (tazza[&"xf"] as Transform3D).is_equal_approx(xf) \
		and is_equal_approx(float(tazza.get(&"livello", 0.0)), 0.5) \
		and bool(fuoco.get(&"acceso", false))
	print("   giro su disco del mondo: versione %d, tazza e fuoco intatti %s%s" % [
		letto.version, giro_ok, "" if giro_ok else "   <-- ATTESO: true"])
	var vuoto := saves.load_world(dir.path_join("non_esiste.tres"))
	var silenzio := vuoto.oggetti.is_empty() and saves.last_load_message.is_empty()
	print("   mondo assente: %d voci, in silenzio %s%s" % [vuoto.oggetti.size(), silenzio,
		"" if silenzio else "   <-- ATTESO: vuoto e in silenzio"])
	# E LE MACCHIE (D-251): una lista di dizionari con dentro la trasformata. Il mondo di
	# prima, scritto qui sopra senza macchie, le rilegge vuote.
	var w2 := WorldState.new()
	var xf_m := Macchia.trasformata_su(Vector3(9.1, 0.0, 6.2), Vector3.UP, 1.1)
	w2.macchie = [{&"xf": xf_m, &"raggio": 0.129, &"seme": 42.5, &"schizzata": true, &"sporco": 0.4}]
	var senza := letto.macchie.is_empty()
	saves.save_world(w2, path)
	var letto2 := saves.load_world(path)
	var m: Dictionary = letto2.macchie[0] if letto2.macchie.size() == 1 \
		and letto2.macchie[0] is Dictionary else {}
	var macchia_ok: bool = senza and not m.is_empty() \
		and (m.get(&"xf", Transform3D()) as Transform3D).is_equal_approx(xf_m) \
		and is_equal_approx(float(m.get(&"sporco", 0.0)), 0.4) and bool(m.get(&"schizzata", false))
	print("   giro su disco delle macchie: senza macchie %s, poi %d macchia intatta %s%s" % [
		senza, letto2.macchie.size(), macchia_ok, "" if macchia_ok else "   <-- ATTESO: true"])
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(dir)


## Le macchie di caffè (D-251): la pozza è grande quanto il caffè che c'era, il mocio la porta
## via in pochi secondi, sta sul piano su cui è caduta e copre quello che deve. Che il caffè cada
## dove deve, che il mocio arrivi a terra da in piedi e che la casa se ne ricordi si cammina in
## `tools/prova_mocio.gd`.
func _check_macchie() -> void:
	print("-- Macchie di caffè: grandi quanto il caffè, e il mocio le porta via (D-251)")
	var piena := Macchia.raggio_per(1.0, false)
	var schizzo := Macchia.raggio_per(1.0, true)
	var fondo := Macchia.raggio_per(0.05, false)
	var misure_ok := piena > 0.07 and piena < 0.12 and schizzo > piena and fondo < piena \
		and fondo >= Macchia.RAGGIO_MINIMO
	print("   raggio: tazza piena %.1f cm, lanciata %.1f, un fondo di tazza %.1f%s" % [
		piena * 100.0, schizzo * 100.0, fondo * 100.0, "" if misure_ok
		else "   <-- ATTESO: la piena fra 7 e 12, la lanciata più larga, il fondo più piccolo e non sotto il minimo"])
	var ml := PI * piena * piena * Macchia.SPESSORE * 1e6
	print("   la pozza della tazza piena tiene %.1f ml%s" % [ml,
		"" if absf(ml - Macchia.ML_TAZZA) < 0.5 else "   <-- ATTESO: %.0f, il caffè che c'era" % Macchia.ML_TAZZA])

	var t_piena := _secondi_di_mocio(piena)
	var t_schizzo := _secondi_di_mocio(schizzo)
	var tempi_ok := t_piena >= 2.0 and t_piena <= 5.0 and t_schizzo > t_piena and t_schizzo <= 8.0
	print("   secondi di mocio: tazza piena %.1f, lanciata %.1f%s" % [t_piena, t_schizzo,
		"" if tempi_ok else "   <-- ATTESO: la piena fra 2 e 5, la lanciata di più ma entro 8"])
	var finita := Macchia.dopo_strofinata(0.01, 10.0, piena)
	print("   dieci secondi su una macchia quasi pulita: %.2f%s" % [finita,
		"" if finita == 0.0 else "   <-- ATTESO: 0, mai sotto"])

	var storte := PackedStringArray()
	for n in [Vector3.UP, Vector3(0.3, 1.0, -0.2).normalized(), Vector3.FORWARD, Vector3.DOWN]:
		var xf_n := Macchia.trasformata_su(Vector3(1.0, 2.0, 3.0), n, 0.7)
		var b := xf_n.basis
		var giusta := b.y.is_equal_approx(n) and is_equal_approx(b.determinant(), 1.0) \
			and b.orthonormalized().is_equal_approx(b) \
			and xf_n.origin.is_equal_approx(Vector3(1.0, 2.0, 3.0) + n * Macchia.SOLLEVATA)
		if not giusta:
			storte.append(str(n))
	print("   su pavimento, pendenza, muro e soffitto: l'alto è la normale, sollevata di %.0f mm%s" % [
		Macchia.SOLLEVATA * 1000.0, "" if storte.is_empty() else "   <-- ATTESO: storta per %s" % ", ".join(storte)])

	var xf := Macchia.trasformata_su(Vector3(5.0, 0.0, 5.0), Vector3.UP, 0.3)
	for c in [[Vector3(5.0, 0.01, 5.0), 0.0, true, "il centro"],
			[Vector3(5.12, 0.01, 5.0), 0.0, true, "a un raggio e un quinto"],
			[Vector3(5.30, 0.01, 5.0), 0.0, false, "a tre raggi"],
			[Vector3(5.30, 0.01, 5.0), 0.2, true, "a tre raggi, con le frange"],
			[Vector3(5.0, 0.75, 5.0), 0.0, false, "sul tavolo, sopra la macchia"]]:
		var got := Macchia.copre(xf, 0.10, c[0], c[1])
		print("      copre %-30s %s%s" % [c[3], got, "" if got == c[2] else "   <-- ATTESO: %s" % c[2]])


func _secondi_di_mocio(r: float) -> float:
	var sporco := 1.0
	var t := 0.0
	while sporco > 0.0 and t < 60.0:
		sporco = Macchia.dopo_strofinata(sporco, 1.0 / 60.0, r)
		t += 1.0 / 60.0
	return t


func _report_partita(got: String, expected: String, label: String) -> void:
	var note := "" if got == expected else "   <-- ATTESO: %s" % expected
	print("      %-58s %s%s" % [label, got, note])


## Lo «stare a guardare» della cupola (3.5): la logica PURA e STATICA di `DomeActivity` —
## il gate (in cupola E posa in corso), i punti d'emissione della coppia started/ended, e
## il filtro sulla sequenza. Gemella di `_check_moka_ritual`: nessuno
## SceneTree, nessun autoload, nessun timer.
##
## Il moto del telescopio, il dwell timer runtime e la
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

	# `affects_sequence(key)` NON ESISTE PIU'. La review dell'epica 3 ha spostato il gate
	# della cupola da `phase_started(&"imaging")` — che e' il MONTAGGIO della fase — a
	# `Events.sequence_started`, che e' lo START vero. Il segnale porta il fatto senza la
	# chiave: non c'e' piu' niente da filtrare, e queste righe collaudavano un filtro che
	# non c'e'. Tolte con la funzione, non sostituite: cio' che il gate fa adesso e' gia'
	# coperto da `is_gate_open`/`should_emit_started`/`should_emit_ended` qui sopra.


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


## La telemetria (3.6): l'aritmetica PURA — unione degli intervalli, idle per differenza
## (con sovrapposizioni), e l'assemblaggio del report (attività chiuse/abbandonate/idle/
## fuori-posa, `wait_total_min`, `quit_mid_pose`). Gemella di `Game.split_spend`: nessuno
## SceneTree, nessun autoload istanziato, nessun I/O su file.
##
## Il file su disco, la scrittura al quit (`NOTIFICATION_WM_CLOSE_REQUEST`, che in
## headless non arriva) e la leggibilità della riga F12 li verifica l'operatore. Il banco
## legge la logica: `build_report(..., quit=true)` copre la LOGICA del secondo momento.
func _check_telemetry() -> void:
	print("-- Telemetria: unione intervalli, idle per differenza, report (3.6)")

	# (1) merge_intervals: sovrapposti e contigui si FONDONO, non si sommano — caffè sul
	# fuoco mentre si sale in cupola è il caso normale. L'esempio delle Design Notes.
	print("   -- merge_intervals: unione, non somma")
	_report_merge([[0, 10], [5, 12], [20, 25]], [[0, 12], [20, 25]],
		"sovrapposti [0,10]+[5,12] + disgiunto [20,25]")
	_report_merge([[0, 5], [5, 10]], [[0, 10]], "contigui a 5 si fondono")
	_report_merge([[10, 20], [0, 5]], [[0, 5], [10, 20]], "fuori ordine → riordinati")
	_report_merge([[0, 10], [3, 6]], [[0, 10]], "uno dentro l'altro → il contenente")
	_report_merge([], [], "vuoto → vuoto")

	# (2) idle_segments: posa − UNIONE delle attività. L'esempio delle Design Notes, più i
	# casi di frontiera (nessuna copertura, copertura totale).
	print("   -- idle_segments: posa meno l'unione, nessun idle negativo")
	_report_idle([[0, 30]], [[0, 12], [20, 25]], [[12.0, 8.0], [25.0, 5.0]],
		"posa [0,30], coperti [0,12]+[20,25]")
	_report_idle([[0, 30]], [], [[0.0, 30.0]], "posa senza attività → tutta idle")
	_report_idle([[0, 30]], [[0, 30]], [], "posa tutta coperta → nessun idle")
	# Due attività SOVRAPPOSTE dentro la posa: l'unione [5,20] lascia idle [0,5] e [20,30].
	# Sommandole (15+5=20 > 15 reali) si otterrebbe idle negativo — qui NON accade.
	_report_idle([[0, 30]], [[5, 15], [10, 20]], [[0.0, 5.0], [20.0, 10.0]],
		"due sovrapposte [5,15]+[10,20] → union [5,20], niente idle negativo")

	# (3) build_report: la struttura esatta del file. Attività chiusa, abbandonata, idle,
	# e una FUORI posa (registrata lo stesso, ma non conta per idle).
	print("   -- build_report: la struttura del file su disco")
	# Una posa [0,30]. caffe [2,8] chiuso dentro; cupola [10,-1] abbandonato dentro;
	# forum [40,45] chiuso FUORI dalla posa (dopo l'alba della finestra). now = 50.
	var windows := [[0.0, 30.0]]
	var activities := [
		{&"what": &"caffe", &"t": 2.0, &"end": 8.0},
		{&"what": &"cupola", &"t": 10.0, &"end": -1.0},
		{&"what": &"forum", &"t": 40.0, &"end": 45.0},
	]
	var report: Dictionary = TELEMETRY.build_report(3, "abc12345", windows, activities,
		2, false, 50.0)

	_report_field(report, &"night", 3, "night = night_index")
	_report_field(report, &"tuning_hash", "abc12345", "tuning_hash presente")
	_report_field(report, &"menu_reopened", 2, "menu_reopened = conteggio presentazioni")
	_report_field(report, &"quit_mid_pose", false, "quit_mid_pose = false all'alba")
	# wait_total_min = somma delle finestre di posa = 30, NON la durata della notte.
	_report_field(report, &"wait_total_min", 30.0, "wait_total_min = somma delle pose")

	var acts: Array = report.get(&"wait_activities", [])
	print("   wait_activities (%d voci, ordinate per t):" % acts.size())
	for a in acts:
		print("      %-8s t=%.1f dur=%s%s" % [
			a.get(&"what"), a.get(&"t"), str(a.get(&"dur")),
			"  abbandonata" if a.get(&"abandoned", false) else ""])

	# caffe chiuso: dur = 6, nessun abandoned.
	_report_activity(acts, "caffe", 2.0, 6.0, false, "caffe chiuso dentro la posa")
	# cupola aperto alla scrittura: dur = null, abandoned = true — NON omesso.
	_report_activity(acts, "cupola", 10.0, null, true, "cupola abbandonata (dur null)")
	# forum FUORI posa: registrato lo stesso, dur = 5, non conta per idle.
	_report_activity(acts, "forum", 40.0, 5.0, false, "forum fuori posa, registrato lo stesso")
	# idle: la posa [0,30] meno l'unione delle coperture DENTRO (caffe [2,8] + cupola
	# [10,50]→clampata alla posa a [10,30]). Scoperti: [0,2] e [8,10]. forum è fuori posa,
	# non copre niente. → idle {t:0,dur:2} e {t:8,dur:2}.
	_report_idle_voice(acts, 0.0, 2.0, "idle [0,2] prima del caffè")
	_report_idle_voice(acts, 8.0, 2.0, "idle [8,10] fra caffè e cupola")

	# (4) quit_mid_pose = true: la LOGICA del secondo momento. Il chiamante (`_write`)
	# chiude la finestra aperta a `now` PRIMA di passarla; qui si simula quello — una
	# finestra [0,20] chiusa a now=20 — e si verifica che il flag arrivi vero e che
	# wait_total la conti.
	print("   -- build_report(quit=true): la logica del quit a posa in corso")
	var q_report: Dictionary = TELEMETRY.build_report(1, "def", [[0.0, 20.0]], [], 0,
		true, 20.0)
	_report_field(q_report, &"quit_mid_pose", true, "quit_mid_pose = true al quit")
	_report_field(q_report, &"wait_total_min", 20.0, "posa aperta chiusa a now conta in wait_total")

	# (5) Notte senza attività: file valido, wait_activities = solo idle che copre le pose.
	var empty_report: Dictionary = TELEMETRY.build_report(2, "ghi", [[0.0, 15.0]], [], 0,
		false, 15.0)
	var empty_acts: Array = empty_report.get(&"wait_activities", [])
	var only_idle: bool = empty_acts.size() == 1 and empty_acts[0].get(&"what") == "idle" \
		and is_equal_approx(float(empty_acts[0].get(&"dur")), 15.0)
	var idle_note := "" if only_idle else "   <-- ATTESO: una sola voce idle di dur 15"
	print("   notte senza attività: wait_activities = %s%s" % [empty_acts, idle_note])

	# (6) uncovered_min: l'aritmetica DIETRO la riga F12 (`current_pose_uncovered_min` la
	# delega). Posa aperta [0, now=18]; caffe [2,8] chiuso, cupola [12,-1] aperto → clampato
	# a [12,18]. Coperti [2,8]+[12,18]; scoperti [0,2] e [8,12] = 2+4 = 6. Nessuna posa → -1.
	print("   -- uncovered_min: i minuti scoperti della posa in corso (riga F12)")
	var live_acts := [
		{&"what": &"caffe", &"t": 2.0, &"end": 8.0},
		{&"what": &"cupola", &"t": 12.0, &"end": -1.0},
	]
	_report_scalar(TELEMETRY.uncovered_min(0.0, 18.0, live_acts), 6.0,
		"posa [0,18], coperti caffe[2,8]+cupola[12,18] → scoperti 6")
	_report_scalar(TELEMETRY.uncovered_min(-1.0, 18.0, live_acts), -1.0,
		"nessuna posa → -1")


func _report_scalar(got: float, expected: float, label: String) -> void:
	var note := "" if is_equal_approx(got, expected) else "   <-- ATTESO: %.1f" % expected
	print("      %-58s = %.1f%s" % [label, got, note])


func _report_merge(input: Array, expected: Array, label: String) -> void:
	var got := TELEMETRY.merge_intervals(input)
	var note := "" if _same_intervals(got, expected) else "   <-- ATTESO: %s" % str(expected)
	print("      %-52s = %s%s" % [label, str(got), note])


func _report_idle(windows: Array, covered: Array, expected: Array, label: String) -> void:
	var got := TELEMETRY.idle_segments(windows, covered)
	# expected è una lista di [t, dur]; got è una lista di {t, dur}.
	var got_pairs: Array = []
	for seg in got:
		got_pairs.append([float(seg[&"t"]), float(seg[&"dur"])])
	var note := "" if _same_intervals(got_pairs, expected) else "   <-- ATTESO: %s" % str(expected)
	print("      %-58s = %s%s" % [label, str(got_pairs), note])


## Uguaglianza fra liste di coppie `[a, b]` di float, ordine e valori (approx).
func _same_intervals(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for k in a.size():
		if not is_equal_approx(float(a[k][0]), float(b[k][0])):
			return false
		if not is_equal_approx(float(a[k][1]), float(b[k][1])):
			return false
	return true


func _report_field(report: Dictionary, key: StringName, expected: Variant, label: String) -> void:
	var got: Variant = report.get(key)
	var ok: bool
	if got is float and expected is float:
		ok = is_equal_approx(got, expected)
	else:
		ok = got == expected
	var note := "" if ok else "   <-- ATTESO: %s" % str(expected)
	print("   %-46s %s = %s%s" % [label, key, str(got), note])


func _report_activity(
	acts: Array, what: String, exp_t: float, exp_dur: Variant, exp_abandoned: bool, label: String
) -> void:
	var found: Dictionary = {}
	# La voce con questo `what` (nel report di test ce n'è una sola per what).
	for a in acts:
		if a.get(&"what") == what:
			found = a
			break
	var ok := not found.is_empty() and is_equal_approx(float(found.get(&"t")), exp_t) \
		and bool(found.get(&"abandoned", false)) == exp_abandoned
	if ok:
		if exp_dur == null:
			ok = found.get(&"dur") == null
		else:
			ok = found.get(&"dur") != null and is_equal_approx(float(found.get(&"dur")), float(exp_dur))
	var note := "" if ok else "   <-- ATTESO: t=%.1f dur=%s abandoned=%s" % [
		exp_t, str(exp_dur), exp_abandoned]
	print("      %-52s %s%s" % [label, "OK" if ok else "diverge", note])


func _report_idle_voice(acts: Array, exp_t: float, exp_dur: float, label: String) -> void:
	var found := false
	for a in acts:
		if a.get(&"what") == "idle" and is_equal_approx(float(a.get(&"t")), exp_t) \
			and is_equal_approx(float(a.get(&"dur")), exp_dur):
			found = true
			break
	var note := "" if found else "   <-- ATTESO: idle t=%.1f dur=%.1f" % [exp_t, exp_dur]
	print("      %-52s %s%s" % [label, "presente" if found else "ASSENTE", note])


## I forum della BBS (3.7): la logica PURA e collaudabile — il filtro `available(night)`
## per notte, il round-trip di `forum_read` sul save (i letti attraversano le notti), e il
## conteggio righe dell'a-capo su un corpo lungo (nessuna perdita di testo). Gemello di
## `_check_owned_items`/`_check_dome_presence`: nessuno SceneTree, nessun timer.
##
## La connessione (handshake), il disegno del vetro, lo scroll esplicito e la
## leggibilità a 256x192 NON si collaudano qui: sono effetto e percezione — verifiche
## d'operatore, che si camminano nel gioco (come dice lo spec). Il banco legge la tavola.
func _check_forum() -> void:
	print("-- Forum BBS: filtro per notte, round-trip forum_read, a-capo senza perdite (3.7)")

	# (1) ForumBoard.available(night): i messaggi compaiono col passare delle notti. Si
	# carica il FORUM VERO (`forum.tres`), non board a mano: è ciò che la BBS legge davvero.
	var forum := _load_source(FORUM_PATH) as ForumData
	if forum == null:
		return
	print("   dal .tres: %d aree" % forum.boards.size())
	if forum.boards.size() < 3:
		print("   <-- ATTESO: almeno 3 aree con voci diverse")

	# Ogni messaggio con `appears_from_night <= night` è disponibile; gli altri no. Il
	# conteggio dei disponibili non deve mai calare col crescere della notte (monotono), e
	# almeno un messaggio deve comparire DOPO la notte 1 (prova la comparsa nel tempo).
	var total_msgs := 0
	var appears_later := false
	for board in forum.boards:
		total_msgs += board.messages.size()
		for msg in board.messages:
			if msg != null and msg.appears_from_night > 1:
				appears_later = true
	print("   messaggi totali nel .tres: %d" % total_msgs)
	if not appears_later:
		print("   <-- ATTESO: almeno un messaggio con appears_from_night > 1")

	# Monotonìa e correttezza del filtro su una board: a notte più alta, mai meno messaggi.
	var previous := -1
	var monotonic := true
	for night in range(1, 6):
		var count := 0
		for board in forum.boards:
			var avail := board.available(night)
			count += avail.size()
			# Correttezza: ogni disponibile ha appears_from_night <= night; nessun assente
			# ha appears_from_night <= night.
			for msg in board.messages:
				var is_avail := avail.has(msg)
				var should := msg.appears_from_night <= night
				if is_avail != should:
					print("   <-- ATTESO: %s a notte %d disponibile=%s (appears_from_night=%d)" % [
						msg.id, night, should, msg.appears_from_night])
		if count < previous:
			monotonic = false
		print("   notte %d: %d messaggi visibili" % [night, count])
		previous = count
	if not monotonic:
		print("   <-- ATTESO: i messaggi visibili non calano mai col crescere della notte")

	# (2) PlayerProfile.has_read/mark_read + round-trip: un letto una notte resta letto la
	# notte dopo (attraversa il save). Stessa contabilità di owned_items — default [], nessun
	# bump di versione.
	var p := PlayerProfile.new()
	print("   il giocatore nasce senza niente letto: has_read = %s" % p.has_read(&"eq_newton_collimazione"))
	if p.has_read(&"eq_newton_collimazione"):
		print("   <-- ATTESO: un profilo nuovo non ha letto niente")

	p.mark_read(&"eq_newton_collimazione")
	print("   dopo mark_read: has_read(letto)=%s has_read(altro)=%s" % [
		p.has_read(&"eq_newton_collimazione"), p.has_read(&"ds_m13_estate")])
	if not p.has_read(&"eq_newton_collimazione") or p.has_read(&"ds_m13_estate"):
		print("   <-- ATTESO: legge quello marcato, non gli altri")

	# Idempotenza: leggere due volte non duplica.
	p.mark_read(&"eq_newton_collimazione")
	var dup_note := "" if p.forum_read.size() == 1 else "   <-- ATTESO: mark_read è idempotente"
	print("   mark_read due volte: forum_read = %s%s" % [p.forum_read, dup_note])

	# Round-trip su disco: i letti sopravvivono al save/load, come il possesso.
	var bench_dir := "user://saves/_bench_forum"
	var path := "%s/profile.tres" % bench_dir
	DirAccess.make_dir_recursive_absolute(bench_dir)
	var saves := SaveManager.new()
	p.mark_read(&"ds_m13_estate")
	saves.save_profile(p, path)
	var back := saves.load_profile(path)
	var round_ok := back.has_read(&"eq_newton_collimazione") and back.has_read(&"ds_m13_estate")
	print("   round-trip: has_read(a)=%s has_read(b)=%s" % [
		back.has_read(&"eq_newton_collimazione"), back.has_read(&"ds_m13_estate")])
	if not round_ok:
		print("   <-- ATTESO: i letti sopravvivono al .tres (attraversano le notti)")

	# Un profilo SENZA il campo (default []) è «niente letto», non un errore.
	var fresh := PlayerProfile.new()
	print("   default: forum_read vuoto = %s (assente = niente letto)" % fresh.forum_read.is_empty())
	if not fresh.forum_read.is_empty():
		print("   <-- ATTESO: default [] — nessun bump di versione")

	# Ripulire i file di banco.
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

	# (3) A-capo del corpo lungo: NESSUNA PERDITA DI TESTO. Si prende il messaggio più
	# lungo del forum, lo si manda a capo con la STESSA logica della BBS, e si verifica che
	# ricomponendo le righe si riottengano tutte le parole del corpo — nessuna riga
	# troncata in silenzio (l'AC che la 2.2 ha pagato). Lo scroll esplicito è d'operatore;
	# qui si prova che il testo non si perde.
	var longest: ForumMessage = null
	for board in forum.boards:
		for msg in board.messages:
			if msg != null and (longest == null or msg.body.length() > longest.body.length()):
				longest = msg
	if longest == null:
		print("   <-- ATTESO: almeno un messaggio nel forum")
		return
	var lines := _bbs_wrap(longest.body, BBS_WRAP_WIDTH)
	print("   messaggio più lungo (%s): %d caratteri -> %d righe a %d col" % [
		longest.id, longest.body.length(), lines.size(), BBS_WRAP_WIDTH])
	# Nessuna riga eccede la larghezza (a meno di una singola parola più lunga di width).
	var over := 0
	for line in lines:
		if line.length() > BBS_WRAP_WIDTH and line.find(" ") != -1:
			over += 1
	if over > 0:
		print("   <-- ATTESO: nessuna riga a più parole eccede %d col" % BBS_WRAP_WIDTH)
	# Nessuna parola persa: le parole del corpo (ignorando gli spazi e gli a-capo)
	# ricompaiono tutte nelle righe.
	var src_words := PackedStringArray()
	for token in longest.body.replace("\n", " ").split(" ", false):
		src_words.append(token)
	var out_words := PackedStringArray()
	for line in lines:
		for token in line.split(" ", false):
			out_words.append(token)
	var same_count := src_words.size() == out_words.size()
	print("   parole nel corpo: %d, parole nelle righe: %d" % [src_words.size(), out_words.size()])
	if not same_count:
		print("   <-- ATTESO: nessuna parola persa nell'a-capo (troncamento silenzioso)")
	# Almeno una board deve avere un messaggio che eccede una finestra ragionevole (prova
	# che lo scroll ha materiale su cui esercitarsi). BODY_WINDOW della BBS è 8.
	if lines.size() <= 8:
		print("   <-- ATTESO: almeno un messaggio più lungo del vetro (per provare lo scroll)")


## L'a-capo della BBS, RIPRODOTTO qui per collaudare che il corpo non si perda. È una
## copia della logica di `bbs.gd::_wrap` — la BBS non la espone (è privata al suo Control,
## e importarla vorrebbe dire montarlo). Se un giorno la BBS cambia il suo `_wrap`, questa
## copia va aggiornata: il banco collauda la FORMA dell'a-capo, non l'identità del codice.
func _bbs_wrap(text: String, width: int) -> PackedStringArray:
	var out := PackedStringArray()
	for paragraph in text.split("\n", true):
		if paragraph.is_empty():
			out.append("")
			continue
		var line := ""
		for word in paragraph.split(" ", false):
			if line.is_empty():
				line = word
			elif line.length() + 1 + word.length() <= width:
				line += " " + word
			else:
				out.append(line)
				line = word
		if not line.is_empty():
			out.append(line)
	return out


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


## Le stampe delle foto (D-239): quale immagine esce, e se il registro attraversa il disco.
##
## IL LIVELLO DELL'IMMAGINE NON È LO SCAGLIONE DEL PAGAMENTO: tre gradini fissi contro i
## cinque tarabili di `payout_tiers`. Si stampano i bordi, dove un `>` al posto di `>=`
## cambia foto.
##
## IL REGISTRO porta un `Transform3D` e chiavi `StringName`: si prova che il `.tres` li
## restituisca com'erano, perché una stampa che torna ruotata di un grado è storta sul muro.
func _check_prints() -> void:
	print("-- Le stampe: quale foto esce, e se il registro sopravvive al disco (D-239)")
	for caso: Array in [[0, 1], [49, 1], [50, 2], [79, 2], [80, 3], [100, 3]]:
		var t := Photo.image_tier(caso[0])
		print("   qualità %d -> immagine t%d" % [caso[0], t])
		if t != caso[1]:
			print("   <-- ATTESO: t%d" % caso[1])

	print("   un profilo nuovo ha %d stampe" % PlayerProfile.new().photo_prints.size())
	if not PlayerProfile.new().photo_prints.is_empty():
		print("   <-- ATTESO: si comincia senza stampe in giro")

	var bench_dir := "user://saves/_bench_stampe"
	var via := "%s/profile.tres" % bench_dir
	DirAccess.make_dir_recursive_absolute(bench_dir)
	var dove := Transform3D(Basis(Vector3.UP, 0.7), Vector3(6.2, 1.4, 0.11))
	var voci: Array[Dictionary] = [{
		&"target": &"m42", &"livello": 2, &"notte": 3, &"foto": 1,
		&"appesa": true, &"xf": dove, &"su": "Osservatorio/Muro", &"xf_su": dove,
	}]
	var p := PlayerProfile.new()
	p.photo_prints = voci
	var saves := SaveManager.new()
	saves.save_profile(p, via)
	var back := saves.load_profile(via)
	var v: Dictionary = back.photo_prints[0] if back.photo_prints.size() == 1 else {}
	var xf_back: Transform3D = v.get(&"xf", Transform3D())
	var xf_ok := xf_back.is_equal_approx(dove)
	var soggetto_ok: bool = v.get(&"target") is StringName and v.get(&"target") == &"m42"
	print("   round-trip: %d stampe, trasformata intatta %s, soggetto StringName %s, appesa %s" % [
		back.photo_prints.size(), xf_ok, soggetto_ok, v.get(&"appesa", false)])
	if back.photo_prints.size() != 1 or not xf_ok or not soggetto_ok or not v.get(&"appesa", false):
		print("   <-- ATTESO: una stampa, appesa, al millimetro e col soggetto StringName")
	DirAccess.remove_absolute(via)
	DirAccess.remove_absolute(bench_dir)


const BUS_PATH := "res://phases/startup/sources/honest_bus.tres"


## Un ingresso della fase dell'accensione, scritto a mano.
##
## `quando` è la maschera degli interruttori NELL'ISTANTE in cui si è tentata la
## porta di ciascun apparecchio: è il campo su cui gira tutta questa fase, e
## costruirlo a mano è il solo modo di collaudarla senza montare niente.
func _bus_input(powered: int, attempted: int, quando: Array) -> StartupInput:
	var i := StartupInput.new()
	i.powered = powered
	i.attempted = attempted
	i.powered_when = PackedInt32Array(quando)
	return i


func _check_honest_bus() -> void:
	print("-- HonestBus: risponde chi aveva corrente quando gli hai aperto la porta")
	var src := _load_source(BUS_PATH) as HonestBus
	if src == null:
		return
	print("   dal .tres: fed_by = %s (la ruota prende corrente dalla camera)"
		% str(src.fed_by))

	var mount := 1
	var camera := 2
	var filter := 4

	# Determinismo: `delta` non deve entrare da nessuna parte.
	var i_det := _bus_input(mount, mount, [mount, 0, 0])
	var a := src.sample(i_det, 0.016)
	var b := src.sample(i_det, 0.99)
	print("   sample(i, 0.016) = %d, sample(i, 0.99) = %d -> %s"
		% [a, b, "DETERMINISTICA" if a == b
			else "NON deterministica  <-- ATTESO: deterministica"])

	var casi := [
		["nessuna porta aperta: non risponde nessuno",
			_bus_input(mount | camera, 0, [0, 0, 0]), 0],
		["montatura accesa e collegata",
			_bus_input(mount, mount, [mount, 0, 0]), mount],
		["collegata da spenta, accesa DOPO: la porta resta muta",
			_bus_input(mount, mount, [0, 0, 0]), 0],
		["ruota collegata con la camera accesa",
			_bus_input(camera, filter, [0, 0, camera]), filter],
		["ruota collegata con la camera spenta, camera accesa dopo",
			_bus_input(camera, filter, [0, 0, 0]), 0],
		["ruota collegata bene, poi la camera si spegne",
			_bus_input(0, filter, [0, 0, camera]), 0],
		["tutto acceso e tutto collegato",
			_bus_input(mount | camera, mount | camera | filter,
				[mount, camera, mount | camera]), mount | camera | filter],
	]
	for caso in casi:
		var atteso: int = caso[2]
		var avuto: int = src.sample(caso[1], 0.016)
		print("   %-52s -> %d%s" % [caso[0], avuto,
			"" if avuto == atteso else "   <-- ATTESO: %d" % atteso])


const PELTIER_PATH := "res://phases/cooling/sources/honest_peltier.tres"


func _cooling_input(setpoint: float, temperature: float, t: float) -> CoolingInput:
	var i := CoolingInput.new()
	i.setpoint = setpoint
	i.temperature = temperature
	i.seconds_running = t
	return i


func _check_honest_peltier() -> void:
	print("-- HonestPeltier: la cella scende di tanto sotto l'ambiente, e non di piu'")
	var src := _load_source(PELTIER_PATH) as HonestPeltier
	if src == null:
		return
	var fondo := src.floor_temperature()
	print("   dal .tres: ambiente %+.1f, salto massimo %.1f -> fondo %+.1f"
		% [src.ambient, src.max_drop, fondo])

	# Determinismo: `delta` non deve entrare da nessuna parte.
	var i_det := _cooling_input(-20.0, 0.0, 3.0)
	var a := src.sample(i_det, 0.016)
	var b := src.sample(i_det, 0.99)
	print("   sample(i, 0.016) = %+.4f, sample(i, 0.99) = %+.4f -> %s"
		% [a, b, "DETERMINISTICA" if is_equal_approx(a, b)
			else "NON deterministica  <-- ATTESO: deterministica"])

	# Chiedendo entro i margini si ottiene quello che si e' chiesto.
	var dentro := _cooling_input(fondo + 6.0, fondo + 6.0, 5.0)
	var v := src.sample(dentro, 0.016)
	print("   arrivati a un setpoint raggiungibile, la velocita' e' %+.4f gradi/s%s"
		% [v, "" if is_zero_approx(v) else "   <-- ATTESO: 0, ci si resta"])

	# Chiedendo oltre il fondo NON ci si arriva, e si ondeggia: due istanti diversi
	# dello stesso ciclo devono dare due equilibri diversi.
	var t1 := src.equilibrium(_cooling_input(fondo - 20.0, fondo, 0.0))
	var t2 := src.equilibrium(_cooling_input(fondo - 20.0, fondo, src.wobble_period * 0.25))
	print("   chiedendo venti gradi oltre il fondo: equilibrio %+.2f e %+.2f%s"
		% [t1, t2, "" if absf(t2 - t1) > 0.3
			else "   <-- ATTESO: due istanti diversi, due valori diversi"])
	if mini(roundi(t1 * 100.0), roundi(t2 * 100.0)) < roundi((fondo - src.wobble - 0.01) * 100.0):
		print("   ma si scende sotto il fondo  <-- ATTESO: il fondo e' un fondo")

	# La cella lavora in proporzione a quello che le si chiede, e satura.
	var poco := src.duty(_cooling_input(src.ambient - 10.0, 0.0, 0.0))
	var tanto := src.duty(_cooling_input(fondo, 0.0, 0.0))
	var troppo := src.duty(_cooling_input(fondo - 30.0, 0.0, 0.0))
	print("   cella: dieci gradi sotto l'ambiente %d%%, al fondo %d%%, oltre %d%%%s"
		% [roundi(poco * 100.0), roundi(tanto * 100.0), roundi(troppo * 100.0),
			"" if poco < tanto and is_equal_approx(tanto, troppo) and is_equal_approx(troppo, 1.0)
			else "   <-- ATTESO: cresce, e si ferma al 100%"])

	# LA DISCESA, integrata come la integra la fase: quanto ci mette ad arrivare.
	# Il passo e' fisso perche' una misura che dipende dal frame rate non e' una
	# misura.
	var passo := 1.0 / 60.0
	var bersaglio := fondo + 4.0
	var caso := _cooling_input(bersaglio, src.ambient_temperature(), 0.0)
	var secondi := 0.0
	while absf(caso.temperature - bersaglio) > 0.1 and secondi < 300.0:
		caso.temperature += src.sample(caso, passo) * passo
		caso.seconds_running = secondi
		secondi += passo
	var lunga := secondi > 90.0
	print("   dall'ambiente a %+.0f gradi: %.1f s%s"
		% [bersaglio, secondi,
			"   <-- nota: piu' di un minuto e mezzo di attesa" if lunga else ""])


## LA LUNA DEL CALENDARIO: le copie che `core/luna.gd` è costretta a tenere, e
## l'almanacco che dice se il modello è un modello.
##
## PERCHÉ QUI E NON SOLO NELLA SONDA. `tools/prova_luna.gd` fa tutto questo e di
## più, ma ha bisogno di montare `main.tscn`; queste sono funzioni STATICHE e pure
## — nessun SceneTree, nessun autoload — ed è esattamente la roba che questo banco
## esiste per collaudare. Le tre copie qui sotto sono dichiarate come copie nei
## commenti di `core/luna.gd`, con la promessa che il banco le confronti: questa è
## quella promessa.
##
## `core/` NON PUÒ DIPENDERE DA NIENTE (tabella dei confini), quindi la Luna
## ricopia l'ora d'inizio della notte da `NightClock` e la latitudine e la
## trigonometria sferica da `SkyGeometry`. Se divergessero, il gioco avrebbe una
## Luna che sorge a un'ora che l'orologio non ha, vista da un osservatorio che non
## è quello dove il planetario cerca le stelle — e ciascuno dei due file
## continuerebbe ad avere ragione da solo.
func _check_luna() -> void:
	print("-- Luna: il calendario, le copie e l'almanacco del 1999")
	print("   ora d'inizio: Luna %d, NightClock %d%s"
		% [Luna.ORA_INIZIO, CLOCK.NIGHT_START_HOUR,
			"" if Luna.ORA_INIZIO == CLOCK.NIGHT_START_HOUR
			else "   <-- ATTESO: uguali, la Luna sorge sull'orologio del gioco"])
	print("   latitudine:   Luna %.2f, SkyGeometry %.2f%s"
		% [Luna.LATITUDINE, SkyGeometry.LATITUDINE,
			"" if is_equal_approx(Luna.LATITUDINE, SkyGeometry.LATITUDINE)
			else "   <-- ATTESO: uguali, e' lo stesso osservatorio"])

	# LE DUE TRIGONOMETRIE SFERICHE, confrontate su un campione che copre tutto il
	# cielo raggiungibile: da est a ovest, da sotto l'equatore al circumpolare.
	var peggio := 0.0
	for ha in [-120.0, -90.0, -45.0, 0.0, 45.0, 90.0, 120.0]:
		for dec in [-25.0, -5.0, 20.0, 40.0, 60.0, 80.0]:
			peggio = maxf(peggio, absf(Luna.alt_az(ha, dec).x - SkyGeometry.altezza(ha, dec)))
	print("   altezza sull'orizzonte: scarto massimo fra le due copie %.6f gradi%s"
		% [peggio, "" if peggio < 0.0001
			else "   <-- ATTESO: zero, e' la stessa formula scritta due volte"])

	# IL CALENDARIO: una notte, un giorno. La prima e la trentesima.
	print("   notte 1 = %s, notte 30 = %s"
		% [Luna.data_scritta(1), Luna.data_scritta(30)])
	if Luna.data(1) != Vector3i(1999, 11, 16):
		print("   la prima notte non e' il 16 novembre 1999  <-- il calendario e' scivolato")
	if Luna.data(30) != Vector3i(1999, 12, 15):
		print("   trenta notti non fanno ventinove giorni  <-- l'aritmetica giuliana e' rotta")

	# L'ALMANACCO, due date su sei: la sonda le fa tutte, qui bastano gli estremi
	# del ciclo. Sono valori PUBBLICATI, non prodotti da questo codice — ed e' la
	# sola differenza fra collaudare un modello e ammirarlo.
	_report_luna("novilunio  8 nov 1999 03:53 UT", 1999, 11, 8, 3.88, 180.0)
	_report_luna("plenilunio 23 nov 1999 07:04 UT", 1999, 11, 23, 7.07, 0.0)

	# LA FACCIA GIRATA DALLA PARTE DELLA LUCE. È un invariante fisico che non
	# dipende da come sono orientati gli assi del mondo: finché la Luna cresce, sul
	# suo lato visibile è mattina, e il Sole sta a EST della Luna — dalla parte di
	# Mare Crisium, che è infatti la prima cosa che la falce giovane mostra. Quando
	# cala, sta a ovest. Se il segno della cornice fosse sbagliato, la faccia
	# uscirebbe girata al contrario della propria luce e i crateri illuminati
	# sarebbero quelli sbagliati, con la fase perfettamente giusta.
	var cresce := Luna.effemeridi(Luna.istante(1, 0.0))
	var cala := Luna.effemeridi(Luna.istante(13, 480.0))
	var d_cresce := Vector3(cresce[&"luna_est"]).dot(Vector3(cresce[&"sole_dir"]))
	var d_cala := Vector3(cala[&"luna_est"]).dot(Vector3(cala[&"sole_dir"]))
	print("   il Sole sull'est della Luna: crescente %+.2f, calante %+.2f%s"
		% [d_cresce, d_cala, "" if d_cresce > 0.0 and d_cala < 0.0
			else "   <-- ATTESO: + e -, altrimenti la faccia e' girata contro la luce"])
	print("   verso del mondo: %+.0f%s" % [Luna.chiralita(), "" if Luna.chiralita() > 0.0
		else "   <-- nota: la convenzione est = +X e' specchiata rispetto al cielo vero"])


## Una data d'almanacco: l'angolo di fase che il modello ci trova, contro quello
## che ci deve essere. Dodici gradi di fase al giorno, quindi lo scarto in gradi
## si legge anche in minuti d'orologio — che e' l'unita' in cui un errore qui
## diventa «la luna piena e' il giorno sbagliato».
func _report_luna(label: String, anno: int, mese: int, giorno: int,
		ora_ut: float, atteso: float) -> void:
	var jd := float(Luna.giuliano_di(anno, mese, giorno)) - 0.5 + ora_ut / 24.0
	var e := Luna.effemeridi(jd)
	var scarto := absf(fposmod(float(e[&"fase"]) - atteso + 180.0, 360.0) - 180.0)
	print("   %-32s fase %6.2f (attesa %.0f), scarto %.2f gradi = %.0f minuti%s"
		% [label, e[&"fase"], atteso, scarto, scarto / 12.19 * 1440.0,
			"" if scarto < 0.5 else "   <-- ATTESO: sotto mezzo grado, cioe' sotto l'ora"])


## I PIANETI: il Sole calcolato due volte, l'almanacco del 1999 e la regola che
## decide chi si vede.
##
## PERCHÉ QUI E NON SOLO NELLA SONDA. `tools/prova_pianeti.gd` fa tutto questo e
## di più, ma ha bisogno di montare `main.tscn` per arrivare al materiale del
## cielo; queste sono funzioni STATICHE e pure — effemeridi e visibilità — ed è
## esattamente la roba che questo banco esiste per collaudare.
##
## IL SOLE DUE VOLTE È LA PROVA CHE NON COSTA NIENTE. `core/luna.gd` lo calcola
## con la serie di Meeus, `core/pianeti.gd` lo ricava dall'orbita della Terra:
## due modelli scritti in due momenti diversi per due scopi diversi, che devono
## dare lo stesso Sole. Se divergessero, la Luna sarebbe illuminata da una parte
## e le fasi di Venere dall'altra, e ciascuno dei due file continuerebbe ad avere
## ragione da solo — che è lo stesso guasto delle copie della Luna, scoperto con
## lo stesso metodo.
func _check_pianeti() -> void:
	print("-- Pianeti: il Sole due volte, l'almanacco del 1999, chi si vede")

	# I DUE SOLI, su quattro istanti del mese di lavoro.
	var peggio := 0.0
	for notte in [1, 15, 30]:
		for minuti in [0.0, 240.0, 480.0]:
			var jd := Luna.istante(notte, minuti)
			peggio = maxf(peggio, rad_to_deg(Vector3(Luna.effemeridi(jd)[&"sole_dir"])
				.angle_to(Vector3(Pianeti.sole(jd)[&"dir"]))))
	print("   il Sole: Luna contro Pianeti, scarto massimo %.4f gradi%s"
		% [peggio, "" if peggio < 0.05
			else "   <-- ATTESO: sotto il ventesimo di grado, e' lo stesso Sole"])

	# L'ALMANACCO: le due opposizioni del 1999, cercate come massimo
	# dell'elongazione in una finestra di cinque giorni. Sono date PUBBLICATE.
	_report_opposizione("Giove all'opposizione, 23 ottobre 1999", &"giove", 1999, 10, 23)
	_report_opposizione("Saturno all'opposizione, 6 novembre 1999", &"saturno", 1999, 11, 6)

	# GLI INVARIANTI DEI DUE INTERNI: quanto si staccano dal Sole. Cinque anni
	# sono venti congiunzioni di Mercurio, abbastanza perché il massimo ci capiti
	# dentro. Un pianeta interno con l'orbita sbagliata sfonda questi numeri
	# subito, e nessun'altra prova se ne accorgerebbe.
	var inizio := float(Luna.giuliano_di(1996, 1, 1)) - 0.5
	var massimi := {&"mercurio": 0.0, &"venere": 0.0}
	for giorno in 1825:
		for e in Pianeti.effemeridi(inizio + float(giorno)):
			if massimi.has(e[&"nome"]):
				massimi[e[&"nome"]] = maxf(massimi[e[&"nome"]], float(e[&"elongazione"]))
	print("   massima elongazione dal Sole: Mercurio %.2f (attesa 26,5-28,5), Venere %.2f (45-48)%s"
		% [massimi[&"mercurio"], massimi[&"venere"],
			"" if massimi[&"mercurio"] > 26.5 and massimi[&"mercurio"] < 28.5
				and massimi[&"venere"] > 45.0 and massimi[&"venere"] < 48.0
			else "   <-- ATTESO: dentro, o l'orbita di un interno e' sbagliata"])

	# CHI SI VEDE: la regola, sulla funzione pura. Un pianeta tramontato non si
	# disegna; uno basso vale molto meno di uno alto; con la luna piena il debole
	# in basso sparisce e Venere no.
	var sotto := PianetiInCielo.luce_di({&"alt": -1.0, &"magnitudine": -4.3}, 0.0)
	var alto := PianetiInCielo.luce_di({&"alt": 60.0, &"magnitudine": -2.7}, 0.0)
	var basso := PianetiInCielo.luce_di({&"alt": 1.0, &"magnitudine": -2.7}, 0.0)
	print("   Giove (mag -2,7): a 60 gradi %.3f, a 1 grado %.3f; Venere tramontata %.3f%s"
		% [alto, basso, sotto, "" if is_zero_approx(sotto) and basso < alto
			else "   <-- ATTESO: tramontata zero, e in basso meno che in alto"])
	var debole_luna := PianetiInCielo.luce_di({&"alt": 5.0, &"magnitudine": 0.2}, 1.0)
	var venere_luna := PianetiInCielo.luce_di({&"alt": 5.0, &"magnitudine": -4.3}, 1.0)
	print("   a 5 gradi con la luna piena: mag +0,2 %.3f, mag -4,3 %.3f%s"
		% [debole_luna, venere_luna,
			"" if is_zero_approx(debole_luna) and venere_luna > 0.0
			else "   <-- ATTESO: il debole sparisce, Venere resta"])

	# L'ORDINE È UN PATTO FRA TRE FILE: `Pianeti.ORDINE` decide chi e' l'indice
	# 3 nell'array dello shader, e i colori devono seguirlo. Un colore mancante
	# vorrebbe dire un pianeta disegnato nero, cioe' invisibile senza errori.
	var senza_colore := PackedStringArray()
	for nome in Pianeti.ORDINE:
		if not PianetiInCielo.COLORI.has(nome):
			senza_colore.append(String(nome))
	print("   i cinque nomi, i cinque colori: %d e %d%s"
		% [Pianeti.ORDINE.size(), PianetiInCielo.COLORI.size(),
			"" if senza_colore.is_empty()
			else "   <-- senza colore: " + ", ".join(senza_colore)])


## Un'opposizione d'almanacco: si cerca il massimo dell'elongazione attorno alla
## data pubblicata e si guarda di quanto scivola. Un giorno di scarto e' il
## respiro di un massimo piatto; una settimana vorrebbe dire il pianeta
## dall'altra parte del cielo.
func _report_opposizione(label: String, nome: StringName, anno: int, mese: int,
		giorno: int) -> void:
	var atteso := float(Luna.giuliano_di(anno, mese, giorno)) - 0.5
	var meglio := -1.0
	var quando := 0.0
	for passo in range(-120, 121):
		var jd := atteso + float(passo) / 24.0
		for e in Pianeti.effemeridi(jd):
			if e[&"nome"] == nome and float(e[&"elongazione"]) > meglio:
				meglio = float(e[&"elongazione"])
				quando = jd
	var scarto := quando - atteso
	print("   %-40s massimo %.2f gradi, a %+.1f ore dalla data pubblicata%s"
		% [label, meglio, scarto * 24.0, "" if absf(scarto) < 1.5
			else "   <-- ATTESO: dentro il giorno e mezzo"])


## Le schede del software di ripresa (D-232): quale casella del piano è in corso, e le
## etichette che le fasi danno di sé.
##
## L'INDICE È UNA SOTTRAZIONE, e proprio per questo si collauda: l'orchestratore avanza
## l'indice nel momento in cui prende la scena, e un «meno uno» dimenticato evidenzia la
## scheda dopo quella giusta — un difetto che a occhio sembra un ritardo e non un errore.
##
## LE ETICHETTE NON SI ELENCANO QUI, e non per pigrizia: un elenco copiato invecchierebbe
## al primo upgrade che toglie una fase dal `.tres`. Si collauda ciò che deve valere per
## qualunque piano — ci stanno in una scheda, non sono vuote, non si ripetono.
func _check_work_tabs() -> void:
	print("--- schede della finestra di lavoro ---")
	var casi := [
		[true, 1, 0, 4, 0, "prima fase di setup"],
		[true, 4, 0, 4, 3, "ultima fase di setup"],
		[false, 4, 1, 4, 4, "prima fase di foto"],
		[false, 4, 4, 4, 7, "ultima fase di foto"],
	]
	for c in casi:
		var got := NightPlan.tab_index(c[0], c[1], c[2], c[3])
		print("   %-22s -> %d%s" % [c[5], got, "" if got == c[4] else "   <-- ATTESO: %d" % c[4]])

	var plan := load("res://data/night_plan.tres") as NightPlan
	if plan == null:
		print("   piano assente  <-- ATTESO: data/night_plan.tres")
		return
	var labels := PackedStringArray()
	for scene in plan.setup_phases + plan.photo_phases:
		var node: Node = scene.instantiate()
		var phase := node as Phase
		labels.append(phase.tab_label() if phase != null else "?")
		node.free()
	var storte := PackedStringArray()
	var viste := {}
	for l in labels:
		if l == "" or l == "?" or l.length() > 6 or viste.has(l):
			storte.append(l)
		viste[l] = true
	print("   etichette del piano: %s%s" % [" ".join(labels),
			"" if storte.is_empty() else "   <-- ATTESO: non vuote, al massimo 6 lettere, uniche; storte: %s" % " ".join(storte)])


## Le misure del desktop (D-232). Sono conti, non resa: che si LEGGA si guarda con
## `tools/prova_desktop.tscn`. Qui si collauda che le cose CI STIANO — un pannello da
## 256x192 dentro la finestra di lavoro con le schede, e quella finestra dentro il vetro.
func _check_desktop_window() -> void:
	print("--- finestre del desktop ---")
	var look := DesktopTheme.new()

	var w := DesktopWindow.new()
	w.setup(look, "Terminal", Vector2(264, 218), &"terminal")
	var c := w.client_rect().size
	print("   area utile di una finestra 264x218: %s%s" % [c,
			"" if c == Vector2(256, 192) else "   <-- ATTESO: (256, 192)"])
	var sovrapposti := w.rect_close().intersects(w.rect_maximize()) \
			or w.rect_maximize().intersects(w.rect_minimize())
	var dentro := Rect2(Vector2.ZERO, w.size).encloses(w.rect_minimize())
	print("   i tre pulsanti non si toccano e stanno dentro: %s%s" % [not sovrapposti and dentro,
			"" if not sovrapposti and dentro else "   <-- ATTESO: true"])
	w.free()

	var work := DesktopWindow.new()
	work.setup(look, "MaxIm DL", Desktop.WORK_SIZE, Desktop.WORK_ID)
	work.tabs = PackedStringArray(["DOME", "BOOT", "COOL", "SOLVE", "TARGET", "GOTO", "FOCUS", "SEQ"])
	var wc := work.client_rect().size
	print("   finestra di lavoro %s, area utile %s%s" % [Desktop.WORK_SIZE, wc,
			"" if wc.x >= 256.0 and wc.y >= 192.0 else "   <-- ATTESO: almeno (256, 192)"])
	var ultima := work.rect_tab(work.tabs.size() - 1)
	var stanno := ultima.end.x <= work.size.x - DesktopWindow.BORDER + 0.5
	print("   otto schede nella larghezza: %s%s" % [stanno, "" if stanno else "   <-- ATTESO: true"])
	# Il ritorno da massimizzata torna ALLA MISURA DI PRIMA. Non è ovvio: un Control non
	# scende sotto il suo `custom_minimum_size`, e con l'ordine sbagliato tornava largo
	# quanto il vetro.
	var prima := work.size
	work.toggle_maximize(Rect2(0, 0, 352, 236))
	var grande := work.size
	work.toggle_maximize(Rect2(0, 0, 352, 236))
	var torna := work.size == prima and grande == Vector2(352, 236)
	print("   massimizza e ritorno: %s -> %s -> %s%s" % [prima, grande, work.size,
			"" if torna else "   <-- ATTESO: (352, 236) e poi di nuovo %s" % prima])
	work.free()

	var d := Desktop.new()
	d.setup(look, Vector2(352, 264))
	var entra := d.work_area().encloses(Rect2(Desktop.WORK_POS, Desktop.WORK_SIZE))
	print("   finestra di lavoro dentro il vetro 352x264: %s%s" % [entra, "" if entra else "   <-- ATTESO: true"])
	d.free()


## Il quaderno delle procedure (D-233): ogni pagina sta sulla carta, e ogni fase del
## piano della notte ha la sua pagina.
##
## LA CARTA SI MISURA IN COLONNE, non guardando: `QuadernoData.a_capo()` è la stessa
## funzione con cui il quaderno impagina, quindi una pagina che qui sborda sborda anche
## in partita. Che si LEGGA lo dice lo scatto di `tools/prova_quaderno.gd`.
##
## E LE FASI SI CONTANO DAL PIANO VERO, come `_check_work_tabs`: il giorno che una fase
## entra nel `.tres` senza la sua pagina, il quaderno smette di dire la verità in
## silenzio — qui lo si scopre.
func _check_quaderno() -> void:
	print("-- Quaderno delle procedure: pagine dentro il foglio, una pagina per fase (D-233)")

	# L'a capo: una riga che ci sta resta com'è, spazi di allineamento compresi; una
	# lunga va a capo alla parola e tiene il rientro.
	var tabella := QuadernoData.a_capo("  W A S D   cammina", 20)
	print("   riga di tabella: \"%s\"%s" % [tabella[0],
		"" if tabella.size() == 1 and tabella[0] == "  W A S D   cammina" else "   <-- ATTESO: intatta"])
	var lunga := QuadernoData.a_capo("  una riga lunga che deve andare a capo", 20)
	var rientro_ok := lunga.size() > 1
	for r in lunga:
		rientro_ok = rientro_ok and r.begins_with("  ") and r.length() <= 20
	print("   riga lunga: %s%s" % [" | ".join(lunga),
		"" if rientro_ok else "   <-- ATTESO: a capo entro 20, rientro tenuto"])

	# La voce dell'indice è lunga una riga esatta con il numero in fondo, anche quando il
	# titolo da solo non ci starebbe.
	var voce := QuadernoData.voce_indice("Come muoversi", 3, 2)
	var voce_ok := voce.length() == QuadernoData.COLONNE and voce.ends_with(" 3")
	print("   voce d'indice: \"%s\"%s" % [voce,
		"" if voce_ok else "   <-- ATTESO: %d colonne, numero in fondo" % QuadernoData.COLONNE])
	var lunga_voce := QuadernoData.voce_indice("un titolo che da solo è più lungo di tutta la riga", 12, 2)
	var lunga_ok := lunga_voce.length() == QuadernoData.COLONNE and lunga_voce.ends_with(" 12")
	print("   titolo troppo lungo: \"%s\"%s" % [lunga_voce,
		"" if lunga_ok else "   <-- ATTESO: accorciato, numero in fondo"])

	var dati := _load_source(QUADERNO_PATH) as QuadernoData
	if dati == null:
		return
	print("   dal .tres: %d pagine, carta da %d colonne per %d righe" % [
		dati.pagine.size(), QuadernoData.COLONNE, QuadernoData.RIGHE])
	var sbordano := dati.pagine_che_sbordano()
	for coppia in sbordano:
		print("   pagina %d: %d righe   <-- ATTESO: al massimo %d" % [
			coppia[0] + 1, coppia[1], QuadernoData.RIGHE])
	if sbordano.is_empty():
		print("   nessuna pagina esce dal foglio (indice compreso)")

	# L'INDICE È UNO, E OGNI NUMERO PORTA ALLA SUA PAGINA: si rilegge ogni voce, si
	# prende il numero in fondo e si guarda che quella pagina abbia quel titolo. È il
	# controllo che scopre un indice sfasato di uno rispetto al `- n -` stampato.
	var indici := PackedInt32Array()
	for i in dati.pagine.size():
		if dati.pagine[i] != null and dati.pagine[i].indice:
			indici.append(i)
	if indici.size() != 1:
		print("   pagine d'indice: %d   <-- ATTESO: una" % indici.size())
	else:
		var voci := dati.righe_indice(indici[0])
		var storte := PackedStringArray()
		for riga in voci:
			var numero := riga.substr(riga.rfind(" ") + 1).to_int()
			var giusta := (numero >= 1 and numero <= dati.pagine.size()
				and riga.begins_with(dati.pagine[numero - 1].titolo + " "))
			if not giusta:
				storte.append(riga)
		print("   indice a pagina %d: %d voci%s" % [indici[0] + 1, voci.size(),
			"" if storte.is_empty() else "   <-- ATTESO: ogni numero alla sua pagina (%s)" % " | ".join(storte)])

	var plan := load("res://data/night_plan.tres") as NightPlan
	if plan == null:
		print("   piano assente  <-- ATTESO: data/night_plan.tres")
		return
	var spiegate := dati.fasi_spiegate()
	var mancano := PackedStringArray()
	for scene in plan.setup_phases + plan.photo_phases:
		var node: Node = scene.instantiate()
		var phase := node as Phase
		if phase != null and not spiegate.has(phase.key()):
			mancano.append(String(phase.key()))
		node.free()
	print("   fasi del piano senza pagina: %s%s" % [
		"nessuna" if mancano.is_empty() else ", ".join(mancano),
		"" if mancano.is_empty() else "   <-- ATTESO: una pagina per ogni fase"])


## Il prato (D-249): piatto dove qualcosa poggia a terra, mai sotto la quota dei
## pavimenti, mai più ripido di quanto si cammini, e senza erba dentro i muri.
##
## LE IMPRONTE SI LEGGONO DALLA SCENA GENERATA, non si ribattono qui: è la scena che il
## gioco carica, e un'impronta ricopiata resterebbe giusta il giorno che l'edificio si
## sposta. Si legge lo STATO del .tscn, senza istanziarlo: basta il nodo `Prato`.
func _check_prato() -> void:
	print("-- Prato: piatto dove si poggia, mai sotto zero, pendenze, erba fuori dai muri (D-249)")
	const PENDENZA_MASSIMA := 0.35
	var prato := Prato.new()
	var stato := (load("res://world/blockout.tscn") as PackedScene).get_state()
	var trovato := false
	for i in stato.get_node_count():
		if stato.get_node_name(i) != "Prato":
			continue
		trovato = true
		for k in stato.get_node_property_count(i):
			var nome := stato.get_node_property_name(i, k)
			if nome in ["estensione", "recinto", "piatti", "senza_erba", "seme", "ciuffi_per_m2"]:
				prato.set(nome, stato.get_node_property_value(i, k))
	var est := prato.estensione
	var rec := prato.recinto
	var piatti := prato.piatti
	var senza := prato.senza_erba
	var seme := prato.seme
	var densita := prato.ciuffi_per_m2
	prato.free()
	if not trovato:
		print("   nessun nodo Prato in blockout.tscn   <-- ATTESO: rigenerare con tools/gen_blockout.py")
		return
	print("   prato %s, recinto %s, %d impronte piatte" % [est, rec, piatti.size()])

	# Sulle impronte il terreno è a zero: agli angoli, a metà dei lati e al centro.
	var sollevati := 0
	for r in piatti:
		for p in [r.position, r.end, r.get_center(), Vector2(r.position.x, r.end.y),
				Vector2(r.end.x, r.position.y)]:
			if absf(FormaPrato.altezza(p, piatti, rec)) > 1e-6:
				sollevati += 1
	print("   punti delle impronte sollevati: %d%s" % [sollevati,
		"" if sollevati == 0 else "   <-- ATTESO: 0, l'edificio o l'auto non poggerebbero"])

	var q := FormaPrato.quote(est, piatti, rec)
	var n := FormaPrato.vertici(est)
	var minimo := INF
	var massimo := -INF
	var ripida := 0.0
	for j in n.y:
		for i in n.x:
			var h := q[j * n.x + i]
			minimo = minf(minimo, h)
			massimo = maxf(massimo, h)
			if i + 1 < n.x:
				ripida = maxf(ripida, absf(q[j * n.x + i + 1] - h) / FormaPrato.PASSO)
			if j + 1 < n.y:
				ripida = maxf(ripida, absf(q[(j + 1) * n.x + i] - h) / FormaPrato.PASSO)
	print("   quote da %.2f a %.2f m%s" % [minimo, massimo,
		"" if minimo >= 0.0 else "   <-- ATTESO: mai sotto zero, il recinto resterebbe sospeso"])
	print("   pendenza massima %.0f%% (%.1f gradi)%s" % [ripida * 100.0, rad_to_deg(atan(ripida)),
		"" if ripida <= PENDENZA_MASSIMA else "   <-- ATTESO: al massimo %.0f%%" % (PENDENZA_MASSIMA * 100.0)])

	# LA QUOTA SU CUI SI POSANO I CIUFFI È QUELLA DELLA MAGLIA: dentro un quadrato non
	# esce mai dalle quote dei suoi quattro vertici, e su un vertice è la sua.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var fuori_maglia := 0
	for _k in 300:
		var p := est.position + Vector2(rng.randf() * est.size.x, rng.randf() * est.size.y)
		var i := mini(int((p.x - est.position.x) / FormaPrato.PASSO), n.x - 2)
		var j := mini(int((p.y - est.position.y) / FormaPrato.PASSO), n.y - 2)
		var quattro := [q[j * n.x + i], q[j * n.x + i + 1], q[(j + 1) * n.x + i], q[(j + 1) * n.x + i + 1]]
		var h := FormaPrato.quota(p, est, q)
		if h < float(quattro.min()) - 1e-5 or h > float(quattro.max()) + 1e-5:
			fuori_maglia += 1
	var sul_vertice := absf(FormaPrato.quota(est.position + Vector2(17, 23) * FormaPrato.PASSO, est, q)
		- q[23 * n.x + 17])
	print("   quota sulla maglia: %d punti su 300 fuori dai loro vertici, %.6f m su un vertice%s" % [
		fuori_maglia, sul_vertice,
		"" if fuori_maglia == 0 and sul_vertice < 1e-5 else "   <-- ATTESO: 0 e 0, i ciuffi galleggerebbero"])

	var ciuffi := FormaPrato.ciuffi(seme, densita, est, senza)
	var dentro := 0
	for c in ciuffi:
		if FormaPrato._escluso(c[0], senza):
			dentro += 1
	var ancora := FormaPrato.ciuffi(seme, densita, est, senza)
	var uguali: bool = ancora.size() == ciuffi.size() and (ciuffi.is_empty() or ancora[0][0] == ciuffi[0][0])
	print("   %d ciuffi, %d dentro l'edificio o sotto l'auto, stesso seme stesso prato: %s%s" % [
		ciuffi.size(), dentro, uguali,
		"" if dentro == 0 and uguali and ciuffi.size() > 1000 else "   <-- ATTESO: migliaia, 0, true"])

	# IL LATO DEL CIUFFO È SCRITTO IN DUE FILE, uno GDScript e uno Python: si legge il
	# secondo e si confrontano. Diversi, l'erba sarebbe tutta più grande o più piccola.
	var sorgente := FileAccess.get_file_as_string("res://tools/erba_blender.py")
	var trovata := RegEx.create_from_string("(?m)^LATO_M = ([0-9.]+)").search(sorgente)
	var lato := float(trovata.get_string(1)) if trovata != null else -1.0
	print("   lato del ciuffo: gioco %.2f, fotografia %.2f%s" % [Prato.LATO_CIUFFO, lato,
		"" if is_equal_approx(lato, Prato.LATO_CIUFFO) else "   <-- ATTESO: uguali in world/prato.gd e tools/erba_blender.py"])
	var foto := FileAccess.file_exists(Prato.TEXTURE_CIUFFI)
	print("   texture dei ciuffi: %s%s" % ["c'è" if foto else "manca",
		"" if foto else "   <-- ATTESO: lancia tools/erba_blender.py"])
