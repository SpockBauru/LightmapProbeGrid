shader_type spatial;
render_mode cull_disabled;

group_uniforms Ground;
uniform float ground_strenght = 3.0;
uniform vec2 ground_scale = vec2(0.01, 0.01);
uniform sampler2D ground_albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D ground_normal_map : hint_normal, filter_linear_mipmap_anisotropic;
uniform float ground_normal_map_strenght = 1.0;
group_uniforms;

group_uniforms Walls;
uniform float wall_strenght = 2.0;
uniform vec2 wall_scale = vec2(0.01, 0.01);
uniform sampler2D wall_albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D wall_normal_map : hint_normal, filter_linear_mipmap_anisotropic;
uniform float wall_normal_map_strenght = 1.0;
group_uniforms;

varying float flatness;
varying vec3 pos_vertex;
varying vec3 pos_normal;

void vertex() {
	flatness = dot(NORMAL, vec3(0.0, 1.0, 0.0));
	
	// Triplanar map from mohsen zare youtube: https://www.youtube.com/watch?v=YwnVl2YHXBc
	pos_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	pos_normal = abs(normalize(MODEL_NORMAL_MATRIX * NORMAL));
}

void fragment() {
	// Blend between the two textures
	float ground_blend = clamp((flatness * ground_strenght ) - wall_strenght , 0.0, 1.0);
	float wall_blend = 1.0 - ground_blend;
	
	// Triplanar position
	vec2 uv = mix(pos_vertex.xy, pos_vertex.zy, round(pos_normal.x));
	uv = mix(uv, pos_vertex.xz, round(pos_normal.y));
	
	// Albedo color
	vec3 ground_color = texture(ground_albedo, uv * ground_scale).rgb * ground_blend;
	vec3 wall_color = texture(wall_albedo, uv * wall_scale).rgb * wall_blend;
	ALBEDO = ground_color + wall_color;
	
	// Normal Map
	vec3 ground_normal = texture(ground_normal_map, uv * ground_scale).rgb * ground_blend;
	ground_normal *= ground_normal_map_strenght;
	vec3 wall_normal = texture(wall_normal_map, uv * wall_scale).rgb * wall_blend;
	wall_normal *= wall_normal_map_strenght;
	NORMAL_MAP = ground_normal + wall_normal;
}
