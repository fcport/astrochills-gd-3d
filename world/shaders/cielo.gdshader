// IL CIELO DI UNA NOTTE DI LAVORO: stelle, un accenno di Via Lattea e il fondo.
//
// PERCHE' ESISTE. Fino a ieri il fondo della scena era un colore piatto quasi nero
// (`background_mode = 1`): dalla vetrata della sala di controllo e dalla fenditura
// della cupola non si vedeva il cielo, si vedeva il VUOTO. In un gioco che si
// chiama Astrochill e che si fa in un osservatorio, il cielo e' il soggetto: non
// vederlo non e' una mancanza di rifinitura, e' il pezzo che manca.
//
// PROCEDURALE E NON UNA FOTO, e la ragione e' pratica prima che artistica. Una
// panoramica stellata equirettangolare decente pesa decine di megabyte, e alla
// risoluzione che serve per non avere stelle sfocate ne pesa di piu'; qui le
// stelle sono PUNTI ESATTI a qualunque distanza le si guardi, costano un pugno di
// istruzioni per pixel del solo fondo, e non c'e' nessun file da tenere in giro.
//
// LE STELLE STANNO IN UNA GRIGLIA, e non si vede che ci stanno. La direzione di
// vista viene moltiplicata per una scala e divisa in celle cubiche; ogni cella
// tira i dadi e - se li passa - mette una stella in un punto casuale del suo
// QUARTO CENTRALE. Il quarto centrale non e' un dettaglio: e' quello che permette
// di guardare UNA cella sola invece di ventisette. Una stella confinata nel mezzo
// della sua cella non sborda mai oltre il bordo, quindi nessuna viene tagliata a
// meta' - che e' il difetto tipico di questo trucco, e si vede subito perche' i
// tagli si allineano tutti in file.
//
// DUE STRATI, e servono a togliere il ritmo. Con un solo passo di griglia le
// stelle sono tutte alla stessa distanza minima l'una dall'altra, e un cielo cosi'
// si legge come una texture: regolare. Due scale non commensurate si sovrappongono
// e le distanze tornano irregolari come devono essere.
//
// NON E' UN CIELO DA DEPLIANT. La densita' e la luminosita' sono basse apposta: e'
// una notte reale vista a occhio nudo da un monte dell'entroterra, con la valle
// che alza un po' l'orizzonte, non l'astrofotografia a lunga posa che il giocatore
// dovra' fare LUI col telescopio. Se il cielo di sfondo fosse gia' spettacolare,
// la fotografia guadagnata in due ore di posa non avrebbe piu' niente da dare.
shader_type sky;
render_mode use_debanding;

// Il fondo: bruno-blu quasi nero allo zenit, un filo piu' chiaro e piu' caldo verso
// l'orizzonte. Non e' un gradiente decorativo - e' l'inquinamento luminoso della
// valle, che nel 1999 in Italia c'era gia' tutto, ed e' la ragione per cui gli
// osservatori stanno sui monti e guardano in su.
uniform vec3 zenit : source_color = vec3(0.0020, 0.0030, 0.0075);
uniform vec3 orizzonte : source_color = vec3(0.0130, 0.0125, 0.0150);

// Quanto in fretta il chiarore dell'orizzonte muore salendo. Alto = resta basso.
uniform float caduta_orizzonte : hint_range(1.0, 12.0) = 5.0;

// Quante celle su un radiante: piu' alto = stelle piu' fitte e piu' piccole.
uniform float scala_a : hint_range(20.0, 400.0) = 150.0;
uniform float scala_b : hint_range(20.0, 400.0) = 233.0;

// Quante celle su cento hanno una stella, per strato.
uniform float densita_a : hint_range(0.0, 1.0) = 0.16;
uniform float densita_b : hint_range(0.0, 1.0) = 0.09;

// Quanto e' grande il dischetto di una stella, in frazioni di cella.
uniform float raggio_stella : hint_range(0.05, 0.5) = 0.26;

// La scala generale della luminosita' stellare.
uniform float luminosita : hint_range(0.0, 8.0) = 1.0;

// La Via Lattea: un velo, non una fascia da poster.
uniform float via_lattea : hint_range(0.0, 1.0) = 0.35;

// QUANTO SI ALLARGA UNA STELLA PER STARE DENTRO UN PIXEL. Uno e' la correzione
// piena; zero la toglie, e si vede subito cosa toglie - le stelle tornano a
// spegnersi e riaccendersi tutte insieme mentre si gira la testa. Serve a
// `tools/prova_cielo.gd`, che misura proprio quel tremolio: una sonda che non
// puo' vedere il difetto che sorveglia non sta sorvegliando niente.
uniform float antialias : hint_range(0.0, 1.0) = 1.0;

