## Un oggetto che si prende in mano — e che quando lo lasci cade davvero.
##
## PERCHÉ NON È UN `Interactable`. Quella è la classe di ciò che si usa STANDO
## DOV'È: uno `StaticBody3D`, che ferma il giocatore proprio perché non si sposta.
## Un oggetto che si porta in giro dev'essere l'opposto — un `RigidBody3D`, un
## corpo che muove il motore — e in GDScript l'ereditarietà è singola: fra le due
## non esiste un antenato comune, e inventarne uno vorrebbe dire far finta che una
## moka e un interruttore a muro siano la stessa cosa. Sono due gerarchie, e il
## giocatore le tiene distinte con due variabili invece che con un cast fortunato.
##
## LA MANO NON È UN GENITORE, ED È TUTTA LA DIFFERENZA. Il modo ovvio di tenere
## qualcosa in mano è appenderlo alla camera — `reparent`, e l'oggetto ti segue
## perfetto. Perfetto è il problema: un figlio della camera non ha più una fisica.
## Entra nei muri, attraversa i tavoli, e ti ritrovi la moka dentro l'intonaco
## senza che niente protesti. Qui invece l'oggetto resta un corpo libero e viene
## RINCORSO: a ogni passo di fisica gli si dà la velocità che lo porterebbe dove
## sta la mano, e poi lo si lascia al motore. Se in mezzo c'è un muro, vince il
## muro. È esattamente il motivo per cui una cosa si può appoggiare su un ripiano
## invece che infilarcela dentro.
##
## E LA VELOCITÀ È LIMITATA, che è la seconda metà della stessa idea e non una
## rifinitura. La velocità che «porta là in un tick» è enorme, e a quella velocità
## un corpo salta oltre le pareti sottili prima che il motore se ne accorga: la
## fisica tornerebbe a essere una decorazione, con più righe. Il tetto sulla
## velocità è ciò che tiene l'oggetto dentro il mondo.
##
## IL PESO SI SENTE PERCHÉ IL TETTO DIPENDE DALLA MASSA. Non c'è nessuna
## simulazione di sforzo: un oggetto pesante insegue la mano più piano, quindi ti
## resta indietro quando ti giri, e girarsi con quello in mano è un gesto diverso
## da girarsi con un floppy. È la stessa cosa che si sente davvero portando una
## cassa, e costa una divisione.
class_name Carryable
extends RigidBody3D

## Chi ha bisogno di questi oggetti li trova per GRUPPO, mai per nome: la lezione
## del fungo e dell'anta (D-196) vale a maggior ragione qui, dove i nodi hanno i
## nomi delle cose di tutti i giorni e la collisione di nome è quasi garantita.
const GROUP := &"carryable"

## Metri al secondo con cui la mano insegue un oggetto di un chilo. Sopra i sette
## il trasporto smette di sembrare una mano e comincia a sembrare una calamita —
## l'oggetto sta incollato davanti alla faccia e non ha più peso; sotto i quattro
## resta indietro girandosi anche se è un accendino.
const VELOCITA_MANO := 6.0

## Radianti al secondo con cui l'oggetto si raddrizza verso l'orientamento della
## mano. Non serve limitarlo quanto la traslazione: girando su se stesso un corpo
## non attraversa niente.
const VELOCITA_GIRO := 12.0

## Quando la mano molla: da più lontano di così, in metri, e per almeno tanti
## secondi.
##
## DUE NUMERI E NON UNO, per la stessa ragione per cui il viaggio del telescopio
## ne vuole due (D-198). Un oggetto che sbatte contro uno stipite resta indietro
## per qualche centesimo di secondo, ed è giusto così: è quello che fa una cosa
## vera contro un ostacolo vero. Uno rimasto DIETRO un muro ci resta. Con la sola
## distanza cadrebbe di mano a ogni urto; è il tempo a distinguere l'urto dalla
## separazione.
const STRAPPO := 1.1
const STRAPPO_SECONDI := 0.35

## Emesso quando l'oggetto smette di stare in mano, per qualunque ragione — posato
## dal giocatore o strappato via da un muro. Chi lo teneva lo ascolta: senza,
## resterebbe a credere di avere in mano una cosa che è per terra due stanze fa.
signal posato

## Come si chiama nel prompt, articolo compreso: la riga che si legge è «Raccogli
## la moka», non «Raccogli moka». Stessa regola di `Interactable.prompt_text` —
## il prompt lo legge il giocatore, quindi è italiano.
@export var nome := "l'oggetto"

