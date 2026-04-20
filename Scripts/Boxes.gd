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
