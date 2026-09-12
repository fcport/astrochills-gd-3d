## SVITANDO LA CAMERA A META' POSA, la sequenza muore o continua a contare frame?
##
## LA DOMANDA, E PERCHE' NON E' TEORICA. La posa gira in background APPOSTA: si
## preme START e ci si alza, perche' l'attesa e' il cuore della notte. Ma la strada
## che porta via dalla postazione porta anche in cupola, e in cupola c'e' il
## focheggiatore con la camera avvitata sopra - che si smonta con lo stesso tasto
## con cui si raccoglie un termos. Prima di questa sonda si poteva svitarla, tenerla
## in mano, andare in cucina, e guardare lo schermo contare i frame di una camera
## che si aveva in tasca.
##
## COSA SUCCEDE DAVVERO. La camera e' collegata al PC da un cavo: portandola via il
## cavo se ne va con lei, il software perde il collegamento, e la sequenza si
## interrompe. I frame acquisiti fin li' non ci sono piu' - stavano nella camera -
## e la posa si rifa' da capo. Il collegamento si rifa' riavvitandola.
##
## LE COSE CHE SI GUARDANO, e nessuna e' visibile da un banco di logica pura, perche'
## vivono tutte nel cablaggio fra il mondo, il bus, la fase e la notte:
##
##   1. a meta' sequenza la posa STA lavorando (frame acquisiti fra zero e il totale);
##   2. smontando la camera smette, e il mondo lo sente (`sequence_ended`);
##   3. NON sparisce da sola: il guasto resta sul vetro finche' non lo si legge, e
##      solo allora la fase si chiude - senza foto, senza punteggio, payload vuoto;
##   4. senza camera non si PARTE nemmeno, e riavvitandola si riparte;
##   5. e dopo, la notte offre il menu post-foto invece di un vetro nero.
##
## IL DIFETTO SI RIMETTE: `POSA_SORDA=1` stacca la fase dal bus subito dopo averla
## montata, cioe' rimette esattamente il gioco di prima - la camera in mano e i
## frame che salgono. Senza quel confronto un referto verde non direbbe se la sonda
## sta misurando qualcosa.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_staccata.tscn
##     POSA_SORDA=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_staccata.tscn
##
## GIRANDO CON UNA FINESTRA si aggiunge un atto: il pannello del guasto viene disegnato
## e fotografato in `user://staccata.png`, perche' headless `_draw()` non gira e un
## pannello nuovo che sbaglia una chiamata non se ne accorgerebbe nessuno.
##
## UN `ERROR` E' ATTESO, e viene dall'atto della notte: il piano ridotto non ha la fase
## che sceglie il target, quindi la posa parte con un `target_id` vuoto e lo dice su
## canale 1. E' il prezzo di un piano di una riga sola.
##
## E' una scena e non uno `--script`: la fase legge `Tuning`, che e' un autoload.
extends Node

const FASE := "res://phases/imaging/phase_imaging.tscn"
const SORGENTE := "res://phases/imaging/sources/honest_sequence.tres"

## Dove finisce la fotografia del pannello del guasto, quando si gira con una
## finestra. Headless non disegna niente, e lo dice invece di scrivere un file nero.
const SCATTO := "user://staccata.png"

## A che punto della sequenza si smonta la camera: cinque frame dentro, cioe' con
## del lavoro gia' fatto e parecchio ancora da fare. Smontarla al primo frame o
## all'ultimo sarebbe un caso di confine, e i confini non sono la domanda.
const FRAME_PRIMA := 5

var _guasti := 0
var _fase: PhaseImaging
var _run: NightRun
var _fini := 0
var _esito: PhaseResult
var _sequenze_finite := 0
## I due conteggi dell'atto terzo. Stanno qui e non fra i locali perché una lambda
## in GDScript cattura per VALORE: incrementare un locale catturato non cambia il
## locale, e il referto direbbe sempre zero.
var _menu_aperti := 0
var _piani_esauriti := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[staccata] GUASTO: " + msg)


func _tick() -> int:
	await get_tree().process_frame
	return 0


## Manda avanti l'orologio della notte, che e' l'unica cosa da cui la posa misura
## il tempo. Non si tocca `Engine.time_scale`: qui non si sta misurando un'attesa,
## si sta cercando uno stato.
func _avanza(minuti: float) -> void:
	_run.elapsed_min += minuti
	await _tick()
	await _tick()


func _premi(azione: StringName) -> void:
	var e := InputEventAction.new()
	e.action = azione
	e.pressed = true
	Input.parse_input_event(e)
	await _tick()
	await _tick()


