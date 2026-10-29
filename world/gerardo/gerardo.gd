## GERARDO, il capo dei soci del DLF (D-287): la prima notte ti aspetta al cancello, ti
## fa fare il giro dell'osservatorio e se ne va in macchina giù per la sterrata.
##
## È L'UNICA PERSONA DEL GIOCO, e il GDD la ammette a una condizione: che se ne vada. Il
## protagonista resta solo; lo diventa dieci minuti dopo. Per questo qui non c'è niente
## che sopravviva al giro — nessuno stato salvato, nessun ritorno — e la prima notte la
## riconosce `main.gd` dalle notti già fatte.
##
## È UNO SPRITE, ALLA MANIERA DI DOOM. Un modello vero renderizzato da otto angolazioni
## (`tools/gerardo_blender.py`), e qui una figura piatta che si gira sempre verso la
## camera e sceglie la riga dell'atlante dall'angolo fra il suo sguardo e chi guarda. Le
## colonne sono la posa: ferma, quattro passi, due di parola.
##
## PERCHÉ UN `Interactable` E NON UN `CharacterBody3D`. Gli serve `E` — guardarlo fa
## passare alla battuta dopo — e il contratto di `interactable.gd` esiste perché ci sia un
## modo solo di premerla. Del corpo che scivola non ha bisogno: cammina su un percorso
## scritto e collaudato (`tests/` lo ha fatto scorrere con una capsula, D-287), e la quota
## la legge dal pavimento sotto i piedi. Il giocatore lo urta come urta un mobile.
##
## IL GIRO È UNA COROUTINE, e si legge dall'alto in basso come lo si racconterebbe:
## cammina, aspetta, parla, e alla fine sale in macchina. Una macchina a stati avrebbe
## spezzato in sei rami una cosa che succede in un ordine solo.
class_name Gerardo
extends Interactable

## L'auto è sparita giù per la sterrata: da adesso il turno è tuo. Signal diretto, perché
## chi ascolta è uno e si sa chi è — `main.gd`, che fa cominciare la notte.
signal andato_via

## Comincia la tappa `indice` del giro: si incammina verso di lei. La prima è quella in
## cui ti aspetta; alla seconda ve ne andate dallo slargo, e `main.gd` spegne i fari della
## tua auto, che fin lì lo illuminavano.
signal tappa_cominciata(indice: int)

## Va piano: ha settant'anni e il bastone. Il giocatore cammina a 2,5.
const VELOCITA := 1.05

## Quanta strada fa a ogni fotogramma della camminata. Quattro fotogrammi sono un passo
## per gamba: con questa misura il piede non scivola sul prato.
const PASSO := 0.30

## Quanto in fretta si gira, in radianti al secondo. Un vecchio non ruota sul posto.
const GIRO_TESTA := 4.0

## A che distanza comincia a parlare, quando aspetta il giocatore a una tappa.
const VICINO := 3.5

## Mentre cammina: oltre questa distanza si ferma ad aspettare, e riparte quando torni
## sotto `RIPARTE`. Due soglie e non una, o sul confine partirebbe e si fermerebbe a ogni
## passo.
const LONTANO := 7.0
const RIPARTE := 4.5

## Oltre questa distanza le battute si fermano: non parla a chi non lo sente.
const ASCOLTO := 9.0

## Quanto resta a schermo una battuta: un tanto a lettera, mai meno del minimo. Diciassette
## lettere al secondo è una lettura tranquilla di un sottotitolo.
const TEMPO_PER_LETTERA := 0.06
const TEMPO_MINIMO := 2.8
const PAUSA_FRA_BATTUTE := 0.35

## Quanto lascia passare prima della prima parola: il tempo di accorgersi che c'è.
const PRIMA_PAROLA := 1.2

## Ogni quanto muove la bocca mentre parla.
const TEMPO_BOCCA := 0.2


## Cosa sta aspettando dal giocatore, se aspetta qualcosa (D-289).
enum Attesa { NIENTE, NOME, SCELTA }

