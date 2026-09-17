## L'OCCHIO che si apre nel cielo, grande come un pezzo di cielo, e guarda te.
##
## LA PELLE E LE PALPEBRE SONO DI UN POLPO, la stessa creatura del tentacolo, con la
## stessa pelle (`assets/textures/pelle-polpo`, il polpo di Greg McFall/NOAA). L'IRIDE È
## L'OCCHIO COSMICO, lo stesso che esce nella stampa (`world/orrori/occhio_nella_posa.gd`):
## una nebulosa con una pupilla, e chi l'ha visto in cielo lo riconosce sulla carta.
##
## COPIATO:
##   * L'IRIDE: l'immagine di «Cosmic Eye of Horror» (Huntaer87, CC-BY), resa da
##     `tools/occhio_cosmico_blender.py`. La prima stesura aveva l'iride del polpo della
##     foto, ripetuta a piastrelle, e da sotto era un anello di macchie tutte uguali.
##   * LA PUPILLA SI STRINGE ALLA LUCE in meno di un secondo: qui ci mette `PUPILLA_TAU`.
##     È tonda come nell'immagine, e si stringe stirando l'iride vera
##     (`occhio_bulbo.gdshader`).
##   * IL BULBO NON GIRA CON LA TESTA: un polpo ruota l'occhio per tenerlo dritto
##     sull'orizzonte, guidato dalle statocisti. Per questo la testa qui è girata di
##     `ROLLIO` — le palpebre e la pelle sono storte, l'occhio no — ed è il dettaglio che
##     fa sembrare la cosa un animale invece che un disegno.
##   * NON SBATTE LE PALPEBRE. Sott'acqua un occhio non si asciuga: un polpo l'occhio
##     lo CHIUDE, tirandoci sopra la pelle attorno, e basta. Nella foto la piega di
##     sopra copre un terzo del bulbo; qui la piega di sopra scende e quella di sotto
##     sale, finché la prima copre la seconda.
##   * IL BULBO SPORGE dalla pelle, e la pelle gli fa attorno un orlo: è la forma
##     della foto, ed è `PROFILO`.
##
## INVENTATO, e non c'è modo di non farlo: quanto è grande (non esiste un occhio largo
## un chilometro da misurare), come COMPARE — una macchia di pelle che si allarga
## nel cielo attorno a un occhio chiuso — e il comportamento: aperto, CERCA per
## qualche secondo guardando a caso, poi TROVA la camera e non la lascia più.
##
## LA SCALA È UNA SOLA, `RAGGIO`. Tutta la geometria è costruita in raggi del bulbo e
## poi scalata: le proporzioni fra pupilla, palpebre e orlo sono quelle, e la
## grandezza è un numero, o meglio due: raggio e distanza, perché conta il loro
## rapporto.
##
## PRENDE MEZZO CIELO, e l'ha chiesto Federico: la prima misura, 380 metri a 2600, era
## un occhio largo quattordici gradi, e «molto del cielo vorrei che fosse occupato da
## quest'occhio». Adesso sono 630 metri a 1400: l'occhio aperto è largo più di
## cinquanta gradi, cento Lune piene, e la pelle piena copre novanta gradi di cielo
## prima di cominciare a sgranarsi. Chi esce dalla porta e guarda dritto vede la
## palpebra di sotto sopra la testa.
##
## E NON SI POTEVA INGRANDIRE SOLTANTO. La testa va indietro di un terzo di raggio e si
## allarga a quattro raggi e mezzo: a 2600 metri di distanza, per la stessa grandezza
## nel cielo, la pelle sarebbe arrivata a cinque chilometri e mezzo, oltre i quattro a
## cui la camera smette di disegnare. Avvicinato, il punto più lontano sta a 3266.
##
## NIENTE COLLISIONE e niente ombre portate: sta a un chilometro e mezzo, e le ombre
## della Luna in scena finiscono a cento metri. Le palpebre l'ombra sul bulbo la
## fanno lo stesso, calcolata nello shader.
##
## Lo apre `debug/occhio.gd` (tasto F6); quando la storia ci sarà, lo aprirà lei.
class_name Occhio
extends Node3D

## Emesso quando si è chiuso ed è sparito nel cielo: chi l'ha aperto libera il nodo.
signal svanito

## Il raggio del bulbo, in metri. È LA scala: vedi la testata.
const RAGGIO := 630.0

## Quanto lontano sta da chi guarda, se lo colloca `colloca()`.
const DISTANZA := 1400.0

