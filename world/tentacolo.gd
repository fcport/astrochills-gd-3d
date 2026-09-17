## IL TENTACOLO che scende dal cielo davanti all'osservatorio.
##
## Questo file NON disegna niente: piega le novanta ossa che stanno dentro
## `assets/models/tentacolo.glb` (lo costruisce `tools/tentacolo_blender.py`). La
## forma è un lavoro di Blender; quello che si vede muoversi nasce qui.
##
## COME SI MUOVE UN TENTACOLO VERO, e perché non basta farlo dondolare. Un braccio
## di polpo è un idrostato muscolare: non ha ossa, non ha leve, e la sua unità di
## movimento non è la rotazione di un giunto ma un'ONDA DI CURVATURA che parte dalla
## base e corre verso la punta. È il movimento che in letteratura si chiama *bend
## propagation*, e ha tre caratteri che qui sono tre righe di codice:
##
##   1. L'ONDA VIAGGIA, non pulsa. Ogni pezzo del braccio fa quello che ha fatto il
##      pezzo sopra di lui, ma DOPO — `_ritardo` è il tempo che l'onda ci mette ad
##      arrivare fin lì. Senza ritardo tutto il braccio si piega insieme, e quello
##      che si vede è una bandiera o una frusta rigida, non una cosa viva.
##   2. L'ONDA ACCELERA SCENDENDO. Un'onda di flessione corre più veloce dove il
##      corpo è sottile, quindi negli ultimi metri il ritardo si accumula più
##      piano e la punta finisce per anticipare il resto: è il principio dello
##      schiocco della frusta, ed è il motivo per cui la punta ha una vita sua.
##   3. LE SCALE CONTANO. Una cosa alta come un palazzo che oscilla una volta al
##      secondo non sembra enorme: sembra piccola e vicina. I tre modi qui sotto
##      hanno periodi di 17, 7,3 e 3,9 secondi — lenti, e con rapporti volutamente
##      non interi, o dopo poche oscillazioni tornerebbero in fase tutti insieme e
##      il movimento diventerebbe periodico a occhio. Sono stati tarati sul pezzo
##      che si guarda, i quaranta metri sopra il prato, e allungando il braccio NON
##      si sono rallentati: quel pezzo deve muoversi come prima. La grandezza della
##      colonna intera la dice un quarto movimento, il COLOSSO, da quaranta secondi.
##
## LA PUNTA TIENE IL POSTO, e non è una comodità di collisione. L'inviluppo delle
## ampiezze è piena sopra la punta e cala negli ultimi quarantacinque metri: il corpo
## si contorce, la punta no.
## Un braccio che ARRIVA da qualche parte e ci resta è una cosa che ha deciso dove
## stare; un braccio che sbandiera dappertutto è un nastro al vento. La differenza
## si legge in mezzo secondo, e sta tutta in quella curva.
##
## NIENTE COLLISIONE, ed è dichiarato. Questa cosa attraversa il mondo: nessun
## corpo, nessuna forma, il giocatore ci cammina dentro. Serve a GUARDARE il
## movimento (è uno strumento di debug, `debug/tentacolo.gd`, tasto F5). Quando e
## se diventerà un fatto della storia, la collisione sarà una decisione di quella
## storia — e sarà una capsula per osso, non una mesh.
class_name Tentacolo
extends Node3D

## Segnalato quando è tornato su e non c'è più niente da vedere: chi l'ha calato
## lo usa per liberare il nodo invece di tenere in scena una cosa fuori dal cielo.
signal risalito

## Quanto è lungo, in metri. È RICOPIATO da `tools/tentacolo_blender.py`, perché un
## `.gd` non importa un `.py` — se cambia là, cambia qui. Sbagliarlo non rompe
## niente di vistoso: l'onda si distribuisce su una lunghezza che non è quella del
## modello, e la piega risulta più stretta o più larga di quanto la pelle pretende.
const LUNGHEZZA := 1500.0

