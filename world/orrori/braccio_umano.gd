## UN BRACCIO UMANO grande quanto una montagna: uno dei cinque di `Ctrl+F4`.
##
## LA FORMA non sta qui. È il braccio destro di un corpo scolpito da Blender Studio,
## tagliato alla spalla e armato da `tools/braccio_umano_blender.py`, con le giunture prese
## dai face set del modello: qui dentro c'è solo come si muove.
##
## COME SI MUOVE UNA MANO, che è la cosa che fa capire cos'è. Una mano ferma alta un
## chilometro potrebbe essere una roccia con cinque punte; una mano che si chiude no.
##   - Le dita si chiudono sulle tre articolazioni insieme, e l'ultima segue la penultima:
##     la distale piega due terzi della interfalangea prossimale (Rijpkema e Girard 1991,
##     il vincolo con cui si animano le prese).
##   - Aperte si allargano a ventaglio attorno al medio, il mignolo più di tutte; chiuse si
##     stringono.
##   - Non si chiudono tutte nello stesso istante: parte il mignolo e arriva l'indice, poi il
##     pollice si chiude sopra.
##   - Il polso si piega all'indietro quando la mano si allunga aperta, e in avanti quando
##     stringe.
## Gli angoli stanno dentro l'escursione attiva di una mano vera, e lontani dal fondo: una
## mano che arriva al limite sembra rotta.
##
## LE OSSA SI TROVANO PER NOME e le direzioni si misurano, come nel tentacolo: il palmo è
## dove punta il prodotto fra il verso che va dal mignolo all'indice e quello che va dal
## polso al medio — per una mano destra — e il nodo gira il modello perché il braccio salga
## lungo il suo +Y e il palmo guardi il suo +Z. Chi lo mette in scena gira il nodo verso la
## camera, e da lì in poi vede il palmo.
##
## Si flette attorno all'asse X di ogni osso, che l'esportatore ha messo perpendicolare al
## verso della piega; la sonda lo verifica misurando che le dita chiuse finiscano sul palmo.
class_name BraccioUmano
extends Node3D

signal sceso

const MODELLO := "res://assets/models/braccio_umano.glb"
const DITA := ["mignolo", "anulare", "medio", "indice", "pollice"]

## Quanto ci mette a salire e a tornare giù, in secondi.
const DURATA_SALE := 22.0
const DURATA_SCENDE := 18.0

## Dove sta la spalla, in multipli di `altezza` sotto quota zero: prima di salire e salito.
## Prima, con la mano mezza chiusa, le punte stanno un quinto sotto zero: il profilo del
## prato scende di quattro gradi, e a un chilometro e mezzo nasconde solo cento metri. Su,
## sopra l'orizzonte c'è l'avambraccio intero e un pezzo di braccio.
const SPALLA_GIU := 1.2
const SPALLA_SU := 0.24

## LA PRESA. Quanto è chiusa la mano, da 0 (aperta del tutto) a 1 (a pugno).
const CHIUSA_SALENDO := 0.55
const APERTA := 0.06
const STRETTA := 0.9
## Un giro intero di apri e chiudi, in secondi, e come si divide: aperta, si chiude,
## chiusa, si apre (frazioni del giro, in fila).
const CICLO := 17.0
const CICLO_APERTA := 0.42
const CICLO_CHIUDE := 0.2
const CICLO_CHIUSA := 0.18
## Di quanti secondi un dito segue quello prima, dal mignolo al pollice.
const RITARDO_DITO := 0.3