## Quanto aspetta dopo aver abbassato la maniglia, prima di passare: il tempo dell'anta
## (`Door.durata`) e un attimo.
const ATTESA_PORTA := 0.8

## Quanto un tratto deve passare vicino al centro di un vano perché la porta sia sulla sua
## strada: mezzo vano e un po'.
const SULLA_PORTA := 0.6

## LA SUA SAGOMA, per non passare dentro a niente: il raggio della capsula di
## `gerardo.tscn`, e lo stacco da terra della capsula con cui guarda davanti.
const RAGGIO := 0.28
const STACCO := 0.3

## Quanto arretra al massimo per lasciar girare un'anta che si apre verso di lui.
const INDIETRO_MAX := 1.2

## Quanto aspetta, bloccato da chi gli sta davanti, prima di chiedergli di spostarsi; e
## dopo quanto glielo richiede, se quello non si sposta (D-291).
const PAZIENZA := 1.2
const RICHIEDE := 12.0

## La cupola che ti ha chiesto di aprire è aperta quando il battente è a fine corsa: la
## stessa soglia di `PhaseDome.FULLY_OPEN`. Se dopo `SOLLECITO` secondi non l'hai ancora
## aperta, te lo ricorda (D-293).
const APERTA := 0.999
const SOLLECITO := 20.0

## La placca delle luci rosse della cupola, per come la chiama il suo prompt.
const LUCE_ROSSA := "la luce rossa"

## L'ATLANTE: otto righe di direzione, sette colonne di posa. Riga 0 è la faccia, e le
## altre girano di 45° in senso antiorario visto dall'alto — lo stesso verso in cui
## `tools/gerardo_blender.py` fa girare la camera.
const DIREZIONI := 8
const POSE := 7
const POSA_FERMA := 0
const POSA_PASSO := 1
const PASSI := 4
const POSA_PAROLA := 5
const PAROLE := 2

@export var giro: GiroGerardo

@onready var _figura: Sprite3D = %Figura
@onready var _sottotitoli: CanvasLayer = %Sottotitoli
@onready var _riquadro: PanelContainer = %Riquadro
@onready var _chi: Label = %Chi
@onready var _riga: Label = %Riga
@onready var _scelte: Label = %Scelte

## Dove guarda, come vettore in pianta. Lo sprite non ruota: è da questo che sceglie la
## riga dell'atlante.
var _sguardo := Vector2(0.0, 1.0)
var _posa := POSA_FERMA
var _strada_fatta := 0.0
var _parlando := false
var _avanti := false
## Se si è fermato ad aspettare chi è rimasto indietro (`_resta_indietro`).
var _fermo := false
var _auto: AutoDiGerardo
var _porte: Array[Door] = []
var _capsula := CapsuleShape3D.new()
## Le porte che il giocatore ha chiuso, finché Gerardo non le riapre (D-291).
var _chiuse_da_te := {}
## Da quanto il giocatore gli blocca la strada, e se gliel'ha già detto.
var _bloccato := 0.0
var _detto := false
var _attesa := Attesa.NIENTE
var _nome := ""
var _scelta := 0
var _quante_scelte := 1


func _ready() -> void:
	prompt_text = "Avanti"
	enabled = false
	interacted.connect(func(_by: Node3D) -> void: _avanti = true)
	_sottotitoli.visible = false
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	for etichetta in [_chi, _riga, _scelte]:
		(etichetta as Label).add_theme_font_override("font", font)
	_scelte.visible = false
	_capsula.radius = RAGGIO
	_capsula.height = 1.75 - STACCO


