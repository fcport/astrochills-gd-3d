// L'erba del prato: il ciuffo fotografato da tools/erba_blender.py, su due
// rettangoli incrociati (world/prato.gd).
//
// È ps1.gdshader con tre cose in più e nessuna in meno. La texture con la
// trasparenza A SOGLIA: un filo d'erba ha il bordo netto, e un bordo sfumato
// vorrebbe dire ordinare migliaia di rettangoli trasparenti. La variante e la tinta
// di ogni ciuffo, che arrivano dal MultiMesh in INSTANCE_CUSTOM. E le due facce: un
// rettangolo d'erba si guarda da tutte e due le parti.

shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled, cull_disabled;

// Le varianti in fila, da sinistra a destra.
uniform sampler2D ciuffi : source_color, filter_nearest, repeat_disable;
uniform float varianti = 4.0;
// Sotto questa copertura il pixel non c'è.
uniform float soglia : hint_range(0.0, 1.0) = 0.4;

// Risoluzione della griglia di snapping, la stessa di ps1.gdshader.
uniform float snap_resolution : hint_range(8.0, 2048.0) = 665.0;

varying float colonna;
varying vec3 tinta;

void vertex() {
	colonna = floor(INSTANCE_CUSTOM.r * varianti);
	tinta = INSTANCE_CUSTOM.gba;
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec2 grid = vec2(snap_resolution, snap_resolution * 0.75);
	clip.xy = round(clip.xy / clip.w * grid) / grid * clip.w;
	POSITION = clip;
}

void fragment() {
	vec4 foto = texture(ciuffi, vec2((UV.x + colonna) / varianti, UV.y));
	ALBEDO = foto.rgb * tinta;
	ALPHA = foto.a;
	ALPHA_SCISSOR_THRESHOLD = soglia;
	ROUGHNESS = 1.0;
}
