### quest_item.gd

@tool
extends Area2D

@onready var sprite_2d = $Sprite2D

@export var id := ""
@export var item_quantity := 1
@export var item_icon = Texture2D

func _ready():
	# Show texture in game
	if not Engine.is_editor_hint():
		sprite_2d.texture =  item_icon

func _process(_delta):
	# Show texture in engine
	if Engine.is_editor_hint():
		sprite_2d.texture = item_icon

func start_interact():
	print("I am an item!")
	
