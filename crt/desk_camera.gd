## Porta il giocatore alla postazione davanti a uno schermo (ADR-003).
##
## In prima persona la camera È la testa: non si stacca mai dal corpo. È il
## corpo a essere portato alla postazione, e la camera resta dove è sempre
## stata — figlia del corpo. Guardare la stanza da un punto dove il giocatore
## non è romperebbe l'unica cosa che il gioco vende: la presenza in quel luogo.
##
## Il campo visivo si stringe durante la transizione. Non è un vezzo: a FOV
## largo il monitor resterebbe piccolo anche da vicino, e stringere legge come
## «mi avvicino a guardare».
class_name DeskCamera
extends Node

signal seated()
signal left()

const TRANSITION := 0.5
const SEATED_FOV := 33.0
## Quanto dura il ritorno al monitor dopo essersi guardati attorno. Un quarto di secondo:
## abbastanza da leggersi come un gesto, poco da non far aspettare.
const RECENTER := 0.25

## Da seduti ci si guarda intorno, e la sedia gira.
##
## PERCHÉ ESISTE. Dalla postazione la sala del telescopio si vede — c'è una vetrata
## fra la sala di controllo e la cupola — ma solo se si può alzare lo sguardo: il tubo
## che va sulla stella del SOLVE, e la fessura che gli gira dietro da sola. È nato
## quando la cupola si apriva dal PC; adesso si apre e si chiude dalla pulsantiera in
## cupola (D-188), ma la ragione per guardare in alto è rimasta.
##
## L'IMBARDATA VA SUL CORPO E IL BECCHEGGIO SULLA TESTA, come in piedi. E girare il
## corpo da seduti non sposta la testa di un millimetro: il marcatore del sedile è
## dritto sopra l'origine del corpo (`_cam.position` è una traslazione verticale
## pura), quindi ruotare attorno a Y è esattamente una sedia girevole.
##
## SI TORNA COM'ERA ALZANDOSI, senza codice apposta: `_leave()` rimette il corpo
## nella posa di prima e la testa al beccheggio di prima, che sono le stesse due
## cose che il guardarsi intorno ha cambiato.
##
## I DUE NUMERI SONO RICOPIATI DA `world/player/player.gd`, e la copia è
## deliberata: `crt/` non conosce `world/` — è un sistema generico che riceve un
## `Control` e non sa nemmeno di stare in un osservatorio — e importare il
## giocatore per due costanti aprirebbe una porta che la tabella dei confini tiene
## chiusa. Se un giorno la sensibilità diventerà un'impostazione, sarà un dato che
## arriva a tutti e due da fuori, non un file che ne importa un altro.
const MOUSE_SENSITIVITY := 0.0022
const PITCH_LIMIT := deg_to_rad(89.0)

var is_seated := false

var _player: Node3D
var _cam: Camera3D
var _seat: Marker3D
var _standing_xform: Transform3D
var _standing_fov: float
var _standing_pitch: float
## La posa della seduta, quella che `_sit()` calcola. Serve a `recenter()`.
var _seated_xform: Transform3D
var _seated_pitch := 0.0
var _busy := false


## Dice alla postazione chi si siede, con quale testa, e dove. Torna `false` se
## non è stato possibile configurarla.
##
## SI VALIDA QUI, dove il chiamante è ancora nello stack e l'errore può nominarlo.
## Senza, un `seat` nullo passa inosservato per tutta la partita e si schianta
## dentro `_sit()` alla prima interazione col monitor — cioè lontanissimo dalla
## riga che ha sbagliato, e con il giocatore già senza controllo.
##
## Se manca anche uno solo dei tre non si configura NIENTE: mezza postazione
## configurata siederebbe il corpo lasciando la testa dov'era.
##
## L'ESITO SI RESTITUISCE, non si lascia solo nel log, ed è una correzione della
## code review del 2026-08-22. Un `push_error` avvisa lo sviluppatore ma non ferma
## il chiamante: chi montava la postazione proseguiva lo stesso, e alla prima `E`
## il punto d'ingresso spegneva il controller del giocatore PRIMA di scoprire che
## `toggle()` non poteva partire. Nessun tween, nessun segnale, e un giocatore
## senza movimento né testa, con l'unica uscita in un tasto che nessuno avrebbe
## ragione di provare. Un errore di configurazione deve fermare chi configura.
func configure(player: Node3D, cam: Camera3D, seat: Marker3D) -> bool:
	if player == null or cam == null or seat == null:
		push_error("[crt] configure() incompleta — player=%s camera=%s seat=%s" % [
			player, cam, seat])
		return false
	_player = player
	_cam = cam
	_seat = seat
	return true


