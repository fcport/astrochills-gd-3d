## Un fuoco del piano cottura, e la manopola che lo accende (D-244).
##
## PERCHÉ ESISTE. Federico: la moka «fa il caffè quando la metti sul fornello, non fa il
## caffè a caso». Prima bastava guardarla e premere E, e il caffè si faceva da solo. Adesso
## lo fa il fuoco, e il fuoco lo accende una manopola.
##
## IL NODO È LA MANOPOLA. Sta sulla striscia a destra del piano, ed è lì che si guarda e si
## preme E; il bruciatore che accende sta più in là, sulla griglia, a `fuoco` di distanza. Uno per
## fuoco e non un piano cottura con quattro manopole: ogni manopola si mira da sola, e un
## nodo che le avesse tutte dovrebbe capire quale si sta guardando.
##
## LA MANOPOLA SI GIRA, e per questo non è disegnata dentro la cucina: un pezzo del modello
## della stanza non può ruotare. È quella dello Smeg S64S (D-285): argento, rotonda, con la
## presa a barretta, e l'asse IN VERTICALE perché sta sul piano e non sul frontale. La tacca
## sulla barretta c'è perché una manopola girata di un quarto senza tacca non si distingue da
## una chiusa.
##
## NON SA COSA CI SIA SOPRA. È la moka a chiedere se sta su un fuoco acceso (`sotto_a`); il
## fuoco non tiene nessuna pentola, e non c'è niente da tenere allineato fra i due.
class_name Fornello
extends Interactable

const GROUP := &"fornello"

## Quanto lontano in pianta dal centro del bruciatore una pentola ci cuoce sopra. Il
## bruciatore è largo undici centimetri e la base della moka nove: quattro centimetri di
## scarto sono una moka appoggiata un po' storta sulla griglia, non una moka accanto.
const RAGGIO_SOPRA := 0.04

## E di quanto il fondo può stare sopra la griglia. Poco: una moka tenuta in mano sopra la
## fiamma non cuoce, perché nessuno ce la tiene quaranta secondi.
const ALTO_SOPRA := 0.03

## Quanto sopra o sotto la griglia può arrivare lo sguardo perché «posa» voglia dire «metti
## sul fuoco». Il raggio si ferma sulla cima dell'ingombro del bancone, quattro centimetri
## sotto la griglia, o sulla griglia stessa; più in là di una spanna si sta guardando altro.
const ALTO_SGUARDO := 0.15

## Un quarto di giro: aperta, la tacca va da mezzogiorno alle nove — dal muro verso i
## fuochi — cioè in senso antiorario per chi guarda dall'alto: il verso in cui si apre il gas.
const GIRO_APERTA := PI / 2.0

## La manopola dello S64S: una base tonda da 40 mm alta 6, e sopra la presa a barretta,
## lunga quanto la base, larga un centimetro e alta quattordici millimetri.
const RAGGIO_MANOPOLA := 0.020
const ALTA_BASE := 0.006
const BARRETTA := Vector3(0.010, 0.014, 0.036)

## La corona di fiamme: le lingue escono fra spartifiamma e cappellotto, di lato, e piegano
## verso l'alto.
const LINGUE := 18
const LUNGA_LINGUA := 0.016
const PIEGA_LINGUA := deg_to_rad(55.0)

## La memoria della casa lo ascolta: un fuoco lasciato acceso resta acceso (D-243).
signal cambiato

## Dove sta il centro del bruciatore, alla quota della griglia, rispetto alla manopola.
## Lo scrive `gen_blockout.py` da `geometria.FUOCHI`.
@export var fuoco := Vector3.ZERO

## Il raggio della corona e di quanto le fiamme nascono sotto la griglia. I fuochi non
## sono uguali - ausiliario, semirapido, rapido - e una corona sola, larga quanto il
## rapido, sull'ausiliario brucerebbe nel vuoto. Li scrive `gen_blockout.py` da
## `geometria.CAPPELLI` e `geometria.H_FIAMME`.
@export var corona := 0.042
@export var radice := -0.0275

var acceso := false

var _manopola: Node3D
var _fiamma: MultiMeshInstance3D
var _luce: OmniLight3D


func _ready() -> void:
	add_to_group(GROUP)
	add_to_group(MemoriaDelMondo.GRUPPO)
	_costruisci_manopola()
	_costruisci_fiamma()
	interacted.connect(_su_interazione)
	_applica()


func prompt() -> String:
	return "Spegni il fuoco" if acceso else "Accendi il fuoco"


func _su_interazione(_by: Node3D) -> void:
	acceso = not acceso
	_applica()
	cambiato.emit()


## Il centro del bruciatore, alla quota su cui si posa una pentola.
func centro() -> Vector3:
	return to_global(fuoco)


## Se una pentola col fondo in `fondo` sta sul bruciatore centrato in `centro_fuoco`.
## PURA, per il banco.
static func sta_sopra(centro_fuoco: Vector3, fondo: Vector3) -> bool:
	var in_pianta := Vector2(fondo.x - centro_fuoco.x, fondo.z - centro_fuoco.z).length()
	var sopra := fondo.y - centro_fuoco.y
	return in_pianta <= RAGGIO_SOPRA and sopra >= -0.01 and sopra <= ALTO_SOPRA


## Il fuoco su cui sta una pentola col fondo in `fondo`, o `null`.
static func sotto_a(tree: SceneTree, fondo: Vector3) -> Fornello:
	for n in tree.get_nodes_in_group(GROUP):
		var f := n as Fornello
		if f != null and sta_sopra(f.centro(), fondo):
			return f
	return null


