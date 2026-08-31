## Una porta che si apre e si chiude guardandola e premendo `E`.
##
## PERCHÉ È UN `Interactable` E NON UN MECCANISMO PROPRIO. Il contratto di
## `interactable.gd` esiste per non avere due modi di premere `E`: il raggio parte
## dalla camera, distingue «la guardo» da «ci sono accanto», e il prompt lo scrive
## il giocatore in italiano. Una porta non ha nessun bisogno diverso da quelli, e
## una seconda strada per lo stesso gesto sarebbe solo un posto in più dove il
## comportamento può divergere.
##
## IL NODO STA SUL CARDINE, NON AL CENTRO DELL'ANTA. È la stessa regola dei
## portelli della cupola e delle ante nel modello Blender: un pezzo che ruota si
## descrive dal perno. Mesh e collisione sono quindi spostate di mezza anta lungo
## `+X` locale, e aprire è ruotare il nodo attorno a `Y`. Con l'origine al centro
## l'anta si staccherebbe dal telaio al primo grado di rotazione.
##
## IL VERSO È UN DATO, NON UNA CONVENZIONE. `verso` vale +1 o -1 e arriva dal
## generatore, che lo calcola dalla stessa `APERTURA_PORTE` di `geometria.py` da
## cui nascono la pianta e il modello. L'ingresso si apre verso il prato perché
## una via di fuga non si apre verso l'interno; le interne verso il locale
## servito, tranne dove il locale è troppo stretto per contenere l'anta.
##
## LA PORTA NON CAMBIA VERSO PER FARTI COMODO, MA NON TI SPARA NEMMENO INDIETRO.
## `Interactable` estende `StaticBody3D`, che non spinge un `CharacterBody3D` fermo
## nel suo raggio: l'anta gli passava attraverso, e siccome per aprire una porta
## bisogna guardarla da vicino, capitava a ogni porta che si apre verso chi la apre.
## La prima cura è stata scostarlo con un `move_and_collide` solo, al momento
## dell'interazione — e quello era un TELETRASPORTO: mezzo metro abbondante in un
## fotogramma, che non si legge come farsi da parte ma come un calcio.
##
## Adesso l'anta gira UN FOTOGRAMMA ALLA VOLTA e scosta un pochino per volta, solo
## mentre gli arriva vicino e solo di quanto serve — comincia a mezzo giro di
## distanza e finisce a contatto, così lo spostamento totale è lo stesso ma
## distribuito su mezzo secondo, e mentre lo fa l'anta rallenta. È il gesto vero: chi
## apre una porta verso di sé arretra di un passo, non viene scaraventato.
##
## E se dietro c'è un muro — il magazzino è largo 1,55 — la spinta si ferma e
## **l'anta si apre di meno**, fermandosi a filo di chi l'ha aperta. Non è una posa
## definitiva: il conto si rifà a ogni fotogramma, quindi appena ci si sposta la
## porta finisce di aprirsi da sola.
class_name Door
extends Interactable

## Quanto si spalanca. NOVANTA, ed è una misura, non un gusto: il banco prova la
## sagoma dell'anta grado per grado contro tutto il resto e la porta più stretta
## gira libera fino a 102°. Ottanta erano un margine inventato per una paura — che
## l'anta sparisse contro il muro — di cui nessuno aveva mai misurato il bisogno, e
## in gioco si leggevano come una porta che non si apre mai del tutto.
@export var apertura_gradi: float = 90.0

## Da che parte gira: +1 o -1 rispetto alla rotazione a battente chiuso. Lo
## scrive il generatore, che lo ricava dalla normale del muro.
@export var verso: int = 1

## Quanto dura il movimento a vuoto. Mezzo secondo scarso: abbastanza da vedersi,
## non tanto da far aspettare chi attraversa venti volte per notte. Scostando
## qualcuno ci mette di più, ed è giusto così.
@export var durata: float = 0.55

## Quanta aria si lascia oltre la punta dell'anta scostando chi è nel giro.
## Trentaquattro centimetri: il raggio della capsula del giocatore (0,30) più
## quattro dita. Non di più — la spinta si ferma contro il muro alle spalle, e un
## margine più generoso del necessario fa fermare l'anta prima del dovuto nei
## disimpegni stretti, per una manciata di centimetri che non usa comunque.
const MARGINE := 0.34

## Quanto in fretta l'anta può spostare chi ha davanti, in metri al secondo. È
## QUESTO il numero che distingue una spinta da uno strappo. Un uomo che cammina fa
## 1,4 m/s: l'anta ti muove come una camminata, mai più in fretta.
##
## Non è un limite sullo spostamento — quello lo impone la geometria del settore e
## resta mezzo metro — è un limite sulla VELOCITÀ, e vincola anche l'anta: finché
## sta scostando qualcuno rallenta quanto basta perché la spinta stia sotto. Una
## porta che incontra una persona non continua alla stessa andatura, e il tempo che
## ci mette in più è il tempo di accorgersi che ci si sta spostando.
const SPINTA_MASSIMA := 1.1

