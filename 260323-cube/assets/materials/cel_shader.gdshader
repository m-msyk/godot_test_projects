shader_type spatial;

// Color and texture
uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D texture_albedo : source_color, filter_nearest;

// Cel shading settings
uniform float shading_steps : hint_range(2, 8) = 3.0;
uniform float shadow_softness : hint_range(0.0, 0.5) = 0.05;
uniform float ambient_light : hint_range(0.0, 1.0) = 0.3;

// Rim light
uniform float rim_strength : hint_range(0.0, 1.0) = 0.0;
uniform float rim_sharpness : hint_range(1.0, 8.0) = 3.0;

void fragment() {
    vec4 tex = texture(texture_albedo, UV);
    ALBEDO = albedo.rgb * tex.rgb;
}

void light() {
    // Diffuse cel shading
    float NdotL = dot(NORMAL, LIGHT);
    float stepped_light = floor((NdotL + shadow_softness) * shading_steps) / shading_steps;
    stepped_light = max(stepped_light, ambient_light);
    DIFFUSE_LIGHT += stepped_light * ALBEDO * ATTENUATION * LIGHT_COLOR;

    // Rim light
    float rim = 1.0 - clamp(dot(VIEW, NORMAL), 0.0, 1.0);
    rim = pow(rim, rim_sharpness);
    rim = step(0.5, rim) * rim_strength;
    SPECULAR_LIGHT += rim * LIGHT_COLOR * ATTENUATION;
}