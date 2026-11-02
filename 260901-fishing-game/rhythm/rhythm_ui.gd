class_name RhythmUI extends CanvasLayer

@onready var reel_progress_bar: ProgressBar = $ReelProgressBar
@onready var combo_label: Label = $ComboLabel

func setup(npc_reel: ReelProgressComponent) -> void:
	npc_reel.progress_changed.connect(_on_reel_progress_changed)
	_on_reel_progress_changed(npc_reel.current_progress, npc_reel.catch_threshold)
	combo_label.visible = false

func update_combo(combo: int) -> void:
	if combo <= 1:
		combo_label.visible = false
	else:
		combo_label.visible = true
		combo_label.text = "%dx" % combo

func _on_reel_progress_changed(current: int, threshold: int) -> void:
	reel_progress_bar.max_value = threshold
	reel_progress_bar.value = current
