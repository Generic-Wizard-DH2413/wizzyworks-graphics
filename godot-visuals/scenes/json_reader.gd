extends Node
var path = "res://json_fireworks/"
var checked = false
var shapes = [] #qeue of fw data (dict containing location and points) to be processed inside root node (TestingEnv)
				#AlQ: perhaps change this name to pending_fw_data or something?

#Constantly:
#iterate through the json files inside the json directory and parse json data
func _process(delta):
	if !checked: #only check once (?But why is this inside process() then?)
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "": #continue untill all json files are read in directory
				if dir.current_is_dir():
					print("Found directory: " + file_name)
				else:
					print("Found file: " + file_name)
					var json_as_text = FileAccess.get_file_as_string(path+file_name)
					var json_as_dict = JSON.parse_string(json_as_text) #json is a dictionary with fw data
					if json_as_dict:
						create_shape(file_name,json_as_dict)
				file_name = dir.get_next() #nxt json file to be read
		else:
			print("An error occurred when trying to access the path.")
		checked = true

#append json info dict into the shapes qeue
func create_shape(name, json):
	var points = []
	if(json.get("points") != null && json.get("location") != null):
		for p in json.get("points"): 
			points.append(Vector3(p[0],p[1],0)) #add z-axis since we are in 3D.
		shapes.append({"location": json.get("location"),"points":points}) #{starting location, shape of fw}