## Il bruciatore guardato — `punto` è dove arriva lo sguardo — o `null`: il più vicino IN
## PIANTA entro `entro` metri, purché lo sguardo arrivi all'altezza del piano cottura.
##
## LO SGUARDO E NON LA MANO. La prima stesura cercava il fuoco più vicino alla mano che tiene
## la moka, e da in piedi davanti al bancone la mano sta venticinque centimetri oltre il
## bordo: la sonda non ha trovato un solo punto della cucina da cui la moka andasse sul fuoco.
## Lo sguardo arriva sul piano, sul fuoco che si vuole.
static func guardato(tree: SceneTree, punto: Vector3, entro: float) -> Fornello:
	if punto == Vector3.INF:
		return null
	var migliore: Fornello = null
	var d_min := entro
	for n in tree.get_nodes_in_group(GROUP):
		var f := n as Fornello
		if f == null:
			continue
		var c := f.centro()
		if absf(punto.y - c.y) > ALTO_SGUARDO:
			continue
		var d := Vector2(punto.x - c.x, punto.z - c.z).length()
		if d <= d_min:
			d_min = d
			migliore = f
	return migliore


func stato_da_ricordare() -> Dictionary:
	return {&"acceso": acceso}


func torna_come_ricordato(voce: Dictionary) -> void:
	acceso = bool(voce.get(&"acceso", false))
	_applica()


func _applica() -> void:
	_manopola.rotation.y = GIRO_APERTA if acceso else 0.0
	_fiamma.visible = acceso
	_luce.visible = acceso


func _costruisci_manopola() -> void:
	_manopola = Node3D.new()
	_manopola.name = "Manopola"
	add_child(_manopola)

	var argento := _materiale(Color(0.72, 0.73, 0.74), 0.35)
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = RAGGIO_MANOPOLA
	cilindro.bottom_radius = RAGGIO_MANOPOLA
	cilindro.height = ALTA_BASE
	cilindro.radial_segments = 16
	cilindro.rings = 1
	var base := MeshInstance3D.new()
	base.mesh = cilindro
	base.position = Vector3(0.0, ALTA_BASE / 2.0, 0.0)
	base.material_override = argento
	_manopola.add_child(base)

	# LA BARRETTA, lunga verso il muro: chiusa, la manopola punta a mezzogiorno.
	var presa := BoxMesh.new()
	presa.size = BARRETTA
	var barretta := MeshInstance3D.new()
	barretta.mesh = presa
	barretta.position = Vector3(0.0, ALTA_BASE + BARRETTA.y / 2.0, 0.0)
	barretta.material_override = argento
	_manopola.add_child(barretta)

	var scatola := BoxMesh.new()
	scatola.size = Vector3(0.003, 0.0015, 0.010)
	var tacca := MeshInstance3D.new()
	tacca.mesh = scatola
	tacca.position = Vector3(0.0, ALTA_BASE + BARRETTA.y + 0.0007, -BARRETTA.z / 2.0 + 0.007)
	tacca.material_override = _materiale(Color(0.045, 0.055, 0.06), 0.5)
	_manopola.add_child(tacca)

	# IL VOLUME DA MIRARE È PIÙ LARGO DELLA MANOPOLA, cinque centimetri per una da quattro:
	# a 640×360 una manopola da un metro è una decina di pixel, e mancarla di uno vorrebbe
	# dire mirare il piano. In profondità si ferma a sei centimetri e mezzo, cioè il passo
	# fra due manopole: più lungo, il volume di una coprirebbe quella accanto.
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.05, 0.04, 0.065)
	var col := CollisionShape3D.new()
	col.name = "Col"
	col.shape = forma
	col.position = Vector3(0.0, 0.015, 0.0)
	add_child(col)


func _costruisci_fiamma() -> void:
	var lingua := CylinderMesh.new()
	lingua.top_radius = 0.0
	lingua.bottom_radius = 0.0035
	lingua.height = LUNGA_LINGUA
	lingua.radial_segments = 5
	lingua.rings = 1
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = lingua
	mm.instance_count = LINGUE
	for i in LINGUE:
		var a := TAU * float(i) / float(LINGUE)
		var fuori := Vector3(cos(a), 0.0, sin(a))
		# Girare l'alto attorno a `alto × fuori` lo porta verso `fuori`: la lingua piega
		# verso l'esterno.
		var piega := Basis(Vector3.UP.cross(fuori).normalized(), PIEGA_LINGUA)
		var piede := fuori * corona + Vector3(0.0, radice, 0.0)
		mm.set_instance_transform(i,
			Transform3D(piega, piede + piega * Vector3(0.0, LUNGA_LINGUA / 2.0, 0.0)))
	var mat := ShaderMaterial.new()
	mat.shader = load("res://world/shaders/fiamma.gdshader") as Shader
	mat.set_shader_parameter(&"lunga", LUNGA_LINGUA)
	_fiamma = MultiMeshInstance3D.new()
	_fiamma.name = "Fiamma"
	_fiamma.multimesh = mm
	_fiamma.material_override = mat
	_fiamma.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fiamma.position = fuoco
	add_child(_fiamma)

	# UN FILO DI LUCE BLU sul piano e sul fondo della moka. Poca e corta: in una cucina
	# al buio un fuoco acceso si vede da lontano, ma non illumina la stanza.
	_luce = OmniLight3D.new()
	_luce.name = "LuceFiamma"
	_luce.light_color = Color(0.45, 0.58, 1.0)
	_luce.light_energy = 0.25
	_luce.omni_range = 0.7
	_luce.shadow_enabled = false
	_luce.position = fuoco + Vector3(0.0, 0.03, 0.0)
	add_child(_luce)


func _materiale(colore: Color, ruvido: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colore
	m.roughness = ruvido
	return m