## La corsa della discesa: da quanto più in alto arriva.
##
## MILLEOTTOCENTO METRI. La storia è quella della lunghezza: sessanta metri e la cosa
## COMINCIAVA in aria; trecento e la punta, lassù, era sotto il pixel, ma alzando la
## testa si trovava ancora da dove veniva. Adesso la punta parte oltre la distanza a
## cui la pelle si è già dissolta (`SPARISCE`): non si vede arrivare una cosa, si
## vede una cosa che PRENDE CORPO dal cielo scendendo.
##
## QUARANTADUE SECONDI. Con la `smoothstep` la punta resta invisibile per i primi
## venti — è sopra i mille metri — e gli altri ventidue sono quelli che si guardano:
## la cosa che si addensa, accelera, e rallenta fino a posarsi davanti alla porta.
const CORSA := 1800.0
const DURATA_DISCESA := 42.0
const DURATA_RISALITA := 28.0

## LA PELLE SI DISSOLVE CON LA DISTANZA, ed è la metà che rende incomprensibile da
## dove arrivi. Fino a `PIENO` metri dalla camera il tentacolo è pieno; da lì a
## `SPARISCE` si sgrana a puntini (il retinato per pixel di Godot, che su questa
## risoluzione bassa è lo stesso retinato della PlayStation) e poi non c'è più.
## Alzando la testa si vede la colonna salire, allargarsi, sfarinarsi nel cielo: la
## cima, a millecinquecento metri, non la raggiunge nessuno sguardo.
##
## PERCHE' NON LA NEBBIA. Il mondo non ne ha, ed è una scelta dell'ambiente notturno
## tarato guardando: aggiungerla per nascondere la cima di una cosa sola vorrebbe dire
## cambiare il cielo di tutto il gioco.
const PIENO := 350.0
const SPARISCE := 1000.0

## La velocità dell'onda all'attacco, in metri al secondo, e di quanto accelera verso
## la punta. Nel pezzo che si guarda corre a nove metri al secondo: dai cinquanta ai
## venti metri d'altezza ci mette poco più di tre secondi, ed è quel ritardo che
## disegna la esse.
const VELOCITA_ONDA := 3.2
const ACCELERAZIONE_ONDA := 2.0

## I tre modi sovrapposti: ampiezza in metri, periodo in secondi, sfasatura fra i
## due piani orizzontali (con ±π/2 il moto è circolare, con 0 è piatto: nel mezzo
## è ellittico, che è quello che fa una cosa che non sta oscillando su un binario).
##
## `estensione` è QUANTI METRI SOPRA LA PUNTA il modo vive: la sua ampiezza cala come
## `exp(-d / estensione)` salendo. È la terza forma di questa riga, e ciascuna è
## caduta allungando il braccio:
##   - in frazione di braccio (`s` alla potenza): a duecento metri i modi veloci si
##     trovavano ad ampiezza piena a cento metri d'altezza, dove la loro onda è corta,
##     e la catena piegava di trentadue gradi a giunto;
##   - in metri SOTTO L'ATTACCO: a millecinquecento metri vuol dire ampiezza piena su
##     un chilometro e mezzo di colonna, dove le ossa sono lunghe quaranta metri e
##     un'onda da trenta non ci sta dentro.
## In metri SOPRA LA PUNTA è anche quello che fa un corpo vero: l'increspatura veloce
## vive dove il corpo è SOTTILE e si smorza nella parte grossa. Il modo lento, che
## disegna la esse grande, sale di più; il più veloce resta negli ultimi cento metri.
##
## LE AMPIEZZE SONO UNA VOLTA E MEZZO QUELLE DI PRIMA, perché il braccio è grosso il
## doppio: con lo stesso scostamento di prima un tubo di sette metri sembrava rigido.
const MODI: Array[Dictionary] = [
	{"ampiezza": 4.8, "periodo": 17.0, "sfasatura": 1.4, "estensione": 350.0},
	{"ampiezza": 2.0, "periodo": 7.3, "sfasatura": -0.9, "estensione": 150.0},
	{"ampiezza": 0.75, "periodo": 3.9, "sfasatura": 2.3, "estensione": 70.0},
]

