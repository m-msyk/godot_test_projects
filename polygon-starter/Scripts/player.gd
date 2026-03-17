class_name Player extends CharacterBody3D

@onready var input_component: InputComponent = %InputComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var health_component: HealthComponent = %HealthComponent

func _ready() -> void:
	health_component.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	# Reads input component
	input_component.update()
	
	# Reads movement component
	movement_component.direction = input_component.move_dir
	movement_component.wants_jump = input_component.jump_pressed
	movement_component.tick(delta)
	
	# Reads health component
	if input_component.hurt_pressed:
		health_component.damage(10)
	
	if input_component.heal_pressed:
		health_component.heal(10)

func _on_died() -> void:
	print("Player died")
	queue_free()
