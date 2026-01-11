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

func _ready():
	var dir = DirAccess.open(path)
	if dir:
		if not dir.dir_exists(processed_dir_name):
			dir.make_dir(processed_dir_name)
		if not dir.dir_exists(firework_show_dir_name):
			dir.make_dir(firework_show_dir_name)
	else:
		print("Main directory does not exist.")

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

func save_firework_show_as_json():
	var json_string = JSON.stringify(firework_show_data)
	var firework_show_dir = DirAccess.open(path + firework_show_dir_name)
	var current_firework_show_name = "firework_show_"
	var files := []
	firework_show_dir.list_dir_begin()
	var file_name = firework_show_dir.get_next()
	while file_name != "":
		if not firework_show_dir.current_is_dir():
			files.append(file_name)
		file_name = firework_show_dir.get_next()
	firework_show_dir.list_dir_end()

	if files.is_empty():
		current_firework_show_name = current_firework_show_name + "0.json"
	else:
		files.sort()  # sorts alphabetically
		var last = files[files.size() - 1]
		var base_name = last.trim_suffix(".json")
		var parts = base_name.split("_")
		var number_str = parts[parts.size() - 1]
		var num = int(number_str)
		current_firework_show_name = current_firework_show_name + str(num+1) + ".json"

	save_json_string_to_file(firework_show_dir_name, current_firework_show_name, json_string)

func save_json_string_to_file(folder_path: String, file_name: String, json_string: String) -> void:
	# Combine folder path and file name
	var file_path = folder_path.path_join(file_name)
	# Open file for writing
	var file := FileAccess.open(path + file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()

# Called from firework_show scene
func clear_firework_show_json():
	firework_show_data = []
	#var firework_show_dir = DirAccess.open(path + firework_show_dir_name)
	#for file in firework_show_dir.get_files():
		#print("Deleted file {0}", file)
		#firework_show_dir.remove(file)

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
	await get_tree().create_timer(10.5).timeout
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
