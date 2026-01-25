extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_play_pressed() -> void:
	#SceneChanger.change_scene(preload("res://content/scenes/world.tscn"))
	SceneChanger.change_scene("res://content/scenes/world.tscn", 1.0, Color.WHITE)

func _on_settings_pressed() -> void:
	pass # Replace with function body.

func _on_quit_pressed() -> void:
	await SceneChanger.outro()
	get_tree().quit()
