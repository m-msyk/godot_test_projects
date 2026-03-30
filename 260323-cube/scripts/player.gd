class_name Player extends CharacterBody3D

@onready var input_component: InputComponent = %InputComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var interaction_component: InteractionComponent = %InteractionComponent
@onready var camera: Camera3D = %Camera3D

func _physics_process(delta: float) -> void:
	input_component.update()
	movement_component.direction = input_component.move_dir
	movement_component.wants_jump = input_component.jump_pressed
	movement_component.tick(delta, camera.orbit_angle)

func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	interaction_component.interacted_with_npc.connect(_on_interacted_with_npc)

func _on_interacted_with_npc(npc: NPC) -> void:
	DialogueManager.start(npc)
