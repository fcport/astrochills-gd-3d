// LA COPERTURA DELLE COSE PIÙ SOTTILI DI UN PIXEL: rametti e fili di rete.
//
// Un rametto nella foto di un albero, o il filo di una rete, è largo un pixel della
// texture. Più lontano la mipmap lo media con il vuoto che ha attorno, e la sua trasparenza
// scende livello dopo livello: a soglia sparisce, a retino si dirada fino a non vedersi. Qui
// la copertura si rialza di `recupero` per ogni livello di mipmap che il campionamento sta
// usando - che è esattamente quanto la media l'ha abbassata, a meno del vuoto vero.
//
// Lo usano `albero_sagoma.gdshader` e `rete.gdshader`, con la trasparenza a retino.

float copertura_sottile(float alfa, vec2 uv, vec2 lato_texture, float recupero) {
	vec2 dx = dFdx(uv * lato_texture);
	vec2 dy = dFdy(uv * lato_texture);
	float livello = max(0.0, 0.5 * log2(max(dot(dx, dx), dot(dy, dy))));
	return clamp(alfa * (1.0 + recupero * livello), 0.0, 1.0);
}
