extends Node3D
class_name Main

@export var mask_scene : PackedScene
@export var shaman_scene : PackedScene
@export var shaman_circle_radius := 3.0
@export var mask_resources : Array[MaskResource]

@onready var camera_target: Node3D = $CameraTarget
@onready var camera_container: Node3D = $CameraContainer
@onready var camera_3d: MainCamera = $CameraContainer/Camera3D
@onready var fire_particles: GPUParticles3D = $WorldEnvironment/Campfire/FireParticles

@onready var shamans_container: Node3D = $ShamansContainer
@onready var masks_container: Node3D = $MasksContainer
@onready var totems_container: Node3D = $TotemsContainer
@onready var rune_label: Label = $RuneLayer/Control/RuneLabel

@export_category("Levels")
@export var levels: Array[LevelResource]
var current_level_index := 0
var current_level_id : String

@export_category("Runes")
@export var rune : Runes

var shamans : Array[Shaman]
var masks : Array[Mask]

var selected_mask: Mask
var is_animating := false
var is_end_level := false
@export var swap_animation_duration := 0.5

@onready var level_complete_audio: AudioStreamPlayer3D = $Audios/LevelCompleteAudio
@onready var fire_burst_audio: AudioStreamPlayer3D = $Audios/FireBurstAudio

func _ready():
	camera_container.global_position.x = 20.0
	camera_container.global_position.y = 80.0
	camera_container.global_position.z = -10.0
	get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).tween_property(camera_container, "global_position:x", 0.0, 5.0)
	get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).tween_property(camera_container, "global_position:y", 0.0, 5.0)
	get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).tween_property(camera_container, "global_position:z", 7.0, 5.0)
	await get_tree().create_timer(5.0 + 1.0).timeout
	load_level(levels[0])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"): next_level()
	if event.is_action_pressed("ui_left"):
		current_level_index = clamp(current_level_index - 1, 0, levels.size() - 1)
		load_level(levels[current_level_index])


func create_mask(pos: Vector3)-> Mask:
	var mask := mask_scene.instantiate() as Mask
	masks_container.add_child(mask)
	masks.push_back(mask)
	mask.global_position = pos
	mask.look_at(Vector3.ZERO)
	mask.clicked.connect(func():
		click_mask(mask)
	)
	return mask

func create_shaman(pos: Vector3) -> Shaman:
	var shaman := shaman_scene.instantiate() as Shaman
	shamans_container.add_child(shaman)
	shamans.push_back(shaman)
	shaman.global_position = pos
	shaman.look_at(Vector3.ZERO)
	return shaman

func click_mask(mask: Mask):
	if is_animating: return
	
	if not selected_mask:
		# select mask
		selected_mask = mask
		mask.selected = true
		update_selectable_masks(selected_mask)
		selected_mask.select_audio.play()
		mask.play_is_selected_audio()
		return;
		
	if selected_mask == mask:
		# unselect mask
		selected_mask.cancel_audio.play()
		selected_mask.selected = false
		selected_mask = null
		update_selectable_masks(null)
	else:
		# swap with selected mask
		rune.add_mask_to_history(current_level_id, selected_mask.mask_resource)
		selected_mask.selected = false
		var target_shaman = selected_mask.assigned_shaman
		selected_mask.assigned_shaman = mask.assigned_shaman
		mask.assigned_shaman = target_shaman
		mask.swap_audio.play()
		await swap_animate()
		apply_effect(selected_mask)
		selected_mask = null
		update_selectable_masks(null)
		validity_check()
		

func swap_animate():
	is_animating = true
	await get_tree().create_timer(swap_animation_duration).timeout
	is_animating = false
	
func apply_effect(mask: Mask):
	match mask.mask_resource.effect:
		MaskResource.Effect.None:
			pass
		MaskResource.Effect.SwapNeighbours:
			var neighbours := get_neighbour_masks(mask)
			var lmask = neighbours[0].assigned_shaman
			neighbours[0].assigned_shaman = neighbours[1].assigned_shaman
			neighbours[1].assigned_shaman = lmask
			mask.swap_audio.play()
			await swap_animate()
		MaskResource.Effect.Clockwise:
			var omasks := get_ordered_masks()
			for i in masks.size():
				var left_index = i - 1
				if i < 0: left_index = masks.size() - 1
				omasks[i].assigned_shaman =  shamans[left_index]
			mask.swap_audio.play()
			await swap_animate()

func update_selectable_masks(mask: Mask):
	for m in masks: m.selectable = true
	if mask:
		match mask.mask_resource.available_move:
			MaskResource.AvailableMove.AdjacentCell:
				for m in masks: m.selectable = false
				for n in get_neighbour_masks(mask): n.selectable = true
			MaskResource.AvailableMove.All:
				pass
				
		# user must have the choice to unselect current mask
		mask.selectable = true
	
	for m in masks:
		if mask and m.selectable: m.wobble()
		else: m.idle()

