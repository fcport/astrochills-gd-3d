## DOVE SONO I PIANETI STANOTTE, E QUALI SI VEDONO DAVVERO. Solo funzioni statiche.
##
## COSA FA, IN UNA RIGA: dall'istante della notte ricava la posizione, la
## distanza e la LUMINOSITÀ dei cinque pianeti che si vedono a occhio nudo —
## Mercurio, Venere, Marte, Giove, Saturno — e da questi tre numeri esce da sola
## la risposta alla domanda che conta, cioè quali stanotte si vedono e quali no.
##
## PERCHÉ ESISTE. Il cielo di questo gioco aveva le stelle e aveva la Luna, e le
## stelle sono PROCEDURALI: un campo di puntini plausibile e anonimo, in cui non
## c'è niente da riconoscere. I pianeti sono l'esatto contrario — sono cinque, si
## chiamano per nome, sono più luminosi di quasi tutte le stelle, e chi alza gli
## occhi da un osservatorio li riconosce prima di qualunque costellazione. Sono
## le «cose base da vedere» che mancavano.
##
## E NON SI VEDONO MAI TUTTI INSIEME, che è il punto della richiesta e il motivo
## per cui questo file calcola un'orbita invece di piazzare cinque puntini fissi.
## Un pianeta si vede se è sopra l'orizzonte A QUEST'ORA, e quasi mai lo sono
## tutti: Mercurio non si stacca mai più di ventotto gradi dal Sole e per questo
## sta in cielo solo nel crepuscolo — nelle nove ore di questo gioco non si vede
## MAI — Venere è la stella della sera o quella del mattino e non è mai in
## mezzo, Marte, Giove e Saturno sorgono e tramontano come le stelle ma si
## spostano di mese in mese. Nel mese di lavoro del gioco (16 novembre 1999 in
## poi) il conto dà, misurato sulla prima notte: Giove e Saturno già alti a
## sud-est quando comincia il turno — erano all'opposizione da poche settimane —
## che tramontano alle 4:50 e alle 6:08; Venere che sorge alle 3:07 e diventa la
## cosa più luminosa del cielo; Marte che tramonta alle 20:32, cioè mezz'ora
## PRIMA che la notte cominci, e quindi non si vede mai; Mercurio mai. Cinque
## pianeti, e ogni ora della notte ne mostra un sottoinsieme diverso. Non è
## programmato da nessuna parte: esce dal calendario, come la fase della Luna.
##
## L'ASTRONOMIA È VERA E SI VERIFICA. Gli elementi orbitali sono quelli
## pubblicati dal Jet Propulsion Laboratory per le posizioni approssimate dei
## pianeti maggiori nell'intervallo 1800-2050 (Standish, «Keplerian Elements for
## Approximate Positions of the Major Planets»), e il metodo è il loro: elementi
## che derivano linearmente col tempo, equazione di Keplero risolta a iterazione,
## posizione eliocentrica, differenza con la Terra. JPL dichiara scarti di
## qualche primo d'arco per i pianeti interni e di una decina per Giove e
## Saturno; sullo schermo di questo gioco un pixel vale DODICI primi, quindi
## anche il caso peggiore sta dentro il pixel. `tools/prova_pianeti.gd` lo
## confronta con le configurazioni pubblicate del 1999 — l'opposizione di Giove
## del 23 ottobre, quella di Saturno del 6 novembre — e con i due invarianti che
## nessun modello sbagliato rispetta: la massima elongazione di Mercurio e di
## Venere.
##
## LE MAGNITUDINI SONO FORMULE, NON UNA TABELLA. La luminosità di un pianeta non
## è una sua proprietà: cambia di cento volte fra una congiunzione e
## un'opposizione, perché dipende da quanto è lontano dal Sole, da quanto è
## lontano da noi e da quanta della sua faccia illuminata ci mostra. Sono le
## formule dell'Astronomical Almanac (Meeus, cap. 41), le stesse che danno
## Venere a −4,4 e Saturno a +0,2 — e sono la ragione per cui in questo gioco
## Venere si vede attraverso la finestra della cucina e Saturno bisogna cercarlo.
##
## QUELLO CHE NON C'È, dichiarato (D-171):
##   - le perturbazioni pianeta-pianeta: la grande disuguaglianza fra Giove e
##     Saturno sta negli elementi medi di JPL solo come deriva lineare. È il
##     motivo per cui i due esterni sbagliano dieci primi e gli interni uno;
##   - il tempo-luce e l'aberrazione: la luce di Giove parte quaranta minuti
##     prima di arrivare, e in quaranta minuti Giove si sposta di un decimo di
##     primo. Meno di un centesimo di pixel;
##   - la rifrazione atmosferica, come per la Luna: vicino all'orizzonte alza
##     tutto di mezzo grado. È la differenza fra «tramonta» e «è tramontato»;
##   - la parallasse: qui i pianeti si vedono dal centro della Terra. Per Venere
##     al passaggio più vicino vale mezzo primo d'arco, per gli altri meno;
##   - Urano e Nettuno: al limite dell'occhio nudo il primo, fuori portata il
##     secondo, e in un cielo disegnato nessuno dei due si distinguerebbe da una
##     stella qualunque;
##   - i satelliti di Giove e l'anello di Saturno COME OGGETTI: l'anello c'è
##     solo come luminosità (vedi `_magnitudine`), perché a occhio nudo è quello
##     che se ne vede — Saturno con gli anelli aperti è mezza magnitudine più
##     luminoso, e nel 1999 erano ben aperti.
##
## `core/` NON DIPENDE DA NIENTE DI FUORI, ma `core/luna.gd` è dentro: da lì
## arrivano la latitudine, l'ora del cielo e le due rotazioni che portano una
## posizione dall'eclittica all'orizzonte. Sono le stesse per la Luna e per i
## pianeti perché è lo STESSO cielo visto dallo STESSO osservatorio, e una
## seconda copia sarebbe il modo più veloce di avere una Luna che sorge a
## un'ora e Giove a un'altra.
class_name Pianeti


