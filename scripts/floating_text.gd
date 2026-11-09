extends Node2D

@onready var label: Label = $Label

func setup(text: String, color: Color = Color.WHITE, scale_mult: float = 1.0) -> void:
	if not is_node_ready():
		await ready
	label.text = text
	label.modulate = color
	scale = Vector2(scale_mult, scale_mult)
	
	var tween = create_tween()
	tween.set_parallel(true)
	# Float upward
	tween.tween_property(self, "position:y", position.y - 45.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.65).set_delay(0.2)
	tween.chain().tween_callback(queue_free)
