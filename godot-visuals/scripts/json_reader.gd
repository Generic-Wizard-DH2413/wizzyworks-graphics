extends Node
var path = "res://json_fireworks/"
var processed_dir_name = "processed/"
var checked = false
var shapes = [] #qeue of fw data (dict containing location and points) to be processed inside root node (TestingEnv)
				#AlQ: perhaps change this name to pending_fw_data or something?
#@export var firework_data: Resource
var pending_data = []

#Constantly:
#iterate through the json files inside the json directory and parse json data
func _process(delta):
	var dir = DirAccess.open(path)
	var processed_dir = DirAccess.open(path + processed_dir_name)
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
				dir.remove(path+file_name)
				if json_as_dict:
					read_data(json_as_dict)
			file_name = dir.get_next() #nxt json file to be read
	else:
		print("An error occurred when trying to access the path.")

#For testing purposes
func create_json():
	pass

# Gets all data from the json (if there is any)
func read_data(json):
	var data_titles = ["outer_layer", "inner_layer", "outer_layer_color", "outer_layer_second_color", "force", "angle", "location"]
	var firework_data = {}
	
	# checks every item in the json, and creates a new key value pair in the firework_data dictionary
	for i in data_titles.size():
		var val = json.get(data_titles[i])
		if val != null: firework_data[data_titles[i]] = val
	
	# Loads the firework
	pending_data.append(firework_data)


#append json info dict into the shapes qeue
func create_shape(name, json):
	var points = []
	if(json.get("points") != null && json.get("location") != null):
		for p in json.get("points"): 
			points.append(Vector3(p[0],p[1],0)) #add z-axis since we are in 3D.
		shapes.append({"location": json.get("location"),"points":points}) #{starting location, shape of fw}
