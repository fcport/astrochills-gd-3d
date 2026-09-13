## DOV'È LA LUNA STANOTTE, E QUANTA CE N'È. Solo funzioni statiche.
##
## COSA FA, IN UNA RIGA: dal numero della notte ricava una DATA, e dalla data la
## posizione e la fase della Luna vera di quella notte.
##
## PERCHÉ NON BASTAVA UNA DIREZIONALE FERMA. Fino a ieri la luna di questo gioco
## era una `DirectionalLight3D` con una posa scritta a mano e un'energia costante
## (D-071, D-078): faceva il suo mestiere — l'ombra sul prato, il vetro che si
## vede attraverso — ma era la STESSA in tutte le notti, e in cielo non c'era. In
## un gioco che si chiama Astrochill, in cui il giocatore passa la notte a
## fotografare il cielo profondo, la fase lunare non è un dettaglio atmosferico:
## è la variabile che decide se stanotte si può lavorare. Un astrofotografo
## guarda il calendario prima del meteo.
##
## L'ASTRONOMIA È VERA E SI VERIFICA. Non è un ciclo di ventinove giorni fatto a
## occhio: è il modello a bassa precisione di Meeus (Astronomical Algorithms,
## capp. 22, 25, 47, 48), troncato ai termini che contano. `tools/prova_luna.gd`
## lo confronta con i noviluni e i pleniluni VERI del 1999 — sei date pubblicate,
## fra cui l'eclissi totale dell'11 agosto — e li ritrova entro un decimo di
## grado di angolo di fase, cioè entro pochi minuti. Un modello lunare che
## nessuno confronta con un almanacco è un generatore di numeri plausibili.
##
## QUELLO CHE NON C'È, dichiarato (D-171: non si dichiara ciò che non si è
## modellato):
##   - le perturbazioni minori: la longitudine è troncata a dodici termini, la
##     latitudine a quattro. L'errore resta sotto il decimo di grado, cioè un
##     quinto del disco lunare;
##   - la rifrazione atmosferica: vicino all'orizzonte alza la Luna di mezzo
##     grado, e qui non c'è. È la differenza fra «tramonta» e «è tramontata»;
##   - la parallasse: la Luna vista da terra non sta dove la vede il centro
##     della Terra, e la differenza arriva a un grado. Conta per un'occultazione,
##     non per sapere se stanotte c'è il chiaro di luna;
##   - le librazioni: la Luna mostra sempre la stessa faccia, ma dondola di sette
##     gradi in longitudine e sette in latitudine nel corso del mese, e qui il
##     centro del disco è sempre il punto (0, 0). Un osservatore esperto se ne
##     accorge al bordo — Mare Crisium ora più vicino, ora più lontano — e
##     nessun altro;
##   - l'asse della Luna è preso uguale al polo dell'eclittica: il vero ne dista
##     un grado e mezzo (leggi di Cassini), cioè un'inclinazione della faccia
##     che a occhio non si distingue.
##
## `core/` NON DIPENDE DA NIENTE, ed è la ragione per cui `ORA_INIZIO` è
## ricopiata qui invece di essere importata da `NightClock`. È la stessa scelta
## di `HonestCatalog`, con la stessa contropartita: il banco confronta le due
## copie, perché una che diverga in silenzio farebbe sorgere la Luna un'ora
## sbagliata senza che niente lo dica.
class_name Luna


