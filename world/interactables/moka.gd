## La moka: la si prende, la si mette sul fuoco, si accende, si aspetta, e il caffè si versa
## nelle tazze (D-244).
##
## PRIMA ERA UN INTERAGIBILE A TEMPI, e bastava guardarla: E riempiva, E la metteva «sul
## fuoco» senza muoversi dal bancone, un timer, E versava, E beveva. Federico: «premi fa il
## caffè, e che è sta merda? Non ha minimo senso». Il caffè adesso lo fanno le cose: la moka
## si porta sul fornello, la manopola accende il fuoco, e la moka cuoce solo finché sta su
## un fuoco acceso. La sequenza non è scritta da nessuna parte; è quello che succede.
##
## È UNA COSA CHE SI PRENDE IN MANO (`Carryable`), e quindi cade, si lancia, e la casa si
## ricorda dove la si è lasciata e se c'è dentro il caffè (D-243).
##
## COMPARE COMPRANDOLA, come prima: l'articolo `&"moka"` del terminale (3.2). Finché non è
## comprata non si vede, non si tocca e non ferma niente. Federico: «finché non la si
## acquista, la moka che fa il caffè non la teniamo» — e la moka disegnata sul fuoco, che
## c'era sempre e non faceva niente, è uscita dal modello della cucina.
##
## NESSUN BONUS. Un caffè fatto non tocca punteggi né lire: è l'attività del registro FARE
## dell'attesa, e verso la telemetria il contratto resta la coppia `wait_activity_started/
## ended(&"caffe")` — aperta quando la moka comincia a cuocere, chiusa quando il caffè è
## bevuto (`Tazza`).
class_name Moka
extends Carryable

## L'articolo che la fa comparire.
const ITEM := &"moka"

## Il marcatore dell'attività per il condotto di misura (C4).
const ACTIVITY := &"caffe"

## `GRUPPO` e non `GROUP`: quel nome l'ha già `Carryable`, ed è il gruppo di tutto quello
## che si prende in mano.
const GRUPPO := &"moka"

## Quanto sta sul fuoco prima che il caffè salga. Decine di secondi, percepibili: una moka
## vera ci mette tre o quattro minuti, e qui l'attesa piccola deve stare dentro quella
## grande senza mangiarsela. Segue il tempo scalato, quindi F1–F4 la accelerano.
const BREW_SECONDS := 40.0

## Quante tazze fa. È una caffettiera conica da tre tazze (`tools/moka_blender.py`).
const TAZZINE := 3

## Il becco, sul modello: misurato dai vertici di `moka.glb` — il punto più avanzato del
## corpo sopra i dieci centimetri, dalla parte opposta al manico.
const BECCO := Vector3(0.0, 0.137, -0.052)

## Quanto vicino a un fuoco, in pianta, deve arrivare lo sguardo perché E metta la moka su
## quel fuoco invece di posarla dove capita. Quindici centimetri: poco più di metà della
## distanza fra il fuoco davanti e quello dietro, e vince il più vicino.
const PORTATA_FUOCO := 0.15

## Il gesto del versare: quanto dura, e dentro il gesto quando il caffè scende.
const VERSA_SECONDI := 1.8
const VERSA_DA := 0.55
const VERSA_A := 1.3

## Quanto si inclina versando, e di quanto il becco può stare fuori dalla bocca della tazza
## perché il caffè ci entri invece di finire sul tavolo.
const INCLINAZIONE := deg_to_rad(65.0)
const MIRA_BECCO := 0.05

## Se in tre secondi il becco non è arrivato sopra la tazza, il gesto si lascia perdere:
## la tazza era dietro qualcosa, o troppo lontana per arrivarci col braccio.
const VERSA_ATTESA_MAX := 3.0

## Quante tazze di caffè ci sono dentro.
var dosi := 0

## Quanto è andata avanti sul fuoco, da 0 a 1. Tolta dal fuoco non torna indietro: «non
## scade niente» (3.3).
var cottura := 0.0

var _presente := false
var _layer := 0
var _maschera := 0

