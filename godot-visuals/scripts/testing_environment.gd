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

var shapes = ["sphere"]

func _ready():
	camera = get_node("Camera3D")
	json_reader = get_node("JsonReader")
	canvas = get_node("CanvasLayer")
	
	min_ratio = (1-ratio)/2
	max_ratio = ratio + (1-ratio)/2
	
	canvas.get_node("left_line").position.x = min_ratio * screen_width
	canvas.get_node("right_line").position.x = max_ratio * screen_width

	calculate_distances()
	
#constantly check for json files
#AlQ: perhaps we can instead receive signals from JsonReader instead of constant looking? not superimportant currently though
func _process(delta):
	check_json()
	
func calculate_distances():
	sky_width = 2 * tan(deg_to_rad(camera.fov/2)) * camera.position.z * (1920.0/1080.0)
	interval = ratio * sky_width
	half_interval = interval/2

#constantly check for inputs
func _input(event):
	if Input.is_action_just_pressed("load_firework"):
		var mouse_pos_x = ((get_viewport().get_mouse_position().x)/screen_width) - 0.5
		var pos = Vector3(mouse_pos_x * sky_width,-100,0)
		var firework_data = {}
		firework_data["location"] = pos.x
		create_firework(firework_data) #hardcoded fw w/o json file
	if Input.is_action_just_pressed("debug"):
		canvas.visible = true
	if Input.is_action_just_released("debug"):
		canvas.visible = false
	
func create_random_firework():
	pass

func fill_firework_data(firework_data):
	if(!firework_data.get("outer_layer")): firework_data["outer_layer"] = "sphere"
	if(!firework_data.get("inner_layer")): firework_data["inner_layer"] = "random"
	if(!firework_data.get("outer_layer_color")): firework_data["outer_layer_color"] = Vector3(1,1,1);
	if(!firework_data.get("outer_layer_second_color")): firework_data["outer_layer_second_color"] = Vector3(1,1,1);
	if(!firework_data.get("force")): firework_data["force"] = 0.5
	if(!firework_data.get("angle")): firework_data["angle"] = 0.5
	if(!firework_data.get("location")): firework_data["location"] = 0.0

#called if pressing "load_firework" key
#will instantiate fw scene and generate the fw w hardcoded starshape
func create_firework(firework_data):
	var fw = firework.instantiate() #need to instantiate because firework is a separate scene (not a child node)
	fill_firework_data(firework_data)
	fw.set_parameters(firework_data, ["classic_blast", "drawing_blast"])
	add_child(fw)

#called if there are any jason file to be read
#will instantiate fw scene and generate the fw w json shape
func create_shaped_firework(data):
	var fw = firework.instantiate()
	var coordinate = data.get("location")
	fw.position = Vector3(coordinate *half_interval, -30,0) #only care about x-coords
	add_child(fw)
	fw.generate_shape(data.get("points")) #calls fw-->calls blast-->calls figure.

# Checks the json reader for new fireworks
# Is a queue. After read. Remove from qeue. 
func check_json():
	var new_fireworks = true
	while(new_fireworks):
		if(json_reader.pending_data.size() == 0):
			new_fireworks = false
			return
		else:
			if(json_reader.pending_data[0] != null):
				var data = json_reader.pending_data[0]
				data["location"] = data["location"]*half_interval
				create_firework(json_reader.pending_data[0])
		json_reader.pending_data.remove_at(0)
	
	
	
	
