class_name NPC extends CharacterBody3D

@export var npc_name: String

@onready var dialogue_component: DialogueComponent = $DialogueComponent
@onready var quest_component: QuestComponent = $QuestComponent

func start_dialogue() -> void:
	DialogueManager.start(self)
