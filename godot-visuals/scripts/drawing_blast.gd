extends Node3D

var image
var center_image_x
var center_image_y

var particles

# Used for emission point generation
@export var texture: Texture2D
@export var sample_density: int = 4
@export var emission_threshold := 0.5

var firework_data = {}

func set_parameters(firework_data):
	# Store firework data
	self.firework_data = firework_data
	
	# If drawing is not passed through the json, give it a random drawing
	if(firework_data["inner_layer"] == "random"):
		image = get_random_image().get_image()
	else:
		for file_name in DirAccess.get_files_at("res://json_fireworks/firework_drawings/"):
			if (file_name == firework_data["inner_layer"]+".png"):
				image = Image.load_from_file("res://json_fireworks/firework_drawings/" + file_name)				
				print(image)
	
	# Attach the particle generator
	particles = get_node("DrawingParticles")
	
	# Turn the drawing into emission points, passed to the generator
	create_emission_points()
	
	# Center the image
	position.x -=  center_image_x;
	position.y -=  center_image_y;
	

func fire():
	particles.emitting = true

# Get random image from the fireworks folder
# Exists for debugging purposes (creating fireworks without phone)
func get_random_image():
	var path = "res://json_fireworks/permanent_firework/"
	var dir = DirAccess.open(path)
	var images = dir.get_files()
	
	# Get random file from folder. Folder contains png + import 
	# for every image, thus files*2-1.
	var random_int = randi_range(0,(images.size()/2)-1)
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
	particles.process_material.emission_point_texture = emission_texture
	particles.process_material.emission_color_texture = color_texture
	particles.process_material.emission_point_count = point_count
	
