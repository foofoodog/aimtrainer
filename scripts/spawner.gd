extends Node2D
class_name Spawner

signal target_spawned(target: Target)

@export var bird_scene: PackedScene = preload("res://scenes/targets/bird_target.tscn")
@export var beast_scene: PackedScene = preload("res://scenes/targets/beast_target.tscn")
@export var brute_scene: PackedScene = preload("res://scenes/targets/brute_target.tscn")

var is_active: bool = false
var spawn_timer: float = 0.4
var speed_ramp_rate: float = 1.0

# Level progression based on good shots (hits)
var current_level: int = 1
var total_good_shots: int = 0

# Active target count tracking
var active_targets: Array[Target] = []

func _get_brute_spots() -> Array:
	var view_w = maxf(1280.0, get_viewport_rect().size.x)
	return [
		{"x": view_w * 0.18, "y": 360, "layer": Target.DistanceLayer.FAR},
		{"x": view_w * 0.50, "y": 350, "layer": Target.DistanceLayer.FAR},
		{"x": view_w * 0.82, "y": 360, "layer": Target.DistanceLayer.FAR},
		{"x": view_w * 0.30, "y": 440, "layer": Target.DistanceLayer.MID},
		{"x": view_w * 0.70, "y": 440, "layer": Target.DistanceLayer.MID},
		{"x": view_w * 0.50, "y": 460, "layer": Target.DistanceLayer.MID},
		{"x": view_w * 0.16, "y": 550, "layer": Target.DistanceLayer.NEAR},
		{"x": view_w * 0.84, "y": 550, "layer": Target.DistanceLayer.NEAR}
	]

func start(ramp_rate: float) -> void:
	speed_ramp_rate = ramp_rate
	current_level = 1
	total_good_shots = 0
	spawn_timer = 0.4
	is_active = true

func stop() -> void:
	is_active = false
	for t in active_targets:
		if is_instance_valid(t):
			t.queue_free()
	active_targets.clear()

func set_hits(hits: int) -> void:
	total_good_shots = hits
	current_level = 1 + int(hits / 10)

func get_current_difficulty() -> float:
	# Speeds up to the next level every 10 good shots
	return 1.0 + float(current_level - 1) * 0.20 * speed_ramp_rate

func _process(delta: float) -> void:
	if not is_active:
		return
		
	spawn_timer -= delta
	
	# Clean up freed targets from list
	active_targets = active_targets.filter(func(t): return is_instance_valid(t) and t.is_alive)
	
	if spawn_timer <= 0.0:
		_attempt_spawn()
		var difficulty = get_current_difficulty()
		var base_delay = randf_range(1.6, 2.3)
		spawn_timer = maxf(0.5, base_delay / difficulty)

func _attempt_spawn() -> void:
	var difficulty = get_current_difficulty()
	var max_concurrent = int(clampf(2.0 + (current_level - 1) * 0.5, 2, 8))
	
	if active_targets.size() >= max_concurrent:
		return
		
	var roll = randf()
	if roll < 0.38:
		_spawn_bird()
	elif roll < 0.74:
		_spawn_beast()
	else:
		_spawn_brute()

func _random_distance_layer() -> Target.DistanceLayer:
	var r = randf()
	if r < 0.35:
		return Target.DistanceLayer.FAR
	elif r < 0.72:
		return Target.DistanceLayer.MID
	else:
		return Target.DistanceLayer.NEAR

func _spawn_bird() -> void:
	var bird: BirdTarget = bird_scene.instantiate()
	var layer = _random_distance_layer()
	var dir = 1 if randf() > 0.5 else -1
	var view_w = maxf(1280.0, get_viewport_rect().size.x)
	
	# Spawn birds well below the top HUD bar (height 68) with generous clearance
	var y_min = 165.0
	var y_max = 285.0
	if layer == Target.DistanceLayer.FAR:
		# Far birds fly higher in open sky above mountains
		y_min = 165.0
		y_max = 210.0
	elif layer == Target.DistanceLayer.MID:
		y_min = 195.0
		y_max = 250.0
	elif layer == Target.DistanceLayer.NEAR:
		y_min = 225.0
		y_max = 295.0
		
	var start_x = -70.0 if dir == 1 else view_w + 70.0
	bird.position = Vector2(start_x, randf_range(y_min, y_max))
	bird.direction = dir
	bird.speed = randf_range(260.0, 360.0)
	bird.setup_distance(layer)
	bird.speed_multiplier *= get_current_difficulty()
	
	_add_target(bird)

func _spawn_beast() -> void:
	var beast: BeastTarget = beast_scene.instantiate()
	var layer = _random_distance_layer()
	var dir = 1 if randf() > 0.5 else -1
	var view_w = maxf(1280.0, get_viewport_rect().size.x)
	
	var y_pos = 420.0
	match layer:
		Target.DistanceLayer.FAR: y_pos = randf_range(340.0, 370.0)
		Target.DistanceLayer.MID: y_pos = randf_range(410.0, 460.0)
		Target.DistanceLayer.NEAR: y_pos = randf_range(500.0, 560.0)
		
	var start_x = -80.0 if dir == 1 else view_w + 80.0
	beast.position = Vector2(start_x, y_pos)
	beast.direction = dir
	beast.speed = randf_range(300.0, 420.0)
	beast.setup_distance(layer)
	beast.speed_multiplier *= get_current_difficulty()
	
	_add_target(beast)

func _spawn_brute() -> void:
	var available_spots = _get_brute_spots()
	available_spots.shuffle()
	
	var chosen_spot = null
	for spot in available_spots:
		var pos = Vector2(spot["x"], spot["y"])
		var occupied = false
		for t in active_targets:
			if is_instance_valid(t) and t is BruteTarget:
				if t.position.distance_to(pos) < 60.0:
					occupied = true
					break
		if not occupied:
			chosen_spot = spot
			break
			
	if chosen_spot == null:
		return
		
	var brute: BruteTarget = brute_scene.instantiate()
	brute.position = Vector2(chosen_spot["x"], chosen_spot["y"])
	brute.setup_distance(chosen_spot["layer"])
	brute.speed_multiplier *= get_current_difficulty()
	
	_add_target(brute)
	SoundEffects.play_popup()

func _add_target(target: Target) -> void:
	add_child(target)
	active_targets.append(target)
	target_spawned.emit(target)