## LA SCALA DI QUESTO OCCHIO, se non è quello di `F6`. Di base sono `RAGGIO` e
## `DISTANZA`; l'occhio che si vede nell'oculare (`world/orrori/nell_oculare.gd`) è più
## piccolo e più lontano, perché deve riempire un campo di dodici gradi. Si scrivono
## PRIMA di mettere il nodo in scena: la geometria si costruisce in `_ready`.
@export var raggio := RAGGIO
@export var distanza := DISTANZA

## I layer visivi di pelle, palpebre e bulbo. Di base il primo, come tutto il mondo;
## l'occhio dell'oculare ne ha uno che la camera del giocatore non disegna.
@export_flags_3d_render var strato := 1

## DOV'È L'ALTO per la pupilla e per la testa. Nel cielo è l'alto del mondo, ed è quello
## che fa un polpo vero (vedi `ROLLIO`). L'occhio nell'oculare usa l'alto della camera
## dell'oculare: la vista di un'equatoriale è girata rispetto all'orizzonte, e una pupilla
## orizzontale nel mondo lì dentro esce storta di quaranta gradi — una fessura obliqua
## che nessuno legge come un occhio. Lo si cambia prima di `colloca_verso()`.
var alto := Vector3.UP

## Da dove arriva la luce che si specchia nel bulbo. Nel cielo è la Luna; l'occhio
## nell'oculare ne ha una sua (`world/orrori/nell_oculare.gd`), e il riflesso deve venire
## da quella, o il bulbo resta una palla opaca.
var riflesso_da: Node3D = null

## IL PROFILO DELLA PELLE, in raggi del bulbo: (distanza dall'asse, profondità), con
## la profondità NEGATIVA DAVANTI — l'occhio guarda verso -Z. Si gira attorno all'asse
## e fa la testa.
##
## Parte DENTRO il bulbo, cioè da dove non si vede, e ne esce a sessanta gradi
## dall'asse: lì c'è l'orlo, la cresta a due terzi di raggio davanti al centro. Il
## bulbo arriva a uno: sporge di un terzo di raggio oltre l'orlo, come nella foto. Poi
## la pelle scende e va indietro, e oltre la metà della sua larghezza si sgrana nel
## cielo (`occhio_pelle.gdshader`).
##
## E LE PALPEBRE STANNO SOTTO L'ORLO: sono gusci a 1,008-1,075 raggi, e la pelle
## all'uscita dal bulbo sta già a 1,10. Si aprono scorrendo sulla sfera, e il bordo
## da cui escono non si vede mai.
const PROFILO: Array[Vector2] = [
	Vector2(0.80, -0.30),
	Vector2(0.95, -0.55),
	Vector2(1.05, -0.67),
	Vector2(1.22, -0.68),
	Vector2(1.50, -0.57),
	Vector2(2.10, -0.32),
	Vector2(2.90, -0.02),
	Vector2(3.70, 0.28),
	Vector2(4.40, 0.52),
]

## Quanto è larga la testa, in raggi del bulbo: l'ultimo punto del profilo.
const TESTA := 4.4

const PASSI_PER_TRATTO := 8
const SPICCHI := 128

## Il lato di una piastrella di pelle, in raggi del bulbo: novantacinque metri. Il
## reticolo della foto ha una trentina di maglie per piastrella, quindi una maglia è
## larga tre metri — un pixel o poco più da un chilometro: la pelle di un polpo, da
## lì, si vede come una grana che vibra, non come un disegno. Più grande, e le
## piastrelle si contavano.
const PIASTRELLA := 0.15

## LE PALPEBRE. Ogni margine è un angolo attorno all'asse X della testa (zero è
## davanti, positivo verso l'alto) fatto di due pezzi: una BASE, uguale da un capo
## all'altro, e un ARCO, pieno al centro e nullo ai canti, a `CANTO` radianti
## dall'asse.
##
## APERTE, LA BASE È APPENA OLTRE IL CENTRO e l'apertura la fa tutta l'arco: le due
## pieghe si toccano ai canti, e l'occhio aperto ha due angoli. La prima stesura
## apriva con la base e lasciava l'arco piccolo, e i margini arrivavano all'orlo
## della pelle ancora staccati — da vicino era una palla con un taglio. I canti
## stanno a cinquantasei gradi, dentro l'orlo che ne ha sessanta: si vedono.
##
## CHIUSE, l'arco è zero e le basi stanno a `CHIUSA` oltre il centro: quella di
## sopra copre quella di sotto per quattro gradi, da un capo all'altro.
##
## `ARCO_FORMA` sotto uno fa i capi tondi, sopra li fa a punta: un polpo ha la
## fessura tonda, non l'occhio a mandorla di un mammifero.
const CANTO := 0.98
const ARCO_FORMA := 0.8
const LATO_PALPEBRA := 1.35
const COLONNE_PALPEBRA := 61
const APERTA_BASE := -0.01
const SU_ARCO := 0.80
const GIU_ARCO := 0.64
const CHIUSA := -0.035

