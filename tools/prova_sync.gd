## LA SINCRONIZZAZIONE SERVE A QUALCOSA? Si gioca male apposta, e si guarda.
##
## LA DOMANDA. È facile scrivere una fase 5 che sembri funzionare: la stella
## compare fuori centro, la si porta al centro, il punteggio sale. Ma la promessa
## del GDD è un'altra e più difficile — che l'errore residuo **si veda dopo**, come
## l'oggetto scentrato che arriva dal GOTO. Se quella catena è rotta, la fase 5 è
## un giocattolo: si gioca, dà un voto, e non cambia niente.
##
## COME SI MISURA. Si sincronizza DUE VOLTE, bene e male, e si guarda dove
## atterra lo stesso GOTO. Se i due atterraggi sono uguali, la catena è rotta e
## questa sonda ha fatto il suo mestiere.
##
## E NON SI PRETENDE CHE UN SYNC BUONO CENTRI IL CHIP, perché non lo fa nemmeno
## nella realtà: fra la stella di taratura e il soggetto ci sono decine di gradi,
## e con l'asse polare storto di otto decimi l'errore ricresce lungo la strada.
## Un GOTO buono lascia il soggetto nel cercatore, non nell'inquadratura della
## camera — che è esattamente perché si centra guardando nel cercatore. La sonda
## chiede quindi le due cose che devono essere vere: che il sync tirato via
## finisca **fuori** dal chip, e che quello fatto bene finisca **molto** più
## vicino.
##
## È IL DIFETTO INIETTATO DI QUESTA FAMIGLIA DI SONDE, come `BLOCCATA=1` per la
## cupola: la versione «male» non è una simulazione di guasto, è il giocatore che
## preme SYNC senza aver centrato niente. Se anche così l'oggetto arriva al
## centro, il modello di puntamento non è collegato a niente.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_sync.tscn
##
## È una scena e non uno `--script`: le fasi leggono `Tuning`, che è un autoload.
extends Node

## Quanto ci si accontenta di avvicinarsi al centro nella prova «fatta bene», in
## gradi. Un decimo di grado è quello che ottiene una persona che guarda.
const CENTRATURA := 0.08

## Il soggetto su cui si prova il GOTO. M13 sta alto: è raggiungibile da questa
## cupola per una buona parte della notte, e la prova non deve rompersi
## sull'orizzonte dell'edificio, che è misurato altrove.
const SOGGETTO := &"m13"

## A che ora si prova, in minuti dall'inizio della notte. M13 è dato per le
## 22:00-03:00, quindi a 150 minuti (le 23:30) sta a mezz'ora dal meridiano.
const QUANDO := 150.0

## Quante notti si simulano per parte. Vedi il commento in `_gioca()`.
const NOTTI := 20

var _guasti := 0


func _ready() -> void:
	_gioca.call_deferred()


func _gioca() -> void:
	var bene := _molti_giri(true)
	var male := _molti_giri(false)
	print("[sync] %d notti per parte, soggetto %s alle %d minuti" % [NOTTI, SOGGETTO, QUANDO])
	print("[sync] sincronizzazione CENTRATA:   errore medio %5.1f'  ->  soggetto a %5.1f' dal centro (peggio %5.1f'), inquadrato %d volte su %d"
		% [bene.x, bene.y, bene.z, int(bene.w), NOTTI])
	print("[sync] sincronizzazione TIRATA VIA: errore medio %5.1f'  ->  soggetto a %5.1f' dal centro (peggio %5.1f'), inquadrato %d volte su %d"
		% [male.x, male.y, male.z, int(male.w), NOTTI])

	# SI GIUDICA SU VENTI NOTTI E NON SU UNA, e non e' pignoleria statistica: su
	# una sola notte i due errori possono ELIDERSI per caso - lo sfasamento degli
	# encoder in un verso e la deriva dell'asse polare nell'altro - e una
	# sincronizzazione tirata via atterrare piu' vicino di una fatta bene. Succede
	# davvero, ed e' successo alla prima stesura di questa sonda: il referto
	# gridava al guasto per un caso fortunato. La domanda giusta e' come va in
	# media, perche' e' quello che il giocatore vive in venti notti.
	if male.w > NOTTI * 0.25:
		_guasto("SONDA CIECA: senza sincronizzare il soggetto arriva inquadrato %d volte su %d, "
			% [int(male.w), NOTTI] + "quindi la fase 5 non e' collegata al GOTO")
	if male.y < bene.y * 2.0:
		_guasto("sincronizzare bene non avvicina il soggetto molto piu' che sincronizzare male")
	if bene.x >= male.x:
		_guasto("la fase 5 misura lo stesso errore a chi centra e a chi non centra")

	if _guasti == 0:
		print("[sync] ok: l'errore della fase 5 arriva fino al GOTO e si vede")
	else:
		print("[sync] GUASTO: %d controlli falliti" % _guasti)
	get_tree().quit()