var _versando: Tazza = null
## Da che parte guarda il becco per tutto il gesto. Si decide UNA VOLTA, all'inizio: vedi
## `usa_su`.
var _versa_girata := Basis.IDENTITY
var _versa_t := 0.0
var _versa_attesa := 0.0
var _getto: MeshInstance3D
var _vapore: CPUParticles3D


func _ready() -> void:
	super()
	add_to_group(GRUPPO)
	_layer = collision_layer
	_maschera = collision_mask
	_costruisci_getto()
	_costruisci_vapore()
	Events.item_purchased.connect(_on_item_purchased)
	_apply_presence(Game.profile.owns(ITEM))


static func find_in(tree: SceneTree) -> Moka:
	return tree.get_first_node_in_group(GRUPPO) as Moka


# --- la logica pura: statica, senza SceneTree, per il banco ----------------------

## La cottura dopo `delta` secondi. Avanza solo su un fuoco acceso e con la moka vuota: una
## moka col caffè dentro, rimessa sul fuoco, non ne fa altro.
static func avanza_cottura(prima: float, dosi_dentro: int, sul_fuoco_acceso: bool,
		delta: float) -> float:
	if dosi_dentro > 0 or not sul_fuoco_acceso:
		return prima
	return minf(1.0, prima + delta / BREW_SECONDS)


## Se si può versare: c'è caffè, e la tazza è vuota.
static func puo_versare(dosi_dentro: int, tazza_vuota: bool) -> bool:
	return dosi_dentro > 0 and tazza_vuota


## Quanto è inclinata, da 0 a 1, a un istante del gesto del versare.
static func inclinazione_a(t: float) -> float:
	if t < VERSA_DA:
		return smoothstep(0.0, VERSA_DA, t)
	if t < VERSA_A:
		return 1.0
	return 1.0 - smoothstep(VERSA_A, VERSA_SECONDI, t)


# --- sul fuoco ------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	super(delta)
	if not _presente:
		return
	if _versando != null:
		_avanza_versata(delta)
	var fuoco := _fuoco_sotto()
	var acceso := fuoco != null and fuoco.acceso
	if acceso and dosi == 0 and cottura == 0.0:
		Events.wait_activity_started.emit(ACTIVITY)
	var prima := cottura
	cottura = avanza_cottura(cottura, dosi, acceso, delta)
	if prima < 1.0 and cottura >= 1.0:
		dosi = TAZZINE
		cottura = 0.0
		Log.info("caffe", "il caffè è salito")
		_annuncia()
	# IL VAPORE DAL BECCO è l'unica cosa che dice «ci siamo» finché i suoni non ci sono: esce
	# negli ultimi secondi, quando la moka borbotta, e continua se la si lascia sul fuoco.
	_vapore.emitting = acceso and (dosi > 0 or cottura > 0.8)


## Il fuoco su cui sta, o `null`. In mano no, e nemmeno coricata.
func _fuoco_sotto() -> Fornello:
	if in_mano() or global_basis.y.dot(Vector3.UP) < 0.9:
		return null
	return Fornello.sotto_a(get_tree(), global_position)


func _fuoco_vicino() -> Fornello:
	return Fornello.guardato(get_tree(), punto_mirato(), PORTATA_FUOCO)


func prompt_posa() -> String:
	if _fuoco_vicino() != null:
		return "Metti la moka sul fuoco"
	return super()


## VICINO A UN FUOCO LA SI METTE SUL FUOCO, dritta e al centro della griglia, col manico
## verso chi la mette. È la stessa scelta della camera CCD, che vicino al fuoco del
## telescopio si avvita: lasciarla cadere dove capita la metterebbe mezza fuori dalla
## griglia, e il giocatore dovrebbe centrarla a colpi di E.
func posa() -> void:
	var f := _fuoco_vicino()
	if f == null:
		Log.info("caffe", "moka posata dove capita: nessun fuoco guardato (sguardo a %s)" % punto_mirato())
		super()
		return
	lascia()
	# `teletrasporta` E NON `global_transform`: vedi lì perché, è la moka che cadeva (D-245).
	teletrasporta(Transform3D(Basis.IDENTITY, f.centro() + Vector3(0.0, 0.003, 0.0)))
	Log.info("caffe", "moka messa su %s a %s" % [f.name, global_position])
	_controlla_sul_fuoco.call_deferred(f)