## Comincia il giro. `auto` è la sua macchina, già parcheggiata: ci sale alla fine.
func comincia(auto: AutoDiGerardo) -> void:
	_auto = auto
	_porte.clear()
	_raccogli_porte(get_tree().root, _porte)
	# CHI CHIUDE UNA PORTA SI SA: il segnale arriva dopo che la porta ha cambiato stato
	# (la sua connessione e' la prima), quindi «chiusa adesso» vuol dire «l'ha chiusa lui»
	for porta in _porte:
		porta.interacted.connect(_su_porta.bind(porta))
	# LA PRIMA POSA CERCA IL TERRENO DALL'ALTO. Il nodo nasce a quota zero, e lo slargo
	# sta due metri sopra il pavimento: un raggio da un metro e mezzo partirebbe sotto terra,
	# e lo seppellirebbe fino al collo (visto nel primo scatto).
	global_position = Vector3(giro.partenza.x, 30.0, giro.partenza.y)
	global_position = _a_terra(giro.partenza)
	# ti guarda arrivare: ha sentito la macchina sulla ghiaia
	var verso := _verso_giocatore()
	if verso.length_squared() > 1e-6:
		_sguardo = verso.normalized()
	_giro_intero()


func _giro_intero() -> void:
	await get_tree().create_timer(PRIMA_PAROLA, false).timeout
	for i in giro.tappe.size():
		var tappa := giro.tappe[i]
		Log.info("gerardo", "tappa «%s»" % tappa.nome)
		tappa_cominciata.emit(i)
		await _cammina(tappa.percorso, tappa.aspetta)
		if tappa.aspetta:
			await _aspetta_giocatore()
		await _parla(tappa.battute)
	await _sali_in_auto()


# --- camminare ---------------------------------------------------------------

func _cammina(punti: PackedVector2Array, aspetta: bool) -> void:
	for meta in punti:
		await _apri_se_serve(meta)
		while true:
			await get_tree().physics_frame
			var delta := get_physics_process_delta_time()
			if aspetta and _resta_indietro():
				_posa = POSA_FERMA
				continue
			var qui := Vector2(global_position.x, global_position.z)
			var manca := meta - qui
			var passo := VELOCITA * delta
			_gira_verso(manca, delta)
			var arrivato := manca.length() <= passo
			var dopo := meta if arrivato else qui + manca.normalized() * passo
			# NON SI PASSA DENTRO A NIENTE. Il percorso e' collaudato contro i muri, ma le porte
			# e il giocatore si muovono: una porta chiusa dopo che e' passato, un'anta fermata a
			# meta' da chi ci sta davanti, tu in mezzo al corridoio. Prima del passo si guarda.
			var ostacolo := _ostacolo(dopo, manca.normalized())
			if ostacolo is Door and not (ostacolo as Door).is_open():
				await _apri(ostacolo as Door, manca.normalized())
				continue
			# CHI GLI STA DAVANTI SE LO SENTE DIRE, dopo un attimo di pazienza, e di nuovo se
			# non si sposta (D-291)
			if ostacolo is Player:
				_bloccato += delta
				if _bloccato >= PAZIENZA and not _detto:
					_detto = true
					await _esclama(giro.se_lo_blocchi)
				elif _bloccato >= RICHIEDE:
					_bloccato = 0.0
					_detto = false
			if ostacolo != null:
				_posa = POSA_FERMA
				continue
			_bloccato = 0.0
			_detto = false
			global_position = _a_terra(dopo)
			if arrivato:
				break
			_strada_fatta += passo
			_posa = POSA_PASSO + int(_strada_fatta / PASSO) % PASSI
	_posa = POSA_FERMA


## Cosa gli impedisce il prossimo passo: una porta non ancora aperta del tutto, o il
## giocatore. `null` se la strada e' libera. I muri e i mobili no: il percorso li evita gia',
## e fermarsi contro uno spigolo sfiorato vorrebbe dire restare li' per sempre.
##
## Una capsula grande quanto lui, staccata da terra di trenta centimetri (il pavimento, le
## soglie e la ghiaia in salita non contano), messa dove sara' dopo il passo e un dito oltre.
func _ostacolo(dove: Vector2, verso: Vector2) -> Node:
	var domanda := PhysicsShapeQueryParameters3D.new()
	domanda.shape = _capsula
	domanda.collision_mask = LAYER_WORLD | LAYER_PLAYER
	domanda.exclude = [get_rid()]
	var avanti := dove + verso * 0.1
	domanda.transform = Transform3D(Basis(), Vector3(avanti.x,
			global_position.y + STACCO + _capsula.height / 2.0, avanti.y))
	for colpo in get_world_3d().direct_space_state.intersect_shape(domanda, 8):
		var cosa: Object = colpo["collider"]
		if cosa is Door and not (cosa as Door).del_tutto_aperta():
			return cosa as Door
		if cosa is Player:
			return cosa as Player
	return null