## I CINQUE CHE SI VEDONO A OCCHIO NUDO, nell'ordine in cui stanno nel sistema
## solare. L'ordine conta: è quello con cui i parametri finiscono negli array
## dello shader, ed è l'ordine in cui `tools/prova_pianeti.gd` stampa la tabella.
const ORDINE: Array[StringName] = [&"mercurio", &"venere", &"marte", &"giove", &"saturno"]

## Come si chiamano per esteso, che è come li chiamerebbe un quaderno di
## osservazione — e un giorno un'interfaccia.
const SCRITTI := {
	&"mercurio": "Mercurio",
	&"venere": "Venere",
	&"marte": "Marte",
	&"giove": "Giove",
	&"saturno": "Saturno",
}

## GLI ELEMENTI ORBITALI, e la tabella è quella di JPL per il 1800-2050.
##
## Dodici numeri per pianeta, nell'ordine: semiasse maggiore (unità
## astronomiche), eccentricità, inclinazione sull'eclittica, longitudine media,
## longitudine del perielio, longitudine del nodo ascendente — tutti in gradi —
## e poi le stesse sei quantità come DERIVA PER SECOLO giuliano. Il secondo
## gruppo è ciò che rende questo un modello del tempo e non una fotografia del
## primo gennaio 2000: la longitudine media di Mercurio cresce di centoquaranta
## MILA gradi al secolo, che sono i suoi quattrocentoquindici giri.
##
## I NUMERI NON SI TOCCANO E NON SI ARROTONDANO. Sono un adattamento ai minimi
## quadrati delle effemeridi DE405 su due secoli e mezzo: ogni cifra decimale di
## una deriva è un errore che si accumula. Togliendo l'ultima cifra alla deriva
## di `L` di Saturno la sua posizione nel 1999 scivola di un grado.
const ELEMENTI := {
	&"mercurio": [
		0.38709927, 0.20563593, 7.00497902, 252.25032350, 77.45779628, 48.33076593,
		0.00000037, 0.00001906, -0.00594749, 149472.67411175, 0.16047689, -0.12534081],
	&"venere": [
		0.72333566, 0.00677672, 3.39467605, 181.97909950, 131.60246718, 76.67984255,
		0.00000390, -0.00004107, -0.00078890, 58517.81538729, 0.00268329, -0.27769418],
	&"marte": [
		1.52371034, 0.09339410, 1.84969142, -4.55343205, -23.94362959, 49.55953891,
		0.00001847, 0.00007882, -0.00813131, 19140.30268499, 0.44441088, -0.29257343],
	&"giove": [
		5.20288700, 0.04838624, 1.30439695, 34.39644051, 14.72847983, 100.47390909,
		-0.00011607, -0.00013253, -0.00183714, 3034.74612775, 0.21252668, 0.20469106],
	&"saturno": [
		9.53667594, 0.05386179, 2.48599187, 49.95424423, 92.59887831, 113.66242448,
		-0.00125060, -0.00050991, 0.00193609, 1222.49362201, -0.41897216, -0.28867794],
}

