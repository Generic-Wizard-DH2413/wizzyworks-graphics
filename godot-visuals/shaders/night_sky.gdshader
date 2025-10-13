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
//OBS (CHOOSE .TRES FILE FS)
//uniform make var show up in the inspector. (in normal scripts is "@export")
uniform float star_intensity : hint_range(0.0, 5.0) = 0.5;
uniform float twinkle_speed : hint_range(0.0, 5.0) = 0.5;
uniform float twinkle_str: hint_range(0.0, 1.0) = 0.4;
//how quickly sky gets lighter/darker towards horizon
uniform float sky_fade_start : hint_range(0.0, 1.0) = 0.237;
uniform float sky_fade_end   : hint_range(0.0, 1.0) = 0.85;
uniform float gradient_power : hint_range(0.1, 5.0) = 0.327;
uniform float star_fade_start : hint_range(0.0, 1.0) = 0.52;
uniform float star_fade_end   : hint_range(0.0, 1.0) = 0.70;
uniform float star_gradient_power : hint_range(0.1, 5.0) = 0.327;

//color fading from zenith->horizon col
uniform vec3 zenith_color : source_color = vec3(0.01, 0.02, 0.03);
uniform vec3 horizon_color : source_color = vec3(0.393, 0.442, 0.616);

uniform float cells = 220.0; // number of star cells around the sky (1 star possible per cell)
uniform float star_density : hint_range(0.0, 2.0) = 0.08;
//Basically size of stars (still cant be bigger than the cell it is in-->effectively, fewer cells->bigger cells->possibl bigger stars)
uniform float star_ang_size = 0.002; // radians (~0.11°). Tweak 0.0007–0.003.

uniform int   seed = 1;

//to gen a random number via hashing the coordinate
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345 );
    return fract(p.x * p.y);
}

//random rot function
vec2 rot2(vec2 v, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c*v.x - s*v.y, s*v.x + c*v.y);
}

vec2 wrap_cell(vec2 c, float n) {
    return vec2(mod(c.x, n), mod(c.y, n));  // result in [0, n)
}

//convert 3d direaction to 2d UV coords on a sphere (skydome map) for the star grid
vec2 dir_to_uv(vec3 d) {
    float lon = atan(d.z, d.x);  // [-π, π]
    float lat = asin(clamp(d.y, -1.0, 1.0)); // [-π/2, π/2]
    return vec2(lon / (2.0 * PI) + 0.5, lat / PI + 0.5);
}

