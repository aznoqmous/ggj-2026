@tool
extends Node3D
class_name Shaman

@export var mask_position: Node3D
@export var correct_mask_particles: GPUParticles3D

@onready var selectable_light: OmniLight3D = $SelectableLight
@onready var main: Main = $/root/Main

var needed_mask : MaskResource
var assigned_mask: Mask :
	set(value):
		assigned_mask = value
		update_particles()

var was_valid := false
var is_valid : bool :
	get: return assigned_mask and assigned_mask.mask_resource == needed_mask
	
func update_particles():
	correct_mask_particles.emitting = assigned_mask.mask_resource == needed_mask

func _process(delta: float) -> void:
	look_at(Vector3.ZERO)
	if main: selectable_light.omni_range = lerp(selectable_light.omni_range, 1.0 if main.selected_mask and assigned_mask and assigned_mask.selectable else 0.0, delta * 5.0)
