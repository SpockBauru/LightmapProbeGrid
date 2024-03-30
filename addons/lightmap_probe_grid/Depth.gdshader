shader_type spatial;
render_mode unshaded;

uniform sampler2D depth_texture : source_color, hint_depth_texture, filter_nearest, repeat_disable;

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;
	ALBEDO = vec3(depth);
}
