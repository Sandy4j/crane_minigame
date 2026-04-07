extends Node2D

@export var session_cost: int = 1000
@export var aurum: int = 2000

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
@onready var empty_label = $Main/EmptyLabel
@onready var popup = $CraneMachinePopup
@onready var ui = $UI
@onready var result = $CraneResult


func _ready():
	claw.grab_failed.connect(end_session)
	claw.box_dropped.connect(end_session)

	empty_label.visible = false
	train.can_move = false

	aurum_changed.emit(aurum)
	popup.open(session_cost, aurum, is_empty)


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

	await get_tree().process_frame
	_check_boxes()

	if is_empty:
		popup.open(session_cost, aurum, is_empty)
	elif aurum < session_cost:
		session_failed_no_aurum.emit()
		popup.open(session_cost, aurum, is_empty)
	else:
		pending_session = true
		train.can_move = true
		popup.close()

## Aktivasi sesi jika ada sesi yang pending
func start_pending_session() -> void:
	if not pending_session:
		return

	if aurum < session_cost:
		session_failed_no_aurum.emit()
		popup.show_warning()
		popup.open(session_cost, aurum, is_empty)
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
		var item_texture: Texture2D = null
		var item_name: String = area.name
		var sprite = area.get_node_or_null("Sprite2D")
		if sprite:
			item_texture = sprite.texture

		area.queue_free()
		result.show_result(item_name, item_texture)
