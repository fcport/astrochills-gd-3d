// L'INCHIOSTRO nel cielo: una macchia nera che prima tiene la forma, poi si sfalda in
// una nube che si allarga e cancella le costellazioni.
//
// LE DUE FORME SONO QUELLE DI UN CEFALOPODE VERO (Derby, «Cephalopod ink: production,
// chemistry, functions and applications», Mar. Drugs 2014). Un polpo l'inchiostro lo
// butta in due modi: una NUBE diffusa, che fa da cortina, e uno PSEUDOMORFO — un
// grumo tenuto insieme dal muco, grande più o meno quanto l'animale, che per qualche
// secondo resta compatto e fa da esca. Qui arrivano in quell'ordine: esce lo
// pseudomorfo, allungato nel verso del getto, sta fermo come una sagoma; poi il muco
// cede e diventa nube, che si allarga come si allarga un fumo, sempre più larga e
// sempre più rada.
//
// È MELANINA, e il colore è quello: nero con un fondo bruno. Contro il cielo di notte il
// bruno non si vede quasi — si vede che le stelle non ci sono più — ma dove il cielo
// è chiaro di Luna la macchia ha un tono caldo, non grigio.
//
// SI MOLTIPLICA SUL CIELO come le nubi (vedi `orrore_nubi.gdshader`), per la stessa
// ragione.
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

#include "res://world/shaders/orrore_rumore.gdshaderinc"

// Dove sta il centro della macchia, e verso dove è stata spinta.
uniform vec3 centro = vec3(0.0, 0.7, 0.7);
uniform vec3 getto = vec3(1.0, 0.0, 0.0);
// Il raggio, in radianti di cielo.
uniform float raggio = 0.1;
// 1 = pseudomorfo compatto, 0 = nube sfatta.
uniform float coesione = 1.0;
// Quanto è fitta, e quanto è accesa in tutto.
uniform float densita = 1.0;
uniform float forza = 1.0;
uniform float tempo = 0.0;

varying vec3 dir;

void vertex() {
	dir = VERTEX;
}

void fragment() {
	vec3 d = normalize(dir);
	vec3 c = normalize(centro);
	vec3 t1 = normalize(getto - c * dot(getto, c));
	vec3 t2 = cross(c, t1);
	float z = dot(d, c);
	float scuro = 0.0;
	if (z > 0.0) {
		// le coordinate attorno al centro, in radianti
		float ax = atan(dot(d, t1), z);
		float ay = atan(dot(d, t2), z);
		// LO PSEUDOMORFO È ALLUNGATO nel verso del getto; la nube si arrotonda
		float allungo = mix(1.0, 1.7, coesione);
		float e = sqrt((ax / allungo) * (ax / allungo) + ay * ay);
		// IL BORDO: netto e appena mosso finché il muco tiene, sfilacciato quando cede
		float sfilaccia = (orrore_ottave(d * mix(9.0, 4.0, coesione) + vec3(tempo * 0.015)) - 0.5);
		float bordo = e + sfilaccia * raggio * mix(1.1, 0.18, coesione);
		float corpo = 1.0 - smoothstep(raggio * mix(0.55, 0.85, coesione), raggio, bordo);
		// dentro, la nube ha i suoi riccioli; lo pseudomorfo è pieno
		float riccioli = mix(smoothstep(0.2, 0.8, orrore_ottave(d * 7.0 - vec3(tempo * 0.02))), 1.0, coesione);
		scuro = clamp(corpo * mix(0.7, 1.15, riccioli) * densita, 0.0, 1.0) * forza;
	}
	vec3 melanina = vec3(0.055, 0.040, 0.030);
	ALBEDO = mix(vec3(1.0), melanina, scuro);
}
