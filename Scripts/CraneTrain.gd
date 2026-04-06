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
	_return_to_drop_zone(false)
	_refresh_box_targets()

	claw.box_dropped.connect(_reset_after_session)
	claw.grab_failed.connect(_reset_after_session)

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
	if not can_move or not crane_machine.session_active:
		return
	if claw.is_busy():
		return
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
	can_move = true
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
	_refresh_box_targets()
	if box_targets.is_empty():
		return

	if selected_index < 0:
		selected_index = _find_initial_index(direction)
		if selected_index < 0:
			return
		_try_deduct_session()
		_snap_to_selected_box(true)
		return

	var new_index: int = clamp(selected_index + direction, 0, box_targets.size() - 1)
	if new_index == selected_index:
		return

	_try_deduct_session()
	selected_index = new_index
	_snap_to_selected_box(true)

## Refresh daftar box yang akan dipotong
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

	if selected_index >= box_targets.size():
		selected_index = box_targets.size() - 1
	elif selected_index < -1:
		selected_index = -1

## Cari index box pertama yang sesuai dengan posisi claw
func _find_initial_index(direction: int) -> int:
	if box_targets.is_empty():
		return -1

	var claw_global_x: float = claw.global_position.x
	if direction > 0:
		for i in range(box_targets.size()):
			if box_targets[i].global_position.x >= claw_global_x:
				return i
	elif direction < 0:
		for i in range(box_targets.size() - 1, -1, -1):
			if box_targets[i].global_position.x <= claw_global_x:
				return i

	return _find_nearest_box_index()

## Cari index box terdekat
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

## Snap ke posisi box yang dipilih
func _snap_to_selected_box(use_tween: bool) -> void:
	if selected_index < 0 or selected_index >= box_targets.size():
		return

	var target_x: float = box_targets[selected_index].global_position.x - claw.position.x
	if use_tween:
		_tween_to_x(target_x, snap_speed)
	else:
		_stop_tween()
		position.x = target_x

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

## Hentikan tween yang sedang berjalan
func _stop_tween() -> void:
	if movement_tween != null:
		movement_tween.kill()
		movement_tween = null

## Cek apakah sedang ada tween yang berjalan 
func _is_tweening() -> bool:
	return movement_tween != null and movement_tween.is_running()
