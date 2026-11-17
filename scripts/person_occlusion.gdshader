shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D avatar_texture : source_color, repeat_disable, filter_nearest;
uniform vec4 occluded_color : source_color = vec4(0.973, 0.733, 0.38, 1.0);

void vertex() {
	// Match the camera-facing Sprite3D quad, including its atlas region and offset.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]
	);
}

void fragment() {
	float foreground = texture(scene_depth, SCREEN_UV).r;
	float mask = texture(avatar_texture, UV).a;
	// In reverse Z the wall is closer than the sprite only where its depth is greater.
	if (mask < 0.5 || foreground - FRAGCOORD.z < 0.00004) {
		discard;
	}
	ALBEDO = occluded_color.rgb;
	ALPHA = 0.88;
}
