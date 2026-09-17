// IL BULBO dell'occhio nel cielo: l'iride, la pupilla, e la Luna che ci si specchia.
//
// La geometria è una sfera di raggio uno, girata da `world/occhio.gd` verso quello che
// guarda: la pupilla sta sempre sul suo -Z. Quello che CAMBIA - quanto è larga la pupilla,
// l'ombra delle palpebre - si calcola qui dalla posizione sulla sfera.
//
// L'IRIDE È L'OCCHIO COSMICO, lo stesso che esce nella stampa al posto del soggetto
// (`world/orrori/occhio_nella_posa.gd`): Federico, «l'occhio che compare sarebbe bello che
// fosse quello che poi va anche nella stampa». È l'immagine che rende
// `tools/occhio_cosmico_blender.py`, proiettata sulla faccia davanti del bulbo. La prima
// stesura era l'iride di un polpo, un quadrato di foto ripetuto tre volte: da sotto era un
// anello di macchie tutte uguali.
//
// LA PUPILLA SI ALLARGA E SI STRINGE SULL'IRIDE VERA. Nell'immagine la pupilla è larga
// `iride_pupilla` del disco; quando qui è più larga o più stretta non si disegna un
// cerchio nero sopra, si STIRA l'iride lungo il raggio fra la pupilla e il bordo, che è
// quello che fa un'iride vera: i filamenti vicino alla pupilla si accorciano quando si
// allarga, e si allungano quando si stringe.
//
// IL RIFLESSO DELLA LUNA non è un effetto: una superficie bagnata e liscia specchia
// la sorgente più forte del cielo, e di notte è quella. È anche la cosa che fa
// leggere una sfera scura come un occhio invece che come una palla. Sta in
// EMISSION perché la luce della Luna in scena ha lo speculare quasi spento (lo
// vuole il pavimento, non l'occhio), e con quello il bulbo resterebbe opaco.
shader_type spatial;
render_mode cull_back;

uniform sampler2D iride : source_color, hint_default_black, filter_linear_mipmap, repeat_disable;

// Quanto è largo sul bulbo il disco dell'immagine, in raggi del bulbo; quanto è largo il
// disco nell'immagine, in frazione del lato; e quanto è larga, in frazione del disco, la
// pupilla che l'immagine ha già.
uniform float iride_raggio = 0.9;
uniform float iride_disco = 0.4902;
uniform float iride_pupilla = 0.20;

// La pupilla di adesso, in raggi del bulbo. La muove lo script, da buio a luce.
uniform float pupilla_raggio = 0.18;
uniform vec3 pupilla_colore : source_color = vec3(0.012, 0.012, 0.022);

uniform float rugosita = 0.22;

// Verso la Luna, in coordinate del mondo, e quanta ce n'è (0-1).
uniform vec3 luna_dir = vec3(0.0, 1.0, 0.0);
uniform float luna_luce = 0.0;
uniform float riflesso_stretto = 500.0;
uniform float riflesso_forza = 2.5;

// LE PALPEBRE, per l'ombra che fanno sul bulbo. Le stesse quattro grandezze con cui
// lo script costruisce i loro margini: un angolo attorno all'asse X della testa, più
// un arco che è pieno al centro e zero ai canti.
uniform mat3 testa_inversa = mat3(1.0);
uniform vec3 centro = vec3(0.0);
uniform float su_apertura = 0.5;
uniform float su_arco = 0.25;
uniform float giu_apertura = 0.4;
uniform float giu_arco = 0.15;
uniform float canto = 0.98;
uniform float arco_forma = 0.8;
uniform float ombra = 0.20;

// Da 0 a 1: la comparsa. Il bulbo sta al centro, quindi c'è appena c'è la testa.
uniform float presenza = 1.0;

varying vec3 locale;
varying vec3 mondo;

// Il retinato di Bayer: la stessa soglia per pixel della pelle, perché bulbo e pelle
// compaiono insieme.
float soglia(vec2 f) {
	int x = int(mod(f.x, 4.0));
	int y = int(mod(f.y, 4.0));
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[y * 4 + x]) + 0.5) / 16.0;
}

// L'arco del margine: pieno al centro, zero ai canti.
float arco(float beta) {
	float c = cos(clamp(beta / canto, -1.0, 1.0) * 1.5707963);
	return pow(max(c, 0.0), arco_forma);
}

void vertex() {
	locale = VERTEX;
	mondo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (presenza <= soglia(FRAGCOORD.xy)) {
		discard;
	}
	vec3 p = normalize(locale);

	// l'iride, solo sulla faccia davanti; dietro non la vede nessuno
	vec2 q = p.xy / iride_raggio;
	float rr = length(q);
	float pr = clamp(pupilla_raggio / iride_raggio, 0.02, 0.9);
	float aa = max(fwidth(rr), 1e-4);
	// il raggio nell'immagine: fra pupilla e bordo si stira, fuori dal disco resta il bordo
	float nel_disco = mix(iride_pupilla, 1.0, clamp((rr - pr) / (1.0 - pr), 0.0, 1.0));
	vec2 verso = rr > 1e-5 ? q / rr : vec2(1.0, 0.0);
	vec2 uv = vec2(0.5) + verso * vec2(1.0, -1.0) * min(nel_disco, 0.985) * iride_disco;
	vec3 colore = texture(iride, uv).rgb;
	// oltre il disco il bulbo è il bordo scuro dell'iride, che sfuma nel buio
	colore *= 1.0 - 0.75 * smoothstep(1.0, 1.25, rr);
	float davanti = step(p.z, 0.0);
	float dentro = (1.0 - smoothstep(pr - aa, pr + aa, rr)) * davanti;
	colore = mix(colore, pupilla_colore, dentro);
	colore *= davanti;

	// l'ombra delle palpebre, vicino ai margini
	vec3 d = normalize(testa_inversa * (mondo - centro));
	float beta = asin(clamp(d.x, -1.0, 1.0));
	float alfa = atan(d.y, -d.z);
	float w = arco(beta);
	float sotto_su = (su_apertura + su_arco * w) - alfa;
	float sopra_giu = alfa + (giu_apertura + giu_arco * w);
	float ombreggia = mix(0.30, 1.0, smoothstep(0.0, ombra, sotto_su))
			* mix(0.55, 1.0, smoothstep(0.0, ombra * 0.6, sopra_giu));
	ALBEDO = colore * ombreggia;
	ROUGHNESS = rugosita;
	SPECULAR = 0.5;

	vec3 verso_luna = normalize((VIEW_MATRIX * vec4(luna_dir, 0.0)).xyz);
	vec3 riflesso = reflect(-VIEW, NORMAL);
	float lampo = pow(max(dot(riflesso, verso_luna), 0.0), riflesso_stretto);
	EMISSION = vec3(0.80, 0.86, 1.0) * lampo * luna_luce * riflesso_forza * ombreggia;
}
