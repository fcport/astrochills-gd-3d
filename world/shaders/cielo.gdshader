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

// Il polo del piano galattico: la fascia passa perpendicolare a questa direzione.
// Non e' l'astronomia vera - il cielo di questo gioco non e' mappato su un catalogo
// e non deve esserlo (D-171: non si dichiara quello che non si e' modellato) - e'
// solo un'inclinazione che non coincide con nessun asse della scena, cosi' la fascia
// non sembra allineata all'edificio.
uniform vec3 polo_galattico = vec3(0.42, 0.78, -0.46);


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


// Uno strato di stelle. Torna gia' colorato: le stelle non sono tutte bianche, e
// quel poco di colore che hanno e' la sola cosa che le fa leggere come stelle
// invece che come polvere sullo schermo.
vec3 strato(vec3 dir, float scala, float densita) {
	vec3 p = dir * scala;
	vec3 cella = floor(p);
	vec3 d = dadi(cella);
	if (d.z > densita) {
		return vec3(0.0);
	}
	// Il quarto centrale della cella: cosi' il dischetto non sborda mai.
	vec3 centro = cella + vec3(0.25) + 0.5 * vec3(d.x, d.y, fract(d.z * 71.3));
	float dist = length(p - centro) / raggio_stella;
	// Il profilo: nucleo pieno e alone che muore in fretta. Elevato al quadrato
	// perche' una stella e' un punto, non una macchia.
	float disco = max(0.0, 1.0 - dist);
	disco = disco * disco * disco;
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


void sky() {
	vec3 dir = normalize(EYEDIR);

	// Il fondo. `dir.y` va da -1 (sotto) a 1 (zenit); sotto l'orizzonte non c'e'
	// niente da vedere perche' c'e' il prato, ma il colore ci sta lo stesso -
	// dalla vetrata si vede il cielo BASSO, ed e' li' che il gradiente conta.
	float su = clamp(dir.y, 0.0, 1.0);
	vec3 fondo = mix(orizzonte, zenit, pow(su, 1.0 / caduta_orizzonte));

	// La Via Lattea: la distanza angolare dal piano galattico, screziata.
	float dal_piano = abs(dot(dir, normalize(polo_galattico)));
	float fascia = exp(-dal_piano * dal_piano * 26.0);
	fascia *= 0.45 + 0.55 * rumore(dir * 9.0);
	fondo += vec3(0.85, 0.88, 1.00) * fascia * via_lattea * 0.010;

	vec3 stelle = strato(dir, scala_a, densita_a) + strato(dir, scala_b, densita_b);

	// LE STELLE SI SPENGONO SULL'ORIZZONTE, e non e' un vezzo: l'aria che si
	// attraversa guardando basso e' molte volte quella che si attraversa guardando
	// su, e le stelle basse sono sempre piu' fioche. Senza questo, la vetrata della
	// sala di controllo - che guarda dritta all'orizzonte - mostrava le stelle piu'
	// brillanti proprio dove nella realta' non se ne vede quasi nessuna.
	stelle *= smoothstep(-0.02, 0.28, dir.y);

	COLOR = fondo + stelle * luminosita;
}