func toggle() -> void:
	if _busy:
		return
	if _player == null or _cam == null or _seat == null:
		push_error("[crt] toggle() prima di configure(): la postazione non sa dove sedersi")
		return
	# FUORI DALL'ALBERO IL TWEEN NON AVANZA. `create_tween()` lega il Tween allo
	# SceneTree del nodo: da orfano restituisce un Tween che non riceve mai un
	# tick, `await t.finished` non torna, e `seated` non viene emesso. Il giocatore
	# resterebbe seduto per sempre — senza controllo, perché chi orchestra glielo
	# ha tolto al passo 1, e senza input, perché lo cede solo su `seated`.
	# Questo nodo non ha una scena: chi lo istanzia deve ricordarsi di add_child().
	if not is_inside_tree():
		push_error("[crt] DeskCamera fuori dall'albero: il tween non avanzerebbe mai")
		return
	if is_seated:
		_leave()
	else:
		_sit()


## Se una transizione è in corso. A metà transizione il giocatore non è né in
## piedi né alla postazione, e chi orchestra deve poterlo sapere: è l'istante
## in cui `is_seated` dice la verità e non basta.
func is_busy() -> bool:
	return _busy


## Riporta lo sguardo al monitor dopo essersi guardati attorno.
##
## DA SEDUTI IL MOUSE HA DUE PADRONI: di norma muove il puntatore sul vetro, e con ALT
## tenuto premuto gira la testa (lo smista `main.gd`). Lasciato ALT si torna al computer
## — e se la testa restasse girata, il mouse muoverebbe una freccia su un vetro che non
## si vede. Si torna alla posa della seduta, la stessa che `_sit()` ha calcolato.
func recenter() -> void:
	if not is_seated or _busy or _player == null or _cam == null:
		return
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_player, "global_transform", _seated_xform, RECENTER)
	t.tween_property(_cam, "rotation:x", _seated_pitch, RECENTER)