// Il polo del piano galattico: la fascia passa perpendicolare a questa direzione.
// Non e' l'astronomia vera - il cielo di questo gioco non e' mappato su un catalogo
// e non deve esserlo (D-171: non si dichiara quello che non si e' modellato) - e'
// solo un'inclinazione che non coincide con nessun asse della scena, cosi' la fascia
// non sembra allineata all'edificio.
//
// SI LEGGE NEL SISTEMA DELLE STELLE, da quando il cielo gira: la Via Lattea sta
// FRA le stelle, non fra gli alberi, e deve attraversare la fenditura insieme a
// loro. Il valore non e' cambiato, quindi a inizio notte la fascia sta dove stava:
// e' l'unico istante in cui il vecchio significato e il nuovo coincidono.
uniform vec3 polo_galattico = vec3(0.42, 0.78, -0.46);

// L'ASSE ATTORNO A CUI GIRA TUTTO IL CIELO: il polo celeste nord, in coordinate del
// mondo. La sua ALTEZZA SULL'ORIZZONTE VALE LA LATITUDINE - 43,9 gradi, Montegrimano
// - e il suo azimut e' il nord, che in questo modello sta verso +Z. Non e' un numero
// scelto qui: lo scrive `gen_blockout.py` leggendo `LATITUDINE` da `geometria.py`,
// che e' la stessa riga da cui il modellatore inclina l'asse polare del telescopio.
//
// E' DICHIARATO COME VETTORE e non come due angoli perche' cosi' lo shader non ha
// convenzioni da rispettare: gli arriva una direzione, e ci gira attorno.
uniform vec3 polo_celeste = vec3(0.0, 0.6934, 0.7206);

// DI QUANTO IL CIELO HA GIRATO da inizio notte, in radianti. Lo scrive
// `world/tempo_siderale.gd` a ogni fotogramma: quindici gradi per ogni ora di gioco,
// che e' la sola velocita' che il cielo abbia.
//
// ZERO E' IL CIELO DI SEMPRE, ed e' voluto: a inizio notte questo shader disegna
// esattamente quello che disegnava prima che la rotazione esistesse.
uniform float giro = 0.0;


// --- LA LUNA -----------------------------------------------------------------
//
// NON GIRA CON LE STELLE, e per questo si disegna su `dir` e non su `fisso`. Nel
// sistema delle stelle una stella sta ferma per sempre; la Luna no - percorre
// tredici gradi al giorno fra le stelle, mezzo grado all'ora, cioe' il proprio
// diametro. Chi glielo ricalcola a ogni fotogramma e' `world/luce_di_luna.gd`,
// che sa che notte e' e legge le effemeridi vere di quella data.
//
// E LA FASE NON ARRIVA COME NUMERO, arriva come GEOMETRIA: qui ci sono due
// direzioni - dov'e' la Luna e dov'e' il Sole - e da che parte sia illuminata lo
// decide un prodotto scalare, esattamente come lo decide il sistema solare. Un
// uniform `fase` sarebbe la seconda verita' sulla stessa cosa, e il giorno che
// divergesse si vedrebbe una falce che guarda dalla parte sbagliata mentre tutti
// i conti tornano.

// Dove sta la Luna, in coordinate del mondo. Il default guarda sotto i piedi,
// cioe' la Luna e' tramontata: un cielo che si aprisse senza nessuno a scrivere
// questo parametro non deve mostrare una luna inventata allo zenit.
uniform vec3 luna_dir = vec3(0.0, -1.0, 0.0);

// Dove sta il Sole. Di notte e' sotto l'orizzonte e non illumina niente di
// quello che si vede: serve SOLO a dire da che parte cade la luce sulla Luna.
uniform vec3 sole_dir = vec3(0.0, -1.0, 0.0);

// Il raggio del disco COME SI DISEGNA, in radianti. Il default e' il vero:
// mezzo grado di diametro, 0,00452 di raggio, ed e' il numero che quasi tutti
// sbagliano - disegnata come la si ricorda, la Luna verrebbe cinque volte
// troppo grande.
//
// MA CHI LO SCRIVE LO INGRANDISCE, ed e' una bugia dichiarata: il mondo si
// disegna in un SubViewport da 640x360 con un campo visivo di 75 gradi, dove
// mezzo grado sono DUE PIXEL E MEZZO. In due pixel e mezzo non esiste nessuna
// fase - non c'e' differenza fra una falce e una luna piena - e questo intero
// lavoro esiste per far vedere quella differenza. Il fattore e il conto stanno
// in `world/luce_di_luna.gd`, dove sta anche il motivo.
//
// QUELLO CHE RESTA VERO E' IL RAPPORTO: il fattore e' costante, quindi il
// cinque per cento di differenza fra perigeo e apogeo - la superluna - passa
// intatto, e una luna piena di dicembre resta piu' grande di una di giugno.
uniform float luna_raggio = 0.00452;

