// La maglia della rete del recinto (`world/recinto.gd`): la texture di Poly Haven con la
// sua opacità, tinta di verde, A RETINO e con la copertura rialzata da lontano
// (`copertura_sottile.gdshaderinc`). Il filo è di tre millimetri, e a quattro metri, sullo
// schermo del gioco, è meno di un pixel.

shader_type spatial;
render_mode cull_disabled, diffuse_lambert;

#include "res://world/shaders/copertura_sottile.gdshaderinc"

uniform sampler2D maglia : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tinta : source_color = vec3(1.0);
// La ripetizione della maglia sul pannello, quella che il modello dichiara.
uniform vec3 scala = vec3(1.0);
uniform vec3 spostamento = vec3(0.0);
uniform float recupero = 0.8;

void vertex() {
	UV = UV * scala.xy + spostamento.xy;
}

void fragment() {
	vec4 c = texture(maglia, UV);
	ALBEDO = c.rgb * tinta;
	ROUGHNESS = 0.6;
	ALPHA = copertura_sottile(c.a, UV, vec2(textureSize(maglia, 0)), recupero);
	ALPHA_HASH_SCALE = 1.0;
}
