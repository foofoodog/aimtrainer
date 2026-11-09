extends Target
class_name BruteTarget

var max_dwell_time: float = 1.8
var dwell_timer: float = 1.8
var is_popping: bool = false
var is_ducking: bool = false
var ground_y: float = 0.0
var target_y: float = 0.0

func _init() -> void:
	target_type_name = "Brute"
	base_points = 120

func _ready() -> void:
	# Calculate dwell time based on speed multiplier
	dwell_timer = maxf(0.7, max_dwell_time / maxf(0.5, speed_multiplier))
	max_dwell_time = dwell_timer
	
	target_y = position.y
	ground_y = position.y + 70.0 # start hidden below
	position.y = ground_y
	
	# Slide up animation
	is_popping = true
	var tween = create_tween()
	tween.tween_property(self, "position:y", target_y, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): is_popping = false)
	
	queue_redraw()

func _process(delta: float) -> void:
	if not is_alive or is_popping or is_ducking:
		return
		
	dwell_timer -= delta
	queue_redraw()
	
	if dwell_timer <= 0.0:
		_duck_and_escape()

func _duck_and_escape() -> void:
	is_ducking = true
	monitoring = false
	var tween = create_tween()
	tween.tween_property(self, "position:y", ground_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(escape)

func _play_death_effect() -> void:
	var tween = create_tween()
	modulate = Color(2.6, 2.6, 2.0) # White hot flash on impact
	tween.tween_property(self, "modulate", Color(0.4, 0.4, 0.4, 0.0), 0.24)
	tween.parallel().tween_property(self, "position:y", position.y + 70.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

func _draw() -> void:
	var armor_steel = Color(0.30, 0.32, 0.38)
	var armor_highlight = Color(0.46, 0.50, 0.58)
	var armor_trim = Color(0.80, 0.62, 0.22) # Bronze/Gold trim
	var brute_skin = Color(0.35, 0.48, 0.32) # Orc/Troll green
	var bullseye_red = Color(0.95, 0.15, 0.15)
	var bullseye_white = Color(1.0, 1.0, 1.0)
	
	# Broad Shoulders / Body
	draw_colored_polygon(PackedVector2Array([
		Vector2(-46, 26),
		Vector2(-42, -18),
		Vector2(42, -18),
		Vector2(46, 26)
	]), armor_steel)
	
	# Shoulder Spikes / Armor pads
	draw_colored_polygon(PackedVector2Array([
		Vector2(-44, -18),
		Vector2(-62, -26),
		Vector2(-42, -38),
		Vector2(-24, -22)
	]), armor_trim)
	draw_colored_polygon(PackedVector2Array([
		Vector2(44, -18),
		Vector2(62, -26),
		Vector2(42, -38),
		Vector2(24, -22)
	]), armor_trim)
	
	# Head / Helmet
	draw_circle(Vector2(0, -38), 24, brute_skin)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22, -38),
		Vector2(0, -56),
		Vector2(22, -38),
		Vector2(16, -24),
		Vector2(-16, -24)
	]), armor_steel)
	
	# Horns
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -48),
		Vector2(-38, -68),
		Vector2(-12, -54)
	]), armor_trim)
	draw_colored_polygon(PackedVector2Array([
		Vector2(18, -48),
		Vector2(38, -68),
		Vector2(12, -54)
	]), armor_trim)
	
	# Glowing red eyes slit
	draw_line(Vector2(-10, -36), Vector2(-3, -36), Color(1.0, 0.2, 0.2), 3.0)
	draw_line(Vector2(3, -36), Vector2(10, -36), Color(1.0, 0.2, 0.2), 3.0)
	
	# Center Target Bullseye (Large)
	draw_circle(Vector2(0, 4), 22, bullseye_white)
	draw_circle(Vector2(0, 4), 14, bullseye_red)
	draw_circle(Vector2(0, 4), 6, Color.YELLOW)
	
	# Dwell Timer Ring (Shrinks around bullseye to warn player)
	if not is_popping and not is_ducking and max_dwell_time > 0.0:
		var frac = clampf(dwell_timer / max_dwell_time, 0.0, 1.0)
		var ring_color = Color.GREEN.lerp(Color.RED, 1.0 - frac)
		draw_arc(Vector2(0, 4), 26, -PI * 0.5, -PI * 0.5 + frac * TAU, 32, ring_color, 4.0)
