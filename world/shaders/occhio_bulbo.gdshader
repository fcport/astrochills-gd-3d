// IL BULBO dell'occhio nel cielo: l'iride, la pupilla, e la Luna che ci si specchia.
//
// La geometria è una sfera di raggio uno, girata da `world/occhio.gd` verso quello che
// guarda: la pupilla sta sempre sul suo -Z. Tutto quello che ha una forma qui dentro -
// la pupilla, il suo bordo, l'ombra delle palpebre - si calcola dalla posizione sulla
// sfera, perché sono cose che CAMBIANO: la pupilla si allarga e si stringe, le
// palpebre si aprono. Una texture le congelerebbe.
//
// LA PUPILLA È UNA BARRA ORIZZONTALE, e resta orizzontale. È quella di un polpo:
// una fessura in piena luce, un rettangolo arrotondato al buio. Il file dell'occhio
// tiene il bulbo senza rollio anche quando la testa è inclinata, che è quello che fa
// un polpo vero con le statocisti; qui basta disegnarla lungo l'asse X del bulbo.
//
// IL RIFLESSO DELLA LUNA non è un effetto: una superficie bagnata e liscia specchia
// la sorgente più forte del cielo, e di notte è quella. È anche la cosa che fa
// leggere una sfera scura come un occhio invece che come una palla. Sta in
// EMISSION perché la luce della Luna in scena ha lo speculare quasi spento (lo
// vuole il pavimento, non l'occhio), e con quello il bulbo resterebbe opaco.
shader_type spatial;
render_mode cull_back;

uniform sampler2D iride : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;

// Quante piastrelle dell'iride ci stanno da un bordo all'altro del bulbo. Nella foto
// la parte scoperta dell'iride è larga una trentina di cellule, e una piastrella ne ha
// una quindicina: la parte scoperta è un raggio e sei decimi, quindi tre.
uniform float piastrelle = 3.0;

// La pupilla, in raggi del bulbo: mezza larghezza e mezza altezza. Le muove lo
// script, da buio a luce.
uniform float pupilla_largo = 0.55;
uniform float pupilla_alto = 0.40;
// L'esponente della superellisse: due è un'ellisse, alto è un rettangolo. Tre è la
// barra con i capi tondi.
uniform float pupilla_forma = 3.0;

// Il filo dorato lungo il bordo della pupilla: nella foto c'è, sotto la fessura.
uniform vec3 bordo_colore : source_color = vec3(0.60, 0.50, 0.26);
uniform float bordo_spessore = 0.022;

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

	vec3 colore = texture(iride, p.xy * piastrelle * 0.5 + 0.5).rgb;

	// la pupilla, solo sulla faccia davanti
	float n = pupilla_forma;
	float s = pow(pow(abs(p.x) / pupilla_largo, n) + pow(abs(p.y) / pupilla_alto, n), 1.0 / n);
	float aa = max(fwidth(s), 1e-4);
	float davanti = step(p.z, 0.0);
	float dentro = (1.0 - smoothstep(1.0 - aa, 1.0 + aa, s)) * davanti;
	float fuori_di = (s - 1.0) * min(pupilla_largo, pupilla_alto);
	float bordo = (1.0 - smoothstep(0.0, bordo_spessore, fuori_di)) * step(0.0, fuori_di) * davanti;
	colore = mix(colore, bordo_colore, bordo * 0.85);
	colore = mix(colore, vec3(0.004, 0.004, 0.006), dentro);

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
