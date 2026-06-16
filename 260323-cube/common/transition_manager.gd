extends Node

enum Type {
	BLACK,
	STOCHASTIC,
	FLASH,
	WIPE,
}

func run(on_swap: Callable, type: Type = Type.BLACK) -> void:
	StateManager.set_state(StateManager.State.PARTIAL)
	await _transition_out(type)
	on_swap.call()
	await _transition_in(type)
	StateManager.set_state(StateManager.State.FREE)

func _transition_out(type: Type) -> void:
	match type:
		Type.BLACK:
			await ScreenFade.fade_to_black()
		Type.STOCHASTIC:
			await ScreenFade.fade_to_black() # placeholder until implemented
		Type.FLASH:
			await ScreenFade.fade_to_black() # placeholder until implemented
		Type.WIPE:
			await ScreenFade.fade_to_black() # placeholder until implemented

func _transition_in(type: Type) -> void:
	match type:
		Type.BLACK:
			await ScreenFade.fade_from_black()
		Type.STOCHASTIC:
			await ScreenFade.fade_from_black() # placeholder
		Type.FLASH:
			await ScreenFade.fade_from_black() # placeholder
		Type.WIPE:
			await ScreenFade.fade_from_black() # placeholder
