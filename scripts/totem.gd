extends Node
class_name Totem

@export var mesh: MeshInstance3D
@onready var activated_audio: AudioStreamPlayer3D = $ActivatedAudio

var active_state = 0.0
var is_active : bool

var randv := .0

func _ready():
	randv = randf()

func _process(delta):
	active_state = lerp(active_state, 1.0 if is_active else 0.0, delta * 2.0)
	mesh.material_override.set("emission_energy_multiplier", lerp(0.0, 1.0 + abs(sin((randv + Time.get_ticks_msec() / 1000.0 / 2.0) * PI)), active_state))
