## UN ORRORE COSMICO: la forma comune di tutto quello che sta in `world/orrori/`.
##
## Sono cose della storia che la storia non ha ancora: non si sa in che notte arrivino,
## né cosa le chiami. Adesso le apre `debug/orrori.gd` con `Ctrl+F1`…`Ctrl+F8`, per
## guardarle; quando la storia ci sarà, le aprirà lei, e questi file restano.
##
## IL CONTRATTO È QUELLO DEL TENTACOLO E DELL'OCCHIO: `inizia()` la fa cominciare,
## `finisci()` le chiede di andarsene — e una cosa grande quanto il cielo non sparisce in
## un fotogramma, quindi se ne va a modo suo e alla fine emette `finito`. Chi l'ha
## aperta libera il nodo lì, non prima.
##
## E IL TEMPO PASSA DA `passo()`, pubblico, per la stessa ragione di `Tentacolo.passo()`:
## in headless un fotogramma dura un millesimo di secondo, e una sonda che aspettasse i
## fotogrammi veri guarderebbe un minuto di cielo in sessanta millesimi.
class_name Orrore
extends Node3D

## Se n'è andato del tutto: il nodo si può liberare.
signal finito

## Il raggio della cupola su cui si disegnano gli orrori del cielo, in metri.
##
## TREMILANOVECENTO, cioè appena dentro i quattromila a cui la camera smette di
## disegnare, e fuori da tutto il resto: il punto più lontano dell'occhio sta a 3266
## metri, le braccia all'orizzonte a 3500. Una cupola più vicina passerebbe davanti a
## loro e le coprirebbe; più lontana, la taglierebbe il piano della camera.
const CUPOLA := 3900.0

var _attivo := false
var _in_uscita := false
var _tempo := 0.0


## Comincia. Chiamarlo di nuovo non fa niente.
func inizia() -> void:
	if _attivo:
		return
	_attivo = true
	_in_uscita = false
	_tempo = 0.0
	_comincia()


## Gli chiede di andarsene; alla fine arriva `finito`.
func finisci() -> void:
	if not _attivo or _in_uscita:
		return
	_in_uscita = true
	_congeda()


## Vero da `inizia()` a `finito`.
func attivo() -> bool:
	return _attivo


## Vero da `finisci()` a `finito`.
func in_uscita() -> bool:
	return _in_uscita


## Da quanti secondi è cominciato.
func tempo() -> float:
	return _tempo


func _process(delta: float) -> void:
	passo(delta)


func passo(delta: float) -> void:
	if not _attivo:
		return
	_tempo += delta
	_avanza(delta)


## Da chiamare quando se n'è andato davvero.
func _chiudi() -> void:
	_attivo = false
	_in_uscita = false
	finito.emit()


# --- da riscrivere ------------------------------------------------------------------

func _comincia() -> void:
	pass


func _congeda() -> void:
	_chiudi()


func _avanza(_delta: float) -> void:
	pass


# --- in comune ----------------------------------------------------------------------

## La camera che sta disegnando adesso: quella del giocatore, o quella dell'oculare se
## qualcuno ci ha l'occhio dentro.
func _camera() -> Camera3D:
	return get_viewport().get_camera_3d() if is_inside_tree() else null


## Dove sta guardando chi guarda, in pianta: il verso della camera schiacciato
## sull'orizzonte. Se la camera guarda dritta in su o non c'è, il nord.
func _davanti() -> Vector3:
	var cam := _camera()
	if cam == null:
		return Vector3.BACK
	var d := -cam.global_basis.z
	d.y = 0.0
	return d.normalized() if d.length_squared() > 1e-4 else Vector3.BACK


## Un verso del cielo da azimut (gradi, da nord verso est) e altezza (gradi), con la
## convenzione di `Luna.direzione()`: nord +Z, est +X.
static func verso(azimut: float, altezza: float) -> Vector3:
	return Luna.direzione(altezza, azimut)


## L'azimut, in gradi, di un verso del mondo.
static func azimut_di(v: Vector3) -> float:
	return rad_to_deg(atan2(v.x, v.z))


## La cupola del cielo: una sfera vista da dentro, che segue la camera. Il materiale lo
## decide chi la usa.
func _cupola(nome: String, materiale: Material) -> MeshInstance3D:
	var sfera := SphereMesh.new()
	sfera.radius = CUPOLA
	sfera.height = CUPOLA * 2.0
	sfera.radial_segments = 96
	sfera.rings = 48
	var m := MeshInstance3D.new()
	m.name = nome
	m.mesh = sfera
	m.material_override = materiale
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# la sfera è grande quanto il mondo: un AABB che la contiene tutta non va mai
	# scartato, ed è quello che serve
	m.extra_cull_margin = CUPOLA
	add_child(m)
	return m


## Tiene la cupola centrata sulla camera: il cielo è all'infinito, e una cupola che
## restasse ferma si vedrebbe spostarsi camminando.
func _segui_la_camera() -> void:
	var cam := _camera()
	if cam != null:
		global_position = cam.global_position


## La luce che arriva dalla Luna adesso, come energia della luce in scena: gli orrori
## disegnati senza luce la usano per non essere più chiari della notte che hanno attorno.
func _energia_luna() -> float:
	var luna := LuceDiLuna.find_in(get_tree()) if is_inside_tree() else null
	return luna.light_energy if luna != null else LuceDiLuna.ENERGIA_CIELO


static func trova(n: Node, classe: String) -> Node:
	if n == null:
		return null
	if n.get_script() != null and (n.get_script() as Script).get_global_name() == classe:
		return n
	if n.is_class(classe):
		return n
	for f in n.get_children():
		var t := trova(f, classe)
		if t != null:
			return t
	return null