## Gli angoli, in gradi, da aperta a chiusa, SOPRA LA POSA DEL MODELLO. Nocca
## (metacarpo-falangea), interfalangea prossimale; la distale è `DISTALE` volte la
## prossimale. Aperta va sotto zero perché il corpo è scolpito con la mano rilassata, le dita
## già piegate di una quindicina di gradi: a zero la mano aperta restava un artiglio.
const NOCCA := Vector2(-18.0, 66.0)
const PROSSIMALE := Vector2(-13.0, 88.0)
const DISTALE := 2.0 / 3.0
## Il pollice: base, metacarpo-falangea, interfalangea.
const POLLICE := [Vector2(0.0, 22.0), Vector2(0.0, 45.0), Vector2(-5.0, 65.0)]
## Il ventaglio da aperta, in gradi verso il mignolo (negativo: verso il pollice).
const VENTAGLIO := {"mignolo": 17.0, "anulare": 7.0, "medio": -1.0, "indice": -11.0}
## Il polso: all'indietro da aperta, in avanti da chiusa; e il gomito, che non sta mai dritto.
const POLSO := Vector2(-24.0, 16.0)
const GOMITO := 8.0
const GOMITO_RESPIRA := 8.0
const GOMITO_PERIODO := 23.0
## Il braccio che gira su se stesso: il palmo si volta e torna.
const TORSIONE := 22.0
const TORSIONE_PERIODO := 29.0

## La lunghezza della falange distale oltre la sua articolazione, in metri del modello
## (quella che lo script misura va da 19 a 24 millimetri): serve solo a dire dov'è la punta.
const PUNTA_DITO := 0.022

## Quanto è alto, dalla spalla alla punta del medio, in metri. Si scrive prima di metterlo
## in scena, come `sinistro` e `sfasatura`.
var altezza := 1200.0
## Il braccio sinistro è il destro specchiato.
var sinistro := false
## Di quanti secondi ritarda la prima presa: cinque mani che stringono insieme sono un
## balletto.
var sfasatura := 0.0

var _modello: Node3D
var _scheletro: Skeleton3D
var _ossa := {}
var _riposo: Array[Quaternion] = []
var _base := Transform3D.IDENTITY
var _palmo_riposo := Vector3.BACK
var _t := 0.0
var _su_da := -1.0
## Quanto è uscito, da 0 (tutto sotto) a 1 (su), e verso dove va.
var _e := 0.0
var _verso := 0.0
var _chiusa := CHIUSA_SALENDO


func _ready() -> void:
	var scena := load(MODELLO) as PackedScene
	if scena == null:
		push_error("braccio umano: manca %s — lancia tools/braccio_umano_blender.py" % MODELLO)
		set_process(false)
		return
	_modello = scena.instantiate() as Node3D
	_modello.name = "Modello"
	add_child(_modello)
	_scheletro = _trova_scheletro(_modello)
	if _scheletro == null:
		push_error("braccio umano: nessuno Skeleton3D nel modello — resta fermo")
		set_process(false)
		return
	for i in _scheletro.get_bone_count():
		_ossa[_scheletro.get_bone_name(i)] = i
		_riposo.append(_scheletro.get_bone_rest(i).basis.get_rotation_quaternion())
	for n in ["braccio", "avambraccio", "mano", "indice_1", "medio_1", "mignolo_1"]:
		if not _ossa.has(n):
			push_error("braccio umano: manca l'osso %s — il modello è cambiato" % n)
			set_process(false)
			return
	_orienta()
	_veste(_modello)
	_posa(0.0)


