extends Node2D

func _draw():
	# Outer glow
	draw_circle(Vector2.ZERO, 72.0, Color(0.95, 0.55, 0.1, 0.22))
	# Main fill
	draw_circle(Vector2.ZERO, 60.0, Color(0.95, 0.60, 0.1, 0.88))
	# Inner highlight
	draw_circle(Vector2.ZERO, 34.0, Color(1.0, 0.88, 0.45, 0.45))
	# Outline ring
	draw_arc(Vector2.ZERO, 60.0, 0.0, TAU, 48, Color(1.0, 0.78, 0.2, 1.0), 3.5)

func die():
	queue_free()
