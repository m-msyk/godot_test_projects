extends Node

signal signatures_changed(count: int)

const SIGNATURES_NEEDED: int = 5

var signatures: int = 0
var signature_givers: Array[String] = []

var time_played_seconds: float = 0.0

func _ready() -> void:
	SaveManager.game_reset.connect(reset)

func _process(delta: float) -> void:
	time_played_seconds += delta

func add_signature(giver_id: String) -> void:
	if signature_givers.has(giver_id):
		return
	signature_givers.append(giver_id)
	signatures += 1
	print("Signatures: ", signatures, "/", SIGNATURES_NEEDED)
	signatures_changed.emit(signatures)
	if signatures >= SIGNATURES_NEEDED:
		_trigger_win()

func has_received_signature_from(giver_id: String) -> bool:
	return signature_givers.has(giver_id)

func _trigger_win() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func reset() -> void:
	signatures = 0
	signature_givers.clear()
	time_played_seconds = 0.0
