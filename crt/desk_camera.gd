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
const SEATED_FOV := 42.0

var is_seated := false

var _player: Node3D
var _cam: Camera3D
var _seat: Marker3D
var _standing_xform: Transform3D
var _standing_fov: float
var _standing_pitch: float
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
	# `rotation.x` positivo ALZA lo sguardo. Da seduti, con FOV verticale 42° e
	# vetro alto 0,24 m a 0,44 m di distanza, lo schermo occupa da −25,51° a
	# +3,90° rispetto all'orizzonte:
	#     asse a +11,50° → inquadra [−9,50°, +32,50°] → si vede il 46% dello
	#                      schermo, la sola parte alta;
	#     asse a −11,50° → inquadra [−32,50°, +9,50°] → schermo intero, con
	#                      margine sopra e sotto.
	# Verificato guardando, non solo calcolando (storia 1.3).
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_player, "global_transform", target, TRANSITION)
	t.tween_property(_cam, "rotation:x", euler.x, TRANSITION)
	t.tween_property(_cam, "fov", SEATED_FOV, TRANSITION)
	await t.finished

	is_seated = true
	_busy = false
	seated.emit()


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
