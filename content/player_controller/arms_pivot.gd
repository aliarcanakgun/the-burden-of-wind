extends Node3D

@export_group("Arms Position Sway")
@export var pos_sway_amount := 0.004 # strength of arms lag
@export var pos_sway_smooth := 8.0
@export var max_pos_sway := 0.04

@export_group("Cage Rotation Sway")
@export var rot_sway_amount := 1.6 # pendulum strength for the cage
@export var rot_sway_smooth := 5.0
@export var max_rot_sway := 15.0 # degrees

@onready var cage: Node3D = $r_wrist/cage
@onready var init_pos: Vector3 = position
@onready var cage_init_rot: Vector3 = cage.rotation_degrees

var mouse_input := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_input = event.relative

func _process(delta: float) -> void:
	# position sway (apply to pivot)
	# moves arms and cage together opposite to mouse
	var target_x := -mouse_input.x * pos_sway_amount
	var target_y := mouse_input.y * pos_sway_amount
	
	target_x = clampf(target_x, -max_pos_sway, max_pos_sway)
	target_y = clampf(target_y, -max_pos_sway, max_pos_sway)
	
	var target_pos := init_pos + Vector3(target_x, target_y, 0.0)
	position = position.lerp(target_pos, delta * pos_sway_smooth)
	
	# rotation sway (apply ONLY to cage)
	# rotates cage like a pendulum based on movement
	var target_rot_z := mouse_input.x * rot_sway_amount
	var target_rot_x := -mouse_input.y * rot_sway_amount
	
	target_rot_z = clampf(target_rot_z, -max_rot_sway, max_rot_sway)
	target_rot_x = clampf(target_rot_x, -max_rot_sway, max_rot_sway)
	
	var target_rot := cage_init_rot + Vector3(target_rot_x, 0.0, target_rot_z)
	cage.rotation_degrees = cage.rotation_degrees.lerp(target_rot, delta * rot_sway_smooth)
	
	# reset input to return to center
	mouse_input = Vector2.ZERO
