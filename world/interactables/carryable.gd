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

## Metri al secondo con cui parte un oggetto da un chilo lanciato a barra piena (vedi
## `Player.TEMPO_CARICA`). Sei è il lancio da sotto di chi tira una cosa dall'altra
## parte della stanza, non una palla da baseball.
##
## VA CON LA RADICE DELLA MASSA come la mano (`_velocita_massima()`), e per la
## stessa ragione: il termos parte più piano della tazza.
const VELOCITA_LANCIO := 6.0

## Sotto questa massa il braccio non va più veloce. Senza, la tazza da centocinquanta
## grammi partirebbe a quindici metri al secondo: la radice premia le cose leggere
## all'infinito, e il braccio che le tira invece pesa sempre uguale.
const MASSA_BRACCIO := 0.5

## IL GIRO DEL LANCIO, in radianti al secondo. Federico: «ho provato a tirare la
## bottiglia e cade perfettamente in piedi». In mano la cosa sta dritta (vedi
## `_giro_verso`), e senza un giro volava dritta com'era e atterrava sul fondo — ogni
## volta, che è la cosa che nessun lancio vero fa.
##
## Chi tira una cosa la fa ruotare in avanti col polso. Nove radianti sono un giro e
## mezzo al secondo: in un lancio in casa, mezzo secondo di volo, quasi un giro. Il
## CASO cambia di un terzo la velocità e inclina l'asse, o l'atterraggio sarebbe
## deciso dalla distanza e basta — sempre coricata di qua a tre metri, sempre in
## piedi a quattro.
const GIRO_LANCIO := 9.0
const GIRO_CASO := 0.35
const ASSE_CASO := 0.5

## Lo smorzamento angolare a terra: vedi `_ready()`. IN VOLO SI TOGLIE, e torna al
## primo urto: a quattro il giro del lancio si spegne in un quarto di secondo, cioè
## prima di atterrare, e la bottiglia tornerebbe a toccare terra dritta.
const SMORZAMENTO_GIRO := 4.0


## Emesso quando l'oggetto smette di stare in mano, per qualunque ragione — posato
## dal giocatore o strappato via da un muro. Chi lo teneva lo ascolta: senza,
## resterebbe a credere di avere in mano una cosa che è per terra due stanze fa.
signal posato

## Emesso quando la cosa, dopo essersi mossa, è di nuovo ferma: c'è un posto nuovo da
## ricordare. Lo ascolta `MemoriaDelMondo` (D-243). Le sottoclassi lo emettono anche
## quando cambia quello che hanno DENTRO — la moka col caffè, la tazza piena.
signal cambiato

## Come si chiama nel prompt, articolo compreso: la riga che si legge è «Raccogli
## la moka», non «Raccogli moka». Stessa regola di `Interactable.prompt_text` —
## il prompt lo legge il giocatore, quindi è italiano.
@export var nome := "l'oggetto"

## Se la casa si ricorda dove la si è lasciata (D-243). Vero per quasi tutto: è roba di
## casa, e dopo un riavvio sta dove stava. Falso per chi ha già un altro modo di tornare
## al suo posto — la stampa ha il suo registro, la camera CCD riparte avvitata con la notte.
## Va deciso PRIMA di `super()` in `_ready()`, che è dove si entra nel gruppo.
@export var si_ricorda := true

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

## L'ALTRO MODO SBAGLIATO, tenuto per poterlo misurare: a `true` questo oggetto
## torna sul layer del MONDO, cioè torna a essere un ostacolo per il giocatore.
## Camminandoci sopra si decolla. Vedi `_ready()` per il perché, e
## `tools/prova_mani.gd`, che lo accende con `PROP_OSTACOLO=1`.
@export var ostacolo_per_il_giocatore := false

## IL LANCIO SENZA GIRO, tenuto per poterlo misurare: a `true` si torna a lanciare
## senza far ruotare niente, e la bottiglia torna ad atterrare in piedi. Vedi
## `GIRO_LANCIO` e `tools/prova_mani.gd`, che lo accende con `LANCIO_SENZA_GIRO=1`.
@export var lancio_senza_giro := false

## LA RETE, cioè la promessa che una cosa caduta si ritrova, e vale per tutto
## quello che si prende in mano — non solo per la camera CCD, che è stata la prima
## ad averla (D-217).
##
## IL FATTO, misurato da `tools/prova_smarrimenti.gd`: DIECI METRI QUADRI del
## pavimento di questa casa, in cinquantatre pozze, sono posti in cui una cosa a
## terra non si riprende e in cui una cosa a terra ci può arrivare rotolando. Non
## sono buchi né trappole spettacolari: sono le fessure fra un mobile e il muro e
## fra due mobili affiancati. Il giocatore è largo sessanta e il suo braccio arriva
## a un metro e venti; una borraccia è larga dieci e rotola dove capita.
##
## PERCHÉ NON SI TAPPANO I BUCHI. Sono cinquantatre, e tapparli vorrebbe dire
## cinquantatre volumi invisibili scritti a mano, da rifare a ogni mobile che si
## sposta. `FondoPasserella` esiste perché lì il buco è UNO e profondo un metro e
## sessanta (D-218); qui i buchi sono tanti e profondi zero.
##
## COSA FA: quando una cosa si ferma, si chiede se da qualche parte la si potrebbe
## riprendere. Se no, la si sposta nel posto buono più vicino — e la misura dice
## che quasi sempre sta a un palmo, quindici centimetri; il peggio è mezzo metro,
## dietro la pattumiera della cucina. Non è un teletrasporto: è la cosa che non ci
## stava, nella fessura in cui era rotolata.
##
## SEI DECIMI PRIMA DI GUARDARE: una cosa lasciata cadere rimbalza e rotola, e
## chiedersi «dove sono finita» mentre ci si muove ancora vuol dire chiederselo
## nel posto sbagliato.
const QUIETE := 0.6

