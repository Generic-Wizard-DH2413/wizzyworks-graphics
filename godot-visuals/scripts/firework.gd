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
			

func set_parameters(firework_data):
	# Store firework data
	self.firework_data = firework_data
	
	var components = []
	
	# Attach outer_layer and inner_layer
	if firework_data.get("outer_layer"):
		components.append(firework_data.get("outer_layer"))
	if firework_data.get("inner_layer") && firework_data.get("inner_layer") != "none":
		components.append("drawing")
	
	# Attach nodes
	path = get_node("Path")
	burstLight = get_node("BurstLight3D")
	timer = get_node("Lifetime")
	
	# when instantiated, directly start  launching
	current_state = state.LAUNCHING 
	
	# Set start position for th particle
	particle_pos = Vector3(0,-150, 0)
	position.x = firework_data["location"]
	path.position = particle_pos 
	
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