## Un secondo dopo averla messa sul fuoco, se non ci sta più lo si scrive, e dove è finita.
## Federico l'ha vista cadere dopo «Metti la moka sul fuoco»; la sonda no.
func _controlla_sul_fuoco(f: Fornello) -> void:
	await get_tree().create_timer(1.0).timeout
	if not in_mano() and Fornello.sotto_a(get_tree(), global_position) != f:
		Log.warn("caffe", "la moka messa su %s un secondo dopo sta a %s" % [f.name, global_position])


# --- versare ---------------------------------------------------------------------

func puo_usare_su(bersaglio: Object) -> bool:
	var t := bersaglio as Tazza
	return t != null and _versando == null and in_mano() and puo_versare(dosi, t.vuota())


func prompt_usa_su(_bersaglio: Object) -> String:
	return "Versa il caffè nella tazza"


func usa_su(bersaglio: Object) -> void:
	if not puo_usare_su(bersaglio):
		return
	_versando = bersaglio as Tazza
	_versa_t = 0.0
	_versa_attesa = 0.0
	# IL VERSO DEL BECCO SI FISSA ADESSO, dalla mano alla tazza, e non si ricalcola. La prima
	# stesura lo ricavava a ogni passo da dove stava la moka: il punto voluto si spostava con
	# lei, e la sonda l'ha vista ferma a sedici centimetri dal bersaglio, senza toccare niente,
	# a rimbalzare fra due pose — inseguiva un bersaglio che scappava della stessa quantità.
	var bocca := _versando.bocca()
	var verso := Vector3(bocca.x - global_position.x, 0.0, bocca.z - global_position.z)
	if verso.length() < 0.01:
		verso = -global_basis.z
	_versa_girata = Basis.looking_at(verso.normalized(), Vector3.UP)
	# VERSANDO NON LA SI URTA. La moka va sopra la tazza inseguendo la mano, e nella prima
	# corsa della sonda ci è arrivata di fianco e l'ha rovesciata: poi versava in una tazza
	# coricata, all'infinito. Chi versa non tocca la tazza col bricco, e qui nemmeno.
	add_collision_exception_with(_versando)


func in_gesto() -> bool:
	return _versando != null


## VERSANDO LA MANO LA DECIDE IL GESTO: la moka va sopra la tazza col becco verso di lei,
## e si inclina. La si porta lì inseguendo come sempre (`Carryable`), quindi se in mezzo
## c'è qualcosa, il qualcosa vince.
func punta(mano: Transform3D, testa := Transform3D.IDENTITY) -> void:
	if _versando == null:
		super(mano, testa)
		return
	# `looking_at` gira il -z verso il bersaglio, ed è il becco: `_versa_girata` l'ha fissato
	# `usa_su`.
	var inclinata := _versa_girata * Basis(Vector3.RIGHT, -INCLINAZIONE * inclinazione_a(_versa_t))
	var sopra := _versando.bocca() + Vector3.UP * 0.05
	_mano = Transform3D(inclinata, sopra - inclinata * BECCO)


func _avanza_versata(delta: float) -> void:
	var t := _versando
	# Una tazza presa in mano da qualcun altro, o rovesciata, non la si insegue più.
	if not is_instance_valid(t) or t.in_mano() or t.global_basis.y.dot(Vector3.UP) < 0.8:
		_smetti_di_versare()
		return
	var becco := global_transform * BECCO
	var sopra := Vector2(becco.x - t.bocca().x, becco.z - t.bocca().z).length() <= MIRA_BECCO
	# FINCHÉ IL BECCO NON È SOPRA LA TAZZA IL CAFFÈ NON SCENDE: il gesto si ferma sull'orlo
	# dell'inclinazione e aspetta la moka, invece di versare sul tavolo.
	if _versa_t >= VERSA_DA and not sopra and _versa_t < VERSA_A:
		_versa_attesa += delta
		if _versa_attesa >= VERSA_ATTESA_MAX:
			_smetti_di_versare()
		return
	_versa_t += delta
	if _versa_t >= VERSA_DA and _versa_t <= VERSA_A:
		t.riempi_a(inverse_lerp(VERSA_DA, VERSA_A, _versa_t))
		_mostra_getto(becco, t.superficie())
	else:
		_getto.visible = false
	if _versa_t >= VERSA_SECONDI:
		t.riempi_a(1.0)
		dosi -= 1
		_smetti_di_versare()
		_annuncia()
		t._annuncia()