## LA SEZIONE DI UNA PALPEBRA: (angolo dal margine, distanza dal centro). Dal dentro,
## che è quasi a contatto col bulbo, gira attorno al bordo e torna indietro fuori: una
## piega di pelle spessa un quindicesimo di raggio, venticinque metri, col bordo tondo.
## Quella di sotto sta sei millesimi più in basso, perché chiusa ci passa sotto.
const SEZIONE: Array[Vector2] = [
	Vector2(0.30, 1.008),
	Vector2(0.07, 1.008),
	Vector2(0.018, 1.020),
	Vector2(0.0, 1.042),
	Vector2(0.018, 1.064),
	Vector2(0.07, 1.075),
	Vector2(0.25, 1.075),
	Vector2(0.55, 1.075),
	Vector2(0.95, 1.075),
	Vector2(1.45, 1.075),
	Vector2(2.05, 1.075),
]
const SOTTO := 0.006

## La testa è girata di dieci gradi attorno all'asse dello sguardo. La pupilla no.
const ROLLIO := -0.18

## I TEMPI, in secondi.
##
## COMPARE IN DICIOTTO, e il primo pezzo c'è subito: il fronte parte svelto dal
## centro e rallenta allargandosi, come una macchia che si spande, e al secondo
## secondo l'occhio chiuso è già mezzo disco. È una lezione del tentacolo, che nei
## primi venti secondi non si vedeva, e chi aveva premuto il tasto lo ripremeva
## pensando che non fosse successo niente — ritirandolo.
const DURATA_COMPARE := 18.0
const ATTESA_CHIUSO := 2.5
## Si apre in due tempi: uno spiraglio, una pausa, poi tutto.
const SCHIUDE_SPIRAGLIO := 1.4
const SPIRAGLIO := 0.18
const SPIRAGLIO_TIENE := 2.0
const SCHIUDE_TUTTO := 3.2
const DURATA_CHIUDE := 2.4
const DURATA_SVANISCE := 12.0

## Per quanto, da quando comincia ad aprirsi, guarda a caso prima di trovare la camera.
const CERCA_PER := 7.0

## Dove guarda chi si fa trovare già aperto e distratto (`apri_subito`): di lato e in
## basso, in radianti. Ventiquattro gradi di lato stanno dentro `SGUARDO_MASSIMO`, e
## bastano perché la pupilla sia fuori dal centro del bulbo di un terzo di raggio.
const ALTROVE := Vector2(0.42, -0.14)

## Di quanto il bulbo può girare rispetto alla testa: trenta gradi.
const SGUARDO_MASSIMO := 0.52

## Il movimento del bulbo: un colpo rapido quando la mira è lontana, un inseguimento
## lento quando è vicina. Sotto `SACCADE_DA` radianti di errore insegue.
const SACCADE_TAU := 0.07
const INSEGUE_TAU := 0.45
const SACCADE_DA := 0.05

## La pupilla, in raggi del bulbo, al buio e in luce: tonda, quindi i due numeri sono uguali.
## Al buio è il doppio di quella dell'immagine, in luce due terzi.
const PUPILLA_LARGA := Vector2(0.40, 0.40)
const PUPILLA_STRETTA := Vector2(0.12, 0.12)
const PUPILLA_TAU := 0.9
## Anche con la Luna piena allo zenit è notte: la pupilla resta per un quarto aperta.
const PUPILLA_LUNA := 0.75

const SHADER_PELLE := "res://world/shaders/occhio_pelle.gdshader"
const SHADER_BULBO := "res://world/shaders/occhio_bulbo.gdshader"
const PELLE_COLORE := "res://assets/textures/pelle-polpo/color.jpg"
const PELLE_NORMALE := "res://assets/textures/pelle-polpo/normal.jpg"
const PELLE_RUVIDITA := "res://assets/textures/pelle-polpo/roughness.jpg"
const IRIDE := "res://assets/textures/occhio_cosmico/occhio.png"

enum Fase { NIENTE, COMPARE, CHIUSO, SI_APRE, APERTO, SI_CHIUDE, SVANISCE }

