extends Node3D
signal path_timeout(pos)
enum path_type_enum {straight, wobbly}
@export var path_type: path_type_enum
@export var wobble_width = 0.5
@export var wobble_speed = 0.3
var wobble_angle = 0

func _ready():
	var timer = get_node("PathTimer") 
	var time = 3.25 + (randf()/2) # random value betweem 3.25 and 3.75
	get_node("FireLaunch").play()
	timer.start(time)

func set_parameres(width, speed):
	wobble_width = width
	wobble_speed = speed

func _physics_process(delta: float) -> void:
		position.y = position.y + 1
		if path_type == path_type_enum.wobbly:
			wobble_angle += wobble_speed
			position.x = sin(wobble_angle)*wobble_width
	

func _on_path_timer_timeout() -> void:
	path_timeout.emit(position)
