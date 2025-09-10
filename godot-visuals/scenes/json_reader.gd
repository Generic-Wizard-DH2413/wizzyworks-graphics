extends Node
var path = "res://json_fireworks/"
var checked = false
var shapes = []

func _process(delta):
	if !checked:
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					print("Found directory: " + file_name)
				else:
					print("Found file: " + file_name)
					var json_as_text = FileAccess.get_file_as_string(path+file_name)
					var json_as_dict = JSON.parse_string(json_as_text)
					if json_as_dict:
						create_shape(file_name,json_as_dict)
				file_name = dir.get_next()
		else:
			print("An error occurred when trying to access the path.")
		checked = true
	
func create_shape(name, json):
	print(json.get("location"))
	var points = []
	if(json.get("points") != null && json.get("location") != null):
		for p in json.get("points"):
			points.append(Vector3(p[0],p[1],p[2]))
		shapes.append({"location": json.get("location"),"points":points})
