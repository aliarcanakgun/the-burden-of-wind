extends CanvasLayer

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey: if event.keycode == KEY_ESCAPE and event.pressed and !SceneChanger.active:
		if GameManager.paused: GameManager.resume()
		else: GameManager.pause()
		visible = GameManager.paused

func _on_resume_pressed() -> void:
	GameManager.resume()
	visible = GameManager.paused

func _on_settings_pressed() -> void:
	pass # Replace with function body.

func _on_quit_pressed() -> void:
	SceneChanger.change_scene("res://content/scenes/main_menu.tscn")
