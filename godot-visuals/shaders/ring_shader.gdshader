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
uniform vec3 ring_axis = vec3(0.0, 1.0, 0.0);
uniform float ring_angle_deg = 0.0;

// Sphere Params
uniform bool sphere;
uniform float sphere_force;

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
mat3 rotation_around_axis(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    vec3 col0 = vec3(
        oc * axis.x * axis.x + c,
        oc * axis.x * axis.y + axis.z * s,
        oc * axis.z * axis.x - axis.y * s
    );

    vec3 col1 = vec3(
        oc * axis.x * axis.y - axis.z * s,
        oc * axis.y * axis.y + c,
        oc * axis.y * axis.z + axis.x * s
    );

    vec3 col2 = vec3(
        oc * axis.z * axis.x + axis.y * s,
        oc * axis.y * axis.z - axis.x * s,
        oc * axis.z * axis.z + c
    );

    return mat3(col0, col1, col2);
}


void start() {
	uint base_number = NUMBER;
	uint alt_seed = hash(base_number + uint(1) + RANDOM_SEED);
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
	if (RESTART_CUSTOM) {
		CUSTOM = vec4(0.0);
		CUSTOM.w = params.lifetime;
		//CUSTOM.x = dynamic_params.angle;
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
		if(sphere){
			AngleParameters angles;
			angles.theta =  rand_from_seed(alt_seed) * 6.28313;;
			angles.phi = 1.5708; // PI/2

			vec3 local_velocity = get_spherical_force(angles, sphere_force);
			mat3 rot = rotation_around_axis(ring_axis, radians(ring_angle_deg));
		    local_velocity = rot * local_velocity;
			//dir = dir * rings;
		    VELOCITY = (EMISSION_TRANSFORM * vec4(local_velocity, 0.0)).xyz;
		}
	}

	process_display_param(params, 0.0);

	AngleParameters angles;
	angles.theta = rand_from_seed(alt_seed) * 6.28313; angles.phi = 1.5708; // PI/2 
	vec3 local_velocity = get_spherical_force(angles, sphere_force); 
	mat3 rot = rotation_around_axis(ring_axis, radians(ring_angle_deg)); 
	local_velocity = rot * local_velocity; 
	//dir = dir * rings; 
	VELOCITY = (EMISSION_TRANSFORM * vec4(local_velocity, 0.0)).xyz;
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
	uint alt_seed = hash(base_number + uint(1) + RANDOM_SEED);
	DisplayParameters params;
	calculate_initial_display_params(params, alt_seed);

	AngleParameters angle_params;
	calculate_random_angles(angle_params, NUMBER, RANDOM_SEED);

	float pi = 3.14159;
	float degree_to_rad = pi / 180.0;

	// Get a time since spawn
	CUSTOM.y += DELTA / LIFETIME;
	CUSTOM.y = mix(CUSTOM.y, 1.0, INTERPOLATE_TO_END);
	float lifetime_percent = CUSTOM.y / params.lifetime;
	if (CUSTOM.y > CUSTOM.w) {
		ACTIVE = false;
	}


	VELOCITY += vec3(0.0, -gravity.y, 0.0) * DELTA;
	VELOCITY -= VELOCITY * air_resistance * DELTA;


	TRANSFORM[3].xyz += VELOCITY;

	process_display_param(params, lifetime_percent);

	float t = clamp(lifetime_percent, 0.0, 1.0);
	float glow_intensity = mix(glow_start, glow_end, pow(lifetime_percent, glow_falloff));	// curve: 1 → 0 over life, with controllable falloff

	// Drive particle color over time.
	COLOR.rgb = params.color.rgb * glow_intensity;

	// Optional: tie transparency to life too.
	COLOR.a = pow(1.0 - t, alpha_falloff);

	if (CUSTOM.y > CUSTOM.w) {
		ACTIVE = false;
	}
}
