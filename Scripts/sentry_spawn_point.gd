@tool
extends Marker2D

@export var preview_radius: float = 18.0:
	set(value):
		preview_radius = value
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	draw_circle(Vector2.ZERO, preview_radius, Color(1.0, 0.75, 0.2, 0.18))
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.75, 0.2, 0.9))
