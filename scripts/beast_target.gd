extends Target
class_name BeastTarget

var run_time: float = 0.0
var run_anim_speed: float = 16.0
var base_y: float = 0.0

func _init() -> void:
	target_type_name = "Beast"
	base_points = 175
	speed = 340.0

func _ready() -> void:
	base_y = position.y
	queue_redraw()

func _process(delta: float) -> void:
	if not is_alive:
		return
	
	run_time += delta * run_anim_speed
	
	# Horizontal sprint
	position.x += direction * speed * speed_multiplier * delta
	# Gallop bounce
	var bounce = abs(sin(run_time * 0.5)) * 14.0
	position.y = base_y - bounce
	
	queue_redraw()
	
	# Check boundary escape
	var view_w = maxf(1280.0, get_viewport_rect().size.x)
	if direction > 0 and position.x > view_w + 120.0:
		escape()
	elif direction < 0 and position.x < -120.0:
		escape()

func _play_death_effect() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	var tumble_target = position + Vector2(-direction * 65.0, -35.0)
	tween.tween_property(self, "position", tumble_target, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", -direction * 3.8, 0.32)
	tween.tween_property(self, "scale", scale * 0.4, 0.32)
	tween.tween_property(self, "modulate:a", 0.0, 0.32)
	tween.chain().tween_callback(queue_free)

func _draw() -> void:
	var facing = 1.0 if direction > 0 else -1.0
	
	var fur_color = Color(0.88, 0.46, 0.18) # Rich fox/tiger orange
	var fur_highlight = Color(1.0, 0.68, 0.35) # Sunset back highlight
	var belly_color = Color(0.96, 0.90, 0.80)
	var dark_color = Color(0.32, 0.16, 0.08)
	var bullseye_red = Color(0.95, 0.15, 0.15)
	var bullseye_white = Color(1.0, 1.0, 1.0)
	
	# Galloping legs angles
	var leg_front_fwd = sin(run_time) * 18.0
	var leg_front_back = -sin(run_time) * 18.0
	var leg_rear_fwd = sin(run_time + PI * 0.8) * 20.0
	var leg_rear_back = -sin(run_time + PI * 0.8) * 20.0
	
	# Rear legs (drawn first for depth)
	draw_line(Vector2(-22 * facing, 10), Vector2((-22 + leg_rear_back) * facing, 32), dark_color, 6.0)
	draw_line(Vector2(20 * facing, 10), Vector2((20 + leg_front_back) * facing, 32), dark_color, 6.0)
	
	# Tail
	var tail_wave = sin(run_time * 0.7) * 8.0
	draw_line(Vector2(-35 * facing, -4), Vector2(-60 * facing, -18 + tail_wave), fur_color, 7.0)
	draw_circle(Vector2(-60 * facing, -18 + tail_wave), 5.0, belly_color)
	
	# Main Torso
	draw_circle(Vector2(10 * facing, 0), 24, fur_color)
	draw_circle(Vector2(-14 * facing, 2), 20, fur_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18 * facing, -14),
		Vector2(16 * facing, -16),
		Vector2(16 * facing, 14),
		Vector2(-18 * facing, 14)
	]), fur_color)
	
	# Target Bullseye on flank
	draw_circle(Vector2(-2 * facing, 0), 12, bullseye_white)
	draw_circle(Vector2(-2 * facing, 0), 7, bullseye_red)
	
	# Front legs
	draw_line(Vector2(-20 * facing, 10), Vector2((-20 + leg_rear_fwd) * facing, 32), fur_color, 6.0)
	draw_line(Vector2(22 * facing, 10), Vector2((22 + leg_front_fwd) * facing, 32), fur_color, 6.0)
	
	# Head
	var head_pos = Vector2(34 * facing, -12)
	draw_circle(head_pos, 15, fur_color)
	# Muzzle
	draw_colored_polygon(PackedVector2Array([
		head_pos + Vector2(6 * facing, -4),
		head_pos + Vector2(20 * facing, 2),
		head_pos + Vector2(6 * facing, 8)
	]), belly_color)
	draw_circle(head_pos + Vector2(20 * facing, 2), 3, dark_color) # Nose
	
	# Ears
	draw_colored_polygon(PackedVector2Array([
		head_pos + Vector2(-6 * facing, -12),
		head_pos + Vector2(2 * facing, -28),
		head_pos + Vector2(8 * facing, -12)
	]), dark_color)
	# Eye
	draw_circle(head_pos + Vector2(6 * facing, -4), 3, Color.BLACK)
	draw_circle(head_pos + Vector2(7 * facing, -5), 1, Color.WHITE)
