@tool
extends Node3D

const GRASS_MESH_HIGH := preload('res://content/assets/grass/grass_high.obj')
const GRASS_MESH_LOW := preload('res://content/assets/grass/grass_low.obj')
const GRASS_MAT := preload('res://content/assets/grass/mat_grass.tres')

const TILE_SIZE := 5.0
const MAP_RADIUS := 200.0

var grass_multimeshes : Array[Array] = []
var previous_tile_id := Vector3.ZERO

@export var heightmap := preload('res://content/resources/heightmap.tres')
@export var heightmap_scale := 6.0:
	set(value):
		heightmap_scale = value
		_update_globals()

@onready var should_render_shadows := true
@onready var density_modifier := 0.8 if Engine.is_editor_hint() else 1.0

func _init() -> void:
	_update_globals()

func _update_globals():
	RenderingServer.global_shader_parameter_set('heightmap', heightmap)
	RenderingServer.global_shader_parameter_set('heightmap_scale', heightmap_scale)

func _ready() -> void:
	_setup_heightmap_collision()
	
	if Engine.is_editor_hint(): return
	
	_setup_grass_instances()
	_generate_grass_multimeshes()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	var wind_volume := 1.0
	if %shed_area.overlaps_body(%player): wind_volume = 0.2
	
	$wind_sfx.pitch_scale = lerpf(0.8, 2.0, GameManager.actual_speed / 5.0)
	$wind_sfx.volume_db = lerpf(-10.0, 5.0, min(GameManager.actual_speed / 2.0, 1.0)) * wind_volume
	$grass_sfx.volume_db = lerpf(-30.0, -18.5, GameManager.actual_speed / 5.0)
	$insect_sfx.volume_db = lerpf(-30.0, -80.0, GameManager.actual_speed / 5.0)

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return # INFO: may cause unexpected results. be careful about it.
	
	RenderingServer.global_shader_parameter_set('player_position', $player.global_position)
	
	# correct LOD by repositioning tiles when the player moves into a new tile
	#var lod_target : Node3D = EditorInterface.get_editor_viewport_3d(0).get_camera_3d() if Engine.is_editor_hint() else $player
	var lod_target : Node3D = $player
	var tile_id : Vector3 = ((lod_target.global_position + Vector3.ONE*TILE_SIZE*0.5) / TILE_SIZE * Vector3(1,0,1)).floor()
	if tile_id != previous_tile_id:
		for data in grass_multimeshes:
			data[0].global_position = data[1] + Vector3(1,0,1)*TILE_SIZE*tile_id
	previous_tile_id = tile_id

## Creates a HeightMapShape3D from the provided NoiseTexture2D
func _setup_heightmap_collision() -> void:
	var image := heightmap.noise.get_image(heightmap.width, heightmap.height)
	var dims := Vector2i(image.get_height(), image.get_width())
	var map_data : PackedFloat32Array
	for j in dims.x:
		for i in dims.y:
			map_data.push_back((image.get_pixel(i, j).r - 0.5)*heightmap_scale)
	
	var heightmap_shape := HeightMapShape3D.new()
	heightmap_shape.map_width = dims.x
	heightmap_shape.map_depth = dims.y
	heightmap_shape.map_data = map_data
	$ground/coll.shape = heightmap_shape

## Creates initial tiled multimesh instances.
func _setup_grass_instances() -> void:
	for i in range(-MAP_RADIUS, MAP_RADIUS, TILE_SIZE):
		for j in range(-MAP_RADIUS, MAP_RADIUS, TILE_SIZE):
			var instance := MultiMeshInstance3D.new()
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if should_render_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			instance.material_override = GRASS_MAT
			instance.position = Vector3(i, 0.0, j)
			instance.extra_cull_margin = 10.0
			add_child(instance)
			
			grass_multimeshes.append([instance, instance.position])

