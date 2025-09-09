extends Node3D
var particles
var figure_scene = preload("res://scenes/figure.tscn")
var figure
var timer

func _ready():
	particles = get_node("GPUParticles3D")
	timer = get_node("BlastTimer")
	
func set_shape(points):
	figure = figure_scene.instantiate()
	figure.set_shape(points)
	add_child(figure)

func fire():
	particles.emitting = true
	print(figure)
	if(figure != null):
		figure.fire()
	timer.start()
