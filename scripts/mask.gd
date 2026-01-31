@tool extends Node3D
class_name Mask

@onready var model_container: Node3D = $ModelContainer
@onready var area_3d: Area3D = $Area3D
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var mask_model : MaskModel

var hovered := false
var selected := false
var selectable := true

@export var assigned_shaman: Shaman :
	set(value):
		assigned_shaman = value
		assigned_shaman.assigned_mask = self
		
var mask_resource: MaskResource

func _ready():
	idle()
	animation_player.seek(animation_player.get_animation("idle").length * randf())
	area_3d.mouse_entered.connect(func():
		hovered = true
	)
	area_3d.mouse_exited.connect(func():
		hovered = false
	)

func _input(event: InputEvent) -> void:
	if not (hovered and selectable): return;
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		clicked.emit()
		click_wobble()

func idle():
	animation_player.play("idle")
	animation_player.seek(animation_player.get_animation("idle").length * randf())
	
func wobble():
	animation_player.play("wobble")
	animation_player.seek(animation_player.get_animation("wobble").length * randf())

func click_wobble():
	animation_player.play("click_wobble")

func _process(delta):
	if not get_viewport().get_camera_3d(): return;
	model_container.scale = lerp(model_container.scale, Vector3.ONE if not (hovered and selectable) else Vector3.ONE * 1.3, delta * 10.0)
	
	if not selectable: model_container.position.y = lerp(model_container.position.y, 0.0, delta * 5.0)
	else:
		model_container.position.y = lerp(model_container.position.y,
		sin(Time.get_ticks_msec() / 1000.0 * TAU) * 0.1 if selected else sin(Time.get_ticks_msec() / 1000.0 * TAU) * 0.05
		, delta * 5.0)
		
	if assigned_shaman:
		global_position = lerp(global_position, assigned_shaman.mask_position.global_position, delta * 5.0)
	
	if mask_model and assigned_shaman:
		mask_model.is_emissive_active = assigned_shaman.is_valid
		mask_model.is_light_active = selected
	
	look_at(get_viewport().get_camera_3d().position)

func load_resource(res: MaskResource):
	mask_resource = res
	for child in model_container.get_children(): child.queue_free()
	mask_model = res.model_scene.instantiate() as MaskModel
	model_container.add_child(mask_model)

func play_is_valid_audio():
	audio_stream_player_3d.stream = mask_resource.audio_is_valid
	audio_stream_player_3d.play()

func play_is_selected_audio():
	audio_stream_player_3d.stream = mask_resource.audio_is_selected
	audio_stream_player_3d.play()

signal clicked()
