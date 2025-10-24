extends Node3D

@onready var audio_player = $AudioPlayer

var explosions_spawned := 0
var MAX_EXPLOSIONS := 10
var outer_particles
var timer
var amount_of_shits = 3;

var firework_data = {}

func set_parameters(firework_data):
	self.firework_data = firework_data
	outer_particles = get_node("OuterBlastParticles")
	outer_particles.emitting = false;
	timer = get_node("BlastTimer")
	
	amount_of_shits = int(firework_data.get("outer_layer_specialfx", 0.0) * 10) + 2
	MAX_EXPLOSIONS = amount_of_shits
	
	
	set_outer_blast_data("cluster")
	randomize()
	set_color()


func _ready():
	pass

func set_color():
	var color = Color(firework_data["outer_layer_color"][0],firework_data["outer_layer_color"][1],firework_data["outer_layer_color"][2],1)
	outer_particles.process_material.set_color(color)

func get_as_color():
	var color = Color(firework_data["outer_layer_color"][0],firework_data["outer_layer_color"][1],firework_data["outer_layer_color"][2],1)
	return color

# Sets random color for the firework
func set_rand_color():
	var r = randf();
	var g = randf();
	var b = randf();

	var color = Color(r,g,b,1.0);
	outer_particles.process_material.set_color(color)
	#outer_particles.process_material.color = color
	#outer_particles.process_material.set_shader_parameter("color_value", color)
	
func get_rand_color():
	var r = randf();
	var g = randf();
	var b = randf();

	var color = Color(r,g,b,1.0);
	return color
#emit generic blast particles and also figure shaped particles. Timer to remove this node (and its particles) starts.

func fire():
	outer_particles.emitting = true
	spawn_predicted_explosions()
	await get_tree().create_timer(0.35).timeout
	get_node("FireworkBlast").play()
	

func set_outer_blast_data(type):
	pass
	#match(type):
		#"sphere":
			#outer_particles.process_material.set_shader_parameter("sphere",true);
			#outer_particles.process_material.set_shader_parameter("sphere_force", 2.5)
			#outer_particles.process_material.set_shader_parameter("air_resistance", 1.5)
			#outer_particles.process_material.set_shader_parameter("gravity", Vector3(0,1.3,0))
			#outer_particles.process_material.set_shader_parameter("life_time", 4.0)
			#
			#
		#"willow":
			#outer_particles.process_material.set_shader_parameter("sphere",true);
			#outer_particles.process_material.set_shader_parameter("sphere_force", 2.0)
			#outer_particles.process_material.set_shader_parameter("air_resistance", 0.98)
			#outer_particles.process_material.set_shader_parameter("gravity", Vector3(0,1.8,0))
			#outer_particles.process_material.set_shader_parameter("life_time", 9.0)


func spawn_predicted_explosions():
	var count = 20
	var base_speed = 20.0
	var lifetime = 1.0 - float(firework_data.get("outer_layer_specialfx", 0.0)) + 0.3
	#self.get_node("SubParticles").amount = amount_of_shits
	var gravity = Vector3(0, -9.8, 0)

	for i in range(count):
		if explosions_spawned >= MAX_EXPLOSIONS:
			return

		explosions_spawned += 1

		var dir = Vector3(
			randf_range(-0.7, 0.7),
			randf_range(0.2, 1.0),
			randf_range(-0.7, 0.7)
		).normalized()
		
		var velocity = dir * base_speed
		var end_pos = velocity * lifetime + 0.5 * gravity * lifetime * lifetime
		end_pos += Vector3(
			randf_range(-1, 1),
			randf_range(-0.5, 0.5),
			randf_range(-1, 1)
		)
		var final_pos = global_position + end_pos
		
		# Om kameran kan se lutning så kan fyrverkeriet skjutas snett
		# Man kan vrida fyrverkeri innan launch
		
		
		await get_tree().create_timer(lifetime).timeout
		spawn_explosion(final_pos)

func spawn_explosion(pos: Vector3):
	var original = $SubParticles
	var e = original.duplicate() as GPUParticles3D
	e.global_position = pos
	e.process_material.set_color(get_as_color())
	get_tree().current_scene.add_child(e)
	get_node("SecondFireworkBlast").play()
	e.emitting = true
