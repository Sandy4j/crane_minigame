extends Control
@export var crane_train: Node2D
@onready var claw: Area2D = crane_train.get_node("CraneClaw") if crane_train else null
@onready var grab_button = $GrabBtn
@onready var left_button = $LeftBtn
@onready var right_button = $RightBtn

func _ready():
	if not crane_train or not claw:
		push_error("ControlButtons: crane_train tidak di-assign di Inspector!")
		return

	for btn in [left_button, right_button, grab_button]:
		btn.toggle_mode = true
		btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		btn.button_pressed = false
		btn.mouse_filter = Control.MOUSE_FILTER_STOP

	crane_train.move_finished.connect(_on_move_finished)
	claw.claw_moving_up.connect(_on_claw_moving_up)
	claw.claw_finished.connect(_on_claw_finished)

func _process(_delta):
	if not is_instance_valid(claw): return
	
	var is_idle = (
		crane_train.can_move and 
		crane_train.get_parent().session_active and 
		not (claw.is_busy() or crane_train.is_auto_moving or crane_train._is_tweening())
	)
	
	var filter = Control.MOUSE_FILTER_STOP if is_idle else Control.MOUSE_FILTER_IGNORE
	left_button.mouse_filter = filter
	right_button.mouse_filter = filter
	grab_button.mouse_filter = (Control.MOUSE_FILTER_STOP if (is_idle and crane_train.selected_index >= 0) else Control.MOUSE_FILTER_IGNORE)

	# Sinkronisasi visual tombol saat pemain menggunakan Input Action
	if is_idle:
		if Input.is_action_just_pressed("left") and crane_train.selected_index >= 0:
			left_button.button_pressed = true
			right_button.button_pressed = false
			grab_button.button_pressed = false
		elif Input.is_action_just_pressed("right"):
			right_button.button_pressed = true
			left_button.button_pressed = false
			grab_button.button_pressed = false
		elif Input.is_action_just_pressed("grab") and crane_train.selected_index >= 0:
			grab_button.button_pressed = true
			left_button.button_pressed = false
			right_button.button_pressed = false

func _on_left_btn_pressed():
	left_button.button_pressed = true
	right_button.button_pressed = false
	grab_button.button_pressed = false
	crane_train._select_box(-1)

func _on_right_btn_pressed():
	right_button.button_pressed = true
	left_button.button_pressed = false
	grab_button.button_pressed = false
	crane_train._select_box(1)

func _on_grab_btn_pressed():
	grab_button.button_pressed = true
	left_button.button_pressed = false
	right_button.button_pressed = false
	crane_train._trigger_drop()

func _on_move_finished():
	left_button.button_pressed = false
	right_button.button_pressed = false

func _on_claw_moving_up():
	grab_button.button_pressed = false

func _on_claw_finished():
	left_button.button_pressed = false
	right_button.button_pressed = false
	grab_button.button_pressed = false
