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
##   - Non si chiudono tutte nello stesso istante: parte il mignolo e arriva l'indice.
## Gli angoli stanno dentro l'escursione attiva di una mano vera, e lontani dal fondo: una
## mano che arriva al limite sembra rotta.
##
## OGNI MANO FA LA SUA COSA. La prima stesura aveva un gesto solo, aprire e chiudere, e
## cinque mani che lo ripetono sfasate di qualche secondo: «fanno tutte lo stesso movimento,
## non va bene». Adesso ce ne sono sette, e sono gesti che chiunque riconosce da lontano:
##   STRINGE   si apre e si chiude a pugno, come prima;
##   CHIAMA    le altre dita chiuse e l'indice che si piega e si distende: «vieni qui»;
##   ARTIGLIO  le nocche tese e le falangi che si piegano, come a graffiare il cielo;
##   ONDA      le dita che si piegano una dopo l'altra, dal mignolo all'indice;
##   TENDE     aperta più che può, il polso all'indietro, le dita che tremano per lo sforzo;
##   INDICA    l'indice teso, il polso piegato verso chi guarda: indica te;
##   GIRA      mezza aperta, il braccio che si volta e mostra il dorso, e torna.
## Ogni braccio comincia da un gesto diverso (lo decide `world/orrori/braccia.gd`) e poi
## passa al successivo quando vuole lui, per una durata sua, con un dado suo: due braccia
## non fanno mai la stessa sequenza. Da un gesto all'altro si passa in `TRANSIZIONE`
## secondi, e ogni braccio ondeggia sulla spalla con periodi che non tornano in fase.
##
## UNA MANO ALTA UN CHILOMETRO SI MUOVE COME UNA MANO ALTA UN CHILOMETRO. La seconda stesura
## faceva i gesti coi tempi di una persona - chiamare ogni secondo e mezzo, tremare cinque
## volte al secondo - e Federico: «le mani fanno cose ridicole». Una cosa grande che si
## muove svelta si legge piccola: è una mano dietro la siepe che saluta. I tempi di un
## gesto qui sotto sono QUELLI DI UNA MANO VERA, e la mano grande li fa `lentezza()` volte
## più piano: la radice di quante volte è più grande, la similitudine di Froude con cui il
## cinema gira i modellini (una scala uno a sedici si gira a quattro volte la velocità).
## Per un braccio di un chilometro sono una quarantina: chiamare con l'indice dura mezzo
## minuto, e il tremito diventa un ondeggiare lento. La salita, ventidue secondi, era già
## su quella scala: è il mezzo secondo con cui si alza un braccio.
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

## Dove sta la spalla, in multipli di `altezza` sotto il nodo, che sta sul terreno dove il
## braccio spunta (`world/orrori/braccia.gd`): prima di salire e salito. Prima, con la mano
## mezza chiusa, le punte stanno un quinto sotto terra. Su, fuori c'è l'avambraccio intero e
## un pezzo di braccio.
const SPALLA_GIU := 1.2
const SPALLA_SU := 0.24

## LA PRESA. Quanto è chiusa la mano, da 0 (aperta del tutto) a 1 (a pugno).
const CHIUSA_SALENDO := 0.55
const APERTA := 0.06
const STRETTA := 0.9

enum Gesto { APERTA, STRINGE, CHIAMA, ARTIGLIO, ONDA, TENDE, INDICA, GIRA }
## I gesti fra cui si sceglie, lassù (APERTA è solo la posa con cui si arriva).
const REPERTORIO := [Gesto.STRINGE, Gesto.CHIAMA, Gesto.ARTIGLIO, Gesto.ONDA, Gesto.TENDE,
	Gesto.INDICA, Gesto.GIRA]
## DA QUI I TEMPI SONO QUELLI DI UNA MANO VERA, in secondi: la mano grande li fa
## `lentezza()` volte più piano.
## Quanto si tiene un gesto, e quanto ci si mette a passare al successivo.
const DURATA_GESTO := Vector2(3.0, 5.0)
const TRANSIZIONE := 0.4
## Il giro più lungo di STRINGE: la sonda aspetta almeno tanto.
const STRINGE_PERIODO_MAX := 3.0
## Di quanto un dito segue quello prima, dal mignolo all'indice.
const RITARDO_DITO := 0.06

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
## L'ondeggiare sulla spalla, in gradi: di lato e avanti-indietro.
const DONDOLA := Vector2(3.5, 2.5)

