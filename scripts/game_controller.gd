extends Node2D

@onready var background: Node2D = $Background
@onready var spawner: Spawner = $Spawner
@onready var crosshair: Crosshair = $Crosshair
@onready var hud: HUD = $HUD
@onready var floating_text_scene = preload("res://scenes/floating_text.tscn")

# Overlays
@onready var game_over_panel: Control = $GameOverCanvas/GameOverPanel
@onready var game_over_title: Label = $GameOverCanvas/GameOverPanel/VBox/Title
@onready var final_score_label: Label = $GameOverCanvas/GameOverPanel/VBox/FinalScoreLabel
@onready var high_score_status: Label = $GameOverCanvas/GameOverPanel/VBox/HighScoreStatus
@onready var stats_label: Label = $GameOverCanvas/GameOverPanel/VBox/StatsLabel

@onready var pause_panel: Control = $PauseCanvas/PausePanel

var total_score: int = 0
var total_shots: int = 0
var total_hits: int = 0
var total_misses: int = 0
var current_streak: int = 0
var sequential_misses: int = 0
var max_sequential_misses: int = 3
var is_game_active: bool = false
var is_paused: bool = false

# AFK Shot Timer
var afk_timer: float = 4.0
var max_afk_time: float = 4.0

# Screen shake
var shake_amount: float = 0.0

func _ready() -> void:
	game_over_panel.visible = false
	pause_panel.visible = false
	
	max_sequential_misses = GameSettings.max_sequential_misses
	max_afk_time = GameSettings.afk_timeout
	afk_timer = max_afk_time
	
	hud.setup(max_sequential_misses, ScoreManager.high_score)
	hud.update_afk_timer(afk_timer, max_afk_time)
	
	_setup_atmospheric_particles()
	
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	start_game()

var muzzle_light: PointLight2D = null

func _setup_atmospheric_particles() -> void:
	var motes = CPUParticles2D.new()
	motes.name = "AmbientMotes"
	motes.texture = RangeFX.get_circle_texture()
	motes.amount = 30
	motes.lifetime = 6.0
	motes.preprocess = 4.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(900.0, 360.0)
	motes.position = Vector2(640.0, 360.0)
	motes.direction = Vector2(1.0, -0.15)
	motes.spread = 25.0
	motes.gravity = Vector2(0, -4.0)
	motes.initial_velocity_min = 12.0
	motes.initial_velocity_max = 32.0
	motes.scale_amount_min = 0.08
	motes.scale_amount_max = 0.20
	motes.color = Color(1.0, 0.90, 0.65, 0.32)
	add_child(motes)

func _trigger_muzzle_flash() -> void:
	if not muzzle_light:
		muzzle_light = PointLight2D.new()
		muzzle_light.texture = RangeFX.get_circle_texture()
		muzzle_light.texture_scale = 14.0
		muzzle_light.color = Color(1.0, 0.85, 0.45)
		muzzle_light.energy = 0.0
		muzzle_light.position = Vector2(get_viewport_rect().size.x * 0.5, get_viewport_rect().size.y - 30.0)
		add_child(muzzle_light)
		
	muzzle_light.energy = 2.5
	var tween = create_tween()
	tween.tween_property(muzzle_light, "energy", 0.0, 0.07)

func start_game() -> void:
	total_score = 0
	total_shots = 0
	total_hits = 0
	total_misses = 0
	current_streak = 0
	sequential_misses = 0
	
	max_afk_time = GameSettings.afk_timeout
	afk_timer = max_afk_time
	
	is_game_active = true
	is_paused = false
	
	spawner.start(GameSettings.speed_ramp_rate)
	hud.setup(max_sequential_misses, ScoreManager.high_score)
	hud.update_afk_timer(afk_timer, max_afk_time)

func _process(delta: float) -> void:
	if not is_game_active or is_paused:
		return
		
	# Countdown AFK shot timer
	afk_timer -= delta
	hud.update_afk_timer(afk_timer, max_afk_time)
	
	if afk_timer <= 0.0:
		trigger_game_over("AFK TIMEOUT!\n(Took too long to take a shot)")
		return
		
	# Update HUD speed and level display
	var difficulty = spawner.get_current_difficulty()
	hud.update_speed(difficulty, spawner.current_level, total_hits % 10)
	if background and background.has_method("set_speed_factor"):
		background.set_speed_factor(difficulty)
	
	# Handle screen shake
	if shake_amount > 0.0:
		shake_amount = move_toward(shake_amount, 0.0, delta * 30.0)
		background.position = Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
	else:
		background.position = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if not is_game_active:
		return
		
	# Toggle Fullscreen
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			var current_mode = DisplayServer.window_get_mode()
			if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			return
		
	if event.is_action_pressed("ui_cancel"): # ESC key
		toggle_pause()
		return
		
	if is_paused:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_fire_shot(event.position)

