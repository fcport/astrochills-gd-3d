## Una macchia di caffè sul pavimento, o su qualunque piano ci sia finita sopra (D-251).
##
## PERCHÉ ESISTE. Federico, giocando, dopo aver lanciato la tazza piena: «non trovo neanche le
## chiazze». La tazza si svuotava e il caffè spariva nel nulla (D-244), e il mocio che doveva
## pulirlo non c'era. Adesso quello che esce dalla tazza cade sul primo piano che trova, e ci
## resta finché qualcuno non va a prendere il mocio (`Mocio`).
##
## È UN RETTANGOLO APPOGGIATO E NON UNA `Decal`. Una decal si stampa su tutto quello che le sta
## dentro — la tazza rotolata lì accanto, la gamba del tavolo — mentre una pozza sta su un piano.
## Il rettangolo sta tre millimetri sopra, girato come il piano che il caffè ha trovato, e la
## forma della pozza la disegna lo shader (`macchia.gdshader`).
##
## SI RICORDA, ma non come le cose che si prendono in mano. Quelle esistono nella scena, e il file
## dice solo dove stanno; una macchia nella scena non c'è, e va RIFATTA. Le rifà `MemoriaDelMondo`,
## da una lista sua (`WorldState.macchie`).
class_name Macchia
extends MeshInstance3D

const GRUPPO := &"macchia"

const SHADER := preload("res://world/shaders/macchia.gdshader")

## I millilitri di una tazza piena: il disco del caffè arriva a 40 mm (`Tazza.PIENA`).
const ML_TAZZA := 40.0

## Quanto è spessa una pozza su un pavimento liscio, in metri. Un millimetro e mezzo: meno
## dell'altezza a cui l'acqua ferma smette di allargarsi (è sui due millimetri e mezzo, quella
## della goccia che sta in piedi), perché un caffè versato da una tazza non si posa fermo — arriva
## con la velocità della caduta e si stende.
const SPESSORE := 0.0015

## LANCIATA NON VERSA, SCHIZZA: lo stesso caffè su una superficie larga il doppio, cioè un
## raggio una volta e quattro, e le gocce attorno.
const SCHIZZO := 1.4

## Sotto questo raggio resta qualche goccia, e una pozza più piccola non si vedrebbe.
const RAGGIO_MINIMO := 0.025

## Quanto il rettangolo è più largo del raggio: il bordo è mosso, e le gocce stanno fuori.
const ALONE := 1.9

## Fin dove arriva davvero la pozza, in raggi: il lobo più largo che disegna lo shader.
const BORDO_MASSIMO := 1.3

## Quanto sta sopra il piano, in metri.
const SOLLEVATA := 0.003

## Quanti secondi di mocio servono per una macchia da dieci centimetri di raggio. Una più
## grande ne vuole di più, in proporzione all'area: la pozza di una tazza lanciata, cinque.
const SECONDI_PULIZIA := 3.0

## Quanto sotto il punto da cui esce si cerca dove cade il caffè, e quante cose che si prendono
## in mano si scavalcano cercandolo.
const CADUTA := 4.0
const STRATI := 4

## C'è qualcosa di nuovo da ricordare: la macchia è nata, o il mocio ci è passato sopra.
signal cambiata

var raggio := 0.09
## Il seme della forma: due macchie della stessa tazza non sono uguali.
var seme := 0.0
var schizzata := false
## Quanto ne resta, da 1 (appena versata) a 0 (pulita del tutto).
var sporco := 1.0

var _mat: ShaderMaterial


func _ready() -> void:
	add_to_group(GRUPPO)
	var piano := PlaneMesh.new()
	piano.size = Vector2.ONE * raggio * ALONE * 2.0
	mesh = piano
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter(&"seme", seme)
	_mat.set_shader_parameter(&"alone", ALONE)
	_mat.set_shader_parameter(&"schizzi", 1.0 if schizzata else 0.0)
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_applica()


# --- la logica pura: statica, per il banco --------------------------------------

## Il raggio della pozza fatta da `livello` di tazza. PURA.
##
## È IL CAFFÈ CHE C'ERA, steso: il volume diviso lo spessore è l'area, e dall'area il raggio.
## Una tazza piena fa nove centimetri, lanciata tredici; un fondo di tazza, tre.
static func raggio_per(livello: float, lanciata: bool) -> float:
	var volume := clampf(livello, 0.0, 1.0) * ML_TAZZA * 1e-6
	var r := sqrt(volume / (PI * SPESSORE))
	if lanciata:
		r *= SCHIZZO
	return maxf(r, RAGGIO_MINIMO)


## Quanto sporco resta di una macchia di raggio `r` dopo `delta` secondi di mocio. PURA.
static func dopo_strofinata(prima: float, delta: float, r: float) -> float:
	var secondi := SECONDI_PULIZIA * maxf(0.4, pow(r / 0.10, 2.0))
	return maxf(0.0, prima - delta / secondi)