func _smetti_di_versare() -> void:
	if is_instance_valid(_versando):
		remove_collision_exception_with(_versando)
	_versando = null
	_getto.visible = false


func lascia() -> void:
	if _versando != null:
		_smetti_di_versare()
	super()


## Il filo di caffè dal becco alla superficie: un cilindro alto un metro, schiacciato e
## stirato fra i due punti.
func _mostra_getto(da: Vector3, a: Vector3) -> void:
	var lungo := a - da
	if lungo.length() < 0.005:
		_getto.visible = false
		return
	var fianco := lungo.cross(Vector3.FORWARD)
	if fianco.length() < 0.0001:
		fianco = lungo.cross(Vector3.RIGHT)
	fianco = fianco.normalized()
	var fronte := fianco.cross(lungo.normalized())
	_getto.global_transform = Transform3D(Basis(fianco, lungo, fronte), (da + a) / 2.0)
	_getto.visible = true


func _costruisci_getto() -> void:
	var filo := CylinderMesh.new()
	filo.top_radius = 0.0025
	filo.bottom_radius = 0.0035
	filo.height = 1.0
	filo.radial_segments = 6
	filo.rings = 1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.11, 0.06)
	mat.roughness = 0.2
	_getto = MeshInstance3D.new()
	_getto.name = "Getto"
	_getto.mesh = filo
	_getto.material_override = mat
	_getto.top_level = true
	_getto.visible = false
	add_child(_getto)


func _costruisci_vapore() -> void:
	var quadro := QuadMesh.new()
	quadro.size = Vector2(0.025, 0.025)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	quadro.material = mat
	var sfuma := Gradient.new()
	sfuma.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	sfuma.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.28), Color(1, 1, 1, 0.0)])
	_vapore = CPUParticles3D.new()
	_vapore.name = "Vapore"
	_vapore.mesh = quadro
	_vapore.amount = 10
	_vapore.lifetime = 1.4
	_vapore.emitting = false
	_vapore.local_coords = false
	_vapore.position = BECCO + Vector3(0.0, 0.01, 0.0)
	_vapore.direction = Vector3.UP
	_vapore.spread = 20.0
	_vapore.initial_velocity_min = 0.03
	_vapore.initial_velocity_max = 0.08
	_vapore.gravity = Vector3(0.0, 0.05, 0.0)
	_vapore.scale_amount_min = 0.6
	_vapore.scale_amount_max = 1.3
	_vapore.color_ramp = sfuma
	add_child(_vapore)


# --- comparire comprandola ------------------------------------------------------

func _on_item_purchased(id: StringName) -> void:
	if id == ITEM:
		_apply_presence(true)


## Accesa o spenta nel mondo. SPENTA non si vede, è congelata e non ha collisione: niente
## da mirare, niente contro cui cadere, e la rete non la guarda (`freeze`). Idempotente:
## ricomprarla non la sposta e non le toglie il caffè.
func _apply_presence(present: bool) -> void:
	if present == _presente and present == visible:
		return
	_presente = present
	visible = present
	freeze = not present
	collision_layer = _layer if present else 0
	collision_mask = _maschera if present else 0
	if not present:
		_vapore.emitting = false


func presente() -> bool:
	return _presente


func stato_da_ricordare() -> Dictionary:
	var voce := super()
	if voce.is_empty():
		return voce
	voce[&"dosi"] = dosi
	voce[&"cottura"] = cottura
	return voce


func torna_come_ricordato(voce: Dictionary) -> void:
	super(voce)
	dosi = int(voce.get(&"dosi", 0))
	cottura = float(voce.get(&"cottura", 0.0))
