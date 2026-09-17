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
// E LA PELLE NON SI RIPETE. Una piastrella di foto ripetuta su un chilometro di pelle si
// conta: da sotto erano file di squame tutte uguali, «i pattern sono un po' troppo uguali
// tutti». Si campiona a PIASTRELLE ESAGONALI (Mikkelsen, «Practical Real-Time Hex-Tiling»,
// JCGT 2022, `esagoni.gdshaderinc`): ogni esagono prende un pezzo della foto spostato e girato a caso, e fra un
// esagono e l'altro si passa per la trama più chiara, così la cucitura non si vede. Sopra,
// una variazione larga di chiaro e scuro, perché una pelle vera non è uguale dappertutto.
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

// Quanto gira a caso ogni esagono (1 = qualunque angolo), e quanto conta la variazione larga.
uniform float giro_esagoni = 1.0;
uniform float variazione = 0.35;

varying float raggio;
varying vec2 piano;

float soglia(vec2 f) {
	int x = int(mod(f.x, 4.0));
	int y = int(mod(f.y, 4.0));
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[y * 4 + x]) + 0.5) / 16.0;
}

#include "res://world/shaders/esagoni.gdshaderinc"

float rumore_largo(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	float a = esagono_caso(i).x;
	float b = esagono_caso(i + vec2(1.0, 0.0)).x;
	float c = esagono_caso(i + vec2(0.0, 1.0)).x;
	float d = esagono_caso(i + vec2(1.0, 1.0)).x;
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
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
	vec3 w;
	vec2 v1;
	vec2 v2;
	vec2 v3;
	esagoni(UV, w, v1, v2, v3);
	vec2 dx = dFdx(UV);
	vec2 dy = dFdy(UV);
	vec2 u1 = esagono_uv(UV, v1, giro_esagoni);
	vec2 u2 = esagono_uv(UV, v2, giro_esagoni);
	vec2 u3 = esagono_uv(UV, v3, giro_esagoni);
	float a1 = esagono_angolo(v1, giro_esagoni);
	float a2 = esagono_angolo(v2, giro_esagoni);
	float a3 = esagono_angolo(v3, giro_esagoni);
	vec3 c1 = textureGrad(colore, u1, gira(dx, a1), gira(dy, a1)).rgb;
	vec3 c2 = textureGrad(colore, u2, gira(dx, a2), gira(dy, a2)).rgb;
	vec3 c3 = textureGrad(colore, u3, gira(dx, a3), gira(dy, a3)).rgb;
	// si passa per la trama più chiara
	vec3 pesi = esagoni_pesi(w, c1, c2, c3);
	vec3 pelle = pesi.x * c1 + pesi.y * c2 + pesi.z * c3;
	// la normale gira con il suo esagono
	vec3 n1 = textureGrad(normale, u1, gira(dx, a1), gira(dy, a1)).rgb * 2.0 - 1.0;
	vec3 n2 = textureGrad(normale, u2, gira(dx, a2), gira(dy, a2)).rgb * 2.0 - 1.0;
	vec3 n3 = textureGrad(normale, u3, gira(dx, a3), gira(dy, a3)).rgb * 2.0 - 1.0;
	n1.xy = gira(n1.xy, -a1);
	n2.xy = gira(n2.xy, -a2);
	n3.xy = gira(n3.xy, -a3);
	vec3 n = normalize(pesi.x * n1 + pesi.y * n2 + pesi.z * n3);
	float ruvida = pesi.x * textureGrad(ruvidita, u1, dx, dy).r + pesi.y * textureGrad(ruvidita, u2, dx, dy).r
			+ pesi.z * textureGrad(ruvidita, u3, dx, dy).r;
	// la variazione larga: chiazze di qualche piastrella, più chiare e più scure
	float chiazza = rumore_largo(UV * 0.31) * 0.65 + rumore_largo(UV * 0.83 + vec2(7.0, 2.0)) * 0.35;
	pelle *= mix(1.0 - variazione, 1.0 + variazione * 0.6, chiazza);

	ALBEDO = pelle * mix(0.2, 1.0, 1.0 - smoothstep(0.2, 0.85, r));
	NORMAL_MAP = n * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = rilievo;
	ROUGHNESS = ruvida;
}
