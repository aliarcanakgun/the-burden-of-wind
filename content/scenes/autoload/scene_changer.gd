extends CanvasLayer

var active := false

func change_scene(scene: String, duration := 1.0, color := Color("1b1b1bfe")) -> void:
	if scene.is_empty(): return
	
	$rect.modulate = color
	active = true
	
	var master = AudioManager.master_volume
	
	await outro(duration)
	#get_tree().change_scene_to_packed(scene)
	get_tree().change_scene_to_file(scene)
	await get_tree().scene_changed
	
	get_tree().paused = false
	#$rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$rect.flip_h = true
	$rect.flip_v = true
	
	var material = $rect.material
	var tween_out = create_tween()
	tween_out.tween_property(material, "shader_parameter/progress", 0.0, duration)
	#tween_out.tween_property($rect, "modulate", Color("ddddddfe"), duration)
	tween_out.tween_property(AudioManager, "master_volume", master, duration)
	tween_out.finished.connect(tween_out_finished, CONNECT_ONE_SHOT)

func outro(duration := 1.0) -> void:
	$rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var material = $rect.material
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(material, "shader_parameter/progress", 1.0, duration)
	#tween.tween_property($rect, "modulate", Color(), duration)
	tween.tween_property(AudioManager, "master_volume", 0.0, duration)
	await tween.finished

func tween_out_finished() -> void:
	$rect.flip_h = false
	$rect.flip_v = false
	$rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	active = false
