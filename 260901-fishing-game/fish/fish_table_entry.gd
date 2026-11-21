class_name FishTableEntry extends Resource
## One fish in a body of water's FishTable.

@export var species: FishSpecies
## Relative chance. Only the ratios between entries in the same table matter.
@export var weight: float = 1.0
## Rare fish: rod and bait luck (FishingComponent.luck) multiplies their weight.
@export var rare: bool = false
## If set, this fish can only be hooked once this WorldState flag is true (set by
## dialogue). Use it for the legendary fish so it can't be found before the clues.
@export var required_flag: String = ""
