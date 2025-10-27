extends Node3D
var outer_particles
var timer

var firework_data = {}

func set_parameters(firework_data):
	self.firework_data = firework_data
	outer_particles = get_node("OuterBlastParticles")
	timer = get_node("BlastTimer")
	
	set_color()


func _ready():
	pass

func set_color():
	var color = Color(firework_data["outer_layer_color"][0],firework_data["outer_layer_color"][1],firework_data["outer_layer_color"][2],1)
	print( "willow blast set color to: ", color)
	outer_particles.process_material.set_color(color)
	var trail = get_node("TrailGlitter")
	trail.process_material.set_color(color)

# Sets random color for the firework
func set_rand_color():
	var r = randf();
	var g = randf();
	var b = randf();

	var color = Color(r,g,b,1.0);
	outer_particles.process_material.set_color(color);
	var trail = get_node("TrailGlitter")
	trail.process_material.set_color(color)
	
#emit generic blast particles and also figure shaped particles. Timer to remove this node (and its particles) starts.
func fire():
	outer_particles.emitting = true
	await get_tree().create_timer(0.35).timeout
	get_node("FireworkBlast").play()
