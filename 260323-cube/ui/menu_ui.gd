class_name MenuUI extends Control

const TASK_ENTRY = preload("res://ui/task_entry.tscn")

@onready var tab_container: TabContainer = $Panel/TabContainer
@onready var task_list: VBoxContainer = $Panel/TabContainer/Tasks/TaskList
@onready var tooltip_panel: PanelContainer = $TooltipPanel
@onready var tooltip_label: Label = $TooltipPanel/TooltipLabel

var _focused_task_index: int = -1

func _ready() -> void:
	tooltip_panel.visible = false
	_connect_signals()
	_populate_tasks()

func _connect_signals() -> void:
	QuestManager.quest_added.connect(_on_quest_added)
	QuestManager.quest_completed.connect(_on_quest_completed)

func _on_quest_added(_quest: Quest) -> void:
	_populate_tasks()

func _on_quest_completed(_quest: Quest) -> void:
	_populate_tasks()

func _populate_tasks() -> void:
	for child in task_list.get_children():
		child.queue_free()
	for quest in QuestManager.get_active_quests():
		var entry := TASK_ENTRY.instantiate()
		task_list.add_child(entry)
		entry.setup(quest)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		tooltip_panel.position = get_local_mouse_position() + Vector2(10, 10)

		var hovering_any := false
		if tab_container.current_tab == 0:  # 0 is the Tasks tab
			for child in task_list.get_children():
				if child is TaskEntry:
					var is_hovering = child.get_global_rect().has_point(event.global_position)
					child.set_highlighted(is_hovering)
					if is_hovering:
						tooltip_label.text = child.get_description()
						hovering_any = true
		tooltip_panel.visible = hovering_any
		
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT:
				tab_container.current_tab = max(0, tab_container.current_tab - 1)
			KEY_RIGHT:
				tab_container.current_tab = min(tab_container.get_tab_count() - 1, tab_container.current_tab + 1)
			KEY_UP:
				_navigate_tasks(-1)
			KEY_DOWN:
				_navigate_tasks(1)

func _navigate_tasks(direction: int) -> void:
	if tab_container.current_tab != 0:
		return
	var tasks = task_list.get_children()
	if tasks.is_empty():
		return
	_focused_task_index = clamp(_focused_task_index + direction, 0, tasks.size() - 1)
	for i in tasks.size():
		tasks[i].set_highlighted(i == _focused_task_index)
	tooltip_label.text = tasks[_focused_task_index].get_description()
	tooltip_panel.visible = true
	tooltip_panel.position = tasks[_focused_task_index].get_global_rect().end + Vector2(10, 10)

func _on_tab_changed(_tab: int) -> void:
	tooltip_panel.visible = false
	_focused_task_index = -1
	for child in task_list.get_children():
		if child is TaskEntry:
			child.set_highlighted(false)
