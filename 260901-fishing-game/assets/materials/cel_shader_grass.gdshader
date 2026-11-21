shader_type spatial;

// Cel shader for ground grass. Same ramp lighting as the other cel shaders
// (cel_ramp.gdshaderinc: the Blender colour ramp, hard bands, no blur), plus the
// grass-only effects in cel_grass.gdshaderinc: blotchy band edges and patches of
// the next band (cloud shadows are shared by every ramp shader). Smooth normals on the mesh make the
// blotchy edges work much better.
//
// Used automatically for any Blender material whose name starts with "grass"
// (see cel_shader_import.gd). Inspired by Dylearn's pixel-art grass demo (MIT).

#include "res://assets/materials/cel_ramp.gdshaderinc"
#include "res://assets/materials/cel_reveal.gdshaderinc"
#include "res://assets/materials/cel_grass.gdshaderinc"

void vertex() {
	cel_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// see-through hole when the player is hidden behind this surface
	if (cel_reveal_cut(cel_world_pos, CAMERA_POSITION_WORLD)) {
		discard;
	}
	// the darkest ramp colour is always present; lights add the steps above it
	ALBEDO = vec3(RAMP_ALBEDO);
	EMISSION = cel_ramp_color(0.0);
}

void light() {
	float NdotL = dot(NORMAL, LIGHT);
	float lit = clamp(NdotL, 0.0, 1.0) * ATTENUATION;

	// the effects belong to the sun only; other lights stay plain
	if (LIGHT_IS_DIRECTIONAL) {
		lit = grass_lit(lit, cel_world_pos, 0.0);
		lit = cel_cloud_lit(lit, cel_world_pos, TIME);
	}

	DIFFUSE_LIGHT += (cel_ramp_color(lit) - cel_ramp_color(0.0)) / RAMP_ALBEDO;
}
