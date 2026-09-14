## Una stampa di una foto: esce dalla stampante, si strappa, si porta in giro e si
## appende a un muro.
##
## È UN `Carryable` PERCHÉ È UNA COSA CHE SI PRENDE IN MANO, e tutto quello che una
## cosa in mano deve fare — inseguire la mano senza entrare nei muri, cadere se la si
## lascia, farsi ritrovare se rotola in una fessura — lo eredita invece di rifarlo.
## Quello che aggiunge sono i due posti in cui non sta in mano e non è per terra:
## attaccata alla stampante, e appesa al muro.
##
## I QUATTRO STATI:
##   IN_STAMPA   esce dalla fessura un po' alla volta, e non si prende: una foto
##               strappata a metà non la vorrebbe nessuno.
##   ATTACCATA   è uscita tutta ed è ancora del modulo continuo. Si strappa.
##   LIBERA      è una cosa come le altre: in mano, o posata.
##   APPESA      sta su un muro, ferma. Si stacca.
##
## APPENDERE È «POSA» CON UN MURO DAVANTI, non un tasto in più. Con qualcosa in mano
## `E` posa sempre (vedi `player.gd`), e `posa()` con `prompt_posa()` sono il posto che
## `Carryable` lascia a chi ha un posto suo: la camera CCD ci si avvita al fuoco, questa
## ci si appende. Il prompt cambia da solo guardando una parete.
##
## DOVE VUOI, SU QUALSIASI MURO: è la scelta di Federico (D-239), contro i chiodi già
## decisi. Quindi niente elenco di posti buoni — si chiede al mondo, come fa la rete di
## `Carryable`: quello che guardo è verticale, è piatto sotto tutto il foglio, e davanti
## non c'è niente? Allora ci si appende.
##
## APPESA, È FIGLIA DI QUELLO SU CUI STA. Un'anta si apre e la foto va con lei; la
## cupola gira e la foto gira. Lasciata ferma dov'era l'anta chiusa sarebbe la stessa
## crosta a mezz'aria che la corazza ha dovuto smettere di lasciare (vedi `corazza.gd`).
class_name Stampa
extends Carryable

## La stampa ha cambiato posto in un modo che vale la pena ricordare: finita di stampare,
## strappata, appesa, staccata, posata. Signal DIRETTO: l'ascoltatore è uno solo, la
## stampante che tiene il registro.
signal cambiata

## Per GRUPPO e mai per nome, come ogni cosa che si prende (D-196). Non `GROUP`: quel
## nome ce l'ha già `Carryable`, e questa resta anche nel suo.
const GRUPPO := &"stampa"

## Le pagine le compone `tools/stampe_foto.py`: una per soggetto e per livello, e un
## retro uguale per tutte.
const PAGINA := "res://assets/stampe/%s_t%d.png"
const RETRO := "res://assets/stampe/retro.png"
const BERSAGLIO := "res://data/targets/%s.tres"

## Il modulo continuo della ML320: nove pollici e mezzo per undici, strisce del trattore
## comprese. È la carta che quella macchina tira, non un formato scelto.
const LARGHEZZA := 0.2413
const ALTEZZA := 0.2794

## Cinque grammi: un foglio di modulo continuo da sessanta grammi al metro quadro. Conta
## solo negli urti — un foglio non sposta una tazza.
const MASSA := 0.005

## Lo spessore del COLLISORE, non della carta. Un decimo di millimetro, su un corpo che
## cade, il motore lo attraversa anche con la collisione continua; quattro no.
const SPESSORE := 0.004

## Quanto sta staccato dal muro il centro del foglio: mezzo collisore più un millimetro,
## così il corpo appeso non tocca l'intonaco e il muro non lo respinge.
const STACCO := SPESSORE * 0.5 + 0.001

## UN MURO È VERTICALE a meno di dieci gradi. Più storto è un piano inclinato — il
## coperchio di un mobile, il tetto della cupola — e un foglio lì sopra non sta appeso,
## sta appoggiato.
const INCLINAZIONE_MAX := 0.17

## PIATTO VUOL DIRE che ogni punto sotto il foglio sta a meno di un centimetro e mezzo dal
## piano del centro. Di più, il foglio sporgerebbe su uno spigolo o nel vano di una
## finestra: appeso a metà sul niente.
const PLANARITA := 0.015

