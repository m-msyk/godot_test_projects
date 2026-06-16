class_name DamageBlockMod extends Mod

@export var blocks_per_level: int = 3

func on_battle_start(battle: RhythmBattle) -> void:
	var level: int = PlayerData.upgrades.get(mod_id, 0)
	battle.damage_blocks_remaining = level * blocks_per_level

func get_stat_display(level: int) -> String:
	return "%d blocks per battle" % (level * blocks_per_level)