## Quanto lontano si cerca un posto da cui prenderla, e in quante direzioni: sono
## le distanze in pianta.
##
## SI ARRIVA FINO A 1,15, cioè fin quasi a `Player.INTERACT_RANGE`, e prima ci si
## fermava a 0,85: una cosa appoggiata SOPRA qualcosa — il tubo, il pilastro — si
## raccoglie stando lontani, perché la distanza da coprire è quasi tutta
## orizzontale. Con il giro corto la sonda la dichiarava persa mentre stava
## all'altezza del petto di chi la guardava.
##
## SEDICI DIREZIONI E NON DODICI, e la differenza è un caso vero: nell'angolo fra
## il rack e la cassettiera della stampante il solo posto in cui il corpo ci sta è
## sulla diagonale a 135 gradi, e con il passo di trenta gradi quella diagonale
## non si prova mai.
const GIRO := [0.25, 0.45, 0.65, 0.85, 1.05, 1.15]
const VERSI := 16

## Quanti piani si attraversano cercando dove stanno i piedi. Il primo corpo che
## il raggio incontra scendendo può essere la cima di un mobile, o il tappo del
## pozzo della cupola: da lassù non ci si arriva, e i piedi vanno più sotto.
const STRATI_SUOLO := 3

## Di quanto si stacca da terra la capsula di prova, in metri. Cinque centimetri,
## e non zero: appoggiata esattamente sul punto colpito dal raggio, la capsula
## TOCCA il pavimento che l'ha fermata, e `intersect_shape` risponde «occupato»
## per ogni posto del mondo. Misurato: con la capsula a filo, otto pose su undici
## risultavano irraggiungibili — cioè in questa casa non si poteva raccogliere
## niente da terra.
const FRANCO_SUOLO := 0.05

## Dove si va a cercare il posto buono in cui rimetterla: anelli via via più
## larghi, fino a un metro. Oltre, spostarla smetterebbe di somigliare a «non ci
## stava» e comincerebbe a somigliare a una sparizione.
const RIPESCAGGIO := [0.15, 0.25, 0.35, 0.50, 0.65, 0.80, 1.00]

## Quante volte di fila si prova a ripescare la stessa cosa prima di arrendersi.
##
## SEI, e il tetto non serve a essere severi: serve a non fare la spola. Nelle
## fessure peggiori il posto buono piu' vicino e' esso stesso stretto — la cosa ci
## rotola dentro e la rete la riguarda — e senza un tetto le due cose si
## rimpallerebbero per tutta la notte. Misurato: due mosse bastano quasi sempre
## (l'angolo nord-ovest della cupola, 65 cm), e le fessure che ne chiedono di piu'
## sono quelle in cui la cosa scivola mentre la si sposta. Sotto le sei si
## arrendeva a meta' ripescaggio.
const RIPESCAGGI_MAX := 6

## QUANTO DEV'ESSERE GRANDE IL PAVIMENTO ATTORNO A UN POSTO perché sia un posto e
## non un'ISOLA, in metri quadri.
##
## IL FATTO CHE L'HA RESA NECESSARIA. La domanda «esiste un punto in cui il corpo
## ci sta?» non è la domanda «ci si può andare?», e nella cupola le due danno
## risposte opposte: la passerella anulare lascia fra sé e i muri della sala
## quarantasette centimetri a nord e cinquantasette a est e a ovest, e il corpo ne
## misura sessanta. Nei QUATTRO ANGOLI della sala, dove il cerchio si allontana
## dal rettangolo, di spazio ce n'è — e sono quattro isole da un terzo di metro
## quadro in cui non si entrerà mai, perché per arrivarci bisogna passare da un
## collo di cinquanta. Federico ci ha perso la camera per la seconda volta, e la
## rete gli ha detto di sì: «anche qui mi sa che è persa per sempre».
##
## COME SI RICONOSCE UN'ISOLA: si allaga il pavimento camminabile a partire dai
## piedi, e si conta. Se il pezzo finisce prima di un metro quadro non è una
## stanza, è un buco. Un metro quadro sta comodamente sopra le isole misurate
## (0,36 m² l'una) e sotto il pavimento libero della stanza più piccola della
## casa, che è il bagno.
##
## E COSTA POCO perché si ferma appena supera il conto: venticinque caselle da
## venti centimetri, non l'allagamento della casa.
const ISOLA_MAX := 1.0
const MAGLIA := 0.20