## Quanto spazio libero serve davanti al muro, sotto tutto il foglio. Tre centimetri
## bastano a dire di no a una mensola, a una placca, a un'altra stampa già appesa.
const LIBERO := 0.03

enum Stato { IN_STAMPA, ATTACCATA, LIBERA, APPESA }

## Di quale foto è la stampa. Lo scrive la stampante prima di metterla al mondo.
var target_id: StringName = &""
var livello := 1
var notte := 0
var foto := 0

var stato: Stato = Stato.LIBERA

## Dove torna una stampa staccata dal muro o strappata dalla stampante: la radice del
## mondo, che la stampante le dice. Appesa è figlia del muro, libera no.
var mondo: Node = null

var _davanti: MeshInstance3D
var _dietro: MeshInstance3D
var _col: CollisionShape3D


## Una stampa della foto, o `null` se di quel soggetto a quel livello non c'è la pagina.
## Nasce fuori dall'albero: chi la chiede la mette dove deve stare.
static func crea(soggetto: StringName, livello_foto: int, notte_foto: int, id_foto: int) -> Stampa:
	if not ResourceLoader.exists(PAGINA % [soggetto, livello_foto]):
		return null
	var s := Stampa.new()
	s.target_id = soggetto
	s.livello = livello_foto
	s.notte = notte_foto
	s.foto = id_foto
	s.name = "Stampa_%s" % soggetto
	return s


func _ready() -> void:
	mass = MASSA
	nome = "la stampa di %s" % _sigla()
	_davanti = _faccia(load(PAGINA % [target_id, livello]) as Texture2D, false)
	_dietro = _faccia(load(RETRO) as Texture2D, true)
	_col = CollisionShape3D.new()
	_col.name = "Col"
	var forma := BoxShape3D.new()
	forma.size = Vector3(LARGHEZZA, ALTEZZA, SPESSORE)
	_col.shape = forma
	add_child(_col)
	# LA STAMPA NON SI RICORDA DA SÉ: ha già il suo registro (`Stampante`, D-239), e non
	# esiste nella scena — nasce stampando — quindi la memoria del mondo non la
	# ritroverebbe al suo percorso.
	si_ricorda = false
	# DOPO i figli: `Carryable._ready()` non li guarda, ma la rete sì, e la rete cerca il
	# collisore fra i figli.
	super()
	add_to_group(GRUPPO)


## Una faccia del foglio. DUE QUADRATI E NON UNA SCATOLA: la `BoxMesh` spalma la texture
## su sei facce in una griglia, e davanti e dietro di un foglio non sono la stessa
## immagine. Nello stesso piano non litigano, perché ognuno si vede da un lato solo.
##
## `Nearest` e nessuna mipmap, come ogni texture del gioco. I FORI DEL TRATTORE sono buchi
## veri, con l'alpha a forbice: appesa, la stampa lascia vedere il muro dai fori.
func _faccia(immagine: Texture2D, girata: bool) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(LARGHEZZA, ALTEZZA)
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = immagine
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.roughness = 1.0
	mat.metallic_specular = 0.1
	m.material_override = mat
	if girata:
		m.rotation.y = PI
	add_child(m)
	return m


## La sigla del soggetto la dice il suo `.tres`, non il nome del file.
func _sigla() -> String:
	var via := BERSAGLIO % target_id
	if ResourceLoader.exists(via):
		var dati := load(via) as TargetData
		if dati != null and not dati.short.is_empty():
			return dati.short
	return String(target_id).to_upper()


## LA MANO PORTA UN FOGLIO COME PORTA UN CHILO. Il tetto di `Carryable` va con la radice
## della massa, e cinque grammi farebbero una calamita da trentacinque metri al secondo
## che salta i tramezzi prima che il motore la veda. Si tiene quello di un chilo, che è
## già la velocità di una mano.
func _velocita_massima() -> float:
	return VELOCITA_MANO


# ---------------------------------------------------------------------------
# LA STAMPANTE
# ---------------------------------------------------------------------------

