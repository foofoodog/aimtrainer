extends Control

# Mode selection controls
@onready var mode_option: OptionButton = $MainPanel/VBox/ModeContainer/ModeOption
@onready var custom_settings_panel: Control = $MainPanel/VBox/CustomSettings
@onready var misses_slider: HSlider = $MainPanel/VBox/CustomSettings/MissesHBox/MissesSlider
@onready var misses_value_label: Label = $MainPanel/VBox/CustomSettings/MissesHBox/MissesValue
@onready var speed_slider: HSlider = $MainPanel/VBox/CustomSettings/SpeedHBox/SpeedSlider
@onready var speed_value_label: Label = $MainPanel/VBox/CustomSettings/SpeedHBox/SpeedValue
@onready var afk_slider: HSlider = $MainPanel/VBox/CustomSettings/AFKHBox/AFKSlider
@onready var afk_value_label: Label = $MainPanel/VBox/CustomSettings/AFKHBox/AFKValue

@onready var high_score_label: Label = $MainPanel/VBox/HighScoreLabel
@onready var history_dialog: Window = $HistoryWindow
@onready var history_list: ItemList = $HistoryWindow/VBox/HistoryList

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Setup mode options
	mode_option.clear()
	mode_option.add_item("Easy (20s Timer, 15 Misses, Slow)", GameSettings.GameMode.EASY)
	mode_option.add_item("Medium (10s Timer, 10 Misses, Normal)", GameSettings.GameMode.MEDIUM)
	mode_option.add_item("Hard (5s Timer, 5 Misses, Fast)", GameSettings.GameMode.HARD)
	mode_option.add_item("Custom Mode", GameSettings.GameMode.CUSTOM)
	
	mode_option.select(GameSettings.current_mode)
	_on_mode_selected(GameSettings.current_mode)
	
	_update_high_score_display()
	
	# Listen for window input on the scores popup
	history_dialog.window_input.connect(_on_history_window_input)
	
	# Keep clear button hidden
	var clear_btn = history_dialog.get_node_or_null("VBox/BtnHBox/ClearHistoryButton")
	if clear_btn:
		clear_btn.visible = false

func _input(event: InputEvent) -> void:
	_handle_input_shortcuts(event)

func _on_history_window_input(event: InputEvent) -> void:
	_handle_input_shortcuts(event)

func _handle_input_shortcuts(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Toggle Fullscreen
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			var current_mode = DisplayServer.window_get_mode()
			if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			get_viewport().set_input_as_handled()
			return
			
		# Secret shortcut: Ctrl + Shift + Delete on score screen resets scores
		if history_dialog.visible and event.keycode == KEY_DELETE and event.ctrl_pressed and event.shift_pressed:
			ScoreManager.clear_history()
			_update_high_score_display()
			_populate_history()
			SoundEffects.play_hit(0.5)
			get_viewport().set_input_as_handled()

func _update_high_score_display() -> void:
	high_score_label.text = "★ ALL-TIME HIGH SCORE: %d ★" % ScoreManager.high_score

func _on_mode_selected(index: int) -> void:
	GameSettings.apply_preset(index as GameSettings.GameMode)
	custom_settings_panel.visible = (index == GameSettings.GameMode.CUSTOM)
	
	misses_slider.value = GameSettings.max_sequential_misses
	misses_value_label.text = str(GameSettings.max_sequential_misses)
	
	speed_slider.value = GameSettings.speed_ramp_rate
	speed_value_label.text = "%.1fx" % GameSettings.speed_ramp_rate
	
	afk_slider.value = GameSettings.afk_timeout
	afk_value_label.text = "%.0fs" % GameSettings.afk_timeout

func _on_misses_slider_changed(value: float) -> void:
	GameSettings.max_sequential_misses = int(value)
	misses_value_label.text = str(int(value))

func _on_speed_slider_changed(value: float) -> void:
	GameSettings.speed_ramp_rate = value
	speed_value_label.text = "%.1fx" % value

func _on_afk_slider_changed(value: float) -> void:
	GameSettings.afk_timeout = value
	afk_value_label.text = "%.0fs" % value

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_history_pressed() -> void:
	_populate_history()
	history_dialog.popup_centered(Vector2i(580, 420))

func _populate_history() -> void:
	history_list.clear()
	var records = ScoreManager.score_history
	if records.is_empty():
		history_list.add_item("No games recorded yet. Go shoot some targets!")
		return
		
	for rec in records:
		var txt = "%s | Score: %d | Mode: %s | Acc: %.1f%% (%d hits, %d misses)" % [
			rec.get("timestamp", "N/A"),
			rec.get("score", 0),
			rec.get("mode", "Medium"),
			rec.get("accuracy", 0.0),
			rec.get("hits", 0),
			rec.get("misses", 0)
		]
		if rec.get("is_high_score", false):
			txt = "★ " + txt
		history_list.add_item(txt)

func _on_clear_history_pressed() -> void:
	ScoreManager.clear_history()
	_update_high_score_display()
	_populate_history()

func _on_close_history_pressed() -> void:
	history_dialog.hide()

func _on_quit_pressed() -> void:
	get_tree().quit()