## LA TERRA, dalla stessa tabella e con lo stesso metodo. Non è un sesto pianeta
## da guardare: è il PUNTO DI VISTA. Ogni posizione qui dentro si calcola attorno
## al Sole e poi si sottrae questa, ed è tutta la differenza fra dove un pianeta
## STA e dove lo si VEDE.
##
## In tabella è il baricentro Terra-Luna, che dal Sole dista quanto la Terra a
## meno di cinquemila chilometri: un centesimo di primo d'arco su Marte.
const TERRA := [
	1.00000261, 0.01671123, -0.00001531, 100.46457166, 102.93768193, 0.0,
	0.00000562, -0.00004392, -0.01294668, 35999.37244981, 0.32327364, 0.0]

## I raggi equatoriali, in chilometri: con la distanza fanno il diametro
## apparente. A occhio nudo nessuno di questi è un disco — Venere al massimo
## arriva a un primo d'arco, un trentesimo di Luna — e infatti in cielo si
## disegnano come punti. Serve al telescopio, che è la ragione per cui il numero
## esiste già adesso.
const RAGGIO_KM := {
	&"mercurio": 2439.7,
	&"venere": 6051.8,
	&"marte": 3396.2,
	&"giove": 71492.0,
	&"saturno": 60268.0,
}

## L'unità astronomica in chilometri: la distanza media Terra-Sole, ed è il metro
## con cui è misurato tutto quello che c'è qui dentro.
const AU_KM := 149597870.7

## IL POLO NORD DI SATURNO, in coordinate equatoriali J2000 (IAU). Serve a
## sapere quanto sono INCLINATI GLI ANELLI verso di noi, che è mezza magnitudine
## di luminosità: ad anelli di taglio Saturno cala quasi di una magnitudine, ad
## anelli spalancati riflettono più del globo. Nel 1999 erano aperti di una
## ventina di gradi e si stavano aprendo ancora, verso il massimo del 2003.
const POLO_SATURNO_AR := 40.589
const POLO_SATURNO_DEC := 83.537


## TUTTI E CINQUE IN QUELL'ISTANTE, nell'ordine di `ORDINE`.
##
## Un solo giro per tutti e cinque perché la Terra si calcola UNA volta: è il
## punto di vista comune, e ricalcolarla cinque volte sarebbe la stessa
## trigonometria fatta cinque volte per fotogramma.
##
## LE CHIAVI, per ciascun pianeta:
##   `nome`, `scritto`   la sigla interna e il nome per esteso.
##   `ar`, `dec`         ascensione retta e declinazione, gradi.
##   `ha`                angolo orario, gradi, −180..180 (convenzione montatura).
##   `alt`, `az`         altezza sull'orizzonte e azimut da nord verso est.
##   `dir`               la direzione in coordinate del MONDO, come per la Luna.
##   `distanza`          da qui, in unità astronomiche.
##   `eliocentrica`      dal Sole, in unità astronomiche.
##   `elongazione`       quanti gradi lo separano dal Sole in cielo. È la
##                       quantità che decide se un pianeta è OSSERVABILE prima
##                       ancora che sia sopra l'orizzonte: sotto i dieci gradi
##                       sta nel chiarore del Sole e non lo vede nessuno.
##   `fase`              l'angolo Sole-pianeta-Terra, gradi. Per gli esterni non
##                       supera mai di molto lo zero (Giove mostra sempre il
##                       disco pieno); per Venere e Mercurio arriva a 180.
##   `illuminata`        la frazione illuminata del disco, 0..1.
##   `magnitudine`       quanto è luminoso, scala astronomica: PIÙ PICCOLO È PIÙ
##                       LUMINOSO, e il passo di una magnitudine vale due volte
##                       e mezzo di luce. Venere sta a −4, Saturno a +0,2.
##   `diametro`          il disco apparente, in secondi d'arco.
##   `anelli`            solo Saturno: quanto sono inclinati verso di noi, gradi.
static func effemeridi(jd: float) -> Array[Dictionary]:
	var t := (jd - 2451545.0) / 36525.0
	var terra := _eclittica(TERRA, t)
	var fuori: Array[Dictionary] = []
	for nome in ORDINE:
		fuori.append(_uno(nome, terra, t, jd))
	return fuori