## Quanto dislivello si accetta fra due caselle vicine allagando: un gradino più
## alto di così un `CharacterBody3D` non lo sale (D-033), quindi non è pavimento
## che continua — è un altro piano.
const GRADINO := 0.25

## IL MODO SBAGLIATO, tenuto a portata di mano perché lo si possa misurare: a
## `true` nessuno va a riprendere questa cosa quando finisce dove non ci si
## arriva. Le sonde lo accendono — `prova_ccd.gd` con `CAMERA_SI_PERDE=1`, che
## insieme a questo toglie di scena anche il `FondoPasserella`, perché solo con
## tutte e due le difese spente il pozzo torna quello che era e si vede la partita
## rompersi davvero.
@export var si_puo_perdere := false

## La trasformata dove la mano vuole che stia. La scrive chi lo tiene, a ogni
## passo di fisica, con `punta()`.
var _mano := Transform3D.IDENTITY

## Da quanto sta ferma, e se la rete l'ha già guardata in questa fermata. Il conto
## costa una trentina di interrogazioni allo spazio: poco per una volta, troppo
## per sessanta volte al secondo.
var _quieta_da := 0.0
var _gia_guardata := false
## Dov'era quando la rete l'ha guardata: se striscia via, la si riguarda.
var _dove_guardata := Vector3.ZERO

## Quante volte la rete l'ha gia' spostata da quando e' stata lasciata. Serve a
## non fare la spola: nelle fessure peggiori il posto buono piu' vicino e' esso
## stesso una fessura, la cosa ci rotola dentro e la rete la riguarda — e senza un
## tetto le due cose si rimpallano per tutta la notte. Tre tentativi, poi si passa
## a `_perduta()`, che per la camera CCD vuol dire tornarsene al fuoco.
var _ripescaggi := 0

var _in_mano := false

## Se si è mossa dall'ultima volta che la casa se n'è ricordata. Vedi `cambiato`.
var _mosso := false

## Dove guarda chi lo tiene: il punto colpito dal raggio della mira, o `Vector3.INF`. Lo
## scrive il giocatore a ogni passo con `mira()` (D-244).
var _mirando := Vector3.INF

## Se il giocatore l'ha toccata: presa, spostata, riempita. Solo allora la casa se la ricorda
## (D-243). Vedi `stato_da_ricordare()`.
var _toccata := false

## Se si è già fermata una volta da quando esiste. La prima fermata è l'assestamento
## dell'avvio, e non conta. Vedi `_physics_process`.
var _assestata := false

## Dove portarla al prossimo passo di fisica, e se c'è da farlo. Vedi `teletrasporta()`.
var _teletrasporto := Transform3D.IDENTITY
var _da_teletrasportare := false

## Lanciata e non ha ancora toccato niente: finché è vero lo smorzamento del giro è
## tolto. Vedi `SMORZAMENTO_GIRO`.
var _in_volo := false

## Da quanto tempo l'oggetto è oltre `STRAPPO`. Vedi lassù perché non basta la
## distanza.
var _lontano_da := 0.0

## Chi lo tiene. Serve solo a togliere e rimettere l'esclusione di collisione.
var _chi: PhysicsBody3D = null


static func find_in(tree: SceneTree) -> Carryable:
	return tree.get_first_node_in_group(GROUP) as Carryable


