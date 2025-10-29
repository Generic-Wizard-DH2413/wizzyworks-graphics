extends Node3D
var ring1_particles
var ring2_particles
var ring3_particles
var ring4_particles
var ring5_particles
var ring6_particles
var timer
var firework_data = {}

func set_parameters(firework_data):
	self.firework_data = firework_data
	ring1_particles = get_node("RingParticles1")
	ring2_particles = get_node("RingParticles2")
	ring3_particles = get_node("RingParticles3")
	ring4_particles = get_node("RingParticles4")
	ring5_particles = get_node("RingParticles5")
	ring6_particles = get_node("RingParticles6")
	timer = get_node("BlastTimer")
	
	set_outer_blast_data("tornado")
	randomize()
	set_color()

func _ready():
	pass

func set_color():
	var color = Vector4(firework_data["outer_layer_color"][0],firework_data["outer_layer_color"][1],firework_data["outer_layer_color"][2],1)
	ring1_particles.process_material.set_shader_parameter("color_value", color)
	var color2 = Vector4(firework_data["outer_layer_color"][0],firework_data["outer_layer_color"][1],firework_data["outer_layer_color"][2],1)
	ring2_particles.process_material.set_shader_parameter("color_value", color2)
	var color3 = Vector4(firework_data["outer_layer_color"][0],firework_data["outer_layer_color"][1],firework_data["outer_layer_color"][2],1)
	ring3_particles.process_material.set_shader_parameter("color_value", color3)
	var color4 = Vector4(firework_data["outer_layer_second_color"][0],firework_data["outer_layer_second_color"][1],firework_data["outer_layer_second_color"][2],1)
	ring4_particles.process_material.set_shader_parameter("color_value", color4)
	var color5 = Vector4(firework_data["outer_layer_second_color"][0],firework_data["outer_layer_second_color"][1],firework_data["outer_layer_second_color"][2],1)
	ring5_particles.process_material.set_shader_parameter("color_value", color5)
	var color6 = Vector4(firework_data["outer_layer_second_color"][0],firework_data["outer_layer_second_color"][1],firework_data["outer_layer_second_color"][2],1)
	ring6_particles.process_material.set_shader_parameter("color_value", color6)

# Sets random color for the firework
func set_rand_color():
	var r = randf();
	var g = randf();
	var b = randf();

	var color = Vector4(r,g,b,1.0);
	ring1_particles.process_material.set_shader_parameter("color_value", color)
	ring2_particles.process_material.set_shader_parameter("color_value", color)
	ring3_particles.process_material.set_shader_parameter("color_value", color)

	
	var c = randf();
	var c2 = randf();
	var c3 = randf();
	var color2 =  Vector4(c,c2,c3,1.0);
	ring4_particles.process_material.set_shader_parameter("color_value", color2)
	ring5_particles.process_material.set_shader_parameter("color_value", color2)
	ring6_particles.process_material.set_shader_parameter("color_value", color2)

#emit generic blast particles and also figure shaped particles. Timer to remove this node (and its particles) starts.
func fire():
	ring1_particles.emitting = true
	ring2_particles.emitting = true
	ring3_particles.emitting = true
	ring4_particles.emitting = true
	ring5_particles.emitting = true
	ring6_particles.emitting = true

	# get_node("FireworkBlast").play()
	AudioManager.play_sound($FireworkBlast.stream)
		
func set_outer_blast_data(type):
	match(type):
		"tornado":
			ring1_particles.process_material.set_shader_parameter("sphere",false);
			ring1_particles.process_material.set_shader_parameter("sphere_force", 0.0055)
			
			ring2_particles.process_material.set_shader_parameter("sphere",false);
			ring2_particles.process_material.set_shader_parameter("sphere_force", 0.005)
			
			ring3_particles.process_material.set_shader_parameter("sphere",false);
			ring3_particles.process_material.set_shader_parameter("sphere_force", 0.0045)
			
			ring4_particles.process_material.set_shader_parameter("sphere",false);
			ring4_particles.process_material.set_shader_parameter("sphere_force", 0.004)

			ring5_particles.process_material.set_shader_parameter("sphere",false);
			ring5_particles.process_material.set_shader_parameter("sphere_force", 0.0035)
			
			ring6_particles.process_material.set_shader_parameter("sphere",false);
			ring6_particles.process_material.set_shader_parameter("sphere_force", 0.003)



	
