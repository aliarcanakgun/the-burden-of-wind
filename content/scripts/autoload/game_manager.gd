extends Node

const GRASS_MAT := preload('res://content/assets/grass/mat_grass.tres')
# noise resource
const wind_noise_texture: NoiseTexture2D = preload("res://content/resources/wind_noise.tres")
# gradient for wind speed control (black=calm, white=storm)
const wind_speed_gradient: GradientTexture1D = preload("res://content/resources/wind_speed.tres")

# noise parameters for wind direction
const WIND_NOISE_SCALE = 0.005
const WIND_TIME_SCALE = 0.005

# gust settings
# how fast we sample the gradient over time
const GRADIENT_SCROLL_SPEED := 0.05

# shader constants
const DIR_NOISE_SCALE := 0.005
const DIR_TIME_SCALE := 0.005
const STR_NOISE_SCALE := 0.025
const STR_TIME_SCALE := 0.05

# dynamic variables
var current_wind_direction := Vector3()
var current_wind_velocity := Vector3()
var actual_speed := 0.0 

var tps_mode := true
var paused := false

# max possible wind speed
var max_wind_speed := 3.65

var resume_tween: Tween

func _process(_delta: float) -> void:
	if wind_noise_texture and wind_noise_texture.noise:
		_calculate_wind_data()

func pause(enable_mouse := true) -> void:
	if resume_tween: resume_tween.kill()
	get_tree().paused = true
	paused = true
	if enable_mouse: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume(hide_mouse := true) -> void:
	get_tree().paused = false
	paused = false
	Engine.time_scale = 0.1
	if resume_tween: resume_tween.kill()
	resume_tween = create_tween()
	resume_tween.tween_property(Engine, "time_scale", 1.0, 0.2).set_ease(Tween.EASE_IN_OUT)
	if hide_mouse: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _calculate_wind_data() -> void:
	var sample_pos := Vector2.ZERO 
	var time := Time.get_ticks_msec() / 1000.0
	
	# speed calculation from gradient
	# scroll through the gradient over time (looping 0 to 1)
	var gradient_pos := fmod(time * GRADIENT_SCROLL_SPEED, 1.0)
	
	# sample the gradient texture at the current position
	# if gradient is not assigned, fallback to default noise logic or constant
	if wind_speed_gradient:
		# get color at position. r channel represents intensity (0..1)
		var intensity = wind_speed_gradient.gradient.sample(gradient_pos).r
		actual_speed = max_wind_speed * intensity
	else:
		actual_speed = 1.0 # fallback
	
	# direction (shader match)
	var dir_uv = (sample_pos * DIR_NOISE_SCALE / max(actual_speed, 0.1)) + (Vector2(time, time) * DIR_TIME_SCALE * actual_speed)
	var raw_dir_noise := wind_noise_texture.noise.get_noise_2d(dir_uv.x, dir_uv.y)
	
	# map -1..1 to 0..1 then to angle
	var angle := ((raw_dir_noise + 1.0) * 0.5) * TAU
	current_wind_direction = Vector3(sin(angle), 0, cos(angle)).normalized()
	
	# turbulence (shader match)
	var str_uv = (sample_pos * STR_NOISE_SCALE / max(actual_speed, 0.1)) + (Vector2(time, time) * STR_TIME_SCALE)
	var raw_str_noise := wind_noise_texture.noise.get_noise_2d(str_uv.x, str_uv.y)
	var turbulence = lerp(0.25, 1.0, (raw_str_noise + 1.0) * 0.5)
	
	# final velocity
	current_wind_velocity = current_wind_direction * actual_speed * turbulence
	
	update_shader()

func update_shader() -> void:
	#GRASS_MAT.set_shader_parameter('wind_speed', get_wind_speed())
	GRASS_MAT.set_shader_parameter('wind_speed', 2.75)

func get_wind_speed() -> float:
	return current_wind_velocity.length()
