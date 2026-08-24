## Lo strumento di misura dell'MVP — ASCOLTA IL BUS E BASTA (rilievo C3, chiuso il
## 2026-08-24). Accumula, per notte, le finestre della posa e gli intervalli delle
## quattro attività dell'attesa, e all'alba (o alla chiusura dell'app a notte aperta)
## scrive un file JSON leggibile in `user://telemetry/`, uno per notte.
##
## PERCHÉ UN AUTOLOAD E NON LA FASE. La fase muore e rinasce più volte per notte
## (una per foto, più le repliche di *rifai setup*), le attività vivono in `world/` e
## `bbs/` non nella fase, `phases/` conosce solo `core/`, e `quit_mid_pose` non è
## osservabile da un oggetto che sta venendo distrutto. Uno stato che deve durare
## TUTTA la notte, fondere quattro pose in UN file, e intercettare la chiusura
## dell'app, vive qui.
##
## LA PROPRIETÀ CHE LO RENDE SICURO: nessun altro file di gameplay lo nomina.
## Togliendolo dagli autoload il gioco resta identico — lo strumento di misura non
## deve poter cambiare ciò che misura. L'unico lettore è `debug/debug_overlay.gd`, che
## LEGGE da qui (mai il contrario): quella dipendenza si taglia in release senza
## toccare la misura. Nessun `class_name`: nessuno lo tipizza.
##
## LA TELEMETRIA NON PASSA DA `Log`. `Log` è logging tecnico senza stato; questo è un
## oggetto JSON per notte con stato accumulato. Offline per costruzione: nessuna rete,
## nessun dato personale, nessun `FileAccess` fuori da questo file per la telemetria.
extends Node

const DIR := "user://telemetry"

## Stato per-notte. Si azzera a inizio notte (`_begin_night`) e si legge alla scrittura.
var _active: bool = false
var _night: int = 0
var _tuning: String = ""

## Le finestre della posa: `[t, end]` in minuti di gioco. Una finestra aperta ha
## `end == -1.0` (chiusa a `now` alla scrittura). `_open_pose` è la `t` della finestra
## attualmente aperta, o -1.0 se nessuna posa gira.
var _pose_windows: Array = []
var _open_pose: float = -1.0

## Gli intervalli delle attività: `{what, t, end}` in minuti di gioco. Un record aperto
## ha `end == -1.0` → sarà `abandoned` alla scrittura. Più record dello stesso `what`
## possono convivere (la stessa attività ripetuta), ma solo l'ULTIMO aperto si chiude su
## `ended` — le sovrapposizioni fra attività DIVERSE sono il caso normale.
var _activities: Array = []

var _menu_count: int = 0

## L'ultimo `elapsed_min` visto a notte aperta. `_now()` legge `Game.run.elapsed_min`
## quando può, ma all'alba `Game.run` è già `null` (`end_night()` lo azzera PRIMA di
## `dawn_reached`): allora si usa questo, timbrato all'arrivo di ogni evento a notte
## aperta. Non serve mai per la logica dei campi — quelli sono già timbrati — solo come
## rete di sicurezza per la chiusura delle finestre aperte.
var _last_min: float = 0.0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	# `phase_started` serve SOLO a catturare l'identità della notte (`night_index`,
	# `tuning_hash`) a notte aperta — un fatto diverso da «la posa gira». MAI come
	# finestra di posa: quella è `sequence_started/ended` (la correzione del 2026-08-24,
	# commit 854125b: `phase_started(&"imaging")` scatta al MONTAGGIO del pannello, non
	# allo START, e misurerebbe come attesa vissuta il tempo in cui nessuna posa esiste).
	Events.phase_started.connect(_on_phase_started)
	Events.sequence_started.connect(_on_sequence_started)
	Events.sequence_ended.connect(_on_sequence_ended)
	Events.wait_activity_started.connect(_on_activity_started)
	Events.wait_activity_ended.connect(_on_activity_ended)
	Events.photo_menu_opened.connect(_on_menu_opened)
	Events.dawn_reached.connect(_on_dawn_reached)


# --- Ascolto del bus (cablaggio: nessuna aritmetica qui) --------------------------

## Cattura l'identità della notte, idempotente. `phase_started` arriva più volte per
## notte (ogni fase montata): si apre la notte solo se non c'è già una notte attiva o
## se l'indice è cambiato (nuova notte). `Game.run` è non-null qui — le fasi si montano
## sempre a notte aperta.
func _on_phase_started(_key: StringName) -> void:
	if Game.run == null:
		return
	_last_min = Game.run.elapsed_min
	if _active and Game.run.night_index == _night:
		return
	_begin_night(Game.run.night_index, Tuning.profile_hash)


