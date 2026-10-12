extends Node3D
## State and interaction only; meshes, lighting and animation tracks live in scenes.
const ICONS = [
	preload("res://scenes/3d/icons/apple.tscn"),
	preload("res://scenes/3d/icons/flower.tscn"),
	preload("res://scenes/3d/icons/fish.tscn"),
	preload("res://scenes/3d/icons/rocket.tscn"),
	preload("res://scenes/3d/icons/mushroom.tscn"),
	preload("res://scenes/3d/icons/butterfly.tscn"),
	preload("res://scenes/3d/icons/duck.tscn"),
	preload("res://scenes/3d/icons/tree.tscn")]
var disabled := false
var icon_id := -1
var reduced_motion := false

func animate(animation: String) -> void:
	$AnimationPlayer.stop()
	$Pivot.position = Vector3(0, 0.2, 0)
	$Pivot.scale = Vector3.ONE
	$Pivot.rotation = Vector3.ZERO
	if reduced_motion: return
	$AnimationPlayer.play(animation)
	$AnimationPlayer.advance(0)

func set_icon(value: int) -> void:
	if icon_id == value: return
	icon_id = value
	for child in $Pivot/Icon.get_children():
		$Pivot/Icon.remove_child(child)
		child.queue_free()
	$Pivot/Icon.add_child(ICONS[value % ICONS.size()].instantiate())

func reveal(show_icon: bool, animate := true) -> void:
	$Pivot/Icon.visible = show_icon
	$Pivot/Cover.visible = not show_icon
	if animate:
		self.animate("reveal")

func highlight(active: bool) -> void:
	$Halo.visible = active
	if active:
		animate("bounce")

func mark_matched() -> void:
	$Halo.show()
	animate("match")

func advance_animation(delta: float) -> void:
	$AnimationPlayer.advance(delta)