## Se fra dove sta e la meta c'è una porta chiusa, la apre prima di partire. Il percorso
## mette il punto di partenza fuori dal giro dell'anta; se non lo e', ci pensa `_apri()`.
func _apri_se_serve(meta: Vector2) -> void:
	var qui := Vector2(global_position.x, global_position.z)
	for porta in _porte:
		if porta.is_open() or not porta.can_interact():
			continue
		var c := porta.centro_vano()
		var vano := Vector2(c.x, c.z)
		if Geometry2D.get_closest_point_to_segment(vano, qui, meta).distance_to(vano) > SULLA_PORTA:
			continue
		await _apri(porta, (meta - qui).normalized())


## Apre una porta e aspetta che l'anta sia in fondo.
##
## SE L'ANTA GLI GIREREBBE ADDOSSO, PRIMA FA UN PASSO INDIETRO: e' il gesto di chiunque apra
## una porta che si apre verso di se'. «Addosso» vuol dire dalla parte in cui l'anta gira e
## a meno di un'anta (piu' lui) dal cardine.
func _apri(porta: Door, verso: Vector2) -> void:
	# SE L'HAI CHIUSA TU, prima te lo fa notare (D-291)
	if _chiuse_da_te.has(porta):
		_chiuse_da_te.erase(porta)
		await _esclama(giro.se_chiudi_la_porta)
	var cardine := Vector2(porta.global_position.x, porta.global_position.z)
	var lato3 := porta.lato_apertura()
	var lato := Vector2(lato3.x, lato3.z)
	var giro_anta := porta.lunghezza_anta() + RAGGIO + 0.05
	var indietro := 0.0
	while indietro < INDIETRO_MAX:
		var qui := Vector2(global_position.x, global_position.z)
		var rel := qui - cardine
		if rel.length() >= giro_anta or rel.dot(lato) < -RAGGIO:
			break
		await get_tree().physics_frame
		var passo := VELOCITA * 0.7 * get_physics_process_delta_time()
		global_position = _a_terra(qui - verso * passo)
		indietro += passo
		_strada_fatta += passo
		_posa = POSA_PASSO + PASSI - 1 - int(_strada_fatta / PASSO) % PASSI
	_posa = POSA_FERMA
	var c := porta.centro_vano()
	var vano := Vector2(c.x, c.z)
	# si gira verso la maniglia prima di abbassarla
	while absf(_sguardo.angle_to(vano - Vector2(global_position.x, global_position.z))) > 0.1:
		await get_tree().physics_frame
		_gira_verso(vano - Vector2(global_position.x, global_position.z), get_physics_process_delta_time())
	if not porta.is_open():
		porta.interact(self)
	await get_tree().create_timer(ATTESA_PORTA, false).timeout
	# e se l'anta si e' fermata contro qualcuno, aspetta che finisca la corsa
	var attesa := 0.0
	while not porta.del_tutto_aperta() and attesa < 3.0:
		await get_tree().physics_frame
		attesa += get_physics_process_delta_time()


## Vero se il giocatore è rimasto troppo indietro: ci si ferma a `LONTANO`, si riparte a
## `RIPARTE`.
func _resta_indietro() -> bool:
	var d := _distanza_giocatore()
	if _fermo and d < RIPARTE:
		_fermo = false
	elif not _fermo and d > LONTANO:
		_fermo = true
	return _fermo


func _aspetta_giocatore() -> void:
	while _distanza_giocatore() > VICINO:
		await get_tree().physics_frame
		_gira_verso(_verso_giocatore(), get_physics_process_delta_time())


