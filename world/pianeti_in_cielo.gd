## I PIANETI IN SCENA: quali si vedono stanotte, dove, e quanto forte.
##
## COSA FA, IN UNA RIGA: chiede a `core/pianeti.gd` dove sono i cinque pianeti a
## quest'ora, decide quanta luce ne arriva davvero e la passa allo shader del
## cielo — che li disegna e basta, senza sapere quale sia quale.
##
## È IL GEMELLO DI `luce_di_luna.gd`, con una differenza: la Luna è anche una
## LAMPADA, i pianeti no. Venere al massimo splendore fa un'ombra su una spiaggia
## deserta e niente di più; qui non illuminano nulla, non proiettano nulla, e per
## questo questo nodo è un `Node` e non una luce.
##
## LA DOMANDA VERA NON È DOVE SONO, È SE SI VEDONO. Le posizioni sono
## astronomia e stanno in `core/`; qui sta l'altra metà, che è ottica e
## atmosfera: un pianeta è visibile se è sopra l'orizzonte, se l'aria che deve
## attraversare non se lo mangia, e se il cielo attorno a lui non è più chiaro di
## lui. Tre condizioni, e quasi mai le rispettano tutti e cinque insieme.
##
##   1. L'ORIZZONTE. Sotto, non c'è: è la Terra di mezzo. Vale per più della
##      metà del cielo a ogni ora, ed è da sola la ragione per cui in questo
##      gioco Mercurio non si vede mai — sta sempre vicino al Sole, e quando il
##      Sole è tramontato da tre ore lo è anche lui.
##   2. L'ARIA. Guardando all'orizzonte si guarda attraverso trentotto volte
##      l'aria che si attraversa allo zenit, e ogni passaggio costa luce. Non è
##      una sfumatura grafica: è la ragione per cui un pianeta che sta
##      tramontando si spegne prima di toccare il profilo delle colline, e
##      chiunque abbia aspettato Venere all'orizzonte l'ha visto succedere.
##   3. IL FONDO. Una luce si vede se è più forte di quello che le sta attorno.
##      Con la luna piena alta il cielo è lattiginoso e restano solo le cose
##      forti — le stelle lo sanno già fare in questo shader, e i pianeti devono
##      saperlo allo stesso modo o si vedrebbe un pianeta debole in un cielo in
##      cui non si vede nessuna stella.
##
##      E LA LUNA NON SPEGNE UN PIANETA, ALZA IL PAVIMENTO: Giove con la luna
##      piena si vede uguale, perché sta quattro magnitudini sopra il limite
##      anche allora. L'effetto si vede DOVE IL PIANETA È GIÀ VICINO AL LIMITE,
##      cioè in basso, dove l'aria gli ha già preso due o tre magnitudini: con
##      la luna piena un pianeta tramonta — smette di vedersi — cinque gradi più
##      in alto di come farebbe col cielo buio. Chi ha aspettato un pianeta
##      basso in una notte di luna sa che è così che va a finire.
##
## E NON C'È NESSUNA REGOLA CHE DICA CHI SI VEDE. Non esiste da nessuna parte una
## riga tipo «Giove sì, Mercurio no»: ci sono un'orbita, una magnitudine e tre
## conti, e l'elenco di stanotte esce da lì. È lo stesso patto della Luna: il
## calendario decide, non il programmatore.
##
## IL CIELO DEL MESE DI LAVORO, misurato (`tools/prova_pianeti.gd`), sulla prima
## notte: Giove e Saturno già a cinquanta gradi d'altezza a sud-est quando il
## turno comincia — erano all'opposizione da poche settimane — che scendono a
## ovest e tramontano alle 4:50 e alle 6:08; Venere che sorge alle 3:07 e si
## VEDE dalle quattro, perché la prima ora la passa nell'aria spessa
## dell'orizzonte (è il punto 2 qui sopra, e si vede succedere); Marte che
## tramonta alle 20:32, mezz'ora prima che il turno cominci, e quindi non si
## vede mai; Mercurio mai. Su novanta momenti del mese — trenta notti a tre ore
## — si vedono: Saturno 71 volte, Giove 60, Venere 30, Marte e Mercurio zero.
class_name PianetiInCielo
extends Node

## Chi ha bisogno dei pianeti li trova per GRUPPO, mai per percorso di nodo:
## stessa regola della Luna, del tempo siderale e della cupola (D-196).
const GROUP := &"pianeti"