func _ready() -> void:
	add_to_group(GROUP)
	if si_ricorda:
		add_to_group(MemoriaDelMondo.GRUPPO)
	# SOLO IL LAYER DEGLI INTERAGIBILI, E NON QUELLO DEL MONDO — e questa riga vale
	# un paragrafo, perché la prima stesura ce li metteva tutti e due.
	#
	# Sul layer del MONDO il giocatore ci sbatte contro, e va bene finché si tratta
	# di spingere una scatola col piede. Il problema è quando ci si cammina SOPRA:
	# la capsula sale su un corpo alto dieci centimetri, il solutore trova una
	# compenetrazione verticale e la risolve nell'unico modo che ha — sparando in
	# aria il giocatore. Federico: «se ci cammino sopra faccio dei salti
	# pazzeschi». Non è un numero da tarare: è che un termos non deve essere un
	# gradino.
	#
	# Fuori dal layer del mondo il giocatore ci passa attraverso, il raggio
	# dell'interazione continua a trovarli (cerca mondo E interagibili), e loro
	# continuano a cadere sui piani e a sbattere sui muri, perché quello dipende
	# dalla MASCHERA e non dal layer. Si urtano anche fra loro: una tazza posata
	# sopra un'altra sta sopra.
	#
	# Il prezzo è il calcio: non si spostano più camminandoci dentro. Si spostano
	# prendendoli in mano, che è come si spostano le cose.
	collision_layer |= Interactable.LAYER_INTERACTABLE
	# E STA ANCHE NELLA COPIA DEL MONDO FATTA COME SI VEDE, che è dove vanno le
	# cose su cui ci si posa sopra: una tazza appoggiata su un'altra sta sopra
	# l'altra, e quello lo decide questo layer. Vedi più sotto la maschera.
	collision_layer |= Corazza.LAYER_APPOGGI
	if ostacolo_per_il_giocatore:
		collision_layer |= Interactable.LAYER_WORLD
	else:
		collision_layer &= ~Interactable.LAYER_WORLD
	# SI CADE SULLA GEOMETRIA VERA, NON SUGLI INGOMBRI. Il mondo ha due
	# collisioni: i blocchi grezzi, giusti per il corpo del giocatore, e i
	# triangoli delle mesh, giusti per le cose che ci si posano sopra. Un oggetto
	# che urtasse gli ingombri si fermerebbe sulla cima di una fila di sedie -
	# novanta centimetri, e sotto solo aria fra gli schienali. Vedi `corazza.gd`.
	# E NON SUI VOLUMI D'INTERAZIONE, che è la seconda metà della stessa regola e
	# la prima stesura non ce l'aveva. `Interactable` sta su `LAYER_INTERACTABLE`
	# con la forma che serve a essere MIRATO, e quella forma non è la cosa: il
	# letto ha un volume alto 1,05 - l'altezza della testiera, messa lì apposta
	# perché il raggio dell'occhio lo trovi (vedi `bed.tscn`) - mentre il materasso
	# su cui si dorme sta a 0,58. Con quel layer nella maschera, una tazza posata
	# sul letto si fermava sul volume: mezzo metro sopra le coperte, a mezz'aria.
	# Misurato da `tools/prova_appoggi.gd`.
	#
	# Gli altri oggetti si continuano a urtare perché adesso stanno anche loro
	# sugli APPOGGI, e i mobili veri continuano a fermare la roba perché la
	# corazza copre ogni mesh che si vede - monitor e ante comprese.
	collision_mask |= Corazza.LAYER_APPOGGI
	collision_mask &= ~(Interactable.LAYER_WORLD | Interactable.LAYER_INTERACTABLE)
	# IL SONNO SI TOGLIE SOLO IN MANO, e la prima stesura lo toglieva sempre.
	# `_integrate_forces` su un corpo addormentato non viene chiamato, quindi
	# mentre lo si tiene il sonno va escluso o la mano smette di funzionare da
	# sola dopo qualche secondo di immobilità. Ma tenerlo escluso SEMPRE vuol dire
	# che un oggetto appoggiato su un piano non si assesta mai del tutto: continua
	# a essere risolto ogni tick e conserva un tremito. Misurato — una tazza sulla
	# consolle, dopo tre secondi, andava ancora a 8 cm al secondo. Vedi `prendi()`
	# e `lascia()`, che lo tolgono e lo rimettono.
	# LA COLLISIONE SI GUARDA LUNGO IL PERCORSO, SEMPRE.
	#
	# Serve in mano, dove la mano spinge a sei metri al secondo contro un tramezzo
	# da dieci centimetri. E serve CADENDO, che e' la scoperta successiva: la
	# geometria vera su cui gli oggetti si posano (`corazza.gd`) e' fatta di
	# triangoli, cioe' di superfici a SPESSORE ZERO, e un corpo lasciato cadere da
	# un metro e mezzo arriva a nove centimetri per fotogramma. Misurato: senza
	# questa riga una sonda lasciata cadere sul carrello del proiettore ha
	# attraversato il carrello, il pavimento e le fondamenta, e si e' fermata a
	# ventitre metri sottoterra.
	#
	# ERA STATA TOLTA per curare una tazza che non si fermava mai, e non era lei:
	# la causa era la forma del suo collisore - un cilindro schiacciato (D-201).
	# Tolta l'ipotesi sbagliata, la riga puo' tornare dove serve.
	continuous_cd = true
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
	angular_damp = SMORZAMENTO_GIRO
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
	_mirando = Vector3.INF
	# Presa in mano è toccata, e la fermata dopo averla posata conta anche se è la prima.
	_toccata = true
	_assestata = true
	# Un teletrasporto non ancora eseguito non la deve strappare dalla mano.
	_da_teletrasportare = false
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
	# LA VELOCITÀ NON SI AZZERA: l'oggetto se ne va con quella che aveva in mano.
	# Girarsi di scatto e mollare lo scaglia, posarlo fermo lo posa. Il lancio
	# VOLUTO, a barra piena, è un'altra cosa e sta in `lancia()`.
	gravity_scale = 1.0
	# E il sonno torna, insieme alla collisione normale: posato su un piano, questo
	# oggetto deve poter smettere di essere calcolato invece di tremare per tutta
	# la notte.
	can_sleep = true
	if _chi != null:
		remove_collision_exception_with(_chi)
		_chi = null
	posato.emit()


