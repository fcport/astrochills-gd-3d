// LA PELLE DEL POLPO, campionata come si deve: colore, rilievo e ruvidità presi a
// PIASTRELLE ESAGONALI dalla stessa fotografia (`assets/textures/pelle-polpo`, il polpo di
// Greg McFall/NOAA).
//
// PERCHÉ NON BASTA RIPETERE LA FOTO. Una piastrella ripetuta si conta: sull'occhio del cielo
// era «i pattern sono un po' troppo uguali tutti», e sulle braccia della visione di `Ctrl+F9`
// — dove la pelle è larga quanto un continente — era peggio, perché da vicino la stessa
// chiazza tornava ogni due metri. A esagoni (Mikkelsen, «Practical Real-Time Hex-Tiling»,
// JCGT 2022) ogni tassello prende un pezzo della foto spostato e girato a caso, e fra un
// tassello e l'altro si passa per la trama più chiara: la cucitura non si vede e la ripetizione
// nemmeno. È lo stesso codice della pelle attorno all'occhio e della ghiaia del piazzale.
//
// IL RILIEVO GIRA COL SUO ESAGONO: una normale campionata da un pezzo di foto ruotato, e non
// ruotata a sua volta, illumina la pelle da una direzione diversa in ogni tassello — e si vede
// come una scacchiera di luce.
#include "res://world/shaders/esagoni.gdshaderinc"

void pelle_polpo(sampler2D colore, sampler2D normale, sampler2D ruvidita, vec2 st,
		float giro_esagoni, out vec3 col, out vec3 nrm, out float ruvida) {
	vec3 w;
	vec2 v1;
	vec2 v2;
	vec2 v3;
	esagoni(st, w, v1, v2, v3);
	vec2 dx = dFdx(st);
	vec2 dy = dFdy(st);
	vec2 u1 = esagono_uv(st, v1, giro_esagoni);
	vec2 u2 = esagono_uv(st, v2, giro_esagoni);
	vec2 u3 = esagono_uv(st, v3, giro_esagoni);
	float a1 = esagono_angolo(v1, giro_esagoni);
	float a2 = esagono_angolo(v2, giro_esagoni);
	float a3 = esagono_angolo(v3, giro_esagoni);
	vec3 c1 = textureGrad(colore, u1, gira(dx, a1), gira(dy, a1)).rgb;
	vec3 c2 = textureGrad(colore, u2, gira(dx, a2), gira(dy, a2)).rgb;
	vec3 c3 = textureGrad(colore, u3, gira(dx, a3), gira(dy, a3)).rgb;
	vec3 pesi = esagoni_pesi(w, c1, c2, c3);
	col = pesi.x * c1 + pesi.y * c2 + pesi.z * c3;

	vec3 n1 = textureGrad(normale, u1, gira(dx, a1), gira(dy, a1)).rgb * 2.0 - 1.0;
	vec3 n2 = textureGrad(normale, u2, gira(dx, a2), gira(dy, a2)).rgb * 2.0 - 1.0;
	vec3 n3 = textureGrad(normale, u3, gira(dx, a3), gira(dy, a3)).rgb * 2.0 - 1.0;
	n1.xy = gira(n1.xy, -a1);
	n2.xy = gira(n2.xy, -a2);
	n3.xy = gira(n3.xy, -a3);
	nrm = normalize(pesi.x * n1 + pesi.y * n2 + pesi.z * n3);

	ruvida = pesi.x * textureGrad(ruvidita, u1, dx, dy).r
			+ pesi.y * textureGrad(ruvidita, u2, dx, dy).r
			+ pesi.z * textureGrad(ruvidita, u3, dx, dy).r;
}
