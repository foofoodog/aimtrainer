extends Node2D
class_name RangeBackground

var current_intensity: float = 0.0
var target_intensity: float = 0.0

func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()

func set_speed_factor(speed_multiplier: float) -> void:
	# speed_multiplier starts at 1.0 (Level 1).
	# At ~2.4x speed (Level 7+), target_intensity reaches 1.0 (intense crimson sky).
	target_intensity = clampf((speed_multiplier - 1.0) / 1.4, 0.0, 1.0)

func reset() -> void:
	target_intensity = 0.0
	current_intensity = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if absf(current_intensity - target_intensity) > 0.001:
		current_intensity = move_toward(current_intensity, target_intensity, delta * 0.45)
		queue_redraw()

func _draw() -> void:
	var view_size = get_viewport_rect().size
	var width = maxf(view_size.x, 1280.0)
	var height = maxf(view_size.y, 720.0)
	
	# Overscan padding so no edge is ever exposed during shake or resizing
	var left_pad = -350.0
	var total_w = width + 700.0
	var right_edge = left_pad + total_w
	
	# Base Sky Gradient (Warm Golden Sunset)
	var sky_top_base = Color(0.18, 0.35, 0.58)
	var sky_mid_base = Color(0.85, 0.55, 0.35)
	var sky_bot_base = Color(0.96, 0.78, 0.50)
	var mountain_base = Color(0.42, 0.38, 0.48)
	var far_ground_base = Color(0.38, 0.48, 0.30)
	
	# High-Speed Danger Palette (Crimson / Fiery Blood Red)
	var sky_top_red = Color(0.48, 0.08, 0.12)
	var sky_mid_red = Color(0.86, 0.20, 0.14)
	var sky_bot_red = Color(1.00, 0.42, 0.16)
	var mountain_red = Color(0.44, 0.18, 0.25)
	var far_ground_red = Color(0.40, 0.36, 0.22)
	
	var sky_top = sky_top_base.lerp(sky_top_red, current_intensity)
	var sky_mid = sky_mid_base.lerp(sky_mid_red, current_intensity)
	var sky_bot = sky_bot_base.lerp(sky_bot_red, current_intensity)
	var mountain_color = mountain_base.lerp(mountain_red, current_intensity)
	var far_ground = far_ground_base.lerp(far_ground_red, current_intensity)
	
	RenderingServer.set_default_clear_color(sky_top)
	
	# Draw Sky bands
	draw_rect(Rect2(left_pad, -200, total_w, 380), sky_top)
	draw_rect(Rect2(left_pad, 180, total_w, 120), sky_mid)
	draw_rect(Rect2(left_pad, 300, total_w, 80), sky_bot)
	
	# Distant Sun (shifts from golden twilight to deep burning blood-orange)
	var sun_color = Color(1.0, 0.92, 0.65, 0.60).lerp(Color(1.0, 0.25, 0.12, 0.90), current_intensity)
	var sun_glow = Color(1.0, 0.75, 0.40, 0.22).lerp(Color(0.95, 0.15, 0.10, 0.40), current_intensity)
	draw_circle(Vector2(width * 0.5, 305.0), 65.0, sun_glow)
	draw_circle(Vector2(width * 0.5, 305.0), 38.0, sun_color)
	
	# Distant Mountains (FAR LAYER, Y: 240 - 390)
	var mountain_pts = PackedVector2Array()
	mountain_pts.append(Vector2(left_pad, 390))
	
	# Procedurally generate mountain peaks across the entire width
	var cur_x = left_pad
	var peak_toggle = false
	while cur_x < right_edge:
		cur_x += 160.0
		var peak_y = 250.0 if peak_toggle else 340.0
		peak_toggle = not peak_toggle
		mountain_pts.append(Vector2(cur_x, peak_y))
		
	mountain_pts.append(Vector2(right_edge, 390))
	draw_colored_polygon(mountain_pts, mountain_color)
	
	# Far Ground / Horizon (Y: 350 - 410)
	draw_rect(Rect2(left_pad, 350, total_w, 60), far_ground)
	
	# Midground Rolling Hills & Shooting Range Bunkers (Y: 410 - 530)
	var mid_ground = Color(0.30, 0.42, 0.24)
	var hill_pts = PackedVector2Array()
	hill_pts.append(Vector2(left_pad, 530))
	
	cur_x = left_pad
	var hill_up = true
	while cur_x < right_edge:
		cur_x += 320.0
		var hill_y = 412.0 if hill_up else 435.0
		hill_up = not hill_up
		hill_pts.append(Vector2(cur_x, hill_y))
		
	hill_pts.append(Vector2(right_edge, 530))
	draw_colored_polygon(hill_pts, mid_ground)
	
	# Wooden Target Posts / Trenches in Midground
	var wood_color = Color(0.42, 0.28, 0.16)
	var dark_wood = Color(0.30, 0.18, 0.10)
	
	# Distribute target posts across the full width
	cur_x = left_pad + 100.0
	while cur_x < right_edge - 60.0:
		draw_rect(Rect2(cur_x, 390, 8, 30), wood_color)
		draw_line(Vector2(cur_x - 12, 400), Vector2(cur_x + 20, 400), dark_wood, 3.0)
		cur_x += 220.0
		
	# Near Ground (Y: 510 to bottom)
	var near_ground = Color(0.24, 0.34, 0.18)
	draw_rect(Rect2(left_pad, 510, total_w, maxf(220.0, height - 510.0 + 100.0)), near_ground)
	
	# Foreground Sandbag Bunkers / Range Partitions
	var sandbag = Color(0.68, 0.58, 0.42)
	var sandbag_shade = Color(0.55, 0.45, 0.32)
	
	# Left Bunker (Pop-up cover spot)
	var left_bunker_x = width * 0.16
	draw_colored_polygon(PackedVector2Array([
		Vector2(left_bunker_x - 60, 590),
		Vector2(left_bunker_x - 40, 545),
		Vector2(left_bunker_x + 60, 545),
		Vector2(left_bunker_x + 80, 590)
	]), sandbag)
	draw_rect(Rect2(left_bunker_x - 50, 550, 120, 40), sandbag_shade)
	
	# Right Bunker (Pop-up cover spot)
	var right_bunker_x = width * 0.84
	draw_colored_polygon(PackedVector2Array([
		Vector2(right_bunker_x - 60, 590),
		Vector2(right_bunker_x - 40, 545),
		Vector2(right_bunker_x + 60, 545),
		Vector2(right_bunker_x + 80, 590)
	]), sandbag)
	draw_rect(Rect2(right_bunker_x - 50, 550, 120, 40), sandbag_shade)
	
	# Center Bunker (for wide/ultrawide screens)
	if width > 1400.0:
		var center_bunker_x = width * 0.5
		draw_colored_polygon(PackedVector2Array([
			Vector2(center_bunker_x - 50, 595),
			Vector2(center_bunker_x - 35, 555),
			Vector2(center_bunker_x + 45, 555),
			Vector2(center_bunker_x + 60, 595)
		]), sandbag)
		draw_rect(Rect2(center_bunker_x - 40, 560, 95, 35), sandbag_shade)
	
	# Bottom Shooting Bench / Firing Deck edge
	var bench_y = height - 30.0
	draw_rect(Rect2(left_pad, bench_y, total_w, 40.0), Color(0.18, 0.12, 0.08))
	draw_line(Vector2(left_pad, bench_y), Vector2(right_edge, bench_y), Color(0.32, 0.22, 0.14), 4.0)
