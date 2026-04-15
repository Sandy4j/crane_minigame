extends Control

@onready var exit_button: TextureButton = $Panel/VLayout/ExitButton

func _ready():
	exit_button.pressed.connect(_on_exit_pressed)
	visible = false

func open() -> void:
	visible = true

func close() -> void:
	visible = false

func _on_exit_pressed() -> void:
	get_tree().quit()