## IL COLORE DI CIASCUNO A OCCHIO NUDO, nell'ordine di `Pianeti.ORDINE`.
##
## POCO SATURI, e non per timidezza: a occhio nudo un pianeta è quasi bianco.
## Marte è l'unico che chiunque descriva come «rosso» — e infatti è il solo che
## qui si stacca davvero — Saturno tende al giallo paglia, Giove e Venere sono
## bianchi con un filo di caldo, Mercurio è più grigio. Sono gli indici di colore
## dei cataloghi (B−V fra 0,8 e 1,4) portati a una tinta: un cielo con cinque
## puntini colorati come caramelle sarebbe la cosa più falsa di tutta la scena.
##
## E ARRIVANO ALLO SHADER COME NUMERI LINEARI, non come colori da schermo: un
## indice di colore è un RAPPORTO FRA FLUSSI, e i flussi si sommano in lineare —
## che è anche l'unico spazio in cui il resto di questo cielo lavora. Godot non
## converte gli array di uniform, quindi qui non c'è niente da correggere: i tre
## numeri passano com'è giusto che passino.
const COLORI := {
	&"mercurio": Color(1.00, 0.94, 0.84),
	&"venere": Color(1.00, 0.98, 0.94),
	&"marte": Color(1.00, 0.70, 0.50),
	&"giove": Color(1.00, 0.96, 0.88),
	&"saturno": Color(1.00, 0.92, 0.74),
}

## LA MAGNITUDINE CHE VALE «UNO» sullo schermo, e la luce che le corrisponde.
##
## Serve un aggancio fra la scala degli astronomi e i numeri di uno shader, e
## questo è quello scelto: un oggetto di prima magnitudine — una stella fra le
## più luminose del cielo — vale 1,0, cioè quanto il nucleo della stella più
## forte che `strato()` disegna. Sotto questa riga i pianeti si confondono con le
## stelle, sopra si staccano: che è esattamente come funziona il cielo vero.
const MAG_RIFERIMENTO := 1.0
const LUCE_RIFERIMENTO := 1.0

## QUANTO SI COMPRIME LA SCALA DELLE LUMINOSITÀ, ed è una bugia dichiarata come
## quella della frazione illuminata della Luna.
##
## IL RAPPORTO VERO È MOSTRUOSO. Fra Venere (−4,3) e Saturno (+0,2) ci sono
## quattro magnitudini e mezzo, cioè SESSANTA VOLTE la luce; fra Venere e una
## stella al limite dell'occhio ce ne sono dieci, cioè diecimila volte. Su uno
## schermo che arriva al bianco e poi si ferma, sessanta volte vuol dire che
## Venere è una macchia bianca larga mezzo dito e Saturno non esiste: il rapporto
## vero, disegnato, cancella tutto tranne il primo della classe.
##
## A 0,30 le stesse quattro magnitudini e mezzo diventano un fattore quattro:
## Venere resta chiaramente la più forte, ha il suo alone, e Saturno si vede
## lo stesso. È la compressione che fa l'occhio, che è logaritmico, e che una
## fotografia non fa.
const COMPRESSIONE := 0.30

## QUANTA LUCE MANGIA L'ARIA, in magnitudini per massa d'aria.
##
## Zero e venticinque è un cielo di montagna sereno, che è quello che questo
## osservatorio ha (in pianura si sta sopra 0,35). Vuol dire: un quarto di
## magnitudine persa guardando allo zenit, mezza a trenta gradi, due e mezza a
## cinque gradi, NOVE a un grado dall'orizzonte. Le ultime due sono il motivo per
## cui questa costante esiste: senza, un pianeta resterebbe luminoso uguale fino
## all'istante in cui sparisce sotto il profilo delle colline, e non è così che
## si vede tramontare niente.
const ESTINZIONE := 0.25

## FIN DOVE ARRIVA L'OCCHIO, in magnitudini: col cielo buio e con la luna piena.
##
## Il limite vero di un occhio adattato sotto un cielo di montagna è la sesta
## magnitudine, e con la luna piena scende attorno alla quarta. Qui il buio vale
## cinque e non sei perché questo cielo è disegnato più scuro del vero (vedi
## l'intestazione dello shader): tenere il limite reale significherebbe mostrare
## pianeti che nel cielo disegnato sarebbero sotto la soglia di visibilità dello
## schermo, cioè puntini che ci sono e non si vedono.
##
## IL SECONDO NUMERO È IL CHIARO DI LUNA, e non sparisce nel nulla: è lo stesso
## `contributo` che comanda l'energia della lampada e quante stelle restano in
## cielo. Se un giorno una luna piena lasciasse le stelle spente e i pianeti
## intatti, sarebbe questa riga a non essere stata letta.
const LIMITE_BUIO := 5.0
const LIMITE_LUNA := 2.5

