extends Camera3D

@export var target: Node3D
@export var follow_speed := 5.0
@export var offset := Vector3(0, 2, 6)

func _process(delta):
	if not target:
		return

	var target_pos = target.global_position + offset
	target_pos.z = global_position.z  # lock 2.5D camera motion

	global_position = global_position.lerp(target_pos, delta * follow_speed)
	rotation_degrees = Vector3.ZERO
