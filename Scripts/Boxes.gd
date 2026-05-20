extends Node2D

const BOX_TEXTURES = [
	preload("res://Asset/Crane_Game_Box_A.png"),
	preload("res://Asset/Crane_Game_Box_B.png"),
	preload("res://Asset/Crane_Game_Box_C.png"),
	preload("res://Asset/Crane_Game_Box_D.png"),
]	

@onready var boxes: Array = [
	$BoxA,
	$BoxB,
	$BoxC,
	]
	
var current_texture: Texture2D

func randomize_boxes() -> void:
	current_texture = BOX_TEXTURES[randi() % BOX_TEXTURES.size()]
	for i in range(boxes.size()):
		if is_instance_valid(boxes[i]) and boxes[i].has_node("Sprite2D"):
			boxes[i].get_node("Sprite2D").texture = current_texture

func get_sorted_boxes() -> Array[Area2D]:
	var result: Array[Area2D] = []
	for node in boxes:
		if is_instance_valid(node):
			result.append(node)
	result.sort_custom(func(a: Area2D, b: Area2D):
		return a.global_position.x < b.global_position.x
	)
	return result

func find_initial_index(sorted_boxes: Array[Area2D], claw_x: float) -> int:
	for i in range(sorted_boxes.size()):
		if sorted_boxes[i].global_position.x >= claw_x:
			return i
	return sorted_boxes.size() - 1

func has_boxes() -> bool:
	for node in boxes:
		if is_instance_valid(node):
			return true
	return false
