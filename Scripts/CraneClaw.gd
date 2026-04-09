extends Area2D

@export var drop_speed: float = 60.0
@export var max_drop: float = 65.0

@export var grab_offset: Vector2 = Vector2(0,35)
@export_range(0.0, 1.0, 0.01) var success_chance: float = 0.82
@export var open_anim_threshold: float = 40.0

enum ClawState { IDLE, DROPPING, RETURNING, FAILING }

var state: ClawState = ClawState.IDLE
var start_y: float
var grabbed_box: Area2D = null
var _box_origin: Vector2
var _open_anim_played: bool = false

@onready var wire: Sprite2D = $"../CraneWire"
@onready var anim: AnimatedSprite2D = $ClawSprite
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var train_anchor: Marker2D = get_parent().get_node("Marker2D")

const WIRE_BASE_HEIGHT: float = 8.0

signal box_dropped
signal grab_failed

func _ready():
	start_y = position.y

## Claw dianggap sibuk jika tidak dalam state IDLE
func is_busy() -> bool:
	return state != ClawState.IDLE

func _process(delta):
	match state:
		ClawState.DROPPING:
			position.y += drop_speed * delta
			_update_wire()
			if not _open_anim_played and position.y >= start_y + max_drop - open_anim_threshold:
				anim.play("ClawOpen")
				_open_anim_played = true
			if position.y >= start_y + max_drop:
				state = ClawState.IDLE
				_try_grab()

		ClawState.RETURNING, ClawState.FAILING:
			position.y -= drop_speed * delta
			_update_wire()
			if position.y <= start_y:
				position.y = start_y
				if state == ClawState.RETURNING:
					state = ClawState.IDLE
					if grabbed_box != null:
						get_parent().on_claw_grabbed()
					else:
						get_parent().on_claw_finished()
				# Jika FAILING, biarkan _handle_fail() yang menyelesaikan state

## Update wire berdasarkan posisi claw
func _update_wire():
	var anchor_global = train_anchor.global_position
	var claw_global = global_position
	var wire_length = abs(claw_global.y - anchor_global.y) + WIRE_BASE_HEIGHT
	wire.position = wire.get_parent().to_local((anchor_global + claw_global) / 2.0)
	wire.region_rect = Rect2(0, 0, wire.texture.get_width(), wire_length)

func drop():
	_open_anim_played = false
	state = ClawState.DROPPING

func _try_grab():
	var overlapping = get_overlapping_areas()
	if overlapping.size() > 0:
		grabbed_box = overlapping[0]
		_box_origin = grabbed_box.global_position

		anim.play("ClawGrab")
		grabbed_box.reparent(self, true)

		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(grabbed_box, "position", grab_offset, 0.15) 

		if grabbed_box.has_node("CollisionShape2D"):
			grabbed_box.get_node("CollisionShape2D").disabled = true
		await get_tree().create_timer(0.2).timeout

		if randf() <= success_chance:
			state = ClawState.RETURNING
		else:
			_handle_fail()

## Lepas box dari claw: reparent ke scene root, re-enable collision, play ClawOpen
## Mengembalikan referensi box yang dilepas, atau null jika tidak ada
func _detach_box() -> Area2D:
	if grabbed_box == null:
		return null

	var box = grabbed_box
	grabbed_box = null

	anim.play("ClawOpen")
	box.reparent(get_tree().current_scene)
	if box.has_node("CollisionShape2D"):
		box.get_node("CollisionShape2D").disabled = false

	return box

## Handle saat gagal grab box — box dikembalikan ke posisi semula
func _handle_fail():
	state = ClawState.FAILING

	await get_tree().create_timer(0.55).timeout

	var box = _detach_box()
	if not box:
		state = ClawState.IDLE
		return

	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(box, "global_position", _box_origin, 0.4)

	await tween.finished

	anim.play("ClawNeutral")
	state = ClawState.IDLE
	grab_failed.emit()

## Lepas box dari claw: tampilkan animasi ClawOpen, lalu tampilkan animasi ClawNeutral
func release_box():
	var box = _detach_box()
	if not box:
		return

	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(box, "position:y", box.position.y + 200.0, 0.5)

	await tween.finished

	anim.play("ClawNeutral")
	box_dropped.emit()
