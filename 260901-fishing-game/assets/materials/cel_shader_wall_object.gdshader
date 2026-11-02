shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D texture_albedo : source_color, filter_nearest;
uniform bool use_texture = false;
uniform float shading_steps : hint_range(2, 8) = 2.0;
uniform float shadow_softness : hint_range(0.0, 0.5) = 0.0;
uniform float ambient_light : hint_range(0.0, 1.0) = 0.3;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.0;
uniform float rim_sharpness : hint_range(1.0, 8.0) = 3.0;
uniform vec3 wall_normal = vec3(0.0, 0.0, 1.0); // set this to face away from the wall

void fragment() {
	// if camera is behind the wall plane, discard the whole object
	if (dot(VIEW, (INV_VIEW_MATRIX * vec4(wall_normal, 0.0)).xyz) < -0.3) {
		discard;
	}
	vec3 base_color = albedo.rgb;
	if (use_texture) {
		base_color *= texture(texture_albedo, UV).rgb;
	}
	ALBEDO = base_color;
}

void light() {
	float NdotL = dot(NORMAL, LIGHT);
	float stepped_light = floor((NdotL + shadow_softness) * shading_steps) / shading_steps;
	stepped_light = max(stepped_light, ambient_light);
	DIFFUSE_LIGHT += stepped_light * ALBEDO * ATTENUATION * LIGHT_COLOR;

	float rim = 1.0 - clamp(dot(VIEW, NORMAL), 0.0, 1.0);
	rim = pow(rim, rim_sharpness);
	rim = step(0.5, rim) * rim_strength;
	SPECULAR_LIGHT += rim * LIGHT_COLOR * ATTENUATION;
}