extends HBoxContainer

@onready var grab_button = $GrabButton
@onready var left_button = $LeftButton
@onready var right_button = $RightButton

func _on_grab_button_pressed():
	_simulate_action("grab")


func _on_left_button_pressed():
	_simulate_action("left")


func _on_right_button_pressed():
	_simulate_action("right")


func _simulate_action(action_name: String):
	Input.action_press(action_name)
	await get_tree().process_frame
	Input.action_release(action_name)
