extends Node3D
var firework = preload("res://scenes/firework.tscn")
var json_reader
var camera
var canvas 
@export_range(0, 1) var ratio = 0.5

#calculate
var mode = ProjectSettings.get_setting("display/window/size/mode")

@export var screen_width = DisplayServer.screen_get_size().x if mode == 3 else 1920 #pixel_width
@export var screen_height = DisplayServer.screen_get_size().y if mode == 3 else 1080 #pixel_height
var min_ratio
var max_ratio
var sky_width
var interval
var half_interval
var x_pos: float = 0
var direction: int = 1
var firework_show_index: int = 0
var firework_show_timer: Timer
var firework_show: Node3D
var countdown_layer
var countdown_label
var countdown_bar
var countdown_initial_height: float = 0.0
var countdown_initial_width: float = 0.0
var countdown_initial_time: float = 0.0
var firework_show_playing: bool = false

@export var fire_interval = 3.0
@export var firework_show_delay = 1200.0

func _ready():
	camera = get_node("Camera3D")
	json_reader = get_node("JsonReader")
	canvas = get_node("CanvasLayer")
	countdown_layer = get_node_or_null("CountdownLayer")
	if countdown_layer:
		countdown_label = countdown_layer.get_node_or_null("CountdownLabel")
		countdown_bar = countdown_layer.get_node_or_null("CountdownBar")
		if countdown_bar:
			countdown_initial_height = countdown_bar.size.y
			countdown_initial_width = countdown_bar.size.x
		_initialize_countdown_ui()
	
	min_ratio = (1-ratio)/2
	max_ratio = ratio + (1-ratio)/2
	
	# Move debug lines
	canvas.get_node("left_line").position.x = min_ratio * screen_width
	canvas.get_node("right_line").position.x = max_ratio * screen_width

	calculate_distances()
	var firework_show_scene = load("res://scenes/firework_show.tscn")
	firework_show = firework_show_scene.instantiate()
	add_child(firework_show)
	var detector = firework_show.get_node("Node3D")
	detector.drum_hit.connect(onDetect)
	_setup_firework_show_timer()
	
	
func onDetect(nr):
	
	var firework_data = {}
	x_pos += 40 * direction
	if x_pos >= 250:
		x_pos = 250
		direction = -1
	elif x_pos <= -250:
		x_pos = -250
		direction = 1
	for i in range(nr):
		if (firework_show_index+1 > json_reader.firework_show_data.size()):
			firework_show_index = 0
		if (json_reader.firework_show_data.size() == 0):
			create_mock_fireworks()
		if (json_reader.firework_show_data[firework_show_index] != null):
			firework_data = json_reader.firework_show_data[firework_show_index]
			var x_poss = x_pos + (i * 45 * direction)
			firework_data["location"] = x_poss
			
			firework_data["path_speed"] = 1
			firework_data["path_sound_path"] = null
			firework_data["use_variation"] = true
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
	_update_countdown_ui()

func _on_individual_timer_timeout(timer):
	var data = timer.get_meta("firework_data")
	data["location"] = data["location"] * half_interval
	create_firework(data)
	timer.queue_free()

func _setup_firework_show_timer():
	firework_show_timer = Timer.new()
	firework_show_timer.wait_time = firework_show_delay
	firework_show_timer.one_shot = true
	add_child(firework_show_timer)
	firework_show_timer.connect("timeout", Callable(self, "_on_firework_show_timer_timeout"))
	if firework_show:
		firework_show.connect("countdown_restart_requested", Callable(self, "_on_firework_show_restart_requested"))
	_start_firework_show_countdown()

func _start_firework_show_countdown():
	if firework_show_timer:
		firework_show_timer.wait_time = firework_show_delay
		firework_show_timer.start()
	countdown_initial_time = firework_show_delay
	firework_show_playing = false
	_reset_countdown_ui()
	_show_countdown_ui()

func _on_firework_show_timer_timeout():
	firework_show_playing = true
	_hide_countdown_ui()
	if firework_show:
		firework_show.start_show()

