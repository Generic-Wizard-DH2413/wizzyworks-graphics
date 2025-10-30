# AudioManager.gd (set this as an Autoload in Project Settings → Autoload)
extends Node

var _active_players: Array[AudioStreamPlayer] = []
var _managed_players: Dictionary = {} # For long-running audio with manual control

func play_sound(sound: AudioStream, bus := "Effects", volume := 1.0, pitch := 1.0, delay := 0.8) -> void:
	"""Fire-and-forget sound effect - automatically cleaned up when finished"""
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sound
	player.bus = bus
	player.volume_db = linear_to_db(volume)
	player.pitch_scale = pitch
	_active_players.append(player)

	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(Callable(self, "_on_play_timer_timeout").bind(player), Object.CONNECT_ONE_SHOT)
	player.finished.connect(Callable(self, "_on_player_finished").bind(player), Object.CONNECT_ONE_SHOT)

func play_music(sound: AudioStream, bus := "Music", volume := 1.0, pitch := 1.0, auto_play := true, delay := 0.8) -> AudioStreamPlayer:
	"""Long-running audio with manual control - returns player reference for control"""
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sound
	player.bus = bus
	player.volume_db = linear_to_db(volume)
	player.pitch_scale = pitch
	
	# Store in managed players (no auto-cleanup)
	_managed_players[player] = true
	
	# Connect finished signal for cleanup
	player.finished.connect(Callable(self, "_on_managed_player_finished").bind(player), Object.CONNECT_ONE_SHOT)
	
	if auto_play:
		if delay > 0.0:
			print("[AudioManager] Delaying music play by " + str(delay) + " seconds.")
			var timer := get_tree().create_timer(delay)
			timer.timeout.connect(Callable(self, "_on_music_play_timer_timeout").bind(player), Object.CONNECT_ONE_SHOT)
		else:
			print("[AudioManager] Starting music play immediately.")
			player.play()
	
	return player

func stop_music(player: AudioStreamPlayer) -> void:
	"""Stop and cleanup a managed music player"""
	if is_instance_valid(player):
		if player.playing:
			player.stop()
		_release_managed_player(player)

func stop_all_sounds() -> void:
	"""Stop all fire-and-forget sound effects"""
	for player in _active_players.duplicate():
		_release_player(player, true)

func stop_all_music() -> void:
	"""Stop all managed music players"""
	for player in _managed_players.keys():
		if is_instance_valid(player):
			if player.playing:
				player.stop()
			_release_managed_player(player)

func stop_all() -> void:
	"""Stop everything - both sounds and music"""
	stop_all_sounds()
	stop_all_music()

func _on_play_timer_timeout(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player):
		return
	player.play()

func _on_music_play_timer_timeout(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player):
		return
	player.play()

func _on_player_finished(player: AudioStreamPlayer) -> void:
	_release_player(player)

func _on_managed_player_finished(player: AudioStreamPlayer) -> void:
	_release_managed_player(player)

func _release_player(player: AudioStreamPlayer, force_stop := false) -> void:
	var is_valid := is_instance_valid(player)
	if force_stop and is_valid and player.playing:
		player.stop()
	if _active_players.has(player):
		_active_players.erase(player)
	if is_valid:
		player.queue_free()

func _release_managed_player(player: AudioStreamPlayer) -> void:
	if _managed_players.has(player):
		_managed_players.erase(player)
	if is_instance_valid(player):
		player.queue_free()
