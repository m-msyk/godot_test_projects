shader_type spatial;

#include "res://assets/materials/cel_ramp.gdshaderinc"

uniform sampler2D wave_normal_map;
uniform sampler2D light_pattern;
uniform vec2 wave_speed_1 = vec2(0.02, 0.01);
uniform vec2 wave_speed_2 = vec2(-0.015, 0.02);
uniform float wave_scale = 4.0;
uniform float distortion_strength = 0.05;
uniform vec4 water_color : source_color = vec4(0.2, 0.4, 0.8, 1.0);
uniform vec4 light_color : source_color = vec4(1.0, 1.0, 0.9, 1.0);
uniform float light_pattern_scale = 1.0;
uniform vec2 light_pattern_offset = vec2(0.0, 0.0);
uniform float light_pattern_rotation : hint_range(0.0, 360.0) = 0.0;
uniform bool flip_horizontal = false;
uniform float light_threshold : hint_range(0.0, 1.0) = 0.5;
uniform bool light_pattern_enabled = true; // the lobby's reflection of the ceiling lights; off for outdoor water
uniform bool light_always_on = false; // the whole surface takes the lit tone, no light/dark split

// World-space mode (used by water imported from Blender, see cel_shader_import.gd).
// The default (off) takes waves and the light pattern from the mesh UVs and the ripples
// from the mesh's local coordinates, which is how the lobby pool is tuned. That breaks on
// meshes without a proper UV map, and ripple sizes change with the mesh's scale. In
// world-space mode everything is measured in metres instead, the colour is a flat
// emissive water_color (not tinted by ambient light or washed out by the sun), and cloud
// shadows from a CloudShadows node darken it.
uniform bool world_space = false;
uniform float world_uv_per_metre = 0.05; // pattern repeats once per 1 / this many metres
uniform float cloud_darkness : hint_range(0.0, 1.0) = 0.35; // how much a cloud shadow darkens the water

// footstep ripples
const int MAX_RIPPLES = 8;
uniform vec2 ripple_origins[MAX_RIPPLES];
uniform float ripple_start_times[MAX_RIPPLES];
uniform float game_time = 0.0; // clock driven from script (WaterRippleComponent), kept separate from built-in TIME so footstep timestamps stay in sync
uniform float ripple_duration = 2.8; // seconds a ripple stays visible before fully fading out
uniform float ripple_wavelength = 1.6; // distance in local units between successive ripple peaks; bigger = peaks further apart
uniform float ripple_speed = 6; // how fast the rings expand outward from the footstep
uniform float ripple_falloff = 1.0; // how quickly the ripple weakens with distance; lower = ripple reaches farther
uniform float ripple_strength = 0.08; // how much the ripple distorts the light pattern's UVs; keep modest so it layers on top of ambient wave distortion rather than overwhelming it
uniform float ripple_glow_strength = 0.15; // separate subtle glow from the ripple itself, visible even far from any light pattern edge
uniform float ripple_glow_threshold : hint_range(0.0, 1.0) = 0.3; // ripple glow snaps on above this value instead of fading smoothly, matching the toon banding
uniform float ripple_noise_strength = 0.7; // bends the ripple rings away from a perfect circle so they read as more natural/organic
uniform float ripple_echo_delay = 0.3; // seconds after the main ripple before the weaker echo ripple appears
uniform float ripple_echo_strength = 0.5; // echo amplitude as a fraction of the main ripple's strength (0-1)

varying vec2 local_xz;
varying vec2 world_xz;

