// IL CERCHIO NERO DI CHI GUARDA DENTRO UN TUBO.
//
// PERCHE' NON E' UNA TEXTURE. Un PNG con un buco tondo andrebbe rifatto a ogni
// risoluzione, e questo quadro ne cambia due volte - il mondo vive dentro un
// SubViewport da 640x360 che poi viene stirato. Il cerchio calcolato per pixel sta
// dove deve a qualunque misura e non pesa niente: e' una distanza e una soglia.
//
// IL BORDO NON E' NETTO, e non e' una rifinitura estetica. Un cerchio a spigolo
// vivo su 360 righe si vede a scalini, e a scalini non sembra un tubo - sembra una
// maschera. La sfumatura la si tiene stretta, un paio di punti percentuali: quello
// che serve a togliere la scala, non a fare una vignettatura da fotografia.
//
// E IL CAMPO NON E' TONDO SULLO SCHERMO INTERO: il cerchio si misura sull'ALTEZZA,
// quindi tocca il bordo alto e basso e lascia neri i due fianchi. E' come si vede
// mettendo l'occhio a un oculare su uno schermo largo, ed e' anche quello che
// impedisce di leggere la vista come «il gioco a schermo intero, piu' scuro».
shader_type canvas_item;

// Quanto del semiquadro verticale resta scoperto. 1.0 = il cerchio tocca esattamente
// il bordo alto e basso.
uniform float raggio : hint_range(0.1, 1.5) = 0.92;

// Quanto e' morbido il bordo, nelle stesse unita' del raggio.
uniform float sfumatura : hint_range(0.001, 0.2) = 0.03;

void fragment() {
	// Coordinate centrate, corrette per la forma del quadro: cosi' il cerchio resta
	// un cerchio anche su un 16:9, invece di diventare un'ellisse.
	vec2 q = SCREEN_UV - vec2(0.5);
	vec2 dim = 1.0 / SCREEN_PIXEL_SIZE;
	q.x *= dim.x / dim.y;
	float d = length(q) * 2.0;
	COLOR = vec4(0.0, 0.0, 0.0, smoothstep(raggio - sfumatura, raggio + sfumatura, d));
}
