class_name FishSpecies extends Resource

## How sharply the size roll is skewed toward the low end — bigger means
## large fish become rarer, faster. Tune here to affect every species at once.
const SIZE_RARITY_POWER: float = 3.0

@export var id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var catch_weight: float = 1.0
@export var display_scale: float = 1.0
## Real-world average length for this species, in cm. Drives both the size
## range a catch can roll in (half to double this) and the sell-value formula.
@export var average_length_cm: float = 30.0
## Base sell value at exactly average_length_cm. Sell value scales linearly
## with this, so changing it proportionally rescales every catch's value.
@export var base_value: float = 10.0

func get_length_range() -> Vector2:
	return Vector2(average_length_cm * 0.5, average_length_cm * 2.0)

## Rolls a random length for a freshly-caught fish of this species. Larger
## sizes are rarer: the roll is skewed toward the bottom of the range.
func roll_length_cm() -> float:
	var range: Vector2 = get_length_range()
	var t: float = pow(randf(), SIZE_RARITY_POWER)
	return lerp(range.x, range.y, t)

## Sell value for a catch of the given length — proportional to how it
## compares to the species' average, scaled by base_value.
func get_sell_value(length_cm: float) -> int:
	if average_length_cm <= 0.0:
		return int(round(base_value))
	return int(round(base_value * (length_cm / average_length_cm)))
