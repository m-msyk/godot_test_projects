class_name MenuUI extends Control

const FISH_ENTRY = preload("res://ui/fish_entry.tscn")
const INVENTORY_ENTRY = preload("res://ui/inventory_entry.tscn")

@onready var tab_container: TabContainer = $Panel/TabContainer
@onready var fish_list: GridContainer = $Panel/TabContainer/Encyclopedia/ScrollContainer/FishList
@onready var progress_label: Label = $Panel/TabContainer/Encyclopedia/MarginContainer/ProgressLabel
@onready var inventory_list: VBoxContainer = $Panel/TabContainer/Items/ScrollContainer/InventoryList
@onready var settings_list: VBoxContainer = $Panel/TabContainer/Settings
@onready var tooltip_panel: TooltipPanel = $TooltipPanel
@onready var tooltip_label: Label = $TooltipPanel/TooltipLabel

const SETTINGS_TAB: int = 2

var _tab_focus_mode: bool = false  # false = LEFT/RIGHT switch tabs, true = fully inside the tab's content
var _focused_index: int = -1

func _ready() -> void:
	tooltip_panel.visible = false
	_connect_signals()
	_populate_fish()
	_populate_inventory()

func _connect_signals() -> void:
	PlayerData.fish_caught_changed.connect(_populate_fish)
	PlayerData.fish_caught_changed.connect(_populate_inventory)
	tab_container.tab_changed.connect(_on_tab_changed)

func _populate_fish() -> void:
	var progress := PlayerData.get_encyclopedia_progress()
	progress_label.text = "Caught: %d / %d (%d%%)" % [progress["caught"], progress["total"], int(progress["percentage"] * 100)]
	for child in fish_list.get_children():
		child.queue_free()
	fish_list.get_parent().scroll_vertical = 0
	for species in PlayerData.ALL_FISH:
		var entry := FISH_ENTRY.instantiate()
		fish_list.add_child(entry)
		entry.setup(species, PlayerData.has_caught(species.id))

func _populate_inventory() -> void:
	for child in inventory_list.get_children():
		child.queue_free()
	for species in PlayerData.ALL_FISH:
		var count := PlayerData.get_inventory_count(species.id)
		if count <= 0:
			continue
		var entry := INVENTORY_ENTRY.instantiate()
		inventory_list.add_child(entry)
		entry.setup(species, count)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_LEFT, KEY_A:
			if _tab_focus_mode:
				_handle_horizontal(-1)
			else:
				tab_container.current_tab = max(0, tab_container.current_tab - 1)
		KEY_RIGHT, KEY_D:
			if _tab_focus_mode:
				_handle_horizontal(1)
			else:
				tab_container.current_tab = min(tab_container.get_tab_count() - 1, tab_container.current_tab + 1)
		KEY_DOWN, KEY_S:
			if _tab_focus_mode:
				_move_focus(1, 0)
			else:
				_enter_content_mode()
		KEY_UP, KEY_W:
			if _tab_focus_mode:
				_move_focus(-1, 0)
		KEY_ENTER, KEY_KP_ENTER:
			if _tab_focus_mode:
				_activate_focused()

## On the Settings tab LEFT/RIGHT adjust the focused row's value (it's a
## single column); everywhere else they move focus between grid columns.
func _handle_horizontal(direction: int) -> void:
	if tab_container.current_tab == SETTINGS_TAB:
		_adjust_focused(direction)
	else:
		_move_focus(0, direction)

func _adjust_focused(direction: int) -> void:
	var entries := _current_content_list()
	if _focused_index < 0 or _focused_index >= entries.size():
		return
	var entry = entries[_focused_index]
	if entry.has_method("adjust"):
		entry.adjust(direction)

func _activate_focused() -> void:
	var entries := _current_content_list()
	if _focused_index < 0 or _focused_index >= entries.size():
		return
	var entry = entries[_focused_index]
	if entry.has_method("activate"):
		entry.activate()