func validity_check():
	var nonvalid_shamans = shamans.filter(func(s: Shaman): return not s.is_valid)
	if nonvalid_shamans.size() <= 0: return await end_level()
	is_animating = true
	for shaman in shamans:
		if shaman.is_valid:
			shaman.assigned_mask.play_is_valid_audio()
			shaman.assigned_mask.model_container.scale = Vector3.ONE * 1.5
			shaman.assigned_mask.click_wobble()
			await get_tree().create_timer(0.3).timeout
		if shaman: shaman.was_valid = shaman.is_valid
	is_animating = false

func get_neighbour_masks(mask: Mask) -> Array[Mask]:
	var masks: Array[Mask]
	var index = shamans.find(mask.assigned_shaman)
	var left_index = index - 1
	if left_index < 0: left_index = shamans.size() - 1
	var right_index = (index + 1) % shamans.size()
	masks.push_back(shamans[left_index].assigned_mask)
	masks.push_back(shamans[right_index].assigned_mask)
	return masks

func get_ordered_masks() -> Array:
	return shamans.map(func(s: Shaman): return s.assigned_mask)
	
func load_level(level_resource: LevelResource):
	is_animating = true
	
	get_tree().create_tween().tween_property(fire_particles.process_material, "scale_max", 40.0, 0.5)
	get_tree().create_tween().tween_property(fire_particles.process_material, "emission_sphere_radius", 5.0, 0.5)
	fire_burst_audio.play()
	
	await get_tree().create_timer(1).timeout
	for shaman in shamans:
		get_tree().create_tween().tween_property(shaman, "position:x", 0.0, 0.5)
		get_tree().create_tween().tween_property(shaman, "position:z", 0.0, 0.5)
		get_tree().create_tween().tween_property(shaman, "position:y", -10.0, 0.5)
		await get_tree().create_timer(0.1).timeout
		
	await get_tree().create_timer(0.5).timeout
	
	get_tree().create_tween().tween_property(fire_particles.process_material, "scale_max", 4.0, 0.5)
	get_tree().create_tween().tween_property(fire_particles.process_material, "emission_sphere_radius", 1.0, 0.5)
	
	print("Loading level : ", level_resource.resource_path)
	
	current_level_id = level_resource.resource_path# you can replace to anything that identify a level
	rune.set_history(current_level_id, [])
	
	for s in shamans_container.get_children(): s.queue_free()
	shamans.clear()
	
	for m in masks_container.get_children(): m.queue_free()
	masks.clear()

	await get_tree().create_timer(0.5).timeout
	
	var count :float= level_resource.shamans_needed_masks.size()
	for i in count:
		var shaman : Shaman = create_shaman(Vector3.LEFT.rotated(Vector3.UP, i / count * TAU - PI / 2.0 + (TAU / count) / 2.0) * shaman_circle_radius + Vector3.DOWN * 5.0)
		shaman.needed_mask = level_resource.shamans_needed_masks[i]
		var mask = create_mask(shaman.mask_position.global_position + Vector3.UP * 20.0)
		mask.load_resource(level_resource.shamans_starting_masks[i])
	
	await get_tree().create_timer(1.0).timeout
	var anim_duration = 1.0
	for i in count:
		await get_tree().create_timer(anim_duration / count).timeout
		masks[i].assigned_shaman = shamans[i]
		shamans[i].was_valid = shamans[i].is_valid
		masks[i].swap_audio.play()
	is_animating = false
	
func animate_runes(duration):
	rune_label.text = ""
	var runes = rune.get_history_parsed(str(current_level_id))
	for char in runes:
		rune_label.text += char
		await get_tree().create_timer(duration / runes.length()).timeout
		
func end_level():
	is_end_level = true
	is_animating = true
	
	print("level runes: "+ rune.get_history_parsed(current_level_id))
	
	get_tree().create_tween().tween_property(camera_3d, "zoom", 2.0, 0.5)
	await get_tree().create_timer(0.5).timeout

	var shaman_anim_duration = 0.3
	#animate_runes(shamans.size() * shaman_anim_duration)
	for shaman in shamans:
		if shaman.is_valid:
			shaman.assigned_mask.play_is_valid_audio()
			shaman.assigned_mask.model_container.scale = Vector3.ONE * 1.5
			shaman.assigned_mask.click_wobble()
			await get_tree().create_timer(shaman_anim_duration).timeout
			
	rune_label.text = ""
	
	# do wowzers animation
	camera_3d.current_camera_target = camera_3d.totem_camera_target
	get_tree().create_tween().tween_property(camera_3d, "zoom", 5.0, 0.5)
	
	await get_tree().create_timer(0.5).timeout
	var totem := totems_container.get_children()[current_level_index] as Totem
	totem.mesh.material_override.set("emission", mask_resources[floor(current_level_index / 3)].color)
	totem.is_active = true
	totem.activated_audio.play()
	
	level_complete_audio.play()
	
	await get_tree().create_timer(1.5).timeout
	
	camera_3d.current_camera_target = camera_3d.camera_target
	get_tree().create_tween().tween_property(camera_3d, "zoom", 0.0, 0.5)
	
	rune_label.text = ""
	
	next_level()
	is_animating = false
	is_end_level = false
	

func next_level():
	if current_level_index + 1 >= levels.size(): return end_game()
	current_level_index = (current_level_index + 1) % levels.size()
	load_level(levels[current_level_index])

func end_game():
	print("end game")
	pass