func _sit() -> void:
	_busy = true
	_standing_xform = _player.global_transform
	_standing_fov = _cam.fov
	_standing_pitch = _cam.rotation.x

	var seat_xf := _seat.global_transform
	var euler := seat_xf.basis.get_euler()

	# Il corpo resta dritto: prende solo l'imbardata. Il beccheggio è della testa.
	var target := Transform3D(Basis(Vector3.UP, euler.y), Vector3.ZERO)
	target.origin = seat_xf.origin - target.basis * _cam.position

	# IL BECCHEGGIO VIENE DAL MARKER, e il marker deve puntare al proprio vetro.
	# Qui non si sa dove sia lo schermo — questa classe porta a una POSTAZIONE, e
	# la postazione è il `Marker3D`. Il segno di `euler.x` è quindi una proprietà
	# della scena, non di questo file.
	#
	# LA SPIEGAZIONE STA QUI E NON NELLA SCENA, ed è una correzione della code
	# review del 2026-08-22: il parser dei `.tscn` tollera i commenti `;`, ma
	# nessun salvatore di risorse li conserva — la scena viene rigenerata dallo
	# stato in memoria, e il primo che sposta un nodo nell'editor e salva li
	# cancella. La ragione di un valore non può vivere in un file che si riscrive
	# da solo.
	#
	# IL CASO DEL CRT, coi numeri: `crt_screen.tscn` nasceva col `Seat` a +11,50°
	# attorno a X, mentre la direzione dal sedile `(0, 0.09, 0.44)` all'origine
	# del vetro è −11,56°. Modulo giusto, segno sbagliato — e in Godot un
	# `rotation.x` positivo ALZA lo sguardo. Con vetro alto 0,24 m a 0,44 m di
	# distanza lo schermo occupa da −25,51° a +3,90° rispetto all'orizzonte:
	#     asse a +11,50° → inquadra [−9,50°, +32,50°] → si vede il 46% dello
	#                      schermo, la sola parte alta;
	#     asse a −11,50° → inquadra [−32,50°, +9,50°] → schermo intero.
	# Verificato guardando, non solo calcolando (storia 1.3).
	#
	# IL FOV SEDUTO È 33 E NON PIÙ 42, ed è passato prima da 30 — che era un grado
	# di troppo. Il vetro occupa [−25,51°, +3,90°]: con 30° l'asse a −11,56°
	# inquadra [−26,56°, +3,44°] e il bordo ALTO resta fuori di mezzo grado. Con le
	# finestre piccole non se ne accorgeva nessuno; con una a tutto schermo quel
	# mezzo grado è esattamente dove sta la barra del titolo, e si perdevano il nome
	# della finestra e i suoi pulsanti. A 33° l'inquadratura è [−28,06°, +4,94°] e
	# il vetro ci sta INTERO, con un grado di margine sopra e due e mezzo sotto.
	# Verificato con uno scatto a finestra massimizzata, non solo calcolando.
	#
	# E resta il guadagno per cui si era sceso da 42: lì il monitor prendeva due
	# terzi dell'altezza e il software si leggeva stringendo gli occhi. Scendere
	# sotto i 30 — 24° è stato provato — toglie la cornice del tubo, e con la
	# cornice se ne va la sensazione di essere seduti davanti a un oggetto.
	#
	# ALZANDOSI SI TORNA COM'ERA DA SÉ: `_standing_fov` è salvato qui sotto prima
	# della transizione e rimesso da `_leave()`. Non c'è un secondo numero da
	# tenere allineato a questo.
	_seated_xform = target
	_seated_pitch = euler.x
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_player, "global_transform", target, TRANSITION)
	t.tween_property(_cam, "rotation:x", euler.x, TRANSITION)
	t.tween_property(_cam, "fov", SEATED_FOV, TRANSITION)
	await t.finished

	is_seated = true
	_busy = false
	# IL CURSORE SI RICATTURA, e va detto perché è un cambio di stato che il
	# giocatore sente. Chi orchestra ha spento il controller per sedersi, e
	# spegnendolo il giocatore libera il cursore (giustamente: chi non guarda più
	# intorno non deve restare prigioniero della finestra). Da seduti si guarda
	# intorno di nuovo, quindi il cursore serve catturato.
	#
	# NON C'È UN TASTO PER LIBERARLO DA SEDUTI, ed è una scelta e non una
	# dimenticanza: ESC da seduti è già il tasto che chiude il terminale e la BBS, e
	# prenderlo qui vorrebbe dire rubarglielo — questo nodo è figlio di chi
	# orchestra, e in `_unhandled_input` i figli passano prima. La via d'uscita è
	# `E`: ci si alza, il controller torna acceso, e da lì ESC fa quel che ha
	# sempre fatto. Due tasti invece di uno, in cambio di nessun conflitto.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	seated.emit()


## Il mouse gira la testa, da seduti come in piedi.
##
## DA SEDUTI SOLO CON ALT: senza, `main.gd` consuma il movimento in `_input` e lo
## manda al puntatore sul vetro, e qui non arriva niente. Questo file non lo sa e non
## deve saperlo — riceve quello che gli arriva.
##
## `_unhandled_input` e non `_input`: gli schermi del CRT — il terminale, la BBS,
## le fasi — devono poter prendere quello che è loro prima che questo nodo ci metta
## le mani. Un movimento del mouse non lo vuole nessuno di loro, e infatti arriva
## sempre fin qui; una pressione di tasto invece sì, e non deve arrivarci.
func _unhandled_input(event: InputEvent) -> void:
	if not is_seated or _busy or _player == null or _cam == null:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var motion := event as InputEventMouseMotion
	if motion == null:
		return
	_player.rotate_y(-motion.relative.x * MOUSE_SENSITIVITY)
	_cam.rotation.x = clampf(
		_cam.rotation.x - motion.relative.y * MOUSE_SENSITIVITY,
		-PITCH_LIMIT, PITCH_LIMIT)


func _leave() -> void:
	_busy = true
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_player, "global_transform", _standing_xform, TRANSITION)
	t.tween_property(_cam, "rotation:x", _standing_pitch, TRANSITION)
	t.tween_property(_cam, "fov", _standing_fov, TRANSITION)
	await t.finished

	is_seated = false
	_busy = false
	left.emit()
