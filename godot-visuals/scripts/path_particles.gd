extends GPUParticles3D

var time = 0
func _process(delta):
	process_material.set_shader_parameter("time", time)
	time += delta
