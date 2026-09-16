// LE VENTOSE CONTRO IL CIELO: un braccio premuto dall'altra parte, come un polpo contro
// il vetro di un acquario, che striscia da un orizzonte all'altro.
//
// Il cielo diventa un vetro, e questo shader disegna quello che si vede da dentro
// l'acquario: la faccia orale del braccio schiacciata sulla lastra.
//
// COPIATO DA UN BRACCIO VERO, lo stesso da cui è costruito il tentacolo
// (`tools/tentacolo_blender.py`):
//   * LE VENTOSE SONO SU DUE FILE ALTERNATE (biseriali, come in Octopus; quattro file
//     sarebbero un calamaro), e si fanno più piccole e più fitte verso la punta. Qui il
//     passo è proporzionale alla larghezza del braccio in quel punto, quindi la
//     distanza fra una ventosa e l'altra cresce in progressione geometrica salendo
//     verso la radice.
//   * UNA VENTOSA PREMUTA SU UN VETRO si vede come un disco chiaro — l'INFUNDIBOLO,
//     schiacciato e allargato, con i solchi radiali — attorno a un foro scuro, l'apertura
//     dell'ACETABOLO. Staccata, il disco si ritira e il foro si chiude: resta un bottone
//     scuro più piccolo.
//   * STRISCIANDO, LE VENTOSE SI ATTACCANO UNA DOPO L'ALTRA: un'onda di attacco corre
//     lungo il braccio.
//
// NON È ILLUMINATO DALLA SCENA, e porta la luce in `energia`. Un braccio grande quanto un
// terzo di cielo, schiacciato su una sfera attorno alla camera, non ha una normale
// sensata per la luce della Luna in scena: si tiene la sua luminosità legata a quella
// della notte, così non è mai più chiaro di quanto la Luna potrebbe farlo.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

#include "res://world/shaders/orrore_rumore.gdshaderinc"

uniform sampler2D pelle : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;

// Il percorso: un cerchio massimo che parte da `inizio` e gira attorno a `asse`.
uniform vec3 inizio = vec3(1.0, -0.1, 0.0);
uniform vec3 asse = vec3(0.0, 0.0, 1.0);
// Dove sta la punta, in radianti lungo il percorso.
uniform float testa = 0.0;
// Quanto è lungo il braccio e quanto è largo alla radice (mezza larghezza), in radianti.
uniform float lunghezza = 1.9;
uniform float largo = 0.14;
uniform float tempo = 0.0;
uniform float forza = 1.0;
uniform float energia = 0.2;
// Quanto è lunga una piastrella di pelle sul braccio, in radianti.
uniform float piastrella = 0.035;
// Il passo delle ventose su una fila, in larghezze del braccio.
uniform float passo_ventose = 0.85;

varying vec3 dir;

void vertex() {
	dir = VERTEX;
}

float larghezza(float u) {
	return largo * (0.05 + 0.95 * clamp(u / lunghezza, 0.0, 1.0));
}

void fragment() {
	vec3 d = normalize(dir);
	vec3 a_ = normalize(asse);
	vec3 i0 = normalize(inizio);
	float b = asin(clamp(dot(d, a_), -1.0, 1.0));
	vec3 q = normalize(d - a_ * dot(d, a_));
	float a = atan(dot(cross(i0, q), a_), dot(i0, q));
	a = mod(a + 0.6, 6.2831853) - 0.6;

	// u: quanto dietro la punta, lungo il braccio
	float u = testa - a;
	if (u < 0.0 || u > lunghezza) {
		discard;
	}
	// il braccio non è un nastro dritto: ondeggia, e la punta si torce di più
	float verso_punta = 1.0 - smoothstep(0.0, 0.35, u);
	float storto = 0.035 * sin(u * 4.0 - tempo * 0.55) * smoothstep(0.0, 0.5, u)
			+ 0.05 * verso_punta * sin(tempo * 0.45 + u * 12.0);
	float c = b - storto;
	float w = larghezza(u);
	if (abs(c) > w) {
		discard;
	}
	float bordo = 1.0 - smoothstep(w * 0.9, w, abs(c));

	vec3 colore = texture(pelle, vec2(u, c) / piastrella).rgb;
	// piatto contro il vetro, ma ai lati si stacca e va in ombra
	colore *= mix(0.5, 1.0, sqrt(max(1.0 - (c / w) * (c / w), 0.0)));

	// LE VENTOSE: l'indice lungo il braccio cresce col logaritmo, perché il passo cresce
	// con la larghezza, che cresce con u
	float s = passo_ventose * largo * 0.95 / lunghezza;
	float rho = 0.05 + 0.95 * u / lunghezza;
	float k = log(rho / 0.05) / s;
	float fondo = floor(k);
	for (int n = -1; n <= 1; n++) {
		float i = fondo + float(n);
		if (i < 0.0) {
			continue;
		}
		float uc = lunghezza / 0.95 * (0.05 * exp((i + 0.5) * s) - 0.05);
		float wc = larghezza(uc);
		float fila = mod(i, 2.0) < 0.5 ? -1.0 : 1.0;
		float cc = fila * 0.47 * wc;
		// L'ONDA DI ATTACCO corre lungo il braccio
		float attacco = smoothstep(-0.35, 0.35, sin(i * 0.7 - tempo * 1.9));
		float r = 0.40 * wc * mix(0.68, 1.12, attacco);
		vec2 dv = vec2(u - uc, c - cc);
		float dist = length(dv) / r;
		if (dist < 1.0) {
			float ang = atan(dv.y, dv.x);
			// l'infundibolo schiacciato: chiaro, con i solchi radiali
			vec3 chiaro = vec3(0.66, 0.58, 0.57) * (0.88 + 0.12 * cos(ang * 22.0));
			float disco = smoothstep(0.30, 0.40, dist) * (1.0 - smoothstep(0.88, 1.0, dist));
			colore = mix(colore, chiaro, disco * mix(0.25, 0.9, attacco));
			// il foro dell'acetabolo, che si chiude staccandosi
			float foro = 1.0 - smoothstep(0.22, 0.32, dist / mix(0.5, 1.0, attacco));
			colore *= mix(1.0, mix(0.45, 0.12, attacco), foro);
			// l'orlo, più scuro dove la pelle risale dal vetro
			colore *= mix(1.0, 0.75, smoothstep(0.86, 0.98, dist) * attacco);
		}
	}
	// la radice si perde nella distanza invece di finire tagliata
	float radice = 1.0 - smoothstep(lunghezza * 0.8, lunghezza, u);
	// UN SESTO DELL'ENERGIA, e l'hanno deciso due scatti: alla luce intera, e poi a metà,
	// il braccio era bianco contro il nero, un adesivo e non una cosa lassù. Quello che è
	// illuminato davvero divide la luce per il suo coseno e per l'esposizione della notte;
	// questo non passa dalla luce, e il fattore lo porta dove sta la pelle dell'occhio.
	ALBEDO = colore * energia * 0.16;
	ALPHA = bordo * radice * forza;
}
