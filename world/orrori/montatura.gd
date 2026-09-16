## LA MONTATURA CHE SI MUOVE DA SOLA — `Ctrl+F7`.
##
## Nessuno ha dato un comando, e il telescopio si gira verso di te. Ti punta la bocca del
## tubo in faccia e resta lì; se ti sposti, aspetta un istante e ti viene dietro. La cupola,
## se è aperta, gli va dietro da sola.
##
## LA PRIMA STESURA ANDAVA VERSO UN PUNTO VUOTO DEL CIELO, e si correggeva a scatti come chi
## insegue un satellite. Era il dettaglio giusto per chi fa questo mestiere, e non si capiva:
## Federico, «difficile che si capisca cosa sta succedendo». Un telescopio che si sposta di
## venti gradi verso il cielo è un telescopio che fa il suo lavoro. Uno che si gira verso chi
## gli sta accanto, e lo segue, non ha bisogno di spiegazioni.
##
## COME UN OCCHIO, NON COME UN GOTO. Non ti insegue fotogramma per fotogramma, che sarebbe
## una torretta: quando ti sei spostato di più di `SOGLIA` gradi aspetta `REAZIONE` secondi,
## e poi parte, alla velocità del motore. Si ferma su di te e aspetta la prossima mossa.
##
## MENTRE HAI L'OCCHIO ALL'OCULARE STA FERMO: non ha niente da cercare, lo stai già guardando
## da dentro.
##
## SI CHIEDE ALLA MONTATURA, NON AL BUS. `Events.telescope_aim_changed` è il fatto «il
## software ha mandato il tubo lì», e lo ascoltano le fasi del puntamento: annunciarlo
## vorrebbe dire far credere al software di aver dato un comando. Qui il software non ha
## fatto niente, ed è tutto il punto — il tubo si muove e lo schermo non lo sa.
##
## E SE NE VA RIMETTENDO IL TUBO DOV'ERA, alla velocità del motore: `finito` arriva quando è
## fermo.
class_name OrroreMontatura
extends Orrore

## Di quanti gradi ti devi spostare, visto dal tubo, perché si muova.
const SOGLIA := 2.5

## Quanto aspetta, dopo che ti sei spostato, prima di partire.
const REAZIONE := 0.6

var _montatura: TelescopeMount
var _giocatore: Player
var _oculare: Oculare
var _prima := Vector2.ZERO
var _bersaglio := Vector2.ZERO
var _verso_comandato := Vector3.ZERO
var _spostato_da := 0.0
var _tornando := false


func _comincia() -> void:
	_montatura = TelescopeMount.find_in(get_tree())
	_giocatore = Player.find_in(get_tree())
	if _montatura == null or _giocatore == null:
		push_warning("montatura che si muove: in scena manca la montatura o il giocatore")
		_chiudi()
		return
	_oculare = Oculare.find_in(get_tree())
	_prima = _montatura.dove()
	_puntalo(_verso_il_giocatore())
	Log.debug("orrori", "la montatura si gira da sola verso chi le sta accanto")


func _congeda() -> void:
	if _montatura == null or not is_instance_valid(_montatura):
		_chiudi()
		return
	_tornando = true
	_montatura.punta(_prima.x, _prima.y)


func _avanza(delta: float) -> void:
	if _montatura == null or not is_instance_valid(_montatura):
		return
	if _tornando:
		if not _montatura.in_moto():
			_chiudi()
		return
	if _oculare != null and _oculare.dentro():
		_spostato_da = 0.0
		return
	var verso := _verso_il_giocatore()
	if rad_to_deg(verso.angle_to(_verso_comandato)) <= SOGLIA:
		_spostato_da = 0.0
		return
	_spostato_da += delta
	if _spostato_da >= REAZIONE:
		_spostato_da = 0.0
		_puntalo(verso)


## Dall'apertura del tubo agli occhi del giocatore.
func _verso_il_giocatore() -> Vector3:
	var cam := _giocatore.camera()
	var occhi := cam.global_position if cam != null else _giocatore.global_position
	var d := occhi - _montatura.apertura()
	return d.normalized() if d.length_squared() > 1e-6 else _montatura.direzione()


func _puntalo(verso: Vector3) -> void:
	_verso_comandato = verso
	_bersaglio = equatoriali(verso)
	_montatura.punta(_bersaglio.x, _bersaglio.y)


## DA UN VERSO DEL MONDO AD ANGOLO ORARIO E DECLINAZIONE, in gradi.
##
## Trigonometria sferica classica, al contrario di `SkyGeometry.altezza`: altezza e azimut
## dal verso (nord +Z, est +X, come `Luna.direzione`), poi le coordinate orarie alla
## latitudine dell'osservatorio. L'angolo orario cresce verso ovest, come quello che la
## montatura riceve dal GOTO. Vale anche sotto l'orizzonte, ed è dove sta chi è in cupola.
## La sonda lo verifica sulla montatura vera, puntandola e chiedendole dove guarda.
static func equatoriali(v: Vector3) -> Vector2:
	var d := v.normalized()
	var alt := asin(clampf(d.y, -1.0, 1.0))
	var az := atan2(d.x, d.z)
	var lat := deg_to_rad(SkyGeometry.LATITUDINE)
	var sin_dec := sin(alt) * sin(lat) + cos(alt) * cos(lat) * cos(az)
	var dec := asin(clampf(sin_dec, -1.0, 1.0))
	var ha := atan2(-sin(az) * cos(alt), sin(alt) * cos(lat) - cos(alt) * sin(lat) * cos(az))
	return Vector2(rad_to_deg(ha), rad_to_deg(dec))


func bersaglio() -> Vector2:
	return _bersaglio


## Il verso che ha chiesto al tubo l'ultima volta.
func verso_comandato() -> Vector3:
	return _verso_comandato