## Se il punto `p` sta sopra la macchia posata con la trasformata `xf`, allargata di `margine`.
## PURA. Si guarda sul piano della macchia, e poco sopra o sotto: un punto sul tavolo non sta
## sopra la macchia per terra sotto il tavolo.
static func copre(xf: Transform3D, r: float, p: Vector3, margine := 0.0) -> bool:
	var locale := xf.affine_inverse() * p
	return absf(locale.y) <= 0.12 \
		and Vector2(locale.x, locale.z).length() <= r * BORDO_MASSIMO + margine


## La trasformata di una macchia caduta in `punto` su un piano di normale `normale`, girata di
## `giro` attorno alla normale. PURA. L'alto è la normale: sul pavimento guarda in su, sul prato
## in pendenza segue la pendenza.
static func trasformata_su(punto: Vector3, normale: Vector3, giro: float) -> Transform3D:
	var su := normale.normalized()
	var riferimento := Vector3.FORWARD if absf(su.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var fianco := riferimento.cross(su).normalized()
	var base := Basis(fianco, su, fianco.cross(su)).rotated(su, giro)
	return Transform3D(base, punto + su * SOLLEVATA)


# --- nella scena --------------------------------------------------------------------

## La macchia sotto `punto`, allargata di `margine`, o `null`. Se ce n'è più d'una, la più vicina.
static func sotto(tree: SceneTree, punto: Vector3, margine := 0.0) -> Macchia:
	if punto == Vector3.INF:
		return null
	var migliore: Macchia = null
	var d_min := INF
	for n in tree.get_nodes_in_group(GRUPPO):
		var m := n as Macchia
		if m == null or m.is_queued_for_deletion():
			continue
		if not copre(m.global_transform, m.raggio, punto, margine):
			continue
		var d := m.global_position.distance_to(punto)
		if d < d_min:
			d_min = d
			migliore = m
	return migliore


## IL CAFFÈ ESCE DA `da` E CADE: dove arriva, resta la macchia. La chiama la tazza che si
## rovescia (`Tazza._rovescia`), che si esclude da sola.
##
## IL PRIMO PIANO SOTTO, sulla geometria che si vede (`Corazza.LAYER_APPOGGI`): il pavimento, o
## il tavolo se la tazza si è coricata sul tavolo. SI SCAVALCANO LE COSE CHE SI PRENDONO IN MANO,
## che stanno anche loro su quel layer: una macchia sul piattino resterebbe a mezz'aria appena
## qualcuno sposta il piattino.
static func versa(chi: CollisionObject3D, da: Vector3, livello: float, lanciata: bool) -> Macchia:
	if livello <= 0.0 or not chi.is_inside_tree():
		return null
	var spazio := chi.get_world_3d().direct_space_state
	var giu := PhysicsRayQueryParameters3D.create(da + Vector3.UP * 0.02, da + Vector3.DOWN * CADUTA)
	giu.collision_mask = Corazza.LAYER_APPOGGI
	var escludi: Array[RID] = [chi.get_rid()]
	for _i in STRATI:
		giu.exclude = escludi
		var colpo := spazio.intersect_ray(giu)
		if colpo.is_empty():
			return null
		if colpo["collider"] is Carryable:
			escludi.append(colpo["rid"])
			continue
		var m := Macchia.new()
		m.name = "Macchia"
		m.raggio = raggio_per(livello, lanciata)
		m.schizzata = lanciata
		m.seme = randf() * 100.0
		var xf := trasformata_su(colpo["position"], colpo["normal"], randf() * TAU)
		var memoria := MemoriaDelMondo.find_in(chi.get_tree())
		if memoria != null:
			memoria.aggiungi_macchia(m, xf)
		else:
			chi.get_parent().add_child(m)
			m.global_transform = xf
		Log.info("caffe", "macchia da %.0f cm di raggio a %s" % [m.raggio * 100.0, m.global_position])
		return m
	return null


## Il mocio ci passa sopra per `delta` secondi. Pulita del tutto, se ne va.
func strofina(delta: float) -> void:
	if is_queued_for_deletion():
		return
	sporco = dopo_strofinata(sporco, delta, raggio)
	_applica()
	cambiata.emit()
	if sporco <= 0.0:
		Log.info("caffe", "macchia pulita a %s" % global_position)
		queue_free()


func _applica() -> void:
	if _mat != null:
		_mat.set_shader_parameter(&"sporco", sporco)


func stato_da_ricordare() -> Dictionary:
	return {&"xf": global_transform, &"raggio": raggio, &"seme": seme,
		&"schizzata": schizzata, &"sporco": sporco}


## Una macchia com'era scritta nel file, ancora fuori dalla scena: dove metterla lo decide chi la
## aggiunge, con la trasformata della voce.
static func da_ricordo(voce: Dictionary) -> Macchia:
	var m := Macchia.new()
	m.name = "Macchia"
	m.raggio = float(voce.get(&"raggio", 0.09))
	m.seme = float(voce.get(&"seme", 0.0))
	m.schizzata = bool(voce.get(&"schizzata", false))
	m.sporco = clampf(float(voce.get(&"sporco", 1.0)), 0.0, 1.0)
	return m
