extends Node2D

## VFXManager - Mengelola efek visual untuk success dan failure

signal vfx_finished

@onready var success_overlay: Sprite2D = $Overlay
@onready var success_particles: GPUParticles2D = $GPUParticles2D
@onready var failure_overlay: AnimatedSprite2D = $VFXFailure/Overlay

var is_playing: bool = false

func _ready():
	_hide_all_vfx()

func play_success_vfx() -> void:
	if is_playing:
		return

	is_playing = true
	success_overlay.visible = true
	success_overlay.modulate.a = 0.0
	success_particles.emitting = true
	
	var tween = create_tween()
	tween.tween_property(success_overlay, "modulate:a", 1.0, 0.4)
	
	await tween.finished
	vfx_finished.emit()

func play_failure_vfx() -> void:
	if is_playing:
		return

	is_playing = true
	
	failure_overlay.visible = true
	failure_overlay.modulate.a = 0.0
	failure_overlay.frame = 0
	failure_overlay.play("default")

	var tween = create_tween()
	tween.tween_property(failure_overlay, "modulate:a", 1.0, 0.4)
	await tween.finished

	await get_tree().create_timer(1.2).timeout
	
	var tween_out = create_tween()
	tween_out.tween_property(failure_overlay, "modulate:a", 0.0, 0.4)
	await tween_out.finished
	
	failure_overlay.visible = false
	is_playing = false
	vfx_finished.emit()

func stop_success_vfx() -> void:
	if success_overlay.visible:
		var tween = create_tween()
		tween.tween_property(success_overlay, "modulate:a", 0.0, 0.4)
		await tween.finished
		_hide_all_vfx()
		is_playing = false
		vfx_finished.emit()

func _hide_all_vfx() -> void:
	success_overlay.visible = false
	success_particles.emitting = false
	failure_overlay.visible = false
