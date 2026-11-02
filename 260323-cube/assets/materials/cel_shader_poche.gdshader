shader_type spatial;
render_mode unshaded;

uniform vec4 poche_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);

void fragment() {
    ALBEDO = poche_color.rgb;
}