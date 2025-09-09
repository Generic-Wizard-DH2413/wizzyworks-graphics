extends Node3D
var path
var blast
var particle_pos
enum state {LAUNCHING, FIRING}
var current_state

func _ready():
	path = get_node("Path")
	blast = get_node("Blast")
	current_state = state.LAUNCHING
	particle_pos = Vector3(0,-50,-100)
	path.position = particle_pos
	blast.position = particle_pos

func _physics_process(delta):
	if(current_state == state.LAUNCHING):
		particle_pos.y = particle_pos.y + 1
		path.position = particle_pos
		
func generate_shape(points):
	pass

func _on_path_timer_timeout():
	print("yeh")
	current_state = state.FIRING
	path.queue_free()
	blast.position = particle_pos
	blast.fire()


func _on_blast_timer_timeout():
	blast.queue_free()
	pass # Replace with function body.
