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
		var c_path = "res://scenes/" + c + ".tscn"
		if ResourceLoader.exists(c_path) :
			var node = ResourceLoader.load(c_path).instantiate() 
			add_child(node)
			blast_nodes.append(node)

func set_parameters(firework_data, components):
	path = get_node("Path")
	current_state = state.LAUNCHING #when instantiated, directly start  launching
	particle_pos = Vector3(100,-150, 0)
	path.position = particle_pos 
	self.firework_data = firework_data
	add_components(components)
	for blast in blast_nodes:
		blast.set_parameters(firework_data)
		blast.position = particle_pos 
	position.x = firework_data["location"]
	burstLight = get_node("BurstLight3D")
	timer = get_node("Lifetime")
	
func fire_blast(pos):
	for blast in blast_nodes:
		blast.position = pos
		blast.fire()
	var fw_col = Color(firework_data["outer_layer_color"][0],firework_data["outer_layer_color"][1],firework_data["outer_layer_color"][2],1)
	#burstLight.spawn_burst_light(pos, fw_col) #set pos and col  
	timer.start()

func _on_blast_timer_timeout():
	blast.queue_free() #remove blast node of this fw instance (not from the scene file)

#path timer starts when fw is instantiated -signal-> switch state to FIRING- start explosion particle effect
func _on_path_path_timeout(pos) -> void:
	current_state = state.FIRING
	path.queue_free() #remove path node of this fw instance (not from the scene file (globally))
	fire_blast(pos)

func _on_lifetime_timeout():
	queue_free() #removes firework
