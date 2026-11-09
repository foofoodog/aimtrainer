extends Node2D
class_name Crosshair

var recoil_offset: float = 0.0
var hitmarker_timer: float = 0.0
var is_active: bool = true

func _ready() -> void:
	z_index = 100
	queue_redraw()

func _process(delta: float) -> void:
	if not is_active:
		return
	
	global_position = get_global_mouse_position()
	
	# Spring recoil back to 0
	if recoil_offset > 0.0:
		recoil_offset = move_toward(recoil_offset, 0.0, delta * 70.0)
		queue_redraw()
		
	# Hitmarker timer
	if hitmarker_timer > 0.0:
		hitmarker_timer -= delta
		queue_redraw()

func kick_recoil() -> void:
	recoil_offset = 12.0
	queue_redraw()

func trigger_hitmarker() -> void:
	hitmarker_timer = 0.15
	queue_redraw()

func _draw() -> void:
	var base_radius = 14.0 + recoil_offset
	var color = Color(1.0, 1.0, 1.0, 0.85)
	var line_len = 8.0
	var gap = 4.0 + recoil_offset
	
	# Center dot
	draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.2, 0.2, 0.9))
	
	# Crosshair reticle lines (North, South, East, West)
	draw_line(Vector2(0, -gap), Vector2(0, -gap - line_len), color, 2.0)
	draw_line(Vector2(0, gap), Vector2(0, gap + line_len), color, 2.0)
	draw_line(Vector2(-gap, 0), Vector2(-gap - line_len, 0), color, 2.0)
	draw_line(Vector2(gap, 0), Vector2(gap + line_len, 0), color, 2.0)
	
	# Outer subtle ring
	draw_arc(Vector2.ZERO, base_radius, 0, TAU, 32, Color(1.0, 1.0, 1.0, 0.35), 1.5)
	
	# Hitmarker (Diagonal X when a target is hit)
	if hitmarker_timer > 0.0:
		var hm_color = Color(1.0, 0.2, 0.2, clampf(hitmarker_timer / 0.15, 0.0, 1.0))
		var hm_dist = 8.0
		var hm_len = 8.0
		# 4 diagonal ticks
		draw_line(Vector2(-hm_dist, -hm_dist), Vector2(-hm_dist - hm_len, -hm_dist - hm_len), hm_color, 2.5)
		draw_line(Vector2(hm_dist, -hm_dist), Vector2(hm_dist + hm_len, -hm_dist - hm_len), hm_color, 2.5)
		draw_line(Vector2(-hm_dist, hm_dist), Vector2(-hm_dist - hm_len, hm_dist + hm_len), hm_color, 2.5)
		draw_line(Vector2(hm_dist, hm_dist), Vector2(hm_dist + hm_len, hm_dist + hm_len), hm_color, 2.5)
