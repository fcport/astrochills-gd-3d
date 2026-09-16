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
// Quanto è chiaro il piede del ciuffo rispetto alla punta. La foto è fatta senza
// luce, e un ciuffo chiaro fino a terra sta sul prato come un timbro: in un prato
// vero la base dei fili è all'ombra degli altri fili.
uniform float piede : hint_range(0.0, 1.0) = 0.35;

// Risoluzione della griglia di snapping, la stessa di ps1.gdshader.
uniform float snap_resolution : hint_range(8.0, 2048.0) = 665.0;

// IL COLORE VENUTO DALLO SPAZIO (`world/orrori/colore.gd`). A zero l'erba è quella di
// sempre: è il valore con cui il prato nasce.
//   * `colore_dove` è il punto in pianta (x, z) dove è caduta la pietra, `colore_raggio` fin
//     dove il colore è arrivato nell'erba, in metri — a macchie, non a cerchio;
//   * `colore_forza` quanto brillano le PUNTE, e quanto i ciuffi tremano SENZA VENTO;
//   * `colore_tende` quanto i ciuffi si allungano verso il cielo: nel racconto, prima che il
//     colore se ne vada, ogni ramo si tende verso l'alto;
//   * `colore_raccolta` quanto il bagliore si è ritirato verso la pietra, prima di partire;
//   * `colore_cenere` quanto il prato che ha brillato è diventato polvere grigia;
//   * `colore_buca` il raggio dell'erba schiacciata dove la pietra è entrata nel terreno.
uniform vec2 colore_dove = vec2(0.0);
uniform float colore_raggio = 0.0;
uniform float colore_forza = 0.0;
uniform float colore_tende = 0.0;
uniform float colore_raccolta = 0.0;
uniform float colore_cenere = 0.0;
uniform float colore_buca = 0.0;

#include "res://world/shaders/colore_fronte.gdshaderinc"

varying float colonna;
varying vec3 tinta;
varying vec3 mondo_ciuffo;
varying float preso;
varying float vivo;

void vertex() {
	colonna = floor(INSTANCE_CUSTOM.r * varianti);
	tinta = INSTANCE_CUSTOM.gba;
	mondo_ciuffo = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	preso = 0.0;
	vivo = 0.0;
	if (colore_raggio > 0.0 || colore_buca > 0.0) {
		vec2 q = mondo_ciuffo.xz;
		preso = colore_fronte(q, colore_dove, colore_raggio);
		vivo = colore_fronte(q, colore_dove, colore_raggio * (1.0 - colore_raccolta));
		float alto = 1.0 - UV.y;
		float caso = colore_hash(q * 13.7);
		// TREMANO SENZA VENTO, ognuno per conto suo, a scatti piccoli e non a onde: un prato
		// mosso dal vento si muove tutto nello stesso verso, questo no.
		float t = TIME * 5.0 + caso * 40.0;
		vec2 scossa = vec2(colore_rumore(vec2(t, caso * 7.0)), colore_rumore(vec2(caso * 5.0, t * 1.13))) - 0.5;
		VERTEX.xz += scossa * 0.07 * alto * vivo * colore_forza;
		// E SI TENDONO VERSO IL CIELO
		VERTEX.y *= 1.0 + 0.45 * colore_tende * vivo;
		// LA CENERE: il ciuffo si affloscia e si piega da una parte
		float giu = colore_cenere * preso;
		VERTEX.y *= mix(1.0, 0.3, giu);
		vec2 piega = vec2(cos(caso * 6.2831853), sin(caso * 6.2831853));
		VERTEX.xz += piega * 0.14 * alto * giu;
		// la buca della pietra
		float schiacciato = 1.0 - smoothstep(colore_buca * 0.6, colore_buca, distance(q, colore_dove));
		VERTEX.y *= mix(1.0, 0.12, schiacciato * step(0.001, colore_buca));
	}
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec2 grid = vec2(snap_resolution, snap_resolution * 0.75);
	clip.xy = round(clip.xy / clip.w * grid) / grid * clip.w;
	POSITION = clip;
}

void fragment() {
	vec4 foto = texture(ciuffi, vec2((UV.x + colonna) / varianti, UV.y));
	ALBEDO = foto.rgb * tinta * mix(1.0, piede, UV.y);
	if (preso > 0.0) {
		// BRILLANO I FILI, più forte verso la punta: di notte un prato che fosforeggia è fatto
		// di migliaia di punti, e il bagliore striscia fra un ciuffo e l'altro invece di stare
		// acceso tutto insieme.
		//
		// E BRILLANO DAVVERO. La prima stesura arrivava a mezza unità sulle punte, e sotto la
		// Luna era un campo di lavanda: un colore, non una luce. Sopra l'unità il bagliore
		// dello schermo (acceso da `colore.gd` finché il colore c'è) lo fa sbordare nell'aria.
		float punta = pow(1.0 - UV.y, 1.6);
		vec2 q = mondo_ciuffo.xz;
		float striscia = smoothstep(0.2, 0.8, colore_rumore(q * 0.6 + vec2(TIME * 0.35, -TIME * 0.27)));
		float sfarfalla = 0.6 + 0.4 * colore_rumore(vec2(TIME * 2.3, colore_hash(q) * 50.0));
		vec3 c = colore_tinta(q + vec2(UV.x * 0.3, UV.y * 0.6), TIME);
		EMISSION = c * punta * vivo * colore_forza * mix(0.12, 1.0, striscia) * sfarfalla * 1.5;
		// e l'erba presa ha già una tinta sbagliata anche di giorno: spenta, livida
		float grigio_erba = dot(ALBEDO, vec3(0.299, 0.587, 0.114));
		ALBEDO = mix(ALBEDO, vec3(grigio_erba) * vec3(1.05, 0.92, 1.08), 0.35 * preso * min(colore_forza, 1.0));
		// LA CENERE: polvere grigia e secca. Non chiara: sotto la Luna un grigio chiaro è neve
		// una polvere, non una ghiaia: il granello per pixel della prima stesura sembrava sassi
		float grana = 0.88 + 0.24 * colore_rumore(q * 2.3 + UV * vec2(3.0, 5.0));
		ALBEDO = mix(ALBEDO, vec3(0.30, 0.29, 0.27) * grana * mix(1.0, 0.7, UV.y), preso * colore_cenere);
	}
	ALPHA = foto.a;
	ALPHA_SCISSOR_THRESHOLD = soglia;
	ROUGHNESS = 1.0;
}