void vertex() {
	local_xz = VERTEX.xz;
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 base_uv = UV;
	if (world_space) {
		base_uv = world_xz * world_uv_per_metre;
	} else if (flip_horizontal) {
		base_uv.x = 1.0 - base_uv.x;
	}
	// where footstep ripples are measured: local units (lobby) or world metres
	vec2 ripple_xz = world_space ? world_xz : local_xz;

	vec2 uv1 = base_uv * wave_scale + TIME * wave_speed_1;
	vec2 uv2 = base_uv * wave_scale + TIME * wave_speed_2;
	vec3 n1 = texture(wave_normal_map, uv1).rgb * 2.0 - 1.0;
	vec3 n2 = texture(wave_normal_map, uv2).rgb * 2.0 - 1.0;
	vec3 blended_normal = normalize(n1 + n2);

	// accumulate footstep ripples
	float ripple_freq = 6.2831853 / max(ripple_wavelength, 0.01); // convert wavelength to angular frequency
	vec2 ripple_offset = vec2(0.0);
	float ripple_light = 0.0;
	for (int i = 0; i < MAX_RIPPLES; i++) {
		float age = game_time - ripple_start_times[i];
		if (age < 0.0 || age > ripple_duration) {
			continue;
		}
		// bend this ripple's sampling position away from a perfect circle
		vec2 noise_uv = ripple_xz * 0.15 + ripple_origins[i] * 0.05;
		vec2 warp = (texture(wave_normal_map, noise_uv).rg - vec2(0.5)) * ripple_noise_strength;
		vec2 warped_xz = ripple_xz + warp;

		float d = distance(warped_xz, ripple_origins[i]);
		float ring = sin(d * ripple_freq - age * ripple_speed);
		float time_fade = 1.0 - (age / ripple_duration);
		float spatial_falloff = exp(-d * ripple_falloff);
		float amp = ring * spatial_falloff * time_fade;
		vec2 dir = normalize(warped_xz - ripple_origins[i] + vec2(0.0001));
		ripple_offset += dir * amp * ripple_strength;
		ripple_light += max(amp, 0.0);

		// weaker echo ripple, same origin, offset later in time
		float echo_age = age - ripple_echo_delay;
		if (echo_age >= 0.0 && echo_age <= ripple_duration) {
			float echo_ring = sin(d * ripple_freq - echo_age * ripple_speed);
			float echo_time_fade = 1.0 - (echo_age / ripple_duration);
			float echo_amp = echo_ring * spatial_falloff * echo_time_fade * ripple_echo_strength;
			ripple_offset += dir * echo_amp * ripple_strength;
			ripple_light += max(echo_amp, 0.0);
		}
	}

	vec2 centered_uv = base_uv - vec2(0.5);
	float rad = radians(light_pattern_rotation);
	float s = sin(rad);
	float c = cos(rad);
	vec2 rotated_uv = vec2(
		centered_uv.x * c - centered_uv.y * s,
		centered_uv.x * s + centered_uv.y * c
	) + vec2(0.5);

	vec2 pattern_uv = rotated_uv * light_pattern_scale + light_pattern_offset;
	vec2 distorted_uv = pattern_uv + blended_normal.xy * distortion_strength + ripple_offset;
	float light_mask = 1.0 - texture(light_pattern, distorted_uv).a;

	// hard 2-step cutoff, no gradient
	float lit = light_always_on ? 1.0 : (light_pattern_enabled ? step(light_threshold, light_mask) : 0.0);
	float ripple_lit = step(ripple_glow_threshold, ripple_light);

	vec3 light_emission = light_color.rgb * lit + light_color.rgb * ripple_lit * ripple_glow_strength;
	if (world_space) {
		// flat colour straight from Blender: nothing but emission, so the sun and ambient
		// light can't wash it out or tint it
		float sun = cel_cloud_lit(1.0, vec3(world_xz.x, 0.0, world_xz.y), TIME); // 1 clear .. 0 cloud
		float shade = mix(1.0 - cloud_darkness, 1.0, sun);
		ALBEDO = vec3(0.0);
		SPECULAR = 0.0;
		ROUGHNESS = 1.0;
		EMISSION = water_color.rgb * shade + light_emission * sun;
	} else {
		ALBEDO = water_color.rgb;
		EMISSION = light_emission;
	}
}
