shader_type spatial;

// Color and texture
uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D texture_albedo : source_color, filter_nearest;

// Cel shading settings
uniform float shading_steps : hint_range(2, 8) = 3.0;
uniform float shadow_softness : hint_range(0.0, 0.5) = 0.05;
uniform float ambient_light : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec4 tex = texture(texture_albedo, UV);
    ALBEDO = albedo.rgb * tex.rgb;
}

void light() {
    // Calculate how much light hits the surface
    float NdotL = dot(NORMAL, LIGHT);
    
    // Quantize (step) the lighting into discrete bands
    float stepped_light = floor((NdotL + shadow_softness) * shading_steps) / shading_steps;
    
    // Clamp to minimum ambient lighting
    stepped_light = max(stepped_light, ambient_light);
    
    // Apply the cel-shaded lighting
    DIFFUSE_LIGHT += stepped_light * ALBEDO * ATTENUATION * LIGHT_COLOR;
}