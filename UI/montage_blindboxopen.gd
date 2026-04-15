extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var dim: ColorRect = $"../Dimmer"

func play_montage() -> void:
	show()
	dim.visible = true
	animation_player.play("default")
	await animation_player.animation_finished
	dim.visible = false
	hide()