var _fase := Fase.NIENTE
var _tempo_fase := 0.0
var _presenza := 0.0
var _apertura := 0.0
var _apertura_disegnata := -1.0
var _da_chiudere := 0.0
var _da_svanire := 0.0
var _aperto_da := 0.0
var _pupilla := 1.0
var _abbagliato := 0.0
var _sguardo := Vector3.FORWARD
var _mira := Vector3.FORWARD
var _prossima_occhiata := 0.0
var _rng := RandomNumberGenerator.new()
var _luna: LuceDiLuna

var _testa: Node3D
var _pelle: MeshInstance3D
var _su: MeshInstance3D
var _giu: MeshInstance3D
var _bulbo: MeshInstance3D
var _mat_pelle: ShaderMaterial
var _mat_bulbo: ShaderMaterial


func _ready() -> void:
	# SEME FISSO: le occhiate a caso sono le stesse a ogni apertura, e una sonda che
	# misura lo sguardo misura ogni volta la stessa cosa.
	_rng.seed = 1917
	_costruisci()
	_sguardo = _avanti()
	_mira = _sguardo
	_disegna()
	set_process(true)


## Mette l'occhio nel cielo di chi sta in `guardato`: `azimut` in gradi da +Z verso
## +X, `altezza` in gradi sull'orizzonte. La testa guarda quel punto.
func colloca(guardato: Vector3, azimut: float, altezza: float) -> void:
	var az := deg_to_rad(azimut)
	var h := deg_to_rad(altezza)
	var verso := Vector3(sin(az) * cos(h), sin(h), cos(az) * cos(h))
	colloca_verso(guardato, verso)


## Come `colloca()`, con un verso del mondo invece di due angoli.
func colloca_verso(guardato: Vector3, verso: Vector3) -> void:
	global_position = guardato + verso.normalized() * distanza
	look_at(guardato, alto)
	_sguardo = _avanti()
	_mira = _sguardo


## GIÀ APERTO, senza comparire: per un occhio che c'era prima che lo si guardasse.
##
## Con `altrove` a zero lo sguardo ha già trovato. Altrimenti per `altrove` secondi guarda
## da un'altra parte, di lato e un po' in basso, e poi SCATTA su chi guarda: è il gesto che
## si legge in mezzo secondo — una cosa che si accorge di te.
func apri_subito(altrove: float = 0.0) -> void:
	_presenza = 1.0
	_apertura = 1.0
	_aperto_da = CERCA_PER - maxf(altrove, 0.0)
	if altrove > 0.0:
		var locale := Vector3(sin(ALTROVE.x) * cos(ALTROVE.y), sin(ALTROVE.y),
			-cos(ALTROVE.x) * cos(ALTROVE.y))
		_mira = (global_basis.orthonormalized() * locale).normalized()
		_sguardo = _mira
		# nessuna occhiata a caso prima di trovare: guarda lì e basta
		_prossima_occhiata = altrove + 1.0
	_vai(Fase.APERTO)
	_disegna()


## LA PUPILLA SI STRINGE DI COLPO, come davanti a una luce, e poi torna. È quello che fa
## quando la si inquadra: vedi `world/orrori/nell_oculare.gd`.
func abbaglia(per: float = 2.5) -> void:
	_abbagliato = per


## Comincia a comparire. Chiamarlo quando c'è già non fa niente.
func apri() -> void:
	if _fase == Fase.NIENTE:
		_vai(Fase.COMPARE)


## Chiude l'occhio e poi lo fa sparire; alla fine emette `svanito`.
func chiudi() -> void:
	match _fase:
		Fase.NIENTE, Fase.SVANISCE:
			return
		Fase.SI_APRE, Fase.APERTO:
			_da_chiudere = _apertura
			_vai(Fase.SI_CHIUDE)
		Fase.SI_CHIUDE:
			return
		_:
			_da_svanire = _presenza
			_vai(Fase.SVANISCE)


func _process(delta: float) -> void:
	passo(delta)


