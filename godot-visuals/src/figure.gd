extends Node3D
var points =  PackedVector3Array([Vector3(0,0,0)])
var current_point = 0
var speed = 100
var prev_pos = Vector3(0,0,0)
var fired = false
var done = false
var destination = Vector3(0,0,0)
var scaling = 20
var particles

func _ready():
	particles = get_node("ShapedPathParticles")

func _physics_process(delta):
	if (!fired):
		return
	if done:
		fade_away()
	position += position.direction_to(destination) * speed * delta
	
	if((position-destination).length() < (0.01*speed)):
		current_point += 1
		if(current_point >= points.size()):
			# reset
			current_point = 0
		destination = points[current_point]*scaling

	prev_pos = position
	
func fire():
	particles.emitting = true
	destination = points[current_point]*scaling
	fired = true
	
func fade_away():
	pass

func set_shape(shape):
	var move_vector = position - shape[0]
	for p in shape:
		p = p + move_vector
	points = shape
	

	
