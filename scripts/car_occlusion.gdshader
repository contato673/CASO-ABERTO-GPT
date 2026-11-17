shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec4 occluded_color : source_color = vec4(1.0, 0.69, 0.26, 1.0);

void fragment() {
	// Godot 4.7 uses reverse Z. Greater depth is closer to the camera.\n\t// Ignore subpixel depth differences. The proxy is above the car roof.
	float foreground = texture(scene_depth, SCREEN_UV).r;
	if (foreground - FRAGCOORD.z < 0.00042) {
		discard;
	}
	ALBEDO = occluded_color.rgb;
	ALPHA = 0.84;
}