## LANCIATO: mollato con una spinta lungo `verso`. `trascinamento` è la velocità di
## chi lancia — correndo, la cosa parte anche con quella, come nella vita.
##
## PASSA DA `lascia()` E NON LO RIFÀ, perché le sottoclassi lo estendono: la stampa
## annuncia di essere cambiata, e un lancio che la saltasse lascerebbe il registro
## delle foto convinto che sia ancora in mano.
func lancia(verso: Vector3, trascinamento := Vector3.ZERO) -> void:
	if not _in_mano:
		return
	lascia()
	verso = verso.normalized()
	var v := VELOCITA_LANCIO / sqrt(maxf(mass, MASSA_BRACCIO))
	linear_velocity = verso * v + trascinamento
	if lancio_senza_giro:
		return
	# L'ASSE È IL FIANCO DI CHI LANCIA, e `UP × verso` fa girare la cima in avanti,
	# che è il verso del polso. Tirando dritto in su o in giù il fianco non esiste
	# più, e un asse qualunque orizzontale va bene uguale.
	var asse := Vector3.UP.cross(verso)
	if asse.length() < 0.1:
		asse = Vector3.RIGHT
	asse = asse.normalized().rotated(verso, randf_range(-ASSE_CASO, ASSE_CASO))
	angular_velocity = asse * GIRO_LANCIO * randf_range(1.0 - GIRO_CASO, 1.0 + GIRO_CASO)
	angular_damp = 0.0
	_in_volo = true


## Dove la mano lo vuole, adesso. La chiama chi lo tiene, dal proprio
## `_physics_process`: gira prima del passo di fisica, quindi `_integrate_forces`
## legge sempre un valore di questo tick e non di quello prima.
##
## `testa` è la camera di chi lo tiene. Qui non serve; serve a chi fa un gesto verso la
## faccia, come la tazza che si beve.
func punta(mano: Transform3D, _testa := Transform3D.IDENTITY) -> void:
	_mano = mano


## Il punto che chi lo tiene sta guardando, o `Vector3.INF`.
##
## SERVE A CHI SI POSA IN UN POSTO PRECISO, e la moka l'ha dimostrato: la prima stesura la
## metteva sul fuoco più vicino alla MANO, e da in piedi davanti al bancone la mano sta
## venticinque centimetri oltre il bordo — sopra nessun fuoco, da nessun punto della cucina.
## Chi mette una moka sul fuoco guarda il fuoco, e il fuoco giusto è quello guardato.
func mira(punto: Vector3) -> void:
	_mirando = punto


func punto_mirato() -> Vector3:
	return _mirando


## PORTALA LÌ, FERMA — e dentro il passo di fisica (D-245).
##
## `global_transform = …` SU UN CORPO RIGIDO NON BASTA, e l'ha dimostrato la moka: messa sul
## fuoco con E tornava alla mano e cadeva per terra, anche con la riga «Metti la moka sul
## fuoco» a schermo. L'assegnazione arriva al motore solo quando la scena smaltisce i cambi
## di trasformata; se prima cade un passo di fisica, il motore riscrive sul nodo la posizione
## che conosce lui — quella vecchia — e vince. Misurato con `tools/prova_moka_fuochi.gd`:
## con un passo per fotogramma o meno la moka restava sul fuoco, con cinque passi per
## fotogramma tornava alla mano su tutti e quattro i fuochi.
##
## IL POSTO GIUSTO È `_integrate_forces`, dove lo stato è quello del motore. Si assegna
## ANCHE il nodo, subito: chi chiede dov'è nello stesso fotogramma deve già vederla lì.
func teletrasporta(xf: Transform3D) -> void:
	_teletrasporto = xf
	_da_teletrasportare = true
	global_transform = xf
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = false


## C'è qualcosa di nuovo da ricordare, e l'ha fatto il giocatore (D-243). Le sottoclassi la
## chiamano anche quando cambia quello che hanno dentro — la moka col caffè, la tazza piena —
## senza essersi mosse: una tazza riempita sul tavolo senza spostarla va ricordata piena.
func _annuncia() -> void:
	_toccata = true
	cambiato.emit()


# ---------------------------------------------------------------------------
# QUELLO CHE SI FA CON UNA COSA IN MANO (D-244)
# ---------------------------------------------------------------------------
#
# Di base niente: E posa, il destro non fa niente. Chi sa fare qualcosa lo dice
# sovrascrivendo questi metodi — il giocatore chiede e non nomina nessuno, come per
# `posa()`. Oggi la moka versa nella tazza, e la tazza si beve.

## Mirando `bersaglio` con questa in mano, se E ci fa qualcosa invece di posare.
func puo_usare_su(_bersaglio: Object) -> bool:
	return false


## La riga che lo dice, al posto di «Posa…».
func prompt_usa_su(_bersaglio: Object) -> String:
	return ""


func usa_su(_bersaglio: Object) -> void:
	pass


## Col destro, senza bisogno di mirare niente: se la cosa in mano si usa da sola.
func puo_usare() -> bool:
	return false


func prompt_usa() -> String:
	return ""


func usa() -> void:
	pass


## Se sta facendo un gesto — versare, bere — durante il quale la mano non la muove il
## giocatore, e nessun tasto deve interromperlo posandola o lanciandola.
func in_gesto() -> bool:
	return false


## Cosa questa cosa vuole ritrovare dopo un riavvio (D-243): dove sta. Chi ha anche un
## contenuto — la moka il caffè, la tazza quanto è piena — ci aggiunge il suo.
##
## VUOTO SE NESSUNO L'HA MAI TOCCATA, e la memoria del mondo non ne scrive la voce: una cosa
## mai toccata sta dove la mette la scena, anche quando la scena cambia.
##
## NON SI CHIAMA `ricordo()`, e il nome ovvio l'ha già preso la stampa: `Stampa.ricordo(radice)`
## è la voce del registro delle foto, con un argomento, e in GDScript una sottoclasse non
## può ridefinire un metodo con un'altra firma. La stampa smetteva di compilare, e con lei
## la stampante.
func stato_da_ricordare() -> Dictionary:
	if not _toccata:
		return {}
	return {&"xf": global_transform}


