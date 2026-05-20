extends Control
@export var crane_train: Node2D
@onready var claw: Area2D = crane_train.get_node("CraneClaw") if crane_train else null
@onready var grab_button = $GrabBtn
@onready var left_button = $LeftBtn
@onready var right_button = $RightBtn

# Tracking mouse hovering button
var _hovering_buttons := {}

func _ready():
	if not crane_train or not claw:
		push_error("ControlButtons: crane_train tidak di-assign di Inspector!")
		return

	for btn in [left_button, right_button, grab_button]:
		btn.toggle_mode = true
		btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		btn.button_pressed = false
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.focus_mode = Control.FOCUS_NONE

		btn.mouse_entered.connect(_on_btn_mouse_entered.bind(btn))
		btn.mouse_exited.connect(_on_btn_mouse_exited.bind(btn))
		_hovering_buttons[btn] = false

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
		if Input.is_action_just_pressed("left"):
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

func _on_btn_mouse_entered(btn: BaseButton) -> void:
	if _hovering_buttons.get(btn, false):
		return
	_hovering_buttons[btn] = true
	AudioManager.play_sfx("sfx_btn_hover")

func _on_btn_mouse_exited(btn: BaseButton) -> void:
	if btn.get_global_rect().has_point(get_global_mouse_position()):
		return
	_hovering_buttons[btn] = false

func _on_left_btn_pressed():
	AudioManager.play_sfx("sfx_btn_move")
	left_button.button_pressed = true
	right_button.button_pressed = false
	grab_button.button_pressed = false
	crane_train._select_box(-1)

func _on_right_btn_pressed():
	AudioManager.play_sfx("sfx_btn_move")
	right_button.button_pressed = true
	left_button.button_pressed = false
	grab_button.button_pressed = false
	crane_train._select_box(1)

func _on_grab_btn_pressed():
	AudioManager.play_sfx("sfx_btn_grab")
	grab_button.button_pressed = true
	left_button.button_pressed = false
	right_button.button_pressed = false
	crane_train._trigger_drop()

func _on_move_finished():
	if left_button.button_pressed or right_button.button_pressed:
		AudioManager.play_sfx("sfx_btn_netral")
	left_button.button_pressed = false
	right_button.button_pressed = false

func _on_claw_moving_up():
	if grab_button.button_pressed:
		AudioManager.play_sfx("sfx_btn_netral")
	grab_button.button_pressed = false

func _on_claw_finished():
	if left_button.button_pressed or right_button.button_pressed or grab_button.button_pressed:
		AudioManager.play_sfx("sfx_btn_netral")
	left_button.button_pressed = false
	right_button.button_pressed = false
	grab_button.button_pressed = false
