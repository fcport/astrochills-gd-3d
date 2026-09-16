// LE NUBI CHE PASSANO: bande scure che attraversano il cielo come attraversano la pelle
// di un polpo, e spengono le stelle al loro passaggio.
//
// È UN DISPLAY VERO, e dello stesso polpo della pelle e dell'iride: Octopus cyanea,
// cacciando, fa scorrere sul corpo bande scure larghe, una dietro l'altra, sempre nello
// stesso verso, e la preda che le vede passare si muove e si tradisce (Mather & Mather,
// «Apparent movement in a visual display: the "passing clouds" of Octopus cyanea»,
// J. Zool. 2004). Qui la pelle è il cielo: le bande partono da un punto, `sorgente`,
// corrono verso il punto opposto, e dove passano le stelle non ci sono più.
//
// SI MOLTIPLICA SUL CIELO (`blend_mul`), e non si disegna sopra: una banda non è un
// oggetto nero steso davanti alle stelle, è il cielo che si scurisce. Per questo la cupola
// sta dietro a tutto il resto (`Orrore.CUPOLA`): l'occhio, il tentacolo, il tetto
// restano come sono, e cambia solo lo sfondo.
//
// LE BANDE NON SONO ANELLI. Un fronte perfettamente circolare attorno alla sorgente si
// legge come un'onda disegnata; quelle vere sono macchie irregolari che avanzano
// insieme. Il fronte è spostato avanti e indietro da un rumore sulla direzione, e
// l'intensità lungo la banda è a chiazze.
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

#include "res://world/shaders/orrore_rumore.gdshaderinc"

// Da dove partono le bande: un verso del mondo.
uniform vec3 sorgente = vec3(0.0, 0.2, 1.0);
// Secondi dall'inizio.
uniform float tempo = 0.0;
// 0-1: quanto è acceso tutto quanto, per entrare e uscire senza scatti.
uniform float forza = 0.0;
// Quanto corrono, in radianti di cielo al secondo, e ogni quanti radianti ne passa una.
uniform float velocita = 0.32;
uniform float passo_bande = 0.95;
// Quanto è larga una banda, in frazione del passo.
uniform float larghezza = 0.22;
// Quanto scuro nel cuore di una banda: 1 è nero. E nero dev'essere: la prima prova le
// teneva al 93% e le stelle restavano al 70% della loro luce — su un cielo già nero una
// banda che non spegne le stelle non si vede passare.
uniform float profondita = 1.0;

varying vec3 dir;

void vertex() {
	dir = VERTEX;
}

void fragment() {
	vec3 d = normalize(dir);
	vec3 s = normalize(sorgente);
	float angolo = acos(clamp(dot(d, s), -1.0, 1.0));

	// il fronte, spinto avanti e indietro dal rumore: le bande arrivano a macchie
	float storto = (orrore_ottave(d * 2.2 + vec3(0.0, tempo * 0.03, 0.0)) - 0.5) * 0.9;
	float fase = (angolo + storto - velocita * tempo) / passo_bande;
	float x = fract(fase) - 0.5;
	float banda = exp(-(x * x) / (larghezza * larghezza * 0.5));

	// a chiazze lungo la banda, e con un reticolo fine come quello della pelle
	float chiazze = smoothstep(0.25, 0.75, orrore_ottave(d * 5.0 - vec3(tempo * 0.04)));
	float grana = 0.8 + 0.2 * orrore_rumore(d * 60.0);
	// non partono prima di esserci: il primo fronte nasce dalla sorgente al tempo zero
	float nate = smoothstep(0.0, 0.25, velocita * tempo - angolo + 0.25);
	// e si spengono arrivando dall'altra parte del cielo
	float vive = 1.0 - smoothstep(2.4, 3.1, angolo);

	// il cuore della banda satura: dentro, le stelle non ci sono
	float scuro = clamp(banda * 1.7 * mix(0.65, 1.0, chiazze) * grana * nate * vive, 0.0, 1.0) * forza;
	ALBEDO = clamp(vec3(1.0) - scuro * profondita * vec3(1.0, 1.02, 1.05), 0.0, 1.0);
}
