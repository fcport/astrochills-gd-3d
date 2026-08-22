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
uniform float brightness : hint_range(0.0, 3.0) = 1.15;
uniform vec3 tint : source_color = vec3(0.86, 1.0, 0.92);

// Piega le UV come il vetro di un cinescopio.
vec2 curve_uv(vec2 uv, float amount) {
	uv = uv * 2.0 - 1.0;
	vec2 offset = abs(uv.yx) / amount;
	uv += uv * offset * offset;
	return uv * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = curve_uv(UV, curvature);

	// Fuori dal vetro curvato: nero. Branchless, niente discard.
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
