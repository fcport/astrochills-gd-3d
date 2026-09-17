// Gli alberi lontani del panorama: la foto di fianco di `tools/alberi_blender.py` su due
// rettangoli incrociati (`world/panorama.gd`), come l'erba del prato.
//
// LA TRASPARENZA È A RETINO (ALPHA_HASH): un pixel c'è o non c'è, con la probabilità della
// copertura. Da lontano una chioma spoglia non è una sagoma piena ma una velatura di
// rametti attraverso cui si vede il cielo, e una soglia fissa sceglieva fra due sbagli:
// bassa, macchie grigie piene; alta, i soli tronchi. Il retino è anche quello che faceva
// la PlayStation al posto della trasparenza.
//
// E LA COPERTURA SI RECUPERA UN PO' CON LA DISTANZA (`copertura_sottile.gdshaderinc`):
// senza, a trecento metri la chioma si dissolverebbe.

shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

#include "res://world/shaders/copertura_sottile.gdshaderinc"

// Le varianti in fila, da sinistra a destra.
uniform sampler2D sagome : source_color, filter_linear_mipmap, repeat_disable;
uniform float varianti = 4.0;
// Quanto si alza la copertura per ogni livello di mipmap.
uniform float recupero = 0.2;

varying float colonna;

void vertex() {
	colonna = INSTANCE_CUSTOM.r;
	// la normale in su, come i ciuffi: di taglio, ogni albero prenderebbe la luce di un muro
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	float k = floor(colonna * varianti);
	vec2 uv = vec2((k + clamp(UV.x, 0.002, 0.998)) / varianti, UV.y);
	vec4 c = texture(sagome, uv);
	vec2 lato = vec2(textureSize(sagome, 0)) / vec2(varianti, 1.0);
	ALBEDO = c.rgb;
	ROUGHNESS = 1.0;
	ALPHA = copertura_sottile(c.a, UV, lato, recupero);
	ALPHA_HASH_SCALE = 1.0;
}
