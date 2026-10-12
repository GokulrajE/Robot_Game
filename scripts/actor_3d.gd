extends Node3D
## Animation selection and facing; mesh geometry and tracks are authored in scenes.
var animation_enabled := true
var walking := false

func set_animation_active(active: bool) -> void:
	animation_enabled = active
	if active:
		$AnimationPlayer.play("walk" if walking and $AnimationPlayer.has_animation("walk") else "idle")
	else:
		$AnimationPlayer.pause()

func face(direction: Vector3) -> void:
	var moving := direction.length_squared() > 0.001
	if moving:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), 0.25)
	if moving != walking:
		walking = moving
		if animation_enabled:
			$AnimationPlayer.play("walk" if walking and $AnimationPlayer.has_animation("walk") else "idle")

func set_protected(active: bool) -> void:
	$Shield.visible = active
