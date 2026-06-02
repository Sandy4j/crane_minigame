extends Control

@onready var exit_button: TextureButton = $Panel/VLayout/ExitButton

signal exit_requested

func _ready():
	exit_button.pressed.connect(_on_exit_pressed)
	visible = false

func open() -> void:
	visible = true

func close() -> void:
	visible = false

func _on_exit_pressed() -> void:
	exit_requested.emit()
