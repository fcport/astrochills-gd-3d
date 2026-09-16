## L'INCHIOSTRO NEL CIELO — `Ctrl+F2`.
##
## Qualcosa, lassù, spruzza inchiostro: prima un grumo nero che tiene la forma, poi una
## nube che si allarga per un minuto su un terzo del cielo e alla fine si dirada. Il
## perché delle due forme sta in `world/shaders/orrore_inchiostro.gdshader`.
##
## DOVE: davanti a chi lo chiama, quaranta gradi sull'orizzonte, cioè dove uno che guarda
## avanti lo vede senza cercarlo. Il getto va di traverso.
##
## I TEMPI, in secondi. Il grumo esce in poco più di un secondo e sta compatto fino al
## settimo, che è l'ordine di grandezza di uno pseudomorfo vero; poi cede. La nube si
## allarga come un fumo — il raggio cresce con la RADICE del tempo, che è come si
## allarga una cosa che diffonde, veloce all'inizio e poi sempre più piano — e si
## assottiglia mentre si allarga: la stessa quantità di nero su un cielo più grande.
class_name OrroreInchiostro
extends Orrore

const SHADER := "res://world/shaders/orrore_inchiostro.gdshader"

const ALTEZZA := 40.0
const ESCE := 1.2
const TIENE_FINO := 7.0
const CEDE_IN := 8.0
## Il raggio del grumo, in radianti: sei gradi e mezzo, dodici Lune.
const GRUMO := 0.115
## Quanto si allarga la nube: radianti per radice di secondo.
const DIFFONDE := 0.13
## Quanto dura prima di cominciare a diradarsi, e in quanto si dirada.
const DURA := 70.0
const DIRADA := 20.0
## Quanto scompare in fretta se gli si chiede di andarsene.
const VIA := 5.0

var _materiale: ShaderMaterial
var _via := 1.0
var _centro := Vector3.UP
var _getto := Vector3.RIGHT


func _comincia() -> void:
	var avanti := _davanti()
	var az := azimut_di(avanti)
	_centro = verso(az, ALTEZZA)
	# di traverso: novanta gradi da chi guarda, sull'orizzonte
	_getto = verso(az + 90.0, 0.0)
	_materiale = ShaderMaterial.new()
	_materiale.shader = load(SHADER) as Shader
	_materiale.set_shader_parameter("getto", _getto)
	_cupola("Inchiostro", _materiale)
	_segui_la_camera()
	_scrivi()


func _congeda() -> void:
	pass


func _avanza(delta: float) -> void:
	_segui_la_camera()
	if _in_uscita:
		_via = maxf(_via - delta / VIA, 0.0)
	_scrivi()
	if (_in_uscita and _via <= 0.0) or _tempo >= DURA + DIRADA:
		_chiudi()


func _scrivi() -> void:
	var t := _tempo
	var r := GRUMO * smoothstep(0.0, ESCE, t)
	# il getto lo spinge via dal punto in cui è uscito, e poi la spinta si esaurisce
	var deriva := 0.10 * (1.0 - exp(-t / 3.0))
	var coesione := 1.0
	var densita := 1.0
	if t > TIENE_FINO:
		coesione = 1.0 - smoothstep(0.0, CEDE_IN, t - TIENE_FINO)
		r = GRUMO + DIFFONDE * sqrt(t - TIENE_FINO)
		# LA STESSA QUANTITÀ SU UN CIELO PIÙ GRANDE: la densità scende con l'area, ma non
		# fino a sparire — una nube d'inchiostro vera resta nera al centro a lungo. Il
		# pavimento è ALTO, 0,85: a 0,45 la nube al trentesimo secondo lasciava le stelle al
		# settanta per cento, e non si vedeva che c'era
		densita = clampf(pow(GRUMO * 2.2 / r, 1.2), 0.85, 1.0)
	var dirada := 1.0 - smoothstep(DURA, DURA + DIRADA, t)
	_materiale.set_shader_parameter("centro", _centro.rotated(_centro.cross(_getto).normalized(), deriva))
	_materiale.set_shader_parameter("raggio", r)
	_materiale.set_shader_parameter("coesione", coesione)
	_materiale.set_shader_parameter("densita", densita * dirada)
	_materiale.set_shader_parameter("forza", _via)
	_materiale.set_shader_parameter("tempo", t)


## Il raggio di adesso, in radianti: per le sonde.
func raggio() -> float:
	return float(_materiale.get_shader_parameter("raggio")) if _materiale != null else 0.0