func _gira_verso(dove: Vector2, delta: float) -> void:
	if dove.length_squared() < 1e-6:
		return
	var voluto := dove.normalized()
	var angolo := _sguardo.angle_to(voluto)
	var giro_max := GIRO_TESTA * delta
	_sguardo = _sguardo.rotated(clampf(angolo, -giro_max, giro_max)).normalized()


## La quota del pavimento sotto un punto della pianta: un raggio dall'alto, che salta se
## stesso e le porte (un'anta aperta sotto i piedi non è un pavimento). Dentro si parte da
## un metro e mezzo sopra i piedi, sotto il soffitto: dall'alto si troverebbe il tetto. Il
## raggio scende fin dove serve per la prima posa, che parte da trenta metri.
func _a_terra(p: Vector2) -> Vector3:
	var spazio := get_world_3d().direct_space_state
	var da := global_position.y + 1.5
	var domanda := PhysicsRayQueryParameters3D.create(Vector3(p.x, da, p.y), Vector3(p.x, da - 40.0, p.y))
	domanda.collision_mask = LAYER_WORLD
	var esclusi: Array[RID] = [get_rid()]
	for porta in _porte:
		esclusi.append(porta.get_rid())
	domanda.exclude = esclusi
	var colpo := spazio.intersect_ray(domanda)
	if colpo.is_empty():
		return Vector3(p.x, global_position.y, p.y)
	return colpo["position"] as Vector3


# --- parlare -----------------------------------------------------------------

func _parla(battute: Array[BattutaGiro]) -> void:
	if battute.is_empty():
		return
	_parlando = true
	for b in battute:
		var domanda := b.chiede_nome or not b.rami.is_empty()
		await _di(b.testo, domanda, b.dove if b.indica else Vector2.INF)
		if b.chiede_nome:
			await _chiedi_nome()
		elif domanda:
			# LA RISPOSTA NON SI RIPETE: la si e' appena scelta e letta nella lista (D-289,
			# Federico: «non c'e' bisogno che la fai ripetere»). Gerardo risponde subito.
			var scelto := await _scegli(b.rami)
			for testo in b.rami[scelto].battute:
				await _di(testo)
		match b.aspetta:
			BattutaGiro.Aspetta.CUPOLA_APERTA:
				await _aspetta_la_cupola()
			BattutaGiro.Aspetta.LUCE_ROSSA:
				await _aspetta_la_luce_rossa()
	_parlando = false


## «Dai, prova subito»: aspetta che il giocatore apra la cupola dalla pulsantiera, e lo
## guarda farlo. I piedi del giocatore restano liberi: deve andare al pulsante.
func _aspetta_la_cupola() -> void:
	var cupola := DomeShutter.find_in(get_tree())
	if cupola == null:
		return
	var aspettato := 0.0
	while cupola.aperture() < APERTA:
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time()
		_gira_verso(_verso_giocatore(), delta)
		aspettato += delta
		if aspettato >= SOLLECITO:
			aspettato = 0.0
			await _esclama(giro.se_non_apri)


## «Accendila un po'»: aspetta che il giocatore accenda le rosse della cupola dalla loro
## placca. La placca si riconosce da cosa accende, come la chiama il suo prompt.
func _aspetta_la_luce_rossa() -> void:
	var placca: LightSwitch = null
	for n in get_tree().root.find_children("*", "LightSwitch", true, false):
		if (n as LightSwitch).locale == LUCE_ROSSA:
			placca = n
	if placca == null:
		return
	while not placca.accesa_ora():
		await get_tree().physics_frame
		_gira_verso(_verso_giocatore(), get_physics_process_delta_time())


## Una battuta: resta a schermo un tanto a lettera, o finche' non lo si guarda e si preme
## `E`. Parla solo a chi lo sente. Il sottotitolo si spegne quando ha finito, tranne quello
## di una `domanda`, che resta mentre si risponde: lo spegne `_finisci_attesa()`.
##
## `indica`, se non e' INF, e' il punto in pianta che mostra mentre parla: ci si gira verso,
## invece di guardare chi ascolta (D-292). La mano non si alza: vedi `tools/gerardo_blender.py`.
func _di(testo: String, domanda: bool = false, indica: Vector2 = Vector2.INF) -> void:
	enabled = true
	_riga.text = "
