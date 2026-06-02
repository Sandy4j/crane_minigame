extends Camera2D
class_name CameraShake

@export var intensity: float = 3.0
@export var duration: float = 0.2
@export var steps: int = 5

var _rest_offset: Vector2 = Vector2.ZERO
var _shake_tween: Tween
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rest_offset = offset

func shake() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()

	var step_duration := duration / float(steps)
	_shake_tween = create_tween()

	for i in steps:
		var falloff := 1.0 - float(i) / float(steps)
		var amount := intensity * falloff
		var target := Vector2(
			_rng.randf_range(-amount, amount),
			_rng.randf_range(-amount, amount)
		)
		_shake_tween.tween_property(self, "offset", target, step_duration)

	_shake_tween.tween_property(self, "offset", _rest_offset, step_duration * 0.6)
