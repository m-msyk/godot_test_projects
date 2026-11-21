// Grass lighting effects shared by the ground (cel_shader_grass) and the
// scattered tufts (grass_tuft), so a tuft always matches the ground under it.
// Include cel_ramp.gdshaderinc first.
//
// Both effects just push the lighting value around BEFORE the ramp lookup,
// so every colour is still one of the ramp's own colours and every edge is a
// hard step:
//  1. Organic edges: world-space noise wobbles band edges into blotches.
//  2. Patches: slow noise lifts some areas to the next-brighter band.
// (Cloud shadows are shared by every ramp surface now, see cel_ramp.gdshaderinc.)

group_uniforms organic_edges;
uniform float wobble_amount : hint_range(0.0, 0.5) = 0.1; // how far edges wander (0 = polygon edges)
uniform float wobble_scale : hint_range(0.01, 4.0) = 0.2; // noise cycles per metre; blotch ~ 1/scale metres

group_uniforms patches;
uniform float patch_shift : hint_range(-1.0, 1.0) = 0.3; // + brighter band, - darker band (0 = off)
uniform float patch_scale : hint_range(0.005, 1.0) = 0.07; // cycles per metre
uniform float patch_threshold : hint_range(0.0, 1.0) = 0.58; // higher = fewer, smaller patches
group_uniforms;

// The sun's lighting value for a point on the ground (world position p).
// extra_shift lets tufts sit a band above/below the ground they stand on.
float grass_lit(float lit, vec3 p, float extra_shift) {
	// 1. organic edges
	lit += (cel_fbm(p * wobble_scale) - 0.5) * 2.0 * wobble_amount;

	// 2. patches of the next band
	float patch = step(patch_threshold, cel_noise(vec3(p.x * patch_scale, 7.0, p.z * patch_scale)));
	lit += patch * patch_shift + extra_shift;
	return clamp(lit, 0.0, 1.0);
}