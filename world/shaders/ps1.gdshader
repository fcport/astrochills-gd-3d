// Materiale PS1: vertex snapping + illuminazione per-vertice.
//
// Il jitter dei vertici non è un difetto: la PlayStation non aveva una unità in
// virgola mobile per la geometria, e le posizioni si agganciavano a una griglia
// in screen space. È metà di ciò che rende riconoscibile quell'estetica.
//
// L'altra metà — l'affine texture mapping, cioè le texture che "nuotano" sulle
// superfici — arriva quando ci saranno texture vere.

shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled;

uniform vec3 albedo : source_color = vec3(0.7, 0.7, 0.7);

// Risoluzione della griglia di snapping. Più bassa = più jitter.
uniform float snap_resolution : hint_range(8.0, 2048.0) = 665.0;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec2 grid = vec2(snap_resolution, snap_resolution * 0.75);
	clip.xy = round(clip.xy / clip.w * grid) / grid * clip.w;
	POSITION = clip;
}

void fragment() {
	ALBEDO = albedo;
	ROUGHNESS = 1.0;
}
