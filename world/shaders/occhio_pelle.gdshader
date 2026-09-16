// LA PELLE attorno all'occhio nel cielo, e le sue palpebre.
//
// È la pelle del tentacolo (`assets/textures/pelle-polpo`, dalla stessa fotografia),
// perché è la stessa creatura. Quello che questo shader aggiunge è come la pelle
// FINISCE e come COMPARE, ed è tutto nel retinato:
//
//   * NON HA UN BORDO. Oltre `sfuma_da` la pelle si sgrana a puntini fino a sparire
//     nel cielo: la testa di cui quest'occhio fa parte non si vede dove finisca, che
//     è la metà dell'orrore e la stessa regola del tentacolo, la cui cima si
//     dissolve prima che lo sguardo ci arrivi.
//   * COMPARE DAL CENTRO. `presenza` spinge in fuori un fronte: prima c'è l'occhio
//     chiuso, poi la pelle attorno che si allarga nel cielo come una macchia. Il
//     raggio di ogni vertice arriva in UV2.x, già diviso per il raggio della testa.
//   * E LA MACCHIA NON È TONDA. Con il raggio e basta la pelle finiva in un cerchio
//     retinato perfetto, che da lontano era un'icona e non una cosa. Il raggio si
//     deforma con cinque onde attorno all'asse, a frequenze intere perché al giro si
//     richiudano. L'ANGOLO SI CALCOLA PER PIXEL, dalla posizione: passato per vertice
//     salta da +π a -π fra due spicchi, e il triangolo in mezzo interpola tutte le
//     fasi — nel cielo c'era una riga di puntini. E fra i puntini la pelle si fa SCURA:
//     sparisce nel buio prima di sgranarsi, che è come sparisce una cosa di notte.
//
// IL RETINATO È PER PIXEL, come il `DISTANCE_FADE_PIXEL_DITHER` del tentacolo: sulla
// risoluzione bassa del gioco è lo stesso retinato della PlayStation, e scrive la
// profondità come un materiale opaco - niente ordinamento di trasparenze su una cosa
// larga un chilometro.
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D colore : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D normale : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D ruvidita : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float rilievo = 0.8;

uniform float presenza = 1.0;
// Da dove, in frazione del raggio della testa, la pelle comincia a sgranarsi.
uniform float sfuma_da = 0.45;
// Quanto è largo il fronte che avanza comparendo.
uniform float fronte_largo = 0.25;

varying float raggio;
varying vec2 piano;

float soglia(vec2 f) {
	int x = int(mod(f.x, 4.0));
	int y = int(mod(f.y, 4.0));
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[y * 4 + x]) + 0.5) / 16.0;
}

void vertex() {
	raggio = UV2.x;
	piano = VERTEX.xy;
}

void fragment() {
	float giro = atan(piano.y, piano.x);
	// Le fasi scorrono col raggio: i lobi non escono dritti dal centro come le punte
	// di una stella - la prima stesura, con due onde sole, disegnava una stella marina
	// - ma storti, e diversi da un anello all'altro.
	float frastaglio = 1.0
			+ 0.13 * sin(2.0 * giro + 1.3 + 2.1 * raggio)
			+ 0.11 * sin(3.0 * giro + 4.1 - 3.3 * raggio)
			+ 0.07 * sin(7.0 * giro + 2.0 + 5.7 * raggio)
			+ 0.05 * sin(13.0 * giro + 0.4 - 9.1 * raggio)
			+ 0.03 * sin(29.0 * giro + 5.2 + 17.0 * raggio);
	float r = raggio * frastaglio;
	float fronte = presenza * (1.0 + fronte_largo);
	// L'ULTIMO FATTORE È IL BORDO DELLA MESH, e c'è perché i lobi rientranti portano
	// il raggio deformato sotto uno anche dove la mesh è finita: senza, un lobo
	// sarebbe tagliato netto da un arco di cerchio.
	float c = (1.0 - smoothstep(fronte - fronte_largo, fronte, r))
			* (1.0 - smoothstep(sfuma_da, 1.0, r))
			* (1.0 - smoothstep(0.8, 1.0, raggio));
	if (c <= soglia(FRAGCOORD.xy)) {
		discard;
	}
	ALBEDO = texture(colore, UV).rgb * mix(0.2, 1.0, 1.0 - smoothstep(0.2, 0.85, r));
	NORMAL_MAP = texture(normale, UV).rgb;
	NORMAL_MAP_DEPTH = rilievo;
	ROUGHNESS = texture(ruvidita, UV).r;
}
