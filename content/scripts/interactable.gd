class_name Interactable extends Area3D

signal on_interact

@export var prompt_message := ""

func interact() -> void:
	on_interact.emit()
