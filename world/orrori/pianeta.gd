## LA VISIONE DEL PIANETA — `Ctrl+F9`.
##
## Ti si chiudono gli occhi. Quando li riapri non sei più in cupola: sei fermo nello spazio
## davanti a un pianeta che non è nostro, con cinque braccia enormi avvolte attorno che lo
## tengono e lo girano piano. Poi da sotto le braccia escono tentacoli più piccoli, uno dopo
## l'altro, ognuno sopra quelli di prima, finché del pianeta non resta niente di scoperto. Poi
## la cosa si volta, e in mezzo alle braccia c'è un OCCHIO: partono tutti da lì. Guarda altrove, poi scatta su di te e la pupilla si stringe. E
## mentre ti guarda tu vieni tirato indietro, piano e poi svelto, finché quella cosa non è un
## punto fra le stelle. Buio. Sei di nuovo in cupola, e non è successo niente.
##
## LA RICHIESTA, DA FEDERICO, in tre passaggi. Prima: «il player chiude gli occhi, sviene, si
## ritrova in mezzo allo spazio davanti a questo pianeta, poi vede il pianeta che viene
## mangiato, e poi vede il mostro che mangia anche lui. E non può fare niente». Prima ancora
## era tutto dentro l'oculare — il pianeta cresceva nel campo e poi se ne andava — e guardare
## una cosa da dentro uno strumento la tiene a distanza di sicurezza: c'è un tubo fra te e lei.
##
## POI, GUARDANDOLA: «è evidente che quello è un pianeta super pezzotto, super piccolo in
## realtà; non mi ci posso avvicinare così, e quando arriva attaccato è grande quanto un
## asteroide». È vero, ed è una questione di scala: da mezzo raggio si vede la buccia, e la
## buccia di una cosa grande quanto un pianeta non si vede mai — quello che si vede da vicino
## è sempre un sasso. Quindi NON CI SI AVVICINA MAI: si resta a tre raggi e mezzo, che è la
## distanza da cui un pianeta è un pianeta. E alla fine, invece di finirci dentro, CI SI
## ALLONTANA: è il movimento che dice quanto è grande, perché una cosa che diventa un punto
## era enorme.
##
## E TERZO: «quando si gira, voglio che si veda l'occhio dal quale poi sono partiti i
## tentacoli». È l'occhio del cielo (`world/occhio.gd`), quello di `F6` e dell'oculare: stessa
## creatura, stessa iride, e adesso si sa anche che le braccia partono da lui.
##
## È UNA VISIONE, E UNA VISIONE NON LASCIA PROVE. La prima idea era un mostro che mangiava
## Giove; Federico l'ha fermata subito — «se ne accorgerebbe tutto il mondo» — ed è il
## pilastro delle anomalie negabili: un pianeta che sparisce dal cielo è un fatto pubblico, e
## il giorno dopo il gioco è un altro gioco. Poi la stessa cosa in piccolo: un satellite che
## manca, una cicatrice nella fascia come quelle della cometa Shoemaker-Levy 9, la curva di
## luce che prova un passaggio. Tutte prove — e una prova trasforma una visione in un indizio,
## cioè in qualcosa da indagare. Qui non resta niente: nessuna stampa, nessun registro,
## nessuna riga sulla BBS, niente spostato, e l'orologio non fa salti — passa il mezzo minuto
## che passa, come per uno rimasto fermo a guardare il buio.
##
## E IL PIANETA NON È NOSTRO, che è l'unico modo di farsene divorare uno senza che il mondo
## se ne accorga: non c'è nessuno che possa smentirti, perché quel posto non è qui. Com'è
## fatto un mondo con l'atmosfera visto da vicino sta in
## `world/shaders/orrore_pianeta.gdshader`, e non è copiato da nessun pianeta vero apposta.
##
## NON SI MUORE, e va detto perché il pilastro del rifugio è esplicito: qui non c'è danno, non
## c'è fallimento, non si perde niente. Si perde il CONTROLLO, per mezzo minuto, ed è
## l'unica cosa che questo orrore toglie. Chi gioca torna esattamente dov'era, in piedi dove
## era in piedi, con la notte che continua.
##
## COME SI FA A NON VEDERE L'OSSERVATORIO. Non si sposta nessuno: la visione accende una
## CAMERA SUA che disegna solo il layer degli orrori (`OrroreNellOculare.STRATO`) e nient'altro.
## Il mondo resta dov'è e semplicemente non viene disegnato; il cielo invece sì, perché le
## stelle non sono oggetti ma lo sfondo dell'ambiente — e un fondo di stelle senza niente
## davanti è esattamente lo spazio. Il cambio si fa da nero a nero, così il taglio non si vede
## mai, e la camera nuova parte guardando dove si stava guardando, o le stelle ruoterebbero di
## scatto.
##
## LE BRACCIA GRANDI SONO CINQUE, e un polpo ne ha otto: le altre tre stanno dall'altra parte
## del globo, che è anche dove sta l'occhio. Tengono il pianeta dal primo all'ultimo secondo.
##
## LO MANGIANO I TENTACOLI, UNO SOPRA L'ALTRO. La prima stesura lo faceva sparire sotto una
## pelle che ci saliva sopra, e Federico l'ha bocciata: «invece che farlo ricoprire da sta
## patina, fai che quella patina sono tanti tentacoli che si sommano uno sopra l'altro e si
## mangiano in questo modo il pianeta». Sono centosettanta, grossi fra un quarto e metà di un
## braccio, e spuntano da un anello attorno all'occhio, SOTTO le braccia grandi: crescono dalla
## radice alla punta uno dopo l'altro, partono di sbieco e serpeggiano — dritti verso il
## centro della faccia erano una stella marina, dritti di sbieco un gomitolo di vimini — e
## ognuno sta più in alto di quelli arrivati prima, così chi arriva dopo passa sopra. Restano
## tutti sotto le braccia grandi, che il pianeta lo tengono ancora. Chi resta sotto si scurisce
## man mano che gli altri lo coprono, e sotto il mucchio si spegne anche il pianeta: fra un
## tentacolo e l'altro c'è il buio, non le nuvole.
##
## La seconda lettura era sbagliata anche lei, e va detto perché era la più facile: «vorrei
## che ce ne fossero una marea in più ma molto più piccoli» voleva dire IN PIÙ delle cinque
## braccia, non al loro posto. Quaranta tentacoli sottili senza le braccia erano una rete, e
## le braccia andavano bene.
##
## L'occhio non si vede finché la cosa non si volta, e allora quello che si vede è l'occhio con
## la corona delle braccia e dei tentacoli che gli partono attorno.
##
## LE VENTOSE NON SI VEDONO, e non è una rinuncia: un polpo che tiene una cosa la avvolge con
## la faccia orale all'INTERNO, contro l'oggetto, e la punta si arrotola con le ventose dentro
## la spirale. Da fuori si vede il dorso del braccio. È lo stesso gesto con cui un
## *Amphioctopus marginatus* si porta dietro mezzo guscio di noce di cocco e se lo richiude
## addosso (Finn, Tregenza e Norman, 2009): non un mostro che azzanna, una bestia che tiene in
## mano una cosa. Come crescono i tentacoli sta in `world/shaders/orrore_braccio_polpo.gdshader`.
##
## LA PUNTA SI ARROTOLA, e come lo fa è l'unico pezzo di geometria copiato: la curvatura
## cresce in progressione geometrica lungo la punta, che è la definizione di una spirale
## logaritmica, ed è la forma in cui un braccio di polpo si arriccia. Il pezzo avvolto e la
## punta si attaccano senza spigolo perché la spirale parte dalla curvatura che ha il globo:
## uno, in raggi del pianeta.
##
## FINISCE DA SOLA, ed è il primo orrore che lo fa — gli altri otto restano finché non gli si
## chiede di andarsene. Una visione ha una durata sua; il contratto di `Orrore` la regge già
## senza cambiare niente, perché `finito` lo può emettere chiunque, non solo chi è stato
## congedato. Il tasto ripremuto la taglia, e la taglia nell'unico modo onesto: buio, e si
## torna in cupola.
##
## LA PELLE È A PIASTRELLE ESAGONALI, col suo rilievo e la sua ruvidità, ed è illuminata da
## una luce vera invece che da un lambert scritto a mano. «Migliora molto le texture perché
## fanno totalmente cagare»: erano la foto della pelle ripetuta sugli UV, piatta e opaca, e da
## vicino erano salsicce di gomma. Adesso è lo stesso campionamento della pelle attorno
## all'occhio del cielo (`world/shaders/pelle_polpo.gdshaderinc`).
##
## LA LUCE DELLA VISIONE È UNA SOLA ed è sua: una direzionale che sta sul layer della visione
## e illumina solo lui. La Luna di stanotte non la tocca nemmeno — sta sul layer del mondo, che
## la camera della visione non guarda — e non deve: una cosa che sta da un'altra parte
## dell'universo non la illumina la Luna di qui.
class_name OrrorePianeta
extends Orrore

