class_name MilestoneDamageMod extends Mod

@export var milestone_interval: int = 100
@export var bonus_damage: int = 50

func on_battle_start(battle: RhythmBattle) -> void:
	battle.last_milestone = 0

func on_hit(battle: RhythmBattle) -> void:
	var milestone: int = (battle.combo / milestone_interval) * milestone_interval
	if milestone > battle.last_milestone and battle.combo >= milestone_interval:
		battle.last_milestone = milestone
		if not battle.npc_defeated:
			battle.npc_health_component.take_damage(bonus_damage)
		else:
			PlayerData.add_rhythm_points(bonus_damage)
		print("Milestone %d! +%d damage" % [milestone, bonus_damage])

func get_stat_display(level: int) -> String:
	return "%d per %dc" % [bonus_damage, milestone_interval]
