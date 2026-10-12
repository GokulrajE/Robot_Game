extends Node3D
## The game advances scene-authored effects so pause freezes them exactly.
func _ready() -> void:
	$AnimationPlayer.animation_finished.connect(func(_animation: StringName): queue_free())
	$AnimationPlayer.play("effect")
	$AnimationPlayer.advance(0)

func advance_effect(delta: float) -> void:
	$AnimationPlayer.advance(delta)
