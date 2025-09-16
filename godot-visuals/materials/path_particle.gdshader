shader_type particles;
render_mode disable_force;

uniform vec4 starting_color = vec4(1.0, 1.0, 0.8, 1.0);
uniform vec4 dissolve_color = vec4(1.0, 0.0, 0.0, 0.0);
uniform float start_time_secs=0;
uniform float end_time_secs=1;

void start() {
	COLOR = dissolve_color;
	// Called when a particle is spawned.
}

void process() {
	COLOR = dissolve_color;
	//COLOR.g = smoothstep(end_time_secs, start_time_secs, TIME);
	//COLOR.b = smoothstep(end_time_secs, start_time_secs, TIME);
	//EMISSION = starting_color;
	//COLOR.a = smoothstep(end_time_secs, start_time_secs, TIME);
	// Called every frame on existing particles (according to the Fixed FPS property).
}

void fragment(){
	


}

void light(){
	
}