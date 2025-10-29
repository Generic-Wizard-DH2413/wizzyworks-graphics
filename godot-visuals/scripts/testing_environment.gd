extends Node3D
var firework = preload("res://scenes/firework.tscn")
var json_reader
var camera
var canvas
@export_range(0, 1) var ratio = 0.5

# Window and screen setup
var mode = ProjectSettings.get_setting("display/window/size/mode")
@export var screen_width = DisplayServer.screen_get_size().x if mode == 3 else 1920 #pixel_width
@export var screen_height = DisplayServer.screen_get_size().y if mode == 3 else 1080 #pixel_height
var min_ratio
var max_ratio
var sky_width
var interval
var half_interval

# Firework show state
var x_pos: float = 0
var direction: int = 1
var firework_show_index: int = 0
var firework_show_timer: Timer
var firework_show: Node3D

# Countdown UI
var countdown_layer
var countdown_label
var countdown_bar
var countdown_initial_height: float = 0.0
var countdown_initial_width: float = 0.0
var countdown_initial_time: float = 0.0

# Show control
var firework_show_playing: bool = false
var countdown_active: bool = false
var current_show_mode: String = "audio" # alternates between "audio" and "json"
@export var show_mode: String = "json" # initial mode
@export var fire_interval = 3.0
@export var firework_show_delay = 1200.0

# JSON show variables
var show_events = []
var show_audio_player: AudioStreamPlayer
var json_show_path: String = "" # will be set by shuffle system

# Shuffle system for music and shows
var audio_music_files: Array = []
var audio_music_shuffle_index: int = 0
var json_show_files: Array = []
var json_show_shuffle_index: int = 0
var last_played_music_name: String = "" # Track last music to avoid repeats


func _ready():
	current_show_mode = show_mode
	camera = get_node("Camera3D")
	json_reader = get_node("JsonReader")
	canvas = get_node("CanvasLayer")
	countdown_layer = get_node_or_null("CountdownLayer")
	if countdown_layer:
		countdown_label = countdown_layer.get_node_or_null("CountdownLabel")
		countdown_bar = countdown_layer.get_node_or_null("CountdownBar")
		if countdown_bar:
			countdown_initial_height = countdown_bar.size.y
			countdown_initial_width = countdown_bar.size.x
		_initialize_countdown_ui()

	min_ratio = (1-ratio)/2
	max_ratio = ratio + (1-ratio)/2

	# Move debug lines
	canvas.get_node("left_line").position.x = min_ratio * screen_width
	canvas.get_node("right_line").position.x = max_ratio * screen_width

	calculate_distances()
	var firework_show_scene = load("res://scenes/firework_show.tscn")
	firework_show = firework_show_scene.instantiate()
	add_child(firework_show)
	var detector = firework_show.get_node("Node3D")
	detector.drum_hit.connect(onDetect)
	
	# Initialize shuffle systems
	_load_and_shuffle_audio_music()
	_load_and_shuffle_json_shows()
	
	_setup_firework_show_timer()