## Returns the currently visible tab's navigable entries (fish grid cells
## for Encyclopedia, inventory rows for Items, option rows for Settings).
func _current_content_list() -> Array:
	match tab_container.current_tab:
		0:
			return fish_list.get_children()
		1:
			return inventory_list.get_children()
		SETTINGS_TAB:
			return settings_list.get_children().filter(func(c): return c.has_method("set_highlighted"))
		_:
			return []

func _current_columns() -> int:
	return fish_list.columns if tab_container.current_tab == 0 else 1

func _enter_content_mode() -> void:
	var entries := _current_content_list()
	if entries.is_empty():
		return
	_tab_focus_mode = true
	_focused_index = 0
	_update_highlight()

func _exit_content_mode() -> void:
	_tab_focus_mode = false
	_focused_index = -1
	_clear_highlights()
	tooltip_panel.visible = false

## Moves focus by (d_row, d_col) within the current tab's grid/list,
## clamping at the edges — except moving up past the top row exits back
## to tab-switching mode.
func _move_focus(d_row: int, d_col: int) -> void:
	var entries := _current_content_list()
	if entries.is_empty():
		return
	var columns := _current_columns()
	var row := _focused_index / columns
	var col := _focused_index % columns
	var new_row := row + d_row
	if new_row < 0:
		_exit_content_mode()
		return
	var row_count := ceili(float(entries.size()) / columns)
	new_row = min(new_row, row_count - 1)
	var row_start := new_row * columns
	var row_len: int = min(columns, entries.size() - row_start)
	var new_col: int = clamp(col + d_col, 0, max(row_len - 1, 0))
	_focused_index = clampi(new_row * columns + new_col, 0, entries.size() - 1)
	_update_highlight()

func _update_highlight() -> void:
	var entries := _current_content_list()
	for i in entries.size():
		if entries[i].has_method("set_highlighted"):
			entries[i].set_highlighted(i == _focused_index)
	if _focused_index >= 0 and _focused_index < entries.size() and entries[_focused_index].has_method("get_description"):
		var entry: Control = entries[_focused_index]
		tooltip_label.text = entry.get_description()
		tooltip_panel.reset_size()
		_position_tooltip_near(entry)
		tooltip_panel.visible = true
	else:
		tooltip_panel.visible = false

## Floats the tooltip directly below the given entry (flipping above it if
## that would run off the bottom), always kept at least EDGE_MARGIN inside
## every screen edge so it can never hang off or crowd the border.
func _position_tooltip_near(entry: Control) -> void:
	const PADDING: float = 6.0
	const EDGE_MARGIN: float = 10.0
	var entry_rect := entry.get_global_rect()
	var tooltip_size := tooltip_panel.size
	var viewport_size := get_viewport_rect().size

	var global_pos := Vector2(entry_rect.position.x, entry_rect.position.y + entry_rect.size.y + PADDING)
	if global_pos.y + tooltip_size.y > viewport_size.y - EDGE_MARGIN:
		global_pos.y = entry_rect.position.y - tooltip_size.y - PADDING

	global_pos.x = clamp(global_pos.x, EDGE_MARGIN, max(viewport_size.x - tooltip_size.x - EDGE_MARGIN, EDGE_MARGIN))
	global_pos.y = clamp(global_pos.y, EDGE_MARGIN, max(viewport_size.y - tooltip_size.y - EDGE_MARGIN, EDGE_MARGIN))

	tooltip_panel.position = get_global_transform().affine_inverse() * global_pos

func _clear_highlights() -> void:
	for list in [fish_list, inventory_list, settings_list]:
		for child in list.get_children():
			if child.has_method("set_highlighted"):
				child.set_highlighted(false)

func _on_tab_changed(_tab: int) -> void:
	tooltip_panel.visible = false
	_tab_focus_mode = false
	_focused_index = -1
	_clear_highlights()
