## LA LUNA IN SCENA: la direzionale che fa la luce di fondo della notte, e il
## disco che si vede in cielo. Sono la stessa cosa, e per questo stanno in un
## nodo solo.
##
## COSA FA, IN UNA RIGA: chiede a `core/luna.gd` dov'è la Luna stanotte, ci punta
## la direzionale, e passa allo shader del cielo quello che serve a disegnarla.
##
## PRIMA ERA UNA POSA SCRITTA A MANO. `gen_blockout.py` metteva la direzionale a
## un'inclinazione fissa con energia 0,22 (D-071, D-078): giusta per quello che
## doveva fare allora — un'ombra sul prato e un vetro attraverso cui si vede
## qualcosa — e falsa in due modi che si notano appena li si nomina. La luna
## stava a quarantatré gradi d'altezza ad AZIMUT TRENTA, cioè a nord-est: da
## questa latitudine la Luna lì non ci arriva mai. E non si muoveva: nove ore di
## notte con l'ombra ferma nello stesso punto, mentre il cielo sopra girava.
##
## L'ENERGIA È IL PUNTO, NON LA POSIZIONE. La richiesta era «la luna che fa la
## luce di fondo, e in base al calendario della dimensione giusta»: le due metà
## vanno insieme, perché una luna che si vede piena e illumina come una falce
## sarebbe peggio di nessuna delle due. Qui l'unico numero che conta —
## `_contributo`, frazione illuminata per seno dell'altezza — comanda insieme
## l'energia della lampada, quanto il fondo del cielo si schiarisce e quante
## stelle restano visibili. Non si possono contraddire perché sono lo stesso
## numero.
##
## LA LUCE È UNA SOLA, E NON PER RISPARMIO. Una direzionale con l'ombra è una
## mappa d'ombra, e servirebbero DUE lampade: la Luna, che un terzo del mese non
## c'è, e il chiarore del cielo, che c'è sempre. Invece di due mappe c'è una
## lampada che somma le due ENERGIE e prende UNA direzione — quella della Luna
## finché la Luna sta in cielo, lo zenit quando è tramontata.
##
## E IL PESO DELLA DIREZIONE È L'ALTEZZA, NON L'ENERGIA. È la correzione che la
## sonda ha imposto alla prima stesura: pesando con l'energia, una mezza luna
## bassa contava meno del fondo e la direzione veniva tirata di ventotto gradi
## verso l'alto — in cielo la luna a sud-ovest, per terra le ombre di una luce
## quasi allo zenit. Una Luna fioca fa comunque l'unica ombra netta della notte,
## quindi finché è sopra l'orizzonte comanda lei; il chiarore prende la direzione
## solo quando non c'è più nessuno a contraddirlo.
##
## IL FONDO NON SCENDE MAI A ZERO, ed è una decisione ripresa e non disfatta.
## D-078 ha stabilito che la luna vale 0,22 «perché di notte da una finestra si
## vede attraverso solo se dall'altra parte c'è qualcosa da vedere». Con un
## calendario vero, un terzo delle notti è senza Luna, e senza un fondo le
## vetrate tornerebbero lastre nere: il difetto che D-078 aveva chiuso, riaperto
## dal calendario. `ENERGIA_CIELO` è quel fondo, e non è un trucco — una notte
## serena in montagna ha comunque l'airglow, le stelle e il chiarore della valle,
## che è già dichiarato nello shader del cielo come inquinamento luminoso.
class_name LuceDiLuna
extends DirectionalLight3D

## Chi ha bisogno della Luna la trova per GRUPPO, mai per percorso di nodo:
## stessa regola del tempo siderale, della montatura e della cupola (D-196).
const GROUP := &"luna"

