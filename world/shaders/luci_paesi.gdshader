// Le luci dei paesi nella valle (`world/panorama.gd`): un punto per lampione, sempre largo
// `pixel` pixel sullo schermo, qualunque sia la distanza. Da tre chilometri un lampione non
// è un disco: è un punto, e diventa più fioco, non più piccolo.
//
// IL COLORE È IL SODIO ad alta pressione, l'arancio dell'illuminazione pubblica italiana del
// 1999 (i LED bianchi verranno vent'anni dopo). LA FORZA scende col quadrato della distanza,
// com'è per una sorgente puntiforme, fra un tetto e un pavimento: sotto il pavimento un
// paese a quindici chilometri sparirebbe, e a occhio nudo invece si vede.
//
// NON SCRIVONO LA PROFONDITÀ e vengono dopo gli anelli lontani, che non la scrivono
// nemmeno loro: chi è dietro una collina l'ha già tolto `tools/prendi_panorama.py`, che
// ha tirato un raggio dall'osservatorio a ogni lampione. Quello che è vicino - gli alberi,
// l'edificio, la griglia - li copre con la profondità.

shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

uniform vec3 colore : source_color = vec3(1.0, 0.62, 0.26);
uniform float energia = 3.0;
uniform float pixel = 2.5;
// La distanza sotto cui la forza non sale più, e il pavimento sotto cui non scende.
uniform float vicino = 1500.0;
uniform float pavimento = 0.06;

varying float forza;

void vertex() {
	vec3 centro = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float d = length(centro);
	float lato = pixel * 2.0 * d / (VIEWPORT_SIZE.y * PROJECTION_MATRIX[1][1]);
	POSITION = PROJECTION_MATRIX * vec4(centro + vec3(VERTEX.xy * lato, 0.0), 1.0);
	forza = INSTANCE_CUSTOM.r * clamp(pow(vicino / max(d, 1.0), 2.0), pavimento, 1.0);
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float a = clamp(1.0 - dot(q, q), 0.0, 1.0);
	ALBEDO = colore * energia;
	ALPHA = a * forza;
}