## DI QUANTE MAGNITUDINI SI DISSOLVE prima di sparire del tutto. Un gradino
## secco — visibile a 4,9 e assente a 5,1 — si vedrebbe come un puntino che si
## spegne di colpo mentre il cielo non cambia, che è il difetto che si nota di
## più fra tutti quelli possibili qui.
const SFUMATURA := 1.5

## L'ALTEZZA SOTTO LA QUALE NON SI DISEGNA PIÙ NIENTE, in gradi, e la fascia in
## cui si sfuma. Sotto zero c'è la Terra; la sfumatura parte appena sopra perché
## l'aria (vedi `ESTINZIONE`) ha già fatto quasi tutto il lavoro, e quello che
## resta è impedire che l'ultimo pixel si spenga di scatto.
const ALTEZZA_SOTTO := -0.3
const ALTEZZA_SOPRA := 1.2

## Il nodo che porta l'ambiente col cielo dentro. Stessa proprietà, stesso
## significato e stessa scrittura di `TempoSiderale` e di `LuceDiLuna`: tre nodi
## che scrivono sullo stesso materiale, ciascuno con la propria strada per
## arrivarci, perché nessuno dei tre deve dipendere dagli altri.
@export var ambiente: NodePath

## A VERO SI DISEGNANO TUTTI E CINQUE SEMPRE, orizzonte e aria ignorati, tutti
## alla stessa luce.
##
## È IL DIFETTO CHE SI RIMETTE, ed è quello che dice se questo nodo sta
## misurando quello che crede: `tools/prova_pianeti.gd` con `TUTTI=1` deve
## trovare cinque pianeti accesi anche a mezzanotte, tre dei quali sotto i piedi.
## Se con l'interruttore non cambiasse niente, vorrebbe dire che la selezione non
## sta selezionando.
@export var tutti := false

var _mat: ShaderMaterial
var _dati: Array[Dictionary] = []
var _luci := PackedFloat32Array()
var _luna: LuceDiLuna
## L'ultimo istante scritto, come (notte, minuti). La notte ci sta dentro per la
## stessa ragione per cui ci sta nella Luna: `elapsed_min` vale 0 tanto alla fine
## di una notte quanto all'inizio della successiva, e senza l'indice il primo
## fotogramma di ogni notte mostrerebbe il cielo di ieri.
var _istante_scritto := Vector2(-1.0, INF)


func _ready() -> void:
	add_to_group(GROUP)
	var we := get_node_or_null(ambiente) as WorldEnvironment
	var sky: Sky = we.environment.sky if we != null and we.environment != null else null
	_mat = sky.sky_material as ShaderMaterial if sky != null else null
	if _mat == null:
		# SI GRIDA E CI SI FERMA, al contrario della Luna: la Luna senza cielo fa
		# comunque la luce della notte, questo nodo senza cielo non fa
		# assolutamente niente — e dirlo è l'unico modo perché qualcuno se ne
		# accorga, visto che il sintomo sarebbe un cielo senza pianeti, che
		# assomiglia moltissimo a un cielo normale.
		push_error("[system] pianeti: non trovo il materiale del cielo (%s)" % ambiente)
		return
	# I COLORI SI SCRIVONO UNA VOLTA SOLA: non cambiano con l'ora, con la notte né
	# con niente. Marte è rosso anche quando è tramontato.
	var tinte := PackedVector3Array()
	for nome in Pianeti.ORDINE:
		var c: Color = COLORI[nome]
		tinte.append(Vector3(c.r, c.g, c.b))
	_mat.set_shader_parameter("pianeta_tinta", tinte)
	_aggiorna(true)


## OGNI FOTOGRAMMA, come la Luna e per la stessa ragione: rispetto all'orizzonte
## un pianeta si muove di quindici gradi l'ora, cioè un pixel di questo schermo
## ogni cinquanta secondi di gioco. A saltare fotogrammi si vedrebbe un cielo che
## scatta mentre la Luna, accanto, scorre.
func _process(_delta: float) -> void:
	_aggiorna(false)


