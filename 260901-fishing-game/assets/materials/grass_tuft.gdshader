shader_type spatial;
render_mode cull_disabled;

// One grass tuft: a camera-facing quad (spins around the vertical axis only, so
// it stays upright) with three blades drawn procedurally, so no texture is
// needed. Rendered by grass_scatter.gd as MultiMesh chunks.
//
// Colour comes from the ground's own ramp: grass_scatter.gd copies the ramp and
// effect settings from the grass material, and each tuft sits a band above or
// below the ground beneath it so it reads against the ground.

#include "res://assets/materials/cel_ramp.gdshaderinc"
#include "res://assets/materials/cel_grass.gdshaderinc"

group_uniforms tuft;
uniform float shift_up : hint_range(0.0, 1.0) = 0.35; // lighter tufts: bands above the ground
uniform float shift_down : hint_range(0.0, 1.0) = 0.35; // darker tufts: bands below the ground
uniform float darker_chance : hint_range(0.0, 1.0) = 0.5; // share of tufts that are the darker kind

group_uniforms wind;
uniform float sway_amount : hint_range(0.0, 1.0) = 0.18; // tip sway, as a fraction of tuft height
uniform float sway_speed : hint_range(0.0, 10.0) = 2.2;
uniform float sway_fps : hint_range(1.0, 60.0) = 8.0; // stepped, slightly choppy sway
uniform vec2 wind_direction = vec2(1.0, 0.4);

// flat = not interpolated across the quad. Interpolating a constant leaves ~1e-5 of
// rounding noise, and feeding that to a hash flips the result pixel by pixel.
varying flat vec3 tuft_origin;
varying flat float tuft_shift; // band shift for this tuft: lighter or darker than the ground

// One blade of grass: narrow where it leaves the ground, thickest about 40% of the
// way up, then tapering to a point at the tip. It curves sideways as it rises
// (lean = how far the tip drifts, in quad widths).
float blade(vec2 uv, float centre, float height, float half_width, float lean) {
	float t = uv.y / height; // 0 at the base, 1 at the tip
	if (t < 0.0 || t > 1.0) {
		return 0.0;
	}
	float x = uv.x - centre - lean * t * t;
	float w = t < 0.4
			? mix(0.22, 1.0, smoothstep(0.0, 0.4, t)) // small at the ground, swelling out
			: (1.0 - t) / 0.6; // then a straight taper to the tip
	return abs(x) < half_width * w ? 1.0 : 0.0;
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float s = length(MODEL_MATRIX[0].xyz);
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 to_cam = vec3(cam.x - origin.x, 0.0, cam.z - origin.z);
	to_cam = normalize(to_cam + vec3(0.0, 0.0, 0.0001));
	vec3 right = cross(vec3(0.0, 1.0, 0.0), to_cam);

	// stepped sway of the tip, along the wind direction as seen across the quad
	float t = floor(TIME * sway_fps) / sway_fps;
	float sway = sin(t * sway_speed + origin.x * 0.35 + origin.z * 0.23);
	vec2 wind = normalize(wind_direction + vec2(0.0001));
	VERTEX.x += dot(vec3(wind.x, 0.0, wind.y), right) * sway * sway_amount * VERTEX.y * VERTEX.y;

	// Overlapping tufts are flat quads at nearly the same depth, which z-fights
	// (speckled blades). Nudging each one a random bit toward the camera ends the tie.
	vec3 base = origin + normalize(cam - origin) * cel_hash(origin * 1.31) * 0.25 * s;

	// upright billboard: x along the quad's right, y straight up, scaled by the instance
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(right * s, 0.0),
			vec4(0.0, s, 0.0, 0.0),
			vec4(to_cam * s, 0.0),
			vec4(base, 1.0));
	tuft_origin = origin;
	tuft_shift = (cel_hash(origin * 3.7) < darker_chance) ? -shift_down : shift_up;
}
void fragment() {
	vec2 uv = vec2(UV.x, 1.0 - UV.y); // y = 0 at the base, 1 at the top
	// three blades growing from nearly the same spot, so the base reads as one clump;
	// only the tips fan out, each curving away from the middle one
	float a = blade(uv, 0.42, 0.74, 0.085, -0.12);
	a = max(a, blade(uv, 0.50, 1.00, 0.090, 0.03));
	a = max(a, blade(uv, 0.58, 0.82, 0.085, 0.14));
	if (a < 0.5) {
		discard;
	}
	// always light the tuft as if it faced up (like the ground), not toward the camera
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ALBEDO = vec3(RAMP_ALBEDO);
	EMISSION = cel_ramp_color(0.0);
}

void light() {
	// the shadow map's soft edge is stochastic; against the hard ramp bands it would
	// speckle the tuft, so shadow is simply on or off here
	float lit = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * step(0.5, ATTENUATION);
	if (LIGHT_IS_DIRECTIONAL) {
		lit = grass_lit(lit, tuft_origin, tuft_shift);
		lit = cel_cloud_lit(lit, tuft_origin, TIME);
	}
	DIFFUSE_LIGHT += (cel_ramp_color(lit) - cel_ramp_color(0.0)) / RAMP_ALBEDO;
}