const SHADER_PIANETA := "res://world/shaders/orrore_pianeta.gdshader"
const SHADER_BRACCIO := "res://world/shaders/orrore_braccio_polpo.gdshader"
const PELLE := "res://assets/textures/pelle-polpo/color.jpg"
const PELLE_NORMALE := "res://assets/textures/pelle-polpo/normal.jpg"
const PELLE_RUVIDITA := "res://assets/textures/pelle-polpo/roughness.jpg"

## Il layer che la camera della visione disegna, e nient'altro. È quello dell'occhio
## nell'oculare (`Ctrl+F5`): un layer che il mondo non usa, e ne basta uno.
const STRATO := OrroreNellOculare.STRATO

## I TEMPI, in secondi, uno per pezzo del racconto.
##   SPEGNE   gli occhi si chiudono
##   NERO     il nero in cui si cambia posto
##   ACCENDE  si riaprono, e sei lì
##   GUARDA   lo guardi: un pianeta tenuto in mano
##   MANGIA   da sotto le braccia escono i tentacoli, uno sopra l'altro, e lo seppelliscono
##   VOLTA    si gira, e in mezzo alle braccia c'è l'occhio, che guarda altrove
##   TROVA    scatta su di te, e la pupilla si stringe
##   VIA      vieni tirato indietro, finché non è un punto fra le stelle
##   BUIO     il buio
##   TORNA    riapri gli occhi in cupola
const SPEGNE := 1.2
const NERO := 0.9
const ACCENDE := 1.4
const GUARDA := 4.0
const MANGIA := 7.5
const VOLTA := 5.0
const TROVA := 4.0
const VIA := 5.5
const BUIO := 1.4
const TORNA := 1.6

const T_NERO := SPEGNE
const T_ACCENDE := T_NERO + NERO
const T_GUARDA := T_ACCENDE + ACCENDE
const T_MANGIA := T_GUARDA + GUARDA
const T_VOLTA := T_MANGIA + MANGIA
const T_TROVA := T_VOLTA + VOLTA
const T_VIA := T_TROVA + TROVA
const T_BUIO := T_VIA + VIA
const T_TORNA := T_BUIO + BUIO
const T_FINE := T_TORNA + TORNA

## Quanto è grande il pianeta, in metri, e da quanti raggi lo si guarda. Tre raggi e mezzo
## danno un disco largo trentaquattro gradi in un campo di sessantacinque: riempie mezza
## inquadratura e attorno resta cielo. Quanto sia grande DAVVERO non conta e non si può
## sapere — non c'è niente accanto con cui confrontarlo, ed è voluto: conta che stia in scala
## con le braccia, e quelle sono misurate in raggi del pianeta.
##
## E NON CI SI AVVICINA MAI: la distanza resta questa per tutta la visione, e alla fine cresce
## fino a `LONTANISSIMO`, venti raggi, da cui tutta la cosa è un pallino fra le stelle.
const RAGGIO := 40.0
const LONTANO := 3.4
const LONTANISSIMO := 20.0
const CAMPO := 65.0

## Quanto lo girano, in gradi al secondo, e attorno a che asse (nel riferimento di chi
## guarda). Due gradi al secondo sono abbastanza per vedere che gira e pochi per non
## sembrare un mappamondo spinto con la mano.
const GIRO := 2.0
const ASSE := Vector3(0.16, 0.22, -0.962)