// Quanto si vede il disco: 0 sotto l'orizzonte, 1 alta e limpida. E' l'aria di
// mezzo, non la fase - la parte illuminata di una falce e' luminosa quanto una
// luna piena, e' soltanto piu' piccola.
uniform float luna_luce = 0.0;

// Quanto chiaro fa la Luna sul resto del cielo: frazione illuminata per seno
// dell'altezza. E' LO STESSO NUMERO che comanda l'energia della direzionale -
// il fondo che si schiarisce, le stelle che spariscono e la luce che entra
// dalla finestra devono crescere insieme o si smentiscono a vicenda.
uniform float luna_chiarore = 0.0;

// COME E' GIRATA LA FACCIA: il nord e l'est della Luna sul disco, in coordinate
// del mondo. Li scrive `world/luce_di_luna.gd` da `core/luna.gd`, che li ricava
// dall'asse vero della Luna nel cielo di quell'istante - la faccia ruota nel
// corso della notte, e al telescopio si vede.
uniform vec3 luna_nord = vec3(0.0, 1.0, 0.0);
uniform vec3 luna_est = vec3(1.0, 0.0, 0.0);

// LA LUNA VERA: il mosaico della camera del Lunar Reconnaissance Orbiter e le
// pendenze dall'altimetro laser dello stesso satellite (NASA, pubblico dominio -
// `tools/prendi_luna.py`). Mappe cilindriche centrate sulla longitudine zero.
// Senza file restano i default - bianco e piatto - e `luna_mappe` a zero: la
// Luna liscia di prima, con la fase giusta.
uniform sampler2D luna_colore : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D luna_rilievo : hint_normal, filter_linear_mipmap, repeat_enable;

// La luminosita' media della faccia visibile, che si divide via: la mappa dice
// dove la Luna e' chiara e dove scura, non quanto e' chiara in tutto. La misura
// `LuceDiLuna.albedo_media()` sul file.
uniform float luna_albedo_media = 1.0;

// 1 se le mappe ci sono, 0 se no.
uniform float luna_mappe = 0.0;


// --- I PIANETI ---------------------------------------------------------------
//
// CINQUE PUNTI CHE NON SONO STELLE, e sono l'unica cosa di questo cielo che si
// possa chiamare per nome. Le stelle qui sono procedurali: un campo plausibile in
// cui non c'e' niente da riconoscere. Mercurio, Venere, Marte, Giove e Saturno
// invece sono OGGETTI - stanno in un posto preciso a un'ora precisa, sono piu'
// luminosi di quasi tutte le stelle, e chi alza gli occhi da un osservatorio li
// riconosce prima di qualunque costellazione.
//
// NON GIRANO CON LE STELLE, e quindi si disegnano su `dir` e non su `fisso`,
// esattamente come la Luna e per la stessa ragione: un pianeta si sposta fra le
// stelle - e' il suo nome che lo dice - e chi glielo ricalcola a ogni fotogramma
// e' `world/pianeti_in_cielo.gd`, che sa che notte e' e a che ora.
//
// TRE ARRAY E NESSUN NOME, ed e' voluto: lo shader non sa quale sia Giove. Sa che
// ci sono cinque cose, dove stanno, di che colore sono e quanto fanno luce. Chi
// decide tutto il resto - compreso se una di queste cinque stanotte si veda o no
// - e' il nodo, in un posto solo.
//
// LE DIMENSIONI SONO CINQUE E RESTANO CINQUE: i pianeti a occhio nudo sono
// questi. Urano e' al limite dell'occhio e in un cielo disegnato non si
// distinguerebbe da una stella; Nettuno non si vede affatto.

// Dove stanno, in coordinate del mondo. Il default sarebbe «sotto i piedi»,
// cioe' tramontati - la stessa posa della Luna assente - MA QUI NON SI PUO'
// SCRIVERE: il linguaggio degli shader di Godot non ammette valori di default
// sugli array di uniform («Setting default values to uniform arrays is not
// supported»). Percio' il valore di partenza sta NEL .tscn, dove lo scrive
// `gen_blockout.py` e dove il suo controllo sul file lo va a cercare: senza,
// questi array partono da zero, e un array di direzioni nulle vuol dire cinque
// pianeti allo zenit con `acos(0)` - cioe' esattamente i pianeti inventati che
// il default serviva a evitare. E' un vincolo del motore dichiarato qui perche'
// la riga che lo compensa e' in un altro file.
uniform vec3 pianeta_dir[5];

