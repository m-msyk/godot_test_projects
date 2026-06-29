extends Node

signal signatures_changed(count: int)
signal upgrades_changed()
signal points_changed(new_total: int)

const SIGNATURES_NEEDED: int = 5

var MODS: Array = []

var signatures: int = 0
var signature_givers: Array[String] = []
var time_played_seconds: float = 0.0
var rhythm_points: int = 0
var note_offset: float = 0.25
var upgrades: Dictionary = {}

func _ready() -> void:
	SaveManager.game_reset.connect(reset)
	_load_mods()

func _load_mods() -> void:
	var dir := DirAccess.open("res://mods/")
	if dir == null:
		print("mods directory not found")
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var mod := load("res://mods/" + file_name) as Mod
			if mod != null:
				print("loaded mod: ", file_name, " | mod_id: '", mod.mod_id, "'")
				MODS.append(mod)
				if not upgrades.has(mod.mod_id):
					upgrades[mod.mod_id] = 0
			else:
				print("failed to load as Mod: ", file_name)
		file_name = dir.get_next()

func _process(delta: float) -> void:
	time_played_seconds += delta

func get_max_health() -> int:
	var bonus: int = 0
	for mod in MODS:
		bonus += mod.get_max_health_bonus(upgrades.get(mod.mod_id, 0))
	return RhythmBattle.BASE_HEALTH + bonus

func get_base_damage() -> float:
	var bonus: float = 0.0
	for mod in MODS:
		bonus += mod.get_base_damage_bonus(upgrades.get(mod.mod_id, 0))
	return RhythmBattle.BASE_DAMAGE + bonus

func get_combo_growth_rate() -> float:
	var bonus: float = 0.0
	for mod in MODS:
		bonus += mod.get_combo_growth_bonus(upgrades.get(mod.mod_id, 0))
	return RhythmBattle.BASE_COMBO_GROWTH + bonus

func get_upgrade_cost(mod_id: String) -> int:
	for mod in MODS:
		if mod.mod_id == mod_id:
			return mod.get_cost(upgrades.get(mod_id, 0))
	return -1

func can_afford(mod_id: String) -> bool:
	return rhythm_points >= get_upgrade_cost(mod_id)

func purchase_upgrade(mod_id: String) -> bool:
	if not can_afford(mod_id):
		return false
	rhythm_points -= get_upgrade_cost(mod_id)
	upgrades[mod_id] = upgrades.get(mod_id, 0) + 1
	points_changed.emit(rhythm_points)
	upgrades_changed.emit()
	return true

func add_rhythm_points(amount: int) -> void:
	rhythm_points += amount
	points_changed.emit(rhythm_points)

func add_signature(giver_id: String) -> void:
	if signature_givers.has(giver_id):
		return
	signature_givers.append(giver_id)
	signatures += 1
	signatures_changed.emit(signatures)
	if signatures >= SIGNATURES_NEEDED:
		_trigger_win()

func has_received_signature_from(giver_id: String) -> bool:
	return signature_givers.has(giver_id)

func reset() -> void:
	signatures = 0
	signature_givers.clear()
	time_played_seconds = 0.0
	rhythm_points = 0
	note_offset = 0.25
	for key in upgrades:
		upgrades[key] = 0
	upgrades_changed.emit()
	points_changed.emit(rhythm_points)

func _trigger_win() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
