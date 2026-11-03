shader_type canvas_item;
// Recolours green pixels (grass, bushes, leaves) for the season. Other
// colours (dirt, water, wood, roofs) are left alone. See season_look.gd.

// Colour that green pixels take on, times their brightness (lets the
// texture's light and shade show through).
uniform vec3 tint = vec3(1.0);
// 0 = unchanged, 1 = fully recoloured.
uniform float amount = 0.0;

void fragment() {
	vec4 c = COLOR;  // already the texture times the modulate colour
	float green = smoothstep(0.02, 0.12, c.g - max(c.r, c.b));
	float brightness = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	c.rgb = mix(c.rgb, clamp(brightness * tint, 0.0, 1.0), amount * green);
	COLOR = c;
}