// Il colore di ciascuno a occhio nudo. Poco saturo, come sono: l'arancione di
// Marte e il giallo paglia di Saturno si notano, il resto e' quasi bianco. Li
// scrive il nodo una volta sola, in `_ready`: non cambiano con l'ora.
//
// `source_color` qui e' una dichiarazione d'intenzione e non una conversione:
// Godot non converte gli ARRAY di uniform, e va bene cosi' - il colore di un
// astro e' un rapporto fra flussi, cioe' un numero lineare.
uniform vec3 pianeta_tinta[5] : source_color;

// QUANTO FA LUCE CIASCUNO, e ZERO VUOL DIRE NON DISEGNARLO. Non e' la magnitudine
// - quella e' un numero che cresce all'incontrario e vale meno di zero per i piu'
// luminosi - e' gia' la luce da mettere sullo schermo, con dentro l'aria che il
// pianeta deve attraversare e il chiaro di luna che gli sta attorno. Il conto,
// con i suoi perche', sta in `world/pianeti_in_cielo.gd`.
//
// UN PIANETA BASSO NON E' UN PIANETA SPENTO: a un grado sull'orizzonte l'aria si
// mangia nove magnitudini, cioe' quattromila volte la luce, e Venere - che e' la
// cosa piu' luminosa del cielo dopo la Luna - sparisce. E' lo stesso motivo per
// cui le stelle qui sotto si spengono guardando basso, ma qui il conto e' vero e
// per ciascuno, non una sfumatura sull'altezza.
uniform float pianeta_luce[5];

// QUANTO E' LARGO IL PUNTO, IN PIXEL. E' un numero in PIXEL e non in gradi, ed e'
// la differenza fra un pianeta e la Luna: la Luna ha una dimensione vera - mezzo
// grado - e si disegna grande quanto e'; un pianeta a occhio nudo non ha
// dimensione, e' un punto, e quello che se ne vede e' quanto lo allarga l'occhio
// (o qui, il pixel). Disegnarlo grande come il suo disco vero - Giove misura
// quaranta secondi d'arco, un ventesimo di pixel - vorrebbe dire non disegnarlo.
//
// E' LA LARGHEZZA DELLA GAUSSIANA, cioe' il raggio a cui il punto vale il
// sessanta per cento: uno vuol dire un nucleo di due pixel e mezzo. Vedi
// `pianeti()` per il motivo per cui e' una gaussiana e non il profilo delle
// stelle - e' un difetto vero, trovato dal provino.
uniform float pianeta_raggio : hint_range(0.5, 4.0) = 1.0;



// Tre numeri pseudocasuali da una cella. Hash intero-in-virgola classico: economico
// e senza texture di rumore da caricare.
vec3 dadi(vec3 cella) {
	vec3 p = fract(cella * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yzz) * p.zyx);
}


// Un valore fra 0 e 1 che varia dolcemente: serve a screziare la Via Lattea, che
// uniforme sembrerebbe una decalcomania.
float rumore(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n = 0.0;
	for (int dx = 0; dx < 2; dx++) {
		for (int dy = 0; dy < 2; dy++) {
			for (int dz = 0; dz < 2; dz++) {
				vec3 o = vec3(float(dx), float(dy), float(dz));
				float w = mix(1.0 - f.x, f.x, o.x)
						* mix(1.0 - f.y, f.y, o.y)
						* mix(1.0 - f.z, f.z, o.z);
				n += dadi(i + o).x * w;
			}
		}
	}
	return n;
}


// Ruota `v` attorno all'asse unitario `k` di `a` radianti. E' la formula di
// Rodrigues, tre prodotti e una somma: girare il cielo costa questo, per pixel del
// solo fondo, e non c'e' modo piu' economico di girare una sfera.
vec3 ruota(vec3 v, vec3 k, float a) {
	float c = cos(a);
	return v * c + cross(k, v) * sin(a) + k * dot(k, v) * (1.0 - c);
}