## generates multimeshes for previously created multimesh instances with LOD based on distance to origin.
func _generate_grass_multimeshes() -> void:
	var multimesh_lods : Array[MultiMesh] = [
		create_grass_multimesh(0.9*density_modifier, TILE_SIZE, GRASS_MESH_HIGH),
		create_grass_multimesh(0.5*density_modifier, TILE_SIZE, GRASS_MESH_HIGH),
		create_grass_multimesh(0.25*density_modifier, TILE_SIZE, GRASS_MESH_LOW),
		create_grass_multimesh(0.1*density_modifier, TILE_SIZE, GRASS_MESH_LOW),
		create_grass_multimesh(0.02*(1.0 if density_modifier != 0.0 else 0.0), TILE_SIZE, GRASS_MESH_LOW),
	]
	for data in grass_multimeshes:
		var distance = data[1].length() # Distance from center tile
		if distance > MAP_RADIUS: continue
		if distance < 45.0:     data[0].multimesh = multimesh_lods[0]
		elif distance < 80.0:   data[0].multimesh = multimesh_lods[1]
		elif distance < 105.0:  data[0].multimesh = multimesh_lods[2]
		elif distance < 125.0:  data[0].multimesh = multimesh_lods[3]
		else:                   data[0].multimesh = multimesh_lods[4]

func create_grass_multimesh(density : float, tile_size : float, mesh : Mesh) -> MultiMesh:
	var row_size = ceil(tile_size*lerpf(0.0, 10.0, density));
	var multimesh := MultiMesh.new()
	multimesh.mesh = mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = row_size*row_size
	
	var jitter_offset := tile_size/float(row_size) * 0.5 * 0.9
	for i in row_size:
		for j in row_size:
			var grass_position := Vector3(i/float(row_size) - 0.5, 0, j/float(row_size) - 0.5) * tile_size
			var grass_offset := Vector3(randf_range(-jitter_offset, jitter_offset), 0, randf_range(-jitter_offset, jitter_offset))
			multimesh.set_instance_transform(i + j*row_size, Transform3D(Basis(), grass_position + grass_offset))
	return multimesh

func generate_eyes():
	var eyes_instance = MultiMeshInstance3D.new()
	add_child(eyes_instance)
	
	eyes_instance.material_override = load("res://content/materials/eyes.tres")
	
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.8,0.8)
	
	eyes_instance.multimesh = create_eyes_multimesh(230, 5.0, 35.0, quad_mesh)
	eyes_instance.global_position = $player.global_position

func create_eyes_multimesh(count: int, min_radius: float, max_radius: float, mesh: Mesh) -> MultiMesh:
	var multimesh := MultiMesh.new()
	multimesh.mesh = mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = false
	multimesh.use_custom_data = true 
	multimesh.instance_count = count
	
	for i in range(count):
		# random angle
		var angle := randf() * TAU 
		
		# uniform donut distribution logic
		# square radii to work in area space, avoiding center clustering
		var r_min_sq := min_radius * min_radius
		var r_max_sq := max_radius * max_radius
		
		# interpolate between squared radii, then sqrt back
		var distance := sqrt(lerpf(r_min_sq, r_max_sq, randf()))
		
		var x := cos(angle) * distance
		var z := sin(angle) * distance
		var pos := Vector3(x, 0.0, z)
		
		multimesh.set_instance_transform(i, Transform3D(Basis(), pos))
		
		# random blink data
		var speed = randf_range(0.5, 2.0)
		var offset = randf_range(0.0, 10.0)
		multimesh.set_instance_custom_data(i, Color(speed, offset, 0.0, 0.0))
		
	return multimesh


func _on_final_interact() -> void:
	%outro_cam.make_current()
	%player.movement_disabled = true
	%player.visible = false
	%beacon_anim.play("anim")
	await %beacon_anim.animation_finished
	SceneChanger.change_scene("res://content/scenes/main_menu.tscn", 0.5, Color.WHITE)
