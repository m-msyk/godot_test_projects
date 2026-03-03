### player.gd

extends CharacterBody2D

# Scene tree node references
@onready var animated_sprite =  $Sprite2D
@onready var ray_cast_2d = $RayCast2D
@onready var move_state_machine: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var icon: TextureRect = $HUD/Signatures/Icon
@onready var amount: Label = $HUD/Signatures/Amount
@onready var quest_tracker: ColorRect = $HUD/QuestTracker
@onready var title: Label = $HUD/QuestTracker/Details/Title
@onready var objectives: VBoxContainer = $HUD/QuestTracker/Details/Objectives
@onready var quest_manager: Node2D = $QuestManager

# Variables
var direction: Vector2
@export var speed := 80
var can_move = true

# Dialogue & Quest variables
var selected_quest: Quest = null
var signature_amount = 0

func _ready():
	Global.player = self
	quest_tracker.visible = false
	update_signatures()
	
	# Signal connections
	quest_manager.quest_updated.connect(_on_quest_updated)
	quest_manager.objective_updated.connect(_on_objective_updated)

# Input for movement
func get_input():
	direction = Input.get_vector("left", "right", "up", "down")
	
	# Turn raycast toward movement direction
	if velocity != Vector2.ZERO:
		ray_cast_2d.target_position = velocity.normalized() * 50

# Movement and animation
func _physics_process(_delta):
	if can_move:
		get_input()
		velocity = direction * speed
		move_and_slide()
		animation()

# Change animation based on input
func animation():
	if direction:
		move_state_machine.travel('walk')
		var target_vector: Vector2 = Vector2(round(direction.x), round(direction.y))
		$AnimationTree.set("parameters/MoveStateMachine/walk/blend_position", target_vector)
		$AnimationTree.set("parameters/MoveStateMachine/idle/blend_position", target_vector)
	else:
		move_state_machine.travel('idle')

func _input(event) -> void:
	# Interact with NPC / quest item
	if can_move:
		if event.is_action_pressed("ui_interact"):
			var target = ray_cast_2d.get_collider()
			if target != null:
				if target.is_in_group("npc"):
					can_move = false
					target.start_dialogue()
					check_quest_objectives(target.npc_id, "talk_to")
				elif target.is_in_group("item"):
					if is_item_needed(target.item_id):
						check_quest_objectives(target.item_id, "collection", target.item_quantity)
						target.queue_free()
					else:
						print("Item not needed for any active quest.")
						
		# Open/close quest log
		if event.is_action_pressed("ui_quest_menu"):
			quest_manager.show_quest_log()

# Check if quest item is needed
func is_item_needed(item_id: String) -> bool:
	if selected_quest != null:
		for objective in selected_quest.objectives:
			if objective.target_id == item_id and objective.target_type == "collection" and not objective.is_completed:
				return true
	return false

func check_quest_objectives(target_id: String, target_type: String, quantity: int = 1):
	if selected_quest == null:
		return
	
	# Update objectives
	var objective_updated = false
	for objective in selected_quest.objectives:
		if objective.target_id == target_id and objective.target_type == target_type and not objective.is_completed:
			print("Completing objective for quest: ", selected_quest.quest_name)
			selected_quest.complete_objective(objective.id, quantity)
			objective_updated = true
			break
	
	# Provide rewards
	if objective_updated:
		if selected_quest.is_completed():
			handle_quest_completion(selected_quest)
	
		# Update UI
		update_quest_tracker(selected_quest)

# Player rewards
func handle_quest_completion(quest: Quest):
	for reward in quest.rewards:
		if reward.reward_type == "signatures":
			signature_amount += reward.reward_amount
			update_signatures()
	update_quest_tracker(quest)
	quest_manager.update_quest(quest.quest_id, "completed")

# Update signature UI
func update_signatures():
	amount.text = str(signature_amount)
	
# Update tracker UI
func update_quest_tracker(quest: Quest):
	# If there's an active quest, populate tracker
	if quest:
		quest_tracker.visible = true
		title.text = quest.quest_name
		
		for child in objectives.get_children():
			objectives.remove_child(child)
		
		for objective in quest.objectives:
			var label = Label.new()
			var font = load("res://fonts/PixelOperator.ttf")
			label.add_theme_font_override("font", font)
			label.add_theme_font_size_override("font_size", 16)
			label.text = objective.description
			
			var completed_color = Color(0.62, 0.912, 0.643, 1.0)
			var incompleted_color = Color(0.848, 0.362, 0.249, 1.0)
			if objective.is_completed:
				label.add_theme_color_override("font_color", completed_color)
			else:
				label.add_theme_color_override("font_color", incompleted_color)
				
			objectives.add_child(label)
	
	# If no active quest, hide tracker
	else:
		quest_tracker.visible = false
	
# Update tracker if quest is complete
func _on_quest_updated(quest_id: String):
	var quest = quest_manager.get_quest(quest_id)
	if quest == selected_quest:
		update_quest_tracker(quest)
	selected_quest = null
	
# Update tracker if objective is complete
func _on_objective_updated(quest_id: String, objective_id: String):
	if selected_quest and selected_quest.quest_id == quest_id:
		update_quest_tracker(selected_quest)
	selected_quest = null
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
