extends Node3D
var particles
var figure_scene = preload("res://scenes/figure.tscn") #AlQ: redundant since its already a child node to the Blast node?
var figure
var timer

func _ready():
	particles = get_node("GPUParticles3D")
	timer = get_node("BlastTimer")
	randomize()
	set_rand_color()

func set_shape(points):
	#figure = figure_scene.instantiate()  #AlQ: again, cant we use our child node?
	#figure.set_shape(points)
	#add_child(figure) #AlQ: again, possibly redundant?
	pass

func set_rand_color():
	var r = randf();
	var g = randf();
	var b = randf();

	var color = Vector4(r,g,b,1.0);
	particles.process_material.set_shader_parameter("color_value", color);
	
	
#emit generic blast particles and also figure shaped particles. Timer to remove this node (and its particles) starts.
func fire():
	particles.emitting = true
	if(figure != null):
		figure.fire()
	timer.start()
	get_node("FireworkBlast").play()