## Dove sta il sole di quel posto, sempre nel riferimento di chi guarda: da sinistra, in
## alto, e un po' da dietro le spalle. Il terminatore cade DENTRO la faccia che si vede, ma
## verso il bordo: con la luce di taglio — la prima prova — metà del globo restava in ombra e
## con lui le braccia che ci stavano sopra, che è il difetto di D-271 in persona. Di fronte
## sarebbe l'errore opposto: un disco pieno, senza la linea fra il giorno e la notte, e quella
## linea è mezza lettura.
const SOLE := Vector3(-0.66, 0.38, 0.30)

## Quanto è acceso il pianeta, che è l'unico a farsi luce da solo (vedi il suo shader).
const ENERGIA := 0.55
## La luce della visione: quanto è forte e di che colore.
const LUCE := 1.35
const LUCE_COLORE := Color(1.0, 0.97, 0.92)
## Quanto è grande una piastrella di pelle, in metri. Su una bestia grande come un pianeta una
## chiazza di pelle è larga come una città: quello che conta è che la trama resti fitta
## abbastanza da non potersi contare.
const PIASTRELLA := 9.0

## LE BRACCIA GRANDI, quelle che lo tengono: cinque, dal primo all'ultimo secondo.
const BRACCIA := 5
## La mezza larghezza di un braccio alla radice, in raggi del pianeta. Con l'arco che fa
## attorno al globo viene lungo una quindicina di volte il proprio diametro, che è la
## proporzione di un braccio vero (D-271).
const LARGO := 0.19
## Quanto è lunga la punta arrotolata di un braccio grande, in raggi del pianeta, e di quanto
## cresce la curvatura per unità di lunghezza.
const PUNTA := 0.85
const PUNTA_CRESCITA := 5.6
## La curvatura da cui parte ogni ricciolo: quella del globo, in raggi del pianeta.
const PUNTA_CURVA := 1.15
## Quanto è schiacciata la sezione di un braccio nel verso che preme sul globo.
const SEZIONE := 0.85

## I TENTACOLI CHE SE LO MANGIANO: tanti, piccoli, e arrivano uno dopo l'altro.
const TENTACOLI := 170
## La loro mezza larghezza alla radice, in raggi del pianeta: da quanto a quanto, a caso. Fra
## un quarto e metà di un braccio grande.
const SOTTILE_MIN := 0.05
const SOTTILE_MAX := 0.09
## Dove spuntano, in gradi dal polo di dietro: FUORI dall'occhio — le palpebre arrivano a
## ventisette gradi — e non oltre i quarantacinque, o il giro porterebbe le radici in vista.
const RADICE_DA := 27.0
const RADICE_A := 45.0
## Di quanto ognuno può andare di sbieco rispetto al meridiano, in radianti, e di quanto può
## svoltare di lato strada facendo (radianti di svolta per radiante di strada). Dritti, lungo
## i cerchi massimi, passavano tutti a meno di trentacinque gradi dal centro della faccia e ne
## lasciavano scoperto il giro: coprivano metà faccia.
const SBIECO := 0.9
const PIEGA := 0.7
## E ONDEGGIANO: la svolta cambia lungo la strada come un'onda, così un tentacolo serpeggia
## invece di tirare una riga. Quanto (radianti di svolta per radiante di strada) e ogni quanto
## (radianti di strada per onda), da quanto a quanto. Dritti erano un gomitolo di vimini.
const ONDA_MIN := 1.5
const ONDA_MAX := 3.5
const ONDA_LUNGA_MIN := 0.7
const ONDA_LUNGA_MAX := 1.2
## Si assottigliano più tardi delle braccia grandi (vedi `_grossezza`): è il pezzo di mezzo
## che copre, e un cono lo lasciava troppo stretto.
const TIRATA := 0.45
## La loro punta arrotolata è lunga sette volte la mezza larghezza, e fa poco più di un giro:
## `PUNTA_GIRO` è il prodotto fra la crescita della curvatura e la lunghezza della punta.
const PUNTA_LUNGA := 7.0
const PUNTA_GIRO := 4.2
## Di quanto l'ultimo sta più in alto del primo, in raggi del pianeta: è lo spessore del
## mucchio. I primi arrivati restano sotto, e chi arriva dopo ci passa sopra.
const STRATI := 0.04
## Quanto ci mette uno a crescere dalla radice alla punta, in secondi, da quanto a quanto.
const CRESCE_MIN := 1.4
const CRESCE_MAX := 2.2
## Quanto si scurisce un tentacolo quando tutti quelli arrivati dopo gli sono passati sopra.
const OMBRA := 0.65
## Quanto si spegne il pianeta sotto il mucchio, e quanto è larga la sfumatura, in radianti.
const SEPOLTO := 0.85
const SFUMA := 0.6
## Dove sta il bordo del globo per chi guarda, in radianti dal polo di dietro. Non è pi
## mezzi: da tre raggi e mezzo si vede meno di mezza sfera, e il bordo cade più indietro.
const ORLO_VISTO := 1.97
## L'OCCHIO in mezzo alla corona: quanto è grande il bulbo e quanto sta lontano dal centro, in
## raggi del pianeta. Un terzo fa un occhio di quattordici metri su un globo di quaranta:
## sporge dalla pelle come sporge quello di un polpo, e le radici delle braccia gli stanno
## attorno senza attraversarlo.
const OCCHIO_SCENA := "res://world/occhio.tscn"
const OCCHIO_RAGGIO := 0.34
const OCCHIO_DOVE := 0.95
## Per quanta parte della voltata guarda altrove prima di scattare su di te.
const OCCHIO_ALTROVE := 0.80

## Il seme delle braccia: la visione viene sempre uguale.
const SEME := 19991116

var _sistema: Node3D
var _globo: MeshInstance3D
var _braccia: Array[MeshInstance3D] = []
## I tentacoli che se lo mangiano, in ordine d'arrivo: quando comincia a crescere ognuno, in
## secondi dall'inizio della mangiata, e quanto ci mette.
var _tentacoli: Array[MeshInstance3D] = []
var _nascite: Array[float] = []
var _durate: Array[float] = []
## La linea di mezzo e la grossezza di ogni tentacolo, nel riferimento del globo: le sonde ci
## misurano quanta faccia coprono.
var _linee: Array[PackedVector3Array] = []
var _spessori: Array[PackedFloat32Array] = []
## Dove spunta ogni braccio e dove arriva la sua punta, nel riferimento del globo: servono
## alle sonde per chiedere quello che conta, cioè che le radici restino dietro il bordo e che
## le punte arrivino sulla faccia che si vede.
var _radici: Array[Vector3] = []
var _punte: Array[Vector3] = []
var _mat_globo: ShaderMaterial
var _mat_braccio: ShaderMaterial
## L'occhio in mezzo alla corona, e la luce che illumina tutta la visione.
var _occhio: Occhio
var _luce: DirectionalLight3D

