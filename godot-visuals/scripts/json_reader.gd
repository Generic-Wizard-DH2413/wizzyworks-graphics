extends Node
var path = "res://json_fireworks/"
var processed_dir_name = "processed/"
var firework_show_dir_name = "firework_show/"
var checked = false
var shapes = [] #qeue of fw data (dict containing location and points) to be processed inside root node (TestingEnv)
				#AlQ: perhaps change this name to pending_fw_data or something?
#@export var firework_data: Resource
var pending_data = []
var firework_show_data = []

#Constantly:
#iterate through the json files inside the json directory and parse json data
func _process(delta):
	var dir = DirAccess.open(path)
	var processed_dir = DirAccess.open(path + processed_dir_name)
	var firework_show_dir = DirAccess.open(path + firework_show_dir_name)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "": #continue untill all json files are read in directory
			if dir.current_is_dir():
				pass
			else:
				print("Found file: " + file_name)
				var json_as_text = FileAccess.get_file_as_string(path+file_name)
				var json_as_dict = JSON.parse_string(json_as_text) #json is a dictionary with fw data
				processed_dir.copy(path + file_name, path + processed_dir_name + file_name)
				firework_show_dir.copy(path + file_name, path + firework_show_dir_name + file_name)
				
				dir.remove(path+file_name)
				if json_as_dict:
					read_data(json_as_dict)
					save_to_firework_show(json_as_dict)
			file_name = dir.get_next() #nxt json file to be read
	else:
		print("An error occurred when trying to access the path.")

func save_to_firework_show(json_as_dict):
	if json_as_dict is Array:
		for item in json_as_dict:
			firework_show_data.append(item)
	# Flaten and add to dir

# Called from firework_show scene
func clear_firework_show_json(): 
	var firework_show_dir = DirAccess.open(path + firework_show_dir_name)
	for file in firework_show_dir.get_files():
		print("Deleted file {0}", file)
		firework_show_dir.remove(file)

# A folder with files each one containing a list of fireworks
# Fire two fireworks at a time? 
# How should it pick the fireworks?
	# Two at a time
	# If it is not enough, pick from another folder (Placeholder fireworks we have created)
	

#For testing purposes
func create_json():
	pass

# Gets all data from the json (if there is any)
func read_data(json):
	if json is Array:
		# Append the entire list of fireworks
		pending_data.append(json)
	else:
		# Handle single firework data for backward compatibility, wrap in list
		pending_data.append([json])


#append json info dict into the shapes qeue
func create_shape(name, json):
	var points = []
	if(json.get("points") != null && json.get("location") != null):
		for p in json.get("points"): 
			points.append(Vector3(p[0],p[1],0)) #add z-axis since we are in 3D.
		shapes.append({"location": json.get("location"),"points":points}) #{starting location, shape of fw}
