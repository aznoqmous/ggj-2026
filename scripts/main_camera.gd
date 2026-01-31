@tool
extends Camera3D
@onready var camera_target: Node3D = $"../CameraTarget"
@export_range(0.1, 2.0, 0.01) var camera_sensitivity := 1.0

func _process(delta: float) -> void:
	var mouse_position = get_viewport().get_mouse_position() - get_viewport().get_visible_rect().size / 2.0
	look_at(camera_target.global_position + Vector3(mouse_position.x, 0, mouse_position.y) / 1000.0 * camera_sensitivity)
	
