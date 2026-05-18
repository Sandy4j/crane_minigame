extends Control


@onready var camera = $"../Camera2D"
@onready var panel = $Panel

func _ready():
	AudioManager.start_bgm()
	AudioManager.switch_bgm("bgm_menu", 0.5)
	pass

func _on_play_btn_pressed():
	var tween = create_tween()
	
	tween.tween_property(panel, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): panel.visible = false)
	if camera:
		tween.tween_property(camera, "position:y", 180.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_callback(func():
		var machine = get_parent()
		if machine and machine.has_method("trigger_initial_popup"):
			machine.trigger_initial_popup()
	)

func _on_exit_btn_pressed():
	get_tree().quit()
