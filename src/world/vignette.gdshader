shader_type canvas_item;
// Full-screen darkness creeping in from the edges. hidden_amount (0..1) tightens
// it while the girl is hidden, so hiding feels claustrophobic and safe at once.

uniform vec4 tint : source_color = vec4(0.0, 0.015, 0.005, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.6;
uniform float hidden_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 p = (UV - vec2(0.5, 0.55)) * vec2(1.7, 1.0);
	float d = length(p);
	float inner = mix(0.45, 0.2, hidden_amount);
	float alpha = smoothstep(inner, 1.05, d) * mix(strength, 0.97, hidden_amount);
	COLOR = vec4(tint.rgb, alpha);
}
