class_name NPC extends CharacterBody3D

@export var npc_name: String
@export var timeline: DialogicTimeline
@export var quests: Array[Quest] = []

@export var shading_steps: float = 2.0
@export var shadow_softness: float = 0.05
@export var ambient_light: float = 0.25
@export var rim_strength: float = 0.0
@export var rim_sharpness: float = 3.0

func _ready() -> void:
	_apply_shader_params()
	add_to_group("interactable")
	_connect_signals()

func _apply_shader_params() -> void:
	for mesh in find_children("*", "MeshInstance3D"):
		for i in mesh.get_surface_override_material_count():
			var mat = mesh.get_surface_override_material(i)
			if mat is ShaderMaterial:
				mat.set_shader_parameter("shading_steps", shading_steps)
				mat.set_shader_parameter("shadow_softness", shadow_softness)
				mat.set_shader_parameter("ambient_light", ambient_light)
				mat.set_shader_parameter("rim_strength", rim_strength)
				mat.set_shader_parameter("rim_sharpness", rim_sharpness)

func start_dialogue() -> void:
	Dialogic.start(timeline)

func _connect_signals() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)

func _on_dialogic_signal(argument: String) -> void:
	var parts = argument.split(":")
	if parts.size() < 1:
		return
	var signal_type = parts[0]
	var signal_value = parts[1] if parts.size() >= 2 else ""
	match signal_type:
		"quest_started":
			_start_quest(signal_value)
		"objective_completed":
			if parts.size() >= 3:
				QuestManager.complete_objective(signal_value, parts[2])
		"floor_unlocked":
			FloorManager.unlock_floor(signal_value)
		"signature_received":
			PlayerData.add_signature(signal_value)

func _start_quest(quest_id: String) -> void:
	for quest in quests:
		if quest.quest_id == quest_id:
			QuestManager.add_quest(quest)
			return
