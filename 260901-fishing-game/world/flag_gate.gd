class_name FlagGate extends StaticBody3D
## A gate that blocks the way until a WorldState flag is set, then opens for good.
##
## An NPC sets the flag from dialogue ([signal arg="set_flag:apartment_gate_open"]), for
## example after you hand over the fish they asked for. Give the gate a CollisionShape3D
## and a mesh as children. When the flag is set the collision switches off and the gate
## slides away (default: sinks into the ground). Flags are saved with the game, so a gate
## that was opened is already open when the game loads.

## The WorldState flag that opens this gate.
@export var open_flag: String = ""
## How far the gate moves when it opens (relative to where it is).
@export var open_offset: Vector3 = Vector3(0.0, -4.0, 0.0)
@export var open_time: float = 1.2
## Hide the gate once it has finished moving.
@export var hide_when_open: bool = true

var _opened: bool = false

func _ready() -> void:
	add_to_group("flag_gate")
	if open_flag.is_empty():
		push_warning("FlagGate '%s' has no open_flag" % name)
		return
	if WorldState.get_flag(open_flag):
		_open(true)
	else:
		WorldState.flag_changed.connect(_on_flag_changed)

func _on_flag_changed(flag_id: String, value: bool) -> void:
	if flag_id == open_flag and value:
		_open(false)

func _open(instant: bool) -> void:
	if _opened:
		return
	_opened = true
	# nothing blocks the way any more, immediately
	for child in find_children("*", "CollisionShape3D", true, false):
		(child as CollisionShape3D).set_deferred("disabled", true)
	var target := position + open_offset
	if instant:
		position = target
		visible = not hide_when_open
		return
	var tween := create_tween()
	tween.tween_property(self, "position", target, open_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if hide_when_open:
		tween.tween_callback(func(): visible = false)
