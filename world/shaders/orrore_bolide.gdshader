// IL BOLIDE, disegnato sulla cupola degli orrori (`Orrore.CUPOLA`): una testa, la sua scia,
// e la traccia che resta accesa dopo.
//
// COPIATO DA COME SI VEDE UN BOLIDE DA TERRA:
//   * LA TESTA È VERDASTRA, la scia arancio: il verde è la luce del magnesio e dell'ossigeno
//     eccitati davanti al sasso, l'arancio il sodio e il ferro che restano dietro. È il
//     colore della maggior parte delle palle di fuoco fotografate.
//   * CRESCE E SCOPPIA: la luminosità sale mentre il sasso scende nell'aria più densa, e alla
//     fine c'è un lampo — il sasso si frantuma — e poi niente.
//   * LA TRACCIA PERSISTENTE: dopo i bolidi luminosi una striscia verde resta accesa per
//     secondi dove è passata la testa.
//   * È CORTO, e non per risparmio: un sasso che cade a dodici metri da te viene VERSO di te, e
//     da terra la sua strada si accorcia in prospettiva. Una striscia da un capo all'altro del
//     cielo cadrebbe a cento chilometri.
//
// Si SOMMA al cielo (`blend_add`) come una luce, e sta dietro a tutto.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

// La strada: un arco di cerchio massimo da `inizio` a `fine`, e dove sta la testa (0-1).
uniform vec3 inizio = vec3(0.0, 0.6, 0.8);
uniform vec3 fine = vec3(0.0, 0.3, 0.95);
uniform float testa = 0.0;
// Quanto è lunga la scia, in frazione della strada.
uniform float scia_lunga = 0.35;
uniform float luce = 1.0;
uniform float scia = 1.0;
uniform float traccia = 0.0;
uniform vec3 colore_testa : source_color = vec3(0.80, 1.00, 0.82);
uniform vec3 colore_scia : source_color = vec3(1.00, 0.70, 0.38);
uniform vec3 colore_traccia : source_color = vec3(0.45, 0.85, 0.55);

varying vec3 dir;

void vertex() {
	dir = VERTEX;
}

void fragment() {
	vec3 d = normalize(dir);
	vec3 a0 = normalize(inizio);
	vec3 a1 = normalize(fine);
	vec3 asse = normalize(cross(a0, a1));
	float arco = acos(clamp(dot(a0, a1), -1.0, 1.0));
	float fuori = asin(clamp(dot(d, asse), -1.0, 1.0));
	vec3 q = normalize(d - asse * dot(d, asse));
	float lungo = atan(dot(cross(a0, q), asse), dot(a0, q));

	float h = testa * arco;
	vec3 c = vec3(0.0);
	// la testa: un nucleo e un alone
	float dt = length(vec2(lungo - h, fuori));
	c += colore_testa * luce * (exp(-pow(dt / 0.006, 2.0)) * 3.0 + exp(-dt / 0.025) * 0.35);
	// la scia, più larga e più spenta verso la coda
	float dietro = (h - lungo) / max(scia_lunga * arco, 1e-4);
	if (dietro > 0.0 && dietro < 1.0) {
		float w = mix(0.0035, 0.007, dietro);
		c += colore_scia * scia * pow(1.0 - dietro, 2.0) * exp(-pow(fuori / w, 2.0)) * 1.4;
	}
	// la traccia che resta, dove la testa è passata
	if (lungo > 0.0 && lungo < h) {
		c += colore_traccia * traccia * exp(-pow(fuori / 0.005, 2.0)) * 0.5;
	}
	ALBEDO = c;
}