## LA PRIMA NOTTE DI LAVORO. Il gioco è ambientato nel 1999 (docs/idea/idea.md) e
## fin qui non aveva un giorno: `night_index` contava e basta. Adesso conta dei
## GIORNI, e il primo va scelto — quindi va motivato.
##
## PERCHÉ NOVEMBRE. Perché la notte di questo gioco va dalle 21:00 alle 06:00
## (`NightClock`, nove ore di buio) e nove ore di buio a 43,9 gradi di latitudine
## esistono solo in inverno: a giugno alle 21:00 c'è ancora il crepuscolo. La
## stagione non è un gusto, è il vincolo che l'orologio del gioco ha già scelto.
##
## PERCHÉ IL SEDICI. Perché è il giorno dopo il primo quarto: la notte 1 si apre
## con una mezza luna alta ventiquattro gradi a sud-ovest, che si vede dalla
## vetrata subito e senza dover sapere niente, e tramonta poco dopo mezzanotte —
## quindi la prima notte mostra tutte e due le cose che questo file serve a
## produrre, la luna che c'è e la luna che se ne va. Un inizio al novilunio
## avrebbe fatto sembrare rotta la funzione appena scritta.
##
## E IL RESTO DEL MESE VIENE DIETRO, che è il punto: notte 7-8 luna piena tutta
## la notte (e il cielo profondo non si fotografa), notte 13 in poi la luna sorge
## sempre più tardi, notte 22 novilunio — buio pieno, la notte buona. Il ciclo
## non è programmato da nessuna parte: esce dal calendario.
const PRIMA_NOTTE_ANNO := 1999
const PRIMA_NOTTE_MESE := 11
const PRIMA_NOTTE_GIORNO := 16

## L'ora in cui comincia la notte. COPIA di `NightClock.NIGHT_START_HOUR`, e il
## banco le confronta: vedi l'intestazione.
const ORA_INIZIO := 21

## Il fuso dell'Italia in novembre, in ore su UT. L'ora legale del 1999 è finita
## il 31 ottobre, quindi per tutto l'arco di notti che il calendario può coprire
## qui è CET e basta: nessuna regola di cambio da scrivere, e nessuna da
## sbagliare. Se un giorno il calendario arrivasse ad aprile, questa riga
## diventerebbe una funzione — e fino ad allora sarebbe stata codice non provato.
const FUSO := 1.0

## Dove sta l'osservatorio. La latitudine è la stessa di `SkyGeometry` e di
## `tools/geometria.py` — l'altezza del polo sull'orizzonte VALE la latitudine —
## e il banco verifica che non divergano. La longitudine serve solo qui: è la
## differenza fra l'ora del quadrante e l'ora del cielo, che a Montegrimano vale
## dieci minuti, cioè due gradi e mezzo di cielo.
const LATITUDINE := 43.9
const LONGITUDINE := 12.47

## L'inclinazione dell'asse terrestre sull'eclittica, in gradi, all'epoca J2000.
## Cala di mezzo secondo d'arco l'anno: in un secolo non sposta niente di quello
## che si vede qui.
const OBLIQUITA := 23.4393

## Il raggio della Luna, in chilometri. Con la distanza fa il diametro apparente,
## che è l'altra metà della domanda «di che dimensione si vede».
const RAGGIO_KM := 1737.4

## Il mese sinodico medio, in giorni: da un novilunio al successivo. NON SERVE AL
## CONTO — la fase esce dalla geometria di Sole e Luna, non da un contatore — e
## sta qui solo per l'ETÀ in giorni, che è il numero con cui un almanacco del
## 1999 avrebbe descritto la Luna di stasera.
const SINODICO := 29.530588853

## Il novilunio dell'eclissi totale dell'11 agosto 1999, in giorno giuliano UT.
## È l'ancora dell'età lunare, ed è scelto perché è la data lunare più
## verificabile del secolo: l'ombra è passata sull'Europa e l'ora della
## congiunzione — 11:09 UT — sta su ogni almanacco.
const NOVILUNIO_NOTO := 2451401.9646

## IL POLO NORD DELL'ECLITTICA, in coordinate equatoriali: ascensione retta 270
## gradi, declinazione 90 meno l'obliquità. È dove punta l'asse di rotazione della
## Luna, a un grado e mezzo (Cassini, 1693): serve a girare la faccia sul disco
## — dove sta il nord della Luna nel cielo di stanotte, a quest'ora.
const POLO_ECLITTICA_AR := 270.0
const POLO_ECLITTICA_DEC := 90.0 - OBLIQUITA


