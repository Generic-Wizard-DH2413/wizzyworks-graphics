shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_back, blend_add; // additive = punchy sparks

uniform sampler2D albedo_tex : source_color; // your soft round sprite
uniform vec4 tint : source_color = vec4(1.0);
uniform float emission_boost = 1.0;

//void vertex() {
	// Called for every vertex the material is visible on.
//}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 tex = texture(albedo_tex, UV);

    // Particle COLOR.rgb was set in the process shader (brightness over lifetime). Will fade
    // Drive EMISSION so the Glow pass can bloom it.
    vec3 base = tex.rgb * tint.rgb;
    EMISSION = base * COLOR.rgb * emission_boost;

    // ALBEDO is traditionally color of material
    ALBEDO =  base * COLOR.rgb * emission_boost;
	//ALBEDO = vec3(0.);
    //ALBEDO   =0.1  * base;   // tiny albedo to “carry” alpha

	// Fade with both texture alpha and particle alpha.
    ALPHA = tex.a * COLOR.a;
	//ALPHA = COLOR.a;
}


//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
