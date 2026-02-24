### player.gd

extends CharacterBody2D

# Scene tree node references
@onready var animated_sprite =  $Sprite2D
@onready var ray_cast_2d = $RayCast2D
@onready var move_state_machine: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var icon: TextureRect = $HUD/Coins/Icon
@onready var amount: Label = $HUD/Coins/Amount
@onready var quest_tracker: ColorRect = $HUD/QuestTracker
@onready var title: Label = $HUD/QuestTracker/Details/Title
@onready var objectives: VBoxContainer = $HUD/QuestTracker/Details/Objectives
@onready var quest_manager: Node2D = $QuestManager

# Variables
var direction: Vector2
@export var speed := 80
var can_move = true

func _ready():
	Global.player = self
	quest_tracker.visible = false

func _physics_process(delta: float) -> void:
	if can_move:
		get_input()
		velocity = direction * speed
		move_and_slide()
		animation()
	

# Input for movement
func get_input():
	direction = Input.get_vector("left", "right", "up", "down")
	
	# Turn raycast toward movement direction
	if velocity != Vector2.ZERO:
		ray_cast_2d.target_position = velocity.normalized() * 50

# Change animation based on input
func animation():
	if direction:
		move_state_machine.travel('walk')
		var target_vector: Vector2 = Vector2(round(direction.x), round(direction.y))
		$AnimationTree.set("parameters/MoveStateMachine/walk/blend_position", target_vector)
		$AnimationTree.set("parameters/MoveStateMachine/idle/blend_position", target_vector)
	else:
		move_state_machine.travel('idle')

func _input(event ) -> void:
	# Interact with NPC / quest item
	if can_move:
		if event.is_action_pressed("ui_interact"):
			var target = ray_cast_2d.get_collider()
			if target != null:
				if target.is_in_group("npc"):
					print("I'm talking to an NPC!")
					can_move = false
					target.start_dialogue()
				elif target.is_in_group("item"):
					print("I'm interacting with an item!")
					# Todo: check if item is needed for quest
					# Todo: remove item
					target.start_interact()
