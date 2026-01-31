extends Node
class_name Runes

class levelMaskModelHistory:
	var array : Array[MaskModel]
var historyDictionnary : Dictionary[String, levelMaskModelHistory]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	historyDictionnary = {}

func setHistory(levelId : String, history : Array[MaskModel]):
	var levelHistory = levelMaskModelHistory.new()
	levelHistory.array = history
	historyDictionnary[levelId] = levelHistory
	
func addMaskToHistory(levelId : String, mask : MaskModel):
	var levelHistory = historyDictionnary[levelId]
	levelHistory.array.append(mask)
	historyDictionnary[levelId] = levelHistory
	
func getHistory(levelId : String):
	return historyDictionnary[levelId]