## La lunghezza della falange distale oltre la sua articolazione, in metri del modello
## (quella che lo script misura va da 19 a 24 millimetri): serve solo a dire dov'è la punta.
const PUNTA_DITO := 0.022

## Quanto è alto, dalla spalla alla punta del medio, in metri. Si scrive prima di metterlo
## in scena, come `sinistro`, `primo_gesto` e `seme`.
var altezza := 1200.0
## Il braccio sinistro è il destro specchiato.
var sinistro := false
## Da che gesto comincia, e il seme del suo dado: cinque braccia con lo stesso dado farebbero
## la stessa sequenza.
var primo_gesto: Gesto = Gesto.STRINGE
var seme := 1

## La posa: per le quattro dita (mignolo, anulare, medio, indice) nocca, prossimale e
## ventaglio; poi le tre articolazioni del pollice; poi polso, gomito e torsione. Gradi.
const _POLLICE0 := 12
const _POLSO := 15
const _GOMITO := 16
const _TORSIONE := 17
const _VOCI := 18

var _modello: Node3D
var _scheletro: Skeleton3D
var _ossa := {}
var _riposo: Array[Quaternion] = []
var _base := Transform3D.IDENTITY
var _palmo_riposo := Vector3.BACK
var _t := 0.0
## Il tempo della mano: il tempo del mondo diviso `_lentezza`.
var _tm := 0.0
var _lentezza := 1.0
var _su_da := -1.0
## Quanto è uscito, da 0 (tutto sotto) a 1 (su), e verso dove va.
var _e := 0.0
var _verso := 0.0
var _rng := RandomNumberGenerator.new()
var _gesto: Gesto = Gesto.APERTA
var _prima: Gesto = Gesto.APERTA
var _gesto_da := 0.0
var _prima_da := 0.0
var _gesto_fino := 0.0
var _variante := 0.5
var _variante_prima := 0.5
var _dondola_periodi := Vector2(29.0, 23.0)
var _dondola_fase := 0.0
var _posa_ora := PackedFloat32Array()


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
	_rng.seed = seme
	_dondola_periodi = Vector2(_rng.randf_range(21.0, 37.0), _rng.randf_range(17.0, 31.0))
	_dondola_fase = _rng.randf() * TAU
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
	# il corpo scolpito è in metri: k è proprio quante volte questo braccio è più grande
	_lentezza = sqrt(k)
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


## Quanto è chiusa la mano adesso, da 0 a 1: la prossimale del medio.
func chiusa() -> float:
	if _posa_ora.size() < _VOCI:
		return CHIUSA_SALENDO
	return inverse_lerp(PROSSIMALE.x, PROSSIMALE.y, _posa_ora[2 * 3 + 1])


## Il gesto che sta facendo adesso.
func gesto() -> Gesto:
	return _gesto


## Quante volte più piano di una mano vera fa i suoi gesti: la radice di quante volte è più
## grande.
func lentezza() -> float:
	return _lentezza


## Comincia subito un gesto, passando da quello di adesso. Serve alla sonda, e servirà alla
## storia il giorno che una mano dovrà fare una cosa precisa.
func fai(g: Gesto) -> void:
	_prima = _gesto
	_prima_da = _gesto_da
	_variante_prima = _variante
	_gesto = g
	_variante = _rng.randf()
	_gesto_da = _tm
	_gesto_fino = _tm + _rng.randf_range(DURATA_GESTO.x, DURATA_GESTO.y)


func _process(delta: float) -> void:
	passo(delta)


func passo(delta: float) -> void:
	if _scheletro == null:
		return
	_t += delta
	_tm += delta / _lentezza
	var prima := _e
	if _verso > 0.0:
		_e = minf(1.0, _e + delta / DURATA_SALE)
		if _e >= 1.0 and _su_da < 0.0:
			_su_da = _t
			fai(primo_gesto)
	elif _verso < 0.0:
		_e = maxf(0.0, _e - delta / DURATA_SCENDE)
	if _su_da >= 0.0 and _verso >= 0.0 and _tm >= _gesto_fino:
		var altri := REPERTORIO.filter(func(g): return g != _gesto)
		fai(altri[_rng.randi() % altri.size()])
	_posa(delta)
	if _verso < 0.0 and prima > 0.0 and _e <= 0.0:
		_verso = 0.0
		sceso.emit()


