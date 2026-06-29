class_name BuildTab extends VBoxContainer

@onready var points_label: Label = $PointsLabel
@onready var upgrade_list: GridContainer = $ScrollContainer/UpgradeList

func _ready() -> void:
	PlayerData.upgrades_changed.connect(_refresh)
	PlayerData.points_changed.connect(_on_points_changed)
	_refresh()

func _refresh() -> void:
	points_label.text = "Points: %d" % PlayerData.rhythm_points
	for child in upgrade_list.get_children():
		child.queue_free()
	$ScrollContainer.scroll_vertical = 0
	for mod in PlayerData.MODS:
		var level: int = PlayerData.upgrades.get(mod.mod_id, 0)
		if level == 0:
			continue
		var name_label := Label.new()
		name_label.text = mod.display_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		upgrade_list.add_child(name_label)

		var stat_label := Label.new()
		stat_label.text = mod.get_stat_display(level)
		stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		upgrade_list.add_child(stat_label)

		var level_label := Label.new()
		level_label.text = "Lv. %d" % level
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		upgrade_list.add_child(level_label)

func _on_points_changed(new_total: int) -> void:
	points_label.text = "Points: %d" % new_total

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		$ScrollContainer.scroll_vertical = 0
