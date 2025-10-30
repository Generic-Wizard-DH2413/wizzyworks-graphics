extends Node3D

# ============================================================================
# SCENE REFERENCES
# ============================================================================
var firework_scene = preload("res://scenes/firework.tscn")
var treeline_scene = preload("res://scenes/treeline.tscn")
var json_reader: Node
var camera: Camera3D
var canvas: CanvasLayer
var firework_show: Node3D
var treeline: Node3D

# ============================================================================
# SCREEN AND VIEWPORT SETUP
# ============================================================================
@export_range(0, 1) var sky_view_ratio = 0.5
var mode = ProjectSettings.get_setting("display/window/size/mode")
@export var screen_width = DisplayServer.screen_get_size().x if mode == 3 else 1920
@export var screen_height = DisplayServer.screen_get_size().y if mode == 3 else 1080
var min_ratio: float
var max_ratio: float
var sky_width: float
var interval: float
var half_interval: float

# ============================================================================
# SHOW MANAGEMENT
# ============================================================================
# Show state
var is_show_playing: bool = false
var is_countdown_active: bool = false
var current_show_mode: String = "audio" # alternates between "audio" and "json"
@export var initial_show_mode: String = "json"
@export var countdown_duration: float = 1200.0

# Show timer
var show_countdown_timer: Timer

# ============================================================================
# FIREWORK RECORDING SYSTEM
# ============================================================================
# Current recording session - organized by firework type
# Drawings (inner_layer) are kept attached to their outer_layer type
var recorded_fireworks: Dictionary = {
	"sphere": [],
	"chrysanthemum": [],
	"willow": [],
	"cluster": [],
	"another_cluster": [],
	"tornado": [],
	"saturn": [],
	"fish": [],
	"pistil": []
}

# Archive of previous shows' recorded fireworks
var archived_firework_recordings: Array = []
@export var max_archived_shows: int = 5

# ============================================================================
# AUDIO MODE (Music-reactive fireworks)
# ============================================================================
var audio_mode_music_files: Array = []
var audio_mode_shuffle_index: int = 0
var audio_mode_show_start_time: float = 0.0
var audio_mode_initial_delay: float = 3.0 # Seconds before first fireworks
var audio_mode_ramp_duration: float = 10.0 # Seconds to reach full intensity
@export var audio_mode_max_fireworks_per_beat: int = 3

# Audio mode firework positioning
var audio_mode_x_position: float = 0.0
var audio_mode_direction: int = 1
var audio_mode_firework_index: int = 0

# ============================================================================
# JSON MODE (Choreographed fireworks)
# ============================================================================
var json_mode_show_files: Array = []
var json_mode_shuffle_index: int = 0
var json_mode_current_show_path: String = ""
var json_mode_show_events: Array = []
@export var json_mode_fire_interval: float = 3.0

# ============================================================================
# SHARED AUDIO AND MUSIC
# ============================================================================
var show_audio_player: AudioStreamPlayer
var show_audio_has_started: bool = false # Track if audio has actually started playing
var last_played_music_name: String = "" # Prevent back-to-back repeats

# ============================================================================
# COUNTDOWN UI
# ============================================================================
var countdown_layer: CanvasLayer
var countdown_label: Label
var countdown_bar: Control
var countdown_initial_height: float = 0.0
var countdown_initial_width: float = 0.0
var countdown_initial_time: float = 0.0


# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready():
	_initialize_scene_references()
	_initialize_screen_setup()
	_initialize_audio_mode()
	_initialize_json_mode()
	_initialize_show_system()


func _initialize_scene_references():
	camera = get_node("Camera3D")
	json_reader = get_node("JsonReader")
	canvas = get_node("CanvasLayer")
	
	var firework_show_scene = load("res://scenes/firework_show.tscn")
	firework_show = firework_show_scene.instantiate()
	add_child(firework_show)
	var detector = firework_show.get_node("Node3D")
	detector.drum_hit.connect(_on_audio_beat_detected)