# --- i gesti ---------------------------------------------------------------------------

func _dito(p: PackedFloat32Array, f: int, nocca: float, prossimale: float, apertura := 0.0) -> void:
	p[f * 3] = nocca
	p[f * 3 + 1] = prossimale
	p[f * 3 + 2] = float(VENTAGLIO[DITA[f]]) * apertura


## Un dito chiuso di `c` (0 aperto, 1 a pugno), con il ventaglio che si stringe chiudendo.
func _dito_chiuso(p: PackedFloat32Array, f: int, c: float, apertura := 1.0) -> void:
	_dito(p, f, lerpf(NOCCA.x, NOCCA.y, c), lerpf(PROSSIMALE.x, PROSSIMALE.y, c), apertura * (1.0 - c))


func _pollice(p: PackedFloat32Array, c: float) -> void:
	for j in 3:
		var r: Vector2 = POLLICE[j]
		p[_POLLICE0 + j] = lerpf(r.x, r.y, c)


## Il profilo di una presa: aperta, si chiude, chiusa, si apre, per `u` da 0 a 1.
static func _presa(u: float) -> float:
	if u < 0.4:
		return 0.0
	if u < 0.6:
		return smoothstep(0.4, 0.6, u)
	if u < 0.8:
		return 1.0
	return 1.0 - smoothstep(0.8, 1.0, u)


## La posa del gesto `g` dopo `t` secondi, con la variante `v` (0..1) che ne sceglie i tempi.
func _posa_del_gesto(g: Gesto, t: float, v: float) -> PackedFloat32Array:
	var p := PackedFloat32Array()
	p.resize(_VOCI)
	p[_GOMITO] = GOMITO
	match g:
		Gesto.STRINGE:
			var periodo := lerpf(2.0, STRINGE_PERIODO_MAX, v)
			for f in 4:
				var c := lerpf(APERTA, STRETTA, _presa(fposmod(t - f * RITARDO_DITO, periodo) / periodo))
				_dito_chiuso(p, f, c)
			var cm := inverse_lerp(PROSSIMALE.x, PROSSIMALE.y, p[2 * 3 + 1])
			_pollice(p, lerpf(APERTA, STRETTA, _presa(fposmod(t - 4.0 * RITARDO_DITO, periodo) / periodo)))
			p[_POLSO] = lerpf(POLSO.x, POLSO.y, cm)
		Gesto.CHIAMA:
			var periodo := lerpf(0.7, 1.0, v)
			for f in 3:
				_dito_chiuso(p, f, 0.88)
			var ci := 0.08 + 0.8 * (0.5 - 0.5 * cos(TAU * t / periodo))
			_dito_chiuso(p, 3, ci, 0.0)
			_pollice(p, 0.8)
			p[_POLSO] = 12.0
			p[_GOMITO] = 18.0
		Gesto.ARTIGLIO:
			var periodo := lerpf(1.5, 2.2, v)
			var s := 0.5 - 0.5 * cos(TAU * t / periodo)
			for f in 4:
				var trema := 3.0 * sin(TAU * t * 5.3 + f * 1.9)
				_dito(p, f, -15.0, lerpf(10.0, 95.0, s) + trema, 0.8)
			_pollice(p, 0.35)
			p[_POLSO] = -28.0
			p[_GOMITO] = 6.0
		Gesto.ONDA:
			var periodo := lerpf(0.8, 1.2, v)
			for f in 4:
				var c := 0.08 + 0.55 * (0.5 - 0.5 * cos(TAU * (t / periodo - f * 0.22)))
				_dito_chiuso(p, f, c, 0.7)
			_pollice(p, 0.3)
			p[_POLSO] = -10.0 + 6.0 * sin(TAU * t / (periodo * 3.0))
			p[_GOMITO] = 10.0
		Gesto.TENDE:
			for f in 4:
				var trema := 4.0 * sin(TAU * t * 3.3 + f * 1.3)
				_dito(p, f, NOCCA.x - 4.0 + trema, PROSSIMALE.x, 1.4)
				p[f * 3 + 2] += 2.5 * sin(TAU * t * 4.1 + f * 1.7)
			_pollice(p, 0.0)
			p[_POLSO] = -32.0
			p[_GOMITO] = 2.0 + 3.0 * sin(TAU * t / lerpf(1.5, 2.5, v))
		Gesto.INDICA:
			for f in 3:
				_dito_chiuso(p, f, 0.92)
			_dito(p, 3, -5.0, -8.0, 0.0)
			_pollice(p, 0.85)
			p[_POLSO] = 40.0 + 4.0 * sin(TAU * t / lerpf(1.5, 2.5, v))
			p[_GOMITO] = 25.0
		Gesto.GIRA:
			for f in 4:
				_dito_chiuso(p, f, 0.3, 0.6)
			_pollice(p, 0.25)
			p[_POLSO] = -5.0
			p[_GOMITO] = 12.0
			p[_TORSIONE] = 75.0 * sin(TAU * t / lerpf(2.0, 3.0, v))
		_:
			for f in 4:
				_dito_chiuso(p, f, APERTA)
			_pollice(p, APERTA)
			p[_POLSO] = POLSO.x
	return p


