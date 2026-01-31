extends Node3D
class_name MaskModel

@export var mesh: MeshInstance3D
@export var lights: Array[OmniLight3D]

var is_emissive_active: bool
var is_light_active: bool
var emissive_state: float = 0.0
var light_state: float = 0.0

func _process(delta: float) -> void:
	emissive_state = lerp(emissive_state, 1.0 if is_emissive_active else 0.0, delta * 5.0)
	light_state = lerp(light_state, 1.0 if is_light_active else 0.0, delta * 5.0)
	
	if lights.size():
		for light in lights:
			light.light_energy = lerp(0.1, 1.0, light_state)
			
	if mesh: mesh.material_override.set("emission_energy_multiplier", lerp(0.0, 8.0, emissive_state))
	
