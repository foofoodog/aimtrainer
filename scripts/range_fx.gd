extends Node
class_name RangeFX

# Procedural Particle & Visual FX System
# Generates zero-dependency procedural particle textures and instantiates dynamic kinetic FX.

static var _circle_texture: ImageTexture = null
static var _feather_texture: ImageTexture = null
static var _spark_texture: ImageTexture = null

static func get_circle_texture() -> ImageTexture:
	if _circle_texture:
		return _circle_texture
	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size * 0.5, size * 0.5)
	var radius = size * 0.48
	for y in range(size):
		for x in range(size):
			var dist = center.distance_to(Vector2(x + 0.5, y + 0.5))
			if dist < radius:
				var alpha = clampf(1.0 - (dist / radius), 0.0, 1.0)
				# Smooth quadratic falloff
				alpha = alpha * alpha
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	_circle_texture = ImageTexture.create_from_image(img)
	return _circle_texture

static func get_feather_texture() -> ImageTexture:
	if _feather_texture:
		return _feather_texture
	var w = 16
	var h = 32
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var center_x = w * 0.5
	for y in range(h):
		var norm_y = float(y) / float(h)
		# Feather silhouette: wider in upper-mid, tapering at quill and tip
		var width_at_y = sin(norm_y * PI) * (w * 0.45)
		for x in range(w):
			var dx = absf(float(x) - center_x)
			if dx <= width_at_y:
				var alpha = clampf(1.0 - (dx / maxf(0.1, width_at_y)), 0.0, 1.0)
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha * 0.9))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	_feather_texture = ImageTexture.create_from_image(img)
	return _feather_texture

static func get_spark_texture() -> ImageTexture:
	if _spark_texture:
		return _spark_texture
	var size = 24
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size * 0.5, size * 0.5)
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x + 0.5, y + 0.5)
			var dx = absf(pos.x - center.x)
			var dy = absf(pos.y - center.y)
			# Diamond flare shape
			var d = dx + dy
			if d < size * 0.5:
				var alpha = clampf(1.0 - (d / (size * 0.5)), 0.0, 1.0)
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha * alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	_spark_texture = ImageTexture.create_from_image(img)
	return _spark_texture

# --- Spawner Methods ---

static func spawn_feather_burst(parent: Node2D, pos: Vector2, tint: Color = Color(0.2, 0.6, 1.0)) -> void:
	var p = CPUParticles2D.new()
	p.position = pos
	p.texture = get_feather_texture()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 22
	p.lifetime = 1.1
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 90.0)
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 240.0
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.damping_min = 35.0
	p.damping_max = 60.0
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.8
	p.color = tint
	
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

static func spawn_dirt_kickup(parent: Node2D, pos: Vector2) -> void:
	var p = CPUParticles2D.new()
	p.position = pos
	p.texture = get_circle_texture()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.92
	p.amount = 18
	p.lifetime = 0.65
	p.direction = Vector2(0, -1)
	p.spread = 75.0
	p.gravity = Vector2(0, 320.0)
	p.initial_velocity_min = 160.0
	p.initial_velocity_max = 280.0
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.65
	p.color = Color(0.55, 0.42, 0.25, 0.85)
	
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

static func spawn_metal_sparks(parent: Node2D, pos: Vector2) -> void:
	var p = CPUParticles2D.new()
	p.position = pos
	p.texture = get_spark_texture()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.98
	p.amount = 28
	p.lifetime = 0.55
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 420.0)
	p.initial_velocity_min = 180.0
	p.initial_velocity_max = 450.0
	p.scale_amount_min = 0.2
	p.scale_amount_max = 0.7
	# Bright glowing incandescent orange-yellow
	p.color = Color(2.5, 1.8, 0.5, 1.0)
	
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	
	# Flying armor debris chunks
	for i in range(4):
		_spawn_debris_chunk(parent, pos)

static func _spawn_debris_chunk(parent: Node2D, pos: Vector2) -> void:
	var chunk = Node2D.new()
	chunk.position = pos
	parent.add_child(chunk)
	
	var vel = Vector2(randf_range(-220.0, 220.0), randf_range(-260.0, -100.0))
	var rot_speed = randf_range(-12.0, 12.0)
	var pts = PackedVector2Array([
		Vector2(-5, -4), Vector2(6, -3), Vector2(4, 5), Vector2(-4, 4)
	])
	
	# Draw small metal plate chunk
	var draw_node = Node2D.new()
	draw_node.draw.connect(func():
		draw_node.draw_colored_polygon(pts, Color(0.4, 0.45, 0.52))
		draw_node.draw_line(Vector2(-5, -4), Vector2(6, -3), Color(0.7, 0.75, 0.8), 1.5)
	)
	chunk.add_child(draw_node)
	draw_node.queue_redraw()
	
	var tween = chunk.create_tween()
	tween.set_parallel(true)
	tween.tween_property(chunk, "position", pos + vel * 0.45 + Vector2(0, 150), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(chunk, "rotation", rot_speed * 0.45, 0.45)
	tween.tween_property(chunk, "modulate:a", 0.0, 0.45).set_delay(0.2)
	tween.chain().tween_callback(chunk.queue_free)

static func spawn_miss_puff(parent: Node2D, pos: Vector2) -> void:
	var p = CPUParticles2D.new()
	p.position = pos
	p.texture = get_circle_texture()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 12
	p.lifetime = 0.45
	p.direction = Vector2(0, -1)
	p.spread = 140.0
	p.gravity = Vector2(0, 180.0)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 140.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.75
	p.color = Color(0.68, 0.62, 0.52, 0.65)
	
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
