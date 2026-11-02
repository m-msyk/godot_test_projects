shader_type canvas_item;

// When silhouette is true, flat-fills every opaque texel with a single
// solid color (preserving only the shape's alpha) instead of the texture's
// own colors/shading, so undiscovered fish stay a true mystery.
uniform bool silhouette = false;
uniform vec4 fill_color : source_color = vec4(0.15, 0.15, 0.15, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	if (silhouette) {
		COLOR = vec4(fill_color.rgb, tex_color.a * fill_color.a);
	} else {
		COLOR = tex_color;
	}
}
