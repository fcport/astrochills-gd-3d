// Monitor CRT diegetico — curvatura, scanline, aberrazione, vignettatura.
//
// Shader spatial su un mesh 3D che mostra la texture di un SubViewport.
// Nessun CompositorEffect: non esiste in Compatibility, e non serve.
//
// filter_nearest sulla texture dello schermo: è metà dell'estetica. Non
// sostituirlo con lineare "per migliorare la resa".

shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform sampler2D screen_tex : filter_nearest;

uniform float curvature : hint_range(1.0, 16.0) = 5.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.30;
uniform float scanline_count : hint_range(60.0, 600.0) = 240.0;
uniform float aberration : hint_range(0.0, 0.02) = 0.0018;
uniform float vignette : hint_range(0.0, 2.0) = 0.35;
uniform float brightness : hint_range(0.0, 3.0) = 1.0;
uniform vec3 tint : source_color = vec3(1.0, 0.96, 0.90);

// Quanta parte del VETRO occupa l'immagine, sui due assi. Vale (1, 1) quando il
// tubo ha lo stesso rapporto del viewport, ed e' il caso normale.
//
// SERVE PERCHE' UN TUBO NON HA IL RAPPORTO CHE VUOI TU. Quello della sala di
// controllo e' 30,9 x 27,4 cm, cioe' quasi quadrato; l'immagine e' 4:3. Restano
// due bande, e la domanda e' chi le disegna. Prima le disegnava la MESH DEL
// MODELLO dietro il quad - un secondo rettangolo, illuminato dalle luci della
// stanza, che si vedeva come uno schermo dietro lo schermo e che in prospettiva
// non poteva coincidere con quello davanti: guardando da seduti, banda spessa
// sopra e niente sotto.
//
// Disegnandole QUI sono fatte della stessa cosa dell'immagine, sullo stesso
// oggetto, e sono nere davvero - `unshaded`, nessuna luce le tocca. Due
// rettangoli che non possono scollarsi perche' sono uno.
//
// Non si dichiara a mano: `crt/crt_screen.gd` lo calcola dal quad e dal viewport.
uniform vec2 image_scale = vec2(1.0, 1.0);

// Di quanti METRI il vetro rientra agli angoli rispetto al suo centro. Zero = un
// quad piatto, che e' come nasce la scena del CRT.
//
// UN VETRO PIATTO SI VEDE, e si vede come un adesivo. Il tubo della sala di
// controllo e' bombato di 12,7 millimetri - misurati sul modello, non scelti - e
// il rettangolo piatto che ci stava davanti leggeva come un quadrato incollato
// sopra una scatola. Non e' un problema di ombreggiatura: `unshaded` non
// illumina niente. E' che il profilo e' dritto, e in un tubo non lo e' mai.
//
// Serve il quad SUDDIVISO: su due triangoli soli non c'e' niente da spostare.
uniform float bulge = 0.0;

// La calotta: al centro niente, agli angoli tutto.
//
// `dot(d, d) * 0.5` e non `clamp(dot(d, d))`: agli angoli d vale (1, 1) e il
// prodotto scalare 2, a meta' di un lato vale 1. Con la meta' gli angoli
// rientrano di `bulge` e i lati della meta', che e' il profilo di una calotta.
// Con il clamp rientrerebbero uguale, e sarebbe una scodella a fondo piatto.
void vertex() {
	vec2 d = (UV - 0.5) * 2.0;
	VERTEX.z -= bulge * dot(d, d) * 0.5;
}

// Piega le UV come il vetro di un cinescopio.
vec2 curve_uv(vec2 uv, float amount) {
	uv = uv * 2.0 - 1.0;
	vec2 offset = abs(uv.yx) / amount;
	uv += uv * offset * offset;
	return uv * 0.5 + 0.5;
}

void fragment() {
	// Prima il vetro: le UV piegate come il cinescopio, sull'INTERO tubo.
	vec2 glass = curve_uv(UV, curvature);
	// Poi l'immagine, che occupa solo la parte centrale del vetro. Tutto quello
	// che segue lavora in coordinate dell'IMMAGINE: le scanline si contano sulle
	// sue righe, la vignettatura sui suoi bordi.
	vec2 uv = (glass - 0.5) / image_scale + 0.5;

	// Fuori dall'immagine: nero. E' il vetro spento attorno, e la cornice curva
	// del tubo, con la stessa riga. Branchless, niente discard.
	vec2 inside = step(vec2(0.0), uv) * step(uv, vec2(1.0));
	float mask = inside.x * inside.y;

	// Aberrazione cromatica: i tre canali campionati con offset opposti.
	float r = texture(screen_tex, uv + vec2(aberration, 0.0)).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv - vec2(aberration, 0.0)).b;
	vec3 col = vec3(r, g, b) * tint * brightness;

	// Scanline orizzontali.
	float scan = 1.0 - scanline_strength * (0.5 + 0.5 * sin(uv.y * scanline_count * 6.28318));
	col *= scan;

	// Vignettatura ai bordi del tubo.
	vec2 v = uv * (1.0 - uv.yx);
	col *= pow(clamp(v.x * v.y * 24.0, 0.0, 1.0), vignette);

	ALBEDO = col * mask;
}
