shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

group_uniforms Ground;
uniform float ground_strenght = 3.0;
uniform vec2 ground_scale = vec2(10.0, 10.0);
uniform float ground_normal_map_strenght = 1.0;
uniform sampler2D ground_normal_map : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D ground_albedo : source_color, filter_linear_mipmap_anisotropic;
group_uniforms;

group_uniforms Walls;
uniform float wall_strenght = 2.0;
uniform vec2 wall_scale = vec2(10.0, 10.0);
uniform float wall_normal_map_strenght = 1.0;
uniform sampler2D wall_normal_map : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D wall_albedo : source_color, filter_linear_mipmap_anisotropic;
group_uniforms;

varying float flatness;
varying vec2 wall_pos;
varying vec2 ground_pos;

void vertex() {
	flatness = dot(NORMAL, vec3(0.0, 1.0, 0.0));
	ground_pos = ground_scale * UV;
	wall_pos = wall_scale * UV;
}

void fragment() {
	float ground_blend = clamp((flatness * ground_strenght ) - wall_strenght , 0.0, 1.0);
	float wall_blend = 1.0 - ground_blend;
	
	// Albedo color
	vec3 ground_color = texture(ground_albedo, ground_pos).rgb * ground_blend;
	vec3 wall_color = texture(wall_albedo, wall_pos).rgb * wall_blend;
	ALBEDO = ground_color + wall_color;
	
	// Normal Map
	vec3 ground_normal = texture(ground_normal_map, ground_pos).rgb * ground_blend * ground_normal_map_strenght;
	vec3 wall_normal = texture(wall_normal_map, wall_pos).rgb * wall_blend * wall_normal_map_strenght;
	NORMAL_MAP = ground_normal + wall_normal;
}