func _on_firework_show_restart_requested():
	_start_firework_show_countdown()

func _stop_firework_show_immediately():
	if not firework_show_playing:
		return
	if firework_show_timer and not firework_show_timer.is_stopped():
		firework_show_timer.stop()
	firework_show_playing = false
	_hide_countdown_ui()
	if firework_show:
		firework_show.stop_show()

func _skip_firework_show_timer():
	if firework_show_playing:
		return
	if not firework_show:
		return
	if firework_show_timer:
		firework_show_timer.stop()
	_on_firework_show_timer_timeout()

func _initialize_countdown_ui():
	if countdown_bar:
		countdown_initial_height = countdown_bar.size.y
		countdown_initial_width = countdown_bar.size.x
	_reset_countdown_ui()
	_hide_countdown_ui()

func _reset_countdown_ui():
	if countdown_bar:
		countdown_bar.size = Vector2(countdown_initial_width, countdown_initial_height)
		countdown_bar.visible = true
	if countdown_label:
		countdown_label.text = ""
		countdown_label.visible = false

func _show_countdown_ui():
	if countdown_layer:
		countdown_layer.visible = true
	if countdown_bar:
		countdown_bar.visible = true

func _hide_countdown_ui():
	if countdown_layer:
		countdown_layer.visible = false
	if countdown_bar:
		countdown_bar.visible = false
	if countdown_label:
		countdown_label.visible = false

func _update_countdown_ui():
	if not countdown_layer:
		return
	if firework_show_timer and not firework_show_timer.is_stopped():
		var time_left = firework_show_timer.get_time_left()
		if countdown_initial_time <= 0.0:
			countdown_initial_time = firework_show_timer.wait_time
		var total_time = max(countdown_initial_time, 0.001)
		var normalized = clamp(time_left / total_time, 0.0, 1.0)
		if countdown_bar:
			countdown_bar.size = Vector2(countdown_initial_width, countdown_initial_height * normalized)
		if countdown_label:
			if time_left <= 1.0:
				countdown_label.visible = true
				countdown_label.text = "Fire!"
			elif time_left <= 5.0:
				countdown_label.visible = true
				countdown_label.text = str(int(time_left))
			else:
				countdown_label.visible = false
		if countdown_layer:
			countdown_layer.visible = true
	else:
		if firework_show_playing:
			if countdown_layer:
				countdown_layer.visible = false
			if countdown_label:
				countdown_label.visible = false
		else:
			_hide_countdown_ui()
	
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
	if Input.is_action_just_pressed("stop_firework_show"):
		_stop_firework_show_immediately()
	if Input.is_action_just_pressed("skip_firework_show"):
		_skip_firework_show_timer()
	
func create_random_firework():
	pass

# For every data value missing in the json, fill it with some value
func fill_firework_data(firework_data):
	if(!firework_data.get("outer_layer")): firework_data["outer_layer"] = "sphere"
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
		{"outer_layer": "tornado", "inner_layer": "1/0.png", "outer_layer_color": [1.0,0.0,0.0], "outer_layer_second_color": [0.0,1.0,0.0], "location": 0.5},
		{"outer_layer": "cluster", "inner_layer": "1/1.png", "outer_layer_color": [1.0,0.0,0.0], "outer_layer_second_color": [0.0,1.0,0.0], "location": 0.5},
		{"outer_layer": "sphere", "inner_layer": "1/2.png", "outer_layer_color": [0.0,0.0,1.0], "outer_layer_second_color": [1.0,1.0,0.0], "location": 0.5},
		{"outer_layer": "chrysanthemum", "inner_layer": "none", "outer_layer_color": [1.0,0.0,1.0], "outer_layer_second_color": [1.0,1.0,0.0], "location": 0.5},
		{"outer_layer": "willow", "inner_layer": "none", "outer_layer_color": [1.0,0.0,1.0], "outer_layer_second_color": [1.0,1.0,0.0], "location": 0.5},
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
	
	
	
	
