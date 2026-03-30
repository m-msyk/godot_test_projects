class_name InteractionComponent extends Node

signal interacted_with_npc(npc: NPC)

@export var interaction_radius: float = 2.0
@export var interaction_angle: float = 60.0  # degrees either side of facing
@export var model: Node3D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()

func _try_interact() -> void:
	var player = get_parent()
	var facing = -model.global_basis.z
	facing.y = 0
	facing = facing.normalized()

	var npcs := get_tree().get_nodes_in_group("npc")

	var best_npc: NPC = null
	var best_angle: float = interaction_angle

	for npc in npcs:
		var to_npc = npc.global_position - player.global_position
		to_npc.y = 0
		var distance = to_npc.length()

		if distance > interaction_radius:
			continue

		var angle = rad_to_deg(facing.angle_to(to_npc.normalized()))

		if angle < best_angle:
			best_angle = angle
			best_npc = npc

	if best_npc != null:
		interacted_with_npc.emit(best_npc)
