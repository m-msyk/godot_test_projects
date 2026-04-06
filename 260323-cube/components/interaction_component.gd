class_name InteractionComponent extends Node

signal interacted_with_npc(npc: NPC)

@export var interaction_radius: float = 2.0
@export var interaction_angle: float = 60.0
@export var model: Node3D
@export var body: CharacterBody3D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()

func _try_interact() -> void:
	var facing = -model.global_basis.z
	facing.y = 0
	facing = facing.normalized()

	var interactables := get_tree().get_nodes_in_group("interactable")
	var best: Node = null
	var best_angle: float = interaction_angle

	for target in interactables:
		var to_target = target.global_position - body.global_position
		to_target.y = 0
		if to_target.length() > interaction_radius:
			continue
		var angle = rad_to_deg(facing.angle_to(to_target.normalized()))
		if angle < best_angle:
			best_angle = angle
			best = target

	if best == null:
		return

	if best is NPC:
		interacted_with_npc.emit(best)
	else:
		best.interact()
