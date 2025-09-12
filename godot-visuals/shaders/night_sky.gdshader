shader_type sky; //run on background (not a geometry)

//shader_type spatial;

//void vertex() {
	// Called for every vertex the material is visible on.
//}

//void fragment() {
	// Called for every pixel the material is visible on.
//}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

//tweak to your liking
//uniform make var show up in the inspector (see material inspect). (in normal scripts is "@export")
uniform float star_density : hint_range(0.0, 2.0) = 0.35;
uniform float star_intensity : hint_range(0.0, 5.0) = 2.4;
uniform float star_size : hint_range(0.0, 2.0) = 0.4;
uniform float twinkle_speed : hint_range(0.0, 5.0) = 0.5;
//how quickly sky gets lighter towards horizon
uniform float horizon_falloff : hint_range(0.0, 2.0) = 1.0;
//color fading from zenith->horizon col
uniform vec3 zenith_color : source_color = vec3(0.02, 0.03, 0.07);
uniform vec3 horizon_color : source_color = vec3(0.09, 0.12, 0.24);

uniform float cells = 420.0; // number of star cells around the sky 
uniform float density = 0.08; // probability of a star per cell (0–0.3 is reasonable)

//to gen a random number via hashing the coordinate
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

//convert 3d direaction to 2d UV coords on a sphere (skydome map) for the star grid
vec2 dir_to_uv(vec3 d) {
    float lon = atan(d.z, d.x);  // [-π, π]
    float lat = asin(clamp(d.y, -1.0, 1.0)); // [-π/2, π/2]
    return vec2(lon / (2.0 * PI) + 0.5, lat / PI + 0.5);
}

//Main sky func called for each sky PIXEL
//Basically fragment/pixel shader
void sky() {
	//convert sky coords to 3d direction
    vec2 uv = SKY_COORDS;  // uv in [0,1]
	float lon = (uv.x - 0.5) * TAU;           // [-π, π]
	float lat = (uv.y - 0.5) * PI;            // [-π/2, π/2]
	vec3 d = vec3(
	    cos(lat) * cos(lon),
	    sin(lat),
	    cos(lat) * sin(lon)
	);
	d=normalize(d);

    // Map y [-1,1] to [0,1] where y=1 is zenith and y=0 is horizon. Easier scale to work with.
    float up = clamp(d.y * 0.5 + 0.5, 0.0, 1.0);
	float horizon = pow(1.0 - up, horizon_falloff);
    //blend colors
	vec3 base_col = mix(zenith_color, horizon_color, horizon);

    vec2 grid = uv * cells;
    vec2 cell = floor(grid);
    vec2 f = fract(grid);

    float rnd = hash(cell);
    float star_here = step(1.0 - star_density, rnd);

    vec2 star_pos = fract(vec2(hash(cell + 11.1), hash(cell + 27.7)));
    float dist = length(f - star_pos);
    float star = smoothstep(star_size, 0.0, dist);

    float t = TIME * twinkle_speed;
    float twinkle = 0.75 + 0.25 * sin(t * 6.283 + rnd * 10.0);

    float star_brightness = star_here * star * star_intensity * twinkle;
    star_brightness *= smoothstep(0.0, 0.2, up);

	//output
    COLOR = base_col + vec3(star_brightness);
}
