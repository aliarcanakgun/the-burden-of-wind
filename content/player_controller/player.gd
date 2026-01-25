class_name Player extends CharacterBody3D

@export_group("Controls")
@export var mouse_control_enabled := true
@export var mouse_sensivity := 1.5

@export_group("Movement")
@export var gravity := 20.0 
@export var acceleration := 7.0
@export var deceleration := 11.0
@export var walk_speed := 5.0
@export var sprint_speed := 10.0
@export var on_air_control := 2.0 # less control on air, not less speed
@export var jump_strength := 7.0

@export_group("Head Bob")
@export var bob_freq := 2.0 # steps per second
@export var bob_amp := 0.06 # up/down amount
@export var t_bob := 0.0 # time accumulator

@export_group("Landing")
@export var landing_depth := 0.3 # how much camera dips
@export var landing_smooth := 4.0 # recovery speed

@export_group("Core Mechanics")
@export var health := 100.0 # player health
@export var fire_health := 100.0
@export var fire_heal_rate := 2.0
@export var fire_damage_rate := 0.0 # 8.0

# cache variables
@onready var head := $head
@onready var head_bob_target := $head/cam/bob_target
@onready var head_start_pos: Vector3 = head_bob_target.position

var last_velocity_y := 0.0
var colliding_interactable: Interactable

var hud_visible := false
var is_on_ladder := false
var is_shielding := false
var is_wind_hitting := false
var movement_disabled := true
var coll_disabled := false
var gameover := false

# footstep
var step_interval = 0.4
var time_since_last_step = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameManager.tps_mode = false

func _input(event: InputEvent) -> void:
	if mouse_control_enabled and event is InputEventMouseMotion and !is_shielding:
		rotate_y(-event.relative.x * mouse_sensivity * 0.001)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * mouse_sensivity * 0.001, deg_to_rad(-89.0), deg_to_rad(89.0))

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_right", "move_left", "move_back", "move_forward") * float(!movement_disabled) * float(!gameover)
	var direction := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	
	# handle gravity separately to avoid lerp conflict
	if !is_on_floor() and (gameover or !movement_disabled):
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump") and !gameover:
		velocity.y = jump_strength
	
	var accel_weight : float = (acceleration if direction.length() > 0 else deceleration) * delta
	
	# reduce control on air, but keep the momentum
	if !is_on_floor(): 
		accel_weight = on_air_control * delta
	
	# separate horizontal movement from vertical physics
	# lerp only X and Z. DO NOT touch Y here.
	velocity.x = lerp(velocity.x, direction.x * speed, accel_weight)
	velocity.z = lerp(velocity.z, direction.z * speed, accel_weight)
	
	# landing effect:
	# check if we just hit the ground
	if is_on_floor() and last_velocity_y < -5.0: # -5.0 is threshold for "hard fall"
		# dip the camera based on fall speed (clamped)
		var impact = clampf(abs(last_velocity_y) * 0.05, 0.1, 0.5)
		head_bob_target.position.y -= impact * landing_depth
		
		# play sfx
		$footstep_sfx.play()
	
	# smooth recovery from landing/bobbing
	head_bob_target.position.y = lerp(head_bob_target.position.y, head_start_pos.y, delta * landing_smooth)
	
	# head_bob_target bob logic:
	# only bob if moving and on floor
	var speed_clamped = velocity.length()
	if is_on_floor() and speed_clamped > 0.1:
		t_bob += delta * velocity.length() * float(is_on_floor())
		
		# sin wave for vertical bob
		var pos_y = sin(t_bob * bob_freq) * bob_amp
		# cos wave for horizontal bob (optional, creates figure-8)
		var pos_x = cos(t_bob * bob_freq * 0.5) * bob_amp * 0.5
		
		# apply to camera/head_bob_target position
		head_bob_target.position.y += pos_y * delta # add to current pos (which is lerping back)
		head_bob_target.position.x = lerp(head_bob_target.position.x, head_start_pos.x + pos_x, delta * 10.0)
	else:
		# reset horizontal center when stopped
		head_bob_target.position.x = lerp(head_bob_target.position.x, head_start_pos.x, delta * 10.0)
	
	# store velocity for next frame landing check
	last_velocity_y = velocity.y
	
	move_and_slide()