## LA DATA DELLA NOTTE `n`, come (anno, mese, giorno).
##
## Una notte = un giorno di calendario, e il giorno è quello in cui la notte
## COMINCIA: la notte 1 è la sera del 16 novembre e finisce la mattina del 17.
## È la convenzione degli osservatori e delle effemeridi, ed è anche l'unica che
## non faccia cambiare data al giocatore a metà turno.
static func data(night_index: int) -> Vector3i:
	return _data_da_giuliano(giuliano_di(PRIMA_NOTTE_ANNO, PRIMA_NOTTE_MESE,
		PRIMA_NOTTE_GIORNO) + maxi(night_index, 1) - 1)


## La data scritta come la scriverebbe un quaderno di osservazione italiano.
static func data_scritta(night_index: int) -> String:
	const MESI := ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno",
		"luglio", "agosto", "settembre", "ottobre", "novembre", "dicembre"]
	var d := data(night_index)
	return "%d %s %d" % [d.z, MESI[d.y - 1], d.x]


## L'ISTANTE, in giorno giuliano UT, della notte `n` dopo `minuti` di gioco.
##
## IL TEMPO DI GIOCO È IL TEMPO DEL MONDO, ed è la stessa regola di
## `TempoSiderale`: `elapsed_min` sono minuti dell'orologio del 1999, non secondi
## reali. Chi passa qui `Game.run.elapsed_min` ottiene l'ora vera della notte.
static func istante(night_index: int, minuti: float) -> float:
	var d := data(night_index)
	# −0,5 porta dal mezzogiorno (dove comincia il giorno giuliano) alla
	# mezzanotte civile; poi si somma l'ora locale e si toglie il fuso.
	return (float(giuliano_di(d.x, d.y, d.z)) - 0.5
		+ (float(ORA_INIZIO) + minuti / 60.0 - FUSO) / 24.0)