## Rimette quello che `stato_da_ricordare()` aveva scritto. FERMA: una cosa ritrovata non
## riparte con la velocità che aveva quando si è chiuso il gioco.
func torna_come_ricordato(voce: Dictionary) -> void:
	if voce.has(&"xf"):
		_toccata = true
		global_transform = voce[&"xf"]
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO


# ---------------------------------------------------------------------------
# LA RETE: una cosa caduta si ritrova
# ---------------------------------------------------------------------------

## QUANDO SCATTA: appena la cosa è ferma, e una volta sola per fermata. Non mentre
## rotola — «da qui ci si arriva?» ha senso solo su qualcosa che ha finito di
## muoversi — e non a ogni tick, che costerebbe trenta interrogazioni allo spazio
## sessanta volte al secondo.
func _physics_process(delta: float) -> void:
	# IL VOLO FINISCE AL PRIMO URTO, o se qualcuno la riprende al volo: da lì in poi
	# la cosa si deve poter fermare, e lo smorzamento del giro torna.
	if _in_volo and (get_contact_count() > 0 or _fuori_dalla_rete()):
		_in_volo = false
		angular_damp = SMORZAMENTO_GIRO
	var in_moto := _fuori_dalla_rete() or linear_velocity.length() > 0.05
	if in_moto:
		_mosso = true
	if si_puo_perdere or in_moto:
		_quieta_da = 0.0
		_gia_guardata = false
		# IN MANO O CONGELATA IL CONTO SI AZZERA: qualcuno l'ha presa e messa
		# dove voleva, e i tentativi di prima non c'entrano piu' niente.
		if _fuori_dalla_rete():
			_ripescaggi = 0
		return
	# E SI RIGUARDA SE NEL FRATTEMPO E' STRISCIATA VIA. «Ferma» qui vuol dire
	# sotto i cinque centimetri al secondo, e una cosa che striscia a quattro
	# centimetri al secondo per due secondi se ne va di otto: abbastanza da
	# passare dal calpestio al fondo del pozzo. Guardata una volta sola, la rete
	# rispondeva sulla posizione di prima. Misurato: due pose su dieci in
	# `prova_ccd.gd` finivano irraggiungibili senza che la rete avesse detto
	# niente, perche' quando aveva guardato la camera era ancora sull'impalcato.
	if _gia_guardata and global_position.distance_to(_dove_guardata) > 0.05:
		_gia_guardata = false
		_quieta_da = 0.0
	if _gia_guardata:
		return
	_quieta_da += delta
	if _quieta_da >= QUIETE:
		_gia_guardata = true
		_dove_guardata = global_position
		_rete_di_sicurezza()
		# E SE SI ERA MOSSA, LA CASA SE NE RICORDA (D-243). Qui, a cosa ferma e dopo la
		# rete, e non posandola: posata rimbalza, e la rete può ancora spostarla di un
		# palmo.
		#
		# LA PRIMA FERMATA NON CONTA. La scena posa le cose un millimetro sopra i piani,
		# e all'avvio cadono tutte di quel millimetro: la prima stesura lo prendeva per
		# uno spostamento, e al primo avvio della partita vera la casa si è ricordata la
		# posizione di ogni tazza e ogni bottiglia. Innocuo quel giorno, e un guaio il
		# giorno in cui si sposta un mobile nel generatore: le cose mai toccate
		# resterebbero inchiodate al posto vecchio.
		if _mosso:
			_mosso = false
			if _assestata:
				_annuncia()
		_assestata = true


## Quando la rete non deve nemmeno guardare. Qui basta «in mano o congelata»; la
## camera CCD ci aggiunge «avvitata al fuoco», che è il suo modo di stare ferma.
func _fuori_dalla_rete() -> bool:
	return in_mano() or freeze


## SI CHIEDE AL MONDO invece di elencare i posti brutti — è la regola del D-217, e
## il motivo per cui questa rete non invecchia con la pianta dell'edificio. La
## fessura dietro il rack è quella che l'ha fatta nascere, ma la stessa domanda
## copre l'armadio di domani e il mobile che qualcuno sposterà.
func _rete_di_sicurezza() -> void:
	if si_riesce_a_prendere():
		_ripescaggi = 0
		return
	var dove := _posto_da_cui_si_prende()
	if dove == Vector3.INF or _ripescaggi >= RIPESCAGGI_MAX:
		_perduta()
		return
	_ripescaggi += 1
	Log.info("presa", "%s era finita dove non ci si arriva (%.2f, %.2f, %.2f): "
		% [nome, global_position.x, global_position.y, global_position.z]
		+ "spostata di %.0f cm" % (global_position.distance_to(dove) * 100.0))
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position = dove


