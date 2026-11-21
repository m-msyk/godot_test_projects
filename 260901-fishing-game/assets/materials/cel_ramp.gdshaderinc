// Colour-ramp lighting shared by the cel shaders.
//
// A material imported from Blender with a Color Ramp (see tools/blender_cel_props.py
// and cel_shader_import.gd) carries the ramp itself, so shadows can change hue
// (a red that goes purple in shade) instead of just getting darker. Blender's
// Shader to RGB -> Color Ramp becomes: ramp factor = N.L * shadow, colour = the
// ramp's colour at that factor.
//
// ramp_count == 0 means "no ramp": the shaders fall back to plain stepped dimming.
// Ramp colours are linear and used as-is, so light colour/energy do not tint them.
// With several lights, each one adds its step above the darkest colour, so
// overlapping lights can overshoot the brightest stop.
//
// Also here: world-space noise helpers and the drifting cloud shadows, which every
// ramp-lit surface (ground, roads, buildings, ...) shares so the shadows line up.

// Godot multiplies the light() output by ALBEDO, and ambient light is scaled by it too.
// Ramp materials keep ALBEDO tiny (so ambient adds ~nothing) and divide it back out.
const float RAMP_ALBEDO = 0.001;

uniform int ramp_count = 0;
uniform bool ramp_linear = false; // false = Constant interpolation, true = Linear
uniform vec4 ramp_data[8]; // rgb = linear colour, a = stop position (0..1), sorted

vec3 cel_ramp_color(float f) {
	vec3 c = ramp_data[0].rgb;
	for (int i = 1; i < 8; i++) {
		if (i >= ramp_count) {
			break;
		}
		vec4 prev = ramp_data[i - 1];
		vec4 cur = ramp_data[i];
		if (f >= cur.a) {
			c = cur.rgb;
		} else {
			if (ramp_linear && f > prev.a) {
				c = mix(prev.rgb, cur.rgb, (f - prev.a) / max(cur.a - prev.a, 0.00001));
			}
			break;
		}
	}
	return c;
}

// --- Noise helpers (world space) ---------------------------------------------
float cel_hash(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float cel_noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = cel_hash(i);
	float n100 = cel_hash(i + vec3(1.0, 0.0, 0.0));
	float n010 = cel_hash(i + vec3(0.0, 1.0, 0.0));
	float n110 = cel_hash(i + vec3(1.0, 1.0, 0.0));
	float n001 = cel_hash(i + vec3(0.0, 0.0, 1.0));
	float n101 = cel_hash(i + vec3(1.0, 0.0, 1.0));
	float n011 = cel_hash(i + vec3(0.0, 1.0, 1.0));
	float n111 = cel_hash(i + vec3(1.0, 1.0, 1.0));
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
			mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}

// two octaves, a little detail on top of the big shapes
float cel_fbm(vec3 p) {
	return cel_noise(p) * 0.8 + cel_noise(p * 2.7 + 17.0) * 0.2;
}

// --- Cloud shadows -------------------------------------------------------------
// Blobs of noise drift across the world and drop whatever they cover to the ramp's
// darkest colour (a hard edge, like the rest of the cel look). Applied to the sun
// only. Surfaces whose ramp has a single colour have no shadow colour to drop to,
// so they don't change; give them a second, darker stop in Blender if you want it.
//
// These are GLOBAL shader parameters (Project Settings > Shader Globals). They sit at
// strength 0 = no clouds everywhere, until a CloudShadows node (world/cloud_shadows.gd)
// is in the scene: put one in outdoor scenes, leave it out of interiors.
global uniform float cel_cloud_strength;
global uniform float cel_cloud_scale; // cycles per metre; cloud ~ 1 / scale metres
global uniform float cel_cloud_threshold; // higher = less cover
global uniform vec2 cel_cloud_speed; // metres per second (world x, z)
// each shader's vertex() sets this: cel_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
varying vec3 cel_world_pos;

float cel_cloud_lit(float lit, vec3 p, float time) {
	vec3 cp = vec3(p.x + time * cel_cloud_speed.x, 3.0, p.z + time * cel_cloud_speed.y) * cel_cloud_scale;
	float cloud = step(cel_cloud_threshold, cel_fbm(cp));
	return lit * (1.0 - cel_cloud_strength * cloud);
}