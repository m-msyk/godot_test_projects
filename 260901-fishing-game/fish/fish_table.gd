class_name FishTable extends Resource
## Which fish live in one body of water, and how likely each is to bite.
##
## Make one per body of water under res://fish/tables/ and point the water at it
## (see WaterTables). The same fish can appear in several tables with different
## weights, so a common fish in one lake can be rare in another.

@export var table_name: String
@export var entries: Array[FishTableEntry] = []

## Picks a fish at random by weight. `luck` (0 = none) multiplies the weight of the
## entries marked rare by (1 + luck), so better rods and bait find rare fish more
## often without making common ones impossible. Entries whose required_flag isn't set
## yet are skipped. Returns null if nothing can be caught.
func pick(luck: float = 0.0) -> FishSpecies:
	var candidates: Array[FishTableEntry] = []
	var weights: Array[float] = []
	var total := 0.0
	for entry in entries:
		if entry == null or entry.species == null or entry.weight <= 0.0:
			continue
		if not entry.required_flag.is_empty() and not WorldState.get_flag(entry.required_flag):
			continue
		var w := entry.weight * ((1.0 + maxf(luck, 0.0)) if entry.rare else 1.0)
		candidates.append(entry)
		weights.append(w)
		total += w
	if candidates.is_empty() or total <= 0.0:
		return null
	var roll := randf() * total
	var cumulative := 0.0
	for i in candidates.size():
		cumulative += weights[i]
		if roll < cumulative:
			return candidates[i].species
	return candidates[candidates.size() - 1].species

## Every species this table can ever produce, ignoring flags (for checking that
## every fish can be caught somewhere).
func get_species() -> Array[FishSpecies]:
	var result: Array[FishSpecies] = []
	for entry in entries:
		if entry != null and entry.species != null and not result.has(entry.species):
			result.append(entry.species)
	return result
