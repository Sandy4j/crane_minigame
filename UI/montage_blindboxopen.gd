extends Node2D

const MONTAGE_FRAMES_PATHS := {
	"a": "res://UI/MontageSpriteFrames/Box_A.tres",
	"b": "res://UI/MontageSpriteFrames/Box_B.tres",
	"c": "res://UI/MontageSpriteFrames/Box_C.tres",
	"d": "res://UI/MontageSpriteFrames/Box_D.tres",
}

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dim: ColorRect = $"../Dimmer"

var _montage_frames_cache: Dictionary = {}

func _get_box_letter(texture: Texture2D) -> String:
	if texture == null:
		return "a"
	var path = texture.resource_path.to_lower()
	if "box_a" in path:
		return "a"
	if "box_b" in path:
		return "b"
	if "box_c" in path:
		return "c"
	if "box_d" in path:
		return "d"
	return "a"

func _get_montage_frames(letter: String) -> SpriteFrames:
	if not _montage_frames_cache.has(letter):
		var path: String = MONTAGE_FRAMES_PATHS.get(letter, MONTAGE_FRAMES_PATHS["a"])
		_montage_frames_cache[letter] = load(path) as SpriteFrames
	return _montage_frames_cache[letter]

func play_montage(box_texture: Texture2D = null) -> void:
	var letter := _get_box_letter(box_texture)
	var frames := _get_montage_frames(letter)
	animated_sprite.sprite_frames = frames
	animated_sprite.animation = letter
	animated_sprite.frame = 0

	show()
	dim.visible = true
	AudioManager.play_sfx("montage")
	animation_player.play("default")
	await animation_player.animation_finished
	dim.visible = false
	hide()