## DOV'È IL SOLE, dalla posizione della Terra: visto da qui sta esattamente dalla
## parte opposta. Torna `alt`, `az` e `dir` come le altre.
##
## SERVE A DUE COSE, e nessuna delle due è illuminare. La prima è l'elongazione,
## cioè quanto un pianeta è lontano dal chiarore; la seconda è il CONTROLLO: la
## Luna calcola il Sole per conto suo, con un altro modello e in un altro file,
## e le due risposte devono coincidere. `tools/prova_pianeti.gd` le confronta, ed
## è la sola verifica di questo file che non abbia bisogno di un almanacco.
static func sole(jd: float) -> Dictionary:
	var t := (jd - 2451545.0) / 36525.0
	var g := -_eclittica(TERRA, t)
	var d := g.length()
	var eq := Luna.eclittiche_in_equatoriali(
		rad_to_deg(atan2(g.y, g.x)), rad_to_deg(asin(g.z / d)))
	var aa := Luna.alt_az(Luna.angolo_orario(eq.x, jd), eq.y)
	return {
		&"ar": fposmod(eq.x, 360.0),
		&"dec": eq.y,
		&"alt": aa.x,
		&"az": aa.y,
		&"dir": Luna.direzione(aa.x, aa.y),
		&"distanza": d,
	}


## Il nome per esteso, o la sigla se il pianeta non è dei cinque.
static func scritto(nome: StringName) -> String:
	return SCRITTI.get(nome, String(nome))


## Un pianeta solo, data la Terra già calcolata.
static func _uno(nome: StringName, terra: Vector3, t: float, jd: float) -> Dictionary:
	var p := _eclittica(ELEMENTI[nome], t)
	# LA DIFFERENZA È TUTTO: `p` è dove il pianeta sta attorno al Sole, `terra`
	# dove stiamo noi, e `g` è il vettore che va da qui a lui. È il solo passaggio
	# di questo file che non si trovi già scritto in un manuale di meccanica
	# celeste, ed è quello che trasforma un'orbita in una cosa che si guarda.
	var g := p - terra
	var d := g.length()
	var r := p.length()
	var rt := terra.length()

	var eq := Luna.eclittiche_in_equatoriali(
		rad_to_deg(atan2(g.y, g.x)), rad_to_deg(asin(g.z / d)))
	var ha := Luna.angolo_orario(eq.x, jd)
	var aa := Luna.alt_az(ha, eq.y)

	# I DUE ANGOLI DEL TRIANGOLO Sole-Terra-pianeta, dal teorema del coseno sui
	# tre lati che si hanno già. L'elongazione è l'angolo con vertice QUI —
	# quanto il pianeta si stacca dal Sole in cielo — la fase è quello con
	# vertice sul PIANETA, cioè quanto della sua faccia illuminata ci volta.
	var elong := rad_to_deg(acos(clampf((rt * rt + d * d - r * r) / (2.0 * rt * d), -1.0, 1.0)))
	var fase := rad_to_deg(acos(clampf((r * r + d * d - rt * rt) / (2.0 * r * d), -1.0, 1.0)))

	var anelli := _inclinazione_anelli(g) if nome == &"saturno" else 0.0
	return {
		&"nome": nome,
		&"scritto": SCRITTI[nome],
		&"ar": fposmod(eq.x, 360.0),
		&"dec": eq.y,
		&"ha": ha,
		&"alt": aa.x,
		&"az": aa.y,
		&"dir": Luna.direzione(aa.x, aa.y),
		&"distanza": d,
		&"eliocentrica": r,
		&"elongazione": elong,
		&"fase": fase,
		&"illuminata": (1.0 + cos(deg_to_rad(fase))) * 0.5,
		&"magnitudine": _magnitudine(nome, r, d, fase, anelli),
		&"diametro": 2.0 * rad_to_deg(asin(float(RAGGIO_KM[nome]) / (d * AU_KM))) * 3600.0,
		&"anelli": anelli,
	}


