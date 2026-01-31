@tool extends Node3D
class_name Mask

@onready var model_container: Node3D = $ModelContainer
@onready var area_3d: Area3D = $Area3D

var hovered := false
var selected := false
var selectable := true

var assigned_shaman: Shaman :
	set(value):
		assigned_shaman = value
		assigned_shaman.assigned_mask = self
		
var mask_resource: MaskResource

func _ready():
	area_3d.mouse_entered.connect(func():
		hovered = true
		print("HOVERED")
	)
	area_3d.mouse_exited.connect(func():
		hovered = false
	)

func _input(event: InputEvent) -> void:
	if not (hovered and selectable): return;
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		clicked.emit()

func _process(delta):
	if not get_viewport().get_camera_3d(): return;
	model_container.scale = lerp(model_container.scale, Vector3.ONE if not (hovered and selectable) else Vector3.ONE * 1.5, delta * 5.0)
	model_container.position.y = lerp(model_container.position.y,
		sin(Time.get_ticks_msec() / 1000.0 * TAU) * 0.1 if selected else sin(Time.get_ticks_msec() / 1000.0 * TAU) * 0.01
	, delta * 5.0)
	if assigned_shaman:
		global_position = lerp(global_position, assigned_shaman.mask_position.global_position, delta * 5.0)
		
	look_at(get_viewport().get_camera_3d().position)

func load_resource(res: MaskResource):
	mask_resource = res
	for child in model_container.get_children(): child.queue_free()
	model_container.add_child(res.model_scene.instantiate())

signal clicked()
