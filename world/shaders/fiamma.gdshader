// La fiamma del gas: lingue blu che escono di lato dal bruciatore (D-244).
//
// ADDITIVA E SENZA LUCE: una fiamma non si illumina, fa luce. Blu pieno alla base e piu'
// scura e violacea verso la punta, che e' come appare la fiamma di un fornello a gas ben
// regolato - la punta gialla e' aria che manca, e un fuoco di cucina non la fa.
//
// IL GUIZZO e' nel vertice, e diverso per ogni lingua (`INSTANCE_ID`): tutte insieme alla
// stessa frequenza sembrerebbero una corona che respira, non un fuoco.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

// L'altezza della lingua, la stessa di `Fornello.LUNGA_LINGUA`.
uniform float lunga = 0.016;

varying float altezza;

void vertex() {
	altezza = clamp(VERTEX.y / lunga + 0.5, 0.0, 1.0);
	float guizzo = 1.0 + 0.18 * sin(TIME * 21.0 + float(INSTANCE_ID) * 2.3)
		+ 0.08 * sin(TIME * 37.0 + float(INSTANCE_ID) * 0.7);
	VERTEX.y = (VERTEX.y + lunga * 0.5) * guizzo - lunga * 0.5;
}

void fragment() {
	vec3 base = vec3(0.10, 0.26, 1.00);
	vec3 punta = vec3(0.30, 0.18, 0.75);
	ALBEDO = mix(base, punta, altezza) * (1.0 - 0.75 * altezza) * 1.5;
}
