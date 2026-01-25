shader_type spatial;
// unshaded: no lighting calc
// cull_disabled: visible from both sides
render_mode unshaded, cull_disabled, depth_draw_opaque;

global uniform sampler2D heightmap : filter_linear, repeat_enable;
global uniform float heightmap_scale;

// glow strength control
uniform float emission_strength : hint_range(1.0, 20.0) = 5.0;
uniform vec3 eye_color : source_color = vec3(1.0, 1.0, 1.0);

varying float blink_val;

void vertex() {
	// --- world position ---
	vec3 world_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	
	// --- heightmap snap ---
	float h = (texture(heightmap, world_pos.xz / vec2(textureSize(heightmap, 0))).x - 0.5) * heightmap_scale;
	world_pos.y = h + 0.5;
	
	// --- billboard (view aligned) ---
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0],
		INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2],
		vec4(world_pos, 1.0)
	);
	
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	
	// --- blink logic ---
	float speed = INSTANCE_CUSTOM.r;
	float offset = INSTANCE_CUSTOM.g;
	float sine_wave = (sin(TIME * speed + offset) + 1.0) * 0.5;
	blink_val = mix(0.1, 1.0, sine_wave);
}

float draw_eye(vec2 uv, vec2 center, float radius) {
	float d = length(uv - center);
	return smoothstep(radius, radius - 0.05, d);
}

void fragment() {
	float left = draw_eye(UV, vec2(0.25, 0.5), 0.07);
	float right = draw_eye(UV, vec2(0.75, 0.5), 0.07);
	float eyes = left + right;
	
	if (eyes < 0.1) discard;

	// multiply color by strength to push rgb > 1.0 for hdr glow
	ALBEDO = eye_color * emission_strength;
	ALPHA = eyes * blink_val;
}