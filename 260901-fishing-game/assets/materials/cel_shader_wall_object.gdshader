shader_type spatial;
render_mode cull_disabled;

#include "res://assets/materials/cel_ramp.gdshaderinc"
#include "res://assets/materials/cel_reveal.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D texture_albedo : source_color, filter_nearest;
uniform bool use_texture = false;
uniform float shading_steps : hint_range(2, 8) = 2.0;
uniform float shadow_softness : hint_range(0.0, 0.5) = 0.0;
uniform float ambient_light : hint_range(0.0, 1.0) = 0.3;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.0;
uniform float rim_sharpness : hint_range(1.0, 8.0) = 3.0;

// World-space direction pointing away from the wall. Fallback for objects
// without a baked direction; wall_object.gd sets it per scene.
uniform vec3 wall_normal = vec3(0.0, 0.0, 1.0);
// Each piece of wall-object geometry carries its own outward direction in its
// vertex colour (see wall_object_baker.gd), so many objects on differently-
// facing walls can share one mesh. A baked colour has alpha 0.5; the default
// vertex colour (alpha 1) means "not baked".
// The object hides when the camera is behind its wall plane. 0.0 matches where
// the wall itself (back-face culled) disappears; negative lets it linger.
uniform float hide_threshold : hint_range(-1.0, 1.0) = 0.0;

varying vec3 world_pos;
varying vec3 world_wall_normal;

void vertex() {
	cel_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (COLOR.a > 0.25 && COLOR.a < 0.75) {
		world_wall_normal = normalize((MODEL_MATRIX * vec4(COLOR.rgb * 2.0 - 1.0, 0.0)).xyz);
	} else {
		world_wall_normal = normalize(wall_normal);
	}
}

void fragment() {
	// see-through hole when the player is hidden behind this surface
	if (cel_reveal_cut(cel_world_pos, CAMERA_POSITION_WORLD)) {
		discard;
	}
	// discard the object while the camera is behind the wall it's mounted on
	vec3 to_camera = normalize(CAMERA_POSITION_WORLD - world_pos);
	if (dot(to_camera, world_wall_normal) < hide_threshold) {
		discard;
	}
	if (ramp_count > 0) {
		// the darkest ramp colour is always present; lights add the steps above it
		ALBEDO = vec3(RAMP_ALBEDO);
		EMISSION = cel_ramp_color(0.0);
	} else {
		vec3 base_color = albedo.rgb;
		if (use_texture) {
			base_color *= texture(texture_albedo, UV).rgb;
		}
		ALBEDO = base_color;
	}
}

void light() {
	float NdotL = dot(NORMAL, LIGHT);
	if (ramp_count > 0) {
		float lit = clamp(NdotL, 0.0, 1.0) * ATTENUATION;
		if (LIGHT_IS_DIRECTIONAL) {
			lit = cel_cloud_lit(lit, cel_world_pos, TIME);
		}
		DIFFUSE_LIGHT += (cel_ramp_color(lit) - cel_ramp_color(0.0)) / RAMP_ALBEDO;
	} else {
		float stepped_light = floor((NdotL + shadow_softness) * shading_steps) / shading_steps;
		stepped_light = max(stepped_light, ambient_light);
		DIFFUSE_LIGHT += stepped_light * ALBEDO * ATTENUATION * LIGHT_COLOR;
	}

	float rim = 1.0 - clamp(dot(VIEW, NORMAL), 0.0, 1.0);
	rim = pow(rim, rim_sharpness);
	rim = step(0.5, rim) * rim_strength;
	SPECULAR_LIGHT += rim * LIGHT_COLOR * ATTENUATION;
}
