class_name RhythmUI extends CanvasLayer

@onready var player_health_bar: ProgressBar = $PlayerHealthBar
@onready var npc_health_bar: ProgressBar = $NPCHealthBar
@onready var combo_label: Label = $ComboLabel

func setup(player_hc: HealthComponent, npc_hc: HealthComponent) -> void:
	player_hc.health_changed.connect(_on_player_health_changed)
	npc_hc.health_changed.connect(_on_npc_health_changed)
	_on_player_health_changed(player_hc.current_health, player_hc.max_health)
	_on_npc_health_changed(npc_hc.current_health, npc_hc.max_health)
	combo_label.visible = false

func update_combo(combo: int) -> void:
	if combo <= 1:
		combo_label.visible = false
	else:
		combo_label.visible = true
		combo_label.text = "%dx" % combo

func _on_player_health_changed(current: int, maximum: int) -> void:
	player_health_bar.max_value = maximum
	player_health_bar.value = current

func _on_npc_health_changed(current: int, maximum: int) -> void:
	npc_health_bar.max_value = maximum
	npc_health_bar.value = current