## IL COLOSSO: l'oscillazione lentissima della colonna intera, e l'unico movimento
## che si vede dove i modi di sopra si sono spenti. Quaranta secondi di periodo e
## venticinque metri di ampiezza, su un'onda lunga due chilometri e mezzo — cioè una
## curva quasi dritta che si sposta, come si sposta la cima di un albero da lontano.
## Comincia a contare sopra `COLOSSO_DA` metri dalla punta e arriva pieno a
## `COLOSSO_PIENO`: il pezzo davanti alla porta non lo sente, e la punta resta dov'è.
const COLOSSO_AMPIEZZA := 25.0
const COLOSSO_PERIODO := 40.0
const COLOSSO_ONDA := 2500.0
const COLOSSO_DA := 150.0
const COLOSSO_PIENO := 700.0

## Gli ultimi metri, dove l'ampiezza cala e la punta tiene il posto. Non a zero:
## una punta perfettamente ferma sembra inchiodata al terreno.
##
## SI MISURA IN METRI DALLA PUNTA, non in frazione di braccio, ed è la stessa
## ragione delle portate qui sopra: tenere il calo a una frazione vuol dire che
## allungando il braccio si allunga anche il tratto che sta fermo, e il pezzo basso
## — l'unico che si guarda da vicino — si irrigidirebbe senza che nessuno abbia
## toccato l'animazione. Venti metri sono venti metri.
##
## E il calo è LUNGO venti metri e non sette, che è una correzione trovata dalla
## sonda: a sette l'ampiezza crollava dell'85% in meno di quattro ossa, e per stare
## dietro a quel crollo la catena piegava di quarantaquattro gradi a giunto — la
## pelle faceva la grinza, e sulla grinza si conta il numero delle ossa.
##
## QUARANTACINQUE E NON VENTI da quando il braccio è grosso il doppio e le onde sono
## una volta e mezzo più ampie. A trenta la sonda ha trovato di nuovo la grinza, nello
## stesso posto e per la stessa ragione della prima volta: 16,6 gradi a ventisette
## metri dalla punta, dove il calo dell'ampiezza si somma all'agitazione della discesa.
const TIENE_METRI := 45.0
const TIENE_QUANTO := 0.85

## Quanti metri, sotto l'attacco, l'onda impiega a partire. Serve solo a non far
## traslare tutta la colonna: lassù non guarda nessuno, ma una cosa appesa che si
## sposta in blocco all'altezza dell'attacco non è appesa a niente.
const ANCORA_METRI := 40.0

## L'ARRICCIATURA della punta: gli ultimi nove metri si avvolgono lentamente, come
## fa un braccio a riposo. In METRI, per la stessa ragione di `TIENE_METRI`: è un
## fatto della punta, e la punta non sa quanto è lungo il resto.
## Quattordici metri e un metro e trenta di raggio: erano nove e ottantacinque
## centimetri, e sono cresciuti di una volta e mezzo insieme al braccio.
const ARRICCIA_METRI := 14.0
const ARRICCIA_DA := 1.0 - ARRICCIA_METRI / LUNGHEZZA
const ARRICCIA_RAGGIO := 1.3
## UN RADIANTE SUL TRATTO — cioè un sesto di giro, un gancio, non una spirale.
##
## E' il numero su cui questo file ha sbagliato due volte, tutte e due le volte
## nello stesso modo: chiedendo alla punta una curva più stretta di quella che
## quattro ossa e mezza sanno disegnare. La prima volta erano tre giri e mezzo (22
## gradi di piega a giunto); la seconda è nata TRADUCENDO questa costante da
## «radianti sul tratto» a «radianti al metro» mentre il braccio passava da
## quarantacinque metri a duecento — il tratto è sempre stato nove metri, ma la
## frazione di braccio che valeva 0,2 adesso vale 0,045, e portandosi dietro il
## vecchio numero si moltiplicava per cinque. Trentadue gradi, e il modello nuovo
## si è preso la colpa di un difetto vecchio.
##
## La sonda l'ha visto tutte e due le volte, ed è per questo che misura i gradi di
## piega e non «se si vede bene»: a occhio, in mezzo a duecento metri di braccio
## che si muove, una grinza negli ultimi nove non la nota nessuno finché non è lei
## la cosa che si sta guardando.
const ARRICCIA_AL_METRO := 1.0 / ARRICCIA_METRI
## Un giro ogni undici secondi.
const ARRICCIA_VELOCITA := 0.55