func _trova_scheletro(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n as Skeleton3D
	for f in n.get_children():
		var s := _trova_scheletro(f)
		if s != null:
			return s
	return null


func _riposo_di(nome: String) -> Vector3:
	return _scheletro.get_bone_global_rest(_ossa[nome]).origin


## Il modello girato e scalato perché la spalla stia nell'origine del nodo, il braccio salga
## lungo +Y e il palmo guardi +Z.
func _orienta() -> void:
	var spalla := _riposo_di("braccio")
	var su := (_riposo_di("mano") - spalla).normalized()
	var radiale := (_riposo_di("indice_1") - _riposo_di("mignolo_1")).normalized()
	var lungo := (_riposo_di("medio_1") - _riposo_di("mano")).normalized()
	var palmo := radiale.cross(lungo)
	palmo = (palmo - su * palmo.dot(su)).normalized()
	_palmo_riposo = palmo
	var girata := Basis(su.cross(palmo), su, palmo).inverse()
	# quanto è lungo dalla spalla alla punta del medio, in metri del modello
	var medio := _riposo_di("medio_3")
	var dir := (medio - _riposo_di("medio_2")).normalized()
	var lunghezza := (girata * (medio + dir * PUNTA_DITO - spalla)).y
	var k := altezza / maxf(lunghezza, 1e-3)
	var b := Basis.from_scale(Vector3(-k if sinistro else k, k, k)) * girata
	_base = Transform3D(b, -(b * spalla))


func _veste(n: Node) -> void:
	if n is MeshInstance3D:
		var m := n as MeshInstance3D
		var pelle := StandardMaterial3D.new()
		# UNA PELLE CHIARA E SPENTA: la riflettanza di una pelle chiara sta attorno a mezzo, e
		# la prima stesura, più chiara e col bordo acceso, sotto la Luna sembrava plastica
		# illuminata da dietro. Un filo di bordo resta, perché il braccio si stacchi dal cielo.
		pelle.albedo_color = Color(0.56, 0.48, 0.45)
		pelle.roughness = 0.66
		pelle.rim_enabled = true
		pelle.rim = 0.12
		pelle.rim_tint = 0.3
		m.material_override = pelle
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# la pelle si piega fuori dall'ingombro di riposo, e i culling la taglierebbero
		m.custom_aabb = AABB(Vector3(-1.0, -0.5, -1.0), Vector3(2.0, 2.0, 2.0))
	for f in n.get_children():
		_veste(f)


func sali() -> void:
	_verso = 1.0
	set_process(true)


func scendi() -> void:
	_verso = -1.0
	set_process(true)


## Quanto è uscito, da 0 a 1.
func uscito() -> float:
	return _e


## Quanto è chiusa la mano adesso, da 0 a 1 (il medio).
func chiusa() -> float:
	return _chiusa


func _process(delta: float) -> void:
	passo(delta)


func passo(delta: float) -> void:
	if _scheletro == null:
		return
	_t += delta
	var prima := _e
	if _verso > 0.0:
		_e = minf(1.0, _e + delta / DURATA_SALE)
		if _e >= 1.0 and _su_da < 0.0:
			_su_da = _t
	elif _verso < 0.0:
		_e = maxf(0.0, _e - delta / DURATA_SCENDE)
	_posa(delta)
	if _verso < 0.0 and prima > 0.0 and _e <= 0.0:
		_verso = 0.0
		sceso.emit()


## Quanto è chiuso il dito `k` (0 il mignolo, 4 il pollice) in questo istante.
func _chiusura(k: int) -> float:
	var e := smoothstep(0.0, 1.0, _e)
	if _verso < 0.0:
		# TORNANDO GIÙ LA MANO SI CHIUDE, piano, a cominciare dal mignolo
		var dentro := 1.0 - e
		return lerpf(_presa(k), STRETTA, smoothstep(0.0, 0.6, dentro - k * 0.03))
	if _su_da < 0.0:
		# SALENDO SI APRE quando esce dal prato: prima mezza chiusa, poi tesa verso il cielo
		return lerpf(CHIUSA_SALENDO, APERTA, smoothstep(0.45, 1.0, e - k * 0.012))
	return _presa(k)


## La presa del giro, per il dito `k`.
func _presa(k: int) -> float:
	if _su_da < 0.0:
		return APERTA
	var tau := _t - _su_da - sfasatura - k * RITARDO_DITO
	if tau <= 0.0:
		return APERTA
	var u := fposmod(tau, CICLO) / CICLO
	var a := CICLO_APERTA
	var b := a + CICLO_CHIUDE
	var c := b + CICLO_CHIUSA
	var chiusa := 0.0
	if u < a:
		chiusa = 0.0
	elif u < b:
		chiusa = smoothstep(a, b, u)
	elif u < c:
		chiusa = 1.0
	else:
		chiusa = 1.0 - smoothstep(c, 1.0, u)
	return lerpf(APERTA, STRETTA, chiusa)


func _posa(_delta: float) -> void:
	var e := smoothstep(0.0, 1.0, _e)
	var t := _t + sfasatura
	var su := -altezza * lerpf(SPALLA_GIU, SPALLA_SU, e)
	var gira := deg_to_rad(TORSIONE) * sin(TAU * t / TORSIONE_PERIODO) * e
	_modello.transform = Transform3D(Basis(Vector3.UP, gira), Vector3(0.0, su, 0.0)) * _base

	for k in DITA.size():
		var nome: String = DITA[k]
		var c := _chiusura(k)
		if nome == "pollice":
			for j in 3:
				var r: Vector2 = POLLICE[j]
				_piega("pollice_%d" % (j + 1), lerpf(r.x, r.y, c))
			continue
		var nocca := lerpf(NOCCA.x, NOCCA.y, c)
		var prossimale := lerpf(PROSSIMALE.x, PROSSIMALE.y, c)
		_piega(nome + "_1", nocca, float(VENTAGLIO[nome]) * (1.0 - c))
		_piega(nome + "_2", prossimale)
		_piega(nome + "_3", prossimale * DISTALE)
		if nome == "medio":
			_chiusa = c

	var polso := lerpf(POLSO.x, POLSO.y, inverse_lerp(APERTA, STRETTA, _chiusa))
	_piega("mano", polso)
	var gomito := GOMITO + GOMITO_RESPIRA * sin(TAU * t / GOMITO_PERIODO)
	# mentre sale il gomito è più piegato, e si distende uscendo
	_piega("avambraccio", lerpf(40.0, gomito, e))


## Flessione e ventaglio, in gradi, sopra la posa di riposo.
func _piega(nome: String, flessione: float, ventaglio := 0.0) -> void:
	var i: int = _ossa.get(nome, -1)
	if i < 0:
		return
	var q := _riposo[i]
	if ventaglio != 0.0:
		q = q * Quaternion(Vector3.BACK, deg_to_rad(ventaglio))
	_scheletro.set_bone_pose_rotation(i, q * Quaternion(Vector3.RIGHT, deg_to_rad(flessione)))


# --- per chi misura -------------------------------------------------------------------

func _nel_mondo(p: Vector3) -> Vector3:
	return _scheletro.global_transform * p


## La spalla, nel mondo.
func spalla_nel_mondo() -> Vector3:
	return _nel_mondo(_scheletro.get_bone_global_pose(_ossa["braccio"]).origin)


## Il polso, nel mondo.
func polso_nel_mondo() -> Vector3:
	return _nel_mondo(_scheletro.get_bone_global_pose(_ossa["mano"]).origin)


## Le cinque punte delle dita, nel mondo, dal mignolo al pollice.
func punte_nel_mondo() -> PackedVector3Array:
	var fuori := PackedVector3Array()
	for nome in DITA:
		var g := _scheletro.get_bone_global_pose(_ossa[nome + "_3"])
		fuori.append(_nel_mondo(g.origin + g.basis.y.normalized() * PUNTA_DITO))
	return fuori


## Le cinque nocche (l'attacco di ogni dito), nel mondo, dal mignolo al pollice.
func nocche_nel_mondo() -> PackedVector3Array:
	var fuori := PackedVector3Array()
	for nome in DITA:
		fuori.append(_nel_mondo(_scheletro.get_bone_global_pose(_ossa[nome + "_1"]).origin))
	return fuori


## Dove guarda il palmo adesso, nel mondo: il verso di riposo portato dalla posa della mano.
func palmo_nel_mondo() -> Vector3:
	var i: int = _ossa["mano"]
	var locale := _scheletro.get_bone_global_rest(i).basis.inverse() * _palmo_riposo
	var ora := _scheletro.get_bone_global_pose(i).basis * locale
	return (_scheletro.global_transform.basis * ora).normalized()
