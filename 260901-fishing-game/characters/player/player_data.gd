extends Node

signal fish_caught_changed()

const WIN_PERCENTAGE: float = 0.5

var ALL_FISH: Array[FishSpecies] = []

var caught_fish: Array[String] = []
var inventory: Dictionary = {}  # species_id -> count held
var largest_catch_cm: Dictionary = {}  # species_id -> largest length ever caught
var time_played_seconds: float = 0.0
var note_offset: float = 0.25
var game_completed: bool = false

func _ready() -> void:
	SaveManager.game_reset.connect(reset)
	_load_fish_species()

func _load_fish_species() -> void:
	var dir := DirAccess.open("res://fish/")
	if dir == null:
		print("fish directory not found")
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var species := load("res://fish/" + file_name) as FishSpecies
			if species != null:
				ALL_FISH.append(species)
			else:
				print("failed to load as FishSpecies: ", file_name)
		file_name = dir.get_next()

func _process(delta: float) -> void:
	time_played_seconds += delta

func has_caught(species_id: String) -> bool:
	return caught_fish.has(species_id)

func get_species(species_id: String) -> FishSpecies:
	for species in ALL_FISH:
		if species.id == species_id:
			return species
	return null

func get_inventory_count(species_id: String) -> int:
	return inventory.get(species_id, 0)

func get_largest_catch(species_id: String) -> float:
	return largest_catch_cm.get(species_id, 0.0)

func catch_fish(species_id: String, length_cm: float = 0.0) -> void:
	var first_catch := not caught_fish.has(species_id)
	if first_catch:
		caught_fish.append(species_id)
	inventory[species_id] = get_inventory_count(species_id) + 1
	if length_cm > get_largest_catch(species_id):
		largest_catch_cm[species_id] = length_cm
	fish_caught_changed.emit()
	if first_catch:
		var progress := get_encyclopedia_progress()
		if progress["percentage"] >= WIN_PERCENTAGE:
			_trigger_win()

func pick_random_fish(pool: Array[FishSpecies] = ALL_FISH) -> FishSpecies:
	if pool.is_empty():
		return null
	var total_weight := 0.0
	for species in pool:
		total_weight += max(species.catch_weight, 0.0)
	if total_weight <= 0.0:
		return pool[randi() % pool.size()]
	var roll := randf() * total_weight
	var cumulative := 0.0
	for species in pool:
		cumulative += max(species.catch_weight, 0.0)
		if roll < cumulative:
			return species
	return pool[pool.size() - 1]

func get_encyclopedia_progress() -> Dictionary:
	var total: int = ALL_FISH.size()
	var caught: int = caught_fish.size()
	var percentage: float = float(caught) / float(total) if total > 0 else 0.0
	return {"caught": caught, "total": total, "percentage": percentage}

func reset() -> void:
	caught_fish.clear()
	inventory.clear()
	largest_catch_cm.clear()
	time_played_seconds = 0.0
	note_offset = 0.25
	game_completed = false
	fish_caught_changed.emit()

func _trigger_win() -> void:
	game_completed = true
