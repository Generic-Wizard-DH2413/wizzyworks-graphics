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

var center_image_x
var center_image_y


var firework_data = {}

func _ready():
	pass

func set_color():
	var color = Vector4(firework_data["color0"][0],firework_data["color0"][1],firework_data["color0"][2],1)
	outer_particles.process_material.set_shader_parameter("color_value", color)

# Sets random color for the firework
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
	get_node("FireworkBlast").play()

func set_outer_blast_data(type):
	match(type):
		"sphere":
			outer_particles.process_material.set_shader_parameter("sphere",true);
			outer_particles.process_material.set_shader_parameter("sphere_force", 2.5)
			outer_particles.process_material.set_shader_parameter("air_resistance", 1.5)
			outer_particles.process_material.set_shader_parameter("gravity", Vector3(0,1.3,0))
			outer_particles.process_material.set_shader_parameter("life_time", 4.0)
			
			
		"willow":
			outer_particles.process_material.set_shader_parameter("sphere",true);
			outer_particles.process_material.set_shader_parameter("sphere_force", 2.0)
			outer_particles.process_material.set_shader_parameter("air_resistance", 0.98)
			outer_particles.process_material.set_shader_parameter("gravity", Vector3(0,1.8,0))
			outer_particles.process_material.set_shader_parameter("life_time", 9.0)
			
func set_parameters(firework_data):
	self.firework_data = firework_data
	if(firework_data["inner_layer"] == "random"):
		image = get_random_image().get_image()
	else:
		for file_name in DirAccess.get_files_at("res://json_fireworks/firework_drawings/"):
			if (file_name == firework_data["inner_layer"]+".png"):
				image = Image.load_from_file("res://json_fireworks/firework_drawings/" + file_name)				
				print(image)
	outer_particles = get_node("OuterBlastParticles")
	inner_particles = get_node("DrawingParticles")
	timer = get_node("BlastTimer")
	
	set_outer_blast_data("sphere")
	
	randomize()
	set_color()
	
	create_emission_points()

# Get random image from the fireworks folder (not safe from errors)
func get_random_image():
	var path = "res://json_fireworks/permanent_firework/"
	var dir = DirAccess.open(path)
	var images = dir.get_files()
	# Get random file (folder contains png + import)
	var random_int = randi_range(0,(images.size()-1)/2)
	return(load(path + "firework_drawing" + str(random_int) + ".png"))

# Creates an emission point image and passes it to the material
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
			var brightness = color.r * 1.0 + color.g * 1.0 + color.b * 1.0

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
	var center_x = min_x +float((max_x - min_x)/2)
	var center_y = min_y +float((max_y - min_y)/2)
	
	center_image_x = min_x + center_x
	center_image_y = min_x + center_y
	
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
	
	