## LA POSIZIONE ATTORNO AL SOLE, in coordinate rettangolari dell'eclittica J2000:
## x verso il punto d'Ariete, z verso il polo dell'eclittica, in unità
## astronomiche. NON è una direzione del mondo di gioco — quella la fa
## `Luna.direzione()` alla fine, dopo l'orizzonte — è un vettore di geometria,
## non di scena.
##
## È LA RICETTA DI JPL, nell'ordine in cui la scrivono loro: elementi al tempo t,
## anomalia media, Keplero, posizione nel piano dell'orbita, tre rotazioni per
## rimetterla nel piano dell'eclittica.
static func _eclittica(el: Array, t: float) -> Vector3:
	var a := float(el[0]) + float(el[6]) * t
	var ecc := float(el[1]) + float(el[7]) * t
	var inc := float(el[2]) + float(el[8]) * t
	var lung := float(el[3]) + float(el[9]) * t
	var peri := float(el[4]) + float(el[10]) * t
	var nodo := float(el[5]) + float(el[11]) * t

	# L'ANOMALIA MEDIA, ripiegata su −180..180 com'è richiesto: Keplero converge
	# comunque, ma su un'anomalia di centomila gradi lo fa partendo da lontano.
	var m := fposmod(lung - peri + 180.0, 360.0) - 180.0
	var arg := peri - nodo

	# L'EQUAZIONE DI KEPLERO, M = E − e·sin E, che NON si risolve in forma
	# chiusa: è il punto in cui un'orbita ellittica smette di essere algebra. Si
	# itera con Newton, e in quattro o cinque passi si arriva sotto il
	# milionesimo di grado anche per Mercurio, che è il più eccentrico di tutti.
	#
	# L'ECCENTRICITÀ IN GRADI, ed è il passaggio di JPL che fa sembrare sbagliata
	# la formula: siccome qui E e M si tengono in gradi, il termine e·sin E va
	# convertito una volta per tutte invece che avanti e indietro a ogni giro.
	var e_gradi := rad_to_deg(ecc)
	var e_anom := m + e_gradi * sin(deg_to_rad(m))
	for _giro in 8:
		var dm := m - (e_anom - e_gradi * sin(deg_to_rad(e_anom)))
		var passo := dm / (1.0 - ecc * cos(deg_to_rad(e_anom)))
		e_anom += passo
		if absf(passo) < 1e-9:
			break

	# La posizione nel PIANO DELL'ORBITA, con il Sole in un fuoco e l'asse x
	# verso il perielio. Da qui in poi è solo questione di girare il piano.
	var ea := deg_to_rad(e_anom)
	var xo := a * (cos(ea) - ecc)
	var yo := a * sqrt(maxf(0.0, 1.0 - ecc * ecc)) * sin(ea)

	# TRE ROTAZIONI IN UNA: argomento del perielio attorno all'asse dell'orbita,
	# inclinazione attorno alla linea dei nodi, longitudine del nodo attorno al
	# polo dell'eclittica. Scritte moltiplicate, che è come le scrive JPL: sei
	# seni e sei coseni invece di tre matrici.
	var cw := cos(deg_to_rad(arg))
	var sw := sin(deg_to_rad(arg))
	var cn := cos(deg_to_rad(nodo))
	var sn := sin(deg_to_rad(nodo))
	var ci := cos(deg_to_rad(inc))
	var si := sin(deg_to_rad(inc))
	return Vector3(
		(cw * cn - sw * sn * ci) * xo + (-sw * cn - cw * sn * ci) * yo,
		(cw * sn + sw * cn * ci) * xo + (-sw * sn + cw * cn * ci) * yo,
		(sw * si) * xo + (cw * si) * yo)


