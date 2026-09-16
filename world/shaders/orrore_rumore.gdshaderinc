// Il rumore degli orrori del cielo: valore interpolato su una griglia 3D, e la sua somma
// a ottave. Si campiona sulle DIREZIONI, non sugli UV: una cupola ha i poli, e un rumore
// sugli UV ci si stringerebbe attorno in una stella.
//
// Niente texture di rumore, e non per risparmio: il cielo si muove per minuti e deve
// restare continuo in ogni direzione, e una mappa ripetuta sulla sfera prima o poi si
// vede ripetere.

float orrore_hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float orrore_rumore(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(orrore_hash(i + vec3(0.0, 0.0, 0.0)), orrore_hash(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(orrore_hash(i + vec3(0.0, 1.0, 0.0)), orrore_hash(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(orrore_hash(i + vec3(0.0, 0.0, 1.0)), orrore_hash(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(orrore_hash(i + vec3(0.0, 1.0, 1.0)), orrore_hash(i + vec3(1.0, 1.0, 1.0)), f.x), f.y),
		f.z);
}

float orrore_ottave(vec3 p) {
	float somma = 0.0;
	float peso = 0.5;
	for (int i = 0; i < 5; i++) {
		somma += peso * orrore_rumore(p);
		p = p * 2.03 + vec3(1.7, 9.2, 4.1);
		peso *= 0.5;
	}
	return somma;
}
