extends Node

enum GameMode {
	EASY,
	MEDIUM,
	HARD,
	CUSTOM
}

var current_mode: GameMode = GameMode.MEDIUM
var max_sequential_misses: int = 10
var speed_ramp_rate: float = 1.0     # 0.5 = slow ramp, 1.0 = normal, 2.0 = fast
var count_escapes_as_miss: bool = true
var afk_timeout: float = 10.0        # Seconds without firing before game over (Easy: 20, Medium: 10, Hard: 5)

func _ready() -> void:
	apply_preset(current_mode)

func apply_preset(mode: GameMode) -> void:
	current_mode = mode
	match mode:
		GameMode.EASY:
			max_sequential_misses = 15
			speed_ramp_rate = 0.5
			count_escapes_as_miss = false
			afk_timeout = 20.0
		GameMode.MEDIUM:
			max_sequential_misses = 10
			speed_ramp_rate = 1.0
			count_escapes_as_miss = true
			afk_timeout = 10.0
		GameMode.HARD:
			max_sequential_misses = 5
			speed_ramp_rate = 1.75
			count_escapes_as_miss = true
			afk_timeout = 5.0
		GameMode.CUSTOM:
			# Keep existing custom parameters
			pass

func get_mode_name(mode: GameMode = current_mode) -> String:
	match mode:
		GameMode.EASY: return "Easy"
		GameMode.MEDIUM: return "Medium"
		GameMode.HARD: return "Hard"
		GameMode.CUSTOM: return "Custom"
	return "Medium"