## QUANTO È LUMINOSO, in magnitudini apparenti.
##
## LE FORMULE SONO QUELLE DELL'ASTRONOMICAL ALMANAC (Meeus, cap. 41), e hanno
## tutte la stessa ossatura: una costante, che è la magnitudine che il pianeta
## avrebbe a una unità astronomica dal Sole e da qui; il termine `5·log(r·d)`,
## che è la legge dell'inverso del quadrato applicata due volte — la luce deve
## arrivare al pianeta e poi tornare indietro; e infine i termini della FASE, che
## sono quelli che distinguono un pianeta da una stella. Una stella è sempre la
## stessa; un pianeta no.
##
## E LA FASE NON È LINEARE, per nessuno di loro. Su Venere il termine quadratico
## vale due magnitudini intere: al quarto è più luminosa che piena, perché
## quando è piena sta dall'altra parte del Sole ed è lontanissima. È il motivo
## per cui il massimo splendore di Venere non capita mai quando si crederebbe.
static func _magnitudine(nome: StringName, r: float, d: float, i: float,
		anelli: float) -> float:
	var base := 5.0 * (log(r * d) / log(10.0))
	match nome:
		&"mercurio":
			return -0.42 + base + 0.0380 * i - 0.000273 * i * i + 0.000002 * i * i * i
		&"venere":
			return -4.40 + base + 0.0009 * i + 0.000239 * i * i - 0.00000065 * i * i * i
		&"marte":
			return -1.52 + base + 0.016 * i
		&"giove":
			return -9.40 + base + 0.005 * i
		&"saturno":
			# L'ANELLO, che è metà della luminosità di Saturno e tutta la ragione
			# per cui questo pianeta ha una formula diversa dagli altri.
			#
			# MANCA IL TERMINE `ΔU`, la differenza di longitudine fra il Sole e
			# noi vista da Saturno: vale quattro centesimi di magnitudine per
			# grado e non supera i sei gradi, cioè meno di quanto si distingua in
			# un cielo disegnato.
			var b := deg_to_rad(absf(anelli))
			return -8.88 + base - 2.60 * sin(b) + 1.25 * sin(b) * sin(b)
	return 99.0


## QUANTO SONO INCLINATI GLI ANELLI verso di noi, in gradi, sempre positivi.
##
## È l'angolo fra la direzione Saturno-Terra e il PIANO degli anelli, cioè
## novanta gradi meno l'angolo con l'asse. Il segno direbbe quale delle due
## facce stiamo vedendo — quella a nord o quella a sud del piano — e qui non
## serve: la formula della luminosità usa il valore assoluto, perché un anello
## illuminato riflette uguale da tutte e due le parti.
static func _inclinazione_anelli(geo: Vector3) -> float:
	# Il polo di Saturno è pubblicato in coordinate equatoriali e qui si lavora in
	# coordinate dell'eclittica: si costruisce il versore e lo si gira
	# dell'obliquità, che è la stessa rotazione di `Luna.eclittiche_in_equatoriali`
	# fatta all'indietro.
	var ar := deg_to_rad(POLO_SATURNO_AR)
	var dec := deg_to_rad(POLO_SATURNO_DEC)
	var eq := Vector3(cos(dec) * cos(ar), cos(dec) * sin(ar), sin(dec))
	var ob := deg_to_rad(Luna.OBLIQUITA)
	var polo := Vector3(eq.x, eq.y * cos(ob) + eq.z * sin(ob), -eq.y * sin(ob) + eq.z * cos(ob))
	return rad_to_deg(asin(clampf(absf(polo.dot(geo.normalized())), 0.0, 1.0)))
