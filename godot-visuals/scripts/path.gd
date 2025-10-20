extends Node3D
signal path_timeout(pos)
enum path_type_enum {straight, wobbly}
@export var path_type: path_type_enum
@export var launch_speed = 1.0  # Speed of upward movement
@export var target_height = 100.0  # Height at which the firework explodes
@export var height_variation = 10.0  # Random variation in height (+/-)
@export var visible_path = true  # Whether to show the path particles
@export var wobble_width = 1
@export var wobble_speed = 0.5
var wobble_angle = 0
var has_reached_target = false
var actual_target_height = 0.0

func _ready():
	# Add random variation to target height
	actual_target_height = target_height + randf_range(-height_variation, height_variation)
	
	# Set path visibility
	var path_particles = get_node("PathParticles")
	if path_particles:
		path_particles.visible = visible_path
	
	get_node("FireLaunch").play()

func set_parameres(width, speed):
	wobble_width = width
	wobble_speed = speed

func _physics_process(delta: float) -> void:
	position.y = position.y + launch_speed
	if path_type == path_type_enum.wobbly:
		wobble_angle += wobble_speed
		position.x = sin(wobble_angle)*wobble_width
	
	# Check if we've reached the actual target height (with variation)
	if !has_reached_target && position.y >= actual_target_height:
		has_reached_target = true
		path_timeout.emit(position)

func _on_path_timer_timeout() -> void:
	# This function can be removed or kept for backwards compatibility
	path_timeout.emit(position)