## QUANTO AGGIUNGE LA LUNA, a disco pieno e allo zenit. Si somma a `ENERGIA_CIELO`,
## quindi non è mai il totale — e allo zenit non ci arriva mai nessuno: da questa
## latitudine la Luna al massimo tocca i settantacinque gradi.
##
## LE NOTTI DI LUNA PIENA SONO PIÙ CHIARE DI PRIMA, ed è la metà voluta del
## cambiamento. Misurato da `tools/prova_luna.gd` sul mese di lavoro:
##
##     notte  8, luna piena a 64 gradi, all'una      0,444   <- la piu' chiara
##     notte  1, mezza luna a 24 gradi, alle 21:00   0,163
##     notte 20, novilunio, tutta la notte           0,070   <- la piu' buia
##
## contro lo 0,22 fisso e uguale di ieri. Una luna piena d'inverno alta in cielo
## fa vedere l'ora sull'orologio e stampa l'ombra della ringhiera sul prato; una
## notte di novilunio no, e non deve. Se le tre righe qui sopra dessero lo stesso
## numero, tutto questo file non servirebbe.
##
## E IL RAPPORTO FRA LA PIÙ CHIARA E LA PIÙ BUIA È SEI, non cento come nella
## realtà: il perché sta su `ENERGIA_CIELO` e sul commento della frazione
## illuminata in `_aggiorna()`.
const ENERGIA_LUNA := 0.42

## IL CHIARORE CHE RESTA SENZA LUNA. Vedi l'intestazione: è il pavimento sotto cui
## la notte non scende, e ha un motivo fisico prima che di gioco.
##
## E NON È «LA LUNA AL MINIMO»: fisicamente una notte senza luna è cento volte
## più buia di una notte di luna piena, non tre. Questo rapporto è compresso
## apposta, e sta scritto qui perché è una bugia dichiarata: al rapporto vero, a
## novilunio non si troverebbe la porta di casa.
const ENERGIA_CIELO := 0.07

## Il colore della Luna alta: freddo, come lo vede un occhio adattato al buio —
## la Luna vera è grigia e la luce che manda è quella del Sole, ma sotto la
## soglia dei coni il blu è l'unica cosa che si vede. È il colore che aveva la
## direzionale prima, e non cambia.
const COLORE_ALTA := Color(0.60, 0.68, 0.96)

## Il colore della Luna BASSA. La stessa aria che rende rosso il tramonto rende
## ambrata la luna che sorge, e sull'arco della notte è la cosa che dice, senza
## una scritta, che sta per tramontare.
const COLORE_BASSA := Color(0.94, 0.72, 0.50)

## Sopra questa altezza il colore non cambia più, in gradi.
const ALTEZZA_FREDDA := 22.0

## QUANTO SI DISEGNA PIÙ GRANDE DEL VERO, ed è la sola bugia geometrica di
## tutto questo lavoro. Sta scritta qui, in chiaro, invece che nascosta dentro
## un numero dello shader.
##
## IL CONTO CHE LA OBBLIGA. Il mondo si disegna in un `SubViewport` da 640×360
## (`main.tscn`, `stretch_shrink = 2`) con la camera del giocatore a 75 gradi di
## campo verticale. Mezzo grado di Luna vera su 75 gradi di schermo alto 360
## pixel fanno DUE PIXEL E MEZZO. In due pixel e mezzo non c'è nessuna fase: una
## falce, una gibbosa e una piena sono lo stesso quadratino bianco, e questo
## lavoro esiste per far vedere la differenza.
##
## QUATTRO, E PERCHÉ QUATTRO. Fa dieci pixel di disco, che è la misura minima in
## cui un terminatore si legge come una curva invece che come una scaletta —
## `tools/prova_luna.gd` stampa il conto in pixel per la risoluzione vera, così
## il giorno che il SubViewport cambi questo numero si ritara guardando un
## numero e non a occhio. Sopra il cinque comincia a sembrare la luna di un
## fondale, che è il difetto opposto e si nota di più.
##
## E IL RAPPORTO RESTA VERO, che è la parte che conta: il fattore è costante,
## quindi il cinque per cento fra perigeo e apogeo passa intatto. La luna piena
## del 22 dicembre 1999 — la più vicina del secolo, 357 mila chilometri — resta
## più grande di ogni altra dell'anno, esattamente come lo era.
const INGRANDIMENTO := 4.0

## LE DUE MAPPE DELLA LUNA VERA: la faccia (mosaico LRO) e le pendenze (quote
## LOLA). Le scarica e le prepara `tools/prendi_luna.py`, e non stanno nel
## repository come nessuna texture di questo progetto (assets/LEGGIMI.txt).
##
## SI CARICANO QUI E NON NELLA SCENA, e la ragione è un clone appena fatto: una
## `ext_resource` verso un file che non c'è è un errore all'apertura del mondo
## intero, mentre qui manca solo la faccia — la Luna resta una palla liscia con
## la fase giusta, e un avviso dice cosa lanciare.
const MAPPA_COLORE := "res://assets/textures/luna/colore.jpg"
const MAPPA_RILIEVO := "res://assets/textures/luna/rilievo.png"

