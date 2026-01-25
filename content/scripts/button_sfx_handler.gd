class_name ButtonSFXHandler extends Node

@export var hover_sfx := preload("res://content/sounds/sfx/mouseclick1.ogg")
@export var target_button: Button

var last_hover_state := false

func _process(_delta: float) -> void:
	if !target_button: return
	
	if target_button.is_hovered() and !last_hover_state: AudioManager.play_sfx(hover_sfx, 0.0, 0.4)
	last_hover_state = target_button.is_hovered()