## La camera della visione, e quella che c'era prima: alla fine si rimette corrente QUELLA,
## non «quella del giocatore», perché chi stava guardando nell'oculare deve ritrovarsi
## nell'oculare.
var _cam_visione: Camera3D
var _camera_prima: Camera3D
var _giocatore: Player
var _controllo_prima := true
var _velo: CanvasLayer
var _nero: ColorRect

var _t := 0.0
var _giro := 0.0
## L'ultimo braccio costruito: `_mesh_braccio` lascia qui la punta, la linea di mezzo e le
## grossezze per chi lo ha chiamato.
var _ultima_punta := Vector3.ZERO
var _ultima_linea := PackedVector3Array()
var _ultime_grossezze := PackedFloat32Array()


func _comincia() -> void:
	_giocatore = Player.find_in(get_tree())
	_camera_prima = get_viewport().get_camera_3d() if is_inside_tree() else null
	# IL CONTROLLO SI TOGLIE SUBITO, prima ancora del nero: la visione comincia perché ti si
	# chiudono gli occhi, e uno a cui si chiudono gli occhi non cammina. Si ricorda com'era,
	# perché chi stava all'oculare o al monitor il controllo non ce l'aveva già, e
	# restituirglielo sarebbe peggio che togliergliene.
	if _giocatore != null:
		_controllo_prima = _giocatore.is_enabled()
		_giocatore.set_enabled(false)
		_giocatore.mostra_mirino(false)
	_fai_il_velo()


## Tagliata prima del tempo: si va al buio e si torna in cupola. Non c'è un altro modo onesto
## di finirla — sparire da davanti a una cosa che sta arrivando non è una fine.
func _congeda() -> void:
	_t = maxf(_t, T_BUIO)


func _avanza(delta: float) -> void:
	var prima := _t
	_t += delta
	_giro += deg_to_rad(GIRO) * delta
	# SI CAMBIA POSTO NEL NERO, sempre: accendere la camera della visione un fotogramma prima
	# o dopo si vedrebbe come un salto
	if prima < T_NERO and _t >= T_NERO:
		_vai_la()
	# QUANDO COMINCIA A VOLTARSI l'occhio è già aperto e guarda da un'altra parte; scatta su
	# di te quando la voltata è quasi finita, cioè quando sei tu quello che ha davanti
	if prima < T_VOLTA and _t >= T_VOLTA and _occhio != null:
		_occhio.apri_subito(VOLTA * OCCHIO_ALTROVE)
	if prima < T_TROVA and _t >= T_TROVA and _occhio != null:
		_occhio.abbaglia(TROVA + VIA)
	if prima < T_TORNA and _t >= T_TORNA:
		_torna_qui()
	if _sistema != null:
		_colloca()
		_disegna()
	# l'occhio si muove dopo essere stato messo al suo posto: lo sguardo si misura da lì
	if _occhio != null:
		_occhio.passo(delta)
	if _nero != null:
		_nero.color.a = velo()
	if _t >= T_FINE:
		_se_ne_va()


# --- il posto dove si va ----------------------------------------------------------------

## Accende la camera della visione e costruisce quello che c'è da vedere. Si chiama nel nero.
func _vai_la() -> void:
	_cam_visione = Camera3D.new()
	_cam_visione.name = "CameraVisione"
	# SOLO IL LAYER DELLA VISIONE: l'osservatorio, il terreno, la cupola e tutto il resto
	# restano dove sono e non vengono disegnati. Il cielo non è un oggetto — è lo sfondo
	# dell'ambiente — e quindi resta: stelle, e niente davanti.
	_cam_visione.cull_mask = STRATO
	_cam_visione.fov = CAMPO
	add_child(_cam_visione)
	if _camera_prima != null and is_instance_valid(_camera_prima) and _camera_prima.is_inside_tree():
		_cam_visione.global_transform = _camera_prima.global_transform
		_cam_visione.far = _camera_prima.far
	_cam_visione.current = true
	_accendi()


## Rimette le cose com'erano. Si chiama nel buio, per la stessa ragione.
func _torna_qui() -> void:
	if _sistema != null:
		_sistema.queue_free()
		_sistema = null
		_globo = null
		_braccia.clear()
		_tentacoli.clear()
		_nascite.clear()
		_durate.clear()
		_linee.clear()
		_spessori.clear()
		_radici.clear()
		_punte.clear()
	if _occhio != null:
		_occhio.queue_free()
		_occhio = null
	if _luce != null:
		_luce.queue_free()
		_luce = null
	if _cam_visione != null:
		_cam_visione.queue_free()
		_cam_visione = null
	# `current = true` su una camera ne spegne ogni altra dello stesso viewport: è come
	# rientra l'oculare, ed è meglio che spegnere la nostra e sperare che qualcuno si faccia
	# avanti — senza nessuna camera corrente il viewport resta nero.
	if _camera_prima != null and is_instance_valid(_camera_prima) and _camera_prima.is_inside_tree():
		_camera_prima.current = true
	if _giocatore != null and is_instance_valid(_giocatore):
		_giocatore.mostra_mirino(_controllo_prima)
		_giocatore.set_enabled(_controllo_prima)


func _se_ne_va() -> void:
	_torna_qui()
	if _velo != null:
		_velo.queue_free()
		_velo = null
		_nero = null
	_chiudi()


func _fai_il_velo() -> void:
	# IL NERO STA IN UN `CanvasLayer` DENTRO IL MONDO, come il velo dell'oculare: disegna nel
	# `SubViewport` del gioco e passa dal filtro CRT insieme a tutto il resto, invece di
	# stargli sopra a piena risoluzione.
	_velo = CanvasLayer.new()
	_velo.name = "VeloVisione"
	_velo.layer = 64
	_nero = ColorRect.new()
	_nero.name = "Nero"
	_nero.set_anchors_preset(Control.PRESET_FULL_RECT)
	_nero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nero.color = Color(0.0, 0.0, 0.0, 0.0)
	_velo.add_child(_nero)
	add_child(_velo)


