class_name Doorway extends Area3D
## A trigger volume placed in a doorway. When the player walks into it, Main fades out,
## loads target_scene, and puts the player at the spawn marker named target_spawn.
##
## Setup: add a Doorway (give it a CollisionShape3D with a box that fills the doorway),
## set target_scene and target_spawn, and add a matching Marker3D (group "spawn_point")
## in the target scene. Do the same in the target scene to come back.
##
## Main finds every Doorway through the "doorway" group when a level loads, so nothing
## else needs wiring.

signal door_entered(target_scene: String, target_spawn: String)

## Scene to load: its name under res://floors/ without ".tscn", e.g. "convenience_store".
@export var target_scene: String = ""
## Name of a Marker3D (group "spawn_point") in the target scene where the player appears.
## Empty = wherever the player is placed in that scene.
@export var target_spawn: String = ""
## If set, the door does nothing until this WorldState flag is true (set by dialogue, e.g.
## after an NPC unlocks it for you).
@export var required_flag: String = ""
## Seconds after the level loads before this door works, so a player who arrives
## standing in a doorway isn't bounced straight back through it.
@export var arm_delay: float = 0.6

var _armed: bool = false
var _used: bool = false

func _ready() -> void:
	add_to_group("doorway")
	collision_layer = 0 # nothing needs to detect the door; it only looks for the player
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(arm_delay).timeout.connect(func(): _armed = true)

func _on_body_entered(body: Node3D) -> void:
	if not _armed or _used or not body.is_in_group("player"):
		return
	if not required_flag.is_empty() and not WorldState.get_flag(required_flag):
		return
	if target_scene.is_empty():
		push_warning("Doorway '%s' has no target_scene" % name)
		return
	_used = true
	door_entered.emit(target_scene, target_spawn)