func _process(delta: float) -> void:
	$hud.visible = hud_visible
	
	# core
	if Input.is_action_just_pressed("shield") and is_on_floor() and !gameover:
		if !is_shielding:
			movement_disabled = true
			%anims.play("shield")
		else:
			%anims.play_backwards("shield")
			await %anims.animation_finished
			movement_disabled = false
		is_shielding = !is_shielding
	
	if is_shielding and !gameover and !movement_disabled:
		head.rotation.x = lerpf(head.rotation.x, 0.0, 10*delta)
	
	if !gameover and !is_on_ladder: _update_stats(delta)
	
	# interaction
	if %raycast.is_colliding() and !gameover:
		var object = %raycast.get_collider()
		if object is Interactable:
			if object != colliding_interactable:
				colliding_interactable = object
		else:
			colliding_interactable = null
	else:
		colliding_interactable = null
	
	if colliding_interactable and !gameover:
		$hud.interaction_text = colliding_interactable.prompt_message
		$hud.interaction_visible = true
	else: $hud.interaction_visible = false
	
	if Input.is_action_just_pressed("interact") and colliding_interactable and !gameover:
		colliding_interactable.interact()
	
	$coll.disabled = coll_disabled
	
	# play footstep sound
	step_interval = 0.3 if Input.is_action_pressed("sprint") else 0.6
	if velocity.length() > 0.1 and is_on_floor():
		time_since_last_step += delta
		
		if time_since_last_step >= step_interval:
			play_footstep()
			time_since_last_step = 0.0
	else:
		time_since_last_step = step_interval

func _update_stats(delta: float) -> void:
	if gameover: return
	
	var speed := GameManager.get_wind_speed()
	$cage_raycast.target_position = GameManager.current_wind_direction * -1
	is_wind_hitting = !$cage_raycast.is_colliding() and speed > 0.5
	
	if is_wind_hitting and !is_shielding:
		var damage = fire_damage_rate * speed * delta
		fire_health -= damage
	else:
		fire_health += fire_heal_rate * delta
	
	fire_health = clamp(fire_health, 0.0, 100.0)
	
	# visual
	%light.light_color = Color("ff0044ff").lerp(Color("8fc0ff"), fire_health/100)
	%light.light_energy = lerpf(0.0, 3.0, fire_health/100)
	
	var gradient_color_1 := Color("ff0044").lerp(Color("00ffff"), fire_health/100)
	var gradient_color_2 := Color("c896d3").lerp(Color("0034ff"), fire_health/100)
	var mat = %fire.material_override as ShaderMaterial
	(mat.get_shader_parameter("Coloring_Texture").gradient as Gradient).set_color(2, gradient_color_1)
	(mat.get_shader_parameter("Coloring_Texture").gradient as Gradient).set_color(3, gradient_color_2)
	mat.set_shader_parameter("Fresnel_Color", Color("e00081").lerp(Color("4fffff"), fire_health/100))
	mat.set_shader_parameter("Emmision_Power", lerpf(0.0, 3.0, fire_health/100))
	mat.set_shader_parameter("Opacity", ease(fire_health/100, 0.4))
	
	# gameover
	if fire_health <= 0.0:
		die()

func die() -> void:
	%sparks.emitting = false
	gameover = true
	get_parent().generate_eyes()
	await get_tree().create_timer(2.5).timeout
	$hud.die()

func play_footstep() -> void:
	$footstep_sfx.pitch_scale = randf_range(0.9, 1.15)
	$footstep_sfx.play()

func activate_camera():
	$head/cam.make_current()
