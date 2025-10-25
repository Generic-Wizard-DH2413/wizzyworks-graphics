extends Node3D
var firework = preload("res://scenes/firework.tscn")
var json_reader
var camera
var canvas 
@export_range(0, 1) var ratio = 0.5

#calculate
@export var screen_width = 1920 #pixel_width
@export var screen_height = 1080 #pixel_height
var min_ratio
var max_ratio
var sky_width
var interval
var half_interval
var x_pos: float = 0
var direction: int = 1
var firework_show_index: int = 0

@export var fire_interval = 3.0

func _ready():
	camera = get_node("Camera3D")
	json_reader = get_node("JsonReader")
	canvas = get_node("CanvasLayer")
	
	min_ratio = (1-ratio)/2
	max_ratio = ratio + (1-ratio)/2
	
	# Move debug lines
	canvas.get_node("left_line").position.x = min_ratio * screen_width
	canvas.get_node("right_line").position.x = max_ratio * screen_width

	calculate_distances()
	var musicSyncScene = load("res://scenes/firework_show.tscn")
	var musicSync = musicSyncScene.instantiate()
	add_child(musicSync)
	var detector = musicSync.get_node("Node3D")
	detector.drum_hit.connect(onDetect)
	
	
func onDetect():
	print("On Detect")
	var firework_data = {}
	x_pos += 40 * direction
	if x_pos >= 250:
		x_pos = 250
		direction = -1
	elif x_pos <= -250:
		x_pos = -250
		direction = 1
	
	if (firework_show_index+1 > json_reader.firework_show_data.size()):
		firework_show_index = 0
		
	print(json_reader.firework_show_data)
	if (json_reader.firework_show_data[firework_show_index] != null):
		firework_data = json_reader.firework_show_data[firework_show_index]
		firework_data["location"] = x_pos
		firework_data["path_speed"] = 1
		firework_data["path_sound_path"] = null
		firework_data["use_variation"] = false
		create_firework(firework_data)
	else:
		create_debug_firework(firework_data)
	
	firework_show_index+=1
	#create_debug_firework(firework_data)
#constantly check for json files
#AlQ: perhaps we can instead receive signals from JsonReader instead of constant looking? not superimportant currently though
func _process(_delta):
	while json_reader.pending_data.size() > 0:
		var firework_list = json_reader.pending_data.pop_front()
		for i in range(firework_list.size()):
			if i == 0:
				# Fire the first firework immediately
				var data = firework_list[0]
				data["location"] = data["location"] * half_interval
				create_firework(data)
			else:
				var timer = Timer.new()
				timer.wait_time = fire_interval * i
				timer.one_shot = true
				timer.set_meta("firework_data", firework_list[i])
				add_child(timer)
				timer.connect("timeout", func(): _on_individual_timer_timeout(timer))
				timer.start()

func _on_individual_timer_timeout(timer):
	var data = timer.get_meta("firework_data")
	data["location"] = data["location"] * half_interval
	create_firework(data)
	timer.queue_free()
	
# Get distances in order to accurately match phone position to space position
func calculate_distances():
	sky_width = 2 * tan(deg_to_rad(camera.fov/2)) * camera.position.z * (1920.0/1080.0)
	interval = ratio * sky_width
	half_interval = interval/2

#constantly check for inputs
func _input(_event):
	if Input.is_action_just_pressed("load_firework"):
		var mouse_pos_x = ((get_viewport().get_mouse_position().x)/screen_width) - 0.5
		var pos = Vector3(mouse_pos_x * sky_width,-100,0)
		var firework_data = {}
		firework_data["location"] = pos.x
		create_debug_firework(firework_data) #hardcoded fw w/o json file
	if Input.is_action_just_pressed("debug"):
		canvas.visible = true
	if Input.is_action_just_released("debug"):
		canvas.visible = false
	if Input.is_action_just_pressed("mock_fireworks"):
		create_mock_fireworks()
	
func create_random_firework():
	pass

# For every data value missing in the json, fill it with some value
func fill_firework_data(firework_data):
	if(!firework_data.get("outer_layer")): firework_data["outer_layer"] = "saturn"
	if(!firework_data.get("inner_layer")): firework_data["inner_layer"] = "none"
	if(!firework_data.get("outer_layer_color")): firework_data["outer_layer_color"] = [randf(),randf(),randf()];
	if(!firework_data.get("outer_layer_second_color")): firework_data["outer_layer_second_color"] = [randf(),randf(),randf()];
	if(!firework_data.get("location")): firework_data["location"] = 0.0
	if(!firework_data.get("path_speed")): firework_data["path_speed"] = 1.0
	if(!firework_data.get("path_wobble")): firework_data["path_wobble"] = 0
	if(!firework_data.get("outer_layer_specialfx")): firework_data["outer_layer_specialfx"] = 0


#called if pressing "load_firework" key
#will instantiate fw scene and generate the fw w hardcoded starshape
func create_firework(firework_data):
	var fw = firework.instantiate() #need to instantiate because firework is a separate scene (not a child node)
	fill_firework_data(firework_data)
	fw.set_parameters(firework_data)
	add_child(fw)

# Adjust this for debugging things (called when pressing F)
func create_debug_firework(firework_data):
	var fw = firework.instantiate() #need to instantiate because firework is a separate scene (not a child node)
	if(!firework_data.get("inner_layer")): firework_data["inner_layer"] = "none"
	fill_firework_data(firework_data)
	fw.set_parameters(firework_data)
	add_child(fw)

func create_mock_fireworks():
	var mock_fireworks = [
		{"outer_layer": "saturn", "inner_layer": "none", "outer_layer_color": [1.0,0.0,0.0], "outer_layer_second_color": [0.0,1.0,0.0], "location": 0.5},
		{"outer_layer": "cluster", "inner_layer": "none", "outer_layer_color": [1.0,0.0,0.0], "outer_layer_second_color": [0.0,1.0,0.0], "location": 0.5},
		{"outer_layer": "sphere", "inner_layer": "none", "outer_layer_color": [0.0,0.0,1.0], "outer_layer_second_color": [1.0,1.0,0.0], "location": 0.5},
		{"outer_layer": "cluster", "inner_layer": "none", "outer_layer_color": [1.0,0.0,1.0], "outer_layer_second_color": [1.0,1.0,0.0], "location": 0.5},
		{"outer_layer": "saturn", "inner_layer": "none", "outer_layer_color": [1.0,0.0,1.0], "outer_layer_second_color": [1.0,1.0,0.0], "location": 0.5},
		{"outer_layer": "another_cluster", "inner_layer": "none", "outer_layer_color": [1.0,0.0,1.0], "outer_layer_second_color": [1.0,1.0,0.0], "location": 0.5},
		{"outer_layer": "saturn", "inner_layer": "none", "outer_layer_color": [1.0,0.0,1.0], "outer_layer_second_color": [1.0,1.0,0.0], "location": 0.5}
	]
	json_reader.pending_data.append(mock_fireworks)
	for mock_firework in mock_fireworks:
		json_reader.firework_show_data.append(mock_firework)

#called if there are any jason file to be read
#will instantiate fw scene and generate the fw w json shape
func create_shaped_firework(data):
	var fw = firework.instantiate()
	var coordinate = data.get("location")
	fw.position = Vector3(coordinate *half_interval, -30,0) #only care about x-coords
	add_child(fw)
	fw.generate_shape(data.get("points")) #calls fw-->calls blast-->calls figure.
	
	
	
	
