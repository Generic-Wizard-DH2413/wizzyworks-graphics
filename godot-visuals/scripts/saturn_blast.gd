extends Node3D
var outer_particles
var ring_particles
var cloud_particles
var timer
var ring_number = 1

var firework_data = {}

func set_parameters(firework_data):
	self.firework_data = firework_data
	outer_particles = get_node("SaturnParticles")
	ring_particles = get_node("RingParticles")
	cloud_particles = get_node("CloudParticles")
	timer = get_node("BlastTimer")
	ring_number = int(firework_data.get("outer_layer_specialfx", 0.5) * 9) + 1
	
	set_outer_blast_data("saturn")
	randomize()
	set_color()

func _ready():
	pass

func set_color():
	var color = Vector4(firework_data["outer_layer_color"][0],firework_data["outer_layer_color"][1],firework_data["outer_layer_color"][2],1)
	outer_particles.process_material.set_shader_parameter("color_value", color)
	var color2 = Vector4(firework_data["outer_layer_second_color"][0],firework_data["outer_layer_second_color"][1],firework_data["outer_layer_second_color"][2],1)
	ring_particles.process_material.set_shader_parameter("color_value", color2)

# Sets random color for the firework
func set_rand_color():
	var r = randf();
	var g = randf();
	var b = randf();

	var color = Vector4(r,g,b,1.0);
	outer_particles.process_material.set_shader_parameter("color_value", color)
	
	var c = randf();
	var c2 = randf();
	var c3 = randf();
	var color2 =  Vector4(c,c2,c3,1.0);
	ring_particles.process_material.set_shader_parameter("color_value", color2)
#emit generic blast particles and also figure shaped particles. Timer to remove this node (and its particles) starts.
func fire():
	#spawn_rings(10)
	var axis = Vector3(1, randf_range(-1,1), 1).normalized()
	var angle = randf_range(0.0, 360.0)
	ring_particles.process_material.set_shader_parameter("ring_axis", axis)
	ring_particles.process_material.set_shader_parameter("ring_angle_deg", angle)
	outer_particles.emitting = true
	ring_particles.emitting = true
	await get_tree().create_timer(0.35).timeout
	get_node("FireworkBlast").play()
	
"""func spawn_rings(count):
	for i in range(count):
		var r = ring_particles.duplicate()
		var mat = r.process_material.duplicate(true)
		r.process_material = mat
		var axis = Vector3(1, randf_range(-1,1), 1).normalized()
		var angle = randf_range(0.0, 360.0)
		mat.set_shader_parameter("ring_axis", axis)
		mat.set_shader_parameter("ring_angle_deg", angle)
		add_child(r)
		r.emitting = true
		r.restart()"""
		
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
			
		"saturn":
			outer_particles.process_material.set_shader_parameter("sphere",true);
			outer_particles.process_material.set_shader_parameter("sphere_force", 1.0)
			outer_particles.process_material.set_shader_parameter("air_resistance", 0.98)
			outer_particles.process_material.set_shader_parameter("gravity", Vector3(0,0,0))
			outer_particles.process_material.set_shader_parameter("life_time", 4.0)
			
			ring_particles.process_material.set_shader_parameter("sphere",false);
			ring_particles.process_material.set_shader_parameter("sphere_force", 0.5)




	
