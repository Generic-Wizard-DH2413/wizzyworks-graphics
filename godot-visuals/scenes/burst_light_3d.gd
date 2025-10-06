extends Node3D

#const DEFAULT_CULL_DISTANCE := 140.0
@export var col_white_boost: float = 1.7
@export var peak_energy: float = 6.0
@export var incr_time: float = 0.32
@export var decr_time: float = 3.32
@export var range_start: float = 0.1
@export var range_mid: float = 45.0

func spawn_burst_light(
	pos: Vector3,
	color: Color,
	peak_energy: float = peak_energy,
	incr_time: float = incr_time,
	decr_time: float = decr_time,
	range_start: float = range_start,
	range_mid: float = range_mid,
	cast_shadows: bool = true, #should be true for hero lights
	#cull_distance: float = DEFAULT_CULL_DISTANCE
) -> void:
	#var cam := get_viewport().get_camera_3d()
	#if cam and cam.global_position.distance_to(pos) > cull_distance:
	#	return

	var L := OmniLight3D.new()
	L.light_color = color * col_white_boost
	L.light_energy = peak_energy
	L.light_volumetric_fog_energy = 4.0   # brighten fog specifically

	L.omni_range = range_start        # use `omni_range` if your Godot build requires it
	L.shadow_enabled = cast_shadows
	#L.light_size = 100.05
	#L.omni_attenuation = 2.0 
	#L.volumetric_fog_energy = 2.0 
	L.global_position = pos
	#print(pos)
	#add_child(L)
	get_tree().current_scene.add_child(L)
	#print("E=",L.light_energy," R=",L.omni_range," size=",L.light_size)


	var t1 := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var t2 := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	t1.tween_property(L, "light_energy", 0.0, (incr_time+decr_time))
	t2.tween_property(L, "omni_range", range_mid, incr_time)
	t2.finished.connect(func ():
		t2.tween_property(L, "omni_range", 0.0, decr_time)
	)
	#t.parallel().tween_property(L, "omni_range", range_mid, incr_time)
	t1.finished.connect(func ():
		if is_instance_valid(L):
			L.queue_free()
	)
	
	
	
