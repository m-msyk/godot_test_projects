class_name MusicArea extends Area3D

@export var stream: AudioStream
@export var blend_distance: float = 2.0

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	print("MusicArea ready, stream: ", stream)
	add_to_group("music_area")
	monitoring = false
	monitorable = false
	if stream:
		audio_player.stream = stream
		audio_player.bus = "Music"
		audio_player.volume_db = -80.0
		audio_player.play()
		print("Audio playing: ", audio_player.playing)
	else:
		print("No stream assigned")

func update_volume(player_pos: Vector3) -> void:
	var shape: Shape3D = $CollisionShape3D.shape
	if shape is BoxShape3D:
		print("player_pos: ", player_pos)
		print("area_pos: ", global_position)
		print("box_size: ", (shape as BoxShape3D).size)
	var influence := _calculate_influence(player_pos)
	print("influence: ", influence)
	audio_player.volume_db = linear_to_db(influence) if influence > 0.0 else -80.0

func _calculate_influence(player_pos: Vector3) -> float:
	var collision_shape := $CollisionShape3D
	var shape: Shape3D = collision_shape.shape
	if shape == null:
		return 0.0
	if shape is SphereShape3D:
		return _sphere_influence(player_pos, shape as SphereShape3D, collision_shape)
	if shape is BoxShape3D:
		return _box_influence(player_pos, shape as BoxShape3D, collision_shape)
	return 0.0

func _sphere_influence(player_pos: Vector3, shape: SphereShape3D, collision_shape: CollisionShape3D) -> float:
	var distance := collision_shape.global_position.distance_to(player_pos)
	var inner_radius: float = shape.radius - blend_distance
	if distance > shape.radius:
		return 0.0
	if distance <= inner_radius:
		return 1.0
	return 1.0 - (distance - inner_radius) / blend_distance

func _box_influence(player_pos: Vector3, shape: BoxShape3D, collision_shape: CollisionShape3D) -> float:
	var local_pos := collision_shape.to_local(player_pos)
	var half: Vector3 = shape.size / 2.0
	if abs(local_pos.x) > half.x or abs(local_pos.z) > half.z:
		return 0.0
	if blend_distance <= 0.0:
		return 1.0
	var dx: float = max(0.0, abs(local_pos.x) - (half.x - blend_distance))
	var dz: float = max(0.0, abs(local_pos.z) - (half.z - blend_distance))
	var dist: float = sqrt(dx * dx + dz * dz)
	return 1.0 - clamp(dist / blend_distance, 0.0, 1.0)
