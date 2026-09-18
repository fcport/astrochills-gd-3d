// UN BRACCIO AVVOLTO ATTORNO AL PIANETA: la pelle delle braccia della visione di `Ctrl+F9`.
// La forma la costruisce `world/orrori/pianeta.gd`; qui c'è solo come si vede.
//
// LA PELLE È QUELLA DEL POLPO che tiene insieme tutti gli orrori — il tentacolo, l'occhio, le
// ventose — e si campiona a piastrelle esagonali col suo rilievo e la sua ruvidità
// (`pelle_polpo.gdshaderinc`). La prima stesura ripeteva la foto sugli UV e basta, senza
// rilievo: da vicino era una salsiccia di gomma a macchie, ed è la cosa che Federico ha
// bocciato per prima («migliora molto le texture perché fanno totalmente cagare»).
//
// QUANTE PIASTRELLE CI STANNO lo decide la CPU, braccio per braccio: la pelle si misura in
// metri di mondo, se no un braccio lungo e uno corto avrebbero le macchie di due taglie
// diverse. Qui arriva già fatto il conto, in `piastrelle`.
//
// CRESCE. I tentacoli che se lo mangiano spuntano dalla radice e si allungano fino alla punta:
// ogni vertice porta in `CUSTOM0` il suo punto sulla linea di mezzo e quanta parte del braccio
// gli sta prima, e tutto quello che sta oltre `cresce` si schiaccia sulla linea di mezzo, cioè
// sparisce. Il bordo che avanza si stringe in un tratto corto (`FRONTE`) con un profilo tondo:
// una punta, non un tubo tagliato. Le braccia grandi valgono uno, e stanno ferme.
//
// OMBRA: chi sta sotto il mucchio è più scuro, e lo decide la CPU tentacolo per tentacolo.
//
// È ILLUMINATO DALLA SCENA, e la scena della visione è fatta di una luce sola: il sole di quel
// posto, che illumina solo il layer della visione (`world/orrori/pianeta.gd`). Prima era
// `unshaded` con un lambert scritto a mano, e una cosa senza rilievo e senza lucentezza, in
// mezzo alle stelle, sembra disegnata.
shader_type spatial;
render_mode cull_back;

#include "res://world/shaders/pelle_polpo.gdshaderinc"

uniform sampler2D colore : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D normale : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D ruvidita : hint_roughness_r, filter_linear_mipmap, repeat_enable;

// Quante piastrelle di pelle stanno per il lungo e attorno al braccio.
uniform vec2 piastrelle = vec2(26.0, 5.0);
uniform float giro_esagoni = 1.0;
// Quanto la pelle di questa cosa è più scura della foto da cui viene.
uniform float tono = 0.50;
// Quanto è bagnata: una pelle di polpo è lucida, ed è metà di quello che la fa sembrare viva.
uniform float lucido = 0.45;

instance uniform float cresce = 1.0;
instance uniform float ombra = 1.0;
const float FRONTE = 0.05;

void vertex() {
	float f = clamp((cresce * (1.0 + FRONTE) - CUSTOM0.w) / FRONTE, 0.0, 1.0);
	VERTEX = mix(CUSTOM0.xyz, VERTEX, sqrt(f));
}

void fragment() {
	vec3 col;
	vec3 nrm;
	float ruvida;
	pelle_polpo(colore, normale, ruvidita, UV * piastrelle, giro_esagoni, col, nrm, ruvida);
	// la foto ha chiazze azzurrine che da vicino fanno il leopardo: si tirano verso il grigio,
	// e restano le macchie senza il colore
	col = mix(vec3(dot(col, vec3(0.333))), col, 0.70);
	ALBEDO = col * tono * ombra;
	NORMAL_MAP = nrm * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.6;
	ROUGHNESS = mix(1.0, ruvida, lucido);
	SPECULAR = 0.5 * lucido;
}