// Uno strato di stelle. Torna gia' colorato: le stelle non sono tutte bianche, e
// quel poco di colore che hanno e' la sola cosa che le fa leggere come stelle
// invece che come polvere sullo schermo.
vec3 strato(vec3 dir, float scala, float densita, float pixel) {
	vec3 p = dir * scala;
	vec3 cella = floor(p);
	vec3 d = dadi(cella);
	if (d.z > densita) {
		return vec3(0.0);
	}
	// Il quarto centrale della cella: cosi' il dischetto non sborda mai.
	vec3 centro = cella + vec3(0.25) + 0.5 * vec3(d.x, d.y, fract(d.z * 71.3));
	// UNA STELLA NON PUO' ESSERE PIU' PICCOLA DI UN PIXEL, e questa e' la riga che
	// toglie il difetto piu' fastidioso di tutto il cielo. Il dischetto disegnato
	// misura poco piu' di mezzo pixel: girando la testa il suo centro passa da una
	// parte all'altra del pixel e la stella si ACCENDE E SI SPEGNE, mille volte,
	// tutte insieme. Non e' scintillio - le stelle vere scintillano di intensita',
	// non di esistenza - ed e' l'aliasing piu' classico che ci sia.
	//
	// LA CURA NON E' INGRANDIRE, E' ALLARGARE CONSERVANDO LA LUCE. Si porta il
	// raggio ad almeno un pixel e si divide la luminosita' per l'area guadagnata:
	// la stella copre sempre lo stesso numero di fotoni, distribuiti su almeno un
	// pixel. Ingrandire e basta darebbe un cielo di palline; questo da' stelle che
	// stanno ferme e cambiano solo di intensita', che e' quello che fanno davvero.
	float r_cella = max(raggio_stella, pixel * scala * antialias);
	float conserva = (raggio_stella * raggio_stella) / (r_cella * r_cella);
	float dist = length(p - centro) / r_cella;
	// Il profilo: nucleo pieno e alone che muore in fretta. Elevato al quadrato
	// perche' una stella e' un punto, non una macchia.
	float disco = max(0.0, 1.0 - dist);
	disco = disco * disco * disco * conserva;
	// LA MAGNITUDINE E' DISTRIBUITA, non uniforme: poche stelle forti e molte
	// deboli. Alla quarta potenza il sorteggio piatto diventa una distribuzione in
	// cui la stella luminosa e' rara - che e' quello che si vede alzando la testa.
	float mag = fract(d.x * 313.7 + d.y * 97.1);
	mag = mag * mag * mag * mag;
	float forza = (0.08 + 0.92 * mag) * disco;
	// Il colore: fra l'ambra di una gigante fredda e l'azzurro di una calda,
	// centrato sul bianco. Poco - le stelle sono quasi bianche a occhio nudo.
	float t = fract(d.y * 41.3 + d.z * 17.7);
	vec3 tinta = mix(vec3(1.00, 0.88, 0.72), vec3(0.80, 0.88, 1.00), t);
	return tinta * forza;
}


