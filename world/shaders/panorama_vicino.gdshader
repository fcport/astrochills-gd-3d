// Il panorama vicino: la griglia di `world/panorama.gd`.
//
// DA VICINO IL SATELLITE NON BASTA. Dieci metri a pixel sono un campo intero: a venti metri
// dal prato il terreno era una macchia olivastra liscia. Allora il satellite dice DOVE (il
// colore di quel campo, più chiaro o più scuro dei vicini) e quattro texture dicono DI COSA:
// l'erba del prato, la ghiaia della strada bianca, l'asfalto, le foglie secche del bosco.
// Dove sta ognuna lo dicono le maschere di `tools/prendi_panorama.py`: le strade di
// OpenStreetMap e il bosco di WorldCover.
//
// DA LONTANO TORNA IL SATELLITE: fra `vicino_da` e `vicino_a` metri dalla camera la trama
// sparisce, perché da lì un sasso della ghiaia è più piccolo di un pixel e il campo intero
// è quello che si vede.
//
// L'ERBA HA LA FASE DEL PRATO: le coordinate partono dallo spigolo del prato
// (`origine_prato`) e si ripetono ogni `righello_prato`, gli stessi due numeri del materiale
// del prato. Sul bordo le due trame combaciano.

shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

// Il satellite, in assi di gioco: la riga zero è il bordo sud.
uniform sampler2D colore : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
// Rosso: sterrate. Verde: bosco. Blu: asfalto.
uniform sampler2D maschere : filter_linear_mipmap, repeat_disable;
// L'osservatorio (x, z) e quanti metri coprono le mappe attorno.
uniform vec2 centro = vec2(0.0);
uniform float mezzo = 800.0;
// Il colore medio del satellite: la trama si scurisce e schiarisce di quanto il campo si
// scosta da lui.
uniform vec3 medio : source_color = vec3(0.2);

uniform sampler2D prato : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sterrata : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sottobosco : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D asfalto : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 origine_prato = vec2(0.0);
uniform float righello_prato = 2.0;
uniform float righello_sterrata = 2.0;
uniform float righello_sottobosco = 1.7;
uniform float righello_asfalto = 2.0;
uniform float vicino_da = 60.0;
uniform float vicino_a = 260.0;

varying vec3 mondo;

#include "res://world/shaders/esagoni.gdshaderinc"

// Quanto va stirata una trama sul lato corto: la sterrata è larga il doppio di quanto è
// alta, e stesa su un quadrato ogni sasso diventava una lastra lunga il doppio.
vec2 forma_di(sampler2D t) {
	vec2 lati = vec2(textureSize(t, 0));
	return vec2(1.0, lati.x / lati.y);
}

// UNA TRAMA IN METRI: il righello è quanto copre la foto sul lato largo.
vec3 trama_di(sampler2D t, vec2 p, float righello) {
	return texture(t, p / righello * forma_di(t)).rgb;
}

void vertex() {
	mondo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = (mondo.xz - centro + vec2(mezzo)) / (2.0 * mezzo);
	vec3 satellite = texture(colore, uv).rgb;
	vec3 m = texture(maschere, uv).rgb;
	vec2 p = mondo.xz - origine_prato;
	vec3 trama = trama_di(prato, p, righello_prato);
	trama = mix(trama, trama_di(sottobosco, p, righello_sottobosco), smoothstep(0.2, 0.8, m.g));
	// quanto questo campo è più chiaro o più scuro della media, sulla luminanza
	float campo = dot(satellite, vec3(0.3, 0.59, 0.11)) / max(dot(medio, vec3(0.3, 0.59, 0.11)), 0.001);
	trama *= clamp(campo, 0.6, 1.5);
	// LE STRADE NO: la loro tinta è già quella misurata sulle foto, più chiara del prato di
	// quanto il calcare lo è davvero. Col satellite sopra la ghiaia contava due volte, sempre
	// al tetto di una volta e mezza, e sul piazzale di notte era un lenzuolo.
	vec3 strada = trama_di(asfalto, p, righello_asfalto);
	if (m.r > 0.25) {
		// LA GHIAIA A ESAGONI: col righello vero, un metro e trenta, la foto ripetuta
		// disegnava righe sul piazzale
		strada = mix(strada, esagoni_colore(sterrata, p / righello_sterrata, forma_di(sterrata), 1.0),
			smoothstep(0.25, 0.6, m.r));
	}
	trama = mix(trama, strada, smoothstep(0.25, 0.6, max(m.r, m.b)));
	float lontano = smoothstep(vicino_da, vicino_a, length(mondo - CAMERA_POSITION_WORLD));
	ALBEDO = mix(trama, satellite, lontano);
	ROUGHNESS = 1.0;
}