## Emesso a movimento concluso, con lo stato raggiunto. Serve a chi vorrà
## appenderci un suono o una reazione senza sapere come è fatta la rotazione.
signal moved(open: bool)

var _aperta := false
var _chiusa_y := 0.0

## I gradi di apertura raggiunti, sempre da 0 a `apertura_gradi`. Il verso lo
## applica `_applica()`: qui l'angolo è un numero positivo e i confronti «più
## aperta / meno aperta» restano leggibili.
var _angolo := 0.0

## Chi ha aperto, per continuare a fargli largo mentre l'anta gira. È l'unico stato
## che sopravvive all'interazione, e serve proprio perché il conto NON si fa una
## volta sola.
var _chi: CharacterBody3D = null

## A che distanza dal cardine l'anta stava scostando qualcuno l'ultimo fotogramma,
## o zero. Serve a rallentare l'anta: la stessa rotazione, a un metro dal cardine,
## sposta il doppio che a mezzo metro.
var _contatto := 0.0


func _ready() -> void:
	# La rotazione con cui la porta nasce È la posizione di battente chiuso: la
	# decide il generatore orientando il nodo lungo il muro. Leggerla invece di
	# assumere zero significa che una porta ruotata a mano nell'editor continua a
	# funzionare.
	_chiusa_y = rotation.y
	_angolo = 0.0
	set_physics_process(false)
	# `interact()` non va sovrascritta — lo dice il contratto — così un domani la
	# porta può avere più di un ascoltatore senza che nessuno chiami `super()`.
	interacted.connect(_on_interacted)


## Il prompt cambia con lo stato, e il player rilegge il testo a ogni sguardo:
## chi la guarda sa già cosa succederà premendo `E`.
func prompt() -> String:
	return "Chiudi" if _aperta else "Apri"


## Se è aperta adesso. Di sola lettura: si cambia stato solo interagendo.
func is_open() -> bool:
	return _aperta


## Porta la porta nello stato voluto. `immediata` salta l'animazione — serve a
## chi allestisce una scena già aperta senza vederla sbattere all'avvio.
func set_open(open: bool, immediata: bool = false) -> void:
	_aperta = open
	if immediata:
		_angolo = apertura_gradi if open else 0.0
		_applica()
		set_physics_process(false)
		moved.emit(_aperta)
		return
	set_physics_process(true)


func _on_interacted(by: Node3D) -> void:
	_chi = by as CharacterBody3D
	set_open(not _aperta)


func _applica() -> void:
	rotation.y = _chiusa_y + deg_to_rad(_angolo) * signf(verso)


## Un fotogramma di rotazione: si prova ad avvicinarsi alla meta, e chi è nel giro
## viene scostato di quel tanto che serve adesso.
##
## Il processo resta acceso finché l'anta non è arrivata — anche se è ferma perché
## bloccata da qualcuno. È voluto: appena quel qualcuno si sposta, la porta finisce
## la corsa da sola invece di restare mezza aperta finché non la si riapre.
func _physics_process(delta: float) -> void:
	var meta := apertura_gradi if _aperta else 0.0
	var passo := (apertura_gradi / maxf(durata, 0.05)) * delta
	if _contatto > 0.05:
		# a un metro dal cardine la stessa rotazione sposta il doppio che a mezzo:
		# il freno si calcola sul raggio a cui sta chi si sta scostando
		passo = minf(passo, rad_to_deg(SPINTA_MASSIMA * delta / _contatto))
	_angolo = _fa_largo(move_toward(_angolo, meta, passo), delta)
	_applica()
	if is_equal_approx(_angolo, meta):
		set_physics_process(false)
		moved.emit(_aperta)


## Quanto è lunga l'anta, letta dalla sua collisione invece che assunta.
## Il generatore mette la `BoxShape3D` a metà anta lungo `+X`, larga quanto il
## vano: chi cambia la larghezza di una porta in `geometria.py` non deve venire
## a cambiare anche un numero qui.
func _lunghezza_anta() -> float:
	var col := get_node_or_null(^"Col") as CollisionShape3D
	if col == null:
		return 0.9
	var box := col.shape as BoxShape3D
	return box.size.x if box != null else 0.9


