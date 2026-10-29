// LA LUCE DI GERARDO, alla maniera di Doom (D-287).
//
// PERCHÉ NON BASTA `shaded`. Uno sprite è un foglio girato verso chi guarda, e la sua
// normale è orizzontale: la luce lambertiana lo accende solo quando arriva da davanti. Fuori,
// nei fari dell'auto, era perfetto. Dentro, le plafoniere stanno sopra la testa, la luce gli
// arriva di taglio, e in mezzo alla sala illuminata diventava una sagoma nera — Federico:
// «diventa stranamente tutto nero, e fa paura nel modo sbagliato».
//
// IN DOOM UNO SPRITE PRENDEVA LA LUCE DEL SETTORE in cui stava, da qualunque parte venisse.
// Qui è lo stesso conto: ogni luce che lo raggiunge — attenuazione e ombra comprese, quindi
// una lampada dietro un muro non conta — lo accende per almeno il FONDO della sua forza,
// anche se gli sta sopra la testa. Il resto dipende da dove arriva: piena da davanti,
// sempre meno di lato, e da dietro resta il fondo meno quanto toglie. Uno controluce resta
// più scuro, come deve; non diventa un buco.
shader_type spatial;
render_mode cull_disabled, specular_disabled, depth_draw_opaque;

uniform sampler2D atlante : source_color, filter_nearest;

// Quanta luce prende comunque da una lampada che lo raggiunge, e quanta in più (o in meno)
// a seconda che gli arrivi davanti o dietro. 0,6 + 0,4: dall'alto sei decimi, da davanti
// tutta, da dietro due decimi.
const float FONDO = 0.6;
const float DIREZIONE = 0.4;

void vertex() {
	// GIRA ATTORNO ALLA VERTICALE, come `billboard = FIXED_Y`: con un materiale suo, lo
	// sprite non lo fa più da sé.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 c = texture(atlante, UV);
	// il taglio a metà opacità, come `alpha_cut`: l'atlante ha già l'alfa netta
	if (c.a < 0.5) {
		discard;
	}
	ALBEDO = c.rgb;
}

void light() {
	float quanto = clamp(FONDO + DIREZIONE * dot(NORMAL, LIGHT), 0.0, 1.0);
	DIFFUSE_LIGHT += quanto * ATTENUATION * LIGHT_COLOR / PI;
}
