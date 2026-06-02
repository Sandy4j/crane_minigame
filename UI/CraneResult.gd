extends Control

signal result_closed
signal reward_collected(reward_data: Dictionary)

const STAR_TEXTURE = preload("res://Asset/font/Crane_RarityStars.png")

@onready var item_image: TextureRect = $Panel/VLayout/ItemImage
@onready var item_name: Label = $Panel/VLayout/ItemName
@onready var back_button: TextureButton = $Panel/VLayout/BackButton
@onready var stars: HBoxContainer = $Panel/VLayout/RarityStars

var _reward_texture_cache: Dictionary = {}
var _current_reward: Dictionary = {}

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	visible = false

func show_result() -> void:
	_current_reward = PoolsRewards.get_random_reward()
	
	var res_path: String = _current_reward["texture_path"]
	var tex := _get_cached_reward_texture(res_path)
	var display_name = _current_reward["name"].capitalize()
	
	item_name.text = display_name
	item_image.texture = tex
	
	_update_stars(_current_reward["rarity"])
	
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
	if not _current_reward.is_empty():
		reward_collected.emit(_current_reward)
		_current_reward = {}
	result_closed.emit()
