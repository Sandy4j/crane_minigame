extends Area2D

@export var drop_speed: float = 60.0
@export var max_drop: float = 75.0

var start_y: float
var is_dropping: bool = false
var is_returning: bool = false
var grabbed_box: Area2D = null

@onready var wire: Sprite2D = $CraneWire
@onready var anim: AnimatedSprite2D = $ClawSprite
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var train_anchor: Marker2D = get_parent().get_node("Marker2D")

const WIRE_BASE_HEIGHT: float = 8.0

signal box_dropped(box: Area2D)

func _ready():
	start_y = position.y

func is_busy() -> bool:
	return is_dropping or is_returning

func _process(delta):
	if is_dropping:
		position.y += drop_speed * delta
		_update_wire()
		if position.y >= start_y + max_drop:
			is_dropping = false
			_try_grab()

	elif is_returning:
		position.y -= drop_speed * delta
		_update_wire()
		if position.y <= start_y:
			position.y = start_y
			is_returning = false
			get_parent().on_claw_finished()

func _update_wire():
	var anchor_local = to_local(train_anchor.global_position)
	var wire_length = abs(anchor_local.y) + WIRE_BASE_HEIGHT
	wire.position = Vector2(anchor_local.x, anchor_local.y / 2.0)
	wire.region_rect = Rect2(0, 0, wire.texture.get_width(), wire_length)

func drop():
	anim.play("ClawOpen")
	is_dropping = true

func _try_grab():
	var overlapping = get_overlapping_areas()
	if overlapping.size() > 0:
		grabbed_box = overlapping[0]
		anim.play("ClawGrab")
		grabbed_box.reparent(self)
		grabbed_box.position = Vector2(0, 10)
		if grabbed_box.has_node("CollisionShape2D"):
			grabbed_box.get_node("CollisionShape2D").disabled = true
		is_returning = true
	else:
		anim.play("ClawNeutral")
		await get_tree().create_timer(0.2).timeout
		is_returning = true

func release_box():
	if grabbed_box == null:
		return
		
	var box = grabbed_box
	var scene_root = get_tree().current_scene
	var world_pos = box.global_position
	grabbed_box = null

	anim.play("ClawOpen")
	box.reparent(scene_root)
	box.global_position = world_pos

	if box.has_node("CollisionShape2D"):
		box.get_node("CollisionShape2D").disabled = false
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(box, "position:y", box.position.y + 120.0, 0.4)

	await tween.finished
	anim.play("ClawNeutral")
	box_dropped.emit(box)
