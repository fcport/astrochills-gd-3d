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
## `StaticBody3D` CHE SI MUOVE, E CHI GLI STA DAVANTI. `Interactable` estende
## `StaticBody3D`, che non spinge un `CharacterBody3D` fermo nel suo raggio:
## l'anta gli passava attraverso, e siccome per aprire una porta bisogna
## guardarla da vicino, capitava a ogni porta che si apre verso chi la apre.
##
## LA PORTA NON CAMBIA VERSO PER FARTI COMODO. Il verso è un dato fisico — i
## cardini stanno da una parte sola — e girarlo secondo dove sta il giocatore
## renderebbe l'ingresso una porta che si apre verso l'interno, che è proprio
## quello che una via di fuga non può fare. Chi apre una porta verso di sé fa un
## passo indietro: qui lo fa la porta per lui, spingendolo FUORI DAL SETTORE che
## l'anta spazza, radialmente rispetto al cardine, con `move_and_collide` perché
## un muro alle spalle lo fermi invece di farlo attraversare.
class_name Door
extends Interactable

## Quanto si spalanca. Ottanta gradi e non novanta: una porta aperta a filo di
## muro sembra smontata, e questi dieci gradi la fanno leggere come una porta.
@export var apertura_gradi: float = 80.0

## Da che parte gira: +1 o -1 rispetto alla rotazione a battente chiuso. Lo
## scrive il generatore, che lo ricava dalla normale del muro.
@export var verso: int = 1

## Quanta aria si lascia oltre la punta dell'anta scostando chi è nel giro.
## Trentaquattro centimetri: il raggio della capsula del giocatore (0,30) più
## quattro dita. Non di più — la spinta si ferma contro il muro alle spalle, e un
## margine più generoso del necessario fa fallire lo scostamento nei disimpegni
## stretti per una manciata di centimetri che l'anta non usa comunque.
const MARGINE := 0.34

## L'aria sull'angolo del settore, in radianti. Chi sta appena fuori ci finisce
## dentro con mezzo passo, e una spinta che arriva a metà rotazione si vede più
## di una spinta che parte subito.
const ARIA := 0.25

## Quanto dura il movimento. Mezzo secondo scarso: abbastanza da vedersi, non
## tanto da far aspettare chi attraversa venti volte per notte.
@export var durata: float = 0.55

## Emesso a movimento concluso, con lo stato raggiunto. Serve a chi vorrà
## appenderci un suono o una reazione senza sapere come è fatta la rotazione.
signal moved(open: bool)

var _aperta := false
var _chiusa_y := 0.0
var _tween: Tween = null

## Di quanto si apre QUESTA volta. Di norma è `apertura_gradi`, ma in un locale
## stretto chi apre non ha dove indietreggiare: il magazzino è largo 1,55 e con
## l'anta dentro restano undici centimetri di troppo. Allora la porta si apre di
## meno — che è quello che fa una persona vera in un ripostiglio.
var _apertura_utile := 0.0


func _ready() -> void:
	# La rotazione con cui la porta nasce È la posizione di battente chiuso: la
	# decide il generatore orientando il nodo lungo il muro. Leggerla invece di
	# assumere zero significa che una porta ruotata a mano nell'editor continua a
	# funzionare.
	_chiusa_y = rotation.y
	_apertura_utile = apertura_gradi
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
	if _tween != null and _tween.is_valid():
		# Chi cambia idea a metà corsa non deve accodare due rotazioni: la
		# precedente si annulla, e si riparte da dove l'anta è arrivata.
		_tween.kill()
	_aperta = open
	var bersaglio := _chiusa_y + (deg_to_rad(_apertura_utile) * signf(verso) if open else 0.0)
	if immediata:
		rotation.y = bersaglio
		moved.emit(_aperta)
		return
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, ^"rotation:y", bersaglio, durata)
	_tween.finished.connect(func() -> void: moved.emit(_aperta))


func _on_interacted(by: Node3D) -> void:
	# prima si sposta chi è nel giro, poi l'anta parte: al contrario il primo
	# fotogramma di rotazione lo troverebbe ancora lì
	_apertura_utile = _scosta(by)
	set_open(not _aperta)


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


## Toglie dai piedi chi sta dentro il settore che l'anta spazzerà.
##
## Il conto si fa nel sistema dell'anta A BATTENTE CHIUSO, non in quello corrente:
## chiudendo, il nodo è già ruotato, e il settore da liberare resta quello.
## `+X` locale è l'anta chiusa, e ruotando di `verso` positivo la punta va verso
## `-Z` locale — quindi il settore sta fra l'angolo zero e l'apertura, misurato
## in quel verso.
func _scosta(chi: Node3D) -> float:
	var corpo := chi as CharacterBody3D
	if corpo == null:
		return apertura_gradi
	var chiusa := Transform3D(Basis(Vector3.UP, _chiusa_y), global_position)
	var loc := chiusa.affine_inverse() * corpo.global_position
	var raggio := Vector2(loc.x, loc.z).length()
	var portata := _lunghezza_anta() + MARGINE
	if raggio < 0.05 or raggio > portata:
		return apertura_gradi
	# ARIA sull'angolo: chi sta appena fuori dal settore ci finisce dentro
	# facendo mezzo passo, e una spinta che arriva a metà rotazione si vede.
	var angolo := atan2(-loc.z * signf(verso), loc.x)
	if angolo < -ARIA or angolo > deg_to_rad(apertura_gradi) + ARIA:
		return apertura_gradi
	var fuori := chiusa.basis * Vector3(loc.x, 0.0, loc.z).normalized()
	corpo.move_and_collide(fuori * (portata - raggio))
	# SE IL MURO HA FERMATO LA SPINTA, SI APRE DI MENO. In un locale stretto non
	# c'è indietro dove andare, e insistere significherebbe far passare l'anta
	# dentro chi la apre. L'anta si ferma prima di arrivargli addosso: è quello
	# che si fa in un ripostiglio, e si legge come una porta che trova un
	# ostacolo, non come un difetto.
	var dopo := chiusa.affine_inverse() * corpo.global_position
	var r2 := Vector2(dopo.x, dopo.z).length()
	if r2 >= portata - 0.01:
		return apertura_gradi
	var a2 := atan2(-dopo.z * signf(verso), dopo.x)
	# il mezzo angolo occupato dal corpo visto dal cardine, così l'anta si ferma
	# a filo e non gli entra dentro
	var mezzo := asin(clampf(MARGINE / maxf(r2, 0.05), 0.0, 1.0))
	return clampf(rad_to_deg(a2 - mezzo), 0.0, apertura_gradi)