// LA LUNA: il disco piu' l'alone che l'aria le fa attorno. Torna gia' colorata.
//
// SI DISEGNA PER GEOMETRIA, non per maschera: si prende il punto del disco che
// si sta guardando, si ricava la NORMALE della sfera li' sopra, e la si
// illumina col Sole. Ne esce la fase giusta, orientata come la orienta il cielo,
// senza che nessuno debba dire quale sia.
vec3 luna(vec3 dir, float pixel) {
	// Tramontata: non c'e' niente da disegnare, e nemmeno da calcolare. E' il
	// caso di un terzo delle notti del mese, e di tutte le ore in cui la Luna
	// sta dall'altra parte della Terra.
	if (luna_luce <= 0.0) {
		return vec3(0.0);
	}
	float cd = dot(dir, luna_dir);
	float ang = acos(clamp(cd, -1.0, 1.0));

	// LA FRAZIONE ILLUMINATA, ricavata invece che ricevuta. L'angolo di fase e'
	// l'angolo Sole-Luna-Terra: `-dot(sole, luna)` ne e' il coseno, e la formula
	// classica (1 + cos i)/2 diventa questa. Serve alla luce cenere.
	float k = 0.5 * (1.0 - dot(sole_dir, luna_dir));

	// L'ALONE, e non e' decorazione: e' la ragione per cui una notte di luna si
	// riconosce senza guardare la Luna. L'aria diffonde la sua luce in una
	// macchia larga decine di gradi, e mezzo grado di disco su tutto il cielo
	// non basterebbe a leggere come «c'e' la luna». Due esponenziali: una
	// stretta attorno al disco, una larga che muore in una trentina di gradi.
	float vicino = exp(-ang * 26.0);
	float largo = exp(-ang * ang * 5.0);
	vec3 alone = vec3(0.72, 0.80, 1.00) * (vicino * 0.050 + largo * 0.013) * k;

	// FUORI DAL DISCO C'E' SOLO L'ALONE, e tutto quello che segue - due letture di
	// texture e un po' di trigonometria - si fa solo dove serve. La Luna occupa
	// una frazione minuscola del cielo, lo shader gira su tutto il fondo.
	if (ang > luna_raggio * 1.5) {
		return alone * luna_luce;
	}

	// LA NORMALE DELLA SUPERFICIE nel punto che si sta guardando. La Luna e' una
	// sfera lontana: il punto a distanza `u` dal centro del disco (in raggi) ha
	// la normale che esce dal piano del disco di sqrt(1 - u*u). Al centro `u` e'
	// zero e la direzione radiale non esiste - per questo e' moltiplicata per
	// `u`, e per questo il vettore nullo si sostituisce invece di normalizzarlo.
	//
	// E IL SEGNO E' MENO, che e' l'errore che il provino ha trovato al primo
	// scatto. `luna_dir` va DA CHI GUARDA VERSO la Luna; la normale del punto che
	// sta al centro del disco va dalla Luna VERSO CHI GUARDA, cioe' dalla parte
	// opposta. Con il piu' le fasi uscivano tutte complementari - luna piena
	// disegnata come falce e falce come piena - e sarebbe stato invisibile a ogni
	// prova numerica, perche' l'angolo di fase, la data, la luce e l'energia
	// erano tutti giusti: sbagliava solo il disegno.
	vec3 o = dir - luna_dir * cd;
	float lo = length(o);
	vec3 radiale = lo > 1e-7 ? o / lo : vec3(0.0);
	float u = clamp(ang / luna_raggio, 0.0, 1.0);
	vec3 n = normalize(-luna_dir * sqrt(max(0.0, 1.0 - u * u)) + radiale * u);

	// DOVE SI STA GUARDANDO, SULLA LUNA: latitudine e longitudine selenografiche
	// del punto, dalla normale e dalla cornice della faccia. Il centro del disco
	// e' (0, 0) - le librazioni non ci sono, ed e' dichiarato in `core/luna.gd`.
	vec3 terra = -luna_dir;
	float lat = asin(clamp(dot(n, luna_nord), -1.0, 1.0));
	float lon = atan(dot(n, luna_est), dot(n, terra));
	vec2 uv = vec2(0.5 + lon / TAU, 0.5 - lat / PI);

	// IL RILIEVO: la mappa porta la pendenza vera del suolo nel riferimento
	// locale (est, nord, su) di quel punto, e qui la si gira nel mondo. Le due
	// tangenti sono le derivate della sfera in longitudine e in latitudine: si
	// ricavano dalla stessa cornice della faccia, quindi seguono l'est della
	// Luna qualunque sia il verso del mondo.
	vec3 t_est = -sin(lon) * terra + cos(lon) * luna_est;
	vec3 t_nord = -sin(lat) * (cos(lon) * terra + sin(lon) * luna_est) + cos(lat) * luna_nord;
	vec3 pendenza = texture(luna_rilievo, uv).rgb * 2.0 - 1.0;
	vec3 nr = normalize(mix(n, normalize(n * pendenza.z + t_est * pendenza.x + t_nord * pendenza.y),
			luna_mappe));

	// LA LUCE SULLA REGOLITE: la legge di Lommel-Seeliger, 2·μ0/(μ0 + μ), con μ0
	// il coseno verso il Sole e μ quello verso chi guarda. E' la fotometria dei
	// corpi coperti di polvere, e fa due cose che una lambertiana non fa: a luna
	// piena μ0 e μ coincidono e il disco resta PIATTO fino al bordo - l'effetto
	// che si vede a occhio nudo - e al terminatore la luce muore gradualmente,
	// cosi' che le pendenze del rilievo contano esattamente dove i crateri si
	// vedono davvero. Lontano dal terminatore il rilievo sparisce, come alla
	// luna piena, dove al telescopio non c'e' un'ombra.
	//
	// Il minimo su μ evita la divisione per zero al bordo, dove la normale del
	// disco e' perpendicolare alla vista.
	float mu0 = max(dot(nr, sole_dir), 0.0);
	float mu = max(dot(nr, terra), 0.02);
	float acceso = 2.0 * mu0 / (mu0 + mu);

	// La faccia: il colore del mosaico diviso per la sua media, cosi' che i mari
	// siano piu' scuri e gli altipiani piu' chiari senza che il disco intero cambi
	// luminosita' rispetto a quella gia' tarata.
	vec3 suolo = mix(vec3(1.00, 0.97, 0.91),
			texture(luna_colore, uv).rgb / max(luna_albedo_media, 1e-3), luna_mappe);

	// LA LUCE CENERE: la parte in ombra non e' nera. La illumina la TERRA, che
	// vista da lassu' e' piena quando la Luna e' nuova - «la luna vecchia in
	// braccio alla nuova», ed e' il motivo per cui di una falce sottile si vede
	// comunque tutto il tondo.
	float cenere = 0.020 * (1.0 - k);

	// IL BORDO ANTIALIASATO, con la stessa misura che tiene ferme le stelle:
	// `pixel` dice quanto cielo sta in un pixel. Senza, a questa risoluzione il
	// disco avrebbe la scaletta e le cornerebbe la falce.
	float bordo = max(pixel, 1e-5);
	float dentro = 1.0 - smoothstep(luna_raggio - bordo, luna_raggio + bordo, ang);

	// 1,3 VOLTE L'ALBEDO MEDIA: gli altipiani passano l'unita' e il tonemapping li
	// porta quasi al bianco, i mari restano sotto e si leggono grigi. Era 2,4 finche'
	// il disco era liscio, e con la faccia vera a 2,4 bruciava tutto: altipiani e
	// mari finivano entrambi nella spalla della curva ACES, e la faccia si vedeva
	// appena, come in una foto sovraesposta. A occhio nudo i mari si vedono
	// benissimo - sono la cosa che tutti chiamano «la faccia» - e questa e' la
	// luminosita' a cui si vedono. Il resto del cielo sta comunque sotto i
	// centesimi: la Luna resta di gran lunga la cosa piu' chiara lassu'.
	vec3 disco = suolo * (acceso + cenere) * dentro * 1.3;
	return (disco + alone) * luna_luce;
}


