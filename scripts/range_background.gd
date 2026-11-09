extends Node2D
class_name RangeBackground

var current_intensity: float = 0.0
var target_intensity: float = 0.0
var anim_time: float = 0.0

func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()

func set_speed_factor(speed_multiplier: float) -> void:
	target_intensity = clampf((speed_multiplier - 1.0) / 1.4, 0.0, 1.0)

func reset() -> void:
	target_intensity = 0.0
	current_intensity = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	anim_time += delta
	var needs_redraw = false
	
	if absf(current_intensity - target_intensity) > 0.001:
		current_intensity = move_toward(current_intensity, target_intensity, delta * 0.45)
		needs_redraw = true
		
	# Redraw smoothly for animated wind flag & clouds
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
	var sky_top_base = Color(0.16, 0.32, 0.54)
	var sky_upper_base = Color(0.35, 0.44, 0.58)
	var sky_mid_base = Color(0.86, 0.54, 0.32)
	var sky_bot_base = Color(0.98, 0.76, 0.46)
	
	# High-Speed Danger Palette (Crimson / Fiery Blood Red)
	var sky_top_red = Color(0.44, 0.06, 0.12)
	var sky_upper_red = Color(0.65, 0.12, 0.16)
	var sky_mid_red = Color(0.88, 0.22, 0.14)
	var sky_bot_red = Color(1.00, 0.44, 0.16)
	
	var sky_top = sky_top_base.lerp(sky_top_red, current_intensity)
	var sky_upper = sky_upper_base.lerp(sky_upper_red, current_intensity)
	var sky_mid = sky_mid_base.lerp(sky_mid_red, current_intensity)
	var sky_bot = sky_bot_base.lerp(sky_bot_red, current_intensity)
	
	RenderingServer.set_default_clear_color(sky_top)
	
	# Multi-layer Sky Gradient
	draw_rect(Rect2(left_pad, -200, total_w, 280), sky_top)
	draw_rect(Rect2(left_pad, 80, total_w, 110), sky_upper)
	draw_rect(Rect2(left_pad, 190, total_w, 110), sky_mid)
	draw_rect(Rect2(left_pad, 300, total_w, 70), sky_bot)
	
	# Soft sunset clouds drifting in upper atmosphere
	_draw_clouds(left_pad, total_w, sky_mid)
	
	# Setting Sun with Multi-layered Radiant Corona
	var sun_pos = Vector2(width * 0.5, 305.0)
	var sun_glow_outer = Color(1.0, 0.70, 0.35, 0.18).lerp(Color(0.95, 0.15, 0.10, 0.30), current_intensity)
	var sun_glow_mid = Color(1.0, 0.82, 0.45, 0.35).lerp(Color(1.0, 0.22, 0.12, 0.55), current_intensity)
	var sun_core = Color(1.0, 0.95, 0.75, 0.95).lerp(Color(1.0, 0.45, 0.20, 0.98), current_intensity)
	
	draw_circle(sun_pos, 110.0, sun_glow_outer)
	draw_circle(sun_pos, 65.0, sun_glow_mid)
	draw_circle(sun_pos, 38.0, sun_core)
	
	# Faceted 3D Mountains (Warm Sunlit Face vs Cool Shadow Face + Snow Caps)
	_draw_faceted_mountains(left_pad, right_edge)
	
	# Far Horizon Ground
	var far_ground_base = Color(0.36, 0.46, 0.28)
	var far_ground_red = Color(0.38, 0.32, 0.20)
	var far_ground = far_ground_base.lerp(far_ground_red, current_intensity)
	draw_rect(Rect2(left_pad, 350, total_w, 60), far_ground)
	
	# Layered Rolling Hills (Deep midground + Near midground)
	_draw_rolling_hills(left_pad, right_edge)
	
	# Target Range Stakes & Posts
	_draw_target_posts(left_pad, right_edge)
	
	# Animated Shooting Range Windsock / Flag
	_draw_wind_flag(width * 0.88, 380.0)
	
	# Near Ground (Y: 510 to bottom)
	var near_ground = Color(0.24, 0.35, 0.18)
	draw_rect(Rect2(left_pad, 510, total_w, maxf(220.0, height - 510.0 + 100.0)), near_ground)
	
	# 3D-Beveled Sandbag Bunkers with Drop Shadows
	_draw_sandbag_bunkers(width)
	
	# Bottom Shooting Bench (Wood Planks & Firing Deck)
	_draw_shooting_bench(left_pad, total_w, right_edge, height)