## La mano a pugno, e quella mezza chiusa con cui esce dal prato.
func _posa_chiusa(c: float) -> PackedFloat32Array:
	var p := PackedFloat32Array()
	p.resize(_VOCI)
	for f in 4:
		_dito_chiuso(p, f, c)
	_pollice(p, c)
	p[_POLSO] = lerpf(POLSO.x, POLSO.y, c)
	p[_GOMITO] = GOMITO
	return p


## `a` verso `b`, con il peso `w` per le dita spostato di `ritardo` per dito (dal mignolo).
static func _mescola(a: PackedFloat32Array, b: PackedFloat32Array, w: float, ritardo := 0.0) -> PackedFloat32Array:
	var p := PackedFloat32Array()
	p.resize(_VOCI)
	for i in _VOCI:
		var f := mini(floori(i / 3.0), 4) if i < _POLSO else 0
		var wi := clampf(w - f * ritardo, 0.0, 1.0)
		p[i] = lerpf(a[i], b[i], wi)
	return p


func _posa(_delta: float) -> void:
	var e := smoothstep(0.0, 1.0, _e)
	var p: PackedFloat32Array
	if _su_da < 0.0:
		# SALENDO SI APRE quando esce dal prato: prima mezza chiusa, poi tesa verso il cielo
		p = _mescola(_posa_chiusa(CHIUSA_SALENDO), _posa_del_gesto(Gesto.APERTA, 0.0, 0.0),
			smoothstep(0.45, 1.0, e), 0.012)
	else:
		var tg := _tm - _gesto_da
		p = _posa_del_gesto(_gesto, tg, _variante)
		if tg < TRANSIZIONE:
			var prima := _posa_del_gesto(_prima, _tm - _prima_da, _variante_prima)
			p = _mescola(prima, p, smoothstep(0.0, TRANSIZIONE, tg))
		if _verso < 0.0:
			# TORNANDO GIÙ LA MANO SI CHIUDE, piano, a cominciare dal mignolo
			p = _mescola(p, _posa_chiusa(STRETTA), smoothstep(0.0, 0.6, 1.0 - e), 0.03)
	_posa_ora = p

	var su := -altezza * lerpf(SPALLA_GIU, SPALLA_SU, e)
	var tt := _t + _dondola_fase * 10.0
	var dondola := Basis(Vector3.BACK, deg_to_rad(DONDOLA.x) * sin(TAU * tt / _dondola_periodi.x) * e) \
		* Basis(Vector3.RIGHT, deg_to_rad(DONDOLA.y) * sin(TAU * tt / _dondola_periodi.y + 1.3) * e)
	var gira := Basis(Vector3.UP, deg_to_rad(p[_TORSIONE]) * e)
	_modello.transform = Transform3D(dondola * gira, Vector3(0.0, su, 0.0)) * _base

	for f in 4:
		var nome: String = DITA[f]
		_piega(nome + "_1", p[f * 3], p[f * 3 + 2])
		_piega(nome + "_2", p[f * 3 + 1])
		_piega(nome + "_3", p[f * 3 + 1] * DISTALE)
	for j in 3:
		_piega("pollice_%d" % (j + 1), p[_POLLICE0 + j])
	_piega("mano", p[_POLSO])
	# mentre sale il gomito è più piegato, e si distende uscendo
	_piega("avambraccio", lerpf(40.0, p[_GOMITO], e))


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
