class_name ShopUI extends Control

@onready var points_label: Label = $Panel/VBoxContainer/TopRow/PointsLabel
@onready var mod_list: GridContainer = $Panel/VBoxContainer/ModList
@onready var close_button: Button = $Panel/VBoxContainer/TopRow/CloseButton
@onready var tooltip_panel: TooltipPanel = $TooltipPanel
@onready var tooltip_label: Label = $TooltipPanel/TooltipLabel

var _mod_labels: Array = []  # Array of {name, level, cost, mod} dicts per row

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	close_button.pressed.connect(close)
	tooltip_panel.visible = false
	PlayerData.points_changed.connect(_on_points_changed)

func open() -> void:
	_populate_mods()
	show()
	StateManager.set_state(StateManager.State.PARTIAL)

func close() -> void:
	hide()
	StateManager.set_state(StateManager.State.FREE)

func _populate_mods() -> void:
	for child in mod_list.get_children():
		child.queue_free()
	_mod_labels.clear()
	points_label.text = "Points: %d" % PlayerData.rhythm_points
	for mod in PlayerData.MODS:
		var level: int = PlayerData.upgrades.get(mod.mod_id, 0)
		var cost: int = PlayerData.get_upgrade_cost(mod.mod_id)
		var affordable: bool = PlayerData.can_afford(mod.mod_id)
		var dim := Color(0.5, 0.5, 0.5, 1)
		var bright := Color(1, 1, 1, 1)

		var name_label := Label.new()
		name_label.text = mod.display_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.modulate = bright if affordable else dim
		mod_list.add_child(name_label)

		var level_label := Label.new()
		level_label.text = "Lv. %d" % level
		level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		level_label.modulate = bright if affordable else dim
		mod_list.add_child(level_label)

		var cost_label := Label.new()
		cost_label.text = "%d pts" % cost
		cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cost_label.modulate = bright if affordable else dim
		mod_list.add_child(cost_label)

		_mod_labels.append({
			"name": name_label,
			"level": level_label,
			"cost": cost_label,
			"mod": mod
		})

func _refresh_rows() -> void:
	for entry in _mod_labels:
		var mod: Mod = entry["mod"]
		var level: int = PlayerData.upgrades.get(mod.mod_id, 0)
		var cost: int = PlayerData.get_upgrade_cost(mod.mod_id)
		var affordable: bool = PlayerData.can_afford(mod.mod_id)
		var dim := Color(0.5, 0.5, 0.5, 1)
		var bright := Color(1, 1, 1, 1)
		entry["level"].text = "Lv. %d" % level
		entry["cost"].text = "%d pts" % cost
		entry["name"].modulate = bright if affordable else dim
		entry["level"].modulate = bright if affordable else dim
		entry["cost"].modulate = bright if affordable else dim

func _find_hovered_mod(mouse_pos: Vector2) -> Mod:
	for entry in _mod_labels:
		var name_label: Label = entry["name"]
		var cost_label: Label = entry["cost"]
		var row_rect := Rect2(
			name_label.global_position,
			Vector2(cost_label.global_position.x + cost_label.size.x - name_label.global_position.x,
				name_label.size.y)
		)
		if row_rect.has_point(mouse_pos):
			return entry["mod"]
	return null

func _on_points_changed(new_total: int) -> void:
	points_label.text = "Points: %d" % new_total

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseMotion:
		tooltip_panel.position = get_local_mouse_position() + Vector2(10, 10)
		var hovered_mod := _find_hovered_mod(event.global_position)
		if hovered_mod:
			tooltip_panel.show_tooltip(hovered_mod.description, get_local_mouse_position() + Vector2(10, 10))
		else:
			tooltip_panel.hide_tooltip()
		# highlight hovered row
		for entry in _mod_labels:
			var is_hovered = _find_hovered_mod(event.global_position) == entry["mod"]
			var color := Color.YELLOW if is_hovered else Color.WHITE
			entry["name"].add_theme_color_override("font_color", color)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hovered_mod := _find_hovered_mod(event.global_position)
		if hovered_mod and PlayerData.can_afford(hovered_mod.mod_id):
			PlayerData.purchase_upgrade(hovered_mod.mod_id)
			_refresh_rows()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