## GUARDIA `_active` come ogni altro handler: fuori da una notte aperta (prima del primo
## `phase_started`, o dopo che `_write` ha chiuso la notte) gli eventi del bus non toccano
## lo stato. In gioco la posa parte sempre a notte aperta — è difesa e coerenza, non un
## caso raggiungibile — ma evita che una finestra orfana faccia mostrare all'overlay una
## posa di una notte mai cominciata.
func _on_sequence_started() -> void:
	if not _active:
		return
	_last_min = _now()
	# Difesa: uno `started` senza il precedente `ended` (non dovrebbe capitare, la fase
	# emette `sequence_ended` sempre e una volta sola) non lascia due finestre aperte.
	if _open_pose >= 0.0:
		_close_open_pose()
	_open_pose = _now()


func _on_sequence_ended() -> void:
	if not _active:
		return
	_last_min = _now()
	if _open_pose < 0.0:
		return
	_close_open_pose()


func _on_activity_started(what: StringName) -> void:
	if not _active:
		return
	_last_min = _now()
	_activities.append({&"what": what, &"t": _now(), &"end": -1.0})


## Chiude l'ULTIMO record aperto di questo `what`. Un `ended` senza uno `started` aperto
## corrispondente si ignora (I/O matrix: «ended senza started aperto → ignorato»).
func _on_activity_ended(what: StringName) -> void:
	if not _active:
		return
	_last_min = _now()
	for i in range(_activities.size() - 1, -1, -1):
		var rec: Dictionary = _activities[i]
		if rec[&"what"] == what and float(rec[&"end"]) < 0.0:
			rec[&"end"] = _now()
			return


func _on_menu_opened() -> void:
	if not _active:
		return
	_menu_count += 1


func _on_dawn_reached() -> void:
	if not _active:
		return
	_write(false)


## La CHIUSURA DELL'APP a notte aperta — il secondo momento di scrittura, senza cui
## `quit_mid_pose` non potrebbe mai valere `true` (la sessione che lo produce è proprio
## quella che all'alba non arriva). Qui `Game.run` è ancora non-null (`end_night` non è
## stato chiamato), quindi `elapsed_min` è leggibile. In headless la notifica non arriva:
## il meccanismo si verifica eseguendolo (chiudere la finestra a posa in corso).
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_CLOSE_REQUEST:
		return
	if not _active:
		return
	_write(_open_pose >= 0.0)


# --- Vita della notte -------------------------------------------------------------

func _begin_night(night: int, tuning: String) -> void:
	_active = true
	_night = night
	_tuning = tuning
	_pose_windows = []
	_open_pose = -1.0
	_activities = []
	_menu_count = 0


## `Game.run.elapsed_min` quando c'è; altrimenti l'ultimo minuto visto a notte aperta
## (all'alba `Game.run` è `null`). Vedi il commento su `_last_min`.
func _now() -> float:
	if Game.run != null:
		return Game.run.elapsed_min
	return _last_min


func _close_open_pose() -> void:
	_pose_windows.append([_open_pose, _now()])
	_open_pose = -1.0


## Scrive il file della notte e chiude lo stato. IDEMPOTENTE per notte: dopo la scrittura
## `_active` è falso, quindi chi ha già scritto la notte non riscrive (l'alba dopo un
## quit-mid-pose, o un secondo `dawn_reached`, non producono un secondo file).
##
## Le finestre aperte (quit a metà) si chiudono a `now` ai fini di `wait_total_min`/idle;
## `build_report` riceve i dati grezzi e fa tutta l'aritmetica.
func _write(quit_mid_pose: bool) -> void:
	var windows: Array = _pose_windows.duplicate(true)
	if _open_pose >= 0.0:
		windows.append([_open_pose, _now()])
	var report := build_report(_night, _tuning, windows, _activities, _menu_count,
		quit_mid_pose, _now())
	var path := "%s/night-%d.json" % [DIR, _night]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		# Errore TECNICO (canale 1), non un log diegetico e non `Log`: lo strumento di
		# misura ha perso una notte e chi sviluppa deve saperlo, invece di scoprire un buco
		# nel confronto fra notti. `push_error` è canale 1, e non passa da `Log`.
		push_error("[telemetry] impossibile scrivere %s (err %d)" % [
			path, FileAccess.get_open_error()])
		_active = false
		return
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	_active = false


# --- Accessori per l'overlay F12 (debug/ LEGGE, mai il contrario) -----------------

## I minuti della finestra di posa in corso, o -1.0 se nessuna posa gira.
func current_pose_min() -> float:
	if _open_pose < 0.0:
		return -1.0
	return _now() - _open_pose


## Quanti minuti della posa in corso sono SCOPERTI (nessuna attività li copre), o -1.0
## se nessuna posa gira. È il dato più importante — l'attesa non riempita — mostrato dal
## vivo mentre la si vive. Delega alla pura `uncovered_min`, così l'aritmetica dietro la
## riga F12 è collaudabile sul banco come `idle_segments`.
func current_pose_uncovered_min() -> float:
	return uncovered_min(_open_pose, _now(), _activities)


# --- FUNZIONI PURE STATICHE (collaudate sul banco, senza SceneTree) ---------------

