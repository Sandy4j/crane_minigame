extends Control

@onready var grab_button = $GrabBtn
@onready var left_button = $LeftBtn
@onready var right_button = $RightBtn

func _simulate_action(action_name: String):
	Input.action_press(action_name)
	await get_tree().process_frame
	Input.action_release(action_name)

func _on_left_btn_pressed():
	_simulate_action("left")


func _on_right_btn_pressed():
	_simulate_action("right")


func _on_grab_btn_pressed():
	_simulate_action("grab")

