extends Node3D
#member variables (unique for per instance)
var path
var blast
var particle_pos
enum state {LAUNCHING, FIRING}
var current_state

func _ready():
	path = get_node("Path")
	blast = get_node("Blast")
	current_state = state.LAUNCHING #when instantiated, directly start  launching
	particle_pos = Vector3(0,-50, 0)
	path.position = particle_pos 
	blast.position = particle_pos 

#Constantly make fw go upwards if launching
func _physics_process(delta):
	if(current_state == state.LAUNCHING):
		particle_pos.y = particle_pos.y + 1
		path.position = particle_pos

#is called from the testing_env scene	
#pass shape points to blast scene
func generate_shape(points):
	if(blast != null): #AlQ: dont happen?
		blast.set_shape(points)

#path timer starts when fw is instantiated -signal-> switch state to FIRING- start explosion particle effect
func _on_path_timer_timeout():
	current_state = state.FIRING
	path.queue_free() #remove path node of this fw instance (not from the scene file (globally))
	blast.position = particle_pos
	blast.fire()


func _on_blast_timer_timeout():
	blast.queue_free() #remove blast node of this fw instance (not from the scene file)