// I PIANETI: cinque punti, ciascuno col suo colore e la sua luce. Torna gia'
// colorato, come `strato` e `luna`.
//
// SI ESCE SUBITO PER QUELLI CHE NON CI SONO, e nella notte tipica sono tre su
// cinque: un confronto e via, prima di qualunque trigonometria. Questo ciclo gira
// per ogni pixel del fondo.
//
// IL PROFILO E' UNA GAUSSIANA, E LA PRIMA STESURA AVEVA QUELLO DELLE STELLE -
// nucleo pieno e caduta al cubo su poco piu' di un pixel. Sembrava la scelta
// ovvia: un pianeta a occhio nudo e' un punto come una stella. E il provino
// (`tools/scatta_pianeti.gd`) ha trovato SATURNO SPARITO: luce dichiarata 1,28,
// misurata sullo schermo ZERO. Il motivo e' che un profilo appuntito su un
// pixel vale quasi tutto solo nel suo centro esatto, e un pianeta cade dove
// capita DENTRO il pixel: mezzo pixel fuori centro, e di quel nucleo ne resta un
// sesto. Non era Saturno a essere debole, era Saturno a essere caduto male.
//
// UNA GAUSSIANA LARGA UN PIXEL E' PIATTA DOVE SERVE: fra il centro di un pixel e
// il suo angolo perde il ventidue per cento e non il cinque sesti, quindi un
// pianeta vale quanto deve valere ovunque cada, e girando la testa non pulsa.
// E' lo stesso problema che `strato()` risolve allargando le stelle - un punto
// piu' piccolo di un pixel si accende e si spegne - ma qui non si puo'
// «conservare la luce» dividendo per l'area: una stella in meno non la nota
// nessuno, un PIANETA che si spegne e' la cosa che il giocatore stava cercando.
//
// L'ALONE INVECE E' FISICO: la luce forte sborda, nell'aria e nell'occhio.
// Siccome e' moltiplicato per la stessa `luce` del nucleo, Venere se lo porta
// dietro largo e Saturno quasi per niente - e non c'e' nessuna regola che dica
// «i pianeti luminosi brillano di piu'», viene fuori da sola.
//
// QUATTRO CENTESIMI SU DUE RAGGI E MEZZO, E PRIMA ERANO DIECI SU QUATTRO: cosi'
// larghi i pianeti diventavano PALLE. Misurato sul provino, a 0,10 Giove veniva
// 0,75 gradi a meta' luce e un grado e mezzo contando l'alone - a schermo intero
// quasi tre volte la Luna, che di gradi ne misura mezzo - e in cielo sembravano
// due lampioni. A 0,04 restano 0,53 e 0,76, cioe' un punto che sfavilla.
//
// E IL NUCLEO NON SI TOCCA. La tentazione era stringere `pianeta_raggio`: a 0,5 i
// pianeti sono davvero puntini (0,26 gradi), ma torna il difetto che la gaussiana
// larga era li' per risolvere - un nucleo piu' stretto del pixel si accende e si
// spegne a seconda di dove cade dentro di esso, e Saturno sparisce girando la
// testa. La dimensione la fa l'alone, che e' la parte che l'occhio aggiunge; il
// nucleo e' la parte che tiene il pianeta acceso.
vec3 pianeti(vec3 dir, float pixel) {
	vec3 somma = vec3(0.0);
	for (int i = 0; i < 5; i++) {
		if (pianeta_luce[i] <= 0.0) {
			continue;
		}
		float ang = acos(clamp(dot(dir, pianeta_dir[i]), -1.0, 1.0));
		float r = max(pixel, 1e-5) * pianeta_raggio;
		float dist = ang / r;
		float nucleo = exp(-0.5 * dist * dist);
		float alone = exp(-ang / (r * 2.5)) * 0.04;
		somma += pianeta_tinta[i] * (nucleo + alone) * pianeta_luce[i];
	}
	return somma;
}