## Il nodo che porta l'ambiente col cielo dentro. Lo scrive `gen_blockout.py`.
## Stessa proprietà, stesso significato e stessa scrittura di `TempoSiderale`:
## due nodi che scrivono sullo stesso materiale, ciascuno con la propria strada
## per arrivarci, perché nessuno dei due deve dipendere dall'altro.
@export var ambiente: NodePath

## A VERO LA LUNA TORNA COM'ERA: posa fissa, energia fissa, niente in cielo.
##
## È IL DIFETTO CHE SI RIMETTE, e c'è qualcosa che lo vede: `tools/prova_luna.gd`
## con `FISSA=1` deve trovare la stessa direzione a ogni ora della notte e la
## stessa energia in tutte le notti del mese. Se non cambiasse niente, quella
## sonda non starebbe misurando quello che crede.
@export var fissa := false

var _mat: ShaderMaterial
var _dati: Dictionary = {}
var _contributo := 0.0
## L'ultimo istante calcolato, come (notte, minuti). LA NOTTE CI STA DENTRO, e
## non è una precauzione teorica: con i soli minuti, cambiare notte all'ora zero
## lasciava la Luna di ieri: `elapsed_min` vale 0 tanto prima quanto dopo, e il
## confronto diceva «niente di nuovo». In gioco si sarebbe visto una volta sola,
## al primo fotogramma di ogni notte, che è anche il momento in cui nessuno
## guarda ancora il cielo — il guasto perfetto.
var _istante_scritto := Vector2(-1.0, INF)


func _ready() -> void:
	add_to_group(GROUP)
	shadow_enabled = true
	var we := get_node_or_null(ambiente) as WorldEnvironment
	var sky: Sky = we.environment.sky if we != null and we.environment != null else null
	_mat = sky.sky_material as ShaderMaterial if sky != null else null
	if _mat == null:
		# SI GRIDA MA NON CI SI FERMA, come fa il tempo siderale per la stessa
		# ragione: dove sta la Luna è un fatto del mondo e la lampada lo usa
		# comunque. Un disco che non si disegna è un guasto di resa; una notte
		# senza la luce giusta sarebbe un guasto di illuminazione, ed è peggio.
		push_error("[system] luna: non trovo il materiale del cielo (%s)" % ambiente)
	_carica_mappe()
	_aggiorna(true)


## OGNI FOTOGRAMMA, e non è spreco: la Luna si sposta di mezzo grado all'ora
## rispetto alle stelle e di quindici rispetto all'orizzonte, quindi in nove ore
## la lampada gira di sessantasei gradi (misurato). A saltare qualche fotogramma
## si guadagnerebbero quaranta operazioni di trigonometria e si perderebbe la
## sola cosa che rende l'ombra viva: che si muove.
func _process(_delta: float) -> void:
	_aggiorna(false)


