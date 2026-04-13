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
	
func _get_random_box_textures() -> Array:
	var pool = BOX_TEXTURES.duplicate()
	pool.shuffle()
	return pool.slice(0, 3)

func randomize_boxes() -> void:
	var new_textures = _get_random_box_textures()
	for i in range(boxes.size()):
		if is_instance_valid(boxes[i]) and boxes[i].has_node("Sprite2D"):
			boxes[i].get_node("Sprite2D").texture = new_textures[i]
