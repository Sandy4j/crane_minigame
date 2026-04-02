extends Node2D

@export var speed: float = 100.0
@export var auto_speed: float = 100.0
@export var drop_zone_x: float = 220.0

var min_x: float = 220.0
var max_x: float = 433.0
var can_move: bool = true
var is_auto_moving: bool = false
var has_deducted_for_session: bool = false

@onready var claw = $CraneClaw
@onready var crane_machine = get_parent()


func _ready():
	# Dengarkan sinyal box_dropped untuk tahu kapan box sudah dilepas
	claw.box_dropped.connect(_on_box_dropped)

func _process(delta):
	if is_auto_moving:
		position.x = move_toward(position.x, drop_zone_x, auto_speed * delta)
		if position.x == drop_zone_x:
			is_auto_moving = false
			claw.release_box()
		return

	if can_move:
		var is_moving = Input.is_action_pressed("left") or Input.is_action_pressed("right")
		if is_moving and not has_deducted_for_session:
			# Aurum dipotong saat train mulai bergerak
			crane_machine.start_pending_session()
			has_deducted_for_session = true
		
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

	if claw.grabbed_box == null:
		can_move = false
		claw.drop()

func on_claw_grabbed():
	is_auto_moving = true

func on_claw_finished():
	can_move = true
	has_deducted_for_session = false

func _on_box_dropped():
	can_move = true
	has_deducted_for_session = false