func _aggiorna(forza: bool) -> void:
	# NIENTE NOTTE, NIENTE CALENDARIO: prima di `Game.start_night()` non c'è un
	# indice di notte da convertire in data. Si usa la notte 1 alle 21:00 — cioè
	# la prima sera del gioco — perché è l'unica risposta che non inventa una
	# data e non lascia il mondo senza luce nel menu.
	var notte: int = Game.run.night_index if Game.run != null else 1
	var minuti: float = Game.run.elapsed_min if Game.run != null else 0.0
	if fissa:
		minuti = 0.0
		notte = 1
	var adesso := Vector2(float(notte), minuti)
	if not forza and adesso.is_equal_approx(_istante_scritto):
		return
	_istante_scritto = adesso

	_dati = Luna.effemeridi(Luna.istante(notte, minuti))
	var dir: Vector3 = _dati[&"dir"]
	var alt: float = _dati[&"alt"]

	# IL CONTRIBUTO: quanto chiaro fa questa Luna, adesso. Frazione illuminata
	# per il seno dell'altezza — la legge del coseno di Lambert su una superficie
	# orizzontale, che è il prato e il tetto.
	#
	# E LA FRAZIONE ENTRA LINEARE, che NON è la fotometria vera e va detto: la
	# curva di fase della Luna è ripidissima, una mezza luna manda un DECIMO
	# della luce di una piena, non la metà. Al rapporto vero venti notti su
	# ventinove sarebbero indistinguibili dal novilunio, e il calendario — che è
	# la cosa che questo lavoro doveva rendere leggibile — tornerebbe a essere un
	# interruttore fra luna e buio. Si tiene la retta e si dichiara la bugia.
	var elevazione := clampf(sin(deg_to_rad(alt)), 0.0, 1.0)
	_contributo = float(_dati[&"illuminata"]) * elevazione

	var energia_luna := ENERGIA_LUNA * _contributo
	light_energy = ENERGIA_CIELO + energia_luna

	# DA DOVE ARRIVA LA LUCE. Vedi l'intestazione: una lampada sola per due cose,
	# e il peso è l'ALTEZZA della Luna — non la sua energia.
	#
	# ED È LA SECONDA STESURA, perché la prima pesava con l'energia e sbagliava in
	# un modo che si vede. Misurato dalla sonda: la notte 1 alle 21:00, con la
	# mezza luna a ventiquattro gradi, il fondo del cielo valeva quasi metà del
	# totale e tirava la direzione di VENTOTTO GRADI verso l'alto. In cielo si
	# sarebbe vista la luna bassa a sud-ovest e per terra le ombre di una luce
	# quasi allo zenit: le due metà di questo lavoro che si smentiscono a vicenda.
	#
	# FINCHÉ LA LUNA È IN CIELO, LA LUCE È LA SUA, per fioca che sia — è comunque
	# l'unica cosa in cielo che faccia un'ombra netta. Quando tramonta resta il
	# chiarore, che viene da tutte le parti insieme e non ha una direzione: lo
	# zenit è la meno sbagliata, ed è anche quella le cui ombre si notano di meno.
	# Il passaggio si fa fra −2 e +18 gradi d'altezza, cioè nella fascia in cui la
	# Luna è così bassa che l'aria se la mangia quasi tutta.
	var peso := smoothstep(-2.0, 18.0, alt)
	var somma := (Vector3.UP * (1.0 - peso) + dir * peso).normalized()
	if somma.length_squared() < 0.5:
		somma = Vector3.UP
	# `looking_at(-somma)`: l'asse −Z di una direzionale è il verso in cui la
	# luce VIAGGIA, quindi per venire DALLA Luna deve puntare dalla parte
	# opposta. Il vettore alto si scambia quando la sorgente è quasi allo zenit,
	# dove `UP` sarebbe parallelo e la base non si potrebbe costruire.
	var alto := Vector3.UP if absf(somma.y) < 0.999 else Vector3.FORWARD
	global_basis = Basis.looking_at(-somma, alto)

	# Il colore segue l'altezza, non la fase: è l'aria che arrossa, e l'aria non
	# sa che fase è.
	var freddo := clampf(alt / ALTEZZA_FREDDA, 0.0, 1.0)
	light_color = COLORE_BASSA.lerp(COLORE_ALTA, freddo)

	_scrivi_nel_cielo()


