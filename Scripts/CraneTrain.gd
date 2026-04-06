extends Node2D

@export var speed: float = 100.0
@export var drop_zone_x: float = 220.0
@export var snap_speed: float = 200.0

var can_move: bool = true
var is_auto_moving: bool = false
var has_deducted_for_session: bool = false
var selected_index: int = -1
var box_targets: Array[Area2D] = []
var movement_tween: Tween = null

@onready var claw = $CraneClaw
@onready var crane_machine = get_parent()


func _ready():
	_refresh_box_targets()
	_snap_to_selected_box(false)
	
	claw.box_dropped.connect(_on_box_dropped)

func _process(delta):
	if is_auto_moving:
		return

	if can_move and not _is_tweening() and not claw.is_busy():
		if Input.is_action_just_pressed("left"):
			_select_box(-1)
		elif Input.is_action_just_pressed("right"):
			_select_box(1)

	if Input.is_action_just_pressed("grab"):
		_trigger_drop()

func _trigger_drop():
	if claw.is_busy():
		return

	if claw.grabbed_box == null:
		can_move = false
		claw.drop()

func on_claw_grabbed():
	_stop_tween()
	is_auto_moving = true
	_tween_to_x(drop_zone_x, speed, func():
		is_auto_moving = false
		claw.release_box()
	)

func on_claw_finished():
	can_move = true
	has_deducted_for_session = false
	_refresh_box_targets()
	_snap_to_selected_box(false)

func _on_box_dropped():
	can_move = true
	has_deducted_for_session = false
	_refresh_box_targets()
	_snap_to_selected_box(false)

func _select_box(direction: int) -> void:
	_refresh_box_targets()
	if box_targets.is_empty():
		return

	if selected_index < 0:
		selected_index = 0

	var new_index: int = clamp(selected_index + direction, 0, box_targets.size() - 1)
	if new_index == selected_index:
		return

	if not has_deducted_for_session:
		# Aurum dipotong saat mulai memilih posisi box.
		crane_machine.start_pending_session()
		has_deducted_for_session = true

	selected_index = new_index
	_snap_to_selected_box(true)

func _refresh_box_targets() -> void:
	var boxes := get_tree().get_nodes_in_group("box")
	box_targets.clear()
	for node in boxes:
		if node is Area2D and is_instance_valid(node):
			box_targets.append(node)

	box_targets.sort_custom(func(a: Area2D, b: Area2D):
		return a.global_position.x < b.global_position.x
	)

	if box_targets.is_empty():
		selected_index = -1
		return

	if selected_index < 0 or selected_index >= box_targets.size():
		selected_index = _find_nearest_box_index()

func _find_nearest_box_index() -> int:
	if box_targets.is_empty():
		return -1

	var claw_global_x: float = claw.global_position.x
	var nearest_index := 0
	var nearest_distance: float = abs(box_targets[0].global_position.x - claw_global_x)

	for i in range(1, box_targets.size()):
		var candidate_distance: float = abs(box_targets[i].global_position.x - claw_global_x)
		if candidate_distance < nearest_distance:
			nearest_distance = candidate_distance
			nearest_index = i

	return nearest_index

func _snap_to_selected_box(use_tween: bool) -> void:
	if selected_index < 0 or selected_index >= box_targets.size():
		return

	var target_x: float = box_targets[selected_index].global_position.x - claw.position.x
	if use_tween:
		_tween_to_x(target_x, snap_speed)
	else:
		_stop_tween()
		position.x = target_x

func _tween_to_x(target_x: float, move_speed: float, on_finished: Callable = Callable()) -> void:
	_stop_tween()

	var distance: float = abs(position.x - target_x)
	if distance <= 0.01:
		position.x = target_x
		if on_finished.is_valid():
			on_finished.call()
		return

	var duration: float = distance / max(move_speed, 1.0)
	movement_tween = create_tween()
	movement_tween.set_trans(Tween.TRANS_SINE)
	movement_tween.set_ease(Tween.EASE_OUT)
	movement_tween.tween_property(self, "position:x", target_x, duration)
	if on_finished.is_valid():
		movement_tween.finished.connect(func(): on_finished.call(), CONNECT_ONE_SHOT)

func _stop_tween() -> void:
	if movement_tween != null:
		movement_tween.kill()
		movement_tween = null

func _is_tweening() -> bool:
	return movement_tween != null and movement_tween.is_running()
