extends Interactable

@export var player: Player

var tween: Tween

func _on_interact() -> void:
	player.movement_disabled = true
	player.coll_disabled = true
	player.is_on_ladder = true
	
	tween = create_tween()
	tween.chain().tween_property(player, "position", $target1.global_position, 14.0)
	tween.chain().tween_property(player, "position", $target2.global_position, 0.8)
	tween.chain().tween_property(player, "position", $target3.global_position, 0.4)
	
	await tween.finished
	player.movement_disabled = false
	player.coll_disabled = false
	player.is_on_ladder = false
