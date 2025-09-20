extends Node3D
var outer_particles
var inner_particles
var figure_scene = preload("res://scenes/figure.tscn") #AlQ: redundant since its already a child node to the Blast node?
var figure
var timer
var image

func _ready():
	outer_particles = get_node("GPUParticles3D")
	inner_particles = get_node("DrawingParticles")
	timer = get_node("BlastTimer")
	randomize()
	set_rand_color()
	image = texture.get_image()
	create_emission_points()
	inner_particles.position.x -= 50/2
	inner_particles.position.y -= 50/2

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
	outer_particles.process_material.set_shader_parameter("color_value", color)
	
	
#emit generic blast particles and also figure shaped particles. Timer to remove this node (and its particles) starts.
func fire():
	outer_particles.emitting = true
	inner_particles.emitting = true
	if(figure != null):
		figure.fire()
	timer.start()
	#get_node("FireworkBlast").play()
	

@export var texture: Texture2D
@export var mesh: MeshInstance3D
@export var emission_threshold := 0.5
@export var num_points := 1000
@export var sample_density: int = 4
@export var img_scale: float = 0.01

func create_emission_points():
	var emission_points = []
	for y in range(0, image.get_height(), sample_density):
		for x in range(0, image.get_width(), sample_density):
			var color = image.get_pixel(x, y)
			
			# Customize for our different colors
			var brightness = color.r * 0.5 + color.g * 0.5 + color.b * 0.5

			if brightness > emission_threshold:
					# Convert pixel to 3D space (flat plane projection)
				var pos = Vector3(	float(x)/image.get_width(),
									float(y)/image.get_height(),
									0.0)
				emission_points.append(pos)
	
	var point_count = emission_points.size()
	#print(emission_points)
	var emission_image = Image.create(point_count, 1, false, Image.FORMAT_RGBF)

	for i in range(point_count):
		var p = emission_points[i]
		# Encode position as RGB (floating point)
		emission_image.set_pixel(i, 0, Color(p.x, p.y, p.z))
	
	#inner_particles.process_material.emission_shape = GPUParticles3DMaterial.EMISSION_SHAPE_POINTS
	var emission_texture = ImageTexture.create_from_image(emission_image)
	inner_particles.process_material.emission_point_texture = emission_texture
	inner_particles.process_material.emission_point_count = point_count
	
