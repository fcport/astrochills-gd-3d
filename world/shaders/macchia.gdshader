// Una pozza di caffè (D-251): un rettangolo appoggiato, e la forma la disegna questo shader.
//
// IL BORDO È MOSSO, E NON È UN CERCHIO. Un liquido su un pavimento si allarga finché trova una
// fuga o un dislivello, e si ferma a lobi. Il raggio cambia con l'angolo seguendo un rumore letto
// SU UN CERCHIO — la direzione, non l'angolo — così il giro si chiude senza una cucitura.
//
// IL BORDO È PIÙ SCURO DEL CENTRO, ed è fisica, non gusto: è l'«anello del caffè» (Deegan e
// altri, Nature 1997). Una pozza evapora prima sul bordo, il liquido dal centro corre a
// rimpiazzarlo e si porta dietro la polvere di caffè, che resta lì.
//
// PULENDO NON SBIADISCE TUTTA INSIEME: il mocio porta via prima le parti sottili, a chiazze.
// `sporco` è una soglia su un rumore, più un'opacità che cala.

shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform float seme = 0.0;
uniform float sporco : hint_range(0.0, 1.0) = 1.0;
// Quanto il rettangolo è più largo del raggio: vedi `Macchia.ALONE`.
uniform float alone = 1.9;
uniform float schizzi : hint_range(0.0, 1.0) = 0.0;
uniform vec3 colore : source_color = vec3(0.24, 0.13, 0.065);
uniform vec3 colore_bordo : source_color = vec3(0.07, 0.035, 0.015);
uniform float opacita : hint_range(0.0, 1.0) = 0.9;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float rumore(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float frattale(vec2 p) {
	float somma = 0.0;
	float peso = 0.5;
	for (int k = 0; k < 4; k++) {
		somma += rumore(p) * peso;
		p = p * 2.03 + vec2(17.0, 9.0);
		peso *= 0.5;
	}
	return somma / 0.9375;
}

void fragment() {
	// In raggi: il bordo medio sta a 1.
	vec2 p = (UV - 0.5) * 2.0 * alone;
	float r = length(p);
	vec2 verso = r > 0.0001 ? p / r : vec2(1.0, 0.0);
	vec2 s = vec2(seme, seme * 0.618);

	// Il bordo, fra 0,75 e 1,25 raggi a seconda della direzione, più un tremito fine. SCHIZZATA
	// È PIÙ STRAPPATA: il caffè arriva con la velocità del lancio e fa lingue, non un cerchio — i
	// lobi sono il doppio e fitti il doppio. Lo scatto della prima stesura la mostrava tonda
	// quanto quella versata, solo più grande.
	float lobi = mix(0.5, 1.0, schizzi);
	float fitti = mix(1.6, 3.2, schizzi);
	float bordo = 1.0 - 0.5 * lobi + lobi * frattale(verso * fitti + s)
		+ 0.06 * (rumore(p * 7.0 + s) - 0.5);
	float dentro = bordo - r;
	float pozza = smoothstep(0.0, 0.03, dentro);

	// Le gocce dello schizzo: fuori dal bordo, e sempre più rade allontanandosi.
	float vicino = 1.0 - smoothstep(bordo + 0.05, bordo + 0.8, r);
	float gocce = smoothstep(0.72, 0.76, rumore(p * 7.0 + s * 1.7)) * vicino * schizzi;
	float forma = max(pozza, gocce);

	// L'anello: gli ultimi venti centesimi di raggio sono più scuri, e il centro è un velo più
	// chiaro. Le gocce sono tutte bordo.
	float anello = 1.0 - smoothstep(0.0, 0.20, dentro);
	vec3 tinta = mix(colore, colore_bordo, anello * 0.85);

	// Pulendo se ne vanno prima le chiazze dove il rumore è alto.
	float chiazze = rumore(p * 3.0 + s * 2.3) * 0.85;
	float resta = 1.0 - smoothstep(sporco - 0.12, sporco + 0.02, chiazze);

	ALBEDO = tinta;
	// Bagnata luccica: è la cosa che la fa leggere come liquido e non come una macchia di vernice.
	ROUGHNESS = 0.3;
	SPECULAR = 0.4;
	ALPHA = forma * resta * opacita * mix(0.45, 1.0, sporco);
}
