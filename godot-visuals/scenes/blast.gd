extends Node3D
var particles
var shape
var timer

func _ready():
	particles = get_node("GPUParticles3D")
	shape = get_node("ShapedParticles")
	timer = get_node("BlastTimer")
	

func fire():
	particles.emitting = true
	shape.emitting = true
	timer.start()
