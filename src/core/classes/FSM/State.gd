class_name State
extends Node

func enter(state_owner: Node2D, state_machine: StateMachine) -> void: pass

func exit(state_owner: Node2D, state_machine: StateMachine) -> void: pass

func update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void: pass

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void: pass
