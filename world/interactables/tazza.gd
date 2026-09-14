## Una tazza: si riempie dalla moka, si beve col destro, e lanciata piena si svuota (D-244).
##
## LE TAZZE CI SONO GIÀ, e Federico ha chiesto di usare quelle: una sulla consolle della sala
## di controllo, una col piattino sul tavolo della cucina. Sono quella del servizio da tè di
## Poly Haven (`prop_blender.py`); prima erano soltanto cose da prendere in mano.
##
## IL CAFFÈ È UN DISCO dentro la tazza, alla quota a cui arriva, largo quanto la tazza è
## larga a quella quota. Le misure del modello sono prese dai vertici (`raggio_a`): il fondo
## interno a 7 mm, e la parete che si allarga salendo. A tazza piena il disco sta a 40 mm,
## cioè una quarantina di millilitri — un terzo di una moka da tre tazze.
##
## BERE È UN GESTO, e per due secondi la tazza non la muove la mano: sale verso la bocca, si
## inclina, il caffè cala, e torna giù. Col destro, perché E con le mani piene posa — e posare
## per sbaglio una tazza che si voleva bere sarebbe peggio che non poterla bere.
class_name Tazza
extends Carryable

## Il fondo interno e la quota del caffè a tazza piena, sull'asse del modello.
const FONDO := 0.007
const PIENA := 0.040

## Il bordo: dove la moka punta il becco.
const BORDO := 0.068

## Il raggio interno a varie quote, misurato sui vertici di `tazza.glb`. Il primo punto è
## estrapolato: sul fondo il modello non ha vertici vicino all'asse.
const QUOTE := [0.007, 0.020, 0.035, 0.050, 0.060]
const RAGGI := [0.009, 0.0173, 0.0269, 0.0349, 0.0353]

## Quanto dura il gesto del bere, e dentro il gesto quando il caffè comincia e finisce di
## calare.
const BEVI_SECONDI := 2.2
const BEVI_DA := 0.6
const BEVI_A := 1.6

## Di quanto la si inclina bevendo, verso la faccia.
const INCLINAZIONE_BERE := deg_to_rad(55.0)

## Sotto quanto la tazza è considerata rovesciata: il coseno fra il suo alto e la
## verticale. Settanta gradi e il caffè è fuori.
const ROVESCIATA := 0.35

## Quanta ce n'è dentro, da 0 a 1.
var livello := 0.0

var _caffe: MeshInstance3D
var _bevendo := false
var _bevi_t := 0.0
var _livello_prima := 0.0

## Lanciata piena: al primo urto il caffè esce. Vedi `lancia`.
var _rovescia_urtando := false


func _ready() -> void:
	super()
	var disco := CylinderMesh.new()
	disco.top_radius = 1.0
	disco.bottom_radius = 1.0
	disco.height = 0.002
	disco.radial_segments = 16
	disco.rings = 1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.09, 0.05)
	mat.roughness = 0.15
	_caffe = MeshInstance3D.new()
	_caffe.name = "Caffe"
	_caffe.mesh = disco
	_caffe.material_override = mat
	_caffe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_caffe)
	_aggiorna_caffe()


## Il raggio interno della tazza alla quota `quota`, interpolato fra le misure. PURA.
static func raggio_a(quota: float) -> float:
	if quota <= QUOTE[0]:
		return RAGGI[0]
	for i in range(1, QUOTE.size()):
		if quota <= QUOTE[i]:
			return lerpf(RAGGI[i - 1], RAGGI[i], inverse_lerp(QUOTE[i - 1], QUOTE[i], quota))
	return RAGGI[-1]


## La quota del caffè per un livello da 0 a 1. PURA.
static func quota_per(frazione: float) -> float:
	return lerpf(FONDO, PIENA, clampf(frazione, 0.0, 1.0))


func vuota() -> bool:
	return livello <= 0.0


## Il centro della bocca, dove la moka punta il becco.
func bocca() -> Vector3:
	return global_transform * Vector3(0.0, BORDO, 0.0)


## Il centro della superficie del caffè, o del fondo se è vuota.
func superficie() -> Vector3:
	return global_transform * Vector3(0.0, quota_per(livello), 0.0)