## IL MODO SBAGLIATO, tenuto a portata di mano perché lo si possa misurare.
##
## A `true` l'oggetto viene TELETRASPORTATO dove sta la mano a ogni passo, invece
## di esserci portato: è quello che succede appendendolo alla camera, ed è la
## prima cosa che chiunque scrive. Attraversa i muri, e non lo dice nessuno.
##
## È `@export` E NON UNA COSTANTE PERCHÉ SI DEVE POTER RIMETTERE IL DIFETTO: senza
## il confronto, un referto che dice «l'oggetto non è entrato nel muro» non
## distingue il merito del rincorrimento dal fatto che nessuno abbia provato a
## spingercelo dentro. Vedi `tools/prova_mani.gd`, che lo accende con
## `MANO_RIGIDA=1`.
@export var mano_rigida := false

## La trasformata dove la mano vuole che stia. La scrive chi lo tiene, a ogni
## passo di fisica, con `punta()`.
var _mano := Transform3D.IDENTITY

var _in_mano := false

## Da quanto tempo l'oggetto è oltre `STRAPPO`. Vedi lassù perché non basta la
## distanza.
var _lontano_da := 0.0

## Chi lo tiene. Serve solo a togliere e rimettere l'esclusione di collisione.
var _chi: PhysicsBody3D = null


static func find_in(tree: SceneTree) -> Carryable:
	return tree.get_first_node_in_group(GROUP) as Carryable


func _ready() -> void:
	add_to_group(GROUP)
	# Layer 1 perché il giocatore ci sbatta contro e possa spingerlo col piede,
	# layer 3 perché il raggio dell'interazione lo trovi. Gli stessi due di
	# `Interactable`, e in OR per la stessa ragione: un'assegnazione cieca
	# cancellerebbe una maschera scelta nell'ispettore.
	collision_layer |= Interactable.LAYER_WORLD | Interactable.LAYER_INTERACTABLE
	collision_mask |= Interactable.LAYER_WORLD
	# IL SONNO SI TOGLIE SOLO IN MANO, e la prima stesura lo toglieva sempre.
	# `_integrate_forces` su un corpo addormentato non viene chiamato, quindi
	# mentre lo si tiene il sonno va escluso o la mano smette di funzionare da
	# sola dopo qualche secondo di immobilità. Ma tenerlo escluso SEMPRE vuol dire
	# che un oggetto appoggiato su un piano non si assesta mai del tutto: continua
	# a essere risolto ogni tick e conserva un tremito. Misurato — una tazza sulla
	# consolle, dopo tre secondi, andava ancora a 8 cm al secondo. Vedi `prendi()`
	# e `lascia()`, che lo tolgono e lo rimettono.
	# LA COLLISIONE LUNGO IL PERCORSO SI ACCENDE SOLO IN MANO: vedi `prendi()`.
	# I CONTATTI SI DEVONO POTER LEGGERE dentro `_integrate_forces`, o
	# `get_contact_count()` restituisce zero per sempre — senza dirlo. Quattro
	# bastano: sono le facce che un oggetto può toccare in un angolo.
	contact_monitor = true
	max_contacts_reported = 4
	# SMORZAMENTO, e serve a far FINIRE il movimento invece che a rallentarlo.
	#
	# Un corpo appoggiato affonda nella superficie fino al limite che il solutore
	# consente - un centimetro - e da li' in poi il correttore lo respinge a ogni
	# tick. Su un cilindro basso quegli impulsi cadono su punti di contatto che non
	# sono mai perfettamente simmetrici, e la somma e' una COPPIA: misurato, una
	# tazza appoggiata sulla consolle girava su se stessa a un giro e mezzo al
	# secondo e non si fermava piu', perche' sopra la soglia di sonno il motore non
	# la lascia mai dormire.
	#
	# Lo smorzamento angolare alto e' anche la cosa vera: una tazza di porcellana su
	# un piano di formica non e' una trottola, e un termos non rotola come una
	# biglia. Quello lineare resta basso, o un oggetto lanciato si fermerebbe a
	# mezz'aria.
	angular_damp = 4.0
	linear_damp = 0.2


## La riga che il giocatore legge guardandolo. Non c'è un `can_interact()` da
## stringere: un oggetto per terra si può sempre prendere, ed è la cosa che lo
## distingue dagli interagibili, che invece hanno tempi e condizioni.
func prompt() -> String:
	return "Raccogli %s" % nome