## Comincia a uscire. Ferma, e senza collisione: non la si mira e non la si prende.
func inizia_stampa() -> void:
	stato = Stato.IN_STAMPA
	_ferma()
	_col.disabled = true
	esci(0.0)


## Quanta pagina è uscita, da 0 a 1.
##
## ESCE PRIMA LA CIMA, come da una stampante vera: la riga in stampa è quella sulla
## fessura, e sopra c'è quello che è già stampato. Il foglio si accorcia dal basso e la
## texture si ritaglia dall'alto; a posizionarlo sulla fessura ci pensa la stampante.
func esci(frazione: float) -> void:
	var alto := ALTEZZA * clampf(frazione, 0.0, 1.0)
	for m: MeshInstance3D in [_davanti, _dietro]:
		(m.mesh as QuadMesh).size = Vector2(LARGHEZZA, maxf(alto, 0.0005))
		m.position.y = ALTEZZA * 0.5 - alto * 0.5
		(m.material_override as StandardMaterial3D).uv1_scale = Vector3(1.0, clampf(frazione, 0.0, 1.0), 1.0)


## È uscita tutta: si può strappare.
func finisci_stampa() -> void:
	esci(1.0)
	_col.disabled = false
	stato = Stato.ATTACCATA
	Log.info("stampa", "%s è uscita dalla stampante" % nome)
	cambiata.emit()


## Il modulo continuo la spinge fuori: comincia la stampa dopo, e questa — se nessuno
## l'ha strappata — si stacca e cade dove capita.
func stacca_dalla_stampante() -> void:
	if stato != Stato.IN_STAMPA and stato != Stato.ATTACCATA:
		return
	esci(1.0)
	_libera()
	cambiata.emit()


# ---------------------------------------------------------------------------
# LA MANO
# ---------------------------------------------------------------------------

func prompt() -> String:
	match stato:
		Stato.ATTACCATA:
			return "Strappa %s" % nome
		Stato.APPESA:
			return "Stacca %s" % nome
	return super()


## Guardando un muro su cui ci sta, il prompt lo dice. Altrove si posa.
func prompt_posa() -> String:
	if not dove_appenderla().is_empty():
		return "Appendi %s" % nome
	return super()


## Con un muro buono davanti si appende; altrove si posa come qualunque altra cosa.
func posa() -> void:
	var dove := dove_appenderla()
	if dove.is_empty():
		super()
		return
	appendi(dove[&"su"], dove[&"xf"])


## Prenderla la strappa o la stacca, senza doverlo dire: chi la prende dalla stampante la
## sta strappando, chi la prende dal muro la sta staccando. Mentre esce no.
func prendi(chi: PhysicsBody3D) -> void:
	if in_mano() or stato == Stato.IN_STAMPA:
		return
	var era := stato
	if era != Stato.LIBERA:
		_libera()
	super(chi)
	if era == Stato.ATTACCATA:
		Log.info("stampa", "%s strappata" % nome)
	elif era == Stato.APPESA:
		Log.info("stampa", "%s staccata dal muro" % nome)
	cambiata.emit()


func lascia() -> void:
	var era_in_mano := in_mano()
	super()
	if era_in_mano:
		cambiata.emit()


## La appende su `su`, in `xf`. La usa anche la stampante quando rimette al loro posto le
## stampe di ieri, e allora non annuncia niente: non è cambiato niente.
func appendi(su: Node3D, xf: Transform3D, annuncia := true) -> void:
	if in_mano():
		lascia()
	_ferma()
	if get_parent() == null:
		su.add_child(self, true)
	elif get_parent() != su:
		reparent(su)
	global_transform = xf
	stato = Stato.APPESA
	if annuncia:
		Log.info("stampa", "%s appesa a %s" % [nome, su.name])
		cambiata.emit()


