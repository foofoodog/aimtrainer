extends Node

const SAVE_PATH: String = "user://scores.json"

var high_score: int = 0
var score_history: Array = []

func _ready() -> void:
	load_data()

func record_game(score: int, hits: int, misses: int, accuracy: float, mode_name: String) -> bool:
	var is_new_high: bool = score > high_score
	if is_new_high:
		high_score = score
	
	var time_dict = Time.get_datetime_dict_from_system()
	var time_str = "%04d-%02d-%02d %02d:%02d" % [
		time_dict["year"], time_dict["month"], time_dict["day"],
		time_dict["hour"], time_dict["minute"]
	]
	
	var entry = {
		"timestamp": time_str,
		"score": score,
		"hits": hits,
		"misses": misses,
		"accuracy": accuracy,
		"mode": mode_name,
		"is_high_score": is_new_high
	}
	
	score_history.push_front(entry)
	if score_history.size() > 50:
		score_history.resize(50)
		
	save_data()
	return is_new_high

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK and typeof(json.data) == TYPE_DICTIONARY:
			high_score = int(json.data.get("high_score", 0))
			score_history = json.data.get("history", [])

func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"high_score": high_score,
			"history": score_history
		}
		file.store_string(JSON.stringify(data, "\t"))

func clear_history() -> void:
	score_history.clear()
	high_score = 0
	save_data()