func _draw_clouds(left_pad: float, total_w: float, tint: Color) -> void:
	var cloud_col = Color(tint.r * 1.1, tint.g * 1.05, tint.b * 1.1, 0.25)
	# Draw smooth puffy cloud bands that drift slowly
	var drift = fmod(anim_time * 8.0, total_w)
	var c1_x = left_pad + fmod(180.0 + drift, total_w)
	_draw_puffy_cloud(Vector2(c1_x, 90.0), 90.0, cloud_col)
	
	var c2_x = left_pad + fmod(640.0 + drift * 0.7, total_w)
	_draw_puffy_cloud(Vector2(c2_x, 140.0), 120.0, cloud_col * 0.85)
	
	var c3_x = left_pad + fmod(1100.0 + drift * 0.5, total_w)
	_draw_puffy_cloud(Vector2(c3_x, 70.0), 80.0, cloud_col * 0.75)

func _draw_puffy_cloud(pos: Vector2, w: float, col: Color) -> void:
	draw_circle(pos, w * 0.28, col)
	draw_circle(pos + Vector2(w * 0.24, -w * 0.08), w * 0.22, col)
	draw_circle(pos + Vector2(-w * 0.24, w * 0.02), w * 0.20, col)
	draw_circle(pos + Vector2(w * 0.45, w * 0.05), w * 0.16, col)

func _draw_faceted_mountains(left_pad: float, right_edge: float) -> void:
	var base_y = 390.0
	var cur_x = left_pad
	var peak_step = 160.0
	var peak_toggle = false
	
	var lit_color_base = Color(0.48, 0.42, 0.54)
	var shadow_color_base = Color(0.36, 0.32, 0.42)
	var snow_color = Color(0.92, 0.94, 0.98, 0.85)
	
	var lit_color = lit_color_base.lerp(Color(0.55, 0.22, 0.30), current_intensity)
	var shadow_color = shadow_color_base.lerp(Color(0.38, 0.14, 0.20), current_intensity)
	
	while cur_x < right_edge:
		var x0 = cur_x
		var x_peak = cur_x + peak_step * 0.5
		var x1 = cur_x + peak_step
		var peak_y = 240.0 if peak_toggle else 310.0
		peak_toggle = not peak_toggle
		
		# Sunlit Face (Left slope)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x0, base_y),
			Vector2(x_peak, peak_y),
			Vector2(x_peak, base_y)
		]), lit_color)
		
		# Shadow Face (Right slope)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x_peak, peak_y),
			Vector2(x1, base_y),
			Vector2(x_peak, base_y)
		]), shadow_color)
		
		# Snow Cap on high peaks
		if peak_y <= 260.0:
			var snow_h = 32.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(x_peak, peak_y),
				Vector2(x_peak - 22.0, peak_y + snow_h),
				Vector2(x_peak - 8.0, peak_y + snow_h - 6.0),
				Vector2(x_peak, peak_y + snow_h - 2.0),
				Vector2(x_peak + 12.0, peak_y + snow_h - 4.0),
				Vector2(x_peak + 24.0, peak_y + snow_h)
			]), snow_color)
			
		cur_x += peak_step

func _draw_rolling_hills(left_pad: float, right_edge: float) -> void:
	# Back Hill Layer
	var back_hill_col = Color(0.28, 0.38, 0.22).lerp(Color(0.34, 0.30, 0.18), current_intensity)
	var back_pts = PackedVector2Array([Vector2(left_pad, 510)])
	var cur_x = left_pad
	var toggle = true
	while cur_x < right_edge:
		cur_x += 280.0
		var hy = 430.0 if toggle else 455.0
		toggle = not toggle
		back_pts.append(Vector2(cur_x, hy))
	back_pts.append(Vector2(right_edge, 510))
	draw_colored_polygon(back_pts, back_hill_col)
	
	# Fore Hill Layer with ridge shading
	var fore_hill_col = Color(0.32, 0.44, 0.25).lerp(Color(0.38, 0.34, 0.20), current_intensity)
	var fore_pts = PackedVector2Array([Vector2(left_pad, 530)])
	cur_x = left_pad + 60.0
	toggle = false
	while cur_x < right_edge:
		cur_x += 310.0
		var hy = 415.0 if toggle else 440.0
		toggle = not toggle
		fore_pts.append(Vector2(cur_x, hy))
	fore_pts.append(Vector2(right_edge, 530))
	draw_colored_polygon(fore_pts, fore_hill_col)

