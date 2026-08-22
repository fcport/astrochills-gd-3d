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


func configure(player: Node3D, cam: Camera3D, seat: Marker3D) -> void:
	_player = player
	_cam = cam
	_seat = seat


func toggle() -> void:
	if _busy or _player == null:
		return
	if is_seated:
		_leave()
	else:
		_sit()


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
