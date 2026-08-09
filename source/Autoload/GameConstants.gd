extends Node

# GameConstants — AUTOLOAD
# Project-wide constants that benefit from editor autocompletion.
# Shake presets live here (not in PlayerCamera) specifically so typing
# `GameConstants.ShakePreset.` autocompletes the preset names — a
# StringName gives the editor nothing to suggest.

enum ShakePreset {
	FAST_FALL,
	FORCED_FALL,
	BIG_FALL,
	HIT_LIGHT,
	HIT_HEAVY,
	PARRY_SUCCESS,
	BOSS_INTRO,
}

const SHAKE_PRESETS: Dictionary = {
	ShakePreset.FAST_FALL:     {"power": 5.0,  "duration": 0.05,  "frequency": 60.0, "type": PlayerCamera.ShakeType.RANDOM},
	ShakePreset.FORCED_FALL:   {"power": 6.0,  "duration": 0.35, "frequency": 20.0, "type": PlayerCamera.ShakeType.RANDOM},
	ShakePreset.BIG_FALL:      {"power": 70.0, "duration": 0.7,  "frequency": 70.0, "type": PlayerCamera.ShakeType.RANDOM},
	ShakePreset.HIT_LIGHT:     {"power": 4.0,  "duration": 0.15, "frequency": 35.0, "type": PlayerCamera.ShakeType.RANDOM},
	ShakePreset.HIT_HEAVY:     {"power": 9.0,  "duration": 0.35, "frequency": 25.0, "type": PlayerCamera.ShakeType.RANDOM},
	ShakePreset.PARRY_SUCCESS: {"power": 3.0,  "duration": 0.0,  "frequency": 0.0,  "type": PlayerCamera.ShakeType.RANDOM},
	ShakePreset.BOSS_INTRO:    {"power": 6.0,  "duration": 0.6,  "frequency": 15.0, "type": PlayerCamera.ShakeType.RANDOM},
}