## Quanto dura un frame in minuti di notte, con la configurazione di partenza della
## fase. E' la stessa regola di `PhaseImaging._game_min_per_frame()`, ricopiata qui
## perche' la sonda deve poter dire dove si trova la sequenza SENZA chiederlo alla
## fase che sta collaudando.
func _min_per_frame() -> float:
	return maxf(float(PhaseImaging.EXPOSURE_DEFAULT) / 60.0 * Tuning.pose_time_scale, 0.001)


## Dove sarebbe la sequenza dopo `minuti`, secondo la sorgente di verita' vera.
func _dove_saremmo(minuti: float) -> Dictionary:
	var sorgente: ImagingTruthSource = load(SORGENTE)
	var ing := ImagingInput.new()
	ing.elapsed_since_start_min = minuti
	ing.frames_total = PhaseImaging.FRAMES_DEFAULT
	ing.min_per_frame = _min_per_frame()
	return sorgente.sample(ing)


func _monta() -> PhaseImaging:
	_esito = null
	_fini = 0
	var scena: Node = load(FASE).instantiate()
	var fase := scena as PhaseImaging
	# `setup()` PRIMA dell'albero e `screen()` dopo: e' il contratto che dichiara
	# `night/night_session.gd`, e una sonda che lo violasse proverebbe un altro gioco.
	fase.setup(_run, {&"target_id": &"M42", &"min_exp": 30})
	fase.finished.connect(func(r: PhaseResult) -> void:
		_fini += 1
		_esito = r)
	add_child(fase)
	return fase


