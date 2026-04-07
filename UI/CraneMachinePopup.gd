extends CanvasLayer

@onready var cost_value: Label = $PopupRoot/Panel/VLayout/CostRow/CostValue
@onready var warning_label: Label = $PopupRoot/Panel/VLayout/WarningLabel
@onready var start_button: TextureButton = $PopupRoot/Panel/VLayout/ButtonRow/StartButton
@onready var exit_button: TextureButton = $PopupRoot/Panel/VLayout/ButtonRow/ExitButton

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	visible = false

func open(cost: int, current_aurum: int, machine_empty: bool = false) -> void:
	cost_value.text = str(cost)
	warning_label.visible = false

	# Disable start button jika aurum tidak cukup atau mesin habis
	var can_play: bool = current_aurum >= cost and not machine_empty
	start_button.modulate.a = 1.0 if can_play else 0.45
	start_button.disabled = not can_play

	visible = true

func close() -> void:
	visible = false

func show_warning() -> void:
	warning_label.visible = true

func _on_start_pressed() -> void:
	get_parent().try_start_session()

func _on_exit_pressed() -> void:
	get_tree().quit()
