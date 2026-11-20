shader_type canvas_item;
// Screen-space sky: very dark green at the top fading into a sickly pale
// green-grey glow at the horizon, with slow drifting mist and a soft vignette.
// Colours are set from Palette by sky.gd.

uniform vec4 top_color : source_color = vec4(0.05, 0.085, 0.06, 1.0);
uniform vec4 glow_color : source_color = vec4(0.70, 0.74, 0.64, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.09, 0.13, 0.095, 1.0);
uniform float glow_height : hint_range(0.0, 1.0) = 0.6;
uniform float mist_amount : hint_range(0.0, 1.0) = 0.12;
uniform float scroll = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	vec3 col;
	if (uv.y < glow_height) {
		float t = uv.y / glow_height;
		col = mix(top_color.rgb, glow_color.rgb, pow(t, 1.8));
	} else {
		float t = (uv.y - glow_height) / (1.0 - glow_height);
		col = mix(glow_color.rgb, bottom_color.rgb, smoothstep(0.0, 1.0, t));
	}
	// Mist bands drifting slowly, strongest around the horizon.
	float band = exp(-pow((uv.y - glow_height) * 3.2, 2.0));
	float mist = fbm(vec2(uv.x * 3.0 + TIME * 0.015 + scroll, uv.y * 7.0 - TIME * 0.01));
	col = mix(col, glow_color.rgb, mist * mist_amount * (0.4 + band));
	// Darken the far corners.
	vec2 d = (uv - vec2(0.5, glow_height)) * vec2(1.0, 1.25);
	col *= 1.0 - 0.45 * smoothstep(0.35, 1.0, length(d));
	COLOR = vec4(col, 1.0);
}
