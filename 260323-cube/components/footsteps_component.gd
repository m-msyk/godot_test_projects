class_name FootstepsComponent extends Node

@export var footstep_sound: AudioStream
@export var footstep_bus: String = "SFX"
@export var min_pitch: float = 0.8
@export var max_pitch: float = 1.2
@export var base_step_interval: float = 0.5  # seconds between steps at base speed

var _step_timer: float = 0.0
var _is_moving: bool = false

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	audio_player.bus = footstep_bus
	audio_player.stream = footstep_sound

func tick(delta: float, velocity: Vector3, base_speed: float) -> void:
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	_is_moving = horizontal_speed > 0.1

	if not _is_moving:
		_step_timer = 0.0
		return

	# Scale step interval inversely with speed
	var speed_ratio = horizontal_speed / base_speed
	var step_interval = base_step_interval / speed_ratio

	_step_timer += delta
	if _step_timer >= step_interval:
		_step_timer = 0.0
		_play_footstep()

func _play_footstep() -> void:
	audio_player.pitch_scale = randf_range(min_pitch, max_pitch)
	audio_player.play()
