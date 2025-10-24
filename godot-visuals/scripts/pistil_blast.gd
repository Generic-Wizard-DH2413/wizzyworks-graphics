extends Node3D
var outer_particles
var inner_particles
var middle_particles

var timer
var audio_player
var sphere_number = 1

var firework_data = {}

func set_parameters(firework_data):
	self.firework_data = firework_data
	inner_particles = get_node("OuterSphereParticles")
	outer_particles = get_node("OuterSphereParticles3")
	middle_particles = get_node("OuterSphereParticles2")
	audio_player=get_node("AudioPlayer")
	timer = get_node("CrackleTimer")
	sphere_number = int(firework_data.get("outer_layer_specialfx", 0.5) * 9) + 1
	
	#set_outer_blast_data("sphere")
	randomize()
	#set_color()
	set_rand_color()
func _ready():
	pass

func set_color():
	var color3 = Vector4(firework_data["outer_layer_second_color"][0],firework_data["outer_layer_second_color"][1],firework_data["outer_layer_second_color"][2],1)
	outer_particles.process_material.set_shader_parameter("color_value", color3)
	var color = Vector4(firework_data["outer_layer_second_color"][0],firework_data["outer_layer_second_color"][1],firework_data["outer_layer_second_color"][2],1)
	inner_particles.process_material.set_shader_parameter("color_value", color)
	var color2 = Vector4(firework_data["outer_layer_color"][0],firework_data["outer_layer_color"][1],firework_data["outer_layer_color"][2],1)
	middle_particles.process_material.set_shader_parameter("color_value", color2)

# Sets random color for the firework
func set_rand_color():
	var r = randf();
	var g = randf();
	var b = randf();

	var color = Vector4(r,g,b,1.0);
	middle_particles.process_material.set_shader_parameter("color_value", color)

	
	var c = clamp(r-0.6,0.0,1.0);
	var c2 = clamp(g+0.6,0.0,1.0);
	var c3 = clamp(b*g*1.5,0.0,1.0);
	var color2 =  Vector4(c,c2,c3,1.0);
	#print(outer_particles.process_material == inner_particles.process_material) # true? then they’re shared

	inner_particles.process_material.set_shader_parameter("color_value", color2)
	outer_particles.process_material.set_shader_parameter("color_value", color2)

	
#Called from the fw scene
func fire():
	#spawn_rings(10)
	get_node("FireworkBlast").play() #sfx
	outer_particles.emitting = true
	inner_particles.emitting = true
	middle_particles.emitting = true
	timer.start()
	
func _on_crackle_timer_timeout() -> void:
	audio_player.play_random_part()
	print("playing") 
	# Replace with function body.
	

func spawn_rings(count):
	var base_axis = Vector3(1, randf_range(-1,1), 1).normalized()
	var base_angle = randf_range(0.0, 360.0)
	inner_particles.process_material.set_shader_parameter("ring_axis", base_axis)
	inner_particles.process_material.set_shader_parameter("ring_angle_deg", base_angle)
	inner_particles.restart()
	inner_particles.emitting = true
	for i in range(count - 1):
		var r = inner_particles.duplicate()
		
		var mat = r.process_material.duplicate(true)
		r.process_material = mat
		# random axis and angle for each ring
		var axis = Vector3(1, randf_range(-1,1), 1).normalized()
		var angle = randf_range(0.0, 360.0)
		mat.set_shader_parameter("ring_axis", axis)
		mat.set_shader_parameter("ring_angle_deg", angle)

		add_child(r)
		r.emitting = true
		r.restart()
		
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
			
			inner_particles.process_material.set_shader_parameter("sphere",false);
			inner_particles.process_material.set_shader_parameter("sphere_force", 0.5)




	