## TUTTO QUELLO CHE SI SA DELLA LUNA IN QUELL'ISTANTE, in un dizionario.
##
## Un dizionario e non dieci funzioni separate perché i termini di Meeus si
## calcolano una volta e servono tutti insieme: `fase` e `dec` escono dagli
## stessi cinque angoli, e chiamarli due volte vorrebbe dire calcolarli due volte
## per fotogramma.
##
## LE CHIAVI:
##   `fase`      angolo di fase in gradi, 0..180: 0 = piena, 180 = novilunio. È
##               l'angolo Sole-Luna-Terra, cioè la cosa fisica; «primo quarto» è
##               un nome che si dà a un valore di questo numero. NON dice se
##               cresce o cala — novanta gradi sono tanto il primo quanto
##               l'ultimo quarto — e per quello c'è `crescente()`.
##   `illuminata` la frazione illuminata del disco, 0..1. È `(1+cos fase)/2`.
##   `eta`       giorni dal novilunio, 0..29,53. Serve a dirlo a parole.
##   `ar`,`dec`  ascensione retta e declinazione, gradi.
##   `ha`        angolo orario, gradi, −180..180. Negativo a est, zero in
##               meridiano, positivo a ovest: la convenzione di `TelescopeMount`.
##   `alt`,`az`  altezza sull'orizzonte e azimut da nord verso est, gradi.
##   `diametro`  diametro apparente in gradi. Mezzo grado, e varia del dieci per
##               cento fra perigeo e apogeo — la «superluna».
##   `distanza`  chilometri.
##   `dir`       la direzione della Luna in coordinate del MONDO.
##   `sole_dir`  la direzione del Sole in coordinate del mondo. Sta qui perché è
##               ciò che decide DA CHE PARTE la Luna è illuminata: chi disegna il
##               disco non ha bisogno di sapere che fase è, gli basta sapere dove
##               sta il Sole. Di notte è sotto l'orizzonte, e va bene così — non
##               serve a illuminare la scena, serve a illuminare la Luna.
##   `luna_nord`,`luna_est`  come è girata la FACCIA: due versori del mondo,
##               perpendicolari alla linea di vista, che dicono dove stanno il
##               nord e l'est della Luna sul disco. L'est è quello della
##               convenzione IAU — la parte di Mare Crisium — che dalla Terra si
##               vede dalla parte dell'OVEST del cielo: non è un refuso, è il
##               motivo per cui l'Unione Astronomica l'ha rovesciato nel 1961.
static func effemeridi(jd: float) -> Dictionary:
	var t := (jd - 2451545.0) / 36525.0

	# I CINQUE ANGOLI FONDAMENTALI (Meeus cap. 47), in gradi. Crescono di
	# centinaia di migliaia di gradi per secolo: è normale, sono giri.
	var lp := 218.3165 + 481267.8813 * t      # longitudine media della Luna
	var mp := 134.9634 + 477198.8675 * t      # anomalia media della Luna
	var ms := 357.5291 + 35999.0503 * t       # anomalia media del Sole
	var dm := 297.8502 + 445267.1115 * t      # elongazione media Luna-Sole
	var f := 93.2721 + 483202.0175 * t        # argomento di latitudine

	# LA LONGITUDINE ECLITTICA. Il primo termine è l'ellisse dell'orbita — sei
	# gradi e tre decimi, il più grande di tutti — il secondo è l'evezione, il
	# terzo la variazione. Sono i tre che Tolomeo, Ipparco e Tycho hanno scoperto
	# in quest'ordine, ed è anche l'ordine in cui contano.
	var lambda_l := (lp
		+ 6.289 * _sin(mp)
		+ 1.274 * _sin(2.0 * dm - mp)
		+ 0.658 * _sin(2.0 * dm)
		- 0.186 * _sin(ms)
		- 0.059 * _sin(2.0 * mp - 2.0 * dm)
		- 0.057 * _sin(mp - 2.0 * dm + ms)
		+ 0.053 * _sin(mp + 2.0 * dm)
		+ 0.046 * _sin(2.0 * dm - ms)
		+ 0.041 * _sin(mp - ms)
		- 0.035 * _sin(dm)
		- 0.031 * _sin(mp + ms))

	# LA LATITUDINE ECLITTICA: l'orbita della Luna è inclinata di poco più di
	# cinque gradi sull'eclittica, e questo è il motivo per cui non c'è
	# un'eclissi ogni mese. Qui serve alla declinazione, che decide quanto alta
	# arriva in cielo.
	var beta := (5.128 * _sin(f)
		+ 0.281 * _sin(mp + f)
		- 0.278 * _sin(f - mp)
		+ 0.176 * _sin(2.0 * dm - f))

	# LA DISTANZA, in chilometri. Il termine grande vale ventimila chilometri:
	# è la differenza fra perigeo e apogeo, cioè fra una luna grande e una
	# piccola. È la metà «dimensione» della domanda.
	var r := (385000.56
		- 20905.355 * _cos(mp)
		- 3699.111 * _cos(2.0 * dm - mp)
		- 2955.968 * _cos(2.0 * dm)
		- 569.925 * _cos(2.0 * mp))

	# L'ANGOLO DI FASE (Meeus 48.4). NON è l'elongazione media `dm`: la Luna
	# corre su un'ellisse, e fra la fase media e quella vera ci sono fino a
	# dodici gradi — mezza giornata di anticipo o di ritardo sul primo quarto.
	# È esattamente la differenza fra un calendario e un contatore modulo 29,53.
	var fase_giro := fposmod(180.0 - dm
		- 6.289 * _sin(mp)
		+ 2.100 * _sin(ms)
		- 1.274 * _sin(2.0 * dm - mp)
		- 0.658 * _sin(2.0 * dm)
		- 0.214 * _sin(2.0 * mp)
		- 0.110 * _sin(dm), 360.0)
	# E SI RIPIEGA SU 0..180, che e' l'intervallo in cui l'angolo di fase ESISTE:
	# e' un angolo fra tre corpi, non un giro, e non c'e' nessuna differenza
	# geometrica fra 200 gradi e 160. La formula di Meeus ne produce comunque uno
	# fino a 360 perche' vi somma la fase MEDIA, che gira; ripiegarlo e' l'ultimo
	# passo del conto, non una comodita'.
	#
	# LO SBAGLIO CHE C'ERA QUI, ed e' stato trovato dalla sonda leggendo la
	# tabella del mese: senza il ripiegamento, dalla luna piena in poi la fase
	# resta sopra 180 per due settimane, e `fase_scritta` chiamava «novilunio»
	# venti notti di fila - fra cui quella con il disco illuminato al cento per
	# cento. Sulla LUCE non si vedeva niente, perche' il coseno non distingue
	# 200 da 160: era un guasto che si vedeva solo nelle parole.
	var fase := 360.0 - fase_giro if fase_giro > 180.0 else fase_giro

	var eq := eclittiche_in_equatoriali(lambda_l, beta)
	var ha := angolo_orario(eq.x, jd)
	var aa := alt_az(ha, eq.y)

	# IL SOLE, e serve solo a dire da che parte cade la luce sulla Luna. Modello
	# a un termine e mezzo (Meeus cap. 25, «low accuracy»): un centesimo di grado
	# di errore, e qui basterebbe anche molto meno.
	var d_giorni := jd - 2451545.0
	var ms_s := 357.529 + 0.98560028 * d_giorni
	var lambda_s := (280.459 + 0.98564736 * d_giorni
		+ 1.915 * _sin(ms_s) + 0.020 * _sin(2.0 * ms_s))
	var eq_s := eclittiche_in_equatoriali(lambda_s, 0.0)
	var aa_s := alt_az(angolo_orario(eq_s.x, jd), eq_s.y)

	# L'ASSE DELLA LUNA nel cielo di adesso, e da lì come è girata la faccia. Il
	# nord della Luna non è «in alto sullo schermo»: la Luna che sorge a est ha
	# il nord inclinato da una parte, quella che tramonta dall'altra, e in una
	# notte la faccia ruota di decine di gradi. Chi la guarda al telescopio tutta
	# la notte lo vede.
	var aa_asse := alt_az(angolo_orario(POLO_ECLITTICA_AR, jd), POLO_ECLITTICA_DEC)
	var dir_l := direzione(aa.x, aa.y)
	var faccia := cornice(dir_l, direzione(aa_asse.x, aa_asse.y))

	return {
		&"fase": fase,
		&"illuminata": (1.0 + cos(deg_to_rad(fase))) * 0.5,
		&"eta": fposmod(jd - NOVILUNIO_NOTO, SINODICO),
		&"ar": fposmod(eq.x, 360.0),
		&"dec": eq.y,
		&"ha": ha,
		&"alt": aa.x,
		&"az": aa.y,
		&"distanza": r,
		&"diametro": 2.0 * rad_to_deg(asin(RAGGIO_KM / r)),
		&"dir": dir_l,
		&"sole_dir": direzione(aa_s.x, aa_s.y),
		&"luna_nord": faccia[0],
		&"luna_est": faccia[1],
	}


