shader_type canvas_item;
render_mode unshaded;

uniform sampler2D scene_color : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec2 viewport_size = 1.0 / SCREEN_PIXEL_SIZE;
	float pixel_size = max(2.0, floor(viewport_size.y / 420.0 + 0.5));
	vec2 pixel_center = (floor(FRAGCOORD.xy / pixel_size) + 0.5) * pixel_size;
	vec3 color = texture(scene_color, pixel_center * SCREEN_PIXEL_SIZE).rgb;
	COLOR = vec4(floor(color * 47.0 + 0.5) / 47.0, 1.0);
}
