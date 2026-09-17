// LA SCIA DEL METEORITE: la striscia di fumo che la pietra lascia scendendo, fino al prato.
//
// Un nastro lungo tutta la strada, dal punto in cielo da cui parte fino alla buca, sempre
// girato verso chi guarda. `UV.x` è la distanza dalla buca lungo la strada, in metri;
// `UV.y` il lato del nastro, -1 o +1. Si vede solo DIETRO la pietra: `testa` è quanto le
// manca ad arrivare, e quello che sta più vicino alla buca non è ancora stato attraversato.
//
// OGNI PEZZO DI SCIA HA UN'ETÀ: da quanti secondi la pietra ci è passata. Appena passata è
// incandescente — aria e metallo fusi — e dopo mezzo secondo è fumo, che si allarga, si
// spegne e si sfilaccia nel giro di mezzo minuto. È la «traccia persistente» dei bolidi
// fotografati, ed è quello che dice a chi guarda da dove è arrivata la cosa che adesso sta
// fumando nel prato.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

#include "res://world/shaders/orrore_rumore.gdshaderinc"

uniform vec3 direzione = vec3(0.0, 1.0, 0.0);
// Quanti metri mancano alla pietra per arrivare; zero, è arrivata.
uniform float testa = 1e9;
// Da quanti secondi è arrivata (zero finché vola), e la velocità, per l'età di ogni pezzo.
uniform float dopo = 0.0;
uniform float velocita_arrivo = 250.0;
uniform float velocita_partenza = 1200.0;
uniform float lunghezza = 5000.0;
// Il fumo: largo all'inizio e dopo trenta secondi, quanto vive, e il suo colore alla Luna.
uniform float largo = 2.0;
uniform float allarga = 1.2;
uniform float vive = 30.0;
uniform vec3 fumo : source_color = vec3(0.36, 0.38, 0.44);
uniform float luna = 1.0;
uniform float spegni = 1.0;

varying float eta;
varying float lato;
varying float metri;

// Il tempo che la pietra ci ha messo ad andare da `s` metri dalla buca fino a `t`: la velocità
// scende piano da quella di partenza a quella d'arrivo, lungo la strada.
float velocita(float s) {
	return mix(velocita_arrivo, velocita_partenza, clamp(s / lunghezza, 0.0, 1.0));
}

void vertex() {
	metri = UV.x;
	lato = UV.y;
	// l'età: il tratto fra il pezzo e la testa, alla velocità media fra i due, più il dopo
	float tratto = max(metri - testa, 0.0);
	float v = 0.5 * (velocita(metri) + velocita(testa));
	eta = tratto / max(v, 1.0) + dopo;
	float w = largo + allarga * sqrt(max(eta, 0.0)) * 2.0;
	vec3 centro = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 guardo = normalize(centro - CAMERA_POSITION_WORLD);
	vec3 fianco = normalize(cross(direzione, guardo));
	// il fumo sale e deriva piano, a sbuffi
	vec3 deriva = vec3(0.0, 1.0, 0.0) * eta * 0.35
			+ vec3(1.0, 0.0, 0.3) * (orrore_rumore(vec3(metri * 0.004, eta * 0.05, 1.0)) - 0.5) * eta * 1.2;
	vec3 mondo = centro + fianco * lato * w + deriva;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(mondo, 1.0);
}

void fragment() {
	if (metri < testa) {
		discard;
	}
	// il bordo del nastro sfuma, e il fumo si sfilaccia col rumore
	float bordo = 1.0 - smoothstep(0.35, 1.0, abs(lato));
	float fili = orrore_ottave(vec3(metri * 0.02, lato * 1.5, eta * 0.08));
	float denso = bordo * smoothstep(0.25, 0.7, fili + 0.25 - eta / vive * 0.5);
	float vivo = 1.0 - smoothstep(vive * 0.3, vive, eta);
	// incandescente appena passata, fumo dopo mezzo secondo
	float caldo = exp(-eta / 0.18);
	vec3 fuoco = mix(vec3(1.0, 0.45, 0.12), vec3(1.0, 0.95, 0.75), exp(-eta / 0.05));
	ALBEDO = mix(fumo * luna, fuoco * 6.0, caldo);
	// VICINO A TERRA IL FUMO NON È UN NASTRO: gli ultimi metri sono polverone e fumo della
	// buca, che fanno le particelle; un nastro largo quindici metri a mezz'aria era un lenzuolo
	float quota = mix(smoothstep(25.0, 110.0, metri), 1.0, caldo);
	ALPHA = clamp(denso * vivo * mix(0.4, 1.0, caldo) * spegni * quota, 0.0, 1.0);
	// vicino alla testa il nastro si stringe a punta, non finisce di taglio
	ALPHA *= smoothstep(0.0, 6.0, metri - testa);
}
