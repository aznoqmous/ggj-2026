extends Node
class_name Runes

class levelMaskResourceHistory:
	var array : Array[MaskResource]
var _level_history_dictionnary : Dictionary[String, levelMaskResourceHistory]

@export var _mask_default_rune : String = '?'
@export var _mask_rune_dictionnary : Dictionary[MaskResource, String] = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_level_history_dictionnary = {}

# rune generation
func get_mask_rune(mask : MaskResource) -> String:
	if (!_mask_rune_dictionnary.has(mask)):
		return _mask_default_rune
	return _mask_rune_dictionnary[mask]

func get_masks_rune(masks : Array[MaskResource]) -> String:
	var runes : String = ""
	for mask in masks:
		runes += get_mask_rune(mask)
	return runes

# history manipulation

func set_history(levelId : String, history : Array[MaskResource]) -> void:
	var levelHistory = levelMaskResourceHistory.new()
	levelHistory.array = history
	_level_history_dictionnary[levelId] = levelHistory

func add_mask_to_history(levelId : String, mask : MaskResource) -> void:
	var levelHistory = _level_history_dictionnary[levelId]
	levelHistory.array.append(mask)
	_level_history_dictionnary[levelId] = levelHistory

func get_history_object(levelId : String) -> levelMaskResourceHistory:
	return _level_history_dictionnary[levelId]
	
func get_history_parsed(levelId : String) -> String:
	return get_masks_rune(get_history_object(levelId).array)