// LA PIETRA CADUTA: la crosta scura di un meteorite, e dentro il colore.
//
// UNA METEORITE APPENA CADUTA HA LA CROSTA DI FUSIONE: un guscio nero e opaco di pochi
// decimi di millimetro, dove la superficie è fusa nell'attraversare l'aria. Nel racconto
// la pietra è calda e dentro ha dei GLOBULI di colore; qui brilla prima arancio di calore
// (`calore`), e raffreddandosi lascia vedere il colore nelle crepe e nei globuli.
shader_type spatial;
render_mode diffuse_lambert;

#include "res://world/shaders/orrore_rumore.gdshaderinc"
#include "res://world/shaders/colore_fronte.gdshaderinc"

uniform float calore = 0.0;
uniform float colore = 0.0;
uniform float grigia = 0.0;

varying vec3 locale;

void vertex() {
	locale = VERTEX;
}

void fragment() {
	float crepe = orrore_ottave(locale * 18.0);
	float globuli = smoothstep(0.58, 0.66, orrore_rumore(locale * 26.0 + vec3(3.0)));
	float vene = 1.0 - smoothstep(0.02, 0.06, abs(crepe - 0.5));
	vec3 crosta = vec3(0.05, 0.045, 0.042) * (0.7 + 0.6 * crepe);
	ALBEDO = mix(crosta, vec3(0.46, 0.45, 0.43) * (0.8 + 0.4 * crepe), grigia);
	ROUGHNESS = 0.9;
	vec3 fuoco = vec3(1.0, 0.42, 0.12) * calore * (0.4 + 0.6 * vene);
	float respira = 0.7 + 0.3 * sin(TIME * 1.7 + crepe * 9.0);
	vec3 dentro = colore_tinta(locale.xz * 6.0 + locale.y * 3.0, TIME) * colore * respira
		* max(vene, globuli) * 0.8;
	EMISSION = (fuoco + dentro) * (1.0 - grigia);
}