# --- quello che si vede -----------------------------------------------------------------

func _accendi() -> void:
	_sistema = Node3D.new()
	_sistema.name = "Sistema"
	add_child(_sistema)

	# LA LUCE DELLA VISIONE, che illumina solo il suo layer: braccia, tentacoli e occhio sono
	# materiali illuminati come tutto il resto del gioco, e senza una luce sarebbero neri.
	_luce = DirectionalLight3D.new()
	_luce.name = "SoleDiLa"
	# LA MASCHERA DELLA CAMERA TAGLIA ANCHE LE LUCI, e non solo la roba da disegnare: una
	# luce sta su un layer come una mesh, e se la camera quel layer non lo guarda la luce non
	# esiste. Ne servono due, e non sono la stessa cosa: `layers` è dove sta la luce — e deve
	# stare dove guarda la camera della visione — mentre `light_cull_mask` è cosa illumina.
	# Senza la prima, braccia e occhio restavano neri, con addosso solo il turchino
	# del cielo, e sembravano ritagli di cartone.
	_luce.layers = STRATO
	_luce.light_cull_mask = STRATO
	_luce.light_energy = LUCE
	_luce.light_color = LUCE_COLORE
	_luce.shadow_enabled = false
	add_child(_luce)
	# E LA LUNA DI QUI NON ILLUMINA QUELLA ROBA LÀ, senza bisogno di toccarla: sta sul layer
	# del mondo, che la camera della visione non guarda.

	_mat_globo = ShaderMaterial.new()
	_mat_globo.shader = load(SHADER_PIANETA) as Shader
	_mat_globo.set_shader_parameter("energia", ENERGIA)
	_globo = MeshInstance3D.new()
	_globo.name = "Globo"
	_globo.mesh = _sfera(1.0)
	_globo.material_override = _mat_globo
	_globo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_globo.layers = STRATO
	_sistema.add_child(_globo)

	_mat_braccio = ShaderMaterial.new()
	_mat_braccio.shader = load(SHADER_BRACCIO) as Shader
	# le piastrelle delle braccia sono già nei loro UV, misurate in metri: qui una e una
	_mat_braccio.set_shader_parameter("piastrelle", Vector2.ONE)
	_mat_braccio.set_shader_parameter("colore", _texture(PELLE))
	_mat_braccio.set_shader_parameter("normale", _texture(PELLE_NORMALE))
	_mat_braccio.set_shader_parameter("ruvidita", _texture(PELLE_RUVIDITA))

	# LE BRACCIA GRANDI. Le radici stanno dietro, strette attorno al polo lontano: dagli otto
	# ai ventisei gradi da lì. Più larghe, di due braccia spuntava la radice dal bordo del
	# globo, come due nocche: un braccio grosso sta fuori dalla buccia di quanto è grosso, e il
	# bordo lo scopre molto prima dei novanta gradi.
	var dado := RandomNumberGenerator.new()
	dado.seed = SEME
	for i in BRACCIA:
		var az := TAU * float(i) / float(BRACCIA) + dado.randf_range(-0.22, 0.22)
		var phi := deg_to_rad(dado.randf_range(8.0, 26.0))
		var radice := Vector3(sin(phi) * cos(az), sin(phi) * sin(az), -cos(phi))
		# la tangente verso il fronte, lungo il cerchio massimo che passa per +Z
		var avanti := _verso_il_fronte(radice)
		if avanti == Vector3.ZERO:
			continue
		var arco := (PI - phi) - dado.randf_range(0.25, 0.95)
		var largo := LARGO * dado.randf_range(0.85, 1.12)
		var m := _pezzo("Braccio%d" % i,
			_mesh_braccio(radice, avanti, arco, largo, PUNTA, PUNTA_CRESCITA))
		_braccia.append(m)
		_radici.append(radice)
		_punte.append(_ultima_punta)

	# I TENTACOLI CHE SE LO MANGIANO, al posto della pelle che ci saliva sopra. Spuntano da
	# un anello attorno all'occhio, SOTTO le braccia grandi, e crescono verso la faccia che si
	# vede uno dopo l'altro, ognuno lungo il suo cerchio massimo girato di sbieco: si
	# incrociano, e chi arriva dopo passa sopra a chi c'era già. Alla fine del pianeta non
	# resta niente di scoperto.
	var ordine := RandomNumberGenerator.new()
	ordine.seed = SEME + 1
	var passo_nascite := (MANGIA - CRESCE_MAX) / float(TENTACOLI - 1)
	for i in TENTACOLI:
		var az := ordine.randf_range(0.0, TAU)
		var phi := deg_to_rad(ordine.randf_range(RADICE_DA, RADICE_A))
		var radice := Vector3(sin(phi) * cos(az), sin(phi) * sin(az), -cos(phi))
		var avanti := _verso_il_fronte(radice)
		if avanti == Vector3.ZERO:
			continue
		avanti = avanti.rotated(radice, ordine.randf_range(-SBIECO, SBIECO))
		# chi si ferma prima di metà faccia, chi la passa un poco
		var arco := (PI - phi) + ordine.randf_range(-0.6, 0.4)
		var largo := ordine.randf_range(SOTTILE_MIN, SOTTILE_MAX)
		var punta := PUNTA_LUNGA * largo
		# L'ALTEZZA È L'ORDINE D'ARRIVO: il primo sta sulla buccia, l'ultimo sopra tutti. Due
		# tentacoli alla stessa quota, dove si incrociano, si compenetrano e sfarfallano
		var quota := STRATI * float(i) / float(TENTACOLI - 1)
		var svolta := ordine.randf_range(-PIEGA, PIEGA)
		var onda := ordine.randf_range(ONDA_MIN, ONDA_MAX)
		var numero := TAU / ordine.randf_range(ONDA_LUNGA_MIN, ONDA_LUNGA_MAX)
		var fase := ordine.randf_range(0.0, TAU)
		var piega := func(strada: float) -> float:
			return svolta + onda * cos(numero * strada + fase)
		var m := _pezzo("Tentacolo%d" % i,
			_mesh_braccio(radice, avanti, arco, largo, punta, PUNTA_GIRO / punta, quota, piega,
				TIRATA))
		# finché non comincia a crescere non c'è
		m.set_instance_shader_parameter("cresce", 0.0)
		m.visible = false
		_tentacoli.append(m)
		_nascite.append(passo_nascite * float(i) + ordine.randf_range(0.0, passo_nascite))
		_durate.append(ordine.randf_range(CRESCE_MIN, CRESCE_MAX))
		_linee.append(_ultima_linea)
		_spessori.append(_ultime_grossezze)
		_radici.append(radice)

	# L'OCCHIO IN MEZZO ALLA CORONA, da cui partono le braccia. È quello del cielo, con la sua
	# iride e la sua pupilla, e NON è figlio del sistema: si scrive il suo posto a ogni passo,
	# perché il sistema è scalato e lui la sua scala ce l'ha già.
	var scena := load(OCCHIO_SCENA) as PackedScene
	if scena != null:
		_occhio = scena.instantiate() as Occhio
		_occhio.name = "OcchioDellaCosa"
		_occhio.raggio = OCCHIO_RAGGIO * RAGGIO
		_occhio.strato = STRATO
		add_child(_occhio)
		# il tempo glielo passiamo noi, come a tutto il resto della visione
		_occhio.set_process(false)
		# VIA LA SUA PELLE: l'occhio del cielo si porta dietro una macchia di pelle larga
		# quattro volte e mezzo il bulbo, che lassù è la testa che non si vede dove finisce.
		# Qui la testa è il mucchio dei tentacoli: la macchia ci si appoggiava sopra come una
		# frittella retinata, più chiara di tutto il resto. Restano bulbo e palpebre.
		var sua_pelle := _occhio.find_child("Pelle", true, false) as GeometryInstance3D
		if sua_pelle != null:
			sua_pelle.visible = false


