class_name RhythmNote extends Node2D

@onready var color_rect: ColorRect = $ColorRect
@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var point_light: PointLight2D = $PointLight2D

var hit_time: float = 0.0
var lane: int = 0

func _ready() -> void:
	particles.emitting = false
	particles.modulate = modulate
	point_light.energy = 0.0
	point_light.color = Color(modulate.r, modulate.g, modulate.b)

func hit() -> void:
	color_rect.visible = false
	particles.modulate = modulate
	particles.emitting = true
	var tween := create_tween()
	tween.tween_property(point_light, "energy", 1.0, 0.02)
	tween.tween_property(point_light, "energy", 0.0, 0.15)
	await get_tree().create_timer(particles.lifetime).timeout
	queue_free()