func _draw_target_posts(left_pad: float, right_edge: float) -> void:
	var wood_color = Color(0.44, 0.30, 0.18)
	var wood_highlight = Color(0.55, 0.38, 0.24)
	var dark_wood = Color(0.28, 0.16, 0.08)
	
	var cur_x = left_pad + 90.0
	while cur_x < right_edge - 60.0:
		# Main vertical post with wood grain highlight
		draw_rect(Rect2(cur_x, 390, 8, 30), wood_color)
		draw_line(Vector2(cur_x + 1, 390), Vector2(cur_x + 1, 420), wood_highlight, 1.5)
		# Horizontal target beam
		draw_line(Vector2(cur_x - 14, 400), Vector2(cur_x + 22, 400), dark_wood, 3.5)
		# Cast shadow line onto turf
		draw_line(Vector2(cur_x + 8, 420), Vector2(cur_x + 24, 426), Color(0.12, 0.18, 0.09, 0.5), 2.0)
		cur_x += 220.0

func _draw_wind_flag(x: float, y: float) -> void:
	# Wooden pole
	draw_rect(Rect2(x, y - 55.0, 4.0, 60.0), Color(0.38, 0.26, 0.16))
	draw_circle(Vector2(x + 2, y - 55), 4.0, Color(0.75, 0.65, 0.2))
	
	# Fluttering triangular range flag (orange-red warning flag)
	var wave1 = sin(anim_time * 8.0) * 4.0
	var wave2 = cos(anim_time * 9.5) * 5.0
	var flag_pts = PackedVector2Array([
		Vector2(x + 4, y - 54),
		Vector2(x + 36, y - 48 + wave1),
		Vector2(x + 4, y - 42)
	])
	draw_colored_polygon(flag_pts, Color(0.95, 0.32, 0.15))
	draw_line(Vector2(x + 4, y - 54), Vector2(x + 36, y - 48 + wave1), Color(1.0, 0.6, 0.3), 1.5)

func _draw_sandbag_bunkers(width: float) -> void:
	_draw_single_bunker(width * 0.16, 545.0)
	_draw_single_bunker(width * 0.84, 545.0)
	if width > 1400.0:
		_draw_single_bunker(width * 0.5, 555.0)

func _draw_single_bunker(center_x: float, top_y: float) -> void:
	var sandbag = Color(0.72, 0.62, 0.46)
	var sandbag_shade = Color(0.52, 0.42, 0.30)
	var sandbag_highlight = Color(0.85, 0.75, 0.58)
	
	# Main Bunker Parapet Trapezoid
	draw_colored_polygon(PackedVector2Array([
		Vector2(center_x - 62, top_y + 45),
		Vector2(center_x - 42, top_y),
		Vector2(center_x + 62, top_y),
		Vector2(center_x + 82, top_y + 45)
	]), sandbag)
	
	# Front Bevel Shading & Texture Stitches
	draw_rect(Rect2(center_x - 52, top_y + 6, 124, 38), sandbag_shade)
	
	# Highlight rim on top ridge
	draw_line(Vector2(center_x - 40, top_y + 1), Vector2(center_x + 60, top_y + 1), sandbag_highlight, 2.0)
	
	# Individual Sandbag Sack Bulges & Seams
	for i in range(3):
		var sack_x = center_x - 34.0 + float(i) * 36.0
		draw_line(Vector2(sack_x, top_y + 4), Vector2(sack_x + 3, top_y + 42), Color(0.35, 0.28, 0.18, 0.7), 2.0)

func _draw_shooting_bench(left_pad: float, total_w: float, right_edge: float, height: float) -> void:
	var bench_y = height - 32.0
	# Deep rich wood planks
	draw_rect(Rect2(left_pad, bench_y, total_w, 42.0), Color(0.20, 0.13, 0.08))
	draw_rect(Rect2(left_pad, bench_y + 2, total_w, 12.0), Color(0.28, 0.18, 0.12))
	# Plank divider grooves
	draw_line(Vector2(left_pad, bench_y), Vector2(right_edge, bench_y), Color(0.42, 0.28, 0.18), 3.0)
	draw_line(Vector2(left_pad, bench_y + 14), Vector2(right_edge, bench_y + 14), Color(0.12, 0.08, 0.05), 2.0)
