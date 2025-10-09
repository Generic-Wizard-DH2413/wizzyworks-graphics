extends AudioStreamPlayer3D
@export var snippet_length: float = 2.0

func _ready():
	pass

func play_random_part():
	if not stream:
		return

	var duration = stream.get_length()

	var start_time = randf_range(0.0, max(0.0, duration - snippet_length))
	play(start_time)

	await get_tree().create_timer(snippet_length).timeout
	stop()
