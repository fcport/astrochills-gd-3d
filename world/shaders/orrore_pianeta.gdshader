// UN PIANETA CHE NON È NOSTRO, visto da vicino — la visione di `Ctrl+F9`.
//
// Non è un pianeta fotografato, ed è voluto: una mappa vera è la mappa di un pianeta che
// esiste, e questo non deve esistere. Quello che si copia non è un posto, è COME SI VEDE
// UN MONDO CON L'ATMOSFERA quando ci si sta accanto, che è la cosa che fa capire in mezzo
// secondo che non si sta guardando dentro un telescopio.
//
//   * LE NUVOLE STANNO IN FASCE parallele all'equatore, e le fasce scorrono in versi
//     alternati. Sono le correnti zonali dei pianeti giganti: getti paralleli che vanno uno
//     verso est e il successivo verso ovest, ed è il motivo per cui su Giove le bande si
//     sfilacciano sui bordi invece che dentro. Qui il verso cambia a ogni fascia e il
//     disegno di una fascia scorre in longitudine: due fasce vicine si spostano in versi
//     opposti, e si vede.
//   * LE NUVOLE SONO STIRATE IN LONGITUDINE, non a chiazze tonde: dentro un getto una
//     macchia viene tirata lungo il parallelo. Il rumore si campiona su una direzione
//     schiacciata ai poli, e questo è tutto lo stiramento.
//   * IL TERMINATORE È SFUMATO. Su un sasso senza aria la linea fra il giorno e la notte è
//     netta; con l'atmosfera c'è l'arco del crepuscolo, largo qualche grado, ed è la
//     differenza fra una palla illuminata e un mondo.
//   * IL BORDO È PIÙ CHIARO dalla parte del giorno: la luce che attraversa l'atmosfera di
//     taglio ne attraversa molta di più, e il bordo di un pianeta nuvoloso si accende in un
//     filo sottile. È l'anello che si vede in ogni foto di Venere e di Titano.
//   * LA NOTTE NON È NERA DEL TUTTO. Un nero pieno, contro il cielo dell'oculare,
//     sarebbe un buco che mangia le stelle: resta un fondo appena acceso, così il disco si
//     legge come una cosa tonda e non come un ritaglio.
//
// NON È ILLUMINATO DALLA SCENA. La sua luce è `sole`, una direzione ferma rispetto a chi
// guarda, e la stessa che illumina le braccia (`orrore_braccio_polpo.gdshader`): la Luna di
// stanotte illumina l'osservatorio, non un pianeta che sta da un'altra parte. Ferma
// rispetto alla camera vuol dire che il pianeta può girare quanto vuole e il terminatore
// resta dov'è, con le nuvole che ci passano dentro — che è come si vede davvero.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque, depth_prepass_alpha, cull_back, fog_disabled, shadows_disabled;

#include "res://world/shaders/orrore_rumore.gdshaderinc"

// Dove sta il sole di quel posto, nel mondo. La scrive `world/orrori/pianeta.gd`.
uniform vec3 sole = vec3(-0.72, 0.42, -0.10);
uniform vec3 chiaro : source_color = vec3(0.86, 0.82, 0.72);
uniform vec3 scuro : source_color = vec3(0.22, 0.18, 0.17);
// Il filo di atmosfera sul bordo.
uniform vec3 alone : source_color = vec3(0.58, 0.66, 0.78);
uniform float energia = 1.0;
uniform float presenza = 1.0;
uniform float tempo = 0.0;
// Quante fasce: il numero di mezzi periodi che ci stanno da un polo all'altro.
uniform float fasce = 7.0;
// Quanto scorre una fascia, in radianti al secondo.
uniform float deriva = 0.013;
// Quanto è acceso il lato in ombra.
uniform float notte = 0.03;
// SEPOLTO: fin dove l'hanno coperto i tentacoli, in radianti dal polo di dietro, e quanto si
// spegne là sotto. Fra un tentacolo e l'altro non si devono vedere le nuvole accese, ma il
// buio che c'è sotto un mucchio.
uniform float copre = 0.0;
uniform float sfuma = 0.6;
uniform float sepolto = 0.0;

varying vec3 n_mondo;
varying vec3 n_modello;
varying vec3 p_mondo;

void vertex() {
	n_modello = NORMAL;
	n_mondo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	p_mondo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n = normalize(n_mondo);
	vec3 nm = normalize(n_modello);
	vec3 s = normalize(sole);
	vec3 vista = normalize(CAMERA_POSITION_WORLD - p_mondo);

	// LE FASCE si contano sulla latitudine del pianeta, non su quella di chi guarda:
	// `n_modello` gira col globo, quindi il disegno resta attaccato al pianeta mentre le
	// braccia lo voltano.
	float lat = asin(clamp(nm.y, -1.0, 1.0));
	float lon = atan(nm.x, nm.z);
	float fascia = lat * fasce;
	float verso = mod(floor(fascia / 3.14159265), 2.0) * 2.0 - 1.0;
	float lon_scorsa = lon + verso * deriva * tempo;

	vec3 q = vec3(cos(lat) * sin(lon_scorsa), sin(lat) * 3.4, cos(lat) * cos(lon_scorsa));
	// tre scale: le macchie grosse dentro un getto, la grana che le sfilaccia e il pulviscolo
	// che si vede solo da vicino. Con due sole, il globo da tre raggi era una palla sfumata
	float t = orrore_ottave(q * 3.2) + 0.30 * orrore_ottave(q * 9.0)
			+ 0.16 * orrore_ottave(q * 26.0);
	t = clamp((t - 0.70) * 2.0 + 0.5, 0.0, 1.0);
	// la fascia decide il fondo, il rumore lo sporca e ne sfilaccia il bordo — il bordo di
	// una banda non è mai una riga dritta
	float banda = smoothstep(-0.30, 0.30, sin(fascia + 1.3 * (t - 0.5)));
	vec3 colore = mix(scuro, chiaro, clamp(0.62 * banda + 0.52 * t, 0.0, 1.0));

	// IL GIORNO E LA NOTTE, con l'arco del crepuscolo al posto di una linea netta.
	float lam = dot(n, s);
	float giorno = smoothstep(-0.13, 0.11, lam);
	// l'esponente sotto l'unità tiene il bordo del giorno meno buio di un lambertiano
	// puro: un'atmosfera diffonde anche di taglio
	float diffusa = pow(clamp(lam, 0.0, 1.0), 0.7);
	float bordo = 1.0 - clamp(dot(n, vista), 0.0, 1.0);

	vec3 luce = colore * (notte + giorno * (0.14 + 0.86 * diffusa));
	luce += alone * pow(bordo, 7.0) * giorno * 0.30;
	float sotto = 1.0 - smoothstep(copre - sfuma, copre, acos(clamp(-nm.z, -1.0, 1.0)));
	luce *= 1.0 - sepolto * sotto;

	ALBEDO = luce * energia;
	ALPHA = presenza;
}
