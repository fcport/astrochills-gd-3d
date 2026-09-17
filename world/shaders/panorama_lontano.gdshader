// Il panorama da lontano: gli anelli di `world/panorama.gd`, colorati dal satellite.
//
// NON SCRIVE LA PROFONDITÀ, e sta fra i trasparenti con la priorità più bassa: gli
// anelli si coprono l'uno con l'altro nell'ordine in cui sono scritti gli indici, dal
// più lontano al più vicino, e quello che è davvero vicino li copre perché la
// profondità la leggono. Perché così e non come il resto sta in testa a `panorama.gd`.
// ALPHA scritto a uno è il modo di dire a Godot «trasparente», e nient'altro.

shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_lambert, specular_disabled;

// Il satellite, in assi di gioco: la riga zero è il bordo sud.
uniform sampler2D colore : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
// L'osservatorio (x, z) e quanti metri copre la mappa attorno.
uniform vec2 centro = vec2(0.0);
uniform float mezzo = 30000.0;
// Fuori dalla mappa, il colore medio della mappa.
uniform vec3 medio : source_color = vec3(0.1);

varying vec3 mondo;

void vertex() {
	mondo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = (mondo.xz - centro + vec2(mezzo)) / (2.0 * mezzo);
	vec2 dentro = step(vec2(0.0), uv) * step(uv, vec2(1.0));
	ALBEDO = mix(medio, texture(colore, uv).rgb, dentro.x * dentro.y);
	ROUGHNESS = 1.0;
	ALPHA = 1.0;
}