func _prova() -> void:
	_run = NightRun.new()
	Events.sequence_ended.connect(func() -> void: _sequenze_finite += 1)

	await _atto_svitata()
	await _atto_senza_camera()
	await _atto_notte()
	await _atto_scatto()

	print("[staccata] --- %d guasti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)


## ATTO PRIMO: si parte, si lavora, e a meta' strada qualcuno svita la camera.
func _atto_svitata() -> void:
	_fase = _monta()
	await _tick()

	# IL DIFETTO RIMESSO: la fase non sente piu' il bus, cioe' il gioco di prima.
	if OS.get_environment("POSA_SORDA") == "1":
		Events.camera_mounted_changed.disconnect(Callable(_fase, "_su_camera"))
		print("[staccata] POSA_SORDA: la fase e' stata staccata dal bus")

	await _premi(&"imaging_start")
	if not _fase.is_working():
		_guasto("la sequenza non e' partita premendo ENTER")
		_smonta()
		return

	var quanto := _min_per_frame() * float(FRAME_PRIMA)
	await _avanza(quanto)
	var meta := _dove_saremmo(quanto)
	var fatti: int = meta.get(&"frames_done", 0)
	print("[staccata] a %.1f minuti di posa: %d/%d frame" % [
		quanto, fatti, PhaseImaging.FRAMES_DEFAULT])
	if fatti <= 0 or fatti >= PhaseImaging.FRAMES_DEFAULT:
		_guasto("la sonda non e' a meta' sequenza: %d frame su %d" % [
			fatti, PhaseImaging.FRAMES_DEFAULT])

	# LA MANO CHE SVITA. Nel gioco lo dice `CcdCamera` raccogliendo la camera dal
	# fuoco; qui si dice lo stesso fatto sul bus, che e' tutto cio' che la fase puo'
	# sentire del mondo.
	var prima := _sequenze_finite
	Events.camera_mounted_changed.emit(false)
	await _tick()

	if _fase.is_working():
		_guasto("la sequenza sta ancora lavorando con la camera in mano")
	if _sequenze_finite != prima + 1:
		_guasto("il mondo non ha saputo che la posa e' finita (sequence_ended: %d)" % [
			_sequenze_finite - prima])
	if _fini != 0:
		_guasto("la fase si e' chiusa da sola: chi torna dalla cupola non legge niente")

	# Il tempo continua a passare, e la sequenza morta non deve resuscitare.
	await _avanza(quanto)
	if _fase.is_working() or _fini != 0:
		_guasto("la posa e' ripartita da sola dopo lo scollegamento")

	# Il giocatore torna, si siede, legge, e preme.
	await _premi(&"imaging_start")
	if _fini != 1:
		_guasto("premendo ENTER sul guasto la fase non si e' chiusa (fini: %d)" % _fini)
		_smonta()
		return

	print("[staccata] esito: ok=%s punteggio=%d payload=%s" % [
		_esito.ok, _esito.score, _esito.payload])
	if _esito.ok:
		_guasto("la posa persa si dichiara riuscita")
	if _esito.score != 0:
		_guasto("la posa persa vale %d punti" % _esito.score)
	if not _esito.payload.is_empty():
		_guasto("il payload non e' vuoto: la foto verrebbe coniata lo stesso")

	# Liberandola non deve uscire un secondo `sequence_ended`: il mondo si e' gia'
	# spento una volta, e spegnerlo due e' un `started` in meno che non torna.
	var prima_di_liberare := _sequenze_finite
	_smonta()
	await _tick()
	if _sequenze_finite != prima_di_liberare:
		_guasto("un secondo sequence_ended liberando la fase gia' morta")


## ATTO SECONDO: la camera non c'e'. Non si parte, e riavvitandola si riparte.
func _atto_senza_camera() -> void:
	_fase = _monta()
	await _tick()

	Events.camera_mounted_changed.emit(false)
	await _premi(&"imaging_start")
	if _fase.is_working():
		_guasto("la sequenza e' partita senza camera al fuoco")

	Events.camera_mounted_changed.emit(true)
	await _premi(&"imaging_start")
	if not _fase.is_working():
		_guasto("riavvitando la camera la sequenza non riparte")
	else:
		print("[staccata] riavvitata: la sequenza riparte")

	_smonta()


## ATTO TERZO: e la notte, dopo, dove ti lascia?
##
## LA DOMANDA VERA DI QUESTO ATTO. Un ciclo foto che finisce senza foto era la fine
## del lavoro: schermo vuoto e giocatore in piedi. Dopo una posa persa sarebbe un
## vicolo cieco — la sequenza non c'è più, nessuno dice come rifarla, e le ore che
## restano non servono a niente. Deve arrivare il menu post-foto, che è già il posto
## dove si decide quanto rifare.
##
## SI MONTA UNA NOTTE VERA, con un piano ridotto all'osso: nessuna fase di setup, e
## come unica fase foto la posa. Il `target_id` non arriva da nessuno — la fase che
## lo sceglie non è nel piano — e la posa lo dice con un errore di canale 1: è
## ATTESO, ed è il prezzo di un piano di una riga sola.
func _atto_notte() -> void:
	var crt: CrtScreen = load("res://crt/crt_screen.tscn").instantiate()
	add_child(crt)

	var piano := NightPlan.new()
	piano.setup_phases = ([] as Array[PackedScene])
	piano.photo_phases = ([load(FASE)] as Array[PackedScene])

	var notte: NightSession = load("res://night/night_session.tscn").instantiate()
	notte.plan = piano
	_piani_esauriti = 0
	_menu_aperti = 0
	notte.plan_exhausted.connect(func() -> void: _piani_esauriti += 1)
	Events.photo_menu_opened.connect(func() -> void: _menu_aperti += 1)
	add_child(notte)

	Game.start_night()
	if not notte.configure(crt):
		_guasto("la notte non si configura")
		notte.queue_free()
		crt.queue_free()
		return
	notte.begin()
	notte.set_player_present(true)
	await _tick()

	await _premi(&"imaging_start")
	Game.run.elapsed_min += _min_per_frame() * float(FRAME_PRIMA)
	await _tick()

	Events.camera_mounted_changed.emit(false)
	await _tick()
	await _premi(&"imaging_start")
	await _tick()
	await _tick()

	print("[staccata] dopo il guasto: menu aperti %d, piano esaurito %d, punteggio posa %s" % [
		_menu_aperti, _piani_esauriti, Game.run.phase_scores])
	if _menu_aperti != 1:
		_guasto("dopo la posa persa il menu post-foto non è arrivato (menu: %d)" % _menu_aperti)
	if _piani_esauriti != 0:
		_guasto("la notte si è dichiarata esaurita dopo una posa persa")

	notte.queue_free()
	crt.queue_free()
	await _tick()


## ATTO QUARTO: il pannello del guasto si LEGGE?
##
## E' l'unica domanda che un collaudo headless non puo' toccare — senza rendering
## `_draw()` non gira, e una chiamata sbagliata dentro il pannello nuovo non se ne
## accorgerebbe nessuno. Girando con una finestra si arriva allo stesso guasto degli
## atti di sopra e si fotografa quello che il giocatore troverebbe tornando dalla
## cupola. Ingrandito tre volte, come le altre sonde di lettura.
func _atto_scatto() -> void:
	if DisplayServer.get_name() == "headless":
		print("[staccata] headless: nessuno scatto (il pannello non viene disegnato)")
		return

	_fase = _monta()
	var strato := CanvasLayer.new()
	strato.scale = Vector2(3, 3)
	add_child(strato)
	var vista := _fase.screen()
	vista.get_parent().remove_child(vista)
	strato.add_child(vista)

	await _premi(&"imaging_start")
	await _avanza(_min_per_frame() * float(FRAME_PRIMA))
	Events.camera_mounted_changed.emit(false)
	# I `Control` si ridisegnano su `queue_redraw`, che arriva al fotogramma dopo.
	for _i in 6:
		await _tick()

	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(SCATTO)
		print("[staccata] scatto in %s" % ProjectSettings.globalize_path(SCATTO))

	strato.queue_free()
	_smonta()


func _smonta() -> void:
	if _fase == null:
		return
	remove_child(_fase)
	_fase.queue_free()
	_fase = null