## L'ULTIMA SPIAGGIA, quando neanche un posto buono esiste. Qui non si fa niente:
## una tazza dimenticata sotto un armadio è una tazza dimenticata, e spostarla in
## un'altra stanza sarebbe più strano che lasciarla lì. La camera CCD sovrascrive
## — senza di lei la partita non può più finire, e per lei si torna al fuoco.
func _perduta() -> void:
	Log.info("presa", "%s è ferma dove non ci si arriva (%.2f, %.2f, %.2f) e non c'è "
		% [nome, global_position.x, global_position.y, global_position.z]
		+ "un posto migliore entro un metro")


## IL POSTO BUONO PIÙ VICINO: anelli via via più larghi attorno a dov'è, e per
## ciascun candidato si chiede due cose — che la cosa ci STIA (niente geometria
## addosso) e che da lì la si POSSA prendere. Si scende sul pavimento con un
## raggio invece di tenere la quota: la fessura in cui è rotolata e il pavimento
## di fianco non sono sempre alla stessa altezza.
func _posto_da_cui_si_prende() -> Vector3:
	var spazio := get_world_3d().direct_space_state
	var alto := _centro().y - global_position.y
	for d in RIPESCAGGIO:
		for k in VERSI:
			var ang := TAU * float(k) / float(VERSI)
			var x: float = global_position.x + cos(ang) * (d as float)
			var z: float = global_position.z + sin(ang) * (d as float)
			var giu := PhysicsRayQueryParameters3D.create(
				Vector3(x, global_position.y + 0.6, z),
				Vector3(x, global_position.y - 1.2, z))
			giu.collision_mask = Corazza.LAYER_APPOGGI
			giu.exclude = [get_rid()]
			var suolo := spazio.intersect_ray(giu)
			if suolo.is_empty():
				continue
			var base: Vector3 = suolo["position"]
			if not _ci_sta(spazio, base):
				continue
			if si_riesce_a_prendere(base + Vector3.UP * alto):
				return base
	return Vector3.INF


## La cosa ci sta, in quel punto? Si prova la sua stessa forma contro la geometria
## vera: rimetterla dentro un mobile sarebbe peggio di lasciarla nella fessura.
func _ci_sta(spazio: PhysicsDirectSpaceState3D, base: Vector3) -> bool:
	for f in get_children():
		var forma := f as CollisionShape3D
		if forma == null:
			continue
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = forma.shape
		# LA POSA SI TIENE: una bottiglia coricata resta coricata, e provarla in
		# piedi direbbe che non ci sta dove invece ci sta.
		#
		# E SI ALZA DI UN CENTIMETRO, che è lo stesso inciampo del `FRANCO_SUOLO`
		# della capsula: posata esattamente sul punto colpito dal raggio, la forma
		# TOCCA il pavimento che l'ha fermata e `intersect_shape` risponde
		# «occupato» per ogni posto della casa. Misurato: senza questo centimetro
		# la rete non trovava un posto buono da nessuna parte, e ogni cosa finiva
		# dichiarata perduta.
		q.transform = Transform3D(forma.global_basis,
			base + forma.global_position - global_position + Vector3.UP * 0.01)
		q.collision_mask = Corazza.LAYER_APPOGGI
		q.exclude = [get_rid()]
		q.margin = 0.0
		if not spazio.intersect_shape(q, 1).is_empty():
			return false
	return true


## C'È UN POSTO DA CUI PRENDERLA? Ci si sta con la capsula del giocatore, la si
## vede senza mondo in mezzo, ed è dentro la portata dell'interazione — da in
## piedi o accovacciati, che è come si raccoglie una cosa da terra.
##
## I PIEDI SI CERCANO A PIÙ PIANI. Il raggio che scende cercando il pavimento si
## ferma sul PRIMO corpo che trova, e il primo corpo può essere la cima di un
## mobile o il tappo del pozzo della cupola: da lassù non ci si arriva, e la
## funzione concludeva che non ci si arriva da nessuna parte. Si scende di piano
## in piano e ci si ferma sul primo su cui una persona ci sta davvero.
func si_riesce_a_prendere(bersaglio := Vector3.INF) -> bool:
	var spazio := get_world_3d().direct_space_state
	if bersaglio == Vector3.INF:
		bersaglio = _centro()
	for d in GIRO:
		for k in VERSI:
			var ang := TAU * float(k) / float(VERSI)
			var x: float = bersaglio.x + cos(ang) * (d as float)
			var z: float = bersaglio.z + sin(ang) * (d as float)
			var scartati: Array[RID] = []
			for _strato in STRATI_SUOLO:
				var giu := PhysicsRayQueryParameters3D.create(
					Vector3(x, bersaglio.y + 1.2, z),
					Vector3(x, bersaglio.y - 2.5, z))
				giu.collision_mask = Interactable.LAYER_WORLD
				giu.exclude = scartati
				var suolo := spazio.intersect_ray(giu)
				if suolo.is_empty():
					break
				scartati.append(suolo["rid"])
				if _ci_si_arriva(spazio, suolo["position"], bersaglio):
					return true
	return false


