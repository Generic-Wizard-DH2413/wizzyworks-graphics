extends Node3D
signal path_timeout(pos)
@export var path_speed = 1.0  # Speed of upward movement
@export var target_height = 70.0  # Height at which the firework explodes
@export var height_variation = 10.0  # Random variation in height (+/-)
@export var visible_path = true  # Whether to show the path particles
@export var wobble_width = 1
@export var wobble_speed = 0.5
var wobble_angle = 0
var has_reached_target = false
var actual_target_height = 0.0
var random_angle_deg = 0.0
var x_increment = 0.0
var base_x = 0.0

func _ready():
	# Add random variation to target height
	actual_target_height = target_height + randf_range(-height_variation, height_variation)
	
	# Set random angle for path direction (1-2 degrees left or right)
	random_angle_deg = randf_range(-5.0, 5.0)
	var angle_rad = deg_to_rad(random_angle_deg)
	x_increment = tan(angle_rad) * path_speed
	
	# Set path visibility
	var path_particles = get_node("PathParticles")
	if path_particles:
		path_particles.visible = visible_path
	
	get_node("FireLaunch").play()

func set_parameters(width, speed):
	wobble_width = width
	wobble_speed = speed

func _physics_process(delta: float) -> void:
	position.y += path_speed * delta * 60
	base_x += x_increment * delta * 60
	wobble_angle += wobble_speed * delta * 60
	position.x = base_x + sin(wobble_angle) * wobble_width
	
	# Check if we've reached the actual target height (with variation)
	if !has_reached_target && position.y >= actual_target_height:
		has_reached_target = true
		path_timeout.emit(position)

func _on_path_timer_timeout() -> void:
	# This function can be removed or kept for backwards compatibility
	path_timeout.emit(position)
