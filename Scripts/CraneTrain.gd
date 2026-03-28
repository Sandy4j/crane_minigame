extends Node2D

@export var speed: float = 100.0
var min_x: float = 190.0
var max_x: float = 410.0

var can_move: bool = true

@onready var claw = $CraneClaw

func _process(delta):
	if can_move:
		if Input.is_action_pressed("left"):
			position.x -= speed * delta
		if Input.is_action_pressed("right"):
			position.x += speed * delta
		position.x = clamp(position.x, min_x, max_x)
	
	if Input.is_action_just_pressed("grab"):
		_trigger_drop()

func _trigger_drop():
	if claw.is_busy():
		return
	if claw.grabbed_box != null:
		claw.release_box()
	else:
		can_move = false
		claw.drop()

func on_claw_finished():
	can_move = true
	get_parent().end_session()