## Un passo di animazione. PUBBLICO per le sonde, come in `Tentacolo`: in headless un
## fotogramma dura un millesimo di secondo, e chi misura venti secondi di sguardo
## spegne `_process` e chiama questo col passo che gli serve.
func passo(delta: float) -> void:
	_tempo_fase += delta
	match _fase:
		Fase.COMPARE:
			var t := minf(_tempo_fase / DURATA_COMPARE, 1.0)
			_presenza = 1.0 - (1.0 - t) * (1.0 - t)
			if _tempo_fase >= DURATA_COMPARE:
				_presenza = 1.0
				_vai(Fase.CHIUSO)
		Fase.CHIUSO:
			if _tempo_fase >= ATTESA_CHIUSO:
				_vai(Fase.SI_APRE)
		Fase.SI_APRE:
			_apertura = _curva_apertura(_tempo_fase)
			if _tempo_fase >= SCHIUDE_SPIRAGLIO + SPIRAGLIO_TIENE + SCHIUDE_TUTTO:
				_apertura = 1.0
				_vai(Fase.APERTO)
		Fase.SI_CHIUDE:
			_apertura = _da_chiudere * (1.0 - smoothstep(0.0, 1.0, _tempo_fase / DURATA_CHIUDE))
			if _tempo_fase >= DURATA_CHIUDE:
				_apertura = 0.0
				_da_svanire = _presenza
				_vai(Fase.SVANISCE)
		Fase.SVANISCE:
			_presenza = _da_svanire * (1.0 - smoothstep(0.0, 1.0, _tempo_fase / DURATA_SVANISCE))
			if _tempo_fase >= DURATA_SVANISCE:
				_presenza = 0.0
				_vai(Fase.NIENTE)
				svanito.emit()
	if _fase == Fase.SI_APRE or _fase == Fase.APERTO:
		_aperto_da += delta
	else:
		_aperto_da = 0.0
	_muovi_lo_sguardo(delta)
	_muovi_la_pupilla(delta)
	_disegna()


func _vai(fase: Fase) -> void:
	_fase = fase
	_tempo_fase = 0.0


## LO SPIRAGLIO PRIMA DI APRIRSI: si scosta la pelle, si ferma, poi si apre tutto.
## È la parte che fa paura, e non ha niente di documentato — un polpo apre l'occhio
## come gli pare.
func _curva_apertura(t: float) -> float:
	if t < SCHIUDE_SPIRAGLIO:
		return SPIRAGLIO * smoothstep(0.0, 1.0, t / SCHIUDE_SPIRAGLIO)
	t -= SCHIUDE_SPIRAGLIO
	if t < SPIRAGLIO_TIENE:
		return SPIRAGLIO
	t -= SPIRAGLIO_TIENE
	return lerpf(SPIRAGLIO, 1.0, smoothstep(0.0, 1.0, t / SCHIUDE_TUTTO))


# --- lo sguardo ------------------------------------------------------------------

func _avanti() -> Vector3:
	return -global_basis.orthonormalized().z


## CERCA, POI TROVA. Finché cerca, il bulbo salta da un punto a caso all'altro e ci
## resta un secondo o due; dopo `CERCA_PER` punta la camera e non la molla. Il salto
## e l'inseguimento sono lo stesso filtro con due tempi: lontano dalla mira è un
## colpo, vicino è una deriva.
func _muovi_lo_sguardo(delta: float) -> void:
	var avanti := _avanti()
	if _aperto_da >= CERCA_PER:
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		if cam != null:
			_mira = _nel_limite((cam.global_position - global_position).normalized(), avanti)
	else:
		_prossima_occhiata -= delta
		if _prossima_occhiata <= 0.0:
			_mira = _occhiata_a_caso()
			_prossima_occhiata = _rng.randf_range(0.9, 2.2)
	var tau := SACCADE_TAU if _sguardo.angle_to(_mira) > SACCADE_DA else INSEGUE_TAU
	_sguardo = _sguardo.slerp(_mira, 1.0 - exp(-delta / tau)).normalized()


func _occhiata_a_caso() -> Vector3:
	var giro := _rng.randf_range(-SGUARDO_MASSIMO, SGUARDO_MASSIMO)
	var su := _rng.randf_range(-0.6 * SGUARDO_MASSIMO, 0.35 * SGUARDO_MASSIMO)
	var locale := Vector3(sin(giro) * cos(su), sin(su), -cos(giro) * cos(su))
	return (global_basis.orthonormalized() * locale).normalized()


func _nel_limite(dir: Vector3, avanti: Vector3) -> Vector3:
	var angolo := avanti.angle_to(dir)
	if angolo <= SGUARDO_MASSIMO:
		return dir
	return avanti.slerp(dir, SGUARDO_MASSIMO / angolo).normalized()