void sky() {
	vec3 dir = normalize(EYEDIR);

	// IL CIELO GIRA E IL PAESAGGIO NO, e questa e' la riga che tiene separate le due
	// cose. `dir` e' dove si sta guardando RISPETTO ALLA TERRA: sotto sta il prato,
	// su sta lo zenit, e non cambiano mai. `fisso` e' la stessa direzione letta
	// nel sistema DELLE STELLE, che gira attorno al polo celeste di quindici gradi
	// l'ora - e nel sistema delle stelle una stella sta ferma per sempre.
	//
	// SI GIRA ALL'INDIETRO, e non e' un segno da aggiustare a occhio: il cielo che
	// gira di `giro` in avanti e' lo stesso che guardarlo da un sistema girato di
	// `giro` all'indietro. Il verso e' misurato, non dedotto - `tools/prova_rotazione.gd`
	// lo verifica facendo inseguire una stella al telescopio, e con il segno
	// sbagliato il tubo la perde al doppio della velocita' invece di tenerla.
	vec3 fisso = ruota(dir, normalize(polo_celeste), -giro);

	// Il fondo. `dir.y` va da -1 (sotto) a 1 (zenit); sotto l'orizzonte non c'e'
	// niente da vedere perche' c'e' il prato, ma il colore ci sta lo stesso -
	// dalla vetrata si vede il cielo BASSO, ed e' li' che il gradiente conta.
	float su = clamp(dir.y, 0.0, 1.0);
	vec3 fondo = mix(orizzonte, zenit, pow(su, 1.0 / caduta_orizzonte));

	// La Via Lattea: la distanza angolare dal piano galattico, screziata.
	float dal_piano = abs(dot(fisso, normalize(polo_galattico)));
	float fascia = exp(-dal_piano * dal_piano * 26.0);
	fascia *= 0.45 + 0.55 * rumore(fisso * 9.0);
	fondo += vec3(0.85, 0.88, 1.00) * fascia * via_lattea * 0.010;

	// QUANTO CIELO STA IN UN PIXEL, in radianti. Si misura invece di dichiararlo:
	// dipende dalla risoluzione e dal campo visivo, e una costante scritta qui
	// sarebbe giusta su un solo schermo. `dFdx` e `dFdy` dicono di quanto cambia la
	// direzione di vista fra questo pixel e il suo vicino, che e' esattamente la
	// domanda.
	float pixel = 0.5 * (length(dFdx(dir)) + length(dFdy(dir)));

	vec3 stelle = strato(fisso, scala_a, densita_a, pixel)
			+ strato(fisso, scala_b, densita_b, pixel);

	// LE STELLE SI SPENGONO SULL'ORIZZONTE, e non e' un vezzo: l'aria che si
	// attraversa guardando basso e' molte volte quella che si attraversa guardando
	// su, e le stelle basse sono sempre piu' fioche. Senza questo, la vetrata della
	// sala di controllo - che guarda dritta all'orizzonte - mostrava le stelle piu'
	// brillanti proprio dove nella realta' non se ne vede quasi nessuna.
	stelle *= smoothstep(-0.02, 0.28, dir.y);

	// E SI SPENGONO ANCHE PER LA LUNA, che e' la cosa che questo cielo non sapeva
	// fare e che decide se stanotte si lavora. Con la luna piena alta il fondo del
	// cielo diventa lattiginoso e restano solo le stelle piu' forti: e' il motivo
	// per cui un astrofotografo guarda il calendario prima del meteo, ed e' anche
	// il modo in cui il gioco lo puo' dire senza scriverlo da nessuna parte.
	//
	// DUE TERZI E NON TUTTE: alla luna piena vera, a occhio nudo, di stelle ne
	// restano una manciata. Qui il cielo e' gia' tarato basso per un occhio
	// adattato al buio (`luminosita` vale uno), e spegnerlo del tutto lascerebbe
	// una fenditura vuota invece di un cielo lavato.
	stelle *= mix(1.0, 0.35, clamp(luna_chiarore, 0.0, 1.0));
	fondo += vec3(0.42, 0.52, 0.86) * luna_chiarore * 0.008;

	// I PIANETI SI SOMMANO E NON SI OCCLUDONO, ed e' una semplificazione
	// dichiarata: un pianeta che passasse dietro il disco della Luna si vedrebbe
	// attraverso. Succede un paio di volte l'anno in tutto il cielo, dura
	// un'ora, e per vederla in questo gioco bisognerebbe che capitasse in una
	// delle trenta notti del calendario.
	COLOR = fondo + stelle * luminosita + luna(dir, pixel) + pianeti(dir, pixel);
}