## Quanto più si agita mentre sta ancora scendendo. Una cosa che si cala si dimena;
## una volta arrivata si calma, e la differenza fra i due stati è metà del motivo
## per cui l'arrivo si guarda.
##
## 0,35 E NON 0,5: con le onde più ampie, il mezzo in più della discesa bastava da solo
## a spingere la piega oltre il limite.
const FOGA_IN_DISCESA := 0.35

var _scheletro: Skeleton3D
var _catena: PackedInt32Array = PackedInt32Array()
var _riposo: Array[Basis] = []
var _dir_riposo: Array[Vector3] = []
var _lunghezze := PackedFloat32Array()
## Dove sta ogni giunto lungo il braccio, in frazione (0 all'attacco, 1 in punta):
## le ossa sono lunghe diverse, e `k / n` non dice più niente.
var _s := PackedFloat32Array()
var _origine := Vector3.ZERO
var _radice_riposo := Vector3.ZERO
## Dove stanno DAVVERO i giunti, in spazio scheletro, dopo l'ultima piega: non la
## curva voluta, la catena che ne è uscita. Vedi `_piega()`.
var _reali := PackedVector3Array()
var _ritardo := PackedFloat32Array()
var _giu := Vector3.DOWN
var _piano_a := Vector3.RIGHT
var _piano_b := Vector3.BACK
var _t := 0.0
## 1 = tutto su nel cielo, 0 = arrivata. Si muove verso `_verso`.
var _quota := 1.0
var _verso := 0.0
var _modello: Node3D


func _ready() -> void:
	_modello = get_node_or_null("Modello") as Node3D
	if _modello == null:
		push_error("tentacolo: manca il nodo Modello — la discesa non si vede")
		set_process(false)
		return
	_scheletro = _trova_scheletro(self)
	if _scheletro == null:
		push_error("tentacolo: nessuno Skeleton3D nel modello — resta fermo")
		set_process(false)
		return
	_misura_il_riposo()
	_dissolvi_con_la_distanza()
	_modello.position.y = CORSA
	# Una piega subito, prima del primo fotogramma: chi chiede `punta()` appena
	# istanziato deve sentirsi dire dove sta la punta, non dove sta il nodo.
	_piega()
	set_process(true)


