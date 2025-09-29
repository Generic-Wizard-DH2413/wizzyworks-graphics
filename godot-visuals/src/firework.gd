extends Node3D
#member variables (unique for per instance)
var path
var blast
var particle_pos
enum state {LAUNCHING, FIRING}
var current_state

# Contains all unique data of the firework
var firework_data = {}

func _ready():
	pass

#Constantly make fw go upwards if launching
func _physics_process(delta):
	pass

func set_parameters(firework_data):
	path = get_node("Path")
	current_state = state.LAUNCHING #when instantiated, directly start  launching
	particle_pos = Vector3(100,-150, 0)
	path.position = particle_pos 
	self.firework_data = firework_data
	blast = get_node("Blast")
	blast.set_parameters(firework_data)
	position.x = firework_data["location"]
	blast.position = particle_pos 

func _on_blast_timer_timeout():
	blast.queue_free() #remove blast node of this fw instance (not from the scene file)

#path timer starts when fw is instantiated -signal-> switch state to FIRING- start explosion particle effect
func _on_path_path_timeout(pos) -> void:
	current_state = state.FIRING
	path.queue_free() #remove path node of this fw instance (not from the scene file (globally))
	blast.position = pos
	blast.fire()
