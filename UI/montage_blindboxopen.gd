extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dim: ColorRect = $"../Dimmer"

func _get_box_letter(texture: Texture2D) -> String:
	if texture == null:
		return "a"
	var path = texture.resource_path.to_lower()
	if "box_a" in path: return "a"
	if "box_b" in path: return "b"
	if "box_c" in path: return "c"
	if "box_d" in path: return "d"
	return "a"

func play_montage(box_texture: Texture2D = null) -> void:
	var letter = _get_box_letter(box_texture)
	var new_frames = SpriteFrames.new()
	if not new_frames.has_animation("default"):
		new_frames.add_animation("default")
	
	for i in range(16):
		var frame_str = "%04d" % i
		var tex_path = ""
		if letter == "a":
			tex_path = "res://Asset/montage/montage_blindbox_a_%s.png" % frame_str
		elif letter == "b":
			tex_path = "res://Asset/montage/Montage_Blindbox_B_%s.png" % frame_str
		elif letter == "c":
			tex_path = "res://Asset/montage/Montage_Blindbox_C_%s.png" % frame_str
		elif letter == "d":
			tex_path = "res://Asset/montage/Montage_Blindbox_D_%s.png" % frame_str
			
		var tex = load(tex_path)
		if tex != null:
			new_frames.add_frame("default", tex)
	
	animated_sprite.sprite_frames = new_frames
	animated_sprite.animation = "default"
	
	show()
	dim.visible = true
	animation_player.play("default")
	await animation_player.animation_finished
	dim.visible = false
	hide()
