extends Control

signal result_closed

const STAR_TEXTURE = preload("res://Asset/font/Crane_RarityStars.png")

@onready var item_image: TextureRect = $Panel/VLayout/ItemImage
@onready var item_name: Label = $Panel/VLayout/ItemName
@onready var back_button: TextureButton = $Panel/VLayout/BackButton
@onready var stars: HBoxContainer = $Panel/VLayout/RarityStars

var _reward_texture_cache: Dictionary = {}

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	visible = false

func show_result() -> void:
	var reward = PoolsRewards.get_random_reward()
	
	var res_path: String = reward["texture_path"]
	var tex := _get_cached_reward_texture(res_path)
	var display_name = reward["name"].capitalize()
	
	item_name.text = display_name
	item_image.texture = tex
	
	_update_stars(reward["rarity"])
	
	visible = true

func _get_cached_reward_texture(path: String) -> Texture2D:
	if _reward_texture_cache.has(path):
		return _reward_texture_cache[path]
	var loaded := load(path) as Texture2D
	if loaded != null:
		_reward_texture_cache[path] = loaded
	return loaded

func _update_stars(rarity: int) -> void:
	for child in stars.get_children():
		child.queue_free()

	for i in rarity:
		var star = TextureRect.new()
		star.texture = STAR_TEXTURE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.custom_minimum_size = Vector2(30, 30)
		stars.add_child(star)

func _input(event):
	if visible and event.is_action_pressed("grab"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()

func _on_back_pressed() -> void:
	visible = false
	result_closed.emit()
