extends Node3D
var outer_particles
var timer

var firework_data = {}

func set_parameters(firework_data):
	self.firework_data = firework_data
	outer_particles = get_node("OuterBlastParticles")
	timer = get_node("BlastTimer")
	
	set_outer_blast_data("sphere")
	randomize()
	set_color()


func _ready():
	pass

func set_color():
	var color = Vector4(firework_data["outer_layer_color"][0],firework_data["outer_layer_color"][1],firework_data["outer_layer_color"][2],1)
	outer_particles.process_material.set_shader_parameter("color_value", color)

# Sets random color for the firework
func set_rand_color():
	var r = randf();
	var g = randf();
	var b = randf();

	var color = Vector4(r,g,b,1.0);
	outer_particles.process_material.set_shader_parameter("color_value", color)
	
#emit generic blast particles and also figure shaped particles. Timer to remove this node (and its particles) starts.
func fire():
	outer_particles.emitting = true
	# get_node("FireworkBlast").play()
	AudioManager.play_sound($FireworkBlast.stream)

# TODO: Remove this
func set_outer_blast_data(type):
	match(type):
		"sphere":
			outer_particles.process_material.set_shader_parameter("sphere",true);
			outer_particles.process_material.set_shader_parameter("sphere_force", 2.5)
			outer_particles.process_material.set_shader_parameter("air_resistance", 1.5)
			outer_particles.process_material.set_shader_parameter("gravity", Vector3(0,1.3,0))
			outer_particles.process_material.set_shader_parameter("life_time", 4.0)
			
			
		"willow":
			outer_particles.process_material.set_shader_parameter("sphere",true);
			outer_particles.process_material.set_shader_parameter("sphere_force", 2.0)
			outer_particles.process_material.set_shader_parameter("air_resistance", 0.98)
			outer_particles.process_material.set_shader_parameter("gravity", Vector3(0,1.8,0))
			outer_particles.process_material.set_shader_parameter("life_time", 9.0)




	
