## LE VENTOSE CONTRO IL CIELO — `Ctrl+F3`.
##
## Un braccio preme dall'altra parte del cielo come contro il vetro di un acquario, e
## striscia: entra da un orizzonte con la punta, passa alto davanti a chi l'ha chiamato
## e se ne va dall'orizzonte opposto. Le ventose, due file alternate, si attaccano e si
## staccano mentre avanza. Cosa è copiato da un braccio vero sta in
## `world/shaders/orrore_ventose.gdshader`.
##
## IL PERCORSO È UN CERCHIO MASSIMO che passa per due punti: l'entrata, sull'orizzonte
## ottanta gradi di lato rispetto a chi guarda, e un punto davanti a lui a cinquantacinque
## gradi d'altezza. Due punti bassi da parti opposte avrebbero dato un arco che passa
## sotto l'orizzonte davanti, o dritto allo zenit dove non guarda nessuno.
##
## STRISCIA A TRE GRADI AL SECONDO: il cielo lo attraversa in un minuto e mezzo. Una cosa
## grande che si muove piano è più grande di una che corre.
class_name OrroreVentose
extends Orrore

const SHADER := "res://world/shaders/orrore_ventose.gdshader"
const PELLE := "res://assets/textures/pelle-polpo/color.jpg"

const VELOCITA := 0.052
const LUNGHEZZA := 1.9
const LARGO := 0.14
const ENTRA_DI_LATO := 80.0
const ALTO := 55.0
## Quanto sotto l'orizzonte entra la punta, in gradi.
const SOTTO := 6.0
const LASCIA := 4.0

var _materiale: ShaderMaterial
var _forza := 1.0
var _testa := 0.0


func _comincia() -> void:
	var az := azimut_di(_davanti())
	var entrata := verso(az - ENTRA_DI_LATO, -SOTTO)
	var alto := verso(az, ALTO)
	_materiale = ShaderMaterial.new()
	_materiale.shader = load(SHADER) as Shader
	_materiale.set_shader_parameter("inizio", entrata)
	_materiale.set_shader_parameter("asse", entrata.cross(alto).normalized())
	_materiale.set_shader_parameter("lunghezza", LUNGHEZZA)
	_materiale.set_shader_parameter("largo", LARGO)
	if ResourceLoader.exists(PELLE):
		_materiale.set_shader_parameter("pelle", load(PELLE))
	_cupola("Ventose", _materiale)
	_segui_la_camera()


func _congeda() -> void:
	pass


func _avanza(delta: float) -> void:
	_segui_la_camera()
	_testa += VELOCITA * delta
	if _in_uscita:
		_forza = maxf(_forza - delta / LASCIA, 0.0)
	_materiale.set_shader_parameter("testa", _testa)
	_materiale.set_shader_parameter("tempo", _tempo)
	_materiale.set_shader_parameter("forza", _forza)
	_materiale.set_shader_parameter("energia", _energia_luna())
	# se n'è andato quando anche la radice ha passato l'orizzonte di là
	if (_in_uscita and _forza <= 0.0) or _testa > PI + LUNGHEZZA + 0.2:
		_chiudi()


## Dove sta la punta lungo il percorso, in radianti: per le sonde.
func testa() -> float:
	return _testa