## La riga mentre lo si tiene. «Posa» e non «Lascia»: il gesto normale è
## appoggiare una cosa dove si sta guardando, e lasciarla cadere è solo quello
## che succede se sotto non c'è niente.
func prompt_posa() -> String:
	return "Posa %s" % nome


## Cosa succede premendo il tasto con questo in mano.
##
## PERCHÉ NON È SEMPLICEMENTE `lascia()`, che è quello che fa qui. Perché ci sono
## oggetti che hanno UN POSTO: la camera CCD si avvita al focheggiatore, e
## lasciarla cadere davanti al telescopio non è la stessa cosa. Chiedendo
## all'oggetto invece di decidere nel giocatore, il caso speciale sta nella classe
## che lo conosce — e il giocatore non deve nominare né la camera né il
## telescopio. Vedi `ccd_camera.gd`.
func posa() -> void:
	lascia()


## Se sta in mano a qualcuno adesso.
func in_mano() -> bool:
	return _in_mano


func prendi(chi: PhysicsBody3D) -> void:
	if _in_mano:
		return
	_in_mano = true
	_chi = chi
	_lontano_da = 0.0
	# LA GRAVITÀ SI SPEGNE, e non è un modo di barare sul peso. La mano ci lavora
	# contro a ogni tick con la stessa forza, quindi lasciarla accesa vorrebbe
	# dire calcolare due volte la stessa cosa in versi opposti — e sbagliare di un
	# filo, cioè far scivolare l'oggetto verso il basso finché non tocca il
	# tetto della velocità. Il peso si sente altrove: vedi `_velocita_massima()`.
	gravity_scale = 0.0
	# Sveglio e senza diritto di riaddormentarsi: vedi `_ready()`.
	can_sleep = false
	sleeping = false
	# LA COLLISIONE SI GUARDA LUNGO IL PERCORSO, e SOLO ADESSO. Un corpo spinto
	# dalla mano a sei metri al secondo copre dieci centimetri per fotogramma, e il
	# modo normale di risolvere le collisioni guarda solo dov'è arrivato: contro un
	# tramezzo da dieci si finisce dentro, o oltre. Misurato — spingendo la mano
	# dentro un muro, senza questa riga la scatola ci entrava per nove centimetri su
	# dieci, con si ferma alla superficie.
	#
	# MA TENERLA ACCESA SEMPRE COSTA UN OGGETTO CHE NON SI FERMA. Un corpo appoggiato
	# affonda nella superficie fino al margine che il solutore consente, e con la
	# collisione continua quel margine viene ricontrollato lungo un percorso che a
	# corpo fermo è lungo zero: le correzioni si sommano invece di spegnersi.
	# Misurato — una tazza sulla consolle girava su se stessa a un giro e mezzo al
	# secondo e non si addormentava mai; spenta la collisione continua si ferma.
	# Cadendo non serve: nessun oggetto lasciato cadere raggiunge la velocità a cui
	# un tramezzo si attraversa.
	continuous_cd = true
	# E SI SMETTE DI URTARE CHI LO TIENE. Senza, l'oggetto tenuto a mezzo metro
	# dalla faccia è un corpo che spinge il giocatore all'indietro mentre il
	# giocatore insegue l'oggetto: si cammina da soli, per la stanza, e non si
	# capisce perché.
	if _chi != null:
		add_collision_exception_with(_chi)


func lascia() -> void:
	if not _in_mano:
		return
	_in_mano = false
	# LA VELOCITÀ NON SI AZZERA, e questo è il lancio: l'oggetto se ne va con
	# quella che aveva in mano. Girarsi di scatto e mollare lo scaglia, posarlo
	# fermo lo posa. Non c'è un comando «lancia» da nessuna parte — c'è la
	# fisica, che è quello che era stato chiesto.
	gravity_scale = 1.0
	# E il sonno torna, insieme alla collisione normale: posato su un piano, questo
	# oggetto deve poter smettere di essere calcolato invece di tremare per tutta
	# la notte.
	can_sleep = true
	continuous_cd = false
	if _chi != null:
		remove_collision_exception_with(_chi)
		_chi = null
	posato.emit()


## Dove la mano lo vuole, adesso. La chiama chi lo tiene, dal proprio
## `_physics_process`: gira prima del passo di fisica, quindi `_integrate_forces`
## legge sempre un valore di questo tick e non di quello prima.
func punta(mano: Transform3D) -> void:
	_mano = mano


