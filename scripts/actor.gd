extends Node2D
## Reusable animated actor; appearance and animation tracks live in its scene.
var heading := Vector2.ZERO

func set_animation_active(active: bool) -> void:
	if active:
		$AnimationPlayer.play("float")
	else:
		$AnimationPlayer.pause()

func face(direction: Vector2) -> void:
	if absf(direction.x) > 0.01:
		$Sprite.flip_h = direction.x < 0
