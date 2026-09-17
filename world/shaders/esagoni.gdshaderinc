// LE PIASTRELLE ESAGONALI (Mikkelsen, «Practical Real-Time Hex-Tiling», JCGT 2022): una foto
// che si ripete si conta, e campionata a esagoni - ognuno con un pezzo della foto spostato e
// girato a caso, e fra un esagono e l'altro si passa per la trama più chiara - la cucitura
// non si vede.
//
// Lo usano `occhio_pelle.gdshader`, per la pelle del polpo, e `panorama_vicino.gdshader`,
// per la ghiaia.

vec2 esagono_caso(vec2 v) {
	vec2 r = vec2(dot(v, vec2(127.1, 311.7)), dot(v, vec2(269.5, 183.3)));
	return fract(sin(r) * 43758.5453);
}

// I tre esagoni che toccano `st`, e quanto pesa ognuno.
void esagoni(vec2 st, out vec3 w, out vec2 v1, out vec2 v2, out vec2 v3) {
	st *= 3.4641016;
	vec2 obliquo = vec2(st.x - 0.57735027 * st.y, 1.15470054 * st.y);
	vec2 base = floor(obliquo);
	vec3 t = vec3(fract(obliquo), 0.0);
	t.z = 1.0 - t.x - t.y;
	float s = step(0.0, -t.z);
	float s2 = 2.0 * s - 1.0;
	w = vec3(-t.z * s2, s - t.y * s2, s - t.x * s2);
	v1 = base + vec2(s, s);
	v2 = base + vec2(s, 1.0 - s);
	v3 = base + vec2(1.0 - s, s);
}

vec2 esagono_centro(vec2 v) {
	return vec2(v.x + 0.5 * v.y, v.y / 1.15470054) / 3.4641016;
}

// Quanto gira l'esagono `v`: `giro` 1 vuol dire qualunque angolo.
float esagono_angolo(vec2 v, float giro) {
	return (esagono_caso(v + vec2(17.0, 3.0)).x * 2.0 - 1.0) * 3.14159265 * giro;
}

vec2 gira(vec2 v, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

// Il punto della foto per l'esagono `v`: girato attorno al suo centro e spostato a caso.
vec2 esagono_uv(vec2 st, vec2 v, float giro) {
	vec2 c = esagono_centro(v);
	return gira(st - c, esagono_angolo(v, giro)) + c + esagono_caso(v);
}

// Il peso di ognuno dei tre campioni: va con la luminanza, poi si stringe.
vec3 esagoni_pesi(vec3 w, vec3 c1, vec3 c2, vec3 c3) {
	vec3 lum = vec3(dot(c1, vec3(0.299, 0.587, 0.114)), dot(c2, vec3(0.299, 0.587, 0.114)),
			dot(c3, vec3(0.299, 0.587, 0.114)));
	vec3 pesi = mix(vec3(1.0), lum, 0.6) * pow(w, vec3(7.0));
	return pesi / max(pesi.x + pesi.y + pesi.z, 1e-5);
}

// Il colore di una trama a esagoni, in `st`: coordinate della foto misurate sul lato largo,
// perché si gira in metri e non in pixel. `forma` le porta sulla foto - (1, 2) per una foto
// larga il doppio di quanto è alta -, e girare prima di stirare lascia tondo quello che è
// tondo.
vec3 esagoni_colore(sampler2D t, vec2 st, vec2 forma, float giro) {
	vec3 w;
	vec2 v1;
	vec2 v2;
	vec2 v3;
	esagoni(st, w, v1, v2, v3);
	vec2 dx = dFdx(st);
	vec2 dy = dFdy(st);
	float a1 = esagono_angolo(v1, giro);
	float a2 = esagono_angolo(v2, giro);
	float a3 = esagono_angolo(v3, giro);
	vec3 c1 = textureGrad(t, esagono_uv(st, v1, giro) * forma, gira(dx, a1) * forma, gira(dy, a1) * forma).rgb;
	vec3 c2 = textureGrad(t, esagono_uv(st, v2, giro) * forma, gira(dx, a2) * forma, gira(dy, a2) * forma).rgb;
	vec3 c3 = textureGrad(t, esagono_uv(st, v3, giro) * forma, gira(dx, a3) * forma, gira(dy, a3) * forma).rgb;
	vec3 pesi = esagoni_pesi(w, c1, c2, c3);
	return pesi.x * c1 + pesi.y * c2 + pesi.z * c3;
}