func _muovi_la_pupilla(delta: float) -> void:
	# DIETRO LE PALPEBRE È BUIO, e la pupilla è tutta aperta. Aperte, la Luna la
	# stringe: è la risposta alla luce, l'unico riflesso della pupilla che un polpo ha.
	var voluta := 1.0
	if _apertura > 0.05:
		voluta = 1.0 - PUPILLA_LUNA * _luce()
	if _abbagliato > 0.0:
		_abbagliato -= delta
		voluta = 0.0
	_pupilla = lerpf(voluta, _pupilla, exp(-delta / PUPILLA_TAU))


## La luce della Luna che arriva adesso, da 0 a 1: la parte di `LuceDiLuna` che non è
## il fondo del cielo.
func _luce() -> float:
	if _luna == null or not is_instance_valid(_luna):
		_luna = LuceDiLuna.find_in(get_tree()) if is_inside_tree() else null
	if _luna == null:
		return 0.0
	return clampf((_luna.light_energy - LuceDiLuna.ENERGIA_CIELO) / LuceDiLuna.ENERGIA_LUNA, 0.0, 1.0)


# --- per le sonde e per l'overlay ------------------------------------------------

func fase() -> String:
	return Fase.keys()[_fase]


func presenza() -> float:
	return _presenza


## Il bulbo sta a un raggio dal centro: c'è quando il fronte della pelle lo ha passato.
func presenza_bulbo() -> float:
	return clampf(_presenza * 2.5, 0.0, 1.0)


func apertura() -> float:
	return _apertura


## Dove guarda la pupilla, nel mondo.
func sguardo() -> Vector3:
	return -_bulbo.global_basis.orthonormalized().z


## L'asse lungo della pupilla, nel mondo: deve restare orizzontale.
func asse_pupilla() -> Vector3:
	return _bulbo.global_basis.orthonormalized().x


func pupilla() -> Vector2:
	return PUPILLA_STRETTA.lerp(PUPILLA_LARGA, _pupilla)


## Il margine di una palpebra all'angolo `beta` dall'asse, in radianti attorno
## all'asse X della testa: positivo verso l'alto.
func margine(superiore: bool, beta: float, a: float = -1.0) -> float:
	var e := _apertura if a < 0.0 else a
	if superiore:
		return lerpf(CHIUSA, APERTA_BASE, e) + lerpf(0.0, SU_ARCO, e) * arco(beta)
	return -(lerpf(CHIUSA, APERTA_BASE, e) + lerpf(0.0, GIU_ARCO, e) * arco(beta))


static func arco(beta: float) -> float:
	var c := cos(clampf(beta / CANTO, -1.0, 1.0) * PI * 0.5)
	return pow(maxf(c, 0.0), ARCO_FORMA)


## La testa, per chi vuole sapere com'è girata.
func testa() -> Node3D:
	return _testa


# --- la costruzione ----------------------------------------------------------------

func _costruisci() -> void:
	_mat_pelle = ShaderMaterial.new()
	_mat_pelle.shader = load(SHADER_PELLE) as Shader
	_mat_pelle.set_shader_parameter("colore", _texture(PELLE_COLORE))
	_mat_pelle.set_shader_parameter("normale", _texture(PELLE_NORMALE))
	_mat_pelle.set_shader_parameter("ruvidita", _texture(PELLE_RUVIDITA))
	_mat_bulbo = ShaderMaterial.new()
	_mat_bulbo.shader = load(SHADER_BULBO) as Shader
	_mat_bulbo.set_shader_parameter("iride", _texture(IRIDE))
	_mat_bulbo.set_shader_parameter("canto", CANTO)
	_mat_bulbo.set_shader_parameter("arco_forma", ARCO_FORMA)

	_testa = Node3D.new()
	_testa.name = "Testa"
	_testa.scale = Vector3.ONE * raggio
	_testa.rotation.z = ROLLIO
	add_child(_testa)

	_pelle = _istanza("Pelle", _testa)
	_pelle.mesh = _mesh_pelle()
	_su = _istanza("PalpebraSu", _testa)
	_su.mesh = ArrayMesh.new()
	_giu = _istanza("PalpebraGiu", _testa)
	_giu.mesh = ArrayMesh.new()

	_bulbo = MeshInstance3D.new()
	_bulbo.name = "Bulbo"
	var sfera := SphereMesh.new()
	sfera.radius = 1.0
	sfera.height = 2.0
	sfera.radial_segments = 96
	sfera.rings = 48
	_bulbo.mesh = sfera
	_bulbo.material_override = _mat_bulbo
	_bulbo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bulbo.scale = Vector3.ONE * raggio
	_bulbo.layers = strato
	add_child(_bulbo)