## Stando con i piedi lì, la cosa si raccoglie? Si prova prima in piedi e poi
## accovacciati: sono due corpi diversi, e quello basso arriva dove l'alto non
## entra. E la capsula è quella giusta per la posa — in piedi si guarda con
## l'occhio in piedi e l'ingombro in piedi, o ogni posto sotto un ripiano
## risulterebbe inagibile.
##
## LA VISTA SI CHIEDE AL LAYER DEL MONDO, che è quello che occlude il raggio del
## giocatore (vedi `player.gd`, `_ray.collision_mask`). Prima si chiedeva alla
## CORAZZA, cioè alla geometria che si VEDE, e sono due cose diverse: sotto una
## scrivania la corazza lascia passare — lì sotto c'è aria — mentre l'ingombro è
## una scatola piena, e il raggio del giocatore ci sbatte. Una cosa lì sotto
## risultava prendibile e non lo era.
func _ci_si_arriva(spazio: PhysicsDirectSpaceState3D, piedi: Vector3,
		bersaglio: Vector3) -> bool:
	for in_piedi in [true, false]:
		var alto: float = Player.STAND_HEIGHT if in_piedi else Player.CROUCH_HEIGHT
		var occhio: float = Player.EYE_HEIGHT if in_piedi else Player.CROUCH_EYE_HEIGHT
		var testa := piedi + Vector3.UP * occhio
		if testa.distance_to(bersaglio) > Player.INTERACT_RANGE:
			continue
		var capsula := CapsuleShape3D.new()
		capsula.radius = 0.30
		capsula.height = alto
		var dove := PhysicsShapeQueryParameters3D.new()
		dove.shape = capsula
		dove.transform = Transform3D(Basis.IDENTITY,
			piedi + Vector3.UP * (alto / 2.0 + FRANCO_SUOLO))
		dove.collision_mask = Interactable.LAYER_WORLD
		if not spazio.intersect_shape(dove, 1).is_empty():
			continue
		var vista := PhysicsRayQueryParameters3D.create(testa, bersaglio)
		vista.collision_mask = Interactable.LAYER_WORLD
		if not spazio.intersect_ray(vista).is_empty():
			continue
		# E CI SI DEVE POTER ANDARE. È l'ultima domanda perché è la più cara, e
		# perché ha senso solo su un posto che ha già passato tutte le altre.
		if _e_un_isola(spazio, piedi, alto):
			continue
		return true
	return false


## QUEL PEZZO DI PAVIMENTO È UN'ISOLA? Si allaga il camminabile a partire dai
## piedi, a maglia di venti centimetri, e ci si ferma appena il conto supera
## `ISOLA_MAX`: da lì in poi è una stanza, e quanto sia grande non interessa.
##
## SI ALLAGA CON LA STESSA CAPSULA con cui ci si è appena provati a stare: in
## piedi si cammina dove si sta in piedi, accovacciati dove si sta accovacciati.
func _e_un_isola(spazio: PhysicsDirectSpaceState3D, piedi: Vector3, alto: float) -> bool:
	var tetto := int(ISOLA_MAX / (MAGLIA * MAGLIA))
	var quote := {Vector2i.ZERO: piedi.y}
	var coda: Array[Vector2i] = [Vector2i.ZERO]
	var quante := 0
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.30
	capsula.height = alto
	var dove := PhysicsShapeQueryParameters3D.new()
	dove.shape = capsula
	dove.collision_mask = Interactable.LAYER_WORLD
	while not coda.is_empty():
		var v: Vector2i = coda.pop_back()
		quante += 1
		if quante > tetto:
			return false
		var y0: float = quote[v]
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = v + d
			if quote.has(q):
				continue
			var x := piedi.x + q.x * MAGLIA
			var z := piedi.z + q.y * MAGLIA
			var giu := PhysicsRayQueryParameters3D.create(
				Vector3(x, y0 + GRADINO + 0.05, z), Vector3(x, y0 - GRADINO - 0.05, z))
			giu.collision_mask = Interactable.LAYER_WORLD
			var suolo := spazio.intersect_ray(giu)
			if suolo.is_empty():
				quote[q] = NAN            # niente pavimento: di là non si va
				continue
			var p: Vector3 = suolo["position"]
			dove.transform = Transform3D(Basis.IDENTITY,
				p + Vector3.UP * (alto / 2.0 + FRANCO_SUOLO))
			if not spazio.intersect_shape(dove, 1).is_empty():
				quote[q] = NAN
				continue
			quote[q] = p.y
			coda.append(q)
	return true


## IL CENTRO DEL CORPO, che NON è la sua origine: quasi tutte queste cose hanno
## l'origine sulla BASE, cioè nel punto in cui toccano il piano su cui stanno.
## Puntarci il raggio della vista vorrebbe dire puntare al pavimento — il raggio
## arriva sul pavimento un attimo prima della cosa, la vista risulta ostruita, e
## una cosa posata benissimo viene dichiarata perduta.
##
## SI CHIEDE AL COLLISORE dov'è il proprio centro, invece di scrivere qui un
## numero: il giorno che il modello cambia, questo continua a valere.
func _centro() -> Vector3:
	for f in get_children():
		if f is CollisionShape3D:
			return (f as CollisionShape3D).global_position
	return global_position


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
	if _da_teletrasportare:
		_da_teletrasportare = false
		state.transform = _teletrasporto
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		return
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