## IL NORD E L'EST DELLA LUNA SUL DISCO, come due versori del mondo.
##
## Il nord è l'asse proiettato sul piano del disco. L'est è il verso in cui la
## Luna ruota — cioè, al centro del disco, `asse × verso_la_Terra` — ed è il
## pezzo che dipende da come è fatto il MONDO, non da come è fatta la Luna: vedi
## `chiralita()`. Con quel segno, la faccia è girata come l'illuminazione, che è
## calcolata nello stesso mondo, e le due cose non possono smentirsi — la falce
## crescente mostra Mare Crisium, come nella realtà.
static func cornice(dir_luna: Vector3, asse: Vector3) -> Array[Vector3]:
	var verso_terra := -dir_luna
	var nord := (asse - verso_terra * asse.dot(verso_terra)).normalized()
	var est := nord.cross(verso_terra) * chiralita()
	return [nord, est]


## SE IL MONDO È DESTRORSO O SPECCHIATO, e il perché questa funzione esiste.
##
## Con l'alto a +Y, il nord a +Z e l'est a +X — la convenzione di `direzione()`,
## che è quella della cupola — la terna (est, nord, alto) è SINISTRORSA: guardando
## il polo, l'est cade a SINISTRA, mentre nel mondo vero cade a destra. È una
## scelta fatta prima della Luna, e con le stelle procedurali non si vede. Con la
## Luna sì: un prodotto vettoriale dà un verso in un mondo e l'opposto nel suo
## specchio, e la faccia uscirebbe girata al contrario della propria luce.
##
## QUINDI IL SEGNO NON SI SCRIVE, SI MISURA: +1 se `direzione()` descrive un mondo
## destrorso, −1 se specchiato. Il giorno che la convenzione venisse raddrizzata,
## la Luna seguirebbe da sola, senza una seconda riga da ricordarsi di cambiare.
static func chiralita() -> float:
	var e := direzione(0.0, 90.0)
	var n := direzione(0.0, 0.0)
	var su := direzione(90.0, 0.0)
	return signf(e.cross(n).dot(su))


