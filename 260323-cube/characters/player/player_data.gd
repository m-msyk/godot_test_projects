extends Node

signal signatures_changed(count: int)

const SIGNATURES_NEEDED: int = 5

var signatures: int = 0
var signature_givers: Array[String] = []

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