func _fire_shot(click_pos: Vector2) -> void:
	# Reset AFK timer on every shot taken
	afk_timer = max_afk_time
	
	total_shots += 1
	SoundEffects.play_gunshot()
	crosshair.kick_recoil()
	shake_amount = 5.0
	_trigger_muzzle_flash()
	
	# Raycast / Query targets at click point
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = click_pos
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var results = space_state.intersect_point(query, 10)
	var hit_target: Target = null
	var highest_z = -999
	
	for res in results:
		var collider = res.get("collider")
		if collider is Target and collider.is_alive:
			if collider.z_index > highest_z:
				highest_z = collider.z_index
				hit_target = collider
				
	if hit_target != null:
		_handle_hit(hit_target, click_pos)
	else:
		_handle_miss(click_pos)

func _handle_hit(target: Target, hit_pos: Vector2) -> void:
	total_hits += 1
	current_streak += 1
	# User rule: hitting a target resets sequential misses to 0!
	sequential_misses = 0
	
	# Check if level up occurred (every 10 hits)
	var old_lvl = spawner.current_level
	spawner.set_hits(total_hits)
	var new_lvl = spawner.current_level
	if new_lvl > old_lvl:
		SoundEffects.play_level_up()
		_spawn_floating_text("LEVEL %d! SPEED UP!" % new_lvl, hit_pos + Vector2(0, -35), Color(1.0, 0.4, 1.0), 1.5)
	
	var streak_mult = 1.0 + (current_streak - 1) * 0.1
	var points = int(target.get_total_score() * streak_mult)
	
	# Streak bonus: 1000 per consecutive hit in a streak (triggers for streak >= 2)
	var streak_bonus = 0
	if current_streak >= 2:
		streak_bonus = current_streak * 1000
		SoundEffects.play_streak(current_streak)
		_spawn_floating_text("+%d STREAK BONUS! (x%d)" % [streak_bonus, current_streak], hit_pos + Vector2(0, -25), Color(0.2, 1.0, 0.4), 1.25)
		
	total_score += points + streak_bonus
	
	target.on_shot(hit_pos)
	crosshair.trigger_hitmarker()
	SoundEffects.play_hit(target.distance_multiplier)
	
	# Kinetic archetype-specific impact particles
	if target is BirdTarget:
		RangeFX.spawn_feather_burst(self, hit_pos, Color(0.35, 0.75, 1.0))
	elif target is BeastTarget:
		RangeFX.spawn_dirt_kickup(self, hit_pos)
	elif target is BruteTarget:
		RangeFX.spawn_metal_sparks(self, hit_pos)
	
	# Spawn floating score text
	_spawn_floating_text("+%d" % points, hit_pos, Color(1.0, 0.9, 0.2))
		
	hud.update_score(total_score)
	hud.update_combo(current_streak)
	hud.update_misses(sequential_misses)
	hud.update_accuracy(total_hits, total_shots)
	hud.update_speed(spawner.get_current_difficulty(), spawner.current_level, total_hits % 10)

func _handle_miss(click_pos: Vector2) -> void:
	total_misses += 1
	sequential_misses += 1
	current_streak = 0
	
	# Deduct 100 points per miss, down to a minimum of 0
	total_score = maxi(0, total_score - 100)
	
	# Pitch rises the more consecutive missed shots occur
	SoundEffects.play_miss(sequential_misses, max_sequential_misses)
	_spawn_floating_text("-100", click_pos, Color(1.0, 0.25, 0.25), 1.0)
	RangeFX.spawn_miss_puff(self, click_pos)
	
	hud.update_score(total_score)
	hud.flash_score_deduction()
	hud.update_combo(0)
	hud.update_misses(sequential_misses)
	hud.update_accuracy(total_hits, total_shots)
	
	# Check Game Over condition
	if sequential_misses >= max_sequential_misses:
		trigger_game_over("OUT OF ROUNDS!\n(All chances depleted)")

func _spawn_floating_text(text: String, pos: Vector2, color: Color, scale_mult: float = 1.0) -> void:
	var float_node = floating_text_scene.instantiate()
	float_node.position = pos
	add_child(float_node)
	float_node.setup(text, color, scale_mult)

func trigger_game_over(reason: String = "GAME OVER") -> void:
	is_game_active = false
	spawner.stop()
	crosshair.is_active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	SoundEffects.play_game_over()
	
	game_over_title.text = reason
	
	var accuracy = 0.0
	if total_shots > 0:
		accuracy = (float(total_hits) / float(total_shots)) * 100.0
		
	var is_new_high = ScoreManager.record_game(
		total_score,
		total_hits,
		total_misses,
		accuracy,
		GameSettings.get_mode_name()
	)
	
	final_score_label.text = "FINAL SCORE: %d" % total_score
	if is_new_high:
		high_score_status.text = "★ NEW HIGH SCORE! ★"
		high_score_status.modulate = Color(1.0, 0.85, 0.2)
	else:
		high_score_status.text = "HIGH SCORE: %d" % ScoreManager.high_score
		high_score_status.modulate = Color(0.7, 0.85, 1.0)
		
	stats_label.text = "Hits: %d   |   Misses: %d   |   Accuracy: %.1f%%\nSpeed Reached: %.1fx" % [
		total_hits, total_misses, accuracy, spawner.get_current_difficulty()
	]
	
	game_over_panel.visible = true

func toggle_pause() -> void:
	is_paused = not is_paused
	pause_panel.visible = is_paused
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		crosshair.is_active = false
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		crosshair.is_active = true

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_resume_pressed() -> void:
	toggle_pause()
