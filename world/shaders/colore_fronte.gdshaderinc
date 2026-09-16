// IL COLORE VENUTO DALLO SPAZIO nel prato: fin dove è arrivato, e di che colore è.
//
// Lo usa `erba.gdshader`, e `world/orrori/colore.gd` ne tiene una copia in GDScript per
// disegnare la cenere per terra con lo stesso bordo dell'erba grigia. Per questo il caso
// viene da un hash SENZA SENO (Dave Hoskins, «Hash without Sine»): un seno di numeri grandi
// in virgola mobile a 32 bit non dà lo stesso risultato sulla scheda video e nel processore,
// e i due bordi non combacerebbero.

float colore_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float colore_rumore(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(colore_hash(i), colore_hash(i + vec2(1.0, 0.0)), f.x),
		mix(colore_hash(i + vec2(0.0, 1.0)), colore_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// DOVE ARRIVA: 1 dentro, 0 fuori. NON UN CERCHIO: si allarga a macchie e a dita, come
// una muffa, più in là da una parte e meno dall'altra. Il cerchio pieno della prima stesura
// era un faretto puntato sull'erba.
float colore_fronte(vec2 q, vec2 dove, float raggio) {
	if (raggio <= 0.0) {
		return 0.0;
	}
	float n = colore_rumore(q * 0.45) * 0.65 + colore_rumore(q * 1.3 + vec2(17.0, 5.0)) * 0.35;
	float r = raggio * (0.45 + 0.85 * n);
	return 1.0 - smoothstep(r - 0.9, r, distance(q, dove));
}

// IL COLORE. Il racconto dice che era un colore solo per analogia: non ce n'è uno nello
// spettro. Ce n'è uno che l'occhio vede e che nello spettro non sta — il MAGENTA, che
// nessuna lunghezza d'onda da sola produce: è il cervello che lo inventa quando arrivano
// rosso e blu senza verde. Qui è quello, e non sta fermo: scivola verso il viola e verso il
// rosa a chiazze che si muovono, così l'occhio non lo fissa.
vec3 colore_tinta(vec2 q, float t) {
	float a = colore_rumore(q * 2.5 + vec2(t * 0.35, -t * 0.27));
	float b = colore_rumore(q * 5.0 - vec2(t * 0.6, t * 0.45) + vec2(3.0, 11.0));
	vec3 c = mix(vec3(0.92, 0.26, 0.88), vec3(0.52, 0.30, 1.00), smoothstep(0.35, 0.85, a));
	return mix(c, vec3(1.00, 0.36, 0.62), smoothstep(0.55, 0.95, b) * 0.6);
}
