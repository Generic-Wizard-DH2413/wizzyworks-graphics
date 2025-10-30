extends Node3D
var going_up = true;
var going_down = false;
var end_y = -30.0
var start_y = -50.0
var speed = 0.1

func _ready():
	position.y = start_y
	position.z = 320.0
	position.x = 0.0

func _physics_process(delta):
	if(going_up):
		position.y += speed * delta * 60
		if(position.y >= end_y):
			going_up = false
	if(going_down):
		position.y -= speed * delta * 60
		if(position.y <= start_y):
			going_down = false
			queue_free()

func go_down():
	going_down = true
	
