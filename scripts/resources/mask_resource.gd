extends Resource
class_name MaskResource

@export var available_move: AvailableMove 
@export var effect: Effect 
@export var model_scene: PackedScene

@export var audio_is_valid : AudioStream
@export var audio_is_selected : AudioStream

enum AvailableMove {
	AdjacentCell,
	All
}

enum Effect {
	None,
	SwapNeighbours,
	Clockwise
}
