@tool
extends Camera3D
class_name MainCamera

@onready var main: Main = $/root/Main

@onready var camera_target: Node3D = $"../../CameraTarget"
@onready var totem_camera_target: Node3D = $"../../TotemCameraTarget"

@export_range(0.1, 2.0, 0.01) var camera_sensitivity := 1.0
@export_range(0.0, 6.0, 0.01) var zoom := 0.0

var current_camera_target : Node3D
var camera_target_position : Vector3

var screen_shake_time := 0.0
var screen_shake_duration := 1.0
var screen_shake_initial_velocity := Vector2(1.0, 1.0)
var screen_shake_strength := 0.1
var screen_shake_speed := 100.0

func _ready():
	current_camera_target = camera_target
	camera_target_position = camera_target.global_position
	
func _process(delta: float) -> void:
	var mouse_position = get_viewport().get_mouse_position() - get_viewport().get_visible_rect().size / 2.0
	
	if main and not main.is_end_level:
		camera_target_position = lerp(camera_target_position, current_camera_target.global_position + Vector3(mouse_position.x, 0, mouse_position.y) / 1000.0 * camera_sensitivity, delta * 5.0)
		#zoom = lerp(zoom, 0.0, delta * 3.0)
	else:
		camera_target_position = lerp(camera_target_position, current_camera_target.global_position, delta * 5.0)
		#zoom = lerp(zoom, 2.0, delta * 3.0)
	
	var st = (Time.get_ticks_msec() / 1000.0 - screen_shake_time) / screen_shake_duration
	screen_shake_time -= delta
	var screen_shake_position = lerp(
		Vector3.ZERO,
		Vector3(sin(st * TAU * screen_shake_speed * 0.5) * screen_shake_initial_velocity.x, cos(st * TAU * screen_shake_speed) * screen_shake_initial_velocity.y, 0) * screen_shake_strength
	, max(0, screen_shake_time / screen_shake_duration))
	look_at(camera_target_position + screen_shake_position)
	position.z = -zoom

func shake(duration, strength := 0.05, speed := 10.0):
	screen_shake_strength = strength
	screen_shake_speed = speed * duration
	screen_shake_duration = duration
	screen_shake_time = screen_shake_duration