".join(GiroGerardo.righe_battuta(testo))
	var resta := maxf(TEMPO_MINIMO, testo.length() * TEMPO_PER_LETTERA)
	var bocca := 0.0
	_avanti = false
	while resta > 0.0 and not _avanti:
		await get_tree().process_frame
		var delta := get_process_delta_time()
		var mostra := indica != Vector2.INF
		_gira_verso(indica - Vector2(global_position.x, global_position.z) if mostra
				else _verso_giocatore(), delta)
		var sente := _distanza_giocatore() <= ASCOLTO
		_sottotitoli.visible = sente
		if not sente:
			_posa = POSA_FERMA
			continue
		resta -= delta
		bocca += delta
		_posa = POSA_PAROLA + int(bocca / TEMPO_BOCCA) % PAROLE
	enabled = false
	_posa = POSA_FERMA
	if domanda:
		return
	_sottotitoli.visible = false
	await get_tree().create_timer(PAUSA_FRA_BATTUTE, false).timeout


## Una battuta fuori copione, detta solo se il giocatore e' abbastanza vicino da sentirla:
## a chi e' lontano non si grida, e una battuta che aspetta chi non torna lo fermerebbe li'.
func _esclama(testo: String) -> void:
	if testo.is_empty() or _distanza_giocatore() > ASCOLTO:
		return
	await _di(testo)


func _su_porta(by: Node3D, porta: Door) -> void:
	if by is Player and not porta.is_open():
		_chiuse_da_te[porta] = true
	elif by == self:
		_chiuse_da_te.erase(porta)


# --- rispondere --------------------------------------------------------------
# MENTRE SI RISPONDE I PIEDI SONO FERMI. W e S scelgono, le lettere scrivono il nome, lo
# spazio e' uno spazio: con il controller acceso sarebbero anche camminare e saltare.
# `set_movement_locked` toglie quelli, e la testa resta libera di guardarsi attorno. I
# tasti li prende `_input` di questo nodo, prima che arrivino al giocatore: `E` non deve
# anche usare quello che si sta guardando.

## Aspetta che il giocatore scriva il suo nome e prema INVIO. Lo tiene il profilo: e' suo,
## e attraversa le notti come il portafoglio.
func _chiedi_nome() -> void:
	_nome = ""
	_comincia_attesa(Attesa.NOME)
	while _attesa == Attesa.NOME:
		_scelte.text = "Il tuo nome:  %s_

INVIO  conferma" % _nome
		await get_tree().process_frame
		_gira_verso(_verso_giocatore(), get_process_delta_time())
	Game.profile.nome = _nome.strip_edges()
	Log.info("gerardo", "il giocatore si chiama «%s»" % Game.profile.nome)


## Aspetta che il giocatore scelga una risposta: W e S per spostarsi, E o INVIO per dirla.
## Torna l'indice del ramo scelto.
func _scegli(rami: Array[RamoGiro]) -> int:
	_scelta = 0
	_comincia_attesa(Attesa.SCELTA)
	while _attesa == Attesa.SCELTA:
		var righe := PackedStringArray()
		for k in rami.size():
			righe.append(("> " if k == _scelta else "  ") + rami[k].risposta)
		righe.append("")
		righe.append("W/S  scegli    E  rispondi" if rami.size() > 1 else "E  rispondi")
		_scelte.text = "
".join(righe)
		_quante_scelte = rami.size()
		await get_tree().process_frame
		_gira_verso(_verso_giocatore(), get_process_delta_time())
	return _scelta


func _comincia_attesa(quale: Attesa) -> void:
	_attesa = quale
	_sottotitoli.visible = true
	_scelte.visible = true
	var p := Player.find_in(get_tree())
	if p != null:
		p.set_movement_locked(true)


