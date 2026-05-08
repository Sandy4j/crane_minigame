extends Node2D
class_name CraneMachine

@export var session_cost: int = 1000
@export var aurum: int = 5000
@export_range(0.0, 1.0, 0.01) var success_chance: float = 0.82

var session_active: bool = false
var is_empty: bool = false
var has_played_once: bool = false
var pending_session: bool = false

signal session_started
signal session_failed_no_aurum
signal session_ended
signal aurum_changed(new_amount)
signal machine_empty

@onready var train = $CraneTrain
@onready var claw = $CraneTrain/CraneClaw
@onready var vfx_manager = $Inner/VFXSucces
@onready var boxes = $Boxes
@onready var montage = $Montage/montage_blindboxopen

@onready var empty_label = $Inner/EmptyLabel
@onready var ui = $UI
@onready var popup = $PopupUI/PopupRoot
@onready var result = $PopupUI/ResultRoot
@onready var empty = $PopupUI/EmptyRoot

func _ready():
	claw.grab_failed.connect(_on_grab_failed)
	claw.box_dropped.connect(_on_box_dropped)
	result.result_closed.connect(_on_result_closed)
	
	montage.visible = false
	boxes.randomize_boxes()
	empty_label.visible = false
	train.can_move = false

	_load_config()
	aurum_changed.emit(aurum)

func trigger_initial_popup() -> void:
	if not session_active:
		popup.open(self)

func check_success() -> bool:
	return randf() <= success_chance

## Load konfigurasi dari file eksternal
func _load_config() -> void:
	var path := OS.get_executable_path().get_base_dir().path_join("config.json")
	if not FileAccess.file_exists(path):
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Dictionary:
		return

	if data.has("aurum"):
		aurum = int(data["aurum"])
		print("aurum")
	if data.has("cost"):
		session_cost = int(data["cost"])
		print("cost")
	if data.has("success_chance"):
		success_chance = float(data["success_chance"])
		print("chance")
	print("config done")
	
## Aktivasi sesi: potong aurum, set state aktif, emit signal
func _activate_session() -> void:
	aurum -= session_cost
	aurum_changed.emit(aurum)
	session_active = true
	has_played_once = true
	session_started.emit()

func try_start_session() -> void:
	if is_empty:
		return
	if aurum < session_cost:
		session_failed_no_aurum.emit()
		popup.show_warning()
		return

	_activate_session()
	train.can_move = true
	popup.close()

func end_session() -> void:
	session_active = false
	train.can_move = false
	session_ended.emit()
	
	if vfx_manager.is_playing:
		await vfx_manager.vfx_finished

	await get_tree().process_frame
	_check_boxes()

	if is_empty:
		empty.open()
	elif aurum < session_cost:
		session_failed_no_aurum.emit()
		popup.open(self)
	else:
		pending_session = false
		popup.open(self)

## Aktivasi sesi jika ada sesi yang pending
func start_pending_session() -> void:
	if not pending_session:
		return

	if aurum < session_cost:
		session_failed_no_aurum.emit()
		popup.show_warning()
		popup.open(self)
		pending_session = false
		train.can_move = false
		return

	pending_session = false
	_activate_session()

## Cek apakah ada box yang kosong
func _check_boxes() -> void:
	var boxes = get_tree().get_nodes_in_group("box")
	if boxes.size() == 0:
		is_empty = true
		empty_label.visible = true
		machine_empty.emit()

## Signal dari area drop zone
func _on_drop_zone_area_shape_entered(_area_rid, area, _area_shape_index, _local_shape_index):
	if area.is_in_group("box"):
		var box_texture = null
		if area.has_node("Sprite2D"):
			box_texture = area.get_node("Sprite2D").texture
			
		area.queue_free()
		vfx_manager.play_success_vfx()
		await vfx_manager.vfx_finished
		await montage.play_montage(box_texture)
		result.show_result()

func _on_result_closed() -> void:
	vfx_manager.stop_success_vfx()
	if session_active:
		end_session()

func _on_box_dropped() -> void:
	pass

func _on_grab_failed() -> void:
	vfx_manager.play_failure_vfx()
	end_session()