## I minuti SCOPERTI della finestra di posa `[open_pose, now]` — la posa meno l'unione
## delle attività — o -1.0 se nessuna posa gira (`open_pose < 0`). Pura e statica, con
## `now` letto UNA volta dal chiamante: è l'aritmetica che l'overlay F12 mostra dal vivo,
## e il banco la collauda come ogni altro pezzo di misura.
static func uncovered_min(open_pose: float, now: float, activities: Array) -> float:
	if open_pose < 0.0:
		return -1.0
	var covered := _covered_intervals(activities, now)
	var total := 0.0
	for seg in idle_segments([[open_pose, now]], covered):
		total += float(seg[&"dur"])
	return total

## Unione di intervalli `[t, end]`: sovrapposti e contigui si FONDONO, non si sommano.
## `merge_intervals([[0,10],[5,12],[20,25]]) == [[0,12],[20,25]]`. Intervalli degeneri
## (`end <= t`) si scartano. È il cuore di `idle`: caffè sul fuoco MENTRE si sale in
## cupola è il caso normale, e sommando si otterrebbe più attività che tempo.
static func merge_intervals(a: Array) -> Array:
	var clean: Array = []
	for iv in a:
		var t := float(iv[0])
		var e := float(iv[1])
		if e > t:
			clean.append([t, e])
	clean.sort_custom(func(x, y): return float(x[0]) < float(y[0]))
	var out: Array = []
	for iv in clean:
		if out.is_empty() or float(iv[0]) > float(out[-1][1]):
			out.append([float(iv[0]), float(iv[1])])
		else:
			out[-1][1] = maxf(float(out[-1][1]), float(iv[1]))
	return out


## I tratti SCOPERTI dentro le finestre di posa: `windows` meno l'UNIONE di `covered`.
## Ogni tratto è `{t, dur}` in minuti di gioco. Nessun idle negativo, nessun tempo
## doppio: la copertura passa da `merge_intervals`.
## `idle_segments([[0,30]], [[0,12],[20,25]]) == [{t:12,dur:8},{t:25,dur:5}]`.
static func idle_segments(windows: Array, covered: Array) -> Array:
	var union := merge_intervals(covered)
	var out: Array = []
	for w in windows:
		var cursor := float(w[0])
		var w_end := float(w[1])
		for c in union:
			var c_t := float(c[0])
			var c_e := float(c[1])
			if c_e <= cursor or c_t >= w_end:
				continue
			if c_t > cursor:
				out.append({&"what": &"idle", &"t": cursor, &"dur": c_t - cursor})
			cursor = maxf(cursor, c_e)
			if cursor >= w_end:
				break
		if cursor < w_end:
			out.append({&"what": &"idle", &"t": cursor, &"dur": w_end - cursor})
	return out


## Gli intervalli COPERTI da ogni record d'attività: `{what,t,end}` → `[t, end]`, con i
## record aperti (`end < 0`) chiusi a `now`. È ciò che `idle` sottrae dalle finestre.
## Privata alla logica ma statica: la usa `build_report` e l'overlay.
static func _covered_intervals(activities: Array, now: float) -> Array:
	var out: Array = []
	for rec in activities:
		var t := float(rec[&"t"])
		var e := float(rec[&"end"])
		if e < 0.0:
			e = now
		out.append([t, e])
	return out


## Assembla il report della notte dal grezzo — è QUI che sta tutta la struttura, così
## il banco copre l'intero file su disco senza SceneTree né I/O.
##
## - Attività chiusa → `{what, t, dur}`.
## - Attività aperta alla scrittura → `{what, t, dur:null, abandoned:true}` — NON omessa
##   (un abbandono è un dato, non un buco). Un'attività cominciata FUORI da una posa è
##   registrata lo stesso: è solo `idle` che si calcola sulle sole finestre di posa.
## - `idle` → un tratto `{what:"idle", t, dur}` per ogni segmento scoperto delle pose.
## - `wait_total_min` → somma delle finestre (aperte già chiuse a `now` dal chiamante).
##
## Le voci `wait_activities[]` escono ordinate per `t`, così il file si legge a occhio
## nell'ordine in cui i fatti sono accaduti (idle e attività interlacciati).
static func build_report(
	night: int, tuning: String, windows: Array, activities: Array,
	menu: int, quit_mid_pose: bool, now: float
) -> Dictionary:
	var items: Array = []
	for rec in activities:
		var t := float(rec[&"t"])
		var e := float(rec[&"end"])
		if e < 0.0:
			items.append({&"what": String(rec[&"what"]), &"t": t, &"dur": null,
				&"abandoned": true})
		else:
			items.append({&"what": String(rec[&"what"]), &"t": t, &"dur": e - t})

	var covered := _covered_intervals(activities, now)
	for seg in idle_segments(windows, covered):
		items.append({&"what": "idle", &"t": float(seg[&"t"]), &"dur": float(seg[&"dur"])})

	items.sort_custom(func(x, y): return float(x[&"t"]) < float(y[&"t"]))

	var wait_total := 0.0
	for w in windows:
		wait_total += float(w[1]) - float(w[0])

	return {
		&"night": night,
		&"tuning_hash": tuning,
		&"wait_total_min": wait_total,
		&"wait_activities": items,
		&"menu_reopened": menu,
		&"quit_mid_pose": quit_mid_pose,
	}
