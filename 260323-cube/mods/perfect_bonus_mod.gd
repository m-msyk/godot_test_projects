class_name PerfectBonusMod extends Mod

@export var health_bonus: int = 5

func on_song_complete(battle: RhythmBattle) -> void:
	if battle.perfect_run:
		PlayerData.upgrades["max_health"] = PlayerData.upgrades.get("max_health", 0) + 1
		PlayerData.upgrades_changed.emit()
		print("Perfect run! Max health increased by ", health_bonus)

func get_stat_display(level: int) -> String:
	return "Active — +%d max HP on perfect run" % health_bonus
