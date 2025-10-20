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

# Contains all unique data of the firework
var firework_data = {}

func _ready():
	pass

#Constantly make fw go upwards if launching
func _physics_process(delta):
	pass
	
func add_components(components):
	for c in components:
		var c_path = "res://scenes/" + c + "_blast.tscn"
		if ResourceLoader.exists(c_path) :
			var node = ResourceLoader.load(c_path).instantiate() 
			add_child(node)
			blast_nodes.append(node)
			node.position = particle_pos 
			node.set_parameters(firework_data)

func add_path(path_type_name):
	# Dynamically load and create the path based on type
	var path_scene_path = "res://scenes/" + path_type_name + ".tscn"
	if ResourceLoader.exists(path_scene_path):
		path = ResourceLoader.load(path_scene_path).instantiate()
		add_child(path)
		path.position = particle_pos
		
		# Configure path properties from firework_data
		if firework_data.has("path_type") && "path_type" in path:
			print("Setting path type to: ", firework_data["path_type"])
			path.path_type = firework_data["path_type"]
		
		if firework_data.has("launch_speed") && "launch_speed" in path:
			path.launch_speed = firework_data["launch_speed"]
		
		if firework_data.has("target_height") && "target_height" in path:
			path.target_height = firework_data["target_height"]
		
		if firework_data.has("height_variation") && "height_variation" in path:
			path.height_variation = firework_data["height_variation"]
		
		if firework_data.has("visible_path") && "visible_path" in path:
			path.visible_path = firework_data["visible_path"]
		
		if firework_data.has("wobble_width") && "wobble_width" in path:
			path.wobble_width = firework_data["wobble_width"]
			
		if firework_data.has("wobble_speed") && "wobble_speed" in path:
			path.wobble_speed = firework_data["wobble_speed"]
		
		# Connect the timeout signal
		path.connect("path_timeout", _on_path_path_timeout)
		
		return true
	else:
		push_error("Path scene not found: " + path_scene_path)
		return false
			

func set_parameters(firework_data):
	# Store firework data
	self.firework_data = firework_data
	
	var components = []
	
	# Attach outer_layer and inner_layer
	if firework_data.get("outer_layer"):
		components.append(firework_data.get("outer_layer"))
	if firework_data.get("inner_layer") && firework_data.get("inner_layer") != "none":
		components.append("drawing")
		
	
	# Attach nodes (burstLight and timer are still in the scene)
	burstLight = get_node("BurstLight3D")
	timer = get_node("Lifetime")
	
	# when instantiated, directly start launching
	current_state = state.LAUNCHING 
	
	# Set start position for the particle
	particle_pos = Vector3(0,-150, 0)
	position.x = firework_data["location"]
	
	# Dynamically add path based on firework_data
	var path_type_name = firework_data.get("path_scene", "path")  # defaults to "path"
	add_path(path_type_name)
	
	# Add all blast scenes
	add_components(components)
		
	
func fire_blast(pos):
	# Fire every blast node
	for blast in blast_nodes:
		blast.position.y = pos.y
		blast.fire()
	var fw_col = Color(firework_data["outer_layer_color"][0],firework_data["outer_layer_color"][1],firework_data["outer_layer_color"][2],1)
	pos.x = position.x
	burstLight.spawn_burst_light(pos, fw_col) #set pos and col  
	
	timer.start()

#path timer starts when fw is instantiated -signal-> switch state to FIRING- start explosion particle effect
func _on_path_path_timeout(pos) -> void:
	current_state = state.FIRING
	path.queue_free() #remove path node of this fw instance (not from the scene file (globally))
	fire_blast(pos)

func _on_lifetime_timeout():
	queue_free() #removes firework
