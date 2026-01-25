extends CanvasLayer

@export var dot_visible := true
@export var center_interaction_message := true
@export var interaction_message_offset := Vector2(0.0, 36.0)
@export var custom_interaction_message_pos := Vector2()
@export var custom_interaction_message_pos_center_x := false

var interaction_visible := false
var interaction_text := ""

func _process(_delta: float) -> void:
	%dot.visible = dot_visible
	
	%interaction_message_text.text = interaction_text
	%interaction_message.size = Vector2.ZERO # set it to minimum size
	
	%interaction_message.visible = interaction_visible
	
	if center_interaction_message: %interaction_message.position = %dot.position - %interaction_message.size/2 + interaction_message_offset
	else: %interaction_message.position = custom_interaction_message_pos - Vector2(float(custom_interaction_message_pos_center_x) * %interaction_message.size.x/2, 0.0) + interaction_message_offset

func die():
	$black.visible = true
	await get_tree().create_timer(2.5).timeout
	SceneChanger.change_scene("res://content/scenes/main_menu.tscn", 1.0, Color.WHITE)