func _istanza(nome: String, padre: Node3D) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nome
	m.material_override = _mat_pelle
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.layers = strato
	padre.add_child(m)
	return m


## LE TEXTURE MANCANTI NON FERMANO NIENTE: `assets/textures` non sta nel repository e
## si rifà con `tools/prendi_pelle.py` (vedi `assets/LEGGIMI.txt`). Senza, l'occhio
## esce bianco e lo dice.
func _texture(via: String) -> Texture2D:
	if not ResourceLoader.exists(via):
		push_warning("occhio: manca %s — vedi assets/LEGGIMI.txt" % via)
		return null
	return load(via) as Texture2D


func _disegna() -> void:
	_mat_pelle.set_shader_parameter("presenza", _presenza)
	_mat_bulbo.set_shader_parameter("presenza", presenza_bulbo())
	if absf(_apertura - _apertura_disegnata) > 1e-5:
		_apertura_disegnata = _apertura
		_mesh_palpebra(_su.mesh as ArrayMesh, true)
		_mesh_palpebra(_giu.mesh as ArrayMesh, false)

	_bulbo.global_basis = Basis.looking_at(_sguardo, alto).scaled(Vector3.ONE * raggio)
	_mat_bulbo.set_shader_parameter("pupilla_raggio", pupilla().y)
	_mat_bulbo.set_shader_parameter("testa_inversa", _testa.global_basis.orthonormalized().inverse())
	_mat_bulbo.set_shader_parameter("centro", global_position)
	_mat_bulbo.set_shader_parameter("su_apertura", lerpf(CHIUSA, APERTA_BASE, _apertura))
	_mat_bulbo.set_shader_parameter("su_arco", lerpf(0.0, SU_ARCO, _apertura))
	_mat_bulbo.set_shader_parameter("giu_apertura", lerpf(CHIUSA, APERTA_BASE, _apertura))
	_mat_bulbo.set_shader_parameter("giu_arco", lerpf(0.0, GIU_ARCO, _apertura))
	if riflesso_da != null and is_instance_valid(riflesso_da):
		_mat_bulbo.set_shader_parameter("luna_luce", 1.0)
		_mat_bulbo.set_shader_parameter("luna_dir",
			(riflesso_da.global_position - global_position).normalized())
		return
	_mat_bulbo.set_shader_parameter("luna_luce", _luce())
	if _luna != null and is_instance_valid(_luna):
		_mat_bulbo.set_shader_parameter("luna_dir", _luna.global_basis.orthonormalized().z)


## La testa: `PROFILO` girato attorno all'asse Z.
func _mesh_pelle() -> ArrayMesh:
	var profilo := PackedVector2Array()
	var n := PROFILO.size()
	for i in n - 1:
		var p0: Vector2 = PROFILO[maxi(i - 1, 0)]
		var p1: Vector2 = PROFILO[i]
		var p2: Vector2 = PROFILO[i + 1]
		var p3: Vector2 = PROFILO[mini(i + 2, n - 1)]
		for k in PASSI_PER_TRATTO:
			profilo.append(p1.cubic_interpolate(p2, p0, p3, float(k) / PASSI_PER_TRATTO))
	profilo.append(PROFILO[n - 1])

	var righe := profilo.size()
	var colonne := SPICCHI + 1
	var punti := PackedVector3Array()
	var uv := PackedVector2Array()
	# LA PIASTRELLA SI SROTOLA LUNGO IL PROFILO: la distanza dal centro, sulla mappa,
	# è la strada fatta sulla pelle e non la distanza dall'asse. Proiettata da davanti,
	# sulla parete dentro l'orlo — che sale quasi dritta verso chi guarda — la mappa
	# si schiacciava in un filo, e ingrandito l'occhio quel filo erano striature nere
	# tutto attorno al bulbo. Così non c'è cucitura (è ancora un piano) e la mappa
	# non si stira mai più di un quinto.
	var strada := profilo[0].x
	for i in righe:
		if i > 0:
			strada += profilo[i].distance_to(profilo[i - 1])
		for j in colonne:
			var psi := TAU * j / SPICCHI
			punti.append(Vector3(profilo[i].x * cos(psi), profilo[i].x * sin(psi), profilo[i].y))
			uv.append(Vector2(cos(psi), sin(psi)) * strada / PIASTRELLA)
	var mesh := ArrayMesh.new()
	# la faccia buona guarda avanti, cioè verso -Z, sul tratto largo della testa
	_riempi(mesh, punti, uv, righe, colonne, righe / 2, Vector3.FORWARD)
	return mesh