## Fa largo a chi sta nel settore, e dice fino a che angolo l'anta può arrivare
## davvero in questo fotogramma.
##
## Il conto si fa nel sistema dell'anta A BATTENTE CHIUSO, non in quello corrente:
## chiudendo, il nodo è già ruotato, e il settore da liberare resta quello.
## `+X` locale è l'anta chiusa, e ruotando di `verso` positivo la punta va verso
## `-Z` locale — quindi il settore sta fra l'angolo zero e l'apertura, misurato
## in quel verso.
func _fa_largo(voluto: float, delta: float) -> float:
	_contatto = 0.0
	if not is_instance_valid(_chi):
		return voluto
	var chiusa := Transform3D(Basis(Vector3.UP, _chiusa_y), global_position)
	var loc := chiusa.affine_inverse() * _chi.global_position
	# in questo piano l'anta chiusa sta su +X e ruota verso +Y qualunque sia `verso`,
	# cosi' angoli e distanze si scrivono una volta sola
	var p := Vector2(loc.x, -loc.z * signf(verso))
	var lunga := _lunghezza_anta()
	if p.length() < 0.05 or p.length() > lunga + MARGINE:
		return voluto                      # oltre la punta dell'anta: non lo tocca

	# QUANTO DISTA DALL'ANTA, non a che angolo sta. Con l'angolo, un corpo a mezzo
	# metro dal cardine ne sottende trentotto di gradi: dietro la porta, dalla parte
	# opposta, risultava comunque "nel settore" e veniva spinto. La porta e' un
	# segmento, e cio' che conta e' la distanza dal segmento.
	var verso_anta := Vector2(cos(deg_to_rad(voluto)), sin(deg_to_rad(voluto)))
	var vicino := verso_anta * clampf(p.dot(verso_anta), 0.0, lunga)
	var distanza := p.distance_to(vicino)
	var voglio := MARGINE + 0.03
	if distanza >= voglio:
		return voluto                      # l'anta gli passa accanto senza toccarlo
	_contatto = p.length()

	# LO SCOSTA PERPENDICOLARMENTE ALL'ANTA - e' la via piu' corta per uscirle di
	# mezzo, ed e' anche come spinge una porta vera - e MAI PIU' IN FRETTA DI UNA
	# CAMMINATA. Il tetto sulla velocita' e' l'intera correzione: lo spostamento
	# totale resta quello che la geometria impone, ma smette di arrivare tutto in un
	# fotogramma. `move_and_collide` e non uno spostamento diretto, perche' un muro
	# alle spalle lo fermi invece di farlo attraversare.
	var normale := (p - vicino).normalized() if distanza > 1e-4 else Vector2(-verso_anta.y, verso_anta.x)
	var quanto := minf(voglio - distanza, SPINTA_MASSIMA * delta)
	var fuori := chiusa.basis * Vector3(normale.x, 0.0, -normale.y * signf(verso))
	var urto := _chi.move_and_collide(fuori * quanto)
	if urto != null:
		# CONTRO UN MURO NON CI SI FERMA: CI SI SCIVOLA LUNGO. Spingere solo di fianco
		# funziona in mezzo a una stanza e fallisce proprio dove serve — in corridoio,
		# dove dopo mezzo metro c'è la parete opposta e la spinta muore lì. L'anta si
		# fermava a filo, e le tre porte strette restavano socchiuse a sessanta gradi.
		# Chi apre una porta in corridoio non si appiattisce al muro: fa un passo
		# INDIETRO lungo il corridoio. Il resto della spinta gira lungo il muro e fa
		# esattamente quel passo.
		_chi.move_and_collide(urto.get_remainder().slide(urto.get_normal()))

	# SE IL MURO HA FERMATO LA SPINTA, SI APRE DI MENO. In un locale stretto non
	# c'e' indietro dove andare, e insistere significherebbe far passare l'anta
	# dentro chi la apre. L'anta si ferma a filo: si legge come una porta che trova
	# un ostacolo, non come un difetto. E siccome il conto si rifa' ogni fotogramma,
	# appena ci si sposta la porta finisce la corsa da sola.
	var dopo := chiusa.affine_inverse() * _chi.global_position
	var q := Vector2(dopo.x, -dopo.z * signf(verso))
	var r2 := q.length()
	var a2 := rad_to_deg(atan2(q.y, q.x))
	if r2 <= voglio:
		return _angolo                     # gli sta addosso al cardine: l'anta non si muove
	# l'angolo a cui l'anta gli arriva a filo: r * sin(scarto) = voglio
	var mezzo := rad_to_deg(asin(clampf(voglio / r2, 0.0, 1.0)))
	# L'anta si ferma dal lato da cui sta arrivando e non lo scavalca. E non TORNA
	# indietro: se qualcuno si infila nel vano a porta gia' aperta, la porta resta
	# dov'e' invece di richiudersegli addosso per rispettare un limite.
	if voluto > _angolo:
		return clampf(minf(voluto, a2 - mezzo), _angolo, apertura_gradi)
	return clampf(maxf(voluto, a2 + mezzo), 0.0, _angolo)
