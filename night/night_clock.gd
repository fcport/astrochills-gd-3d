## L'orologio della notte: un accumulatore, e nient'altro.
##
## `run.elapsed_min += delta * Tuning.game_min_per_sec`. È tutta la formula, ed è
## scritta così nell'architettura. Il `delta` di `_process` è già la quantità su
## cui la pausa e `Engine.time_scale` agiscono: non serve altro, e aggiungere
## altro rompe.
##
## PER QUESTO NON C'È `PROCESS_MODE_ALWAYS` QUI, e non è una dimenticanza. L'AC1
## chiede che «la pausa fermi il tempo davvero»: con quel modo `_process`
## continuerebbe a girare ad albero in pausa e metà del criterio sarebbe falsa.
##
## E PER QUESTO NON SI LEGGE MAI `Engine.time_scale`. Il motore lo ha già
## applicato al `delta` prima di consegnarlo. Moltiplicarlo di nuovo qui
## applicherebbe l'accelerazione due volte — e la notte ×10 diventerebbe ×100
## senza che nessuna riga lo dica. `debug/time_control.gd` scrive su
## `Engine.time_scale`; questo file non lo legge.
##
## IL DATO NON È SUO. `elapsed_min` vive in `NightRun`, che appartiene a `Game`:
## l'orologio fa scorrere, la `NightRun` conserva, `Game` possiede. Una seconda
## copia del tempo qui dentro sarebbe la prima cosa a divergere.
##
## LE DUE MANOPOLE, e quale serve a cosa. `night_length_min` dice quanto è lunga
## la notte NEL MONDO: 540 minuti di gioco sono le nove ore dalle 21:00 alle
## 06:00, e abbassarlo sposta l'alba a un'ora più presto. `game_min_per_sec` dice
## quanto in fretta scorre: 0.6 fa una notte in 15 minuti reali, 0.15 in un'ora,
## 1.8 in cinque minuti — e l'alba resta comunque alle 06:00. **Per tarare
## l'attesa si gira il ritmo, non la lunghezza**, ed è il motivo per cui l'ora si
## ricava per somma diretta e non per compressione.
class_name NightClock
extends Node

## L'ora in cui si arriva all'osservatorio.
##
## È una `const` e non un valore di tuning perché non è sola: sta in coppia con
## `night_length_min = 540`, che vale nove ore ed è scritto per finire alle
## 06:00. Girarne una senza l'altra sposta l'alba, e un override che può farlo in
## silenzio è un modo di rompere il gioco senza accorgersene.
const NIGHT_START_HOUR := 21

## Emesso una volta sola, al padrone dell'orologio.
##
## Signal DIRETTO e non `Events`, per la regola del bus: qui l'ascoltatore è uno
## e si sa chi è. Sul bus ci va `Events.dawn_reached`, che è l'annuncio al resto
## del mondo, e lo emette chi chiude la notte — non chi la misura.
signal dawn()

var _run: NightRun
var _last_hour := -1
var _dawn_sent := false


func _ready() -> void:
	# Fermo finché non c'è una notte da misurare: `begin()` lo accende.
	set_process(false)


## Comincia a misurare. Torna `false` se non c'è niente da misurare.
##
## L'esito si restituisce invece di limitarsi a loggarlo: un orologio che non
## parte lascerebbe una notte senza alba, e chi lo ha montato deve poterlo sapere
## subito. È la lezione della `DeskCamera` nella storia 1.3.
func begin(run: NightRun) -> bool:
	if run == null:
		push_error("[night] orologio avviato senza NightRun")
		return false
	_run = run
	_last_hour = hour()
	_dawn_sent = false
	set_process(true)
	return true


func stop() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_run.elapsed_min += delta * Tuning.game_min_per_sec

	# L'ora varcata è un fatto di notte: sul bus, perché gli ascoltatori non si
	# conoscono ancora — la cupola dell'epica 3 e la telemetria lo vorranno, e
	# trovarlo già emesso è ciò che impedisce loro di andarselo a prendere
	# violando un confine (rilievo M1).
	# OGNI confine varcato, non solo l'ultimo. Un frame lungo — uno stutter, una
	# compilazione di shader, `Engine.time_scale` alto — può attraversarne più
	# d'uno, e con un solo `emit` per frame le ore in mezzo non le annuncerebbe
	# nessuno. Chi conta le ore (la cupola della 3.5, la telemetria) conterebbe
	# male, e il banco stampa il numero dei segnali come se fosse garantito.
	var h := hour()
	while _last_hour != h:
		_last_hour = (_last_hour + 1) % 24
		Events.hour_passed.emit(_last_hour)

	if not _dawn_sent and _run.elapsed_min >= Tuning.night_length_min:
		_dawn_sent = true
		# L'ALBA È UN'ORA ESATTA, non «la soglia più lo sforamento dell'ultimo
		# frame». A 60 fps e ritmo di default lo sforamento è un centesimo di
		# minuto e non si vede; con un frame lungo a ×10 vale minuti di gioco, e
		# il riepilogo scriverebbe «21:00 → 06:06». È proprio nella condizione
		# per cui `F1`-`F4` esistono — tarare senza rigiocare la notte — che il
		# numero smetterebbe di essere confrontabile.
		_run.elapsed_min = Tuning.night_length_min
		# Si smette di misurare PRIMA di annunciare: chi riceve l'alba smonta
		# fasi e mostra il riepilogo, e non deve farlo mentre il tempo scorre
		# ancora sotto di lui.
		set_process(false)
		dawn.emit()


## Minuti di gioco dall'inizio della notte. Zero se non è cominciata.
func elapsed_min() -> float:
	return _run.elapsed_min if _run != null else 0.0


## L'ora di gioco, 0-23. Somma diretta: `elapsed_min` **è** l'ora.
func hour() -> int:
	return int(NIGHT_START_HOUR + elapsed_min() / 60.0) % 24


func minute() -> int:
	return int(elapsed_min()) % 60


## `HH:MM`, che è il formato del mockup normativo dell'overlay.
func clock_text() -> String:
	return "%02d:%02d" % [hour(), minute()]