## DOVE SI APPENDEREBBE ADESSO, guardando dove guarda il giocatore: `{su, xf}`, o vuoto se
## lì non ci sta.
##
## SI GUARDA LA GEOMETRIA VERA, cioè la corazza (`Corazza.LAYER_APPOGGI`), e non gli
## ingombri: la faccia del blocco di una fila di sedie è aria, e una foto appesa lì
## resterebbe sospesa davanti al niente. Ci si appende dove si vede un muro.
##
## TRE DOMANDE, dalla più economica alla più cara:
##   1. quello che guardo, entro la portata, è verticale e non è un oggetto sciolto;
##   2. sotto tutto il foglio — nove punti, i quattro angoli, i quattro lati e il
##      centro — c'è la stessa superficie, piatta e girata allo stesso modo;
##   3. davanti, per tre centimetri, non c'è niente.
func dove_appenderla() -> Dictionary:
	if not is_inside_tree():
		return {}
	var giocatore := Player.find_in(get_tree())
	if giocatore == null:
		return {}
	var occhio := giocatore.camera().global_transform
	var spazio := get_world_3d().direct_space_state
	var mira := PhysicsRayQueryParameters3D.create(occhio.origin,
		occhio.origin - occhio.basis.z * Player.INTERACT_RANGE, Corazza.LAYER_APPOGGI, [get_rid()])
	var colpo := spazio.intersect_ray(mira)
	if colpo.is_empty() or colpo["collider"] is RigidBody3D:
		return {}
	var n: Vector3 = colpo["normal"]
	if absf(n.y) > INCLINAZIONE_MAX:
		return {}
	# A PIOMBO anche su un muro un filo storto: la foto si appende dritta, e se il muro è
	# troppo storto per lei lo dice la planarità qui sotto.
	n = Vector3(n.x, 0.0, n.z).normalized()
	var su := Vector3.UP
	var destra := su.cross(n)
	var centro: Vector3 = colpo["position"]
	for i in [-1, 0, 1]:
		for j in [-1, 0, 1]:
			var punto: Vector3 = centro + destra * (i * LARGHEZZA * 0.5) + su * (j * ALTEZZA * 0.5)
			var tasta := PhysicsRayQueryParameters3D.create(punto + n * 0.05, punto - n * 0.05,
				Corazza.LAYER_APPOGGI, [get_rid()])
			var sotto := spazio.intersect_ray(tasta)
			if sotto.is_empty() or sotto["collider"] is RigidBody3D:
				return {}
			if absf((sotto["position"] - centro).dot(n)) > PLANARITA:
				return {}
			if (sotto["normal"] as Vector3).dot(n) < 0.94:
				return {}
	var davanti := PhysicsShapeQueryParameters3D.new()
	var scatola := BoxShape3D.new()
	scatola.size = Vector3(LARGHEZZA - 0.01, ALTEZZA - 0.01, LIBERO)
	davanti.shape = scatola
	davanti.transform = Transform3D(Basis(destra, su, n), centro + n * (0.002 + LIBERO * 0.5))
	davanti.collision_mask = Corazza.LAYER_APPOGGI
	davanti.exclude = [get_rid()]
	if not spazio.intersect_shape(davanti, 1).is_empty():
		return {}
	# LA CORAZZA STA SOTTO LA MESH (vedi `corazza.gd`), quindi il padre del corpo colpito
	# è la cosa che si vede: è a lei che la foto si appende, e con lei si muove.
	var corpo := colpo["collider"] as Node3D
	var mesh := corpo.get_parent() as MeshInstance3D
	return {
		&"su": mesh if mesh != null else corpo,
		&"xf": Transform3D(Basis(destra, su, n), centro + n * STACCO),
	}


## Come ricordarla domani: di quale foto è, e dove sta. Appesa si ricorda anche a cosa, e
## in coordinate di quella cosa — un'anta aperta domani non è dov'era stanotte.
func ricordo(radice: Node) -> Dictionary:
	var r := {
		&"target": target_id, &"livello": livello, &"notte": notte, &"foto": foto,
		&"appesa": stato == Stato.APPESA, &"xf": global_transform,
	}
	if stato == Stato.APPESA and get_parent() != null and radice != null:
		r[&"su"] = String(radice.get_path_to(get_parent()))
		r[&"xf_su"] = transform
	return r


func _ferma() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true


## Torna una cosa come le altre: figlia del mondo, libera di cadere, e prendibile.
func _libera() -> void:
	if mondo != null and get_parent() != mondo:
		reparent(mondo)
	freeze = false
	_col.disabled = false
	sleeping = false
	stato = Stato.LIBERA
