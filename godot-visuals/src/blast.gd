extends Node3D
var outer_particles
var inner_particles
var figure_scene = preload("res://scenes/figure.tscn") #AlQ: redundant since its already a child node to the Blast node?
var figure
var timer
var image

# Used for emission point generation
@export var texture: Texture2D
@export var mesh: MeshInstance3D
@export var emission_threshold := 0.5
@export var sample_density: int = 4

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

func create_emission_points():
	var emission_points = []
	var color_points = []
	var min_x = image.get_width()
	var max_x = - image.get_width()
	var min_y = image.get_height()
	var max_y = - image.get_height()
	
	for y in range(0, image.get_height(), sample_density):
		for x in range(0, image.get_width(), sample_density):
			
			var rand_x = x
			var rand_y = y
			
			# Random values to not get perfect distance between sampled points
			if(x < image.get_width() - sample_density):
				rand_x += randi_range(0,sample_density-1)
			if(y < image.get_height() - sample_density):
				rand_y += randi_range(0,sample_density-1)
			
			# Retrieve the color at the location
			var color = image.get_pixel(rand_x, rand_y)
			
			# Identify is there is a color (non-black). Values can probably be lowered
			var brightness = color.r * 0.5 + color.g * 0.5 + color.b * 0.5

			# If there is a color
			if brightness > emission_threshold:
				
				# Scale the values from 0 to 1.
				var scaled_x = float(rand_x)/image.get_width();
				var scaled_y = -float(rand_y)/image.get_height();
				
				# Check new min and max of the figure
				if x < min_x: min_x = scaled_x
				if y < min_y: min_y = scaled_y
				if x > max_x: max_x = scaled_x
				if y > max_y: max_y = scaled_y
				
				# Add the point to emission_points, and its color to color_points.
				var pos = Vector3(	scaled_x,
									scaled_y,
									0.0)
				emission_points.append(pos)
				color_points.append(color)
				
	
	# Get the number of points
	var point_count = emission_points.size()

	# Create the emission image and color image passed to the particle generator
	var emission_image = Image.create(point_count, 1, false, Image.FORMAT_RGBF)
	var color_image = Image.create(point_count, 1, false, Image.FORMAT_RGBF)

	# Get the center of the figures
	var center_x = min_x +float((max_x - min_x)/2) - 0.5
	var center_y = min_y +float((max_y - min_y)/2) - 0.5
	
	# For every point in the figure
	for i in range(point_count):
		var p = emission_points[i]
		var c = color_points[i]
		
		# Encode position as RGB (floating point), and move towards the center
		emission_image.set_pixel(i, 0, Color(p.x - center_x, p.y - center_y, p.z))
		color_image.set_pixel(i, 0, c)
	
	# Create textures from the images
	var emission_texture = ImageTexture.create_from_image(emission_image)
	var color_texture = ImageTexture.create_from_image(color_image)
	
	# Pass all values to the particle generator
	inner_particles.process_material.emission_point_texture = emission_texture
	inner_particles.process_material.emission_color_texture = color_texture
	inner_particles.process_material.emission_point_count = point_count
	