## Come si chiama, in italiano, una Luna con quell'angolo di fase. Serve a
## scriverlo: un numero non dice a nessuno che stanotte c'è la luna piena.
##
## LE SOGLIE SONO QUELLE DEGLI ALMANACCHI: i quattro istanti (novilunio, primo
## quarto, plenilunio, ultimo quarto) sono punti, non intervalli, e attorno a
## ciascuno si concede un giorno e mezzo — cioè la finestra in cui a occhio nudo
## la Luna sembra ferma su quella forma.
static func fase_scritta(fase_gradi: float, crescente: bool) -> String:
	var f := fposmod(fase_gradi, 360.0)
	# La distanza dai quattro punti notevoli, in gradi di fase.
	if f > 170.0:
		return "novilunio"
	if f < 10.0:
		return "luna piena"
	if absf(f - 90.0) < 10.0:
		return "primo quarto" if crescente else "ultimo quarto"
	if f > 90.0:
		return "falce crescente" if crescente else "falce calante"
	return "gibbosa crescente" if crescente else "gibbosa calante"


## Sta crescendo? Non si legge dall'angolo di fase — 90 gradi è tanto il primo
## quanto l'ultimo quarto — si legge dall'età: prima di metà mese cresce.
static func crescente(eta_giorni: float) -> bool:
	return eta_giorni < SINODICO * 0.5


## UNA DIREZIONE DEL CIELO IN COORDINATE DEL MONDO.
##
## LA CONVENZIONE È QUELLA DELLA CUPOLA, e non è negoziabile qui: azimut
## `atan2(x, z)`, zero al nord, che in questo modello sta verso +Z — lo dice la
## misura del telescopio, che a declinazione 90 punta ad azimut −1
## (`world/dome_azimuth.gd`, `world/telescope_mount.gd`). Quindi +X è l'est.
## Un segno sbagliato qui farebbe sorgere la Luna a ovest, e sarebbe l'unico
## difetto di questo file che si vede a occhio.
static func direzione(alt_gradi: float, az_gradi: float) -> Vector3:
	var a := deg_to_rad(alt_gradi)
	var z := deg_to_rad(az_gradi)
	return Vector3(cos(a) * sin(z), sin(a), cos(a) * cos(z))


## Il giorno giuliano (numero intero, mezzogiorno UT) di una data gregoriana.
## PUBBLICA perche' `tools/prova_luna.gd` la usa per costruire gli istanti
## dell'almanacco: le date di controllo sono date vere del 1999, non notti di
## questo gioco, e passare dal calendario di gioco per raggiungerle vorrebbe dire
## verificare le effemeridi con la stessa aritmetica che si vuole verificare.
## Fliegel & Van Flandern, con le divisioni intere che il metodo richiede: tutti
## i valori in gioco sono positivi, quindi il troncamento di GDScript coincide
## col pavimento.
static func giuliano_di(anno: int, mese: int, giorno: int) -> int:
	@warning_ignore("integer_division")
	var a := (14 - mese) / 12
	var y := anno + 4800 - a
	var m := mese + 12 * a - 3
	@warning_ignore("integer_division")
	var jdn := (giorno + (153 * m + 2) / 5 + 365 * y
		+ y / 4 - y / 100 + y / 400 - 32045)
	return jdn


