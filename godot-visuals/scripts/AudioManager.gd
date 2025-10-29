# AudioManager.gd (set this as an Autoload in Project Settings → Autoload)
extends Node

var _active_players: Array[AudioStreamPlayer] = []

func play_sound(sound: AudioStream, bus := "Master", volume := 1.0, pitch := 1.0, delay := 0.5) -> void:
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

func stop_all_sounds() -> void:
	for player in _active_players.duplicate():
		_release_player(player, true)

func _on_play_timer_timeout(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player):
		return
	player.play()

func _on_player_finished(player: AudioStreamPlayer) -> void:
	_release_player(player)

func _release_player(player: AudioStreamPlayer, force_stop := false) -> void:
	var is_valid := is_instance_valid(player)
	if force_stop and is_valid and player.playing:
		player.stop()
	if _active_players.has(player):
		_active_players.erase(player)
	if is_valid:
		player.queue_free()
