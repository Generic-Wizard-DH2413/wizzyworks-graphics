// NOTE: Shader automatically converted from Godot Engine 4.4.stable's ParticleProcessMaterial.

shader_type particles;
render_mode disable_velocity;

// Could-be-relevant params
uniform float scale_min;
uniform float scale_max;
uniform float hue_variation_min;
uniform float hue_variation_max;
uniform float anim_speed_min;
uniform float anim_speed_max;
uniform float anim_offset_min;
uniform float anim_offset_max;
uniform float lifetime_randomness;
uniform vec3 emission_shape_offset = vec3(0.0);
uniform vec3 emission_shape_scale = vec3(1.0);
uniform vec3 velocity_pivot = vec3(0.0);
uniform vec4 color_value : source_color;
uniform vec3 gravity;
uniform float air_resistance;

// Sphere Params
uniform bool sphere;
uniform float sphere_force;
//fishy Params
uniform float turn_strength=2.0;
uniform float swim_accel=1.0;

// Light Params
// how glow behaves over lifetime
uniform float glow_start = 8.0;        // brightness at birth
uniform float glow_end = 0.0;          // at death
uniform float glow_falloff = 1.6;      // curve exponent (higher = faster fade)
uniform float alpha_falloff= 1.1; //how quick fragments should fade away

// (original) Creates a random value from a given seed
float rand_from_seed(inout uint seed) {
	int k;
	int s = int(seed);
	if (s == 0) {
		s = 305420679;
	}
	k = s / 127773;
	s = 16807 * (s - k * 127773) - 2836 * k;
	if (s < 0) {
		s += 2147483647;
	}
	seed = uint(s);
	return float(seed % uint(65536)) / 65535.0;
}

// (original)
uint hash(uint x) {
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = (x >> uint(16)) ^ x;
	return x;
}

// (original) parameters related to display
struct DisplayParameters {
	vec3 scale;
	float hue_rotation;
	float animation_speed;
	float animation_offset;
	float lifetime;
	vec4 color;
	float emission_texture_position;
};

// parameters related to sphere
struct AngleParameters{
	float theta;
	float phi;
};

void calculate_initial_display_params(inout DisplayParameters params, inout uint alt_seed) {
	// -------------------- DO NOT REORDER OPERATIONS, IT BREAKS VISUAL COMPATIBILITY
	// -------------------- ADD NEW OPERATIONS AT THE BOTTOM
	float pi = 3.14159;
	params.scale = vec3(mix(scale_min, scale_max, rand_from_seed(alt_seed)));
	params.scale = sign(params.scale) * max(abs(params.scale), 0.001);
	params.hue_rotation = pi * 2.0 * mix(hue_variation_min, hue_variation_max, rand_from_seed(alt_seed));
	params.animation_speed = mix(anim_speed_min, anim_speed_max, rand_from_seed(alt_seed));
	params.animation_offset = mix(anim_offset_min, anim_offset_max, rand_from_seed(alt_seed));
	params.lifetime = (1.0 - lifetime_randomness * rand_from_seed(alt_seed));
	params.color = color_value;
}

void process_display_param(inout DisplayParameters parameters, float lifetime) {
	// Compile-time add textures.
	parameters.color = parameters.color;
}


// --------------------  CUSTOM FUNCTIONS ------------------------------

// Calculates a random theta and phi for the particle
void calculate_random_angles(inout AngleParameters params,  uint number,  uint random_seed ){
	// Generate two random seeds
	uint seed1 = hash(number + uint(1) + random_seed);
	uint seed2 = hash(number + uint(1) + random_seed + uint(0x9E3779B9));

		// Get theta and phi from these random seeds
	params.theta = rand_from_seed(seed1) * 2.0 * PI;
	params.phi = acos(2.0*rand_from_seed(seed2) - 1.0);
}

// Creates a force in a random direction on a sphere
vec3 get_spherical_force(AngleParameters angles, float force){
	// Return the force vector
	return vec3(	force*cos(angles.theta)*sin(angles.phi),
					force*sin(angles.theta)*sin(angles.phi),
					force*cos(angles.phi));
}

vec3 projectile(vec3 start_velocity, AngleParameters params, float t){
	float x = start_velocity.x;
	float y = start_velocity.y - 0.01 * gravity.y * pow(t,2);
	float z = start_velocity.z;
	return vec3(x,y,z);
}



vec3 twinkle(vec3 color, float t){
	return color * sin(t);
}

// --------------------  END OF CUSTOM FUNCTIONS ------------------------------

