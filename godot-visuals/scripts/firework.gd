extends Node3D
#member variables (unique for per instance)
var path
var blast
var drawing
var particle_pos
enum state {LAUNCHING, FIRING}
var current_state
var burstLight
var blast_nodes = []
var timer
var explosion_audio

# Contains all unique data of the firework
var firework_data = {}

func _ready():
	explosion_audio = AudioStreamPlayer.new()
	add_child(explosion_audio)

#Constantly make fw go upwards if launching
func _physics_process(delta):
	pass
	
func add_blast(outer_layer):
	var c_path = "res://scenes/" + outer_layer + "_blast.tscn"
	if ResourceLoader.exists(c_path) :
		var node = ResourceLoader.load(c_path).instantiate() 
		add_child(node)
		blast_nodes.append(node)
		node.position = particle_pos 
		node.set_parameters(firework_data)

func add_drawings():
	var c_path = "res://scenes/drawing_blast.tscn"
	if ResourceLoader.exists(c_path) :
		var node = ResourceLoader.load(c_path).instantiate() 
		add_child(node)
		blast_nodes.append(node)
		node.position = particle_pos 
		node.set_parameters(firework_data)

func add_path(path_speed, target_height, height_variation, visible_path, wobble_width, wobble_speed, path_sound = null):
	# Always load the path.tscn scene
	var path_scene_path = "res://scenes/path.tscn"
	if ResourceLoader.exists(path_scene_path):
		path = ResourceLoader.load(path_scene_path).instantiate()
		add_child(path)
		path.position = particle_pos
		
		# Configure path properties with passed parameters
		path.path_speed = path_speed * 2.5 + 0.5
		path.target_height = target_height
		path.height_variation = height_variation
		path.visible_path = visible_path
		path.wobble_width = wobble_width
		path.wobble_speed = wobble_speed
		path.path_sound_path = path_sound
		
		# Connect the timeout signal
		path.connect("path_timeout", _on_path_path_timeout)
		
		return true
	else:
		push_error("Path scene not found: " + path_scene_path)
		return false
			

func add_blasts_and_path():
	# Attach outer_layer and inner_layer
	if firework_data.get("outer_layer"):
		add_blast(firework_data.get("outer_layer"))
	if firework_data.get("inner_layer") && firework_data.get("inner_layer") != "none":
		add_drawings()
	
	# Set path parameters with hard-coded defaults based on outer_layer, overridden by firework_data if not matched
	var path_speed = firework_data.get("path_speed", 1.0)
	var target_height = 70.0  # default
	var height_variation = firework_data.get("height_variation", 10.0)
	var visible_path = true  # default
	var wobble_width = firework_data.get("path_wobble", 0)
	var wobble_speed = firework_data.get("wobble_speed", 0.5)
	var path_sound = "res://assets/sounds/fire_launch.mp3"
	var outer_layer = firework_data.get("outer_layer", "")
	match outer_layer:
		"sphere":
			visible_path = true
			target_height = 70.0
		"willow":
			visible_path = false
			target_height = 90.0
			path_sound = null
		_:  # Default case: use values from firework_data
			visible_path = firework_data.get("visible_path", true)
			target_height = firework_data.get("target_height", 70.0)
	
	# Dynamically add path based on firework_data
	add_path(path_speed, target_height, height_variation, visible_path, wobble_width, wobble_speed, path_sound)

func set_parameters(firework_data):
	# Store firework data
	self.firework_data = firework_data

	print("Firework data set: ", firework_data)
	
	# Attach nodes (burstLight and timer are still in the scene)
	burstLight = get_node("BurstLight3D")
	timer = get_node("Lifetime")
	
	# when instantiated, directly start launching
	current_state = state.LAUNCHING 
	
	# Set start position for the particle
	particle_pos = Vector3(0,-150, 0)
	position.x = firework_data["location"]
	
	# Add blasts and path
	add_blasts_and_path()
	
	
func fire_blast(pos):
	# Fire every blast node
	for blast in blast_nodes:
		blast.position = pos
		blast.fire()
	var fw_col = Color(firework_data["outer_layer_color"][0],firework_data["outer_layer_color"][1],firework_data["outer_layer_color"][2],1)
	pos = to_global(pos)  # Convert to global position for the burst light
	burstLight.spawn_burst_light(pos, fw_col) #set pos and col  
	
	timer.start()

#path timer starts when fw is instantiated -signal-> switch state to FIRING- start explosion particle effect
func _on_path_path_timeout(pos) -> void:
	current_state = state.FIRING
	path.queue_free() #remove path node of this fw instance (not from the scene file (globally))
	fire_blast(pos)

func _on_lifetime_timeout():
	queue_free() #removes firework
