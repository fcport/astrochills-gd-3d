// LA COLONNA DEL COLORE: il colore che se ne va, versandosi nel cielo.
//
// «Non brillava più: si versava fuori; e mentre la corrente informe di quel colore senza
// nome lasciava il pozzo, sembrava scorrere dritta nel cielo.» (Lovecraft, 1927.) Un cilindro
// più largo in cima che in fondo, visto da dentro e da fuori, dove il colore SCORRE verso
// l'alto a fili: la stessa trama che sale sempre, così l'occhio legge il verso.
//
// I bordi sfumano col coseno fra la normale e lo sguardo, e il cilindro smette di sembrare
// un tubo: al centro è spesso, sui fianchi è aria. Poi si stacca da terra (`stacco`, la
// frazione di altezza che se n'è già andata dal basso) e sparisce in alto.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

#include "res://world/shaders/orrore_rumore.gdshaderinc"
#include "res://world/shaders/colore_fronte.gdshaderinc"

uniform float forza = 0.0;
// Fin dove è arrivata la cima, e da dove si è già staccata la base: frazioni dell'altezza.
uniform float cima = 1.0;
uniform float stacco = 0.0;
// Quanto è alta, in metri: la trama si misura in metri e non si allunga con la colonna.
uniform float altezza = 1.0;

varying vec3 locale;

void vertex() {
	locale = VERTEX;
}

void fragment() {
	float h = locale.y + 0.5;
	float metri = h * altezza;
	float fianco = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float corpo = pow(fianco, 1.6);
	// i fili: rumore allungato in verticale che corre verso l'alto, veloce vicino a terra
	float n = orrore_ottave(vec3(locale.x * 2.2, metri * 0.12 - TIME * 3.5, locale.z * 2.2));
	float fili = smoothstep(0.38, 0.78, n);
	float dentro = smoothstep(stacco, stacco + 0.02, h) * (1.0 - smoothstep(cima - 0.03, cima, h));
	// sale sfumando: in alto è un filo, non un muro
	float quota = mix(1.0, 0.18, smoothstep(0.0, 0.7, h));
	vec3 c = colore_tinta(vec2(locale.x + locale.z, metri * 0.05), TIME);
	ALBEDO = c * forza * corpo * mix(0.3, 1.8, fili) * dentro * quota;
}
