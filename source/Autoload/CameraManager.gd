extends Node

signal shake(force: float)

func camera_shake(force: float = 0.5):
	shake.emit(force)