## Il caffè sale fino a `frazione`. Non cala mai: versare non toglie. In una tazza coricata
## non entra niente — e senza questa riga la moka e la tazza rovesciata si rimpallavano il
## caffè a ogni passo di fisica.
func riempi_a(frazione: float) -> void:
	if global_basis.y.dot(Vector3.UP) < ROVESCIATA:
		return
	livello = maxf(livello, clampf(frazione, 0.0, 1.0))
	_aggiorna_caffe()


func _aggiorna_caffe() -> void:
	_caffe.visible = livello > 0.001
	var q := quota_per(livello)
	var r := raggio_a(q) * 0.96
	_caffe.position = Vector3(0.0, q, 0.0)
	_caffe.scale = Vector3(r, 1.0, r)


# --- bere -------------------------------------------------------------------------

func puo_usare() -> bool:
	return not vuota() and not _bevendo and in_mano()


func prompt_usa() -> String:
	return "Bevi il caffè"


func usa() -> void:
	if not puo_usare():
		return
	_bevendo = true
	_bevi_t = 0.0
	_livello_prima = livello


func in_gesto() -> bool:
	return _bevendo


## Quanto la tazza è andata verso la bocca, da 0 a 1, a un istante del gesto. PURA.
static func verso_la_bocca(t: float) -> float:
	if t < BEVI_DA:
		return smoothstep(0.0, BEVI_DA, t)
	if t < BEVI_A:
		return 1.0
	return 1.0 - smoothstep(BEVI_A, BEVI_SECONDI, t)


## BEVENDO LA MANO LA DECIDE IL GESTO: la tazza sale a una spanna dalla faccia, appena sotto
## gli occhi, e si inclina verso chi beve.
func punta(mano: Transform3D, testa := Transform3D.IDENTITY) -> void:
	if not _bevendo:
		super(mano, testa)
		return
	var bocca_di_chi_beve := testa.origin - testa.basis.z * 0.13 - testa.basis.y * 0.06
	# L'alto della tazza gira verso chi la tiene: attorno al fianco, verso +z della mano.
	var inclinata := mano.basis * Basis(Vector3.RIGHT, INCLINAZIONE_BERE)
	var alla_bocca := Transform3D(inclinata, bocca_di_chi_beve)
	_mano = mano.interpolate_with(alla_bocca, verso_la_bocca(_bevi_t))


func lascia() -> void:
	# Chi posa a metà sorso smette di bere, e quello che è rimasto resta nella tazza.
	_bevendo = false
	super()


# --- rovesciarla ------------------------------------------------------------------

## LANCIATA PIENA SI SVUOTA. Federico: «se lanci la tazzina col caffè dentro, la tazzina si
## svuota». Al primo urto e non al lancio: in volo il caffè sta ancora dentro, e si vede.
func lancia(verso: Vector3, trascinamento := Vector3.ZERO) -> void:
	var piena := not vuota()
	super(verso, trascinamento)
	_rovescia_urtando = piena


func _physics_process(delta: float) -> void:
	super(delta)
	if _bevendo:
		_bevi_t += delta
		if _bevi_t >= BEVI_DA:
			livello = _livello_prima * (1.0 - clampf(inverse_lerp(BEVI_DA, BEVI_A, _bevi_t), 0.0, 1.0))
			_aggiorna_caffe()
		if _bevi_t >= BEVI_SECONDI:
			_bevendo = false
			livello = 0.0
			_aggiorna_caffe()
			# La coppia di C4 si chiude qui: il caffè è bevuto. L'ha aperta la moka mettendosi
			# a cuocere.
			Events.wait_activity_ended.emit(Moka.ACTIVITY)
			_annuncia()
		return
	if vuota():
		_rovescia_urtando = false
		return
	# E NON SOLO LANCIATA: una tazza piena che cade e resta coricata si è rovesciata, da
	# qualunque parte sia arrivata. Mentre la si tiene no — in mano sta dritta.
	var coricata := not in_mano() and global_basis.y.dot(Vector3.UP) < ROVESCIATA
	if coricata or (_rovescia_urtando and get_contact_count() > 0):
		_rovescia()


func _rovescia() -> void:
	_rovescia_urtando = false
	livello = 0.0
	_aggiorna_caffe()
	Log.info("caffe", "%s si è rovesciata" % nome)
	_annuncia()


func stato_da_ricordare() -> Dictionary:
	var voce := super()
	if voce.is_empty():
		return voce
	voce[&"livello"] = livello
	return voce


func torna_come_ricordato(voce: Dictionary) -> void:
	super(voce)
	livello = float(voce.get(&"livello", 0.0))
	_aggiorna_caffe()
