// UN BAGLIORE che guarda sempre la camera: la luce del colore che sale al cielo.
//
// Un quadrato girato verso chi guarda, con dentro una luce che sfuma: un nucleo e un
// alone. Non una sfera — la sfera della prima stesura, colorata e piatta, era una pallina da
// biliardo in cielo. E NON DIVENTA MAI PIÙ PICCOLO DI `minimo` radianti: salendo a un
// chilometro una luce vera resta un punto, non sparisce sotto il pixel.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

uniform vec3 tinta : source_color = vec3(1.0);
uniform float forza = 1.0;
// Il lato del quadrato, in metri, e il più piccolo che può essere visto da chi guarda.
uniform float lato = 1.0;
uniform float minimo = 0.02;

void vertex() {
	vec3 centro = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float distanza = length(centro - CAMERA_POSITION_WORLD);
	float l = max(lato, distanza * minimo);
	vec3 destra = INV_VIEW_MATRIX[0].xyz;
	vec3 su = INV_VIEW_MATRIX[1].xyz;
	vec3 mondo = centro + (destra * VERTEX.x + su * VERTEX.y) * l;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(mondo, 1.0);
}

void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float luce = exp(-r * r * 30.0) * 2.5 + exp(-r * 4.0) * 0.45;
	luce *= 1.0 - smoothstep(0.75, 1.0, r);
	ALBEDO = tinta * forza * luce;
}