## Una palpebra, alla `_apertura` di adesso.
func _mesh_palpebra(mesh: ArrayMesh, superiore: bool) -> void:
	var verso := 1.0 if superiore else -1.0
	var giu := 0.0 if superiore else SOTTO
	var righe := SEZIONE.size()
	var colonne := COLONNE_PALPEBRA
	var punti := PackedVector3Array()
	var uv := PackedVector2Array()
	# LA PIASTRELLA STA ATTACCATA ALLA PELLE, non proiettata come sulla testa: la
	# palpebra scorre, e una texture proiettata le scivolerebbe sopra. Lungo la
	# sezione si misura la strada fatta, attorno all'asse l'arco.
	var strada := 0.0
	for i in righe:
		var s: Vector2 = SEZIONE[i]
		if i > 0:
			var prima: Vector2 = SEZIONE[i - 1]
			strada += Vector2((s.x - prima.x) * s.y, s.y - prima.y).length()
		for j in colonne:
			var beta := lerpf(-LATO_PALPEBRA, LATO_PALPEBRA, float(j) / (colonne - 1))
			var alfa := margine(superiore, beta) + verso * s.x
			var r := s.y - giu
			punti.append(Vector3(sin(beta), cos(beta) * sin(alfa), -cos(beta) * cos(alfa)) * r)
			uv.append(Vector2(beta, strada * verso) / PIASTRELLA)
	# la faccia buona guarda fuori dal bulbo, sul dorso della piega
	_riempi(mesh, punti, uv, righe, colonne, righe - 2, Vector3.ZERO)


## Una griglia di punti diventa una superficie: normali dalle differenze, il raggio
## in UV2 per la comparsa, e le tangenti per la mappa normale.
##
## `fuori` dice da che parte sta la faccia buona, controllata sulla riga `riga`: se è
## zero, la faccia buona è quella che si allontana dal centro della testa.
func _riempi(mesh: ArrayMesh, punti: PackedVector3Array, uv: PackedVector2Array,
		righe: int, colonne: int, riga: int, fuori: Vector3) -> void:
	var normali := PackedVector3Array()
	normali.resize(punti.size())
	for i in righe:
		for j in colonne:
			var lungo := punti[mini(i + 1, righe - 1) * colonne + j] - punti[maxi(i - 1, 0) * colonne + j]
			var attorno := punti[i * colonne + mini(j + 1, colonne - 1)] - punti[i * colonne + maxi(j - 1, 0)]
			normali[i * colonne + j] = attorno.cross(lungo).normalized()
	# un verso solo per tutta la superficie, scelto dove la faccia buona è sicura
	var campione := riga * colonne + colonne / 2
	var voluta := fuori if fuori != Vector3.ZERO else punti[campione].normalized()
	if normali[campione].dot(voluta) < 0.0:
		for k in normali.size():
			normali[k] = -normali[k]

	# in UV2 il raggio, per la comparsa: vedi `occhio_pelle.gdshader`
	var uv2 := PackedVector2Array()
	for p in punti:
		uv2.append(Vector2(Vector2(p.x, p.y).length() / TESTA, 0.0))

	# L'ORDINE DEI VERTICI: Godot vuole le facce buone in senso ORARIO, cioè col
	# prodotto dei due lati opposto alla normale. Si controlla triangolo per
	# triangolo invece di scommettere sul verso della griglia.
	var indici := PackedInt32Array()
	for i in righe - 1:
		for j in colonne - 1:
			var a := i * colonne + j
			var b := a + 1
			var c := a + colonne
			var d := c + 1
			_triangolo(indici, punti, normali, a, b, c)
			_triangolo(indici, punti, normali, b, d, c)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = punti
	arrays[Mesh.ARRAY_NORMAL] = normali
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_TEX_UV2] = uv2
	arrays[Mesh.ARRAY_INDEX] = indici
	var st := SurfaceTool.new()
	st.create_from_arrays(arrays, Mesh.PRIMITIVE_TRIANGLES)
	st.generate_tangents()
	mesh.clear_surfaces()
	st.commit(mesh)


func _triangolo(indici: PackedInt32Array, punti: PackedVector3Array, normali: PackedVector3Array,
		x: int, y: int, z: int) -> void:
	var geometrica := (punti[y] - punti[x]).cross(punti[z] - punti[x])
	indici.append(x)
	if geometrica.dot(normali[x] + normali[y] + normali[z]) > 0.0:
		indici.append(z)
		indici.append(y)
	else:
		indici.append(y)
		indici.append(z)
