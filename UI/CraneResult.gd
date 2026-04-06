extends CanvasLayer

@onready var box_image: TextureRect = $Root/Panel/VLayout/ImageFrame/BoxImage
@onready var box_name: Label = $Root/Panel/VLayout/BoxName
@onready var back_button: TextureButton = $Root/Panel/VLayout/BackButton


func _ready():
	back_button.pressed.connect(_on_back_pressed)
	visible = false


func show_result(item_name: String, item_texture: Texture2D) -> void:
	box_name.text = item_name
	box_image.texture = item_texture
	visible = true


func _on_back_pressed() -> void:
	visible = false
	get_parent().end_session()