# Load all music files from firework_music folder and shuffle them
func _load_and_shuffle_audio_music():
	audio_music_files.clear()
	var dir = DirAccess.open("res://assets/sounds/firework_music")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".mp3") or file_name.ends_with(".ogg") or file_name.ends_with(".wav")):
				audio_music_files.append("res://assets/sounds/firework_music/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	audio_music_files.shuffle()
	audio_music_shuffle_index = 0
	print("[DEBUG] Loaded " + str(audio_music_files.size()) + " audio music files and shuffled them.")


# Load all JSON show files and shuffle them
func _load_and_shuffle_json_shows():
	json_show_files.clear()
	var dir = DirAccess.open("res://json_fireworks/json_firework_shows")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				json_show_files.append("res://json_fireworks/json_firework_shows/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	json_show_files.shuffle()
	json_show_shuffle_index = 0
	print("[DEBUG] Loaded " + str(json_show_files.size()) + " JSON show files and shuffled them.")


# Get next audio music file (with reshuffle when all played)
func _get_next_audio_music() -> String:
	if audio_music_files.is_empty():
		push_error("No audio music files found!")
		return ""
	
	var music_path = audio_music_files[audio_music_shuffle_index]
	var music_name = music_path.get_file().get_basename()
	
	# Skip if same as last played (avoid back-to-back repeats)
	if music_name == last_played_music_name and audio_music_files.size() > 1:
		print("[DEBUG] Skipping " + music_name + " (same as last played)")
		audio_music_shuffle_index += 1
		if audio_music_shuffle_index >= audio_music_files.size():
			audio_music_files.shuffle()
			audio_music_shuffle_index = 0
		music_path = audio_music_files[audio_music_shuffle_index]
		music_name = music_path.get_file().get_basename()
	
	audio_music_shuffle_index += 1
	if audio_music_shuffle_index >= audio_music_files.size():
		print("[DEBUG] All audio music played, reshuffling...")
		audio_music_files.shuffle()
		audio_music_shuffle_index = 0
	
	last_played_music_name = music_name
	return music_path


# Get next JSON show file (with reshuffle when all played)
func _get_next_json_show() -> String:
	if json_show_files.is_empty():
		push_error("No JSON show files found!")
		return ""
	
	var show_path = json_show_files[json_show_shuffle_index]
	var show_name = show_path.get_file().get_basename()
	
	# Skip if same as last played music (avoid back-to-back repeats)
	if show_name == last_played_music_name and json_show_files.size() > 1:
		print("[DEBUG] Skipping " + show_name + " (same as last played)")
		json_show_shuffle_index += 1
		if json_show_shuffle_index >= json_show_files.size():
			json_show_files.shuffle()
			json_show_shuffle_index = 0
		show_path = json_show_files[json_show_shuffle_index]
		show_name = show_path.get_file().get_basename()
	
	json_show_shuffle_index += 1
	if json_show_shuffle_index >= json_show_files.size():
		print("[DEBUG] All JSON shows played, reshuffling...")
		json_show_files.shuffle()
		json_show_shuffle_index = 0
	
	last_played_music_name = show_name
	return show_path
	

# Loads and prepares a JSON firework show
func load_json_firework_show(path: String):
	print("[DEBUG] Entered load_json_firework_show with path: " + str(path))
	var json_text = FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(json_text)
	if data:
		show_events = data["events"]
		var sound_file_name = data["sound_file_name"]
		# Try firework_music folder first, then fall back to sounds folder
		var sound_path = "res://assets/sounds/firework_music/" + sound_file_name
		if not FileAccess.file_exists(sound_path):
			sound_path = "res://assets/sounds/" + sound_file_name
		print("[DEBUG] JSON show loaded. Events: " + str(show_events.size()) + ", Sound: " + sound_path)
		show_audio_player = AudioStreamPlayer.new()
		add_child(show_audio_player)
		show_audio_player.stream = load(sound_path)
	else:
		push_error("Failed to load JSON show from " + path)
	

func onDetect(nr):
	
	var firework_data = {}
	x_pos += 40 * direction
	if x_pos >= 250:
		x_pos = 250
		direction = -1
	elif x_pos <= -250:
		x_pos = -250
		direction = 1
	for i in range(nr):
		if (firework_show_index+1 > json_reader.firework_show_data.size()):
			firework_show_index = 0
		if (json_reader.firework_show_data.size() == 0):
			create_mock_fireworks()
		if (json_reader.firework_show_data[firework_show_index] != null):
			firework_data = json_reader.firework_show_data[firework_show_index]
			var x_poss = x_pos + (i * 45 * direction)
			firework_data["location"] = x_poss
			
			firework_data["path_speed"] = 1
			firework_data["path_sound_path"] = null
			firework_data["use_variation"] = true
			create_firework(firework_data)
		else:
			create_debug_firework(firework_data)

		firework_show_index+=1
	#create_debug_firework(firework_data)
#constantly check for json files
#AlQ: perhaps we can instead receive signals from JsonReader instead of constant looking? not superimportant currently though

func _process(_delta):
		# Handle pending fireworks from JsonReader
		while json_reader.pending_data.size() > 0:
			var firework_list = json_reader.pending_data.pop_front()
			for i in range(firework_list.size()):
				if i == 0:
					var data = firework_list[0]
					data["location"] = data["location"] * half_interval
					create_firework(data)
				else:
					var timer = Timer.new()
					timer.wait_time = fire_interval * i
					timer.one_shot = true
					timer.set_meta("firework_data", firework_list[i])
					add_child(timer)
					timer.connect("timeout", func(): _on_individual_timer_timeout(timer))
					timer.start()
		_update_countdown_ui()

		# Show logic
		if firework_show_playing:
			if current_show_mode == "json" and show_audio_player and show_audio_player.playing:
				var current_time = show_audio_player.get_playback_position()
				while show_events.size() > 0 and current_time >= show_events[0]["time"]:
					var event = show_events.pop_front()
					print("[DEBUG] Processing event: " + str(event))
					fire_event(event)
				# End show when audio finishes and events are done
				if show_events.is_empty() and not show_audio_player.playing:
					print("[DEBUG] JSON show finished - events empty and audio stopped.")
					_end_current_show()
			elif current_show_mode == "json" and show_audio_player:
				# Audio has stopped, check if we should end
				print("[DEBUG] JSON mode but audio not playing. Events left: " + str(show_events.size()) + ", Audio playing: " + str(show_audio_player.playing))
				if show_events.is_empty():
					print("[DEBUG] JSON show finished - no events left and audio stopped.")
					_end_current_show()
			elif current_show_mode == "audio":
				# End show when audio finishes
				if show_audio_player and not show_audio_player.playing:
					_end_current_show()

func _on_individual_timer_timeout(timer):
	var data = timer.get_meta("firework_data")
	data["location"] = data["location"] * half_interval
	create_firework(data)
	timer.queue_free()


# Setup countdown timer and connect signals
func _setup_firework_show_timer():
		firework_show_timer = Timer.new()
		firework_show_timer.wait_time = firework_show_delay
		firework_show_timer.one_shot = true
		add_child(firework_show_timer)
		firework_show_timer.connect("timeout", Callable(self, "_on_firework_show_timer_timeout"))
		if firework_show:
			firework_show.connect("countdown_restart_requested", Callable(self, "_on_firework_show_restart_requested"))
		_start_firework_show_countdown()


# Start countdown before show
func _start_firework_show_countdown():
		if firework_show_timer:
			firework_show_timer.wait_time = firework_show_delay
			firework_show_timer.start()
		countdown_initial_time = firework_show_delay
		firework_show_playing = false
		countdown_active = true
		_reset_countdown_ui()
		_show_countdown_ui()


# Called when countdown ends, triggers the show
func _on_firework_show_timer_timeout():
		countdown_active = false
		firework_show_playing = true
		_hide_countdown_ui()
		print("[DEBUG] Countdown finished, triggering show. Mode: " + str(current_show_mode))
		if current_show_mode == "json":
			# Start JSON show - get next shuffled JSON show
			json_show_path = _get_next_json_show()
			print("[DEBUG] Selected JSON show: " + json_show_path)
			if json_show_path != "":
				load_json_firework_show(json_show_path)
				if show_audio_player:
					show_audio_player.play()
			else:
				print("[DEBUG] No JSON show available.")
				push_error("No JSON show available!")
		elif current_show_mode == "audio":
			# Start audio show - get next shuffled music
			var music_path = _get_next_audio_music()
			print("[DEBUG] Selected audio music: " + music_path)
			if music_path != "":
				show_audio_player = AudioStreamPlayer.new()
				add_child(show_audio_player)
				show_audio_player.stream = load(music_path)
				show_audio_player.play()
			if firework_show:
				firework_show.start_show()


func _on_firework_show_restart_requested():
	print("[DEBUG] Show restart requested. Current mode: " + str(current_show_mode))
	# Only alternate if we're not already handling a stop/end
	if firework_show_playing:
		# Show naturally ended, alternate mode
		if current_show_mode == "json":
			current_show_mode = "audio"
		else:
			current_show_mode = "json"
		print("[DEBUG] Next show mode: " + str(current_show_mode))
		firework_show_playing = false
	_start_firework_show_countdown()


# Stop the current show immediately
func _stop_firework_show_immediately():
		if countdown_active:
			# During countdown, stop button does nothing
			print("[DEBUG] Stop pressed during countdown - ignoring.")
			return
		if firework_show_playing:
			print("[DEBUG] Stopping show and restarting countdown.")
			firework_show_playing = false
			if show_audio_player and show_audio_player.playing:
				show_audio_player.stop()
			if firework_show:
				firework_show.stop_show()
			_hide_countdown_ui()
			# Alternate show mode when manually stopping
			if current_show_mode == "json":
				current_show_mode = "audio"
			else:
				current_show_mode = "json"
			print("[DEBUG] Next show mode after stop: " + str(current_show_mode))
			# Restart countdown after stopping the show
			_start_firework_show_countdown()


# Skip countdown only, not during show
func _skip_firework_show_timer():
		if countdown_active and firework_show_timer:
			print("[DEBUG] Skip pressed, skipping countdown and triggering show.")
			firework_show_timer.stop()
			_on_firework_show_timer_timeout()

func _initialize_countdown_ui():
	if countdown_bar:
		countdown_initial_height = countdown_bar.size.y
		countdown_initial_width = countdown_bar.size.x
	_reset_countdown_ui()
	_hide_countdown_ui()

func _reset_countdown_ui():
	if countdown_bar:
		countdown_bar.size = Vector2(countdown_initial_width, countdown_initial_height)
		countdown_bar.visible = true
	if countdown_label:
		countdown_label.text = ""
		countdown_label.visible = false

func _show_countdown_ui():
	if countdown_layer:
		countdown_layer.visible = true
	if countdown_bar:
		countdown_bar.visible = true

func _hide_countdown_ui():
	if countdown_layer:
		countdown_layer.visible = false
	if countdown_bar:
		countdown_bar.visible = false
	if countdown_label:
		countdown_label.visible = false

func _update_countdown_ui():
	if not countdown_layer:
		return
	if firework_show_timer and not firework_show_timer.is_stopped():
		var time_left = firework_show_timer.get_time_left()
		if countdown_initial_time <= 0.0:
			countdown_initial_time = firework_show_timer.wait_time
		var total_time = max(countdown_initial_time, 0.001)
		var normalized = clamp(time_left / total_time, 0.0, 1.0)
		if countdown_bar:
			countdown_bar.size = Vector2(countdown_initial_width, countdown_initial_height * normalized)
		if countdown_label:
			if time_left <= 1.0:
				countdown_label.visible = true
				countdown_label.text = "Fire!"
			elif time_left <= 5.0:
				countdown_label.visible = true
				countdown_label.text = str(int(time_left))
			else:
				countdown_label.visible = false
		if countdown_layer:
			countdown_layer.visible = true
	else:
		if firework_show_playing:
			if countdown_layer:
				countdown_layer.visible = false
			if countdown_label:
				countdown_label.visible = false
		else:
			_hide_countdown_ui()
	
# Get distances in order to accurately match phone position to space position
# Get distances in order to accurately match phone position to space position
func calculate_distances():
	sky_width = 2 * tan(deg_to_rad(camera.fov/2)) * camera.position.z * (1920.0/1080.0)
	interval = ratio * sky_width
	half_interval = interval/2

#constantly check for inputs

func _input(_event):
		if Input.is_action_just_pressed("load_firework"):
			var mouse_pos_x = ((get_viewport().get_mouse_position().x)/screen_width) - 0.5
			var pos = Vector3(mouse_pos_x * sky_width,-100,0)
			var firework_data = {}
			firework_data["location"] = pos.x
			create_debug_firework(firework_data)
		if Input.is_action_just_pressed("debug"):
			canvas.visible = true
		if Input.is_action_just_released("debug"):
			canvas.visible = false
		if Input.is_action_just_pressed("mock_fireworks"):
			create_mock_fireworks()
		if Input.is_action_just_pressed("stop_firework_show"):
			_stop_firework_show_immediately()
		if Input.is_action_just_pressed("skip_firework_show"):
			_skip_firework_show_timer()
	
func create_random_firework():
	pass

# For every data value missing in the json, fill it with some value
func fill_firework_data(firework_data):
	if(!firework_data.get("outer_layer")): firework_data["outer_layer"] = "sphere"
	if(!firework_data.get("inner_layer")): firework_data["inner_layer"] = "none"
	if(!firework_data.get("outer_layer_color")): firework_data["outer_layer_color"] = [randf(),randf(),randf()];
	if(!firework_data.get("outer_layer_second_color")): firework_data["outer_layer_second_color"] = [randf(),randf(),randf()];
	if(!firework_data.get("location")): firework_data["location"] = 0.0
	if(!firework_data.get("path_speed")): firework_data["path_speed"] = 1.0
	if(!firework_data.get("path_wobble")): firework_data["path_wobble"] = 0
	if(!firework_data.get("outer_layer_specialfx")): firework_data["outer_layer_specialfx"] = 0


#called if pressing "load_firework" key
#will instantiate fw scene and generate the fw w hardcoded starshape
func create_firework(firework_data):
	print("[DEBUG] Creating firework: " + str(firework_data))
	var fw = firework.instantiate() #need to instantiate because firework is a separate scene (not a child node)
	fill_firework_data(firework_data)
	fw.set_parameters(firework_data)
	add_child(fw)

# Adjust this for debugging things (called when pressing F)
func create_debug_firework(firework_data):
	var fw = firework.instantiate() #need to instantiate because firework is a separate scene (not a child node)
	if(!firework_data.get("inner_layer")): firework_data["inner_layer"] = "none"
	fill_firework_data(firework_data)
	fw.set_parameters(firework_data)
	add_child(fw)

func create_mock_fireworks():
			print("[DEBUG] Creating mock fireworks.")
			var mock_fireworks = [
				{"outer_layer": "tornado", "inner_layer": "1/0.png", "outer_layer_color": [1.0,0.0,0.0], "outer_layer_second_color": [0.0,1.0,0.0], "location": 0.5},
				{"outer_layer": "cluster", "inner_layer": "1/1.png", "outer_layer_color": [1.0,0.0,0.0], "outer_layer_second_color": [0.0,1.0,0.0], "location": 0.5},
				{"outer_layer": "sphere", "inner_layer": "1/2.png", "outer_layer_color": [0.0,0.0,1.0], "outer_layer_second_color": [1.0,1.0,0.0], "location": 0.5},
				{"outer_layer": "chrysanthemum", "inner_layer": "none", "outer_layer_color": [1.0,0.0,1.0], "outer_layer_second_color": [1.0,1.0,0.0], "location": 0.5},
				{"outer_layer": "willow", "inner_layer": "none", "outer_layer_color": [1.0,0.0,1.0], "outer_layer_second_color": [1.0,1.0,0.0], "location": 0.5},
				{"outer_layer": "another_cluster", "inner_layer": "none", "outer_layer_color": [1.0,0.0,1.0], "outer_layer_second_color": [1.0,1.0,0.0], "location": 0.5},
				{"outer_layer": "saturn", "inner_layer": "none", "outer_layer_color": [1.0,0.0,1.0], "outer_layer_second_color": [1.0,1.0,0.0], "location": 0.5}
			]
			json_reader.pending_data.append(mock_fireworks)
			for mock_firework in mock_fireworks:
				json_reader.firework_show_data.append(mock_firework)

#called if there are any jason file to be read
#called if there are any jason file to be read
#will instantiate fw scene and generate the fw w json shape
func create_shaped_firework(data):
	var fw = firework.instantiate()
	var coordinate = data.get("location")
	fw.position = Vector3(coordinate *half_interval, -30,0) #only care about x-coords
	add_child(fw)
	fw.generate_shape(data.get("points")) #calls fw-->calls blast-->calls figure.
	
	
	
	

# Fire event for JSON show
func fire_event(event):
		var nr = event["number_of_fireworks"]
		var type = event["firework_type"]
		for i in range(nr):
			var normalized_pos = (i + 1.0) / (nr + 1.0)
			var firework_x = normalized_pos * interval - half_interval
			firework_x += randf_range(-10, 10)
			firework_x = clamp(firework_x, -half_interval, half_interval)
			var firework_data = {
				"outer_layer": type,
				"inner_layer": "none",
				"outer_layer_color": [randf(), randf(), randf()],
				"outer_layer_second_color": [randf(), randf(), randf()],
				"location": firework_x,
				"path_speed": 1.0,
				"path_sound_path": null,
				"use_variation": false
			}
			var timer = Timer.new()
			timer.wait_time = 1.8
			timer.one_shot = true
			timer.set_meta("firework_data", firework_data)
			add_child(timer)
			timer.connect("timeout", func(): _on_firework_timer_timeout(timer))
			timer.start()


func _on_firework_timer_timeout(timer):
		var data = timer.get_meta("firework_data")
		create_firework(data)
		timer.queue_free()

# End current show and alternate mode
func _end_current_show():
		firework_show_playing = false
		countdown_active = false
		print("[DEBUG] Ending current show. Mode: " + str(current_show_mode))
		if show_audio_player and show_audio_player.playing:
			show_audio_player.stop()
		if firework_show:
			firework_show.stop_show()
		_hide_countdown_ui()
		# Alternate show mode
		if current_show_mode == "json":
			current_show_mode = "audio"
		else:
			current_show_mode = "json"
		print("[DEBUG] Next show mode: " + str(current_show_mode))
		_start_firework_show_countdown()