void start() {
	uint base_number = NUMBER;
	uint alt_seed = hash(base_number + uint(1) + RANDOM_SEED);
	uint alt_seed2 =hash(base_number + uint(1337)+uint(1) + RANDOM_SEED);
	DisplayParameters params;
	calculate_initial_display_params(params, alt_seed);
	// Reset alt seed?
	//alt_seed = hash(base_number + uint(1) + RANDOM_SEED);

	AngleParameters angle_params;
	calculate_random_angles(angle_params, NUMBER, RANDOM_SEED);

	process_display_param(params, 0.0);
	if (rand_from_seed(alt_seed) > AMOUNT_RATIO) {
		ACTIVE = false;
	}

	// Reset values
	if (RESTART_CUSTOM) { //restart bool RESTART_X is true if its the first frame so =true
		CUSTOM = vec4(0.0);
		//CUSTOM.w = params.lifetime;
		CUSTOM.w = 0.0; //!NEW: TRACK TIME 
		//CUSTOM.x = dynamic_params.angle;
		//swim directions:
		// pick an initial swim direction on a sphere
		uint base_number = NUMBER;
		uint alt_seed = hash(base_number + uint(1) + RANDOM_SEED);

		float theta = rand_from_seed(alt_seed2) * 6.28318; // [0, 2π)
		float u = rand_from_seed(alt_seed2) * 2.0 - 1.0;   // [-1,1]
		float phi = acos(u);                              // [0, π]

		vec3 swim_dir = vec3(
		    cos(theta) * sin(phi),
		    sin(theta) * sin(phi),
		    cos(phi)
		);
				// store swim_dir in CUSTOM.xyz
		CUSTOM.x = swim_dir.x;
		CUSTOM.y = swim_dir.y;
		CUSTOM.z = swim_dir.z;
	}
	if (RESTART_COLOR) {
		COLOR = params.color;
	}
	if (RESTART_ROT_SCALE) {
		TRANSFORM[0].xyz = vec3(1.0, 0.0, 0.0);
		TRANSFORM[1].xyz = vec3(0.0, 1.0, 0.0);
		TRANSFORM[2].xyz = vec3(0.0, 0.0, 1.0);
	}
	if (RESTART_POSITION) {
		TRANSFORM[3].xyz = vec3(0,0,0);
		TRANSFORM = EMISSION_TRANSFORM * TRANSFORM;
	}
	if (RESTART_VELOCITY) {
	    // Random base direction (anywhere)
	    float theta = rand_from_seed(alt_seed) * 6.28318;
	    float phi = acos(2.0 * rand_from_seed(alt_seed) - 1.0);
	    vec3 base_dir = vec3(cos(theta)*sin(phi), sin(theta)*sin(phi), cos(phi));

	    // Give each particle a random "chaotic" multiplier
	    float chaos = mix(0.5, 2.0, rand_from_seed(alt_seed));

	    VELOCITY = base_dir * chaos * sphere_force;
	}


	process_display_param(params, 0.0);

	// Random base direction (anywhere)
    float theta = rand_from_seed(alt_seed) * 6.28318;
    float phi = acos(2.0 * rand_from_seed(alt_seed) - 1.0);
    vec3 base_dir = vec3(cos(theta)*sin(phi), sin(theta)*sin(phi), cos(phi));

    // Give each particle a random "chaotic" multiplier
    float chaos = mix(0.5, 2.0, rand_from_seed(alt_seed));

    VELOCITY = base_dir * chaos * sphere_force;
}

vec3 particle_position_update(){
	vec3 pos;
	return pos;
}

float size_x(float lifetime, vec3 original_size){
	return -10.0 * lifetime*lifetime + 10.0 * lifetime + 0.1*original_size.y + 1.0;
}


void process() {
	uint base_number = NUMBER;
	uint alt_seed = hash(base_number + uint(1) + RANDOM_SEED); //+ uint(TIME * 1000.0)???
	DisplayParameters params;
	calculate_initial_display_params(params, alt_seed);

	AngleParameters angle_params;
	calculate_random_angles(angle_params, NUMBER, RANDOM_SEED);

	float pi = 3.14159;
	float degree_to_rad = pi / 180.0;

	// Get a time since spawn
	CUSTOM.w += DELTA / LIFETIME;
	CUSTOM.w = mix(CUSTOM.w, 1.0, INTERPOLATE_TO_END);
	float lifetime_percent = CUSTOM.w / params.lifetime;
	if (CUSTOM.w > params.lifetime) {
		ACTIVE = false;
	}

	//CALC SWIMMING DIR------- FISH UNIQUE -------
	vec3 swim_dir = vec3(CUSTOM.x, CUSTOM.y, CUSTOM.z);
	// Small random turn each frame (jitter that's TINY, not full reroll)
	float turn_x = rand_from_seed(alt_seed) * 2.0 - 1.0;
	float turn_y = rand_from_seed(alt_seed)* 2.0 - 1.0;
	float turn_z = rand_from_seed(alt_seed)* 2.0 - 1.0;
	vec3 turn = vec3(turn_x, turn_y, turn_z) * turn_strength; // turn_strength ~ 0.2 or so

	//update fish new dir
	swim_dir += turn * DELTA;
	swim_dir = normalize(swim_dir);

	// write it back so the fish "remembers" its new heading
	CUSTOM.x = swim_dir.x;
	CUSTOM.y = swim_dir.y;
	CUSTOM.z = swim_dir.z;
	// accelerate a bit in that heading
	
	VELOCITY += swim_dir *swim_accel * DELTA;
	//drag
	VELOCITY -= VELOCITY *air_resistance * DELTA;


	TRANSFORM[3].xyz += VELOCITY*DELTA;

	process_display_param(params, lifetime_percent);

	float t = clamp(lifetime_percent, 0.0, 1.0);
	float glow_intensity = mix(glow_start, glow_end, pow(lifetime_percent, glow_falloff));	// curve: 1 → 0 over life, with controllable falloff

	// Drive particle color over time.
	// Fade-in first half, glow-out second half
	//float fade_in = smoothstep(0.3, 0.6, lifetime_percent);
	//float fade_out = 1.0 - smoothstep(0.7, 1.0, lifetime_percent);
	//float brightness = glow_intensity * fade_in * fade_out;

	//COLOR.rgb = params.color.rgb * brightness;
	//COLOR.a = pow(fade_in * fade_out, alpha_falloff);

	COLOR.rgb = params.color.rgb * glow_intensity;

	// Add sparkle flicker
	float sparkle = 0.5 + 0.5 * sin(TIME * 20.0 + float(NUMBER) * 1.7);
	COLOR.rgb *= sparkle;

	// Optional: tie transparency to life too.
	COLOR.a = pow(1.0 - t, alpha_falloff);

	// Gradually dampen velocity near the end
	float damp = smoothstep(0., 1.0, lifetime_percent);
	VELOCITY *= (1.0 - damp * 0.9);

	if (CUSTOM.w > params.lifetime) {
		ACTIVE = false;
	}
}