func _initialize_screen_setup():
	min_ratio = (1 - sky_view_ratio) / 2
	max_ratio = sky_view_ratio + (1 - sky_view_ratio) / 2
	
	# Debug lines
	canvas.get_node("left_line").position.x = min_ratio * screen_width
	canvas.get_node("right_line").position.x = max_ratio * screen_width
	
	_calculate_sky_distances()


func _initialize_audio_mode():
	_load_and_shuffle_audio_music()


func _initialize_json_mode():
	_load_and_shuffle_json_shows()


func _initialize_show_system():
	current_show_mode = initial_show_mode
	_initialize_countdown_ui()
	_setup_show_countdown_timer()


# ============================================================================
# MAIN PROCESS LOOP
# ============================================================================
func _process(_delta):
	_handle_json_reader_pending_fireworks()
	_update_countdown_ui()
	_handle_show_logic()


func _handle_json_reader_pending_fireworks():
	"""Handle pending fireworks from JsonReader (external system)"""
	while json_reader.pending_data.size() > 0:
		var firework_list = json_reader.pending_data.pop_front()
		for i in range(firework_list.size()):
			if i == 0:
				var data = firework_list[0]
				data["location"] = data["location"] * half_interval
				_record_firework(data) # Record user-created firework
				spawn_firework(data)
			else:
				var timer = Timer.new()
				timer.wait_time = json_mode_fire_interval * i
				timer.one_shot = true
				var data = firework_list[i]
				data["location"] = data["location"] * half_interval
				_record_firework(data) # Record user-created firework
				timer.set_meta("firework_data", data)
				add_child(timer)
				timer.connect("timeout", func(): _on_delayed_firework_timer(timer))
				timer.start()


func _handle_show_logic():
	"""Main show logic for JSON and audio modes"""
	if not is_show_playing:
		return
	
	if current_show_mode == "json":
		_process_json_show()
	elif current_show_mode == "audio":
		_process_audio_show()


func _process_json_show():
	"""Process JSON choreographed show events"""
	if show_audio_player and show_audio_player.playing:
		var current_time = show_audio_player.get_playback_position()
		while json_mode_show_events.size() > 0 and current_time >= json_mode_show_events[0]["time"]:
			var event = json_mode_show_events.pop_front()
			print("[DEBUG] Processing event: " + str(event))
			_fire_json_show_event(event)
		
		# Check if show finished
		if json_mode_show_events.is_empty() and not show_audio_player.playing:
			print("[DEBUG] JSON show finished - events empty and audio stopped.")
			_end_show_and_start_countdown()
	elif show_audio_player:
		# Audio stopped, check if we should end
		if json_mode_show_events.is_empty():
			print("[DEBUG] JSON show finished - no events left.")
			_end_show_and_start_countdown()


func _process_audio_show():
	"""Check if audio show has ended"""
	if show_audio_player:
		# Track when audio has started playing
		if show_audio_player.playing and not show_audio_has_started:
			show_audio_has_started = true
			print("[DEBUG] Audio playback started")
		
		# Only check for end if audio has actually started
		if show_audio_has_started and not show_audio_player.playing:
			print("[DEBUG] Audio show finished - music stopped.")
			_end_show_and_start_countdown()