func _aggiorna(forza: bool) -> void:
	if _mat == null:
		return
	# Niente notte, niente calendario: la notte 1 alle 21:00, che è la prima sera
	# del gioco. Stessa scelta e stesso perché della Luna.
	var notte: int = Game.run.night_index if Game.run != null else 1
	var minuti: float = Game.run.elapsed_min if Game.run != null else 0.0
	var adesso := Vector2(float(notte), minuti)
	if not forza and adesso.is_equal_approx(_istante_scritto):
		return
	_istante_scritto = adesso

	_dati = Pianeti.effemeridi(Luna.istante(notte, minuti))

	# IL CHIARO DI LUNA LO CHIEDE ALLA LUNA, e non se lo ricalcola: è lo stesso
	# numero che comanda l'energia della lampada e quante stelle restano accese.
	# Averne una seconda copia qui vorrebbe dire poter avere una notte in cui le
	# stelle sono lavate e i pianeti no.
	#
	# SE LA LUNA NON C'È IN SCENA, il cielo si considera buio: è la risposta meno
	# sbagliata, ed è anche l'unica che non inventa una luna.
	if _luna == null:
		_luna = LuceDiLuna.find_in(get_tree())
	var chiarore := _luna.contributo() if _luna != null else 0.0

	var dirs := PackedVector3Array()
	_luci = PackedFloat32Array()
	for e in _dati:
		dirs.append(e[&"dir"])
		_luci.append(luce_di(e, chiarore) if not tutti else LUCE_RIFERIMENTO)
	_mat.set_shader_parameter("pianeta_dir", dirs)
	_mat.set_shader_parameter("pianeta_luce", _luci)


## QUANTA LUCE ARRIVA DAVVERO DA QUESTO PIANETA, adesso: zero se non si vede.
##
## È IL CUORE DEL FILE, e sono quattro righe di conto e tre di decisione. Si parte
## dalla magnitudine fuori dall'atmosfera — quella che sta sugli almanacchi, e
## che `core/pianeti.gd` calcola dalla geometria del sistema solare — le si somma
## quello che l'aria si mangia, e si guarda se quello che resta sta sopra il
## limite dell'occhio con il cielo che c'è stanotte.
##
## STATICA E PURA, perché così il banco può collaudarla senza montare una scena:
## stessa altezza, stessa magnitudine, stesso chiarore, stesso risultato.
static func luce_di(e: Dictionary, chiarore: float) -> float:
	var alt := float(e[&"alt"])
	if alt <= ALTEZZA_SOTTO:
		return 0.0
	# LA MAGNITUDINE VISTA DA QUI SOTTO: quella vera più l'aria attraversata.
	var m := float(e[&"magnitudine"]) + ESTINZIONE * massa_daria(alt)
	# Il limite dell'occhio stanotte, che la Luna alza.
	var limite := lerpf(LIMITE_BUIO, LIMITE_LUNA, clampf(chiarore, 0.0, 1.0))
	# LA CONVERSIONE IN LUCE: la scala delle magnitudini è logaritmica — ogni
	# passo vale 2,512 volte — e questa è la sua inversa, compressa.
	var luce := LUCE_RIFERIMENTO * pow(10.0, -0.4 * (m - MAG_RIFERIMENTO) * COMPRESSIONE)
	# Le due dissolvenze: il limite dell'occhio e il profilo dell'orizzonte.
	luce *= smoothstep(limite, limite - SFUMATURA, m)
	luce *= smoothstep(ALTEZZA_SOTTO, ALTEZZA_SOPRA, alt)
	return luce


## QUANTA ARIA C'È DI MEZZO, in multipli di quella che c'è allo zenit.
##
## È la formula di Kasten e Young (1989), e non il banale `1/sin(h)` che tutti
## scrivono: quello è giusto in alto e diverge all'orizzonte — a zero gradi darebbe
## aria infinita e magnitudine infinita — mentre l'atmosfera vera è curva, ed è
## spessa trentotto volte lo zenit e non di più. La differenza si vede solo dove
## conta, cioè negli ultimi cinque gradi, che sono esattamente quelli in cui un
## pianeta si spegne mentre tramonta.
static func massa_daria(alt_gradi: float) -> float:
	var h := maxf(alt_gradi, 0.0)
	return 1.0 / (sin(deg_to_rad(h)) + 0.50572 * pow(h + 6.07995, -1.6364))


## Le effemeridi che questo nodo sta usando ADESSO. Serve alle sonde.
func effemeridi() -> Array[Dictionary]:
	return _dati


## Quanta luce ha scritto per ciascuno, nell'ordine di `Pianeti.ORDINE`. Zero
## vuol dire «stanotte, a quest'ora, quello lì non si vede».
func luci() -> PackedFloat32Array:
	return _luci


## Quali si vedono adesso, per nome. È la risposta alla domanda che dà il titolo
## al file, e serve alle sonde — e un giorno a chi dovesse scriverlo sul monitor.
func visibili() -> PackedStringArray:
	var fuori := PackedStringArray()
	for i in _dati.size():
		if i < _luci.size() and _luci[i] > 0.0:
			fuori.append(String(_dati[i][&"scritto"]))
	return fuori


static func find_in(tree: SceneTree) -> PianetiInCielo:
	return tree.get_first_node_in_group(GROUP) as PianetiInCielo
