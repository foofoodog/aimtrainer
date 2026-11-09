extends Area2D
class_name Target

signal hit(target: Target, points: int, hit_position: Vector2)
signal escaped(target: Target)

enum DistanceLayer {
	FAR = 0,
	MID = 1,
	NEAR = 2
}

@export var target_type_name: String = "Target"
@export var base_points: int = 100
var distance_layer: DistanceLayer = DistanceLayer.MID

var is_alive: bool = true
var distance_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var base_scale: float = 1.0
var speed: float = 200.0
var direction: int = 1 # 1 = right, -1 = left

func setup_distance(layer: DistanceLayer) -> void:
	distance_layer = layer
	match layer:
		DistanceLayer.FAR:
			base_scale = 0.48
			distance_multiplier = 2.4
			speed_multiplier = 0.85
			z_index = 5
			modulate = Color(0.82, 0.88, 1.0) # atmospheric haze
		DistanceLayer.MID:
			base_scale = 0.78
			distance_multiplier = 1.5
			speed_multiplier = 1.05
			z_index = 10
			modulate = Color(1.0, 1.0, 1.0)
		DistanceLayer.NEAR:
			base_scale = 1.15
			distance_multiplier = 1.0
			speed_multiplier = 1.3
			z_index = 20
			modulate = Color(1.05, 1.02, 0.98)
	
	scale = Vector2(base_scale, base_scale)

func get_total_score() -> int:
	return int(base_points * distance_multiplier)

func on_shot(hit_pos: Vector2) -> void:
	if not is_alive:
		return
	is_alive = false
	monitoring = false
	monitorable = false
	
	var points = get_total_score()
	hit.emit(self, points, hit_pos)
	_play_death_effect()

func escape() -> void:
	if not is_alive:
		return
	is_alive = false
	escaped.emit(self)
	queue_free()

func _play_death_effect() -> void:
	# Tween scale pop and dissolve
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", scale * 1.4, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.14)
	tween.chain().tween_callback(queue_free)
