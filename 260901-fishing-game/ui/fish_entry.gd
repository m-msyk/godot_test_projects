class_name FishEntry extends Control

const SILHOUETTE_SHADER = preload("res://ui/fish_silhouette.gdshader")

@onready var icon_rect: TextureRect = $Icon
@onready var highlight_border: Panel = $HighlightBorder

var _description: String
var _material: ShaderMaterial

func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = SILHOUETTE_SHADER
	icon_rect.material = _material

func setup(species: FishSpecies, caught: bool) -> void:
	icon_rect.texture = species.icon
	_material.set_shader_parameter("silhouette", not caught)
	_apply_relative_size(species)
	if caught:
		var largest := PlayerData.get_largest_catch(species.id)
		_description = "%s\n%s\nLargest caught: %.1f cm" % [species.display_name, species.description, largest]
	else:
		_description = "??? (undiscovered)\nCatch this fish to reveal its description."

## Sizes the icon relative to the largest species' display_scale, so the
## biggest fish fills the cell and smaller ones shrink proportionally
## instead of all being stretched up to the same size.
func _apply_relative_size(species: FishSpecies) -> void:
	var max_scale := 0.0
	for s in PlayerData.ALL_FISH:
		max_scale = max(max_scale, s.display_scale)
	if max_scale <= 0.0:
		max_scale = 1.0
	var relative: float = species.display_scale / max_scale
	var full_size: float = custom_minimum_size.x
	var target: float = full_size * relative
	var half: float = target * 0.5
	icon_rect.offset_left = -half
	icon_rect.offset_top = -half
	icon_rect.offset_right = half
	icon_rect.offset_bottom = half

func get_description() -> String:
	return _description

func set_highlighted(highlighted: bool) -> void:
	highlight_border.visible = highlighted
