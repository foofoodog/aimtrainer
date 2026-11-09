extends Target
class_name BirdTarget

var flap_time: float = 0.0
var flap_speed: float = 14.0
var wave_freq: float = 3.5
var wave_amp: float = 55.0
var base_y: float = 0.0
var time_elapsed: float = 0.0

func _init() -> void:
	target_type_name = "Bird"
	base_points = 250
	speed = 280.0

func _ready() -> void:
	base_y = position.y
	wave_freq = randf_range(2.5, 4.0)
	wave_amp = randf_range(18.0, 32.0)
	flap_speed = randf_range(12.0, 18.0)
	queue_redraw()

func _process(delta: float) -> void:
	if not is_alive:
		return
	
	time_elapsed += delta
	flap_time += delta * flap_speed
	
	# Horizontal flight
	position.x += direction * speed * speed_multiplier * delta
	# Sinusoidal swooping - constrained so birds never fly up behind the top score bar
	# TopBar ends at y=68; with wing height ~35-65px, clamping at >= 155 keeps it well clear
	var swoop = sin(time_elapsed * wave_freq) * wave_amp
	position.y = clampf(base_y + swoop, 155.0, 330.0)
	
	queue_redraw()
	
	# Check boundary escape
	var view_w = maxf(1280.0, get_viewport_rect().size.x)
	if direction > 0 and position.x > view_w + 120.0:
		escape()
	elif direction < 0 and position.x < -120.0:
		escape()

func _draw() -> void:
	# Draw animated Bird Target
	var facing = 1.0 if direction > 0 else -1.0
	var wing_angle = sin(flap_time) * 0.7
	
	# Color palette
	var body_color = Color(0.18, 0.55, 0.92) # Sky blue bird
	var wing_color = Color(0.10, 0.40, 0.78)
	var belly_color = Color(0.95, 0.95, 0.98)
	var beak_color = Color(1.0, 0.75, 0.15)
	var bullseye_red = Color(0.92, 0.22, 0.22)
	var bullseye_white = Color(1.0, 1.0, 1.0)
	
	# Tail feathers
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24 * facing, 2),
		Vector2(-42 * facing, -8),
		Vector2(-40 * facing, 8)
	]), wing_color)
	
	# Body oval
	draw_circle(Vector2(0, 0), 20, body_color)
	draw_circle(Vector2(4 * facing, 3), 13, belly_color)
	
	# Target Bullseye on body
	draw_circle(Vector2(0, 0), 10, bullseye_white)
	draw_circle(Vector2(0, 0), 6, bullseye_red)
	
	# Head
	var head_pos = Vector2(18 * facing, -7)
	draw_circle(head_pos, 11, body_color)
	# Eye
	draw_circle(head_pos + Vector2(4 * facing, -2), 3, Color.BLACK)
	draw_circle(head_pos + Vector2(5 * facing, -3), 1, Color.WHITE)
	# Beak
	draw_colored_polygon(PackedVector2Array([
		head_pos + Vector2(9 * facing, -2),
		head_pos + Vector2(20 * facing, 0),
		head_pos + Vector2(9 * facing, 4)
	]), beak_color)
	
	# Flapping Wings (Upper & Lower polygons)
	var wing_tip_y = -36 + wing_angle * 30.0
	var wing_pts = PackedVector2Array([
		Vector2(-6 * facing, -6),
		Vector2(-20 * facing, wing_tip_y),
		Vector2(10 * facing, wing_tip_y + 12),
		Vector2(8 * facing, -2)
	])
	draw_colored_polygon(wing_pts, wing_color)