## Lo scheletro si CERCA, non si raggiunge per percorso: il .glb lo importa Godot, e
## il nome dei nodi che ne escono dipende dall'esportatore e dalla versione. Un
## `$Modello/Scheletro/Skeleton3D` si romperebbe alla prima rigenerazione del
## modello, e si romperebbe in silenzio — il tentacolo comparirebbe dritto.
func _trova_scheletro(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n as Skeleton3D
	for f in n.get_children():
		var s := _trova_scheletro(f)
		if s != null:
			return s
	return null


## Misura la catena com'è NATA, e ci costruisce sopra tutto il resto.
##
## SI CAMMINA LA GERARCHIA, non si contano gli indici. Che l'osso 0 sia il padre
## dell'1 è vero nel modello che esce da `tentacolo_blender.py`, ma è una promessa
## dell'esportatore, non una legge: basta un import che riordini e la catena si
## piegherebbe a caso. Qui si parte dall'osso senza padre e si scende di figlio in
## figlio, che è la stessa cosa detta senza fidarsi.
##
## E LE DIREZIONI SI MISURANO, non si assumono. Il glTF porta il mondo da Z-su a
## Y-su e può rigirare la radice: scrivere «la catena va verso il basso» qui dentro
## vorrebbe dire scommettere su una convenzione di export. `_giu` è la direzione
## che la catena HA, letta dalle pose di riposo, e i due piani laterali si ricavano
## da quella. Così il modello può arrivare orientato come gli pare.
func _misura_il_riposo() -> void:
	var indici := PackedInt32Array()
	var i := 0
	for b in _scheletro.get_bone_count():
		if _scheletro.get_bone_parent(b) == -1:
			i = b
			break
	while i != -1:
		indici.append(i)
		var figli := _scheletro.get_bone_children(i)
		i = figli[0] if figli.size() > 0 else -1
	_catena = indici

	_riposo.clear()
	_dir_riposo.clear()
	var origini: Array[Vector3] = []
	for b in _catena:
		var r := _scheletro.get_bone_global_rest(b)
		_riposo.append(r.basis)
		origini.append(r.origin)
	_lunghezze = PackedFloat32Array()
	var fatta := 0.0
	for k in _catena.size():
		if k + 1 < _catena.size():
			_dir_riposo.append((origini[k + 1] - origini[k]).normalized())
			var l := origini[k].distance_to(origini[k + 1])
			_lunghezze.append(l)
			fatta += l
		else:
			_dir_riposo.append(_dir_riposo[k - 1] if k > 0 else Vector3.DOWN)
			_lunghezze.append(LUNGHEZZA - fatta)
	_giu = _dir_riposo[0]
	_origine = origini[0]
	_radice_riposo = _scheletro.get_bone_rest(_catena[0]).origin

	# Due assi qualunque perpendicolari alla catena: servono solo a dare un piano
	# all'onda, e quale dei due sia «avanti» non cambia niente — il movimento è
	# ellittico e non ha una faccia buona.
	_piano_a = _giu.cross(Vector3.RIGHT)
	if _piano_a.length_squared() < 0.01:
		_piano_a = _giu.cross(Vector3.FORWARD)
	_piano_a = _piano_a.normalized()
	_piano_b = _giu.cross(_piano_a).normalized()

	# DOVE STA OGNI GIUNTO, misurato sommando le ossa vere: in punta sono lunghe due
	# metri, in cima quaranta, e il giunto numero `k` non sta a `k / n` del braccio.
	var n := _catena.size()
	_s = PackedFloat32Array()
	_s.resize(n + 1)
	var sommata := 0.0
	for k in n + 1:
		_s[k] = sommata / LUNGHEZZA
		if k < n:
			sommata += _lunghezze[k]

	# IL RITARDO DELL'ONDA, integrato una volta sola. `1/v` si somma lungo il
	# braccio invece di moltiplicare `s` per una costante, perché la velocità non è
	# costante: è il punto 2 della testata.
	_ritardo = PackedFloat32Array()
	_ritardo.resize(n + 1)
	_ritardo[0] = 0.0
	for k in n:
		var s := 0.5 * (_s[k] + _s[k + 1])
		var v: float = VELOCITA_ONDA * (1.0 + ACCELERAZIONE_ONDA * pow(s, 1.6))
		_ritardo[k + 1] = _ritardo[k] + _lunghezze[k] / v


## Mette la dissolvenza sulla pelle: vedi `PIENO` e `SPARISCE`.
##
## SI COPIANO I MATERIALI DEL MODELLO, non si toccano: sono risorse importate dal
## .glb e condivise da chiunque lo istanzi, e scriverci sopra vorrebbe dire cambiare
## il materiale anche al tentacolo del provino, o a quello di una storia futura che
## lo volesse pieno fino in cima.
func _dissolvi_con_la_distanza() -> void:
	for m in _mesh_di(_modello):
		if m.mesh == null:
			continue
		for i in m.mesh.get_surface_count():
			var originale := m.get_active_material(i) as BaseMaterial3D
			if originale == null:
				continue
			var copia := originale.duplicate() as BaseMaterial3D
			copia.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
			# MINIMO PIU' GRANDE DEL MASSIMO, e non è un errore di battitura: con i due
			# numeri in quest'ordine Godot inverte la dissolvenza, e l'oggetto sparisce
			# ALLONTANANDOSI invece che avvicinandosi.
			copia.distance_fade_min_distance = SPARISCE
			copia.distance_fade_max_distance = PIENO
			m.set_surface_override_material(i, copia)


func _mesh_di(n: Node) -> Array[MeshInstance3D]:
	var fuori: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		fuori.append(n as MeshInstance3D)
	for f in n.get_children():
		fuori.append_array(_mesh_di(f))
	return fuori


## Quanti metri sopra la punta sta il giunto `k`, lungo il braccio a riposo.
func metri_dalla_punta(k: int) -> float:
	return (1.0 - _s[k]) * LUNGHEZZA


## Il giunto più vicino a `metri` sopra la punta, lungo il braccio a riposo. Serve
## alle sonde, che chiedono «cosa fa il braccio a venti metri da terra» e non «cosa
## fa il giunto numero 80» — un numero che cambia ogni volta che cambia la regola
## delle ossa.
func giunto_a(metri: float) -> int:
	var voluta := 1.0 - metri / LUNGHEZZA
	var migliore := 0
	for k in _s.size():
		if absf(_s[k] - voluta) < absf(_s[migliore] - voluta):
			migliore = k
	return migliore


## Cala il tentacolo dal cielo. Chiamarlo mentre sta già scendendo non fa niente.
func scendi() -> void:
	_verso = -1.0


## Lo ritira. Quando è tornato su emette `risalito`.
func risali() -> void:
	_verso = 1.0


## Quanto è calato, da 0 (tutto in cielo) a 1 (arrivato). Lo legge l'overlay.
func discesa() -> float:
	return 1.0 - _quota


func _process(delta: float) -> void:
	passo(delta)


## Un passo di animazione. E' PUBBLICO PERCHE' LE SONDE DEVONO POTER MUOVERE IL
## TEMPO A MANO: in headless un fotogramma dura un millesimo di secondo, e una
## sonda che aspettasse i fotogrammi veri misurerebbe venti secondi di onda in due.
## Chi vuole guidarlo spegne `set_process(false)` e chiama questo con il passo che
## gli serve. In partita lo chiama `_process` e basta.
func passo(delta: float) -> void:
	_t += delta
	_muovi_la_quota(delta)
	_piega()


func _muovi_la_quota(delta: float) -> void:
	if is_zero_approx(_verso):
		return
	var durata := DURATA_RISALITA if _verso > 0.0 else DURATA_DISCESA
	var prima := _quota
	_quota = clampf(_quota + _verso * delta / durata, 0.0, 1.0)
	# `smoothstep` e non una rampa dritta: parte piano — sta ancora emergendo da
	# lassù — accelera, e si POSA invece di fermarsi di colpo. Una discesa lineare
	# finisce con uno stacco netto che tradisce l'interpolazione.
	_modello.position.y = CORSA * smoothstep(0.0, 1.0, _quota)
	if _quota >= 1.0 and prima < 1.0:
		_verso = 0.0
		risalito.emit()
	elif _quota <= 0.0:
		_verso = 0.0


## Piega la catena sulla spina calcolata, osso per osso.
##
## OGNI OSSO SI ORIENTA DAL SUO RIPOSO, non dal padre già piegato, e poi la posa si
## riporta in locale dividendo per il padre. Fatto al contrario — accumulando le
## rotazioni lungo la catena — l'errore di ogni giunto si somma a quelli di prima e
## dopo cento ossa la punta è girata su se stessa di parecchi gradi: la pelle si
## attorciglia, e le ventose smettono di guardare tutte dalla stessa parte.
##
## E POI SI RIMETTE LA PUNTA DOVE DEVE STARE, che è la seconda metà del conto e la
## si è scoperta allungando il braccio. Le ossa non si allungano: ogni osso prende
## la DIREZIONE del suo tratto di curva ma resta lungo due metri, mentre il tratto
## di curva, che si scosta di lato, è più lungo di due. Su ogni osso si perde
## qualche centimetro in verticale, e i centimetri si sommano. A quarantacinque
## metri erano trenta centimetri e non se n'è accorto nessuno; a duecento, con le
## onde di quattro metri a metà corpo, sono QUATTRO O CINQUE METRI — la punta
## restava sospesa sopra il tetto mentre il conto la diceva a un metro e ottanta
## dall'erba. Lo scatto contro l'edificio l'ha fatto vedere; la sonda no, perché
## confrontava le direzioni delle ossa e quelle erano giuste.
##
## Si cammina la catena vera, si misura di quanto la punta è rimasta indietro, e di
## tanto si sposta la RADICE. Il debito lo paga l'attacco, lassù nel cielo, dove
## oscillare di un paio di metri su e giù non lo vede nessuno; la punta sta dove
## la curva la vuole, che è l'unico punto di questa cosa che conta dove sta.
func _piega() -> void:
	var punti := _spina()
	var n := _catena.size()
	var padre := Basis.IDENTITY
	var qui: Vector3 = punti[0]
	_reali.resize(n + 1)
	_reali[0] = qui
	for k in n:
		var dir := (punti[k + 1] - punti[k]).normalized()
		var globale := Basis(Quaternion(_dir_riposo[k], dir)) * _riposo[k]
		var locale := padre.inverse() * globale
		_scheletro.set_bone_pose_rotation(_catena[k], locale.get_rotation_quaternion())
		padre = globale
		qui += dir * _lunghezze[k]
		_reali[k + 1] = qui
	var debito: Vector3 = punti[n] - _reali[n]
	for k in n + 1:
		_reali[k] += debito
	_scheletro.set_bone_pose_position(_catena[0], _radice_riposo + debito)


## I punti della spina dorsale, in spazio scheletro: uno per giunto più la punta.
func _spina() -> Array[Vector3]:
	var n := _catena.size()
	var punti: Array[Vector3] = []
	punti.resize(n + 1)
	for k in n + 1:
		var s := _s[k]
		var off := _scostamento(s, _ritardo[k])
		punti[k] = _origine + _giu * (s * LUNGHEZZA) + _piano_a * off.x + _piano_b * off.y
	return punti


## Di quanto la spina si scosta dalla verticale alla frazione `s`, in metri, sui due
## piani laterali. È tutto il movimento del tentacolo, in sei righe.
func _scostamento(s: float, ritardo: float) -> Vector2:
	var foga := 1.0 + FOGA_IN_DISCESA * _quota
	var o := Vector2.ZERO
	for m in MODI:
		# IL TEMPO E' QUELLO DI QUESTO PUNTO DEL BRACCIO, non quello dell'orologio:
		# `_t - ritardo` è ciò che fa viaggiare l'onda verso il basso invece di far
		# pulsare tutto insieme.
		var fase: float = TAU * (_t - ritardo) / float(m["periodo"])
		var a: float = float(m["ampiezza"]) * _inviluppo(s, float(m["estensione"]))
		o += Vector2(sin(fase), sin(fase + float(m["sfasatura"]))) * a
	return (o + _arricciatura(s)) * foga + _colosso(s)


## Quanto è ampia l'onda alla frazione `s`: piena poco sopra la punta, spenta salendo,
## ferma all'attacco, e giù negli ultimi metri, dove la punta tiene il posto. Tutto
## in METRI, perché sono fatti fisici del corpo e non frazioni della sua lunghezza.
func _inviluppo(s: float, estensione: float) -> float:
	var dal_cielo := s * LUNGHEZZA
	var dalla_punta := (1.0 - s) * LUNGHEZZA
	var vive := exp(-dalla_punta / estensione)
	var appesa := smoothstep(0.0, ANCORA_METRI, dal_cielo)
	var tiene := 1.0 - TIENE_QUANTO * (1.0 - smoothstep(0.0, TIENE_METRI, dalla_punta))
	return vive * appesa * tiene


## L'oscillazione della colonna intera: vedi `COLOSSO_AMPIEZZA`. Non passa dalla
## `foga` della discesa — una cosa di un chilometro non si dimena, e agitarla del
## cinquanta per cento vorrebbe dire spostarla di dodici metri in più.
func _colosso(s: float) -> Vector2:
	var dal_cielo := s * LUNGHEZZA
	var dalla_punta := (1.0 - s) * LUNGHEZZA
	var quanto := smoothstep(COLOSSO_DA, COLOSSO_PIENO, dalla_punta) \
		* smoothstep(0.0, ANCORA_METRI * 5.0, dal_cielo)
	if quanto <= 0.0:
		return Vector2.ZERO
	var fase := TAU * (_t / COLOSSO_PERIODO - dalla_punta / COLOSSO_ONDA)
	return Vector2(sin(fase), sin(fase + 1.9)) * (COLOSSO_AMPIEZZA * quanto)


## L'ultimo tratto si avvolge su se stesso, lentamente e senza fermarsi mai: è la
## cosa che, guardando la punta ferma, dice che è viva e non appoggiata.
func _arricciatura(s: float) -> Vector2:
	var f := clampf((s - ARRICCIA_DA) / (1.0 - ARRICCIA_DA), 0.0, 1.0)
	if f <= 0.0:
		return Vector2.ZERO
	var ang := _t * ARRICCIA_VELOCITA + (s - ARRICCIA_DA) * LUNGHEZZA * ARRICCIA_AL_METRO
	return Vector2(cos(ang), sin(ang)) * (ARRICCIA_RAGGIO * f * f)


## I giunti in coordinate di MONDO: dove stanno davvero, dopo l'ultima piega — la
## catena che si vede, non la curva che si voleva. Le sonde li confrontano con le
## pose vere dello scheletro, ed è il confronto che ha trovato la punta sospesa.
func giunti() -> PackedVector3Array:
	var fuori := PackedVector3Array()
	if _scheletro == null:
		return fuori
	var t := _scheletro.global_transform
	for p in _reali:
		fuori.append(t * p)
	return fuori


## Dove sta la punta, in coordinate di mondo. È l'unico modo di chiedere «ci arriva
## davvero, davanti all'osservatorio?» con un numero.
func punta() -> Vector3:
	var g := giunti()
	return g[g.size() - 1] if g.size() > 0 else global_position


## Si mette in pianta dove gli si dice, e la QUOTA se la calcola: la punta deve
## restare `franco` metri sopra l'erba, e l'erba lì sotto non è a zero.
##
## PERCHE' NON UN RAGGIO VERSO IL BASSO. Il prato è un corpo con la collisione vera,
## quindi un raggio funzionerebbe — ma solo dopo il primo passo di fisica, e chi
## cala il tentacolo lo fa nel fotogramma in cui preme il tasto. `FormaPrato.altezza`
## è la stessa formula da cui nasce la maglia, e risponde subito.
func posa_sul_prato(x: float, z: float, franco: float) -> void:
	var suolo := 0.0
	var prato := _trova_prato(get_tree().root)
	if prato != null:
		suolo = prato.position.y + FormaPrato.altezza(
			Vector2(x, z), prato.sito())
	position = Vector3(x, suolo + LUNGHEZZA + franco, z)


func _trova_prato(n: Node) -> Prato:
	if n is Prato:
		return n as Prato
	for f in n.get_children():
		var p := _trova_prato(f)
		if p != null:
			return p
	return null
