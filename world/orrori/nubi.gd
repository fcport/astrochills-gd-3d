## LE NUBI CHE PASSANO SUL CIELO — `Ctrl+F1`.
##
## Il cielo si comporta come la pelle del polpo: bande scure partono da un orizzonte e
## corrono verso l'altro, una dietro l'altra, e dove passano le stelle si spengono. Il
## perché di ogni scelta, e da dove viene il display, è in
## `world/shaders/orrore_nubi.gdshader`.
##
## PARTONO DA DIETRO LE SPALLE di chi le chiama, basse sull'orizzonte: le si vede
## arrivare da sopra la testa e allontanarsi davanti, che è il verso in cui una cosa
## passa sopra di te invece di venirti incontro.
##
## NON FINISCONO DA SOLE. Una pelle che fa le nubi le fa finché la preda si muove: si
## spengono quando le si chiede di andarsene, e l'ultima banda finisce il suo giro.
class_name OrroreNubi
extends Orrore

const SHADER := "res://world/shaders/orrore_nubi.gdshader"

## Quanto ci mettono ad accendersi e a spegnersi, in secondi.
const ENTRA := 4.0
const ESCE := 7.0

var _materiale: ShaderMaterial
var _forza := 0.0


func _comincia() -> void:
	_materiale = ShaderMaterial.new()
	_materiale.shader = load(SHADER) as Shader
	var dietro := -_davanti()
	_materiale.set_shader_parameter("sorgente", (dietro + Vector3.UP * 0.12).normalized())
	_cupola("Nubi", _materiale)
	_segui_la_camera()


func _congeda() -> void:
	pass


func _avanza(delta: float) -> void:
	_segui_la_camera()
	if _in_uscita:
		_forza = maxf(_forza - delta / ESCE, 0.0)
	else:
		_forza = minf(_forza + delta / ENTRA, 1.0)
	_materiale.set_shader_parameter("tempo", _tempo)
	_materiale.set_shader_parameter("forza", smoothstep(0.0, 1.0, _forza))
	if _in_uscita and _forza <= 0.0:
		_chiudi()


func forza() -> float:
	return _forza
