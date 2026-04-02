extends CanvasLayer

@onready var aurum_label: Label = $Control/HUDBar/Content/AurumLabel
@onready var status_label: Label = $Control/HUDBar/Content/StatusLabel
@onready var status_dot: ColorRect = $Control/HUDBar/Content/StatusDot

const COLOR_IDLE    := Color(0.23, 0.36, 0.23, 1)
const COLOR_ACTIVE  := Color(0.49, 0.81, 0.49, 1)
const COLOR_EMPTY   := Color(0.5, 0.2, 0.2, 1)

func _ready():
	var machine = get_parent()
	machine.aurum_changed.connect(_on_aurum_changed)
	machine.session_started.connect(_on_session_started)
	machine.session_ended.connect(_on_session_ended)
	machine.machine_empty.connect(_on_machine_empty)

	_set_status("Idle", COLOR_IDLE)
	aurum_label.text = str(machine.aurum)

func _on_aurum_changed(new_amount: int) -> void:
	aurum_label.text = str(new_amount)

func _on_session_started() -> void:
	_set_status("Playing", COLOR_ACTIVE)

func _on_session_ended() -> void:
	_set_status("Idle", COLOR_IDLE)

func _on_machine_empty() -> void:
	_set_status("Empty", COLOR_EMPTY)

func _set_status(text: String, dot_color: Color) -> void:
	status_label.text = text
	status_dot.color = dot_color
