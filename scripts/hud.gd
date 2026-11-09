extends CanvasLayer
class_name HUD

@onready var score_label: Label = $TopBar/MainHBox/LeftSection/ScoreLabel
@onready var high_score_label: Label = $TopBar/MainHBox/LeftSection/HighScoreLabel
@onready var combo_label: Label = $TopBar/MainHBox/CenterSection/ComboLabel
@onready var speed_label: Label = $TopBar/MainHBox/RightSection/SpeedLabel
@onready var level_progress_label: Label = $TopBar/MainHBox/RightSection/LevelProgressLabel
@onready var accuracy_label: Label = $TopBar/MainHBox/RightSection/AccuracyLabel

# Bottom HUD Elements (Streak Stars above Shot Timer above Subtractive Bullet Glyphs)
@onready var bottom_bar: PanelContainer = $BottomBar
@onready var stars_container: HBoxContainer = $BottomBar/VBox/StarsHBox
@onready var afk_bar: ProgressBar = $BottomBar/VBox/AFKProgressBar
@onready var strikes_container: HBoxContainer = $BottomBar/VBox/StrikesHBox

var max_strikes: int = 10
var strike_pips: Array[Control] = []

# Inner Control class to draw a crisp 5-pointed star glyph
class StarGlyph extends Control:
	var star_color: Color = Color(1.0, 0.84, 0.15)
	var outline_color: Color = Color(0.12, 0.12, 0.16, 0.85)
	
	func _init(star_size: float = 14.0, color: Color = Color(1.0, 0.84, 0.15)) -> void:
		custom_minimum_size = Vector2(star_size, star_size)
		star_color = color
		
	func _draw() -> void:
		var center = size * 0.5
		var outer_r = minf(size.x, size.y) * 0.48
		var inner_r = outer_r * 0.42
		var points = PackedVector2Array()
		
		for i in range(10):
			var r = outer_r if (i % 2 == 0) else inner_r
			var angle = -PI * 0.5 + float(i) * (TAU / 10.0)
			points.append(center + Vector2(cos(angle), sin(angle)) * r)
			
		draw_colored_polygon(points, star_color)
		var outline_pts = points.duplicate()
		outline_pts.append(points[0])
		draw_polyline(outline_pts, outline_color, 1.2)

# Inner Control class to draw a crisp bullet / strike cartridge glyph
class BulletPip extends Control:
	var is_active: bool = true:
		set(val):
			is_active = val
			queue_redraw()
	
	func _init(pip_width: float = 14.0) -> void:
		custom_minimum_size = Vector2(pip_width, 24.0)

	func _draw() -> void:
		var w = size.x
		var h = size.y
		var bullet_inset = 2.0
		var bw = w - bullet_inset * 2.0
		
		if is_active:
			# Golden active bullet cartridge
			var body_color = Color(1.0, 0.78, 0.22)
			var tip_color = Color(1.0, 0.95, 0.50)
			var rim_color = Color(0.85, 0.55, 0.15)
			
			# Cartridge body
			draw_rect(Rect2(bullet_inset, 8.0, bw, h - 11.0), body_color)
			# Bullet nose cone
			draw_circle(Vector2(w * 0.5, 8.0), bw * 0.5, tip_color)
			# Bottom rim
			draw_rect(Rect2(bullet_inset - 1.0, h - 3.5, bw + 2.0, 3.0), rim_color)
		else:
			# Spent / empty silhouette outline
			var empty_color = Color(0.40, 0.44, 0.52, 0.35)
			draw_rect(Rect2(bullet_inset, 8.0, bw, h - 11.0), empty_color, false, 1.5)
			draw_arc(Vector2(w * 0.5, 8.0), bw * 0.5, PI, TAU, 16, empty_color, 1.5)
			draw_rect(Rect2(bullet_inset - 1.0, h - 3.5, bw + 2.0, 3.0), empty_color, false, 1.5)

func setup(max_misses: int, current_high: int) -> void:
	max_strikes = max_misses
	high_score_label.text = "HIGH: %d" % current_high
	update_score(0)
	update_combo(0)
	update_speed(1.0, 1, 0)
	update_accuracy(0, 0)
	_build_strike_display()
	update_misses(0)

var score_tween: Tween = null

func update_score(score: int) -> void:
	score_label.text = "SCORE: %d" % score