## La tangente in `radice` lungo il cerchio massimo che passa per il fronte (+Z), o zero se
## la radice sta proprio sul polo.
func _verso_il_fronte(radice: Vector3) -> Vector3:
	var avanti := Vector3.BACK - radice * radice.dot(Vector3.BACK)
	if avanti.length_squared() < 1e-6:
		return Vector3.ZERO
	return avanti.normalized()


func _pezzo(nome: String, mesh: ArrayMesh) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nome
	m.mesh = mesh
	m.material_override = _mat_braccio
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.layers = STRATO
	_sistema.add_child(m)
	return m


func _sfera(raggio: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = raggio
	s.height = raggio * 2.0
	s.radial_segments = 96
	s.rings = 48
	return s


## IL BRACCIO: la linea di mezzo sta sul globo per il primo pezzo e poi si arrotola.
##
## `radice` è dove spunta (una direzione dal centro del globo), `avanti` la tangente che dice
## da che parte gira, `arco` quanti radianti di globo abbraccia, `punta` quanto è lunga la
## punta arrotolata e `crescita` quanto in fretta le cresce la curvatura, `quota` quanto sta
## sollevato sulla buccia oltre la sua grossezza, `piega` di quanto svolta di lato mentre va:
## dati i radianti di strada fatti, i radianti di svolta per radiante di strada (senza, va
## dritto lungo un cerchio massimo),
## `tirata` quanto presto si assottiglia (vedi `_grossezza`).
func _mesh_braccio(radice: Vector3, avanti: Vector3, arco: float, largo: float,
		punta: float, crescita: float, quota := 0.0, piega := Callable(),
		tirata := 0.85) -> ArrayMesh:
	var linea: Array[Vector3] = []
	var grossezze: Array[float] = []
	var passi_globo := maxi(34, ceili(arco / 0.05))
	var passi_punta := 22
	var lungo := arco + punta

	# IL PEZZO AVVOLTO. Sta PREMUTO sulla superficie — il centro della sezione sta fuori di
	# otto decimi della sua grossezza, cioè il tentacolo affonda un po' nelle nuvole —
	# tranne alla radice, dove sprofonda del tutto: un braccio che cominciasse esattamente
	# sulla buccia mostrerebbe il taglio quando il globo si gira. Appoggiato e basta, sul
	# bordo del globo si vedeva il cielo sotto i tentacoli, e sembravano fili tesi.
	# Si cammina sulla sfera un passo alla volta: `su_globo` è dove si è, `verso` da che parte
	# si va, e a ogni passo il verso svolta di lato quanto dice `piega` — un tentacolo che si
	# avvolge attorno a una cosa non va dritto, la gira. I passi sono corti abbastanza da
	# seguire le onde: un'onda sta in una decina di passi o più.
	var su_globo := radice.normalized()
	var verso := avanti.normalized()
	var passo := arco / float(passi_globo)
	for i in passi_globo + 1:
		var s := float(i) / float(passi_globo)
		var g := _grossezza(s * arco / lungo, largo, tirata)
		var fuori := 1.0 + g * 0.80 + quota - 0.12 * exp(-s * arco * 9.0)
		linea.append(su_globo * fuori)
		grossezze.append(g)
		var dopo := (su_globo * cos(passo) + verso * sin(passo)).normalized()
		var svolta: float = piega.call(s * arco) if piega.is_valid() else 0.0
		verso = (verso * cos(passo) - su_globo * sin(passo)).rotated(dopo, svolta * passo).normalized()
		su_globo = dopo

	# LA PUNTA. Si stacca in tangente e si arriccia nello stesso verso in cui stava girando,
	# con la curvatura che parte da quella del globo e cresce in progressione geometrica: una
	# spirale logaritmica, attaccata senza spigolo al pezzo avvolto.
	var fine := linea[-1].normalized()
	var piano := fine.cross((linea[-1] - linea[-2]).normalized()).normalized()
	var dir := (linea[-1] - linea[-2]).normalized()
	var p := linea[-1]
	var k := PUNTA_CURVA
	var ds := punta / float(passi_punta)
	for i in passi_punta:
		p += dir * ds
		dir = dir.rotated(piano, k * ds)
		k *= exp(crescita * ds)
		linea.append(p)
		grossezze.append(_grossezza((arco + float(i + 1) * ds) / lungo, largo, tirata))
	# l'ultimo anello si chiude quasi in un punto: la punta di un braccio finisce, non è un
	# tubo tagliato
	grossezze[-1] = grossezze[-1] * 0.15

	_ultima_punta = linea[-1]
	_ultima_linea = PackedVector3Array(linea)
	_ultime_grossezze = PackedFloat32Array(grossezze)
	return _tubo(linea, grossezze, largo)


## Quanto è grossa la sezione a `u` (zero alla radice, uno in punta), in raggi del pianeta. Un
## braccio di polpo è un cono con la punta tirata: quasi dritto per metà, poi si assottiglia
## in fretta. Più `tirata` è piccola, più resta grosso fin quasi in punta.
func _grossezza(u: float, largo: float, tirata := 0.85) -> float:
	return largo * (0.04 + 0.96 * pow(1.0 - clampf(u, 0.0, 1.0), tirata))


## IL TUBO attorno alla linea di mezzo, con la sezione ovale: un braccio di polpo non ha la
## sezione tonda, è schiacciato nel verso in cui preme.
##
## Il riferimento si TRASPORTA da un anello all'altro con la rotazione minima che porta la
## vecchia tangente sulla nuova. Riprenderlo ogni volta da una direzione fissa — il radiale
## del globo, per dire — lo farebbe girare su se stesso dove la linea si arrotola, e la pelle
## si torcerebbe attorno alla punta.
## `largo` serve solo per la pelle: dice quanto è lungo il giro del braccio alla radice, e
## quindi quante piastrelle ci stanno attorno.
##
## OGNI VERTICE SA DOVE STA LUNGO IL BRACCIO, per crescere: in `CUSTOM0` porta il punto della
## linea di mezzo a cui appartiene e, nella quarta componente, quanta parte del braccio sta
## prima di lui (da zero alla radice a uno in punta). Lo shader schiaccia sulla linea di mezzo
## tutto quello che sta oltre la parte cresciuta, e il braccio si allunga senza che nessuno
## debba ricostruirlo a ogni fotogramma.
func _tubo(linea: Array[Vector3], grossezze: Array[float], largo: float) -> ArrayMesh:
	var lati := 12
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	var ultimo := linea.size() - 1
	var totale := 0.0
	for i in range(1, linea.size()):
		totale += linea[i].distance_to(linea[i - 1])
	var tangente := (linea[1] - linea[0]).normalized()
	# si parte col "sopra" sul radiale del globo: alla radice è la faccia che guarda fuori
	var su := linea[0].normalized()
	su = (su - tangente * su.dot(tangente)).normalized()
	# LA PELLE SI MISURA IN METRI, non in giri di UV: le piastrelle esagonali devono venire
	# della stessa taglia su un braccio lungo e su uno corto, e quadrate — quindi per il lungo
	# si conta la lunghezza percorsa e attorno il giro alla radice.
	var per_metro := RAGGIO / PIASTRELLA
	var attorno := TAU * largo * per_metro
	var percorso := 0.0
	for i in linea.size():
		if i > 0:
			percorso += linea[i].distance_to(linea[i - 1])
		var t_i := (linea[mini(i + 1, ultimo)] - linea[maxi(i - 1, 0)]).normalized()
		su = (Quaternion(tangente, t_i) * su).normalized()
		su = (su - t_i * su.dot(t_i)).normalized()
		tangente = t_i
		var lato := t_i.cross(su).normalized()
		var g: float = grossezze[i]
		for j in lati + 1:
			var a := TAU * float(j) / float(lati)
			var c := cos(a)
			var s := sin(a)
			st.set_uv(Vector2(percorso * per_metro, float(j) / float(lati) * attorno))
			st.set_custom(0, Color(linea[i].x, linea[i].y, linea[i].z, percorso / totale))
			# la normale di un'ellisse non è il raggio: le due componenti si dividono per i
			# rispettivi semiassi
			st.set_normal((lato * c + su * (s / SEZIONE)).normalized())
			st.add_vertex(linea[i] + (lato * c + su * s * SEZIONE) * g)
	for i in ultimo:
		for j in lati:
			var a := i * (lati + 1) + j
			var b := a + lati + 1
			# l'ordine è quello: Godot tiene le facce girate in senso orario, e con le due
			# terne scambiate del tubo si disegnava solo la parete DI SOTTO — cioè quella
			# appoggiata al globo, che il globo copre.
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(b)
			st.add_index(a + 1)
			st.add_index(b + 1)
			st.add_index(b)
	# le tangenti servono alla mappa del rilievo: senza, la pelle resta liscia
	st.generate_tangents()
	return st.commit()


# --- come si muove ----------------------------------------------------------------------

func _colloca() -> void:
	if _cam_visione == null or not _cam_visione.is_inside_tree():
		return
	var b := _cam_visione.global_basis.orthonormalized()
	var dove := _cam_visione.global_position - b.z * (distanza() * RAGGIO)
	# IL GIRO LENTO E LA VOLTATA sono due rotazioni diverse: il giro è suo e continua sempre;
	# la voltata è quella con cui si mette di fronte a te, ed è mezzo giro attorno alla
	# verticale di chi guarda.
	# ALLONTANANDOSI SCIVOLA ANCHE DI LATO: una cosa che rimpicciolisce e basta potrebbe
	# essere una cosa che si sgonfia; se intanto scorre, sei tu che stai andando indietro.
	dove += b.x * ((distanza() - LONTANO) * 0.10 * RAGGIO)
	var suo := Basis(ASSE.normalized(), _giro)
	var verso_te := Basis(Vector3.UP, PI * voltata())
	_sistema.global_transform = Transform3D(
		b * verso_te * suo * Basis().scaled(Vector3.ONE * RAGGIO), dove)
	var sole := (b * SOLE).normalized()
	_mat_globo.set_shader_parameter("sole", sole)
	_luce.global_transform = Transform3D(Basis.looking_at(-sole, b.y), dove)
	if _occhio != null:
		# la corona sta al polo di dietro del sistema, e l'occhio guarda in fuori da lì
		var corona := (-_sistema.global_basis.z).normalized()
		_occhio.alto = b.y
		_occhio.global_transform = Transform3D(Basis.looking_at(corona, b.y),
			_sistema.global_position + corona * (OCCHIO_DOVE * RAGGIO))


func _disegna() -> void:
	_mat_globo.set_shader_parameter("tempo", _t)
	_mat_globo.set_shader_parameter("copre", copre())
	_mat_globo.set_shader_parameter("sepolto", SEPOLTO)
	_mat_globo.set_shader_parameter("sfuma", SFUMA)
	# CHI STA SOTTO SI SCURISCE man mano che gli altri gli passano sopra: è l'ombra del
	# mucchio, ed è quello che fa leggere gli strati. Si conta dall'ultimo al primo, così la
	# somma di quelli arrivati dopo è già pronta.
	var sopra := 0.0
	for i in range(_tentacoli.size() - 1, -1, -1):
		var c := cresce(i)
		var m := _tentacoli[i]
		m.visible = c > 0.0
		m.set_instance_shader_parameter("cresce", c)
		m.set_instance_shader_parameter("ombra", 1.0 - OMBRA * sopra / float(TENTACOLI - 1))
		sopra += c


func _texture(via: String) -> Texture2D:
	if not ResourceLoader.exists(via):
		push_warning("pianeta: manca %s — vedi assets/LEGGIMI.txt" % via)
		return null
	return load(via) as Texture2D


# --- il racconto, in numeri --------------------------------------------------------------

## Quanto è nero lo schermo adesso, da zero a uno.
##
## SI CHIUDE E SI RIAPRE DUE VOLTE: la prima è il nero in cui si cambia posto, la seconda è la
## fine, e cade mentre si è già lontani — gli occhi si richiudono da soli su una cosa che è
## ormai un punto fra le stelle.
func velo() -> float:
	if _t < SPEGNE:
		return smoothstep(0.0, 1.0, _t / SPEGNE)
	if _t < T_ACCENDE:
		return 1.0
	if _t < T_GUARDA:
		return 1.0 - smoothstep(0.0, 1.0, (_t - T_ACCENDE) / ACCENDE)
	if _t < T_BUIO:
		# resta limpido fino a quasi in fondo, e si chiude mentre quella cosa diventa un punto
		return smoothstep(0.78, 1.0, (_t - T_VIA) / VIA)
	if _t < T_TORNA:
		return 1.0
	return 1.0 - smoothstep(0.0, 1.0, (_t - T_TORNA) / TORNA)


## A che distanza sta, in raggi del pianeta.
##
## NON CI SI AVVICINA MAI, e alla fine ci si allontana ACCELERANDO: piano all'inizio e sempre
## più svelto, che è come si viene tirati via da qualcosa. Avvicinarsi era l'errore della
## stesura di prima — da vicino una cosa grande come un pianeta diventa un asteroide.
func distanza() -> float:
	if _t < T_VIA:
		return LONTANO
	var u := clampf((_t - T_VIA) / VIA, 0.0, 1.0)
	return lerpf(LONTANO, LONTANISSIMO, u * u)


## Il raggio apparente del pianeta, in gradi.
func raggio_apparente() -> float:
	var d := distanza()
	return rad_to_deg(asin(1.0 / d)) if d > 1.0 else 90.0


## Quanto è cresciuto il tentacolo `i`, da zero (non c'è ancora) a uno (tutto).
##
## CRESCE IN FRETTA ALL'INIZIO E PIANO ALLA FINE: il primo pezzo sta dietro il globo e non lo
## vede nessuno, e a velocità costante mezzo tentacolo passerebbe senza che succeda niente.
func cresce(i: int) -> float:
	var u := clampf((_t - T_MANGIA - _nascite[i]) / _durate[i], 0.0, 1.0)
	return 1.0 - (1.0 - u) * (1.0 - u)


## Fin dove è sepolto il pianeta, in radianti dal polo di dietro: là sotto la sua luce si
## spegne, e fra un tentacolo e l'altro invece delle nuvole c'è buio. Oltre pi greco più la
## sfumatura, non ne resta niente di acceso.
##
## NON VA A VELOCITÀ COSTANTE, per la stessa ragione dei tentacoli: il primo tratto sta dietro
## il bordo del globo (`ORLO_VISTO`), e ci arriva in tre decimi del tempo.
func copre() -> float:
	if _t < T_MANGIA:
		return 0.0
	var u := clampf((_t - T_MANGIA) / MANGIA, 0.0, 1.0)
	if u < 0.30:
		return ORLO_VISTO * smoothstep(0.0, 1.0, u / 0.30)
	return lerpf(ORLO_VISTO, PI + SFUMA, smoothstep(0.0, 1.0, (u - 0.30) / 0.70))


## Quanto si è voltata verso di te, da zero a uno (mezzo giro).
func voltata() -> float:
	if _t < T_VOLTA:
		return 0.0
	return smoothstep(0.0, 1.0, clampf((_t - T_VOLTA) / VOLTA, 0.0, 1.0))


## L'occhio in mezzo alla corona, o null.
func occhio() -> Occhio:
	return _occhio


## La luce della visione.
func luce() -> DirectionalLight3D:
	return _luce


## Da quanti secondi va avanti.
func da_quando() -> float:
	return _t


# --- quello che le sonde guardano --------------------------------------------------------

func camera() -> Camera3D:
	return _cam_visione


## La camera che c'era prima, e che si riprende il posto alla fine.
func camera_prima() -> Camera3D:
	return _camera_prima


func sistema() -> Node3D:
	return _sistema


func globo() -> MeshInstance3D:
	return _globo


func braccia() -> Array[MeshInstance3D]:
	return _braccia


## I tentacoli che se lo mangiano, in ordine d'arrivo.
func tentacoli() -> Array[MeshInstance3D]:
	return _tentacoli


## Quando comincia a crescere il tentacolo `i`, in secondi dall'inizio della mangiata.
func nascita(i: int) -> float:
	return _nascite[i]


## La linea di mezzo del tentacolo `i` e le sue grossezze, nel riferimento del globo.
func linea(i: int) -> PackedVector3Array:
	return _linee[i]


func grossezze(i: int) -> PackedFloat32Array:
	return _spessori[i]


## Le radici delle braccia e dei tentacoli, nel mondo: direzioni dal centro del globo.
func radici() -> Array[Vector3]:
	return _versi(_radici)


## Le punte delle braccia, nel mondo: direzioni dal centro del globo.
func punte() -> Array[Vector3]:
	return _versi(_punte)


func _versi(locali: Array[Vector3]) -> Array[Vector3]:
	var fuori: Array[Vector3] = []
	if _sistema == null:
		return fuori
	var b := _sistema.global_basis.orthonormalized()
	for v in locali:
		fuori.append((b * v).normalized())
	return fuori