# ============================================================================
# AUDIO MODE - Music Reactive Fireworks
# ============================================================================
func _load_and_shuffle_audio_music():
	"""Load all music files from firework_music folder and shuffle"""
	audio_mode_music_files.clear()
	var dir = DirAccess.open("res://assets/sounds/firework_music")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".mp3") or file_name.ends_with(".ogg") or file_name.ends_with(".wav")):
				audio_mode_music_files.append("res://assets/sounds/firework_music/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	audio_mode_music_files.shuffle()
	audio_mode_shuffle_index = 0
	print("[DEBUG] Loaded " + str(audio_mode_music_files.size()) + " audio music files and shuffled them.")


func _get_next_audio_music() -> String:
	"""Get next audio music file with shuffle and anti-repeat logic"""
	if audio_mode_music_files.is_empty():
		push_error("No audio music files found!")
		return ""
	
	var music_path = audio_mode_music_files[audio_mode_shuffle_index]
	var music_name = music_path.get_file().get_basename()
	
	# Skip if same as last played (avoid back-to-back repeats)
	if music_name == last_played_music_name and audio_mode_music_files.size() > 1:
		print("[DEBUG] Skipping " + music_name + " (same as last played)")
		audio_mode_shuffle_index += 1
		if audio_mode_shuffle_index >= audio_mode_music_files.size():
			audio_mode_music_files.shuffle()
			audio_mode_shuffle_index = 0
		music_path = audio_mode_music_files[audio_mode_shuffle_index]
		music_name = music_path.get_file().get_basename()
	
	audio_mode_shuffle_index += 1
	if audio_mode_shuffle_index >= audio_mode_music_files.size():
		print("[DEBUG] All audio music played, reshuffling...")
		audio_mode_music_files.shuffle()
		audio_mode_shuffle_index = 0
	
	last_played_music_name = music_name
	return music_path


func _start_audio_mode_show():
	"""Start audio-reactive firework show"""
	show_audio_has_started = false # Reset flag for new show
	var music_path = _get_next_audio_music()
	print("[DEBUG] Selected audio music: " + music_path)

	treeline = treeline_scene.instantiate()
	add_child(treeline)

	if music_path != "":
		var music_stream = load(music_path)
		# Pass music to firework_show which handles AudioManager internally
		if firework_show:
			show_audio_player = await firework_show.start_show_with_music(music_stream)
	else:
		if firework_show:
			firework_show.start_show()
	
	audio_mode_show_start_time = Time.get_ticks_msec() / 1000.0
	print("[DEBUG] Audio show started, ramp-up begins after " + str(audio_mode_initial_delay) + " seconds")


func _on_audio_beat_detected(beat_intensity: int):
	"""Called when drum beat is detected in audio mode"""
	var elapsed_time = (Time.get_ticks_msec() / 1000.0) - audio_mode_show_start_time
	
	# Ignore fireworks during initial delay
	if elapsed_time < audio_mode_initial_delay:
		print("[DEBUG] Ignoring firework trigger (elapsed: " + str(elapsed_time) + "s)")
		return
	
	# Calculate ramp-up intensity
	var ramp_progress = (elapsed_time - audio_mode_initial_delay) / audio_mode_ramp_duration
	ramp_progress = clamp(ramp_progress, 0.0, 1.0)
	
	# Adjust number of fireworks based on ramp-up
	var firework_count = int(ceil(beat_intensity * ramp_progress))
	firework_count = clamp(firework_count, 1, audio_mode_max_fireworks_per_beat)
	
	if firework_count < beat_intensity:
		print("[DEBUG] Ramp-up: " + str(int(ramp_progress * 100)) + "% - firing " + str(firework_count) + "/" + str(beat_intensity) + " fireworks")
	
	_fire_audio_mode_fireworks(firework_count)


func _fire_audio_mode_fireworks(count: int):
	"""Fire fireworks for audio mode with positioning"""
	audio_mode_x_position += 40 * audio_mode_direction
	if audio_mode_x_position >= 250:
		audio_mode_x_position = 250
		audio_mode_direction = -1
	elif audio_mode_x_position <= -250:
		audio_mode_x_position = -250
		audio_mode_direction = 1
	
	for i in range(count):
		if (audio_mode_firework_index + 1 > json_reader.firework_show_data.size()):
			audio_mode_firework_index = 0
		if (json_reader.firework_show_data.size() == 0):
			_create_mock_fireworks()
		
		if (json_reader.firework_show_data[audio_mode_firework_index] != null):
			var firework_data = json_reader.firework_show_data[audio_mode_firework_index]
			var x_position = audio_mode_x_position + (i * 45 * audio_mode_direction)
			firework_data["location"] = x_position
			firework_data["path_speed"] = 1
			firework_data["path_sound_path"] = null
			firework_data["use_variation"] = true
			spawn_firework(firework_data)
		
		audio_mode_firework_index += 1


# ============================================================================
# JSON MODE - Choreographed Fireworks
# ============================================================================
func _load_and_shuffle_json_shows():
	"""Load all JSON show files and shuffle"""
	json_mode_show_files.clear()
	var dir = DirAccess.open("res://json_fireworks/json_firework_shows")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				json_mode_show_files.append("res://json_fireworks/json_firework_shows/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	json_mode_show_files.shuffle()
	json_mode_shuffle_index = 0
	print("[DEBUG] Loaded " + str(json_mode_show_files.size()) + " JSON show files and shuffled them.")


func _get_next_json_show() -> String:
	"""Get next JSON show file with shuffle and anti-repeat logic"""
	if json_mode_show_files.is_empty():
		push_error("No JSON show files found!")
		return ""
	
	var show_path = json_mode_show_files[json_mode_shuffle_index]
	var show_name = show_path.get_file().get_basename()
	
	# Skip if same as last played music (avoid back-to-back repeats)
	if show_name == last_played_music_name and json_mode_show_files.size() > 1:
		print("[DEBUG] Skipping " + show_name + " (same as last played)")
		json_mode_shuffle_index += 1
		if json_mode_shuffle_index >= json_mode_show_files.size():
			json_mode_show_files.shuffle()
			json_mode_shuffle_index = 0
		show_path = json_mode_show_files[json_mode_shuffle_index]
		show_name = show_path.get_file().get_basename()
	
	json_mode_shuffle_index += 1
	if json_mode_shuffle_index >= json_mode_show_files.size():
		print("[DEBUG] All JSON shows played, reshuffling...")
		json_mode_show_files.shuffle()
		json_mode_shuffle_index = 0
	
	last_played_music_name = show_name
	return show_path


func _load_json_show(path: String):
	"""Load and prepare a JSON firework show"""
	print("[DEBUG] Loading JSON show: " + path)
	var json_text = FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(json_text)
	if data:
		json_mode_show_events = data["events"]
		var sound_file_name = data["sound_file_name"]
		
		# Try firework_music folder first, then fall back to sounds folder
		var sound_path = "res://assets/sounds/firework_music/" + sound_file_name
		if not FileAccess.file_exists(sound_path):
			sound_path = "res://assets/sounds/" + sound_file_name
		
		print("[DEBUG] JSON show loaded. Events: " + str(json_mode_show_events.size()) + ", Sound: " + sound_path)
		var music_stream = load(sound_path)
		show_audio_player = AudioManager.play_music(music_stream)
	else:
		push_error("Failed to load JSON show from " + path)


func _start_json_mode_show():
	"""Start choreographed JSON firework show"""
	json_mode_current_show_path = _get_next_json_show()
	print("[DEBUG] Selected JSON show: " + json_mode_current_show_path)

	treeline = treeline_scene.instantiate()
	add_child(treeline)

	if json_mode_current_show_path != "":
		_load_json_show(json_mode_current_show_path)
		# AudioManager handles delayed playback automatically
	else:
		print("[DEBUG] No JSON show available.")
		push_error("No JSON show available!")


func _fire_json_show_event(event: Dictionary):
	"""Fire fireworks for a JSON show event using recorded fireworks"""
	var firework_count = event["number_of_fireworks"]
	var firework_type = event["firework_type"]
	
	for i in range(firework_count):
		var normalized_pos = (i + 1.0) / (firework_count + 1.0)
		var firework_x = normalized_pos * interval - half_interval
		firework_x += randf_range(-10, 10)
		firework_x = clamp(firework_x, -half_interval, half_interval)
		
		# Try to get a recorded firework of this type
		var firework_data = _get_recorded_firework(firework_type)
		
		# If no recorded firework, create a fallback
		if firework_data.is_empty():
			firework_data = {
				"outer_layer": firework_type,
				"inner_layer": "none",
				"outer_layer_color": [randf(), randf(), randf()],
				"outer_layer_second_color": [randf(), randf(), randf()],
				"location": firework_x,
				"path_speed": 1.0,
				"path_sound_path": null,
				"use_variation": false
			}
		else:
			# Update location for this show
			firework_data = firework_data.duplicate(true)
			firework_data["location"] = firework_x
			firework_data["path_speed"] = 1.0
			firework_data["path_sound_path"] = null
			firework_data["use_variation"] = false
		
		# Delay firing slightly for realistic timing
		var timer = Timer.new()
		timer.wait_time = 1.8
		timer.one_shot = true
		timer.set_meta("firework_data", firework_data)
		add_child(timer)
		timer.connect("timeout", func(): _on_delayed_firework_timer(timer))
		timer.start()


# ============================================================================
# FIREWORK RECORDING SYSTEM
# ============================================================================
func _record_firework(firework_data: Dictionary):
	"""Record a user-created firework into the appropriate type list"""
	var outer_layer = firework_data.get("outer_layer", "sphere")
	var inner_layer = firework_data.get("inner_layer", "none")
	
	# Create a clean copy of the firework data (without location/path info)
	var recorded_data = {
		"outer_layer": outer_layer,
		"inner_layer": inner_layer,
		"outer_layer_color": firework_data.get("outer_layer_color", [1.0, 1.0, 1.0]),
		"outer_layer_second_color": firework_data.get("outer_layer_second_color", [1.0, 1.0, 1.0]),
		"outer_layer_specialfx": firework_data.get("outer_layer_specialfx", 0),
		"path_wobble": firework_data.get("path_wobble", 0),
		"wobble_speed": firework_data.get("wobble_speed", 0.5),
		"height_variation": firework_data.get("height_variation", 40.0)
	}
	
	# Determine which list to add to - categorize by outer_layer type
	# Drawings (inner_layer) stay attached to their outer_layer
	var target_list = "sphere" # default
	
	if recorded_fireworks.has(outer_layer):
		target_list = outer_layer
	
	recorded_fireworks[target_list].append(recorded_data)
	
	var has_drawing = inner_layer != "none" and inner_layer != null and inner_layer != ""
	var drawing_note = " (with drawing)" if has_drawing else ""
	var recording_stats = _get_recording_stats()
	print("[RECORDING] Firework recorded as '" + target_list + "'" + drawing_note + ". Total: " + str(recording_stats))


func _get_recorded_firework(firework_type: String):
	"""Get a random recorded firework of the specified type"""
	# First, try to get from the exact type
	if recorded_fireworks.has(firework_type) and recorded_fireworks[firework_type].size() > 0:
		var list = recorded_fireworks[firework_type]
		return list[randi() % list.size()]
	
	# If no exact match, try to get from archived shows
	for archived_show in archived_firework_recordings:
		if archived_show.has(firework_type) and archived_show[firework_type].size() > 0:
			var list = archived_show[firework_type]
			print("[RECORDING] Using archived firework for type: " + firework_type)
			return list[randi() % list.size()]
	
	# If still no match, return empty dict (caller will create fallback)
	print("[RECORDING] No recorded firework found for type: " + firework_type)
	return {}


func _archive_and_reset_recording():
	"""Archive current recording and start fresh for next show"""
	# Only archive if we have recorded fireworks
	var total_recorded = _count_total_recorded_fireworks()
	if total_recorded > 0:
		print("[RECORDING] Archiving " + str(total_recorded) + " recorded fireworks")
		
		# Deep copy the current recording
		var archived_copy = {}
		for type in recorded_fireworks.keys():
			archived_copy[type] = []
			for firework in recorded_fireworks[type]:
				archived_copy[type].append(firework.duplicate(true))
		
		# Add to archive
		archived_firework_recordings.append(archived_copy)
		
		# Limit archive size
		while archived_firework_recordings.size() > max_archived_shows:
			archived_firework_recordings.pop_front()
			print("[RECORDING] Removed oldest archived show from memory")
	
	# Reset current recording
	for type in recorded_fireworks.keys():
		recorded_fireworks[type].clear()
	
	print("[RECORDING] Started fresh recording session")


func _count_total_recorded_fireworks() -> int:
	"""Count total number of recorded fireworks across all types"""
	var total = 0
	for type in recorded_fireworks.keys():
		total += recorded_fireworks[type].size()
	return total


func _get_recording_stats() -> String:
	"""Get a string summary of current recording"""
	var stats = []
	for type in recorded_fireworks.keys():
		var count = recorded_fireworks[type].size()
		if count > 0:
			stats.append(type + ":" + str(count))
	return ", ".join(stats) if stats.size() > 0 else "empty"


# ============================================================================
# SHOW COUNTDOWN AND CONTROL
# ============================================================================
func _setup_show_countdown_timer():
	"""Setup timer for countdown between shows"""
	show_countdown_timer = Timer.new()
	show_countdown_timer.wait_time = countdown_duration
	show_countdown_timer.one_shot = true
	add_child(show_countdown_timer)
	show_countdown_timer.connect("timeout", Callable(self, "_on_countdown_finished"))
	if firework_show:
		firework_show.connect("countdown_restart_requested", Callable(self, "_on_show_naturally_ended"))
	_start_countdown()


func _start_countdown():
	"""Start countdown before next show"""
	if show_countdown_timer:
		show_countdown_timer.wait_time = countdown_duration
		show_countdown_timer.start()
	countdown_initial_time = countdown_duration
	is_show_playing = false
	is_countdown_active = true
	_reset_countdown_ui()
	_show_countdown_ui()


func _on_countdown_finished():
	"""Called when countdown reaches zero - start the show"""
	is_countdown_active = false
	is_show_playing = true
	_hide_countdown_ui()
	print("[DEBUG] Countdown finished, starting show. Mode: " + str(current_show_mode))
	
	if current_show_mode == "json":
		_start_json_mode_show()
	elif current_show_mode == "audio":
		_start_audio_mode_show()


func _on_show_naturally_ended():
	"""Called when audio mode show naturally ends via signal"""
	print("[DEBUG] Show naturally ended. Current mode: " + str(current_show_mode))
	if is_show_playing:
		_alternate_show_mode()
		is_show_playing = false
	_start_countdown()


func _end_show_and_start_countdown():
	"""End current show and start countdown for next"""
	is_show_playing = false
	is_countdown_active = false
	show_audio_has_started = false # Reset flag
	print("[DEBUG] Ending show. Mode: " + str(current_show_mode))
	
	if show_audio_player and is_instance_valid(show_audio_player):
		AudioManager.stop_music(show_audio_player)
		show_audio_player = null
	if firework_show:
		firework_show.stop_show()
	_hide_countdown_ui()
	
	# Delete treeline
	if treeline and is_instance_valid(treeline):
		treeline.go_down()
		# create a temp timer to wait before freeing
		var temp_timer = Timer.new()
		temp_timer.wait_time = 2.0
		temp_timer.one_shot = true
		add_child(temp_timer)
		temp_timer.connect("timeout", func():
			treeline.queue_free()
			treeline = null
		)

	# Archive current recording and start fresh
	_archive_and_reset_recording()
	
	_alternate_show_mode()
	_start_countdown()


func _alternate_show_mode():
	"""Switch between JSON and audio modes"""
	if current_show_mode == "json":
		current_show_mode = "audio"
	else:
		current_show_mode = "json"
	print("[DEBUG] Next show mode: " + str(current_show_mode))


func stop_show():
	"""Stop the current show (called by user input)"""
	if is_countdown_active:
		print("[DEBUG] Stop pressed during countdown - ignoring.")
		return
	
	if is_show_playing:
		print("[DEBUG] Stopping show and restarting countdown.")
		is_show_playing = false
		show_audio_has_started = false # Reset flag
		if show_audio_player and is_instance_valid(show_audio_player):
			AudioManager.stop_music(show_audio_player)
			show_audio_player = null
		if firework_show:
			firework_show.stop_show()
		_hide_countdown_ui()
		
		# Delete treeline
		if treeline and is_instance_valid(treeline):
			treeline.go_down()
			# create a temp timer to wait before freeing
			var temp_timer = Timer.new()
			temp_timer.wait_time = 2.0
			temp_timer.one_shot = true
			add_child(temp_timer)
			temp_timer.connect("timeout", func():
				treeline.queue_free()
				treeline = null
			)
		
		# Archive current recording and start fresh
		_archive_and_reset_recording()
		
		_alternate_show_mode()
		_start_countdown()


func skip_countdown():
	"""Skip countdown to the last 5 seconds"""
	if is_countdown_active and show_countdown_timer:
		var time_left = show_countdown_timer.get_time_left()
		if time_left > 5.0:
			print("[DEBUG] Skip pressed, jumping to last 5 seconds.")
			show_countdown_timer.stop()
			show_countdown_timer.wait_time = 5.0
			show_countdown_timer.start()
		else:
			print("[DEBUG] Skip pressed, but already in last 5 seconds.")


# ============================================================================
# COUNTDOWN UI
# ============================================================================
func _initialize_countdown_ui():
	countdown_layer = get_node_or_null("CountdownLayer")
	if countdown_layer:
		countdown_label = countdown_layer.get_node_or_null("CountdownLabel")
		countdown_bar = countdown_layer.get_node_or_null("CountdownBar")
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
	
	if show_countdown_timer and not show_countdown_timer.is_stopped():
		var time_left = show_countdown_timer.get_time_left()
		if countdown_initial_time <= 0.0:
			countdown_initial_time = show_countdown_timer.wait_time
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
		if is_show_playing:
			if countdown_layer:
				countdown_layer.visible = false
			if countdown_label:
				countdown_label.visible = false
		else:
			_hide_countdown_ui()


# ============================================================================
# FIREWORK CREATION
# ============================================================================
func spawn_firework(firework_data: Dictionary):
	"""Create and spawn a firework with given data"""
	print("[DEBUG] Creating firework: " + str(firework_data))
	var fw = firework_scene.instantiate()
	_fill_firework_defaults(firework_data)
	fw.set_parameters(firework_data)
	add_child(fw)


func _fill_firework_defaults(firework_data: Dictionary):
	"""Fill missing firework data with default values"""
	if not firework_data.get("outer_layer"):
		firework_data["outer_layer"] = "sphere"
	if not firework_data.get("inner_layer"):
		firework_data["inner_layer"] = "none"
	if not firework_data.get("outer_layer_color"):
		firework_data["outer_layer_color"] = [randf(), randf(), randf()]
	if not firework_data.get("outer_layer_second_color"):
		firework_data["outer_layer_second_color"] = [randf(), randf(), randf()]
	if not firework_data.get("location"):
		firework_data["location"] = 0.0
	if not firework_data.get("path_speed"):
		firework_data["path_speed"] = 1.0
	if not firework_data.get("path_wobble"):
		firework_data["path_wobble"] = 0
	if not firework_data.get("outer_layer_specialfx"):
		firework_data["outer_layer_specialfx"] = 0


func _on_delayed_firework_timer(timer: Timer):
	"""Handle delayed firework spawning"""
	var data = timer.get_meta("firework_data")
	spawn_firework(data)
	timer.queue_free()


func _create_debug_firework(mouse_position_x: float):
	"""Create a firework at mouse position for debugging - simulates user creation"""
	var firework_data = {
		"location": mouse_position_x / half_interval, # Normalize for pending_data processing
		"inner_layer": "none",
		"outer_layer": "sphere",
		"outer_layer_color": [randf(), randf(), randf()],
		"outer_layer_second_color": [randf(), randf(), randf()]
	}
	
	# Add to pending_data to simulate user creation - will be processed and recorded
	json_reader.pending_data.append([firework_data])
	
	# Also add to firework_show_data for audio mode playback
	json_reader.firework_show_data.append(firework_data)
	
	print("[DEBUG] Debug firework added to pending_data - will be recorded when processed")


func _create_mock_fireworks():
	"""Create mock fireworks for testing - simulates user-created fireworks"""
	print("[DEBUG] Creating mock fireworks (simulating user creation process).")
	var mock_fireworks = [
		{"outer_layer": "tornado", "inner_layer": "1/0.png", "outer_layer_color": [0.639, 0.353, 0.804], "outer_layer_second_color": [0.988, 0.557, 0.675], "location": 0.5},
		{"outer_layer": "cluster", "inner_layer": "1/1.png", "outer_layer_color": [0.639, 0.353, 0.804], "outer_layer_second_color": [0.357, 0.737, 0.894], "location": 0.5},
		{"outer_layer": "sphere", "inner_layer": "1/2.png", "outer_layer_color": [0.988, 0.557, 0.675], "outer_layer_second_color": [0.357, 0.737, 0.894], "location": 0.5},
		{"outer_layer": "chrysanthemum", "inner_layer": "none", "outer_layer_color": [0.639, 0.353, 0.804], "outer_layer_second_color": [0.357, 0.737, 0.894], "location": 0.5},
		{"outer_layer": "willow", "inner_layer": "none", "outer_layer_color": [0.988, 0.557, 0.675], "outer_layer_second_color": [0.357, 0.737, 0.894], "location": 0.5},
		{"outer_layer": "another_cluster", "inner_layer": "none", "outer_layer_color": [0.639, 0.353, 0.804], "outer_layer_second_color": [0.357, 0.737, 0.894], "location": 0.5},
		{"outer_layer": "saturn", "inner_layer": "none", "outer_layer_color": [0.988, 0.557, 0.675], "outer_layer_second_color": [0.357, 0.737, 0.894], "location": 0.5}
	]
	
	# Add to pending_data to simulate user creation - will be processed and recorded
	json_reader.pending_data.append(mock_fireworks)
	
	# Also add to firework_show_data for audio mode playback
	for mock_firework in mock_fireworks:
		json_reader.firework_show_data.append(mock_firework)
	
	print("[DEBUG] Mock fireworks added to pending_data - will be recorded when processed")


# ============================================================================
# SCREEN CALCULATIONS
# ============================================================================
func _calculate_sky_distances():
	"""Calculate distances to match screen position to 3D space"""
	sky_width = 2 * tan(deg_to_rad(camera.fov/2)) * camera.position.z * (1920.0/1080.0)
	interval = sky_view_ratio * sky_width
	half_interval = interval/2


# ============================================================================
# INPUT HANDLING
# ============================================================================
func _input(_event):
	if Input.is_action_just_pressed("load_firework"):
		var mouse_pos_x = ((get_viewport().get_mouse_position().x)/screen_width) - 0.5
		var pos_x = mouse_pos_x * sky_width
		_create_debug_firework(pos_x)
	
	if Input.is_action_just_pressed("debug"):
		canvas.visible = true
	if Input.is_action_just_released("debug"):
		canvas.visible = false
	
	if Input.is_action_just_pressed("mock_fireworks"):
		_create_mock_fireworks()
	
	if Input.is_action_just_pressed("stop_firework_show"):
		stop_show()
	if Input.is_action_just_pressed("skip_firework_show"):
		skip_countdown()