## L'inverso: da giorno giuliano a (anno, mese, giorno).
static func _data_da_giuliano(jdn: int) -> Vector3i:
	@warning_ignore("integer_division")
	var a := jdn + 32044
	@warning_ignore("integer_division")
	var b := (4 * a + 3) / 146097
	@warning_ignore("integer_division")
	var c := a - (146097 * b) / 4
	@warning_ignore("integer_division")
	var d := (4 * c + 3) / 1461
	@warning_ignore("integer_division")
	var e := c - (1461 * d) / 4
	@warning_ignore("integer_division")
	var m := (5 * e + 2) / 153
	@warning_ignore("integer_division")
	var giorno := e - (153 * m + 2) / 5 + 1
	@warning_ignore("integer_division")
	var mese := m + 3 - 12 * (m / 10)
	@warning_ignore("integer_division")
	var anno := 100 * b + d - 4800 + m / 10
	return Vector3i(anno, mese, giorno)


## Da eclittiche (longitudine, latitudine) a equatoriali (AR, declinazione), in
## gradi. È la rotazione dell'obliquità, e nient'altro.
##
## PUBBLICA DA QUANDO CI SONO I PIANETI, e per la stessa ragione per cui è
## pubblica `alt_az`: `core/pianeti.gd` guarda lo STESSO cielo dalla STESSA
## latitudine, e una seconda copia di questa rotazione — tre righe, facilissime
## da riscrivere — avrebbe messo i pianeti su un'eclittica e la Luna su un'altra
## il giorno che una delle due venisse corretta.
static func eclittiche_in_equatoriali(lambda_g: float, beta_g: float) -> Vector2:
	var l := deg_to_rad(lambda_g)
	var b := deg_to_rad(beta_g)
	var e := deg_to_rad(OBLIQUITA)
	var dec := asin(sin(b) * cos(e) + cos(b) * sin(e) * sin(l))
	var ar := atan2(sin(l) * cos(e) - tan(b) * sin(e), cos(l))
	return Vector2(rad_to_deg(ar), rad_to_deg(dec))


## L'angolo orario di un'ascensione retta, in gradi, −180..180.
##
## IL TEMPO SIDERALE È QUELLO VERO, non i quindici gradi l'ora tondi di
## `TempoSiderale`: la Terra gira di 15,041 gradi l'ora rispetto alle stelle, e
## la differenza fa quattro decimi di grado in una notte intera. È meno del
## diametro della Luna, quindi le stelle dello shader e questa Luna non si
## contraddicono — ma il numero giusto costa lo stesso e vale in tutte le date,
## mentre l'approssimazione tonda si accumula di un grado alla settimana.
##
## PUBBLICA, come `eclittiche_in_equatoriali` qui sopra: è l'ora del cielo di
## questo osservatorio, e i pianeti la leggono da qui invece di ricopiarla.
static func angolo_orario(ar_gradi: float, jd: float) -> float:
	var gmst := 280.46061837 + 360.98564736629 * (jd - 2451545.0)
	var ha := fposmod(gmst + LONGITUDINE - ar_gradi, 360.0)
	return ha - 360.0 if ha > 180.0 else ha


## Da (angolo orario, declinazione) ad (altezza, azimut da nord verso est), in
## gradi. PUBBLICA perche' e' la formula che il banco confronta con la gemella di
## `SkyGeometry`. Trigonometria sferica classica, la stessa di `SkyGeometry.altezza` —
## che però sta in `phases/`, e `core/` non può conoscerla né viceversa. Il banco
## confronta le due altezze su un campione di angoli: due formule della stessa
## cosa che divergano metterebbero la Luna in un posto e le stelle in un altro.
static func alt_az(ha_gradi: float, dec_gradi: float) -> Vector2:
	var h := deg_to_rad(ha_gradi)
	var d := deg_to_rad(dec_gradi)
	var l := deg_to_rad(LATITUDINE)
	var alt := asin(sin(d) * sin(l) + cos(d) * cos(l) * cos(h))
	var az := atan2(-cos(d) * sin(h), sin(d) * cos(l) - cos(d) * sin(l) * cos(h))
	return Vector2(rad_to_deg(alt), fposmod(rad_to_deg(az), 360.0))


static func _sin(gradi: float) -> float:
	return sin(deg_to_rad(gradi))


static func _cos(gradi: float) -> float:
	return cos(deg_to_rad(gradi))