## Quello che serve allo shader per disegnare il disco. CINQUE PARAMETRI E NON
## UNA FASE: la fase non si passa: si passa dove sta il Sole, e il disegno la
## ricava dalla geometria come fa la realtà. Un parametro «fase» sarebbe una
## seconda verità sulla stessa cosa, e la falce potrebbe guardare dalla parte
## sbagliata senza che nessun conto se ne accorga.
func _scrivi_nel_cielo() -> void:
	if _mat == null:
		return
	var alt: float = _dati[&"alt"]
	_mat.set_shader_parameter("luna_dir", _dati[&"dir"])
	_mat.set_shader_parameter("sole_dir", _dati[&"sole_dir"])
	_mat.set_shader_parameter("luna_raggio",
		deg_to_rad(float(_dati[&"diametro"]) * 0.5) * INGRANDIMENTO)
	# QUANTO SI VEDE IL DISCO: non dipende dalla fase — la parte illuminata di
	# una falce è luminosa quanto una piena, è solo più piccola — dipende
	# dall'aria che c'è di mezzo. Sotto l'orizzonte si spegne in un paio di
	# gradi, e bassa resta un terzo: è la luna arancione che si vede sorgere.
	_mat.set_shader_parameter("luna_luce",
		smoothstep(-1.0, 2.5, alt) * lerpf(0.35, 1.0, smoothstep(0.0, 25.0, alt)))
	# Lo stesso numero che comanda la lampada: il fondo del cielo e le stelle che
	# spariscono devono crescere insieme alla luce che entra dalla finestra.
	_mat.set_shader_parameter("luna_chiarore", _contributo)
	# Come è girata la faccia: il nord e l'est della Luna sul disco, adesso.
	_mat.set_shader_parameter("luna_nord", _dati[&"luna_nord"])
	_mat.set_shader_parameter("luna_est", _dati[&"luna_est"])


## Le mappe nel materiale del cielo, se ci sono.
func _carica_mappe() -> void:
	if _mat == null:
		return
	if not ResourceLoader.exists(MAPPA_COLORE) or not ResourceLoader.exists(MAPPA_RILIEVO):
		push_warning("[system] luna: mancano le mappe (python tools/prendi_luna.py): "
			+ "il disco resta liscio")
		_mat.set_shader_parameter("luna_mappe", 0.0)
		return
	var colore := load(MAPPA_COLORE) as Texture2D
	_mat.set_shader_parameter("luna_colore", colore)
	_mat.set_shader_parameter("luna_rilievo", load(MAPPA_RILIEVO) as Texture2D)
	_mat.set_shader_parameter("luna_albedo_media", albedo_media(colore))
	_mat.set_shader_parameter("luna_mappe", 1.0)


## LA LUMINOSITÀ MEDIA DELLA FACCIA VISIBILE, per poterla dividere via.
##
## PERCHÉ SERVE. La luce della Luna — quanto è bianco il disco, quanta luce manda
## sul prato — è già tarata e misurata (vedi `ENERGIA_LUNA` e `scatta_luna.gd`).
## La mappa deve dire DOVE la Luna è più chiara e dove più scura, non cambiare
## quanto è chiara in tutto: un mosaico schiarito per la stampa renderebbe la
## Luna più luminosa di ieri senza che nessun numero di questo file lo dica.
## Dividendo per la media, i mari restano scuri e gli altipiani chiari, e il
## disco intero vale quanto valeva.
##
## SI MISURA SUL FILE, non si scrive a mano: la NASA ha rifatto il mosaico nel
## dicembre 2025, e una costante ricopiata qui sarebbe già vecchia. La media è
## pesata come la vede chi guarda — la faccia visibile, i punti al centro del
## disco più di quelli di scorcio sul bordo.
static func albedo_media(tex: Texture2D) -> float:
	var img := tex.get_image() if tex != null else null
	if img == null:
		return 1.0
	if img.is_compressed():
		img.decompress()
	img.resize(64, 32, Image.INTERPOLATE_LANCZOS)
	var somma := 0.0
	var pesi := 0.0
	for y in 32:
		var lat := PI * (0.5 - (float(y) + 0.5) / 32.0)
		# Le colonne da 16 a 47 sono le longitudini da −90 a +90: la faccia che
		# guarda la Terra.
		for x in range(16, 48):
			var lon := TAU * ((float(x) + 0.5) / 64.0 - 0.5)
			var w := cos(lat) * cos(lat) * cos(lon)
			var c := img.get_pixel(x, y).srgb_to_linear()
			somma += (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) * w
			pesi += w
	return somma / pesi if pesi > 0.0 else 1.0


## Le effemeridi che questa lampada sta usando ADESSO. Serve alle sonde: leggere
## il segnale invece dello stato non prova niente sul fatto che il nodo l'abbia
## ricevuto.
func effemeridi() -> Dictionary:
	return _dati


## Quanto chiaro fa la Luna adesso: frazione illuminata per seno dell'altezza.
func contributo() -> float:
	return _contributo


static func find_in(tree: SceneTree) -> LuceDiLuna:
	return tree.get_first_node_in_group(GROUP) as LuceDiLuna