func _finisci_attesa() -> void:
	_attesa = Attesa.NIENTE
	_scelte.visible = false
	_sottotitoli.visible = false
	var p := Player.find_in(get_tree())
	if p != null:
		p.set_movement_locked(false)


func _input(event: InputEvent) -> void:
	if _attesa == Attesa.NIENTE or not (event is InputEventKey):
		return
	var tasto := event as InputEventKey
	get_viewport().set_input_as_handled()
	if not tasto.pressed:
		return
	var invio := tasto.keycode == KEY_ENTER or tasto.keycode == KEY_KP_ENTER
	if _attesa == Attesa.NOME:
		if invio:
			_finisci_attesa()
		elif tasto.keycode == KEY_BACKSPACE:
			_nome = _nome.left(-1)
		elif tasto.unicode >= 32 and _nome.length() < GiroGerardo.NOME_MAX:
			_nome += char(tasto.unicode)
		return
	if tasto.echo:
		return
	if invio or event.is_action(&"interact"):
		_finisci_attesa()
	elif event.is_action(&"move_forward"):
		_scelta = posmod(_scelta - 1, _quante_scelte)
	elif event.is_action(&"move_back"):
		_scelta = posmod(_scelta + 1, _quante_scelte)


# --- andarsene ---------------------------------------------------------------

## Arrivato alla portiera, sale: sparisce lui, si accendono i fari, e l'auto se ne va.
## Quando i fanali sono spariti giù per la sterrata, il turno comincia.
func _sali_in_auto() -> void:
	_gira_verso(Vector2(_auto.global_position.x, _auto.global_position.z)
			- Vector2(global_position.x, global_position.z), 1.0)
	await get_tree().create_timer(0.6, false).timeout
	visible = false
	collision_layer = 0
	await _auto.parti(giro.strada)
	Log.info("gerardo", "andato via")
	andato_via.emit()
	_auto.queue_free()
	queue_free()


# --- la figura ---------------------------------------------------------------

func _process(_delta: float) -> void:
	# IL RIQUADRO È ALTO QUANTO CIÒ CHE CONTIENE, col bordo basso fermo: cresce da solo quando
	# compaiono le risposte, ma un Control non torna mai più piccolo da sé.
	if _sottotitoli.visible:
		_riquadro.offset_top = _riquadro.offset_bottom - _riquadro.get_combined_minimum_size().y
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var verso_cam := cam.global_position - global_position
	_figura.frame = riga_atlante(_sguardo, Vector2(verso_cam.x, verso_cam.z)) * POSE + _posa


## La riga dell'atlante per chi guarda da `verso_cam`, se lui guarda verso `sguardo`.
## PURA e STATICA, per il banco.
##
## GLI ANGOLI SI CONTANO NEL PIANO MATEMATICO, x a destra e y in su, che dall'alto è
## (x, −z) di Godot: è lo stesso piano di Blender visto dall'alto, dove la camera gira, e
## così «antiorario» vuol dire la stessa cosa nei due posti. La riga 0 è la camera davanti
## alla faccia.
static func riga_atlante(sguardo: Vector2, verso_cam: Vector2) -> int:
	var f := Vector2(sguardo.x, -sguardo.y)
	var c := Vector2(verso_cam.x, -verso_cam.y)
	if c.length_squared() < 1e-6:
		return 0
	var angolo := f.angle_to(c)
	return posmod(roundi(angolo / (TAU / DIREZIONI)), DIREZIONI)


# --- il giocatore ------------------------------------------------------------

func _distanza_giocatore() -> float:
	var p := Player.find_in(get_tree())
	if p == null:
		return 0.0
	return Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()


func _verso_giocatore() -> Vector2:
	var p := Player.find_in(get_tree())
	if p == null:
		return _sguardo
	return Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z)


static func _raccogli_porte(n: Node, fuori: Array[Door]) -> void:
	if n is Door:
		fuori.append(n as Door)
	for f in n.get_children():
		_raccogli_porte(f, fuori)
