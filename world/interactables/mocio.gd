## Il mocio del magazzino: si prende, e col destro tenuto si passa per terra (D-251, D-252).
##
## PERCHÉ ESISTE. Il posto l'aveva deciso Federico insieme al salvataggio (D-243): «il mocio sta
## in magazzino». Poi il caffè ha cominciato a rovesciarsi, e il mocio non c'era: una tazza
## lanciata si svuotava e basta. Adesso il caffè fa una macchia (`Macchia`), e la macchia resta
## finché qualcuno non va di là a prendere il mocio.
##
## È UNA COSA CHE SI PRENDE IN MANO come la tazza: cade, si lancia, e la casa si ricorda dove la
## si è lasciata. Quello che ha in più è il gesto.
##
## ARRIVA PIÙ LONTANO DELLA MANO, ed è la ragione per cui guarda per conto suo. Il raggio del
## giocatore è lungo un metro e venti (`Player.INTERACT_RANGE`) e l'occhio sta a un metro e
## sessantacinque: da in piedi il pavimento non lo tocca mai. Va bene per raccogliere una tazza
## dal tavolo, ma un mocio è lungo un metro e trenta e si usa proprio per terra. Quindi lancia un
## raggio suo, lungo lo sguardo e più lungo, sulla geometria che si vede.
##
## IL DESTRO SI TIENE, NON SI PREME: pulire non è un colpo, è un avanti e indietro che dura
## finché dura. Mollato il tasto il mocio torna in mano, e quello che resta della macchia resta.
##
## SI PULISCE DOVE SI GUARDA, ANCHE DOVE NON C'È NIENTE (D-252). La prima stesura offriva il
## destro solo guardando una macchia, e le frange restavano legate a lei. Federico: «puoi fare che
## posso pulire anche random?». Chi ha un mocio in mano lo passa per terra, macchia o no; una
## macchia se ne va quando le frange ci passano sopra.
class_name Mocio
extends Carryable

## `GRUPPO` e non `GROUP`, come per la moka: quel nome l'ha già `Carryable`.
const GRUPPO := &"mocio"

## Dove la mano tiene il manico, in metri dal fondo delle frange. Portato in giro il mocio sta
## dritto, con le frange mezzo metro sopra il pavimento.
const PRESA := 0.95

## Fin dove arriva lo sguardo col mocio in mano, dall'occhio. Due metri e venti: da in piedi il
## pavimento fino a un metro e mezzo davanti ai piedi, che è dove arriva un mocio a braccio teso.
const PORTATA := 2.2

## Quanto dev'essere orizzontale quello che si guarda perché il mocio ci vada: il coseno fra la
## sua normale e la verticale. Il pavimento e il piano del tavolo sì; un muro no, e il destro non
## offre di strofinarlo.
const PIANO := 0.7

## Il gesto: di quanto vanno avanti e indietro le frange, e quante volte al secondo.
const OSCILLA := 0.10
const OSCILLA_HZ := 1.6

## Il raggio delle frange: una macchia a questa distanza dal centro del mocio la si tocca.
const RAGGIO_FRANGE := 0.12

var _strofinando := false
var _t := 0.0

## Dove arriva lo sguardo col raggio lungo del mocio, o `Vector3.INF`, e la normale di quello che
## tocca. Li aggiorna `punta()`.
var _sguardo := Vector3.INF
var _normale := Vector3.UP

## Dove stanno strofinando le frange, e su che piano. È l'ultimo punto buono dello sguardo: chi
## alza gli occhi pulendo non manda il mocio a mezz'aria.
var _dove := Vector3.INF
var _su := Vector3.UP


func _ready() -> void:
	super()
	add_to_group(GRUPPO)


static func find_in(tree: SceneTree) -> Mocio:
	return tree.get_first_node_in_group(GRUPPO) as Mocio


## Dove arriva lo sguardo col mocio in mano. Per le sonde, come `Player.mirato()`.
func sguardo() -> Vector3:
	return _sguardo


# --- pulire -------------------------------------------------------------------------

func puo_usare() -> bool:
	return in_mano() and not _strofinando and _su_un_piano()


func prompt_usa() -> String:
	return "Tieni premuto: pulisci"


func usa() -> void:
	if not puo_usare():
		return
	_dove = _sguardo
	_su = _normale
	_strofinando = true
	_t = 0.0


func smetti_di_usare() -> void:
	_strofinando = false


func in_gesto() -> bool:
	return _strofinando


func lascia() -> void:
	smetti_di_usare()
	super()


func _su_un_piano() -> bool:
	return _sguardo != Vector3.INF and _normale.dot(Vector3.UP) >= PIANO


## PORTATO STA DRITTO, con la mano sul manico. PULENDO LA MANO LA DECIDE IL GESTO: le frange vanno
## dove si guarda e oscillano di fianco, e il manico punta alla mano. Ci si arriva inseguendo come
## sempre (`Carryable`), quindi il pavimento ferma le frange e un mobile in mezzo le ferma prima.
func punta(mano: Transform3D, testa := Transform3D.IDENTITY) -> void:
	_guarda(testa)
	if not _strofinando:
		_mano = Transform3D(mano.basis, mano.origin - mano.basis.y * PRESA)
		return
	if _su_un_piano():
		_dove = _sguardo
		_su = _normale
	var fianco := testa.basis.x - _su * _su.dot(testa.basis.x)
	fianco = fianco.normalized() if fianco.length() > 0.01 else Vector3.RIGHT
	var frange := _dove + fianco * sin(_t * TAU * OSCILLA_HZ) * OSCILLA + _su * 0.01
	var manico := (mano.origin - frange).normalized()
	var fronte := fianco.cross(manico).normalized()
	_mano = Transform3D(Basis(manico.cross(fronte), manico, fronte), frange)


## Il punto della geometria che si vede lungo lo sguardo, entro `PORTATA`, e la sua normale.
func _guarda(testa: Transform3D) -> void:
	_sguardo = Vector3.INF
	if testa == Transform3D.IDENTITY or not is_inside_tree():
		return
	var q := PhysicsRayQueryParameters3D.create(testa.origin,
		testa.origin - testa.basis.z * PORTATA)
	q.collision_mask = Corazza.LAYER_APPOGGI
	q.exclude = [get_rid()]
	var colpo := get_world_3d().direct_space_state.intersect_ray(q)
	if colpo.is_empty():
		return
	_sguardo = colpo["position"]
	_normale = colpo["normal"]


## PULISCE DOVE STANNO LE FRANGE, non dove si guarda: finché il mocio sta ancora scendendo dalla
## mano, o un mobile lo tiene sollevato, non tocca niente. E pulisce tutte le macchie che tocca.
func _physics_process(delta: float) -> void:
	super(delta)
	if not _strofinando:
		return
	if not in_mano():
		smetti_di_usare()
		return
	_t += delta
	for n in get_tree().get_nodes_in_group(Macchia.GRUPPO):
		var m := n as Macchia
		if m != null and not m.is_queued_for_deletion() \
				and Macchia.copre(m.global_transform, m.raggio, global_position, RAGGIO_FRANGE):
			m.strofina(delta)
