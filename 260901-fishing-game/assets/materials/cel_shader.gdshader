shader_type spatial;

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

void vertex() {
	cel_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// see-through hole when the player is hidden behind this surface
	if (cel_reveal_cut(cel_world_pos, CAMERA_POSITION_WORLD)) {
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