## Venti notti di seguito. Restituisce (errore medio del sync, scarto medio del
## GOTO, scarto peggiore, quante volte il soggetto e' arrivato inquadrato), in
## primi d'arco.
func _molti_giri(centra: bool) -> Vector4:
	var somma_err := 0.0
	var somma_scarto := 0.0
	var peggio := 0.0
	var dentro := 0
	for _i in NOTTI:
		var v := _un_giro(centra)
		somma_err += v.x * 60.0
		somma_scarto += v.y * 60.0
		peggio = maxf(peggio, v.y * 60.0)
		dentro += 1 if v.z > 0.5 else 0
	return Vector4(somma_err / NOTTI, somma_scarto / NOTTI, peggio, float(dentro))


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[sync] GUASTO: " + msg)


## Un giro intero: fase 5, poi GOTO. Restituisce (errore del sync, scarto del
## GOTO, 1 se inquadrato) — tutto in gradi, l'ultimo come booleano travestito.
func _un_giro(centra: bool) -> Vector3:
	var run := NightRun.new()
	run.elapsed_min = QUANDO
	run.selected_target_id = SOGGETTO

	var sync := load("res://phases/sync/phase_sync.tscn").instantiate() as PhaseSync
	sync.setup(run, {})
	add_child(sync)
	# UN FOTOGRAMMA A MANO, o `_scarto` resta zero e la fase dichiara un modello
	# di puntamento perfetto senza aver mai guardato la stella. E' successo, e il
	# referto diceva «tirata via: errore 0,0 primi» - cioe' che saltare la fase 5
	# era meglio che farla.
	sync._process(0.016)
	if centra:
		_centra(sync)
	sync._finish()
	var err_sync := run.pointing_error_deg.length()
	sync.queue_free()

	var goto := load("res://phases/goto/phase_goto.tscn").instantiate() as PhaseGoto
	goto.setup(run, {})
	add_child(goto)
	# Un fotogramma di `_process` a mano: la fase deve leggere il modello di
	# puntamento e calcolare dove atterra, e qui non c'e' nessun ciclo che glielo
	# faccia fare.
	goto._process(0.016)
	var scarto := goto.errore()
	var dentro := goto._inquadrato()
	goto.queue_free()
	return Vector3(err_sync, scarto, 1.0 if dentro else 0.0)


## Centra la stella come la centrerebbe una persona: guarda dove sta, si muove
## verso il centro, si ferma quando è dentro.
##
## NON USA LA TASTIERA e non passa da `_process`: la fase muove il tubo con
## `Input.get_axis`, che qui vorrebbe un ciclo di fotogrammi veri. Si scrive
## direttamente l'encoder, che è il numero che le frecce spostano — la catena che
## si sta misurando comincia dopo, ed è quella fra encoder e cielo.
func _centra(sync: PhaseSync) -> void:
	for _i in 200:
		sync._scarto = sync.truth.sample(sync._truth_input, 0.016)
		if sync._scarto.length() <= CENTRATURA:
			return
		# Un passo verso il centro, mai piu' lungo dello scarto: e' quello che fa
		# una mano che rallenta avvicinandosi.
		var passo := minf(sync._scarto.length(), 0.05)
		sync._encoder += sync._scarto.normalized() * passo
		sync._truth_input.encoder_deg = sync._encoder
	sync._scarto = sync.truth.sample(sync._truth_input, 0.016)