func flash_score_deduction() -> void:
	if score_tween and score_tween.is_valid():
		score_tween.kill()
		
	# Flash red on deduction and smoothly restore to original gold
	score_label.modulate = Color(2.5, 0.2, 0.2)
	score_tween = create_tween()
	score_tween.tween_property(score_label, "modulate", Color.WHITE, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func update_combo(combo: int) -> void:
	if combo > 1:
		var bonus = combo * 1000
		combo_label.text = "STREAK: %d (+%d BONUS)" % [combo, bonus]
		combo_label.visible = true
	else:
		combo_label.visible = false
		
	_update_streak_stars(combo)

func _update_streak_stars(streak: int) -> void:
	for child in stars_container.get_children():
		stars_container.remove_child(child)
		child.queue_free()
		
	# Keep container permanently visible and sized so layout never shifts or jumps
	stars_container.visible = true
	stars_container.custom_minimum_size = Vector2(0, 16)
	
	if streak <= 0:
		return
	
	# Determine star styling and size based on streak count
	var star_count = mini(streak, 15)
	var star_size = 14.0
	var separation = 3.0
	if streak > 6:
		star_size = 12.0
		separation = 2.0
	if streak > 10:
		star_size = 10.0
		separation = 2.0
		
	stars_container.add_theme_constant_override("separation", int(separation))
	
	# Color shifts with streak intensity:
	# Gold (1-4) -> Radiant Cyan-Gold (5-9) -> Fiery Prismatic Flame (10+)
	var star_col = Color(1.0, 0.84, 0.15)
	if streak >= 10:
		star_col = Color(1.0, 0.55, 0.20)
	elif streak >= 5:
		star_col = Color(0.95, 0.95, 0.35)
		
	for i in range(star_count):
		var star = StarGlyph.new(star_size, star_col)
		stars_container.add_child(star)
		
	# If streak exceeds 15, append a sleek badge text "+N"
	if streak > 15:
		var extra_lbl = Label.new()
		extra_lbl.text = "+%d" % (streak - 15)
		extra_lbl.add_theme_font_size_override("font_size", 10)
		extra_lbl.add_theme_color_override("font_color", star_col)
		stars_container.add_child(extra_lbl)
		
	# Star sparkle pulse when streak increases
	var tween = create_tween()
	stars_container.modulate = Color(1.8, 1.8, 1.2)
	tween.tween_property(stars_container, "modulate", Color.WHITE, 0.22)

func update_speed(difficulty: float, level: int = 1, hits_in_level: int = 0) -> void:
	speed_label.text = "SPEED: %.1fx (LVL %d)" % [difficulty, level]
	level_progress_label.text = "NEXT LVL: %d / 10 HITS" % hits_in_level

func update_accuracy(hits: int, shots: int) -> void:
	if shots == 0:
		accuracy_label.text = "ACCURACY: 100%"
	else:
		var pct = (float(hits) / float(shots)) * 100.0
		accuracy_label.text = "ACCURACY: %.1f%%" % pct

func update_misses(current_misses: int) -> void:
	# Subtractive: starts with all pips full, loses one per consecutive miss
	var remaining = max_strikes - current_misses
	
	for i in range(strike_pips.size()):
		var pip = strike_pips[i]
		pip.is_active = (i < remaining)
			
	if remaining <= 2 and remaining > 0:
		_pulse_warning()

func update_afk_timer(time_left: float, max_time: float) -> void:
	var clamped_left = maxf(0.0, time_left)
	var ratio = clampf(clamped_left / maxf(0.1, max_time), 0.0, 1.0)
	afk_bar.value = ratio * 100.0
	
	# Color shift: green/cyan -> yellow -> flashing red
	if clamped_left <= 1.5:
		afk_bar.modulate = Color(1.8, 0.25, 0.25)
	elif clamped_left <= 3.0:
		afk_bar.modulate = Color(1.0, 0.85, 0.2)
	else:
		afk_bar.modulate = Color(0.35, 0.95, 0.55)

func _build_strike_display() -> void:
	for child in strikes_container.get_children():
		strikes_container.remove_child(child)
		child.queue_free()
	strike_pips.clear()
	
	# Dynamic pip width and bar centering
	var pip_w = 14.0
	var separation = 6.0
	if max_strikes > 16:
		pip_w = 11.0
		separation = 4.0
	elif max_strikes > 24:
		pip_w = 9.0
		separation = 3.0
		
	strikes_container.add_theme_constant_override("separation", int(separation))
	
	var total_w = maxf(float(max_strikes) * (pip_w + separation) + 36.0, 180.0)
	bottom_bar.offset_left = -total_w / 2.0
	bottom_bar.offset_right = total_w / 2.0
	
	for i in range(max_strikes):
		var pip = BulletPip.new(pip_w)
		pip.is_active = true
		strikes_container.add_child(pip)
		strike_pips.append(pip)

func _pulse_warning() -> void:
	var tween = create_tween()
	tween.tween_property(bottom_bar, "modulate", Color(1.8, 0.3, 0.3), 0.15)
	tween.tween_property(bottom_bar, "modulate", Color.WHITE, 0.15)
