extends Node2D

signal move_finished

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
@onready var boxes_node: Node2D = get_parent().get_node("Boxes")

func _ready():
	_return_to_drop_zone(false)
	_refresh_box_targets()

	claw.box_dropped.connect(_reset_after_session)
	claw.grab_failed.connect(_reset_after_session)
	claw.claw_returned_with_box.connect(on_claw_grabbed)
	claw.claw_returned_empty.connect(on_claw_finished)

func _process(_delta):
	if is_auto_moving:
		return

	if can_move and not _is_tweening() and not claw.is_busy():
		if Input.is_action_just_pressed("left"):
			_select_box(-1)
		elif Input.is_action_just_pressed("right"):
			_select_box(1)

	if Input.is_action_just_pressed("grab"):
		_trigger_drop()

## Dipanggil saat tombol grab ditekan
func _trigger_drop():
	if not can_move or not crane_machine.session_active: return
	if selected_index < 0: return
	if is_auto_moving or claw.is_busy(): return
	if claw.grabbed_box == null:
		can_move = false
		claw.drop()

## Dipanggil saat claw berhasil grab box
func on_claw_grabbed():
	_stop_tween()
	is_auto_moving = true
	_tween_to_x(drop_zone_x, speed, func():
		is_auto_moving = false
		claw.release_box()
	)

## Dipanggil setelah sesi selesai, baik berhasil maupun gagal
func on_claw_finished():
	_reset_after_session()

## Reset state saat sesi selesai
func _reset_after_session() -> void:
	has_deducted_for_session = false
	selected_index = -1
	_return_to_drop_zone(true, func(): _refresh_box_targets())


## Potong aurum hanya sekali per gerakan awal box
func _try_deduct_session() -> void:
	if not has_deducted_for_session:
		crane_machine.start_pending_session()
		has_deducted_for_session = true

## Pilih box berdasarkan posisi claw
func _select_box(direction: int) -> void:
	if is_auto_moving or claw.is_busy(): return 
	_refresh_box_targets()
	if box_targets.is_empty():
		return

	if selected_index < 0:
		if direction < 0:
			_bump_effect(direction)
			return
		selected_index = _find_initial_index()
		_try_deduct_session()
		_snap_to_selected_box()
		return

	var new_index: int = clamp(selected_index + direction, 0, box_targets.size() - 1)
	if new_index == selected_index:
		_bump_effect(direction)
		return

	_try_deduct_session()
	selected_index = new_index
	_snap_to_selected_box()

## Refresh daftar box yang akan dipilih
func _refresh_box_targets() -> void:
	box_targets = boxes_node.get_sorted_boxes()
	if box_targets.is_empty():
		selected_index = -1
		return
	if selected_index >= box_targets.size():
		selected_index = box_targets.size() - 1
	elif selected_index < -1:
		selected_index = -1

## Cari index box pertama di sebelah kanan claw
func _find_initial_index() -> int:
	return boxes_node.find_initial_index(box_targets, claw.global_position.x)

## Snap ke posisi box yang dipilih
func _snap_to_selected_box() -> void:
	if selected_index < 0 or selected_index >= box_targets.size():
		return
	var target_x: float = box_targets[selected_index].global_position.x - claw.position.x
	_tween_to_x(target_x, snap_speed)

## Animasi mentok saat mencoba gerak ke arah yang illegal
func _bump_effect(direction: int) -> void:
	var target_x: float = position.x
	if selected_index >= 0 and selected_index < box_targets.size():
		target_x = box_targets[selected_index].global_position.x - claw.position.x
	elif selected_index >= box_targets.size():
		return
		
	var bump_distance: float = 15.0
	
	_stop_tween()
	movement_tween = create_tween()
	movement_tween.set_trans(Tween.TRANS_SINE)
	
	AudioManager.play_train_move()
	
	movement_tween.tween_property(self, "position:x", target_x + (direction * bump_distance), 0.1).set_ease(Tween.EASE_OUT)
	movement_tween.tween_property(self, "position:x", target_x, 0.1).set_ease(Tween.EASE_IN_OUT)
	
	movement_tween.finished.connect(func():
		AudioManager.stop_train_move()
		move_finished.emit()
	, CONNECT_ONE_SHOT)

## Kembali ke posisi drop zone
func _return_to_drop_zone(use_tween: bool, on_finished: Callable = Callable()) -> void:
	if use_tween:
		_tween_to_x(drop_zone_x, speed, on_finished)
	else:
		_stop_tween()
		position.x = drop_zone_x
		if on_finished.is_valid():
			on_finished.call()

## Fungsi untuk membuat tween ke posisi tertentu
func _tween_to_x(target_x: float, move_speed: float, on_finished: Callable = Callable()) -> void:
	_stop_tween()
	var distance: float = abs(position.x - target_x)
	if distance <= 0.01:
		position.x = target_x
		if on_finished.is_valid(): on_finished.call()
		move_finished.emit()
		return

	AudioManager.play_train_move()

	var duration: float = distance / max(move_speed, 1.0)
	movement_tween = create_tween()
	movement_tween.set_trans(Tween.TRANS_SINE)
	movement_tween.set_ease(Tween.EASE_OUT)
	movement_tween.tween_property(self, "position:x", target_x, duration)
	
	movement_tween.finished.connect(func():
		AudioManager.stop_train_move()
		if on_finished.is_valid(): on_finished.call()
		move_finished.emit()
	, CONNECT_ONE_SHOT)

## Hentikan tween yang sedang berjalan
func _stop_tween() -> void:
	if movement_tween != null:
		movement_tween.kill()
		movement_tween = null
	AudioManager.stop_train_move()

## Cek apakah sedang ada tween yang berjalan 
func _is_tweening() -> bool:
	return movement_tween != null and movement_tween.is_running()