## Il tetto alla velocità con cui questo oggetto insegue la mano.
##
## Va con la RADICE della massa e non con la massa: a un chilo è la velocità
## piena, a quattro è la metà, a sedici un quarto. Diviso per la massa netta un
## oggetto da dieci chili andrebbe a mezzo metro al secondo, cioè non lo si
## sposterebbe affatto; con la radice resta faticoso ma trasportabile, che è la
## differenza fra una cassa pesante e una cassa inchiodata al pavimento.
func _velocita_massima() -> float:
	return VELOCITA_MANO / sqrt(maxf(mass, 0.05))


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not _in_mano:
		return
	if mano_rigida:
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		state.transform = _mano
		return
	var scarto := _mano.origin - global_position
	# LO STRAPPO SI GUARDA PRIMA DI MUOVERE, come l'arrivo del telescopio: è
	# l'istante in cui la mano perde l'oggetto quello che interessa, e continuando
	# a inseguire per un tick in più lo si darebbe con un tick di ritardo.
	if scarto.length() > STRAPPO:
		_lontano_da += state.step
		if _lontano_da >= STRAPPO_SECONDI:
			# DIFFERITO: `lascia()` cambia `gravity_scale` e le esclusioni di
			# collisione, e questo è il mezzo passo di fisica in cui il motore sta
			# leggendo proprio quelle. Si lascia finire il tick.
			lascia.call_deferred()
			return
	else:
		_lontano_da = 0.0

	var v := scarto / state.step
	var tetto := _velocita_massima()
	if v.length() > tetto:
		v = v.normalized() * tetto
	state.linear_velocity = _senza_cio_che_entra(v, state)
	state.angular_velocity = _giro_verso(_mano.basis, state.step)


## La velocità della mano, tolto quello che spingerebbe dentro ciò che si sta già
## toccando.
##
## PERCHÉ SERVE, quando il motore le collisioni le risolve già. Le risolve DOPO
## averle viste: il corpo entra di qualche millimetro, il solver lo rispinge
## fuori, e va benissimo per un oggetto che cade. Qui però la mano ogni tick gli
## riassegna la velocità che punta dentro il muro, quindi il solver ricomincia da
## capo sessanta volte al secondo e l'affondamento diventa uno STATO invece che un
## istante. Misurato: sei centimetri e mezzo dentro un tramezzo da dieci, cioè
## visibilmente dentro.
##
## Tolta la componente entrante, la mano contro un muro fa quello che fa un
## braccio contro un muro: scivola lungo la parete invece di attraversarla. È la
## stessa cosa che `move_and_slide` fa per il giocatore, e per la stessa ragione.
func _senza_cio_che_entra(v: Vector3, state: PhysicsDirectBodyState3D) -> Vector3:
	for i in state.get_contact_count():
		# La normale punta FUORI da ciò che si tocca, cioè verso di noi: prodotto
		# scalare negativo vuol dire che stiamo andando dentro.
		var n := state.get_contact_local_normal(i)
		var entra := v.dot(n)
		if entra < 0.0:
			v -= n * entra
	return v


## La velocità angolare che porterebbe l'oggetto all'orientamento voluto.
##
## Si passa per il quaternione perché è l'unico modo diretto di ricavare ASSE e
## ANGOLO da «di quanto sono girato rispetto a lì»: gli angoli di Eulero, sommati
## e sottratti, danno il giro lungo o il ribaltamento a seconda di dove ci si
## trova, e girerebbero l'oggetto dalla parte sbagliata a metà stanza.
func _giro_verso(voluta: Basis, passo: float) -> Vector3:
	var q := voluta.get_rotation_quaternion() \
		* global_basis.get_rotation_quaternion().inverse()
	q = q.normalized()
	# LA STRADA CORTA. Ogni rotazione ha due quaternioni che la descrivono, uno
	# per il giro breve e uno per quello lungo dall'altra parte; quello con la
	# parte reale negativa è il secondo. Senza questa riga un oggetto girato di
	# 181 gradi farebbe il giro largo — visibilmente, e solo qualche volta.
	if q.w < 0.0:
		q = Quaternion(-q.x, -q.y, -q.z, -q.w)
	var asse := Vector3(q.x, q.y, q.z)
	if asse.length() < 0.0001:
		return Vector3.ZERO
	var angolo := 2.0 * acos(clampf(q.w, -1.0, 1.0))
	var w := asse.normalized() * (angolo / passo)
	if w.length() > VELOCITA_GIRO:
		w = w.normalized() * VELOCITA_GIRO
	return w