float star_brightness_calc(vec2 uv, float cells_in_layer, float rotation, float layer_offset, vec3 d, float up){
	//1)
	//generate starfield in rotated UV space
	//rotate tiling to avoid row/column alignment between layers.
	vec2 pivot = vec2(0.5);
	vec2 uvr = rot2(uv-pivot, rotation)+pivot;
    vec2 grid = uvr * cells_in_layer; //scale UVs (divide sky into a grid)
    vec2 cell = floor(grid); //floor to integer cell idx

	//1.5 for each cell around cell of interest check if light spills over
	float tot_star_brightness=0.0;
	//Need to check cells surrounding also so stars dont get clipped in their cells
	// 3x3 neighborhood
    for (int ox = -1; ox <= 1; ox++) {
        for (int oy = -1; oy <= 1; oy++) {

            vec2 c = wrap_cell(cell + vec2(float(ox), float(oy)),(cells_in_layer+1.0)); //NOT WORKING??neighbors at end of UV map to avoid seam


			//2)Presence of star check
		    //for each gridcell, a star should be there if rnd > 1-star_density
			float r_presence=hash(c+layer_offset+  10.0); //outputs a random val [0,1] per grid cell
			float star_here = step(1.0 - star_density, r_presence); //either 1=true or 0=false
			//only do calcs if star in this cell
			if(star_here==0.0){
				continue;
			}

			//3)Random independent values for different star attributes, per cell
			float r_size = hash(c + layer_offset + 20.0); //outputs a random val [0,1] per grid cell
		    float r_phase = hash(c+ layer_offset+  30.0); //outputs a random val [0,1] per grid cell
		    vec2  r_pos2     = vec2(
		        hash(c + layer_offset + 40.0),
		        hash(c + layer_offset + 50.0)
		    );


			//4) Random sub-cell pos in rot space
			//randomly(via hash) place stars in uvr positsions
			//if star inside cell, it should appear at random spot inside cell (not in middle always)
		    vec2 star_pos_local = fract(r_pos2); //just get random local cell pos (x,y pos) [0,1]
			vec2 star_uv_rot  = (c + star_pos_local) / cells_in_layer;        // convert from cell idx+fract to uv coords

			//5) pxl vs star vectors
			//undo rot for light calcs
			vec2 star_uv = rot2(star_uv_rot-pivot, -rotation)+pivot;  // undo the rotation for c vs s calcs
			star_uv = fract(star_uv);                     // keep in [0,1]
			//since cell UVs get distorted near top/bottom use spherical coords instead to avoid stretched stars
			float star_lon = (star_uv.x - 0.5) * TAU;
			float star_lat = (0.5 - star_uv.y) * PI;
			//calc star spherical coords to 3d coordinats (from origo pointing to point on skydome sphere)
			vec3  s = vec3(
			    cos(star_lat) * cos(star_lon),
			    sin(star_lat),
			    cos(star_lat) * sin(star_lon)
			); //vec3([-1,1])

			//6) Size of stars randomly and first light calc
			//Random size of stars (based on cos_thresh)
			float theta = mix(0.5 * star_ang_size, star_ang_size, r_size); //at least half of star size
			float cos_thresh=cos(theta); //angle between d (pxl of interest pos) and star center(pos)) needs to be at least star_ang_size/2
			float star_light = smoothstep(cos_thresh, 1.0, dot(d, s));
			//star_light = pow(star_light, 1.3);      // optional softening

			//7) Twinkle animation randomly
		    float t = TIME * twinkle_speed;
		    float twinkle = (1.0-twinkle_str) + twinkle_str * sin(t * 6.283 + r_phase * 10.0);

			//8) Brightness bonus to 10% biggest stars
			//only 10%, the biggest stars gets brighter bonus
			float bonus    = mix(1.0, 2.0, step(0.9, r_size)); //2x multiplier iff top 10%
			float big_bonus    = mix(1.0, 2.0, step(0.95, r_size)); //2x multiplier iff top 10%


			//9) Light calc
			float star_brightness = star_here * star_light * star_intensity * twinkle* bonus * big_bonus;

			//10)change brightness depending on altitude
			float up_star   = clamp((s.y + 1.0) * 0.5, 0.0, 1.0);       // 0..1 from star center
			float star_elev = smoothstep(star_fade_start, star_fade_end, up_star);
			star_brightness *= pow(star_elev,star_gradient_power);


			tot_star_brightness+= star_brightness;
			}
		}
	return tot_star_brightness;
}


//Main sky func called for each sky PIXEL
//Basically fragment/pixel shader
void sky() {
	//convert sky coords to 3d direction
    vec2 uv = SKY_COORDS;  // uv in [0,1]x[0,1] (skysphere->rectangle)
	float lon = (uv.x - 0.5) * TAU;           // [-π, π]
	float lat = (0.5 - uv.y) * PI;      // new: flip V so top is +π/2 (up)
	vec3 d = vec3(
	    cos(lat) * cos(lon),
	    sin(lat),
	    cos(lat) * sin(lon)
	); //d is direction were shading on the skydome
	d=normalize(d);



	float up = clamp((d.y + 1.0) * 0.5, 0.0, 1.0);           // canonical
	float t  = smoothstep(sky_fade_start, sky_fade_end, up); // 0..1 only in that band
	t = pow(t, gradient_power);                              // shape it (optional)

	vec3 base_col = mix(horizon_color, zenith_color, t);

	float rot = 2.39996323; //random
	// Map y [-1,1] to [0,1] where y=1 is zenith and y=0 is horizon. Easier scale to work with.
    //up = clamp(d.y * 1.0 + 1.0, 0.0, 1.0);
	float star_brightness_layer1= star_brightness_calc(uv, (cells * 1.00), (rot * float(seed+0)), 13.37,d ,up);
	float star_brightness_layer2= star_brightness_calc(uv, (cells * 1.3), (rot * float(seed+2)), 1337.0,d, up);


	//output
    COLOR = base_col + vec3(star_brightness_layer1) + vec3(star_brightness_layer2*0.3);
}
