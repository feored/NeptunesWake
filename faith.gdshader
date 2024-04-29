shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1);
uniform float max_line_thickness = 6;


void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * sin(TIME) * max_line_thickness;
	
	float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
	outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
	outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
	outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
	outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
	outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
	outline = min(outline, 1.0);
	
	vec4 color = texture(TEXTURE, UV);
	vec4 final_line_color = line_color;
	final_line_color.a = sin( 0.4974 + TIME * 2.0);
	COLOR = mix(color, final_line_color, outline - color.a);
}