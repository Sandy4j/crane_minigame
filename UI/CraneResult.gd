extends Control

signal result_closed

@onready var item_image: TextureRect = $Panel/VLayout/ImageFrame/ItemImage
@onready var item_name: Label = $Panel/VLayout/ItemName
@onready var back_button: TextureButton = $Panel/VLayout/BackButton

var item_list = [
	"decorations_wall_bianlian.png",
	"decorations_wall_bluespirit.png",
	"decorations_wall_cepot.png",
	"decorations_wall_dewi.png",
	"decorations_wall_kitsune.png",
	"decorations_wall_tengu.png"
]

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	visible = false

func show_result(_item_name: String, _item_texture: Texture2D) -> void:
	var random_item = item_list[randi() % item_list.size()]
	
	var res_path = "res://Asset/item hadiah/" + random_item
	var tex = load(res_path)
	var name = random_item.replace("decorations_wall_", "").replace(".png", "").capitalize()
	
	item_name.text = name
	item_image.texture = tex
	visible = true

func _input(event):
	if visible and event.is_action_pressed("grab"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()

func _on_back_pressed() -> void:
	visible = false
	result_closed.emit()
