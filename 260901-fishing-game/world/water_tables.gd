class_name WaterTables extends RefCounted
## Finds the FishTable for a body of water (a MeshInstance3D in the "water" group).
##
## Three ways to say which table a water uses, checked in this order:
##  1. Node metadata "fish_table" holding a FishTable resource (set in the editor:
##     Node tab > Metadata).
##  2. Node metadata "fish_table" holding a table's name, e.g. "town_lake" loads
##     res://fish/tables/town_lake.tres.
##  3. A Blender custom property "fish_table" on the water object (with Custom
##     Properties ticked at export). glTF import keeps it as the node's "extras".
## No table = the water falls back to every species by their own catch_weight.

const TABLE_FOLDER := "res://fish/tables/"

static func table_for(water: Node) -> FishTable:
	if water == null:
		return null
	var value = water.get_meta("fish_table", null)
	if value == null:
		var extras = water.get_meta("extras", null)
		if extras is Dictionary:
			value = extras.get("fish_table", null)
	if value is FishTable:
		return value
	if value is String and not (value as String).is_empty():
		var path := TABLE_FOLDER + (value as String) + ".tres"
		if ResourceLoader.exists(path):
			return load(path) as FishTable
		push_warning("Water '%s' names fish table '%s' but %s doesn't exist" % [water.name, value, path])
	return null
