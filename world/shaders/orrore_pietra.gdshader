// LA PIETRA CADUTA: la meteorite vera, calda, e dentro il colore.
//
// La forma e la pelle sono GRO 17102,0, una meteorite ferrosa scansionata dalla NASA
// (`tools/meteorite_blender.py`): bruna, con le impronte di pollice che l'aria scava fondendo
// il metallo. Qui si aggiunge solo quello che CAMBIA:
//   * IL CALORE (`calore`, da 1 a 0). Arriva incandescente, bianco-giallo, e si raffredda
//     passando per l'arancio e il rosso cupo. Le fossette restano calde più a lungo delle
//     creste, che sono sottili e toccano l'aria: si legge dalla luminosità della texture,
//     scuro = fossetta.
//   * IL COLORE (`colore`). Raffreddandosi, nelle fossette più profonde e in globuli sparsi
//     compare il colore, che non è di nessuno spettro e non si spegne raffreddandosi.
//   * LA CENERE (`grigia`): quando il colore se ne va, la pietra diventa grigia e secca.
shader_type spatial;
render_mode diffuse_lambert;

#include "res://world/shaders/orrore_rumore.gdshaderinc"
#include "res://world/shaders/colore_fronte.gdshaderinc"

uniform sampler2D pelle : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float calore = 0.0;
uniform float colore = 0.0;
uniform float grigia = 0.0;

varying vec3 locale;

void vertex() {
	locale = VERTEX;
}

// Il colore di un corpo caldo, da 0 (spento) a 1 (bianco): rosso cupo, arancio, giallo.
vec3 incandescenza(float t) {
	vec3 rosso = vec3(0.55, 0.05, 0.0);
	vec3 arancio = vec3(1.0, 0.35, 0.05);
	vec3 giallo = vec3(1.0, 0.85, 0.55);
	vec3 c = mix(rosso, arancio, smoothstep(0.0, 0.5, t));
	return mix(c, giallo, smoothstep(0.5, 1.0, t));
}

void fragment() {
	vec3 base = texture(pelle, UV).rgb;
	// in sRGB, come la si è misurata: `source_color` la legge lineare, e a luminanza lineare
	// tutta la pelle stava sotto la soglia delle fossette e brillava tutta
	float chiaro = pow(dot(base, vec3(0.299, 0.587, 0.114)), 1.0 / 2.2);
	// le fossette: il quarto più scuro della foto (la luminanza della pelle va da 0,15 a 0,43,
	// mediana 0,28: misurata sulla texture)
	float fossa = 1.0 - smoothstep(0.14, 0.24, chiaro);
	ALBEDO = mix(base, vec3(0.42, 0.41, 0.39) * (0.7 + 0.6 * chiaro), grigia);
	ROUGHNESS = mix(0.7, 0.95, grigia);

	// IL CALORE: le creste si spengono prima delle fossette. E SI SPEGNE PRESTO: un metallo
	// sotto i cinquecento gradi non si vede più brillare, quindi la luce va col cubo del calore.
	// La prima taratura la teneva accesa tutta, uniforme, e la pietra era una macchia arancio
	// senza forma; così a metà raffreddamento brillano solo le impronte di pollice.
	float qui = clamp(calore * mix(0.35, 1.0, fossa), 0.0, 1.0);
	vec3 fuoco = incandescenza(qui) * pow(qui, 3.0) * 6.0;

	// IL COLORE: nelle fossette e in globuli, respirando
	float globuli = smoothstep(0.6, 0.7, orrore_rumore(locale * 34.0 + vec3(3.0)));
	float respira = 0.7 + 0.3 * sin(TIME * 1.7 + chiaro * 12.0);
	vec3 dentro = colore_tinta(locale.xz * 40.0 + locale.y * 20.0, TIME) * colore * respira
			* max(fossa * fossa, globuli) * 0.6;
	EMISSION = (fuoco + dentro) * (1.0 - grigia);
}
