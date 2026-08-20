extends StateMachine
class_name PlayerStateMachine

func _on_state_changed(from_state: StringName, to_state: StringName) -> void:
	DebugOverlay.player_state_changed.emit(from_state, to_state)
