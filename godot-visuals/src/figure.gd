#A scene for particle effect following the shape that the user draws
extends Node3D
var points =  PackedVector3Array([Vector3(0,0,0)]) #points of shape
var current_point = 0 #idx of next target in points
var speed = 100
var prev_pos = Vector3(0,0,0) #AlQ: unused?
var fired = false
var done = false  #AlQ: unused?
var destination = Vector3(0,0,0) #moving towards nxt point
var scaling = 20
var particles

func _ready():
	particles = get_node("ShapedPathParticles")

#Constantly check for fire=true--> update position according to shape until done 
func _physics_process(delta):
	if (!fired):
		return
	if done:
		fade_away()
	#move towards next shape point. Updating parant node pos will also move child node (particles)
	position += position.direction_to(destination) * speed * delta
	#if close enough, update to the next destination shape point
	if((position-destination).length() < (0.01*speed)):
		current_point += 1 #incr point idx
		if(current_point >= points.size()): #re-loop from first idx
			# reset
			current_point = 0
		destination = points[current_point]*scaling

	prev_pos = position
	
#called from blast sc
func fire():
	particles.emitting = true
	position = points[current_point]*scaling
	current_point += 1
	destination = points[current_point]*scaling
	fired = true
	
func fade_away():
	pass

#Called from testing_env sc -->firework sc--> blast sc--> here
func set_shape(shape):
	var move_vector = position - shape[0]
	for p in shape:
		p = p + move_vector
	points = shape
	

	
